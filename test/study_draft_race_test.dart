import 'dart:async';

import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/generation.dart';
import 'package:certifications/domain/models/quiz_wizard_data.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:certifications/domain/services/draft_progress_store.dart';
import 'package:certifications/domain/services/generation_api_service.dart';
import 'package:certifications/domain/services/study_api_service.dart';
import 'package:certifications/presentation/widgets/quiz_wizard/on_quiz_wizard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _GatedStudyApi extends StudyApiService {
  final Completer<Study> createResponse = Completer<Study>();
  int createCalls = 0;

  @override
  Future<Study> create(String name) {
    createCalls++;
    return createResponse.future;
  }

  @override
  Future<List<ReportPickerItem>> listReports() async => const [];

  @override
  Future<StudySource> upload({
    required String studyId,
    required String filename,
    required List<int> bytes,
    required String mimeType,
    void Function(double progress)? onProgress,
  }) async => StudySource.fromJson({
    'id': 'source-uploaded',
    'filename': filename,
    'mime_type': mimeType,
    'size_bytes': bytes.length,
    'source_kind': 'upload',
    'status': 'ready',
    'selection_kind': 'all',
  });

  @override
  Future<Study> get(String id) async => Study.fromJson({
    'study': {'id': id, 'title': 'Race study', 'status': 'draft'},
    'sources': [
      {
        'id': 'source-uploaded',
        'filename': 'notes.txt',
        'mime_type': 'text/plain',
        'size_bytes': 4,
        'source_kind': 'upload',
        'status': 'ready',
        'selection_kind': 'all',
      },
    ],
    'quota': {
      'used_bytes': 4,
      'max_account_bytes': 1000,
      'max_file_bytes': 1000,
      'max_study_bytes': 1000,
      'remaining_account_bytes': 996,
    },
  });
}

class _GenerationFixture extends GenerationApiService {
  int startCalls = 0;
  final studyIds = <String>[];

  @override
  Future<GenerationJob> start(
    String studyId,
    StartGenerationRequest input,
  ) async {
    startCalls++;
    studyIds.add(studyId);
    return GenerationJob(
      id: 'race-job',
      studyId: studyId,
      status: 'queued',
      language: input.language,
      requestedCount: input.count,
      queuePosition: 0,
      savedCount: 0,
      stopRequested: false,
      errorCode: '',
      queuedAt: 1760000000,
    );
  }
}

Study _study(String id) => Study.fromJson({
  'study': {'id': id, 'title': 'Race study', 'status': 'draft'},
  'sources': [],
  'quota': {
    'used_bytes': 0,
    'max_account_bytes': 1000,
    'max_file_bytes': 1000,
    'max_study_bytes': 1000,
    'remaining_account_bytes': 1000,
  },
});

QuizWizardData _draft() => QuizWizardData()
  ..name = 'Race study'
  ..currentStep = 1
  ..addFile(AttachedFile(bytes: [1, 2, 3, 4], name: 'notes.txt', kind: 'txt'));

Widget _wizard({
  required _GatedStudyApi studyApi,
  required _GenerationFixture generationApi,
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
    draft: _draft(),
    onGenerate: () {},
    apiService: studyApi,
    generationApi: generationApi,
    progressStore: progressStore,
  ),
  routes: {
    '/v1/generations/race-job': (_) =>
        const Scaffold(body: Text('generation opened')),
  },
);

Future<void> _advanceToGenerate(WidgetTester tester) async {
  final next = find.text('Next');
  await tester.ensureVisible(next);
  await tester.pump();
  await tester.tap(next);
  await tester.pump(const Duration(milliseconds: 400));
  await tester.ensureVisible(next);
  await tester.pump();
  await tester.tap(next);
  await tester.pump(const Duration(milliseconds: 400));
  final generate = find.text('Generate Quiz Now');
  await tester.ensureVisible(generate);
  await tester.tap(generate);
  await tester.pump();
}

void main() {
  testWidgets('Start joins the pending Step 2 draft creation', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final studyApi = _GatedStudyApi();
    final generationApi = _GenerationFixture();
    final progressStore = DraftProgressStore.instance;
    await progressStore.clear('draft-race-study');
    addTearDown(() async {
      if (!studyApi.createResponse.isCompleted) {
        studyApi.createResponse.complete(_study('teardown-draft'));
      }
      await progressStore.clear('draft-race-study');
    });
    await tester.pumpWidget(
      _wizard(
        studyApi: studyApi,
        generationApi: generationApi,
        progressStore: progressStore,
      ),
    );
    await tester.pump();
    expect(studyApi.createCalls, 1, reason: 'Step 2 prepares its draft');

    await _advanceToGenerate(tester);
    expect(studyApi.createCalls, 1, reason: 'Start must join the same draft');
    studyApi.createResponse.complete(_study('single-draft'));
    await tester.pumpAndSettle();

    expect(studyApi.createCalls, 1);
    expect(generationApi.startCalls, 1);
    expect(generationApi.studyIds, ['single-draft']);
    expect(find.text('generation opened'), findsOneWidget);
  });

  testWidgets('late draft creation after leaving wizard starts no generation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final studyApi = _GatedStudyApi();
    final generationApi = _GenerationFixture();
    final progressStore = DraftProgressStore.instance;
    await progressStore.clear('draft-race-study');
    addTearDown(() async {
      if (!studyApi.createResponse.isCompleted) {
        studyApi.createResponse.complete(_study('teardown-draft'));
      }
      await progressStore.clear('draft-race-study');
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => OnQuizWizardScreen(
                  draft: _draft(),
                  onGenerate: () {},
                  apiService: studyApi,
                  generationApi: generationApi,
                  progressStore: progressStore,
                ),
              ),
            ),
            child: const Text('Open wizard'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open wizard'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(studyApi.createCalls, 1);

    await _advanceToGenerate(tester);
    expect(studyApi.createCalls, 1, reason: 'Start must share Step 2 draft');
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    studyApi.createResponse.complete(_study('late-draft'));
    await tester.pumpAndSettle();

    expect(generationApi.startCalls, 0);
    expect(tester.takeException(), isNull);
  });
}
