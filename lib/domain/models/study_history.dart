import 'package:certifications/domain/models/study.dart';

class AvailableStudyTag {
  const AvailableStudyTag({required this.slug, required this.label});

  factory AvailableStudyTag.fromJson(Map<String, dynamic> json) {
    final slug = json['slug'];
    final label = json['label'];
    if (slug is! String || label is! String) {
      throw const FormatException('Invalid available study tag');
    }
    return AvailableStudyTag(slug: slug, label: label);
  }

  final String slug;
  final String label;
}

/// Exact response DTO for the owner-scoped `GET /studies` history endpoint.
class StudyHistoryPage {
  StudyHistoryPage.fromJson(Map<String, dynamic> json)
    : items = _studies(json['items']),
      total = _integer(json['total'], 'total'),
      limit = _integer(json['limit'], 'limit'),
      offset = _integer(json['offset'], 'offset'),
      availableTags = _tags(json['available_tags']);

  final List<Study> items;
  final int total;
  final int limit;
  final int offset;
  final List<AvailableStudyTag> availableTags;

  static int _integer(Object? value, String name) {
    if (value is! int || value < 0) {
      throw FormatException('Invalid study history $name');
    }
    return value;
  }

  static List<Study> _studies(Object? value) {
    if (value is! List || value.any((item) => item is! Map)) {
      throw const FormatException('Study history is missing items');
    }
    return value
        .map((item) => Study.fromJson((item as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  static List<AvailableStudyTag> _tags(Object? value) {
    if (value is! List || value.any((item) => item is! Map)) {
      throw const FormatException('Study history is missing available_tags');
    }
    return value
        .map(
          (item) =>
              AvailableStudyTag.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList(growable: false);
  }
}

class StudyHistoryQuery {
  const StudyHistoryQuery({
    this.q,
    this.createdFrom,
    this.createdTo,
    this.status,
    this.quizId,
    this.tag,
    this.limit = 20,
    this.offset = 0,
  }) : assert(limit >= 1 && limit <= 50),
       assert(offset >= 0);

  final String? q;
  final int? createdFrom;
  final int? createdTo;
  final String? status;
  final String? quizId;
  final String? tag;
  final int limit;
  final int offset;

  Map<String, dynamic> toQueryParameters() {
    final result = <String, dynamic>{'limit': limit, 'offset': offset};
    final search = _nonEmpty(q);
    final cleanStatus = _nonEmpty(status);
    final cleanQuizId = _nonEmpty(quizId);
    final cleanTag = _nonEmpty(tag);
    if (search != null) result['q'] = search;
    if (createdFrom != null) result['created_from'] = createdFrom;
    if (createdTo != null) result['created_to'] = createdTo;
    if (cleanStatus != null) result['status'] = cleanStatus;
    if (cleanQuizId != null) result['quiz_id'] = cleanQuizId;
    if (cleanTag != null) result['tag'] = cleanTag;
    return result;
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static int? startOfLocalDateSeconds(DateTime? value) => value == null
      ? null
      : DateTime(value.year, value.month, value.day).millisecondsSinceEpoch ~/
            1000;

  static int? endOfLocalDateSeconds(DateTime? value) => value == null
      ? null
      : (DateTime(
                  value.year,
                  value.month,
                  value.day + 1,
                ).millisecondsSinceEpoch ~/
                1000) -
            1;
}
