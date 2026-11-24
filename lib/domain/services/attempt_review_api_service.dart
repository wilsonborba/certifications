import 'dart:convert';

import 'package:certifications/core/settings.dart';
import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/models/attempt_review.dart';

class AttemptReviewApiException implements Exception {
  const AttemptReviewApiException(this.statusCode);
  final int statusCode;
}

class AttemptHistoryQuery {
  const AttemptHistoryQuery({
    this.q,
    this.startedFrom,
    this.startedTo,
    this.quizId,
    this.tag,
    this.limit = 20,
    this.offset = 0,
  });

  final String? q;
  final int? startedFrom;
  final int? startedTo;
  final String? quizId;
  final String? tag;
  final int limit;
  final int offset;

  Map<String, dynamic> toQueryParameters() => {
    if (q != null && q!.isNotEmpty) 'q': q,
    if (startedFrom != null) 'started_from': startedFrom,
    if (startedTo != null) 'started_to': startedTo,
    if (quizId != null && quizId!.isNotEmpty) 'quiz_id': quizId,
    if (tag != null && tag!.isNotEmpty) 'tag': tag,
    'limit': limit,
    'offset': offset,
  };
}

class AttemptReviewApiService {
  AttemptReviewApiService({ApiAdapter? adapter})
    : _adapter = adapter ?? ApiAdapter();

  final ApiAdapter _adapter;
  String get _base => '${app_settings.ASODYA_API_URL}/apps/certifications/v1';

  Future<AttemptHistoryPage> listAttempts(AttemptHistoryQuery query) async {
    final response = await _adapter.get(
      Uri.parse('$_base/attempts'),
      queryParams: query.toQueryParameters(),
    );
    return AttemptHistoryPage.fromJson(_decode(response));
  }

  Future<AttemptOverview> getOverview() async {
    final response = await _adapter.get(Uri.parse('$_base/attempts/overview'));
    return AttemptOverview.fromJson(_decode(response));
  }

  Future<AttemptResults> getResults(String attemptId) async {
    final response = await _adapter.get(
      Uri.parse('$_base/attempts/${Uri.encodeComponent(attemptId)}/results'),
    );
    return AttemptResults.fromJson(_decode(response));
  }

  Map<String, dynamic> _decode(dynamic response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AttemptReviewApiException(response.statusCode);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Expected a JSON object from attempt review API',
      );
    }
    return decoded;
  }
}
