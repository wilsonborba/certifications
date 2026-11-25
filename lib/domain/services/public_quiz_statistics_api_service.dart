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
  }) async {
    final acceptLanguage = switch (language) {
      'pt' => 'pt-BR',
      'th' => 'th',
      _ => 'en',
    };
    final response = await _adapter.get(
      Uri.parse('$_base/quizzes/${Uri.encodeComponent(quizId)}/statistics'),
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
