import 'dart:convert';
import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/generation.dart';
import 'package:certifications/domain/models/quiz_wizard_data.dart';
import 'package:certifications/domain/services/draft_progress_store.dart';
import 'package:certifications/domain/services/generation_api_service.dart';
import 'package:certifications/domain/services/study_api_service.dart';
import 'package:certifications/presentation/widgets/quiz_wizard/on_quiz_wizard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

QuizWizardData _draft() => QuizWizardData()
  ..name = 'Race study'
  ..currentStep = 1
  ..addFile(AttachedFile(bytes: [1, 2, 3, 4], name: 'notes.txt', kind: 'txt'));

Widget _wizard({
  required StudyApiService studyApi,
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
  test('create still rejects an unsuccessful POST', () async {
    var detailReads = 0;
    final client = MockClient((request) async {
      if (request.method == 'POST' && request.url.path.endsWith('/studies')) {
        return http.Response('{"error":"denied"}', 503);
      }
      if (request.method == 'GET' && request.url.path.contains('/studies/')) {
        detailReads++;
      }
      return http.Response('{}', 404);
    });
    addTearDown(client.close);
    final service = StudyApiService(
      adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
    );

    await expectLater(
      service.create('Rejected study'),
      throwsA(isA<StudyApiException>()),
    );
    expect(detailReads, 0);
  });

  testWidgets('definite created draft survives a failed optional detail read', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var posts = 0;
    var detailReads = 0;
    final detailStudyIds = <String>[];
    final client = MockClient((request) async {
      if (request.method == 'POST' && request.url.path.endsWith('/studies')) {
        posts++;
        return http.Response(
          jsonEncode({
            'id': 'definite-draft-$posts',
            'title': 'Race study',
            'status': 'draft',
          }),
          201,
        );
      }
      if (request.method == 'GET' &&
          request.url.path.contains('/studies/definite-draft-')) {
        detailReads++;
        detailStudyIds.add(request.url.path.split('/').last);
        if (detailReads == 1) {
          return http.Response('{"error":"unavailable"}', 503);
        }
        return http.Response(
          jsonEncode({
            'study': {
              'id': request.url.path.split('/').last,
              'title': 'Race study',
              'status': 'draft',
            },
            'sources': [],
          }),
          200,
        );
      }
      if (request.method == 'GET' &&
          request.url.path.endsWith('/reports/picker')) {
        return http.Response('{"items":[]}', 200);
      }
      if (request.method == 'POST' && request.url.path.endsWith('/sources')) {
        return http.Response(
          jsonEncode({
            'id': 'uploaded-source',
            'filename': 'notes.txt',
            'mime_type': 'text/plain',
            'size_bytes': 4,
            'source_kind': 'upload',
            'status': 'ready',
            'selection_kind': 'all',
          }),
          201,
        );
      }
      return http.Response('{}', 404);
    });
    addTearDown(client.close);
    final service = StudyApiService(
      adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
    );
    final generation = _GenerationFixture();
    final store = DraftProgressStore.instance;
    for (final id in ['definite-draft-1', 'definite-draft-2']) {
      await store.clear(id);
      addTearDown(() => store.clear(id));
    }
    await tester.pumpWidget(
      _wizard(
        studyApi: service,
        generationApi: generation,
        progressStore: store,
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(posts, 1, reason: 'Step2 POST has already returned definite201');
    expect(detailReads, 1);
    expect(
      find.textContaining('Account allowance unavailable'),
      findsOneWidget,
      reason: 'A summary fallback must not fabricate quota values',
    );
    await _advanceToGenerate(tester);
    await tester.pumpAndSettle();
    expect(
      posts,
      1,
      reason:
          'A failed detail read must not lose the definitely created draft identity',
    );
    expect(detailStudyIds, ['definite-draft-1', 'definite-draft-1']);
    expect(generation.studyIds, ['definite-draft-1']);
    expect(generation.startCalls, 1);
  });
}
