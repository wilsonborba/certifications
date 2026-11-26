class GenerationJob {
  const GenerationJob({
    required this.id,
    required this.studyId,
    required this.status,
    required this.language,
    required this.requestedCount,
    required this.queuePosition,
    required this.savedCount,
    required this.stopRequested,
    required this.errorCode,
    required this.queuedAt,
    this.quizId,
    this.startedAt,
    this.finishedAt,
  });

  final String id;
  final String studyId;
  final String? quizId;
  final String status;
  final String language;
  final int requestedCount;
  final int queuePosition;
  final int savedCount;
  final bool stopRequested;
  final String errorCode;
  final int queuedAt;
  final int? startedAt;
  final int? finishedAt;

  bool get isActive => status == 'queued' || status == 'running';
  bool get canResume =>
      (status == 'cancelled' || status == 'failed') &&
      errorCode != 'cortex_outcome_unknown';

  factory GenerationJob.fromJson(Map<String, dynamic> json) => GenerationJob(
    id: json['id'] as String,
    studyId: json['study_id'] as String,
    quizId: json['quiz_id'] as String?,
    status: json['status'] as String,
    language: json['language'] as String,
    requestedCount: (json['requested_count'] as num).toInt(),
    queuePosition: (json['queue_position'] as num).toInt(),
    savedCount: (json['saved_count'] as num).toInt(),
    stopRequested: json['stop_requested'] as bool,
    errorCode: json['error_code'] as String,
    queuedAt: (json['queued_at'] as num).toInt(),
    startedAt: (json['started_at'] as num?)?.toInt(),
    finishedAt: (json['finished_at'] as num?)?.toInt(),
  );
}

class GenerationEvent {
  const GenerationEvent({
    required this.seq,
    required this.eventType,
    required this.message,
    required this.createdAt,
  });

  final int seq;
  final String eventType;
  final String message;
  final int createdAt;

  factory GenerationEvent.fromJson(Map<String, dynamic> json) =>
      GenerationEvent(
        seq: (json['seq'] as num).toInt(),
        eventType: json['event_type'] as String,
        message: json['message'] as String,
        createdAt: (json['created_at'] as num).toInt(),
      );
}

class GenerationEstimate {
  const GenerationEstimate({
    required this.status,
    required this.sampleCount,
    required this.queueAheadCount,
    required this.source,
    this.estimatedProcessingMs,
  });

  final String status;
  final int? estimatedProcessingMs;
  final int sampleCount;
  final int queueAheadCount;
  final String source;

  bool get isAvailable =>
      status == 'available' && estimatedProcessingMs != null;

  factory GenerationEstimate.fromJson(Map<String, dynamic> json) =>
      GenerationEstimate(
        status: json['status'] as String,
        estimatedProcessingMs: (json['estimated_processing_ms'] as num?)
            ?.toInt(),
        sampleCount: (json['sample_count'] as num).toInt(),
        queueAheadCount: (json['queue_ahead_count'] as num).toInt(),
        source: json['source'] as String,
      );
}

class StartGenerationRequest {
  const StartGenerationRequest({
    required this.language,
    required this.count,
    required this.idempotencyKey,
    this.quizId,
  });

  final String language;
  final int count;
  final String idempotencyKey;
  final String? quizId;

  Map<String, dynamic> toJson() => {
    'language': language,
    'count': count,
    'idempotency_key': idempotencyKey,
    if (quizId != null) 'quiz_id': quizId,
  };
}
