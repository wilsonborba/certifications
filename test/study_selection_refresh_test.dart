import 'dart:async';
import 'dart:convert';

import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/quiz_wizard_data.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:certifications/domain/models/study_selection.dart';
import 'package:certifications/domain/services/draft_progress_store.dart';
import 'package:certifications/domain/services/study_api_service.dart';
import 'package:certifications/presentation/components/quiz/granular_range_selector.dart';
import 'package:certifications/presentation/widgets/quiz_wizard/on_quiz_wizard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

class _SelectionStudyApi extends StudyApiService {
  _SelectionStudyApi({this.failGet = false, this.pendingGet});

  final bool failGet;
  final Completer<Study>? pendingGet;

  @override
  Future<Study> get(String id) async {
    if (failGet) throw const StudyApiException(403);
    return pendingGet?.future ?? _study(id);
  }

  @override
  Future<List<ReportPickerItem>> listReports() async => const [];
}

class _SwitchingSelectionStudyApi extends StudyApiService {
  final oldStudyRead = Completer<Study>();

  @override
  Future<Study> get(String id) => id == 'old-selection-study'
      ? oldStudyRead.future
      : Future.value(_study(id));

  @override
  Future<List<ReportPickerItem>> listReports() async => const [];
}

Study _study(String id) => Study.fromJson({
  'study': {'id': id, 'title': 'Selection study', 'status': 'draft'},
  'sources': [],
});

QuizWizardData _fileStudyDraft(List<int> bytes) => QuizWizardData()
  ..name = 'Selection study'
  ..currentStep = 1
  ..addFile(AttachedFile(bytes: bytes, name: 'notes.txt', kind: 'txt'));

Widget _wizard({
  required String studyId,
  required QuizWizardData draft,
  required StudyApiService api,
  required DraftProgressStore progressStore,
}) => MaterialApp(
  localizationsDelegates: const [
    AppLocalizationsDelegate(),
    FallbackCupertinoLocalizationsDelegate(),
    FallbackMaterialLocalizationsDelegate(),
    DefaultWidgetsLocalizations.delegate,
    DefaultMaterialLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: OnQuizWizardScreen(
    studyId: studyId,
    draft: draft,
    onGenerate: () {},
    apiService: api,
    progressStore: progressStore,
  ),
);

Future<void> _openFileSelector(WidgetTester tester) async {
  final fileName = find.text('notes.txt');
  await tester.ensureVisible(fileName);
  await tester.pump();
  await tester.tap(fileName);
  await tester.pumpAndSettle();
}

Future<void> _commitSelectedText(WidgetTester tester) async {
  final button = find.text('Add selected text');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  const studyId = 'selection-refresh-study';
  const text = 'alpha\nbeta';
  const selectedSpec = 'p1:0-5';
  final store = DraftProgressStore.instance;

  test('text content digest follows upload normalization', () {
    final windowsText = utf8.encode('\uFEFFalpha\r\nbeta');
    final normalized = utf8.encode(text);
    expect(
      StudySelection.contentDigest(windowsText, kind: 'txt'),
      StudySelection.contentDigest(normalized, kind: 'txt'),
    );
    expect(
      StudySelection.contentDigest([1, 2, 3], kind: 'pdf'),
      isNot(StudySelection.contentDigest([1, 2, 4], kind: 'pdf')),
    );
  });

  test('text selections use canonical disjoint UTF-16 ranges', () {
    const source = 'A😀XBC';
    final first = StudySelection.includePassageRange('', 1, 3, source);
    expect(first, 'p1:1-3');
    expect(
      StudySelection.includePassageRange(first!, 5, 6, source),
      'p1:1-3,p1:5-6',
    );
    expect(
      StudySelection.includePassageRange('', 2, 3, source),
      isNull,
      reason: 'offset 2 would split the emoji surrogate pair',
    );
    expect(StudySelection.passageRanges('p1:1-3,p1:5-6', source), [
      (1, 3),
      (5, 6),
    ]);
  });

  test(
    'metadata is bounded, contains no source content, and clears by draft',
    () async {
      await store.clear(studyId);
      addTearDown(() => store.clear(studyId));
      final digest = StudySelection.contentDigest(
        utf8.encode(text),
        kind: 'txt',
      );
      await store.saveSourceSelections(studyId, [
        DraftSourceSelection(
          contentDigest: digest,
          kind: 'passages',
          spec: selectedSpec,
        ),
      ]);

      final restored = await store.getSourceSelections(studyId);
      expect(restored, hasLength(1));
      expect(restored.single.contentDigest, digest);
      expect(restored.single.kind, 'passages');
      expect(restored.single.spec, selectedSpec);
      final raw = web.window.localStorage.getItem(
        'certifications.draft_progress::$studyId::sourceSelections',
      );
      expect(raw, isNotNull);
      expect(raw, isNot(contains(text)));
      expect(raw, contains(digest));

      await store.clear(studyId);
      expect(await store.getSourceSelections(studyId), isEmpty);
    },
  );

  test('unsupported metadata versions are discarded safely', () async {
    await store.clear(studyId);
    addTearDown(() => store.clear(studyId));
    const key = 'certifications.draft_progress::$studyId::sourceSelections';
    web.window.localStorage.setItem(
      key,
      jsonEncode({'version': 2, 'entries': []}),
    );

    expect(await store.getSourceSelections(studyId), isEmpty);
    expect(web.window.localStorage.getItem(key), isNull);
  });

  testWidgets(
    'authorized draft restores matching content selection on reselect',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await store.clear(studyId);
      addTearDown(() => store.clear(studyId));
      final bytes = utf8.encode(text);
      await store.saveSourceSelections(studyId, [
        DraftSourceSelection(
          contentDigest: StudySelection.contentDigest(bytes, kind: 'txt'),
          kind: 'passages',
          spec: selectedSpec,
        ),
      ]);
      final draft = _fileStudyDraft(bytes);

      await tester.pumpWidget(
        _wizard(
          studyId: studyId,
          draft: draft,
          api: _SelectionStudyApi(),
          progressStore: store,
        ),
      );
      await tester.pumpAndSettle();
      await _openFileSelector(tester);

      expect(find.byType(GranularRangeSelector), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        selectedSpec,
      );
      expect(draft.attachedFiles.single.selectionKind, 'passages');
      expect(draft.attachedFiles.single.selectionSpec, selectedSpec);
      expect(draft.attachedFiles.single.isWholeDocument, isFalse);
      final selectedSpans = tester
          .widget<SelectableText>(find.byType(SelectableText))
          .textSpan!
          .children!
          .whereType<TextSpan>()
          .where((span) => span.style?.backgroundColor != null);
      expect(selectedSpans.map((span) => span.text), ['alpha']);
    },
  );

  testWidgets(
    'fresh refresh keeps pending source selections until files are reselected',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const secondText = 'gamma\ndelta';
      const secondId = 'selection-refresh-second-study';
      await store.clear(studyId);
      await store.clear(secondId);
      addTearDown(() async {
        await store.clear(studyId);
        await store.clear(secondId);
      });
      final bytes = utf8.encode(text);
      final secondBytes = utf8.encode(secondText);
      await store.saveSourceSelections(studyId, [
        DraftSourceSelection(
          contentDigest: StudySelection.contentDigest(bytes, kind: 'txt'),
          kind: 'passages',
          spec: selectedSpec,
        ),
        DraftSourceSelection(
          contentDigest: StudySelection.contentDigest(secondBytes, kind: 'txt'),
          kind: 'passages',
          spec: 'p1:6-11',
        ),
      ]);
      final draft = QuizWizardData()
        ..name = 'Selection study'
        ..currentStep = 1;

      await tester.pumpWidget(
        _wizard(
          studyId: studyId,
          draft: draft,
          api: _SelectionStudyApi(),
          progressStore: store,
        ),
      );
      await tester.pumpAndSettle();

      expect(draft.attachedFiles, isEmpty);
      expect(await store.getSourceSelections(studyId), hasLength(2));

      draft.addFile(AttachedFile(bytes: bytes, name: 'notes.txt', kind: 'txt'));
      await tester.pumpAndSettle();
      await _openFileSelector(tester);

      expect(draft.attachedFiles.single.selectionSpec, selectedSpec);
      final retained = await store.getSourceSelections(studyId);
      expect(retained, hasLength(2));
      expect(
        retained.singleWhere((entry) => entry.spec == 'p1:6-11').contentDigest,
        StudySelection.contentDigest(secondBytes, kind: 'txt'),
      );
    },
  );

  testWidgets('different reselected content does not inherit saved ranges', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await store.clear(studyId);
    addTearDown(() => store.clear(studyId));
    final originalBytes = utf8.encode(text);
    await store.saveSourceSelections(studyId, [
      DraftSourceSelection(
        contentDigest: StudySelection.contentDigest(originalBytes, kind: 'txt'),
        kind: 'passages',
        spec: selectedSpec,
      ),
    ]);
    final draft = _fileStudyDraft(utf8.encode('other text'));

    await tester.pumpWidget(
      _wizard(
        studyId: studyId,
        draft: draft,
        api: _SelectionStudyApi(),
        progressStore: store,
      ),
    );
    await tester.pumpAndSettle();
    await _openFileSelector(tester);

    expect(find.byType(GranularRangeSelector), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(draft.attachedFiles.single.isWholeDocument, isTrue);
    expect(draft.attachedFiles.single.selectionKind, 'all');
  });

  testWidgets(
    'text selection updates payload and highlights each source range',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final draft = _fileStudyDraft(utf8.encode('A😀XBC'));

      await tester.pumpWidget(
        _wizard(
          studyId: studyId,
          draft: draft,
          api: _SelectionStudyApi(),
          progressStore: store,
        ),
      );
      await tester.pumpAndSettle();
      await _openFileSelector(tester);

      var selectable = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      selectable.onSelectionChanged!(
        const TextSelection(baseOffset: 1, extentOffset: 3),
        SelectionChangedCause.longPress,
      );
      await tester.pump();
      expect(draft.attachedFiles.single.selectionSpec, isEmpty);
      selectable.onSelectionChanged!(
        const TextSelection.collapsed(offset: 3),
        SelectionChangedCause.tap,
      );
      await tester.pump();
      await _commitSelectedText(tester);
      expect(draft.attachedFiles.single.selectionSpec, 'p1:1-3');
      expect(draft.attachedFiles.single.selectionKind, 'passages');
      expect(
        StudySelection.passage(
          draft.attachedFiles.single.selectionSpec,
          'A😀XBC',
        ),
        'p1:1-3',
      );

      selectable = tester.widget<SelectableText>(find.byType(SelectableText));
      selectable.onSelectionChanged!(
        const TextSelection(baseOffset: 5, extentOffset: 6),
        SelectionChangedCause.longPress,
      );
      await tester.pump();
      await _commitSelectedText(tester);
      expect(draft.attachedFiles.single.selectionSpec, 'p1:1-3,p1:5-6');

      final spans = tester
          .widget<SelectableText>(find.byType(SelectableText))
          .textSpan!
          .children!
          .whereType<TextSpan>()
          .where((span) => span.style?.backgroundColor != null)
          .toList();
      expect(spans.map((span) => span.text), ['😀', 'C']);
    },
  );

  testWidgets(
    'drag updates replace the transient range and keep separate selections',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await store.clear(studyId);
      addTearDown(() => store.clear(studyId));
      final draft = QuizWizardData()..currentStep = 1;
      final file = AttachedFile(
        bytes: utf8.encode('abcdefghij'),
        name: 'notes.txt',
        kind: 'txt',
        isWholeDocument: false,
        selectionKind: 'passages',
        selectionSpec: 'p1:1-5,p1:7-9',
      );
      draft.addFile(file);

      await tester.pumpWidget(
        _wizard(
          studyId: studyId,
          draft: draft,
          api: _SelectionStudyApi(),
          progressStore: store,
        ),
      );
      await tester.pumpAndSettle();
      await _openFileSelector(tester);

      var selectable = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      selectable.onSelectionChanged!(
        const TextSelection(baseOffset: 1, extentOffset: 5),
        SelectionChangedCause.longPress,
      );
      await tester.pump();
      selectable = tester.widget<SelectableText>(find.byType(SelectableText));
      selectable.onSelectionChanged!(
        const TextSelection(baseOffset: 1, extentOffset: 3),
        SelectionChangedCause.drag,
      );
      await tester.pump();
      expect(file.selectionSpec, 'p1:1-5,p1:7-9');
      await _commitSelectedText(tester);

      expect(file.selectionSpec, 'p1:1-3,p1:7-9');
      selectable = tester.widget<SelectableText>(find.byType(SelectableText));
      selectable.onSelectionChanged!(
        const TextSelection(baseOffset: 4, extentOffset: 6),
        SelectionChangedCause.longPress,
      );
      await tester.pump();
      await _commitSelectedText(tester);
      expect(file.selectionSpec, 'p1:1-3,p1:4-6,p1:7-9');
      final highlighted = tester
          .widget<SelectableText>(find.byType(SelectableText))
          .textSpan!
          .children!
          .whereType<TextSpan>()
          .where((span) => span.style?.backgroundColor != null);
      expect(highlighted.map((span) => span.text), ['bc', 'ef', 'hi']);
    },
  );

  testWidgets('failed owner study read does not hydrate local ranges', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await store.clear(studyId);
    addTearDown(() => store.clear(studyId));
    final bytes = utf8.encode(text);
    await store.saveSourceSelections(studyId, [
      DraftSourceSelection(
        contentDigest: StudySelection.contentDigest(bytes, kind: 'txt'),
        kind: 'passages',
        spec: selectedSpec,
      ),
    ]);
    final draft = _fileStudyDraft(bytes);

    await tester.pumpWidget(
      _wizard(
        studyId: studyId,
        draft: draft,
        api: _SelectionStudyApi(failGet: true),
        progressStore: store,
      ),
    );
    await tester.pumpAndSettle();
    await _openFileSelector(tester);

    expect(find.byType(GranularRangeSelector), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(draft.attachedFiles.single.isWholeDocument, isTrue);
    expect(draft.attachedFiles.single.selectionKind, 'all');
  });

  testWidgets('late owner read never replaces a reselect edit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await store.clear(studyId);
    addTearDown(() => store.clear(studyId));
    final bytes = utf8.encode(text);
    await store.saveSourceSelections(studyId, [
      DraftSourceSelection(
        contentDigest: StudySelection.contentDigest(bytes, kind: 'txt'),
        kind: 'passages',
        spec: selectedSpec,
      ),
    ]);
    final draft = _fileStudyDraft(bytes);
    final pendingGet = Completer<Study>();

    await tester.pumpWidget(
      _wizard(
        studyId: studyId,
        draft: draft,
        api: _SelectionStudyApi(pendingGet: pendingGet),
        progressStore: store,
      ),
    );
    await tester.pumpAndSettle();
    await _openFileSelector(tester);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'p1:5-9');
    await tester.pump();
    pendingGet.complete(_study(studyId));
    await tester.pumpAndSettle();

    expect(draft.attachedFiles.single.selectionSpec, 'p1:5-9');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'p1:5-9',
    );
    final saved = await store.getSourceSelections(studyId);
    expect(saved, hasLength(1));
    expect(saved.single.spec, 'p1:5-9');
  });

  testWidgets('a previous draft read cannot restore into a switched draft', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const oldId = 'old-selection-study';
    const newId = 'new-selection-study';
    await store.clear(oldId);
    await store.clear(newId);
    addTearDown(() async {
      await store.clear(oldId);
      await store.clear(newId);
    });
    final bytes = utf8.encode(text);
    final digest = StudySelection.contentDigest(bytes, kind: 'txt');
    await store.saveSourceSelections(oldId, [
      DraftSourceSelection(
        contentDigest: digest,
        kind: 'passages',
        spec: 'p1:0-5',
      ),
    ]);
    await store.saveSourceSelections(newId, [
      DraftSourceSelection(
        contentDigest: digest,
        kind: 'passages',
        spec: 'p1:5-9',
      ),
    ]);
    final draft = _fileStudyDraft(bytes);
    final api = _SwitchingSelectionStudyApi();

    await tester.pumpWidget(
      _wizard(studyId: oldId, draft: draft, api: api, progressStore: store),
    );
    await tester.pump();
    await tester.pumpWidget(
      _wizard(studyId: newId, draft: draft, api: api, progressStore: store),
    );
    await tester.pumpAndSettle();

    api.oldStudyRead.complete(_study(oldId));
    await tester.pumpAndSettle();
    await _openFileSelector(tester);

    expect(draft.attachedFiles.single.selectionSpec, 'p1:5-9');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'p1:5-9',
    );
    expect(await store.getSourceSelections(oldId), hasLength(1));
    expect((await store.getSourceSelections(newId)).single.spec, 'p1:5-9');
  });
}
