import 'dart:convert';

import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/services/public_quiz_statistics_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('empty public statistics preserve unavailable values', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.headers['accept-language'], 'en');
      expect(
        request.url.path,
        '/apps/certifications/v1/quizzes/quiz-1/statistics',
      );
      return http.Response(
        jsonEncode({
          'quiz_id': 'quiz-1',
          'completed_attempt_count': 0,
          'distinct_participants': 0,
          'average_score_pct': null,
          'average_score_denominator': 0,
          'typical_duration_sec': null,
          'duration_denominator': 0,
          'basis': 'all_completed_attempts',
          'score_distribution_denominator': 0,
          'score_distribution': [],
          'question_provenance': {},
          'score_distribution_report_view': {
            'descriptor': {
              'dataset_id': 'cert:quiz:quiz-1:score-distribution',
              'title': 'Quiz score distribution',
              'description': 'Completed attempt scores by percentage band',
              'equation': null,
              'fields': [
                {'name': 'score_band', 'type': 'string', 'role': 'dimension'},
                {'name': 'attempt_count', 'type': 'integer', 'role': 'measure'},
              ],
              'filters': [],
              'data_tier': 'live',
              'can_view': true,
              'visibility': 'public',
              'meta': {'language': 'en'},
            },
            'rows': [],
            'offset': 0,
            'limit': 3,
            'total_rows': 0,
            'visual': {
              'template': 'cert-score-distribution',
              'version': 1,
              'mapping': {
                'bucket': ['score_band'],
                'attempts': ['attempt_count'],
              },
              'options': {},
            },
          },
        }),
        200,
      );
    });
    final service = PublicQuizStatisticsApiService(
      adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
    );

    final stats = await service.getForQuiz('quiz-1');

    expect(stats.completedAttemptCount, 0);
    expect(stats.distinctParticipants, 0);
    expect(stats.averageScorePct, isNull);
    expect(stats.typicalDurationSec, isNull);
    expect(stats.hasCompletedAttempts, isFalse);
    expect(stats.basis, 'all_completed_attempts');
    expect(stats.durationDenominator, 0);
    expect(stats.scoreDistributionReportView['total_rows'], 0);
  });

  test('public statistics retain the server denominator basis', () async {
    final client = MockClient((request) async {
      expect(request.headers['accept-language'], 'pt-BR');
      return http.Response(
        jsonEncode({
          'quiz_id': 'quiz-2',
          'completed_attempt_count': 3,
          'distinct_participants': 2,
          'average_score_pct': 66.6667,
          'average_score_denominator': 3,
          'typical_duration_sec': 120,
          'duration_denominator': 3,
          'basis': 'all_completed_attempts',
          'score_distribution_denominator': 3,
          'score_distribution': [
            {'score_band': '0-49%', 'attempt_count': 1},
            {'score_band': '50-79%', 'attempt_count': 1},
            {'score_band': '80-100%', 'attempt_count': 1},
          ],
          'question_provenance': {
            'combined': {'attempt_count': 0},
          },
          'score_distribution_report_view': {
            'descriptor': {'dataset_id': 'cert:quiz:quiz-2:score-distribution'},
            'rows': [
              {'score_band': '0-49%', 'attempt_count': 1},
              {'score_band': '50-79%', 'attempt_count': 1},
              {'score_band': '80-100%', 'attempt_count': 1},
            ],
            'offset': 0,
            'limit': 3,
            'total_rows': 3,
            'visual': {
              'template': 'cert-score-distribution',
              'version': 1,
              'mapping': {
                'bucket': ['score_band'],
                'attempts': ['attempt_count'],
              },
              'options': {},
            },
          },
        }),
        200,
      );
    });
    final service = PublicQuizStatisticsApiService(
      adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
    );

    final stats = await service.getForQuiz('quiz-2', language: 'pt');

    expect(stats.hasCompletedAttempts, isTrue);
    expect(stats.completedAttemptCount, 3);
    expect(stats.distinctParticipants, 2);
    expect(stats.averageScorePct, 66.6667);
    expect(stats.scoreDistributionDenominator, 3);
    expect(stats.scoreDistribution.map((band) => band.count), [1, 1, 1]);
    expect(stats.basis, 'all_completed_attempts');
  });
}
