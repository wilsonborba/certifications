import 'dart:convert';

import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/models/generation.dart';
import 'package:certifications/domain/services/generation_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> _jobJson({String status = 'queued'}) => {
  'id': 'job-1',
  'study_id': 'study-1',
  'quiz_id': null,
  'status': status,
  'language': 'pt-BR',
  'requested_count': 10,
  'queue_position': 2,
  'saved_count': 0,
  'stop_requested': false,
  'error_code': '',
  'queued_at': 1760000000,
  'started_at': null,
  'finished_at': null,
};

void main() {
  test('start uses the durable generation request DTO exactly', () async {
    late http.Request seen;
    final client = MockClient((request) async {
      seen = request;
      return http.Response(jsonEncode(_jobJson()), 201);
    });
    final service = GenerationApiService(
      adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
    );

    final job = await service.start(
      'study-1',
      const StartGenerationRequest(
        language: 'pt-BR',
        count: 10,
        idempotencyKey: 'stable-key',
      ),
    );

    expect(job.id, 'job-1');
    expect(seen.method, 'POST');
    expect(
      seen.url.path,
      '/apps/certifications/v1/studies/study-1/generations',
    );
    expect(jsonDecode(seen.body), {
      'language': 'pt-BR',
      'count': 10,
      'idempotency_key': 'stable-key',
    });
  });

  test('estimate keeps unavailable values null and uses server timing', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(
        request.url.path,
        '/apps/certifications/v1/studies/study-1/estimate',
      );
      expect(request.url.queryParameters, {'language': 'th', 'count': '5'});
      return http.Response(
        '{"status":"unavailable","estimated_processing_ms":null,"sample_count":0,"queue_ahead_count":1,"source":"none"}',
        200,
      );
    });
    final service = GenerationApiService(
      adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
    );

    final unavailable = await service.estimate(
      studyId: 'study-1',
      language: 'th',
      count: 5,
    );

    expect(unavailable.isAvailable, isFalse);
    expect(unavailable.estimatedProcessingMs, isNull);
    expect(unavailable.source, 'none');
  });

  test('progress events consume the real GET event stream', () async {
    late http.Request seen;
    final client = MockClient((request) async {
      seen = request;
      return http.Response(
        'id: 3\nevent: language_correction\ndata: {"seq":3,"event_type":"language_correction","message":"Correcting language","created_at":1760000003}\n\n',
        200,
        headers: const {'content-type': 'text/event-stream'},
      );
    });
    final service = GenerationApiService(
      adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
    );

    final events = await service.events(jobId: 'job-1', after: 2);

    expect(seen.method, 'GET');
    expect(seen.url.path, '/apps/certifications/v1/generations/job-1/events');
    expect(seen.url.queryParameters, {'after': '2'});
    expect(events.single.eventType, 'language_correction');
    expect(events.single.seq, 3);
  });

  test(
    'stop acts on the current job and resume returns the new queue job',
    () async {
      final methods = <(String, String)>[];
      final client = MockClient((request) async {
        methods.add((request.method, request.url.path));
        return http.Response(
          jsonEncode(_jobJson(status: 'queued')),
          request.url.path.endsWith('/resume') ? 201 : 200,
        );
      });
      final service = GenerationApiService(
        adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
      );

      await service.stop('job-1');
      await service.resume('job-1');

      expect(methods, [
        ('POST', '/apps/certifications/v1/generations/job-1/stop'),
        ('POST', '/apps/certifications/v1/generations/job-1/resume'),
      ]);
    },
  );

  test(
    'resume parses the backend error envelope for an unknown Cortex outcome',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.path,
          '/apps/certifications/v1/generations/job-1/resume',
        );
        return http.Response(
          jsonEncode({
            'error': 'cannot_resume_unknown_cortex_outcome',
            'message': 'Cortex may already have accepted this request',
          }),
          409,
        );
      });
      final service = GenerationApiService(
        adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
      );

      await expectLater(
        service.resume('job-1'),
        throwsA(
          isA<GenerationApiException>()
              .having((error) => error.statusCode, 'statusCode', 409)
              .having(
                (error) => error.code,
                'code',
                'cannot_resume_unknown_cortex_outcome',
              )
              .having(
                (error) => error.message,
                'message',
                'Cortex may already have accepted this request',
              ),
        ),
      );
    },
  );
}
