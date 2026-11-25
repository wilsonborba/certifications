/// Public aggregate returned by GET /quizzes/{id}/statistics.
/// Nullable averages stay unavailable for empty data; counts are not scores.
class PublicQuizStatistics {
  const PublicQuizStatistics({
    required this.quizId,
    required this.completedAttemptCount,
    required this.distinctParticipants,
    required this.averageScorePct,
    required this.typicalDurationSec,
    required this.durationDenominator,
    required this.basis,
    required this.averageScoreDenominator,
    required this.scoreDistributionDenominator,
    required this.scoreDistribution,
    required this.scoreDistributionReportView,
    required this.questionProvenance,
  });

  final String quizId;
  final int completedAttemptCount;
  final int distinctParticipants;
  final double? averageScorePct;
  final int? typicalDurationSec;
  final int durationDenominator;
  final String basis;
  final int averageScoreDenominator;
  final int scoreDistributionDenominator;
  final List<ScoreDistributionBand> scoreDistribution;
  final Map<String, dynamic> scoreDistributionReportView;
  final Map<String, dynamic> questionProvenance;

  bool get hasCompletedAttempts => completedAttemptCount > 0;

  factory PublicQuizStatistics.fromJson(Map<String, dynamic> json) =>
      PublicQuizStatistics(
        quizId: json['quiz_id'] as String,
        completedAttemptCount: (json['completed_attempt_count'] as num).toInt(),
        distinctParticipants: (json['distinct_participants'] as num).toInt(),
        averageScorePct: (json['average_score_pct'] as num?)?.toDouble(),
        typicalDurationSec: (json['typical_duration_sec'] as num?)?.toInt(),
        durationDenominator: (json['duration_denominator'] as num).toInt(),
        basis: json['basis'] as String,
        averageScoreDenominator: (json['average_score_denominator'] as num)
            .toInt(),
        scoreDistributionDenominator:
            (json['score_distribution_denominator'] as num).toInt(),
        scoreDistribution: (json['score_distribution'] as List<dynamic>)
            .map(
              (item) =>
                  ScoreDistributionBand.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false),
        scoreDistributionReportView:
            json['score_distribution_report_view'] as Map<String, dynamic>,
        questionProvenance: json['question_provenance'] as Map<String, dynamic>,
      );

  ScoreDistributionTemplate? get scoreDistributionTemplate =>
      ScoreDistributionTemplate.tryParse(scoreDistributionReportView);
}

/// The Reports VisualTemplate v1 descriptor supplied by the statistics API.
/// Keep the descriptor and binding paired; a binding alone is not enough to
/// select or construct a chart.
class ScoreDistributionTemplate {
  const ScoreDistributionTemplate({
    required this.title,
    required this.bucketField,
    required this.attemptsField,
  });

  final String title;
  final String bucketField;
  final String attemptsField;

  static ScoreDistributionTemplate? tryParse(Map<String, dynamic> reportView) {
    final definition = reportView['template_definition'];
    final binding = reportView['visual'];
    if (definition is! Map || binding is! Map) return null;
    final descriptor = definition.cast<String, dynamic>();
    final visual = binding.cast<String, dynamic>();
    final slots = descriptor['slots'];
    final mapping = visual['mapping'];
    if (descriptor['template_id'] != 'cert-score-distribution' ||
        descriptor['version'] != 1 ||
        descriptor['kind'] != 'chart' ||
        descriptor['visual'] != 'bar' ||
        visual['template'] != 'cert-score-distribution' ||
        visual['version'] != 1 ||
        descriptor['title'] is! String ||
        slots is! List ||
        mapping is! Map) {
      return null;
    }
    final slotsByName = <String, Map<String, dynamic>>{};
    for (final rawSlot in slots) {
      if (rawSlot is Map && rawSlot['slot_name'] is String) {
        slotsByName[rawSlot['slot_name'] as String] = rawSlot
            .cast<String, dynamic>();
      }
    }
    final bucket = slotsByName['bucket'];
    final attempts = slotsByName['attempts'];
    final mapped = mapping.cast<String, dynamic>();
    final bucketFields = mapped['bucket'];
    final attemptFields = mapped['attempts'];
    if (bucket == null ||
        attempts == null ||
        bucket['role'] != 'dimension' ||
        attempts['role'] != 'measure' ||
        bucket['is_required'] != true ||
        attempts['is_required'] != true ||
        bucketFields is! List ||
        bucketFields.length != 1 ||
        bucketFields.single != 'score_band' ||
        attemptFields is! List ||
        attemptFields.isEmpty ||
        attemptFields.any((field) => field != 'attempt_count')) {
      return null;
    }
    return ScoreDistributionTemplate(
      title: descriptor['title'] as String,
      bucketField: bucketFields.single as String,
      attemptsField: attemptFields.first as String,
    );
  }
}

class ScoreDistributionBand {
  const ScoreDistributionBand({required this.label, required this.count});

  final String label;
  final int count;

  factory ScoreDistributionBand.fromJson(Map<String, dynamic> json) =>
      ScoreDistributionBand(
        label: json['score_band'] as String,
        count: (json['attempt_count'] as num).toInt(),
      );
}
