import 'dart:convert';

import 'package:certifications/dal/remote/certifications_api_client.dart';
import 'package:certifications/domain/models/public_question_catalog.dart';
import 'package:http/http.dart' as http;

class PublicQuestionApiException implements Exception {
  const PublicQuestionApiException(this.statusCode);
  final int statusCode;
}

/// Typed client for the held, source-verified CertAPI #49 public reuse
/// contract. It never accepts caller-supplied provenance or question content.
class PublicQuestionApiService {
  PublicQuestionApiService({CertificationsApiClient? client})
    : _client = client ?? CertificationsApiClient();

  final CertificationsApiClient _client;

  Future<PublicQuestionCatalogPage> search({
    String? query,
    String? language,
    String? origin,
    required int limit,
    required int offset,
  }) async {
    final response = await _client.searchPublicQuestions(
      q: query,
      language: language,
      origin: origin,
      limit: limit,
      offset: offset,
    );
    return PublicQuestionCatalogPage.fromJson(_decode(response));
  }

  Future<PublicQuestionReuseResult> reuseSelected({
    required String studyId,
    required List<String> questionVersionIds,
  }) async {
    if (questionVersionIds.isEmpty ||
        questionVersionIds.length > 50 ||
        questionVersionIds.any((id) => id.isEmpty) ||
        questionVersionIds.toSet().length != questionVersionIds.length) {
      throw ArgumentError.value(
        questionVersionIds,
        'questionVersionIds',
        'Supply 1 to 50 distinct immutable version IDs',
      );
    }
    final response = await _client.reuseStudyQuestions(
      studyId,
      questionVersionIds,
    );
    return PublicQuestionReuseResult.fromJson(_decode(response));
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PublicQuestionApiException(response.statusCode);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Expected a JSON object from public question API',
      );
    }
    return decoded;
  }
}
