import 'dart:convert';

import 'package:certifications/core/settings.dart';
import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/models/public_quiz_statistics.dart';

class PublicQuizStatisticsApiException implements Exception {
  const PublicQuizStatisticsApiException(this.statusCode);
  final int statusCode;
}

class PublicQuizStatisticsApiService {
  PublicQuizStatisticsApiService({ApiAdapter? adapter})
    : _adapter = adapter ?? ApiAdapter();

  final ApiAdapter _adapter;
  String get _base => '${app_settings.ASODYA_API_URL}/apps/certifications/v1';

  Future<PublicQuizStatistics> getForQuiz(
    String quizId, {
    String language = 'en',
  }) => _getForQuiz(quizId, language: language, ownerOnly: false);

  /// Fetches statistics from the authenticated owner's private route. This is
  /// deliberately separate from [getForQuiz], which remains the anonymous
  /// public-catalog route and never retries through an owner endpoint.
  Future<PublicQuizStatistics> getForOwnedQuiz(
    String quizId, {
    String language = 'en',
  }) => _getForQuiz(quizId, language: language, ownerOnly: true);

  Future<PublicQuizStatistics> _getForQuiz(
    String quizId, {
    required String language,
    required bool ownerOnly,
  }) async {
    final acceptLanguage = switch (language) {
      'pt' => 'pt-BR',
      'th' => 'th',
      _ => 'en',
    };
    final response = await _adapter.get(
      Uri.parse(
        ownerOnly
            ? '$_base/me/quizzes/${Uri.encodeComponent(quizId)}/statistics'
            : '$_base/quizzes/${Uri.encodeComponent(quizId)}/statistics',
      ),
      headers: {'Accept-Language': acceptLanguage},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PublicQuizStatisticsApiException(response.statusCode);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object from statistics API');
    }
    return PublicQuizStatistics.fromJson(decoded);
  }
}
