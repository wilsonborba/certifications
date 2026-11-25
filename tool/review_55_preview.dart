import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/core/utils/my_theme.dart';
import 'package:certifications/domain/models/generation.dart';
import 'package:certifications/domain/services/generation_api_service.dart';
import 'package:certifications/presentation/widgets/generation_progress_screen.dart';
import 'package:flutter/material.dart';

class _FixtureGenerationApi extends GenerationApiService {
  _FixtureGenerationApi(this.status);

  final String status;
  static final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  GenerationJob _job(String value, {String id = 'fixture-job'}) =>
      GenerationJob(
        id: id,
        studyId: 'fixture-study',
        status: value,
        language: 'en',
        requestedCount: 10,
        queuePosition: value == 'queued' ? 3 : 0,
        savedCount: value == 'running' ? 2 : 0,
        stopRequested: value == 'stop_requested',
        errorCode: value == 'failed' ? 'processing_failed' : '',
        queuedAt: now - 145,
        startedAt: value == 'queued' ? null : now - 62,
        finishedAt: value == 'completed' || value == 'failed' ? now - 4 : null,
      );

  @override
  Future<GenerationJob> get(String jobId) async => _job(status, id: jobId);

  @override
  Future<GenerationEstimate> estimate({
    required String studyId,
    required String language,
    required int count,
  }) async => const GenerationEstimate(
    status: 'available',
    estimatedProcessingMs: 78000,
    sampleCount: 18,
    queueAheadCount: 2,
    source: 'completed_jobs',
  );

  @override
  Future<List<GenerationEvent>> events({
    required String jobId,
    int after = 0,
  }) async => [
    GenerationEvent(
      seq: 1,
      eventType: 'queued',
      message: 'Queued at position 3',
      createdAt: now - 145,
    ),
    if (status != 'queued')
      GenerationEvent(
        seq: 2,
        eventType: 'running',
        message: 'Processing started',
        createdAt: now - 62,
      ),
  ].where((event) => event.seq > after).toList();

  @override
  Future<GenerationJob> stop(String jobId) async => _job('cancelled');

  @override
  Future<GenerationJob> resume(String jobId) async =>
      _job('queued', id: 'fixture-resumed-job');

  @override
  Future<GenerationJob> start(
    String studyId,
    StartGenerationRequest input,
  ) async => _job('queued');
}

void main() {
  final query = Uri.base.queryParameters;
  final locale = Locale(query['locale'] ?? 'en');
  final isDark = query['mode'] == 'dark';
  final status = query['status'] ?? 'queued';

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        FallbackMaterialLocalizationsDelegate(),
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      home: GenerationProgressScreen(
        jobId: 'fixture-job',
        api: _FixtureGenerationApi(status),
      ),
    ),
  );
}
