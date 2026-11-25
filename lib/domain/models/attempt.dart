/// Owner-scoped attempt data returned by the Certifications taking API.
/// This projection deliberately has no answer key, explanation, or citation.
class AttemptView {
  const AttemptView({
    required this.id,
    required this.quizId,
    required this.quizVersionId,
    required this.status,
    required this.startedAt,
    required this.monitoringNotice,
    required this.questions,
    this.completedAt,
  });

  final String id;
  final String quizId;
  final String quizVersionId;
  final String status;
  final int startedAt;
  final int? completedAt;
  final String monitoringNotice;
  final List<AttemptQuestion> questions;

  factory AttemptView.fromJson(Map<String, dynamic> json) => AttemptView(
    id: json['id'] as String,
    quizId: json['quiz_id'] as String,
    quizVersionId: json['quiz_version_id'] as String,
    status: json['status'] as String,
    startedAt: (json['started_at'] as num).toInt(),
    completedAt: (json['completed_at'] as num?)?.toInt(),
    monitoringNotice: json['monitoring_notice'] as String,
    questions: (json['questions'] as List<dynamic>)
        .map((item) => AttemptQuestion.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
  );
}

class AttemptQuestion {
  const AttemptQuestion({
    required this.questionId,
    required this.questionVersionId,
    required this.language,
    required this.origin,
    required this.prompt,
    required this.alternatives,
    this.selectedOptionId,
  });

  final String questionId;
  final String questionVersionId;
  final String language;
  final String origin;
  final String prompt;
  final List<dynamic> alternatives;
  final String? selectedOptionId;

  factory AttemptQuestion.fromJson(Map<String, dynamic> json) =>
      AttemptQuestion(
        questionId: json['question_id'] as String,
        questionVersionId: json['question_version_id'] as String,
        language: json['language'] as String,
        origin: json['origin'] as String,
        prompt: json['prompt'] as String,
        alternatives: json['alternatives'] as List<dynamic>,
        selectedOptionId: json['selected_option_id'] as String?,
      );
}

/// Browser activity records accepted by POST /attempts/{id}/events.
class AttemptActivityEvent {
  const AttemptActivityEvent({
    required this.eventKind,
    this.dedupKey,
    this.durationMs = 0,
    this.occurredAt,
  });

  final String eventKind;
  final String? dedupKey;
  final int durationMs;
  final int? occurredAt;

  Map<String, dynamic> toJson() => {
    if (dedupKey != null) 'dedup_key': dedupKey,
    'event_kind': eventKind,
    'duration_ms': durationMs,
    if (occurredAt != null) 'occurred_at': occurredAt,
  };
}
