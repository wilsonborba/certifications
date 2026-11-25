import 'dart:async';
import 'dart:convert';

import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/models/generation.dart';
import 'package:certifications/domain/models/quiz_wizard_data.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:certifications/domain/services/draft_progress_store.dart';
import 'package:certifications/domain/services/generation_api_service.dart';
import 'package:certifications/domain/services/study_api_service.dart';
import 'package:certifications/presentation/widgets/quiz_wizard/on_quiz_wizard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _GenerationFixture extends GenerationApiService {
  int startCalls = 0;
  StartGenerationRequest? request;
  bool holdResponse = false;
  final Completer<GenerationJob> response = Completer<GenerationJob>();

  @override
  Future<GenerationJob> start(
    String studyId,
    StartGenerationRequest input,
  ) async {
    startCalls++;
    request = input;
    final job = GenerationJob(
      id: 'job-config',
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
    return holdResponse ? response.future : Future.value(job);
  }
}

Map<String, dynamic> _studyDetail({String language = 'th', int count = 7}) => {
  'study': {
    'id': 'prepared-study',
    'title': 'Prepared physics',
    'description': '',
    'source_origin': 'annotations',
    'status': 'draft',
    'quiz_id': '',
    'expires_at': 1760003600,
    'created_at': 1760000000,
    'updated_at': 1760000000,
  },
  'sources': [
    {
      'id': 'source-1',
      'filename': 'notes.pdf',
      'mime_type': 'application/pdf',
      'size_bytes': 12,
      'sha256': 'fixture-sha',
      'fsm_ref': '',
      'source_kind': 'prepared',
      'status': 'ready',
      'selection_kind': 'all',
      'selection_spec': '',
      'is_restricted': false,
      'external_ref': '',
      'created_at': 1760000000,
      'updated_at': 1760000000,
    },
  ],
  'quota': {
    'used_bytes': 12,
    'reserved_bytes': 0,
    'max_file_bytes': 1024,
    'max_study_bytes': 2048,
    'max_account_bytes': 4096,
    'remaining_account_bytes': 4084,
  },
  'config': {'language': language, 'count': count},
};

void main() {
  test('prepared study config parses strictly from detail GET shape', () {
    final config = Study.fromJson(_studyDetail()).preparedConfig!;
    expect(config.language, 'th');
    expect(config.count, 7);
    expect(
      Study.fromJson({
        'study': {'id': 'manual'},
      }).preparedConfig,
      isNull,
    );
    for (final invalid in [
      {'language': 'pt', 'count': 5},
      {'language': 'en', 'count': 0},
      {'language': 'en', 'count': 21},
      {'language': 'th', 'count': 1.5},
    ]) {
      expect(
        () => Study.fromJson({..._studyDetail(), 'config': invalid}),
        throwsFormatException,
      );
    }
  });

  testWidgets(
    'GET config preselects the wizard; edits persist and generation is explicit',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      void expectNoPendingFlutterError(String stage) {
        final error = tester.takeException();
        expect(error, isNull, reason: '$stage: $error');
      }

      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/studies/prepared-study'));
        return http.Response(jsonEncode(_studyDetail()), 200);
      });
      final studyApi = StudyApiService(
        adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
      );
      final generationApi = _GenerationFixture();
      const studyId = 'prepared-study';
      final progress = DraftProgressStore.instance;
      addTearDown(() async {
        await progress.clear(studyId);
        client.close();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await progress.clear(studyId);
      final draft = QuizWizardData()..currentStep = 2;

      await tester.pumpWidget(
        MaterialApp(
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
            initialStep: 2,
            draft: draft,
            onGenerate: () {},
            apiService: studyApi,
            generationApi: generationApi,
            progressStore: progress,
          ),
          routes: {
            '/v1/generations/job-config': (_) =>
                const Scaffold(body: Text('generation started')),
          },
        ),
      );
      await tester.pumpAndSettle();
      expectNoPendingFlutterError('loaded prepared study');

      expect(requests, hasLength(1));
      expect(find.text('ไทย'), findsOneWidget);
      expect(find.text('Number of questions: 7'), findsOneWidget);
      expect(generationApi.startCalls, 0);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      expectNoPendingFlutterError('opened language menu');
      await tester.tap(find.text('Português (Brasil)').last);
      await tester.pumpAndSettle();
      expectNoPendingFlutterError('selected generation language');
      final slider = tester.widget<Slider>(find.byType(Slider));
      slider.onChanged!(17);
      await tester.pumpAndSettle();
      expectNoPendingFlutterError('changed question count');
      expect(draft.generationLanguage, 'pt-BR');
      expect(draft.questionCount, 17);
      expect(find.text('Number of questions: 17'), findsOneWidget);
      expect(generationApi.startCalls, 0);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expectNoPendingFlutterError('opened review step');
      expect(find.textContaining('17 questions'), findsOneWidget);
      expect(find.text('Português (Brasil)'), findsOneWidget);
      expect(generationApi.startCalls, 0);

      final generateButton = find.text('Generate Quiz Now');
      await tester.ensureVisible(generateButton);
      generationApi.holdResponse = true;
      await tester.tap(generateButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expectNoPendingFlutterError('started explicit generation');
      expect(generationApi.startCalls, 1);
      generationApi.response.complete(
        GenerationJob(
          id: 'job-config',
          studyId: studyId,
          status: 'queued',
          language: 'pt-BR',
          requestedCount: 17,
          queuePosition: 0,
          savedCount: 0,
          stopRequested: false,
          errorCode: '',
          queuedAt: 1760000000,
        ),
      );
      await tester.pumpAndSettle();
      expect(generationApi.startCalls, 1);
      expect(generationApi.request?.language, 'pt-BR');
      expect(generationApi.request?.count, 17);
      expect(find.text('generation started'), findsOneWidget);
    },
  );
}
