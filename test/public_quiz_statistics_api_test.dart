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
          'typical_duration_sec': null,
          'basis': 'all_completed_attempts',
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
  });

  test('public statistics retain the server denominator basis', () async {
    final client = MockClient((_) async {
      return http.Response(
        jsonEncode({
          'quiz_id': 'quiz-2',
          'completed_attempt_count': 3,
          'distinct_participants': 2,
          'average_score_pct': 66.6667,
          'typical_duration_sec': 120,
          'basis': 'all_completed_attempts',
        }),
        200,
      );
    });
    final service = PublicQuizStatisticsApiService(
      adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
    );

    final stats = await service.getForQuiz('quiz-2');

    expect(stats.hasCompletedAttempts, isTrue);
    expect(stats.completedAttemptCount, 3);
    expect(stats.distinctParticipants, 2);
    expect(stats.averageScorePct, 66.6667);
    expect(stats.basis, 'all_completed_attempts');
  });
}
