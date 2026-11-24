import 'dart:convert';

import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/models/attempt.dart';
import 'package:certifications/domain/services/attempt_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> _attemptJson() => {
  'id': 'attempt-1',
  'quiz_id': 'quiz-1',
  'quiz_version_id': 'quiz-version-4',
  'status': 'in_progress',
  'started_at': 1760000000,
  'completed_at': null,
  'monitoring_notice': 'Observable browser focus and visibility events.',
  'questions': [
    {
      'question_id': 'question-1',
      'question_version_id': 'question-version-2',
      'language': 'en',
      'origin': 'creator',
      'prompt': 'Choose one.',
      'alternatives': [
        {'id': 'option-a', 'text': 'A'},
        {'id': 'option-b', 'text': 'B'},
      ],
      'selected_option_id': 'option-b',
      // These untrusted extras must not be exposed by the taking model.
      'correct_id': 'option-a',
      'explanation': 'Private until submission',
      'citation_ref': 'private upload marker',
    },
  ],
};

void main() {
  test('taking model keeps saved answer but exposes no grading fields', () {
    final view = AttemptView.fromJson(_attemptJson());

    expect(view.id, 'attempt-1');
    expect(view.questions.single.selectedOptionId, 'option-b');
    expect(view.questions.single.prompt, 'Choose one.');
    expect(view.questions.single.toString(), isNot(contains('Private until')));
    expect(view.questions.single.toString(), isNot(contains('private upload')));
  });

  test(
    'resume, answer save, and activity use their actual Rust DTOs',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return switch (request.url.path) {
          '/apps/certifications/v1/attempts/attempt-1' => http.Response(
            jsonEncode(_attemptJson()),
            200,
          ),
          '/apps/certifications/v1/attempts/attempt-1/answers/question-1' =>
            http.Response('{"saved":true}', 200),
          '/apps/certifications/v1/attempts/attempt-1/events' => http.Response(
            '{"inserted":1}',
            200,
          ),
          _ => http.Response('{}', 404),
        };
      });
      final service = AttemptApiService(
        adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
      );

      final resumed = await service.getAttempt('attempt-1');
      await service.saveAnswer(
        attemptId: resumed.id,
        questionId: resumed.questions.single.questionId,
        selectedOptionId: 'option-b',
      );
      final inserted = await service.recordActivityEvents(
        attemptId: resumed.id,
        events: const [
          AttemptActivityEvent(
            eventKind: 'page_hidden',
            dedupKey: 'attempt-1:hidden:1',
            occurredAt: 1760000001,
          ),
        ],
      );

      expect(inserted, 1);
      expect(requests.map((request) => request.method), ['GET', 'PUT', 'POST']);
      expect(requests.map((request) => request.url.path), [
        '/apps/certifications/v1/attempts/attempt-1',
        '/apps/certifications/v1/attempts/attempt-1/answers/question-1',
        '/apps/certifications/v1/attempts/attempt-1/events',
      ]);
      expect(jsonDecode(requests[1].body), {'selected_option_id': 'option-b'});
      expect(jsonDecode(requests[2].body), {
        'events': [
          {
            'dedup_key': 'attempt-1:hidden:1',
            'event_kind': 'page_hidden',
            'duration_ms': 0,
            'occurred_at': 1760000001,
          },
        ],
      });
    },
  );

  test('only explicit start operation creates an attempt', () async {
    late http.Request seen;
    final client = MockClient((request) async {
      seen = request;
      return http.Response(jsonEncode(_attemptJson()), 201);
    });
    final service = AttemptApiService(
      adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
    );

    final started = await service.startAttempt('quiz-1');

    expect(started.id, 'attempt-1');
    expect(seen.method, 'POST');
    expect(seen.url.path, '/apps/certifications/v1/quizzes/quiz-1/attempts');
  });
}
