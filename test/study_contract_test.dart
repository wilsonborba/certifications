import 'dart:convert';

import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/models/quiz_wizard_data.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:certifications/domain/services/study_api_service.dart';
import 'package:certifications/presentation/components/quiz/granular_range_selector.dart';
import 'package:certifications/presentation/widgets/quiz_wizard/on_quiz_wizard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('study detail parses the Rust study, source, and quota contract', () {
    final study = Study.fromJson({
      'study': {
        'id': 'study-1',
        'title': 'Physics',
        'description': 'Mechanics',
        'source_origin': 'manual',
        'status': 'draft',
        'quiz_id': 'quiz-1',
        'expires_at': 1760000000,
        'created_at': 1759990000,
        'updated_at': 1759990001,
      },
      'sources': [
        {
          'id': 'source-1',
          'filename': 'notes.pdf',
          'mime_type': 'application/pdf',
          'size_bytes': 1024,
          'sha256': 'abc',
          'fsm_ref': 'certifications/user/source-1',
          'source_kind': 'upload',
          'status': 'ready',
          'selection_kind': 'pages',
          'selection_spec': '1-2',
          'is_restricted': false,
          'external_ref': '',
        },
      ],
      'quota': {
        'used_bytes': 345,
        'reserved_bytes': 55,
        'max_file_bytes': 800,
        'max_study_bytes': 1600,
        'max_account_bytes': 1000,
        'remaining_account_bytes': 600,
      },
    });

    expect(study.id, 'study-1');
    expect(study.name, 'Physics');
    expect(study.sources.single.sourceKind, 'upload');
    expect(study.sources.single.selectionKind, 'pages');
    expect(study.sources.single.selectionSpec, '1-2');
    expect(study.activeSizeBytes, 1024);
    expect(study.accountUsedBytes, 400);
    expect(study.accountMaxBytes, 1000);
    expect(study.maxFileBytes, 800);
    expect(study.maxStudyBytes, 1600);
    expect(study.remainingAccountBytes, 600);
    expect(
      study.createdAt,
      DateTime.fromMillisecondsSinceEpoch(1759990000000, isUtc: true),
    );
  });

  test('study summaries keep detail-only usage unavailable', () {
    final summary = Study.fromJson({
      'id': 'study-2',
      'title': 'Biology',
      'description': '',
      'source_origin': 'manual',
      'status': 'draft',
      'quiz_id': 'quiz-2',
      'expires_at': null,
      'created_at': 1760000000,
      'updated_at': 1760000001,
    });
    expect(summary.name, 'Biology');
    expect(summary.accountUsedBytes, isNull);
    expect(summary.accountMaxBytes, isNull);
    expect(summary.activeSizeBytes, isNull);
  });

  test('create uses title and loads the authoritative detail quota', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.method == 'POST' && request.url.path.endsWith('/studies')) {
        return http.Response(
          jsonEncode({
            'id': 'study-3',
            'title': 'Chemistry',
            'description': '',
            'source_origin': 'manual',
            'status': 'draft',
            'quiz_id': 'quiz-3',
            'expires_at': null,
            'created_at': 1760000000,
            'updated_at': 1760000000,
          }),
          201,
        );
      }
      if (request.method == 'GET' &&
          request.url.path.endsWith('/studies/study-3')) {
        return http.Response(
          jsonEncode({
            'study': {
              'id': 'study-3',
              'title': 'Chemistry',
              'description': '',
              'source_origin': 'manual',
              'status': 'draft',
              'quiz_id': 'quiz-3',
              'expires_at': null,
              'created_at': 1760000000,
              'updated_at': 1760000000,
            },
            'sources': [],
            'quota': {
              'used_bytes': 300,
              'reserved_bytes': 0,
              'max_file_bytes': 500,
              'max_study_bytes': 900,
              'max_account_bytes': 1200,
              'remaining_account_bytes': 900,
            },
          }),
          200,
        );
      }
      return http.Response('unexpected request', 404);
    });
    final service = StudyApiService(
      adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
    );

    final study = await service.create('Chemistry');

    expect(requests, hasLength(2));
    expect(requests.first.method, 'POST');
    expect(jsonDecode(requests.first.body), {'title': 'Chemistry'});
    expect(study.accountUsedBytes, 300);
    expect(study.maxFileBytes, 500);
    expect(study.accountMaxBytes, 1200);
    client.close();
  });

  test('selection sends Rust kind and spec fields', () async {
    final client = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(
        request.url.path,
        endsWith('/studies/study-4/sources/source-4/selection'),
      );
      expect(jsonDecode(request.body), {'kind': 'all', 'spec': ''});
      return http.Response(
        jsonEncode({
          'id': 'source-4',
          'filename': 'manual.pdf',
          'mime_type': 'application/pdf',
          'size_bytes': 400,
          'sha256': 'abc',
          'fsm_ref': 'ref',
          'source_kind': 'upload',
          'status': 'ready',
          'selection_kind': 'all',
          'selection_spec': '',
          'is_restricted': false,
          'external_ref': '',
        }),
        200,
      );
    });
    final service = StudyApiService(
      adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
    );

    final source = await service.select(
      studyId: 'study-4',
      sourceId: 'source-4',
      kind: 'all',
      spec: '',
    );

    expect(source.selectionKind, 'all');
    expect(source.selectionSpec, isEmpty);
    client.close();
  });

  test('source upload uses the actual JSON text-content contract', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, endsWith('/studies/study-5/sources'));
      expect(request.headers['content-type'], 'application/json');
      expect(jsonDecode(request.body), {
        'filename': 'notes.txt',
        'mime_type': 'text/plain',
        'content_text': 'one\ntwo\n',
      });
      return http.Response(
        jsonEncode({
          'id': 'source-5',
          'filename': 'notes.txt',
          'mime_type': 'text/plain',
          'size_bytes': 9,
          'sha256': 'hash',
          'fsm_ref': 'server-only-ref',
          'source_kind': 'upload',
          'status': 'ready',
          'selection_kind': 'all',
          'selection_spec': '',
          'is_restricted': false,
          'external_ref': '',
          'created_at': 1760000000,
          'updated_at': 1760000000,
        }),
        201,
      );
    });
    final service = StudyApiService(
      adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
    );

    final source = await service.upload(
      studyId: 'study-5',
      filename: 'notes.txt',
      bytes: utf8.encode('\uFEFFone\r\ntwo\r'),
      mimeType: 'text/plain',
    );

    expect(source.id, 'source-5');
    client.close();
  });

  test(
    'binary source upload stays unavailable on the text-only route',
    () async {
      final client = MockClient((request) async {
        fail('Binary source must not be sent to the text upload route');
      });
      final service = StudyApiService(
        adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
      );

      await expectLater(
        service.upload(
          studyId: 'study-5',
          filename: 'slides.pdf',
          bytes: [0x25, 0x50, 0x44, 0x46],
          mimeType: 'application/pdf',
        ),
        throwsUnsupportedError,
      );
      client.close();
    },
  );

  test(
    'analysis stream parses the published stage and source metadata events',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, endsWith('/studies/study-6/analysis/stream'));
        expect(request.headers['accept'], 'text/event-stream');
        expect(request.body, isEmpty);
        return http.Response(
          'event: stage\ndata: {"study_id":"study-6","stage":"preparing_sources","total_sources":1,"ready_sources":1,"total_bytes":8,"estimate_status":"available","estimated_processing_ms":500}\n\n'
          'event: source_inspected\ndata: {"stage":"inspecting_source","source_id":"source-6","source_kind":"upload","mime_type":"text/plain","selection_kind":"all","selection_spec":"","size_bytes":8,"page_count":0,"duration_seconds":null,"text_char_count":8,"elapsed_ms":2}\n\n'
          'event: complete\ndata: {"study_id":"study-6","stage":"ready","inspected_sources":1,"total_ready_sources":1}\n\n',
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      });
      final service = StudyApiService(
        adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
      );
      final events = <StudyAnalysisEvent>[];

      await service.streamAnalysis('study-6', onEvent: events.add);

      expect(events.map((event) => event.name), [
        'stage',
        'source_inspected',
        'complete',
      ]);
      expect(events.first.data['estimated_processing_ms'], 500);
      expect(events[1].data['page_count'], 0);
      expect(events[1].data['text_char_count'], 8);
      expect(events.last.data['total_ready_sources'], 1);
      expect(events.last.data.containsKey('summary'), isFalse);
      client.close();
    },
  );

  test('wizard quota never invents a limit and counts pending files', () {
    final data = QuizWizardData();
    expect(data.wouldExceedAccountQuota(50), isFalse);
    data.attachedFiles.add(
      AttachedFile(bytes: List.filled(5, 0), name: 'notes.txt', kind: 'txt'),
    );
    data.setAccountQuota(usedBytes: 80, maxBytes: 100);
    expect(data.wouldExceedAccountQuota(15), isFalse);
    expect(data.wouldExceedAccountQuota(16), isTrue);
    expect(data.projectedAccountUsageBytes, 85);
    expect(data.wouldExceedFileLimit(500), isFalse);
    data.setAccountQuota(
      usedBytes: 80,
      maxBytes: 100,
      fileLimitBytes: 4,
      studyLimitBytes: 20,
    );
    expect(data.wouldExceedFileLimit(5), isTrue);
    expect(data.wouldExceedStudyQuota(16), isTrue);
    data.dispose();
  });

  testWidgets('narrow source selection stays unavailable without a contract', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          FallbackMaterialLocalizationsDelegate(),
        ],
        home: Scaffold(
          body: GranularRangeSelector(
            file: AttachedFile(
              bytes: utf8.encode('first line\nsecond line'),
              name: 'notes.txt',
              kind: 'txt',
            ),
            isDesktop: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Source preview'), findsOneWidget);
    expect(
      find.textContaining('Narrow selection is unavailable'),
      findsOneWidget,
    );
    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(SegmentedButton<bool>), findsNothing);
  });

  testWidgets('source wizard has no horizontal overflow at phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = MockClient((request) async => http.Response('{}', 404));
    final draft = QuizWizardData()
      ..name = 'Sample study'
      ..currentStep = 1
      ..addFile(
        AttachedFile(
          bytes: utf8.encode('one\ntwo'),
          name: 'notes.txt',
          kind: 'txt',
        ),
      );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          FallbackMaterialLocalizationsDelegate(),
        ],
        home: OnQuizWizardScreen(
          onGenerate: () {},
          studyId: 'study-existing',
          initialStep: 1,
          draft: draft,
          apiService: StudyApiService(
            adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    client.close();
  });

  test('question contract preserves visual discriminators', () {
    final question = StudyQuestion.fromJson({
      'id': 'q1',
      'prompt': 'Formula?',
      'choices': ['A', 'B'],
      'visual': {
        'kind': 'latex',
        'source': 'E=mc^2',
        'description': 'Mass energy',
      },
    });
    expect(question.visual['kind'], 'latex');
    expect(question.choices, hasLength(2));
  });

  test('all application locales contain critical study labels', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final copy = AppLocalizations(locale);
      expect(copy.text('newStudy'), isNotEmpty);
      expect(copy.text('errorGeneric'), isNotEmpty);
      expect(copy.text('generate'), isNotEmpty);
      expect(copy.text('preparedSourcesLabel'), isNotEmpty);
      expect(copy.text('sourcePreviewTitle'), isNotEmpty);
      expect(copy.text('narrowSelectionUnavailable'), isNotEmpty);
    }
    expect(AppLocalizations(const Locale('xx')).text('newStudy'), isNotEmpty);
  });
}
