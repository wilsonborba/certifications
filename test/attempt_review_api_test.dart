import 'dart:convert';

import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/services/attempt_review_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'history sends only the confirmed filters and bounded page fields',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/apps/certifications/v1/attempts');
        expect(request.url.queryParameters, {
          'q': 'cell',
          'started_from': '100',
          'started_to': '200',
          'quiz_id': 'quiz/a',
          'tag': 'biology',
          'limit': '10',
          'offset': '20',
        });
        return http.Response(
          jsonEncode({
            'items': [
              {
                'id': 'a-1',
                'quiz_id': 'quiz/a',
                'quiz_title': 'Cells',
                'quiz_origin': 'supplied_by_creator',
                'quiz_version_id': 'v-1',
                'attempt_sequence': 2,
                'status': 'completed',
                'score_correct': 1,
                'score_total': 3,
                'previous_attempt_score_pct': 0,
                'score_change_percentage_points': 33.3333,
                'started_at': 150,
                'completed_at': 160,
              },
            ],
            'total': 21,
            'limit': 10,
            'offset': 20,
          }),
          200,
        );
      });
      final api = AttemptReviewApiService(
        adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
      );
      final page = await api.listAttempts(
        const AttemptHistoryQuery(
          q: 'cell',
          startedFrom: 100,
          startedTo: 200,
          quizId: 'quiz/a',
          tag: 'biology',
          limit: 10,
          offset: 20,
        ),
      );
      expect(page.total, 21);
      expect(page.items.single.scorePct, closeTo(100 / 3, 0.001));
      expect(page.items.single.previousAttemptScorePct, 0);
    },
  );

  test(
    'overview retains independent denominators and nullable means',
    () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/apps/certifications/v1/attempts/overview');
        return http.Response(
          jsonEncode({
            'created_quiz_count': 2,
            'completed_attempt_count': 0,
            'distinct_quizzes_attempted': 0,
            'all_attempt_mean_score_pct': null,
            'all_attempt_score_denominator': 0,
            'latest_attempt_per_quiz_mean_score_pct': null,
            'latest_attempt_per_quiz_score_denominator': 0,
            'average_completion_time_seconds': null,
            'completion_time_denominator': 0,
            'question_provenance': {
              'combined': {
                'attempt_count': 0,
                'question_count': 0,
                'correct_question_count': 0,
                'correct_percentage': null,
              },
            },
          }),
          200,
        );
      });
      final api = AttemptReviewApiService(
        adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
      );
      final overview = await api.getOverview();
      expect(overview.createdQuizCount, 2);
      expect(overview.allAttemptMeanScorePct, isNull);
      expect(overview.allAttemptScoreDenominator, 0);
    },
  );

  test('results require the completed result DTO fields', () async {
    final client = MockClient((request) async {
      expect(
        request.url.path,
        '/apps/certifications/v1/attempts/a%2Fb/results',
      );
      return http.Response(
        jsonEncode({
          'id': 'a/b',
          'quiz_id': 'q1',
          'quiz_version_id': 'v1',
          'status': 'completed',
          'score_correct': 1,
          'score_total': 3,
          'started_at': 10,
          'completed_at': 20,
          'stats': {
            'overall': {'correct': 1, 'total': 3, 'percentage': 33.3},
          },
          'activity_summary': {'completeness': 'partial', 'events': []},
          'questions': [
            {
              'question_id': 'qn1',
              'question_version_id': 'qv1',
              'language': 'en',
              'origin': 'supplied_by_creator',
              'prompt': 'Question',
              'alternatives': [
                {'id': 'x', 'text': 'X'},
              ],
              'selected_option_id': 'x',
              'correct_id': 'y',
              'is_correct': false,
              'explanation': null,
              'citation_ref': null,
            },
          ],
        }),
        200,
      );
    });
    final api = AttemptReviewApiService(
      adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
    );
    final result = await api.getResults('a/b');
    expect(result.scorePct, closeTo(100 / 3, 0.001));
    expect(result.questions.single.isCorrect, isFalse);
    expect(result.questions.single.correctId, 'y');
  });
}
