class AttemptHistoryPage {
  const AttemptHistoryPage({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<AttemptHistoryItem> items;
  final int total;
  final int limit;
  final int offset;

  factory AttemptHistoryPage.fromJson(Map<String, dynamic> json) =>
      AttemptHistoryPage(
        items: (json['items'] as List<dynamic>)
            .map(
              (row) => AttemptHistoryItem.fromJson(row as Map<String, dynamic>),
            )
            .toList(growable: false),
        total: (json['total'] as num).toInt(),
        limit: (json['limit'] as num).toInt(),
        offset: (json['offset'] as num).toInt(),
      );
}

class AttemptHistoryItem {
  const AttemptHistoryItem({
    required this.id,
    required this.quizId,
    required this.quizTitle,
    required this.quizOrigin,
    required this.quizVersionId,
    required this.status,
    required this.startedAt,
    this.attemptSequence,
    this.scoreCorrect,
    this.scoreTotal,
    this.previousAttemptScorePct,
    this.scoreChangePercentagePoints,
    this.completedAt,
  });

  final String id;
  final String quizId;
  final String quizTitle;
  final String quizOrigin;
  final String quizVersionId;
  final String status;
  final int? attemptSequence;
  final int? scoreCorrect;
  final int? scoreTotal;
  final double? previousAttemptScorePct;
  final double? scoreChangePercentagePoints;
  final int startedAt;
  final int? completedAt;

  double? get scorePct =>
      scoreCorrect == null || scoreTotal == null || scoreTotal == 0
      ? null
      : scoreCorrect! * 100 / scoreTotal!;

  factory AttemptHistoryItem.fromJson(Map<String, dynamic> json) =>
      AttemptHistoryItem(
        id: json['id'] as String,
        quizId: json['quiz_id'] as String,
        quizTitle: json['quiz_title'] as String,
        quizOrigin: json['quiz_origin'] as String,
        quizVersionId: json['quiz_version_id'] as String,
        status: json['status'] as String,
        attemptSequence: (json['attempt_sequence'] as num?)?.toInt(),
        scoreCorrect: (json['score_correct'] as num?)?.toInt(),
        scoreTotal: (json['score_total'] as num?)?.toInt(),
        previousAttemptScorePct: (json['previous_attempt_score_pct'] as num?)
            ?.toDouble(),
        scoreChangePercentagePoints:
            (json['score_change_percentage_points'] as num?)?.toDouble(),
        startedAt: (json['started_at'] as num).toInt(),
        completedAt: (json['completed_at'] as num?)?.toInt(),
      );
}

class AttemptResults {
  const AttemptResults({
    required this.id,
    required this.quizId,
    required this.quizVersionId,
    required this.status,
    required this.scoreCorrect,
    required this.scoreTotal,
    required this.startedAt,
    required this.stats,
    required this.activitySummary,
    required this.questions,
    this.completedAt,
  });

  final String id;
  final String quizId;
  final String quizVersionId;
  final String status;
  final int scoreCorrect;
  final int scoreTotal;
  final int startedAt;
  final int? completedAt;
  final Map<String, dynamic> stats;
  final Map<String, dynamic> activitySummary;
  final List<AttemptResultQuestion> questions;

  double? get scorePct =>
      scoreTotal == 0 ? null : scoreCorrect * 100 / scoreTotal;

  factory AttemptResults.fromJson(Map<String, dynamic> json) => AttemptResults(
    id: json['id'] as String,
    quizId: json['quiz_id'] as String,
    quizVersionId: json['quiz_version_id'] as String,
    status: json['status'] as String,
    scoreCorrect: (json['score_correct'] as num).toInt(),
    scoreTotal: (json['score_total'] as num).toInt(),
    startedAt: (json['started_at'] as num).toInt(),
    completedAt: (json['completed_at'] as num?)?.toInt(),
    stats: json['stats'] as Map<String, dynamic>,
    activitySummary: json['activity_summary'] as Map<String, dynamic>,
    questions: (json['questions'] as List<dynamic>)
        .map(
          (row) => AttemptResultQuestion.fromJson(row as Map<String, dynamic>),
        )
        .toList(growable: false),
  );
}

class AttemptResultQuestion {
  const AttemptResultQuestion({
    required this.questionId,
    required this.questionVersionId,
    required this.language,
    required this.origin,
    required this.prompt,
    required this.alternatives,
    required this.isCorrect,
    this.selectedOptionId,
    this.correctId,
    this.explanation,
    this.citationRef,
  });

  final String questionId;
  final String questionVersionId;
  final String language;
  final String origin;
  final String prompt;
  final List<dynamic> alternatives;
  final String? selectedOptionId;
  final String? correctId;
  final bool isCorrect;
  final String? explanation;
  final String? citationRef;

  factory AttemptResultQuestion.fromJson(Map<String, dynamic> json) =>
      AttemptResultQuestion(
        questionId: json['question_id'] as String,
        questionVersionId: json['question_version_id'] as String,
        language: json['language'] as String,
        origin: json['origin'] as String,
        prompt: json['prompt'] as String,
        alternatives: json['alternatives'] as List<dynamic>,
        selectedOptionId: json['selected_option_id'] as String?,
        correctId: json['correct_id'] as String?,
        isCorrect: json['is_correct'] as bool,
        explanation: json['explanation'] as String?,
        citationRef: json['citation_ref'] as String?,
      );
}

class AttemptOverview {
  const AttemptOverview({
    required this.createdQuizCount,
    required this.completedAttemptCount,
    required this.distinctQuizzesAttempted,
    required this.allAttemptMeanScorePct,
    required this.allAttemptScoreDenominator,
    required this.latestAttemptPerQuizMeanScorePct,
    required this.latestAttemptPerQuizScoreDenominator,
    required this.averageCompletionTimeSeconds,
    required this.completionTimeDenominator,
    required this.questionProvenance,
  });

  final int createdQuizCount;
  final int completedAttemptCount;
  final int distinctQuizzesAttempted;
  final double? allAttemptMeanScorePct;
  final int allAttemptScoreDenominator;
  final double? latestAttemptPerQuizMeanScorePct;
  final int latestAttemptPerQuizScoreDenominator;
  final double? averageCompletionTimeSeconds;
  final int completionTimeDenominator;
  final Map<String, dynamic> questionProvenance;

  factory AttemptOverview.fromJson(Map<String, dynamic> json) =>
      AttemptOverview(
        createdQuizCount: (json['created_quiz_count'] as num).toInt(),
        completedAttemptCount: (json['completed_attempt_count'] as num).toInt(),
        distinctQuizzesAttempted: (json['distinct_quizzes_attempted'] as num)
            .toInt(),
        allAttemptMeanScorePct: (json['all_attempt_mean_score_pct'] as num?)
            ?.toDouble(),
        allAttemptScoreDenominator:
            (json['all_attempt_score_denominator'] as num).toInt(),
        latestAttemptPerQuizMeanScorePct:
            (json['latest_attempt_per_quiz_mean_score_pct'] as num?)
                ?.toDouble(),
        latestAttemptPerQuizScoreDenominator:
            (json['latest_attempt_per_quiz_score_denominator'] as num).toInt(),
        averageCompletionTimeSeconds:
            (json['average_completion_time_seconds'] as num?)?.toDouble(),
        completionTimeDenominator: (json['completion_time_denominator'] as num)
            .toInt(),
        questionProvenance: json['question_provenance'] as Map<String, dynamic>,
      );
}
