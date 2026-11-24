import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/core/utils/my_theme.dart';
import 'package:certifications/domain/models/generation.dart';
import 'package:certifications/domain/services/generation_api_service.dart';
import 'package:certifications/presentation/widgets/generation_progress_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixtureGenerationApi implements GenerationApiService {
  _FixtureGenerationApi(
    this.status, {
    this.failEvents = false,
    this.failEstimate = false,
  });
  String status;
  String currentJobId = 'job-1';
  final requestedJobIds = <String>[];
  int stopCalls = 0;
  int resumeCalls = 0;
  final bool failEvents;
  final bool failEstimate;

  GenerationJob _job(String value) => GenerationJob(
    id: currentJobId,
    studyId: 'study-1',
    status: value,
    language: 'en',
    requestedCount: 10,
    queuePosition: value == 'queued' ? 2 : 0,
    savedCount: 4,
    stopRequested: false,
    errorCode: '',
    queuedAt: 1760000000,
    startedAt: value == 'queued' ? null : 1760000060,
    finishedAt: value == 'completed' ? 1760000100 : null,
  );

  @override
  Future<GenerationJob> get(String jobId) async {
    requestedJobIds.add(jobId);
    return _job(status);
  }

  @override
  Future<GenerationEstimate> estimate({
    required String studyId,
    required String language,
    required int count,
  }) async {
    if (failEstimate) throw const FormatException('estimate unavailable');
    return const GenerationEstimate(
      status: 'unavailable',
      sampleCount: 0,
      queueAheadCount: 0,
      source: 'none',
    );
  }

  @override
  Future<List<GenerationEvent>> events({
    required String jobId,
    int after = 0,
  }) async {
    if (failEvents) throw const FormatException('events unavailable');
    return [
      GenerationEvent(
        seq: 1,
        eventType: status,
        message: 'Internal fixture message',
        createdAt: 1760000100,
      ),
    ];
  }

  @override
  Future<GenerationJob> stop(String jobId) async {
    stopCalls++;
    status = 'cancelled';
    return _job(status);
  }

  @override
  Future<GenerationJob> resume(String jobId) async {
    resumeCalls++;
    status = 'queued';
    currentJobId = 'job-2';
    return _job(status);
  }

  @override
  Future<GenerationJob> start(
    String studyId,
    StartGenerationRequest input,
  ) async => _job('queued');
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required String status,
  required Size size,
  GenerationApiService? api,
  bool failEvents = false,
  bool failEstimate = false,
}) async {
  final resolvedApi =
      api ??
      _FixtureGenerationApi(
        status,
        failEvents: failEvents,
        failEstimate: failEstimate,
      );
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        FallbackMaterialLocalizationsDelegate(),
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      routes: {
        '/v1/generations/job-2': (_) =>
            GenerationProgressScreen(jobId: 'job-2', api: resolvedApi),
      },
      home: GenerationProgressScreen(jobId: 'job-1', api: resolvedApi),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('phone progress fits, hides raw events and offers safe stop', (
    tester,
  ) async {
    await _pumpScreen(tester, status: 'running', size: const Size(390, 844));
    expect(find.text('Generating questions'), findsWidgets);
    expect(find.text('Stop safely'), findsOneWidget);
    expect(find.text('Internal fixture message'), findsNothing);
    expect(tester.getRect(find.byType(Card)).right, lessThanOrEqualTo(390));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'job remains visible when timeline and estimate are unavailable',
    (tester) async {
      await _pumpScreen(
        tester,
        status: 'running',
        size: const Size(390, 844),
        failEvents: true,
        failEstimate: true,
      );
      expect(find.text('Generating questions'), findsWidgets);
      expect(find.text('Progress events are not available.'), findsOneWidget);
      expect(
        find.text('No measured estimate is available yet'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('completed job has no stop action and uses terminal stage', (
    tester,
  ) async {
    await _pumpScreen(tester, status: 'completed', size: const Size(1300, 860));
    expect(find.text('Generation completed'), findsWidgets);
    expect(find.text('Stop safely'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('queued job shows server queue position without a fake percent', (
    tester,
  ) async {
    final api = _FixtureGenerationApi('queued');
    await _pumpScreen(
      tester,
      status: 'queued',
      size: const Size(390, 844),
      api: api,
    );

    expect(find.text('Queue position'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    expect(find.text('Stop safely'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('safe stop then continue requests a fresh job and queue slot', (
    tester,
  ) async {
    final api = _FixtureGenerationApi('running');
    await _pumpScreen(
      tester,
      status: 'running',
      size: const Size(390, 844),
      api: api,
    );

    await tester.tap(find.text('Stop safely'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(api.stopCalls, 1);
    expect(find.text('Generation stopped'), findsWidgets);
    expect(find.text('Continue generation'), findsOneWidget);

    await tester.tap(find.text('Continue generation'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));
    expect(api.resumeCalls, 1);
    expect(api.requestedJobIds, contains('job-2'));
    expect(find.text('Queue position'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
