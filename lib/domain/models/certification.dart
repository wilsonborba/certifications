import 'package:intl/intl.dart';

class Certification {
  final String id;
  final String title;
  final String fullName;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final String seriesId;
  final String? language;
  final double? score;
  final int? totalQuestions;
  final int? correctQuestions;
  final int? wrongQuestions;

  /// Public URL to view/verify/share the certificate.
  final String shareUrl;

  /// Optional art (logo/badge) if your API provides it.
  final String? badgeUrl;
  final String? issuerName; // e.g., “Thomas Kurian”
  final String? issuerTitle; // e.g., “CEO, Google Cloud”
  final String?
  certificationAs; // e.g., “Professional Machine Learning Engineer”

  Certification({
    required this.id,
    required this.title,
    required this.fullName,
    required this.issuedAt,
    required this.seriesId,
    required this.shareUrl,
    this.expiresAt,
    this.language,
    this.score,
    this.totalQuestions,
    this.correctQuestions,
    this.wrongQuestions,
    this.badgeUrl,
    this.issuerName,
    this.issuerTitle,
    this.certificationAs,
  });

  String get issuedAtLabel => DateFormat.yMMMMd().format(issuedAt);
  String? get expiresAtLabel =>
      expiresAt == null ? null : DateFormat.yMMMMd().format(expiresAt!);

  factory Certification.fromJson(Map<String, dynamic> json) {
    // 1) unwrap root -> data
    dynamic m = (json['data'] is Map<String, dynamic>) ? json['data'] : json;

    // 2) unwrap data -> certifications (your API uses this wrapper)
    if (m is Map<String, dynamic> &&
        m['certifications'] is Map<String, dynamic>) {
      m = m['certifications'] as Map<String, dynamic>;
    }

    DateTime? _safeDate(dynamic v) {
      if (v == null) return null;
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      return DateTime.tryParse(v.toString());
    }

    double? _safeDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    int? _safeInt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    // Your DB row uses uuid_certification as the real id
    final id =
        (m['uuid_certification'] ?? m['certification_id'] ?? m['id'] ?? '')
            .toString();

    return Certification(
      id: id,
      title: (m['certification_title'] ?? m['title'] ?? 'Certification')
          .toString(),
      fullName: (m['full_name'] ?? m['name'] ?? '—').toString(),
      issuedAt: _safeDate(m['created_at'] ?? m['issued_at']) ?? DateTime.now(),
      expiresAt: _safeDate(m['expires_at']),
      // You don't have series_id in your DB row; use id as a reasonable default
      seriesId: (m['series_id'] ?? m['seriesId'] ?? id).toString(),
      language: m['language']?.toString(),
      score: _safeDouble(m['score']),
      totalQuestions: _safeInt(m['total_questions']),
      correctQuestions: _safeInt(m['correct_questions']),
      wrongQuestions: _safeInt(m['wrong_questions']),
      shareUrl:
          (m['share_url'] ??
                  m['public_url'] ??
                  'https://accredit.asodya.com/certifications/$id')
              .toString(),
      badgeUrl: m['badge_url']?.toString(),
      issuerName: m['issuer_name']?.toString(),
      issuerTitle: m['issuer_title']?.toString(),
      certificationAs: m['certified_as']?.toString(),
    );
  }
}
