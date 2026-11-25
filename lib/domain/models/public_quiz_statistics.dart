import 'package:reports_view/reports_view.dart';

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

  ScoreDistributionReportView? get scoreDistributionView =>
      ScoreDistributionReportView.tryParse(
        scoreDistributionReportView,
        scoreDistribution,
        scoreDistributionDenominator,
      );
}

/// The exact backend report page and its published template and binding.
/// A missing or malformed component disables chart rendering.
class ScoreDistributionReportView {
  const ScoreDistributionReportView({
    required this.page,
    required this.template,
    required this.binding,
  });

  final DatasetPage page;
  final VisualTemplate template;
  final CardVisualBinding binding;

  static ScoreDistributionReportView? tryParse(
    Map<String, dynamic> value,
    List<ScoreDistributionBand> bands,
    int denominator,
  ) {
    final rawDescriptor = value['descriptor'];
    final rawTemplate = value['template_definition'];
    final rawBinding = value['visual'];
    if (rawDescriptor is! Map || rawTemplate is! Map || rawBinding is! Map) {
      return null;
    }
    final descriptor = Map<String, dynamic>.from(rawDescriptor);
    final rawRows = value['rows'];
    if (descriptor['dataset_id'] is! String || rawRows is! List) return null;
    final pageJson = <String, dynamic>{
      ...descriptor,
      'rows': rawRows,
      'offset': value['offset'],
      'limit': value['limit'],
      'total_rows': value['total_rows'],
      'visual': rawBinding,
    };
    try {
      final page = DatasetPage.fromJson(pageJson);
      final template = VisualTemplate.fromJson(
        Map<String, dynamic>.from(rawTemplate),
      );
      final binding = CardVisualBinding.fromJson(
        Map<String, dynamic>.from(rawBinding),
      );
      if (template.templateId != 'cert-score-distribution' ||
          template.version != 1 ||
          template.kind != 'chart' ||
          template.visual != 'bar' ||
          binding.template != template.templateId ||
          binding.version != template.version) {
        return null;
      }
      final bucketFields = binding.mapping['bucket'];
      final countFields = binding.mapping['attempts'];
      if (bucketFields?.length != 1 ||
          countFields?.length != 1 ||
          bucketFields!.single != 'score_band' ||
          countFields!.single != 'attempt_count' ||
          page.offset != 0 ||
          page.totalRows != bands.length ||
          page.rows.length != bands.length ||
          denominator != bands.fold<int>(0, (sum, band) => sum + band.count) ||
          !TemplateValidator.validate(
            template,
            binding,
            page.descriptor,
          ).isValid) {
        return null;
      }
      for (var index = 0; index < bands.length; index++) {
        final row = page.rows[index];
        if (row['score_band'] != bands[index].label ||
            row['attempt_count'] is! num ||
            (row['attempt_count'] as num).toInt() != bands[index].count) {
          return null;
        }
      }
      return ScoreDistributionReportView(
        page: page,
        template: template,
        binding: binding,
      );
    } on Object {
      return null;
    }
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
