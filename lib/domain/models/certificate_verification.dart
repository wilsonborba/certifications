/// Factual public verification projection; it contains no ability or conduct
/// verdict and no private attempt answers.
class CertificateVerification {
  const CertificateVerification({
    required this.verificationCode,
    required this.status,
    required this.revocationReason,
    required this.holderPublicId,
    required this.holderName,
    required this.quizTitle,
    required this.scoreCorrect,
    required this.scoreTotal,
    required this.issuedAt,
    required this.activitySummary,
    this.revokedAt,
  });

  final String verificationCode;
  final String status;
  final String revocationReason;
  final String holderPublicId;
  final String holderName;
  final String quizTitle;
  final int scoreCorrect;
  final int scoreTotal;
  final int issuedAt;
  final int? revokedAt;
  final CertificateActivitySummary activitySummary;

  factory CertificateVerification.fromJson(Map<String, dynamic> json) =>
      CertificateVerification(
        verificationCode: json['verification_code'] as String,
        status: json['status'] as String,
        revocationReason: json['revocation_reason'] as String,
        holderPublicId: json['holder_public_id'] as String,
        holderName: json['holder_name'] as String,
        quizTitle: json['quiz_title'] as String,
        scoreCorrect: (json['score_correct'] as num).toInt(),
        scoreTotal: (json['score_total'] as num).toInt(),
        issuedAt: (json['issued_at'] as num).toInt(),
        revokedAt: (json['revoked_at'] as num?)?.toInt(),
        activitySummary: CertificateActivitySummary.fromJson(
          json['activity_summary'] as Map<String, dynamic>,
        ),
      );
}

class CertificateActivitySummary {
  const CertificateActivitySummary({
    required this.focusLostCount,
    required this.pageHiddenCount,
    required this.pageReturnCount,
    required this.knownAwayMs,
    required this.reconnectCount,
    required this.refreshCount,
    required this.unknownGapCount,
    required this.completeness,
    required this.disclaimer,
    required this.events,
  });

  final int focusLostCount;
  final int pageHiddenCount;
  final int pageReturnCount;
  final int knownAwayMs;
  final int reconnectCount;
  final int refreshCount;
  final int unknownGapCount;
  final String completeness;
  final String disclaimer;
  final List<CertificateActivityEvent> events;

  factory CertificateActivitySummary.fromJson(
    Map<String, dynamic> json,
  ) => CertificateActivitySummary(
    focusLostCount: (json['focus_lost_count'] as num).toInt(),
    pageHiddenCount: (json['page_hidden_count'] as num).toInt(),
    pageReturnCount: (json['page_return_count'] as num).toInt(),
    knownAwayMs: (json['known_away_ms'] as num).toInt(),
    reconnectCount: (json['reconnect_count'] as num).toInt(),
    refreshCount: (json['refresh_count'] as num).toInt(),
    unknownGapCount: (json['unknown_gap_count'] as num).toInt(),
    completeness: json['completeness'] as String,
    disclaimer: json['disclaimer'] as String,
    events: (json['events'] as List<dynamic>)
        .map(
          (event) =>
              CertificateActivityEvent.fromJson(event as Map<String, dynamic>),
        )
        .toList(growable: false),
  );
}

class CertificateActivityEvent {
  const CertificateActivityEvent({
    required this.id,
    required this.eventKind,
    required this.durationMs,
    required this.occurredAt,
  });

  final String id;
  final String eventKind;
  final int durationMs;
  final int occurredAt;

  factory CertificateActivityEvent.fromJson(Map<String, dynamic> json) =>
      CertificateActivityEvent(
        id: json['id'] as String,
        eventKind: json['event_kind'] as String,
        durationMs: (json['duration_ms'] as num).toInt(),
        occurredAt: (json['occurred_at'] as num).toInt(),
      );
}
