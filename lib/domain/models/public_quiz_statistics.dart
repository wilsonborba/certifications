/// Public aggregate returned by GET /quizzes/{id}/statistics.
/// Nullable averages stay unavailable for empty data; counts are not scores.
class PublicQuizStatistics {
  const PublicQuizStatistics({
    required this.quizId,
    required this.completedAttemptCount,
    required this.distinctParticipants,
    required this.averageScorePct,
    required this.typicalDurationSec,
    required this.basis,
  });

  final String quizId;
  final int completedAttemptCount;
  final int distinctParticipants;
  final double? averageScorePct;
  final int? typicalDurationSec;
  final String basis;

  bool get hasCompletedAttempts => completedAttemptCount > 0;

  factory PublicQuizStatistics.fromJson(Map<String, dynamic> json) =>
      PublicQuizStatistics(
        quizId: json['quiz_id'] as String,
        completedAttemptCount: (json['completed_attempt_count'] as num).toInt(),
        distinctParticipants: (json['distinct_participants'] as num).toInt(),
        averageScorePct: (json['average_score_pct'] as num?)?.toDouble(),
        typicalDurationSec: (json['typical_duration_sec'] as num?)?.toInt(),
        basis: json['basis'] as String,
      );
}
