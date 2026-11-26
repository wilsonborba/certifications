import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/models/generation.dart';
import 'package:certifications/domain/models/quiz_wizard_data.dart';
import 'package:certifications/domain/services/draft_progress_store.dart';
import 'package:certifications/domain/services/generation_api_service.dart';
import 'package:certifications/domain/services/study_api_service.dart';
import 'package:certifications/presentation/widgets/quiz_wizard/on_quiz_wizard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _ResumeGenerationApi extends GenerationApiService {
  final getJobIds = <String>[];
  int startCalls = 0;

  GenerationJob _job(String id) => GenerationJob(
    id: id,
    studyId: 'resume-study-fixture',
    status: 'running',
    language: 'en',
    requestedCount: 10,
    queuePosition: 0,
    savedCount: 0,
    stopRequested: false,
    errorCode: '',
    queuedAt: 1760000000,
    startedAt: 1760000001,
  );

  @override
  Future<GenerationJob> get(String jobId) async {
    getJobIds.add(jobId);
    return _job(jobId);
  }

  @override
  Future<GenerationEstimate> estimate({
    required String studyId,
    required String language,
    required int count,
  }) async => const GenerationEstimate(
    status: 'unavailable',
    sampleCount: 0,
    queueAheadCount: 0,
    source: 'none',
  );

  @override
  Future<List<GenerationEvent>> events({
    required String jobId,
    int after = 0,
  }) async => [];

  @override
  Future<GenerationJob> stop(String jobId) async => _job(jobId);

  @override
  Future<GenerationJob> resume(String jobId) async => _job('resumed-job');

  @override
  Future<GenerationJob> start(
    String studyId,
    StartGenerationRequest input,
  ) async {
    startCalls++;
    return _job('new-job');
  }
}

void main() {
  testWidgets('returning to the wizard reopens the saved job without POSTing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const studyId = 'resume-study-fixture';
    const jobId = 'saved-job-fixture';
    final store = DraftProgressStore.instance;
    await store.clear(studyId);
    await store.saveGenerationJobId(studyId, jobId);
    final generationApi = _ResumeGenerationApi();
    final studyClient = MockClient(
      (request) async => http.Response('not used', 404),
    );
    final studyApi = StudyApiService(
      adapter: ApiAdapter(client: studyClient, csrfTokenProvider: () => null),
    );
    final draft = QuizWizardData()
      ..name = 'Saved study'
      ..currentStep = 3
      ..addFile(
        AttachedFile(bytes: const [1], name: 'fixture.pdf', kind: 'pdf'),
      );

    await tester.pumpWidget(
      MaterialApp(
        home: OnQuizWizardScreen(
          studyId: studyId,
          initialStep: 3,
          onGenerate: () {},
          apiService: studyApi,
          generationApi: generationApi,
          progressStore: store,
          draft: draft,
        ),
        routes: {
          '/v1/generations/$jobId': (_) =>
              const Scaffold(body: Text('saved job route')),
        },
      ),
    );
    await tester.pumpAndSettle();
    final generateButton = find.text('Generate Quiz Now');
    await tester.ensureVisible(generateButton);
    await tester.pumpAndSettle();
    await tester.tap(generateButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(generationApi.getJobIds, [jobId]);
    expect(generationApi.startCalls, 0);
    expect(find.text('saved job route'), findsOneWidget);
    expect(await store.getGenerationJobId(studyId), jobId);

    await store.clear(studyId);
    studyClient.close();
  });
}
