import 'dart:async';

import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/quiz_wizard_data.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:certifications/domain/services/draft_progress_store.dart';
import 'package:certifications/domain/services/study_api_service.dart';
import 'package:certifications/presentation/widgets/quiz_wizard/on_quiz_wizard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _AnalysisStudyApi extends StudyApiService {
  _AnalysisStudyApi({required this.waitForAbort, this.includeReport = false});

  final bool waitForAbort;
  final bool includeReport;
  final started = Completer<void>();
  bool lateEventSent = false;

  @override
  Future<Study> get(String id) async => Study.fromJson({
    'study': {'id': id, 'title': 'Inspection fixture', 'status': 'draft'},
    'sources': [],
    'quota': {
      'used_bytes': 0,
      'max_account_bytes': 1000,
      'max_file_bytes': 1000,
      'max_study_bytes': 1000,
      'remaining_account_bytes': 1000,
    },
  });

  @override
  Future<void> streamAnalysis(
    String studyId, {
    required void Function(StudyAnalysisEvent event) onEvent,
    Future<void>? abortTrigger,
  }) async {
    if (waitForAbort) {
      onEvent(
        const StudyAnalysisEvent('stage', {'stage': 'preparing_sources'}),
      );
      started.complete();
      await abortTrigger;
      lateEventSent = true;
      onEvent(
        const StudyAnalysisEvent('source_inspected', {
          'stage': 'inspecting_source',
          'source_id': 'late-source',
          'source_kind': 'upload',
          'mime_type': 'application/pdf',
          'page_count': 1,
        }),
      );
      return;
    }

    onEvent(const StudyAnalysisEvent('stage', {'stage': 'preparing_sources'}));
    onEvent(
      const StudyAnalysisEvent('source_inspected', {
        'stage': 'inspecting_source',
        'source_id': 'pdf-source',
        'source_kind': 'upload',
        'mime_type': 'application/pdf',
        'page_count': null,
        'text_char_count': null,
        'duration_seconds': null,
      }),
    );
    if (includeReport) {
      onEvent(
        const StudyAnalysisEvent('source_inspected', {
          'stage': 'inspecting_source',
          'source_id': 'report-source',
          'source_kind': 'report',
          'mime_type': 'application/json',
          'page_count': null,
          'text_char_count': 21,
          'duration_seconds': null,
        }),
      );
    }
    onEvent(
      const StudyAnalysisEvent('source_inspected', {
        'stage': 'inspecting_source',
        'source_id': 'pdf-known-source',
        'source_kind': 'upload',
        'mime_type': 'application/pdf',
        'page_count': 3,
        'text_char_count': null,
        'duration_seconds': null,
      }),
    );
    onEvent(
      const StudyAnalysisEvent('source_inspected', {
        'stage': 'inspecting_source',
        'source_id': 'text-source',
        'source_kind': 'upload',
        'mime_type': 'text/plain',
        'page_count': null,
        'text_char_count': 0,
        'duration_seconds': null,
      }),
    );
    onEvent(
      const StudyAnalysisEvent('source_inspected', {
        'stage': 'inspecting_source',
        'source_id': 'wav-source',
        'source_kind': 'upload',
        'mime_type': 'audio/wav',
        'page_count': null,
        'text_char_count': null,
        'duration_seconds': 2.5,
      }),
    );
    onEvent(
      const StudyAnalysisEvent('source_inspected', {
        'stage': 'inspecting_source',
        'source_id': 'wav-alias-source',
        'source_kind': 'upload',
        'mime_type': 'audio/x-wav',
        'page_count': null,
        'text_char_count': null,
        'duration_seconds': 1.25,
      }),
    );
    onEvent(
      const StudyAnalysisEvent('source_inspected', {
        'stage': 'inspecting_source',
        'source_id': 'image-source',
        'source_kind': 'upload',
        'mime_type': 'image/png',
        'page_count': null,
        'text_char_count': null,
        'duration_seconds': null,
      }),
    );
    onEvent(
      StudyAnalysisEvent('complete', {
        'stage': 'ready',
        'inspected_sources': includeReport ? 7 : 6,
        'total_ready_sources': includeReport ? 7 : 6,
      }),
    );
  }
}

QuizWizardData _draft() => QuizWizardData()
  ..name = 'Inspection fixture'
  ..currentStep = 3;

Widget _app({required _AnalysisStudyApi api, required Locale locale}) =>
    MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        FallbackCupertinoLocalizationsDelegate(),
        FallbackMaterialLocalizationsDelegate(),
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: OnQuizWizardScreen(
        studyId: 'inspection-study',
        initialStep: 3,
        draft: _draft(),
        onGenerate: () {},
        apiService: api,
        progressStore: DraftProgressStore.instance,
      ),
    );

Future<void> _inspect(WidgetTester tester, Locale locale) async {
  final button = find.text(AppLocalizations(locale).text('inspectSources'));
  await tester.ensureVisible(button);
  await tester.pump();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _clearInspectionProgress(WidgetTester tester) async {
  const studyId = 'inspection-study';
  final store = DraftProgressStore.instance;
  await store.clear(studyId);
  addTearDown(() => store.clear(studyId));
}

void main() {
  for (final testCase in [
    (
      locale: const Locale('en'),
      includeReport: false,
      expected: [
        'Inspected 6 source(s).',
        'PDF pages: 3 measured; 1 source(s) unknown',
        'Text/Reports characters: 0',
        'WAV duration: 3.75 seconds',
      ],
    ),
    (
      locale: const Locale('pt', 'BR'),
      includeReport: true,
      expected: [
        '7 fonte(s) inspecionada(s).',
        'Páginas do PDF: 3 medido(s); 1 fonte(s) desconhecida(s)',
        'Caracteres de texto/Reports: 21',
        'Duração do WAV: 3,75 segundos',
      ],
    ),
    (
      locale: const Locale('th'),
      includeReport: false,
      expected: [
        'ตรวจสอบแล้ว 6 แหล่ง',
        'หน้า PDF: วัดได้ 3; ไม่ทราบอีก 1 แหล่ง',
        'อักขระข้อความ/Reports: 0',
        'ระยะเวลา WAV: 3.75 วินาที',
      ],
    ),
  ]) {
    testWidgets('analysis summary preserves values in ${testCase.locale}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _clearInspectionProgress(tester);
      final api = _AnalysisStudyApi(
        waitForAbort: false,
        includeReport: testCase.includeReport,
      );
      await tester.pumpWidget(_app(api: api, locale: testCase.locale));
      await tester.pumpAndSettle();
      await _inspect(tester, testCase.locale);

      for (final text in testCase.expected) {
        expect(find.textContaining(text), findsOneWidget, reason: text);
      }
      expect(find.textContaining('Image'), findsNothing);
      expect(find.textContaining('0 pages'), findsNothing);
      expect(
        find.text(AppLocalizations(testCase.locale).text('generateQuizNow')),
        findsOneWidget,
      );
    });
  }

  testWidgets('pushing a route aborts inspection and ignores late events', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _clearInspectionProgress(tester);
    final api = _AnalysisStudyApi(waitForAbort: true);
    await tester.pumpWidget(_app(api: api, locale: const Locale('en')));
    await tester.pumpAndSettle();
    final button = find.text(
      AppLocalizations(const Locale('en')).text('inspectSources'),
    );
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();
    await api.started.future;

    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('covered route')),
          ),
        );
    await tester.pumpAndSettle();

    expect(api.lateEventSent, isTrue);
    expect(find.text('covered route'), findsOneWidget);
    expect(find.textContaining('PDF pages:'), findsNothing);
  });
}
