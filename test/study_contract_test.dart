import 'dart:async';
import 'dart:convert';

import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/models/quiz_wizard_data.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:certifications/domain/models/study_selection.dart';
import 'package:certifications/domain/services/study_api_service.dart';
import 'package:certifications/presentation/components/quiz/granular_range_selector.dart';
import 'package:certifications/presentation/widgets/quiz_wizard/on_quiz_wizard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _EventStreamClient extends http.BaseClient {
  _EventStreamClient(this.body, this.onRequest);

  final String body;
  final void Function(http.BaseRequest request) onRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    onRequest(request);
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(body)),
      200,
      headers: const {'content-type': 'text/event-stream'},
    );
  }
}

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

  test(
    'Reports picker and attachment use the exact selected dataset contract',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.method == 'GET' &&
            request.url.path.endsWith('/reports/picker')) {
          if (request.url.queryParameters.isEmpty) {
            return http.Response(
              jsonEncode({
                'items': [
                  {
                    'project': 'proj1',
                    'report': 'rep1',
                    'title': 'Quarterly',
                    'is_restricted': false,
                  },
                ],
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'project': 'proj1',
                  'report': 'rep1',
                  'dataset': {
                    'dataset_id': 'data1',
                    'title': 'Counts',
                    'can_view': true,
                    'visibility': 'public',
                  },
                },
                {
                  'project': 'proj1',
                  'report': 'rep1',
                  'dataset': {
                    'dataset_id': 'hidden',
                    'title': 'Hidden',
                    'can_view': false,
                    'visibility': 'restricted',
                  },
                },
              ],
            }),
            200,
          );
        }
        if (request.method == 'POST' &&
            request.url.path.endsWith('/studies/study-1/sources')) {
          return http.Response(
            jsonEncode({
              'id': 'source-report-1',
              'filename': 'Counts',
              'mime_type': 'text/plain',
              'size_bytes': 42,
              'sha256': 'aabb',
              'fsm_ref': '',
              'source_kind': 'report',
              'status': 'ready',
              'selection_kind': 'all',
              'selection_spec': '',
              'is_restricted': false,
              'external_ref': 'proj1/rep1/data1',
              'created_at': 1760000000,
              'updated_at': 1760000000,
            }),
            201,
          );
        }
        return http.Response('unexpected request', 404);
      });
      final service = StudyApiService(
        adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
      );

      final reports = await service.listReports();
      final datasets = await service.listReportDatasets(reports.single);
      final source = await service.attachReportDataset(
        studyId: 'study-1',
        dataset: datasets.single,
      );

      expect(requests[0].method, 'GET');
      expect(requests[0].url.queryParameters, isEmpty);
      expect(requests[1].url.queryParameters, {
        'project': 'proj1',
        'report': 'rep1',
      });
      expect(datasets.map((item) => item.datasetId), ['data1']);
      expect(requests[2].method, 'POST');
      expect(requests[2].url.path, endsWith('/studies/study-1/sources'));
      expect(jsonDecode(requests[2].body), {
        'kind': 'report',
        'filename': 'Counts',
        'external_ref': 'proj1/rep1/data1',
        'is_restricted': false,
      });
      expect(source.sourceKind, 'report');
      expect(source.selectionKind, 'all');
      expect(source.externalRef, 'proj1/rep1/data1');
      client.close();
    },
  );

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
    'binary source upload uses the existing multipart file contract',
    () async {
      final progress = <double>[];
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, endsWith('/studies/study-5/sources'));
        expect(
          request.headers['content-type'],
          startsWith('multipart/form-data;'),
        );
        expect(request.body, contains('name="file"; filename="slides.pdf"'));
        expect(request.body, contains('name="filename"'));
        expect(request.body, contains('slides.pdf'));
        expect(request.body, contains('name="mime_type"'));
        expect(request.body, contains('application/pdf'));
        expect(request.bodyBytes, containsAll([0x25, 0x50, 0x44, 0x46]));
        return http.Response(
          jsonEncode({
            'id': 'source-pdf',
            'filename': 'slides.pdf',
            'mime_type': 'application/pdf',
            'size_bytes': 4,
            'sha256': 'hash',
            'source_kind': 'upload',
            'status': 'ready',
            'selection_kind': 'all',
            'selection_spec': '',
          }),
          201,
        );
      });
      final service = StudyApiService(
        adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
      );

      final source = await service.upload(
        studyId: 'study-5',
        filename: 'slides.pdf',
        bytes: [0x25, 0x50, 0x44, 0x46],
        mimeType: 'application/pdf',
        onProgress: progress.add,
      );

      expect(source.id, 'source-pdf');
      expect(progress, [1]);
      client.close();
    },
  );

  test(
    'analysis stream parses the published stage and source metadata events',
    () async {
      final abortTrigger = Completer<void>();
      final client = _EventStreamClient(
        'event: stage\ndata: {"study_id":"study-6","stage":"preparing_sources","total_sources":1,"ready_sources":1,"total_bytes":8,"estimate_status":"available","estimated_processing_ms":500}\n\n'
        'event: source_inspected\ndata: {"stage":"inspecting_source","source_id":"source-6","source_kind":"upload","mime_type":"text/plain","selection_kind":"all","selection_spec":"","size_bytes":8,"page_count":null,"duration_seconds":null,"text_char_count":8,"elapsed_ms":2}\n\n'
        'event: complete\ndata: {"study_id":"study-6","stage":"ready","inspected_sources":1,"total_ready_sources":1}\n\n',
        (request) {
          expect(request.method, 'POST');
          expect(request, isA<http.Abortable>());
          expect(
            (request as http.Abortable).abortTrigger,
            same(abortTrigger.future),
          );
          expect(
            request.url.path,
            endsWith('/studies/study-6/analysis/stream'),
          );
          expect(request.headers['accept'], 'text/event-stream');
          expect((request as http.Request).body, isEmpty);
        },
      );
      final service = StudyApiService(
        adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
      );
      final events = <StudyAnalysisEvent>[];

      await service.streamAnalysis(
        'study-6',
        onEvent: events.add,
        abortTrigger: abortTrigger.future,
      );

      expect(events.map((event) => event.name), [
        'stage',
        'source_inspected',
        'complete',
      ]);
      expect(events.first.data['estimated_processing_ms'], 500);
      expect(events[1].data['page_count'], isNull);
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

  test('selection strings enforce the accepted canonical bounds and units', () {
    expect(StudySelection.pages('1-3,5', pageCount: 5), '1-3,5');
    expect(StudySelection.pages('1-50,51-100', pageCount: 100), '1-50,51-100');
    expect(StudySelection.pages('1-50,51-101', pageCount: 101), isNull);
    expect(StudySelection.pages('1-3,3-5', pageCount: 5), isNull);
    expect(
      StudySelection.audio('ms:0-12500,30000-45000'),
      'ms:0-12500,30000-45000',
    );
    expect(StudySelection.audio('ms:0-10,10-20'), 'ms:0-20');
    expect(StudySelection.audio('ms:0-10,11-20'), 'ms:0-10,11-20');
    expect(StudySelection.audio('ms:0-10,11-5'), isNull);
    expect(StudySelection.audio('ms:0-10,10-5'), isNull);
    expect(StudySelection.audio('ms:0-10,10-10'), isNull);
    expect(StudySelection.audio('ms:0-10,9-20'), isNull);
    expect(StudySelection.audio('ms:0-100,ms:200-300'), isNull);
    expect(StudySelection.audio('ms:300-400,0-100'), isNull);
    expect(StudySelection.passage('p1:0-4', 'A😀B'), 'p1:0-4');
    expect(StudySelection.passage('p1:0-5', 'A😀B'), isNull);
    expect(StudySelection.passage('p1:1-1', 'abc'), isNull);
    expect(
      StudySelection.passage('p1:0-4,p1:4-5', '\uFEFFA\r\n😀B'),
      'p1:0-4,p1:4-5',
    );
    expect(StudySelection.passage('p1:0-4,4-5', 'ABCDE'), isNull);
    expect(StudySelection.passage('p1:0-6', '\uFEFFA\r\n😀B'), isNull);
    final tooManyPageRanges = List.generate(
      65,
      (i) => '${i * 2 + 1}',
    ).join(',');
    expect(StudySelection.pages(tooManyPageRanges, pageCount: 200), isNull);
    final tooManyAudioRanges = List.generate(
      65,
      (i) => '${i * 20}-${i * 20 + 10}',
    ).join(',');
    expect(StudySelection.audio('ms:$tooManyAudioRanges'), isNull);
  });

  testWidgets('text source selector exposes validated UTF-16 range controls', (
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
    expect(find.byType(SelectableText), findsOneWidget);
    final wholeSource = find.byType(CheckboxListTile);
    expect(wholeSource, findsOneWidget);
    await tester.tap(wholeSource);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(
      find.text('Enter a valid selection within this source.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'p1:0-10');
    await tester.pumpAndSettle();
    expect(
      find.text('Enter a valid selection within this source.'),
      findsNothing,
    );
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
      expect(copy.text('sourceStorageNotice'), isNotEmpty);
      expect(copy.text('sourcePreviewTitle'), isNotEmpty);
      expect(copy.text('narrowSelectionUnavailable'), isNotEmpty);
      expect(copy.text('reportsSourceLabel'), isNotEmpty);
      expect(copy.text('reportPickerLabel'), isNotEmpty);
      expect(copy.text('reportDatasetLabel'), isNotEmpty);
    }
    expect(AppLocalizations(const Locale('xx')).text('newStudy'), isNotEmpty);
  });
}
