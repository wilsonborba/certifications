import 'dart:convert';

import 'package:certifications/core/settings.dart';
import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/models/study_history.dart';

class StudyHistoryApiException implements Exception {
  const StudyHistoryApiException(this.statusCode);
  final int statusCode;
}

class StudyHistoryApiService {
  StudyHistoryApiService({ApiAdapter? adapter})
    : _adapter = adapter ?? ApiAdapter();

  final ApiAdapter _adapter;
  String get _base => '${app_settings.ASODYA_API_URL}/apps/certifications/v1';

  Future<StudyHistoryPage> list(StudyHistoryQuery query) async {
    final response = await _adapter.get(
      Uri.parse('$_base/studies'),
      queryParams: query.toQueryParameters(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StudyHistoryApiException(response.statusCode);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected a study history page object');
    }
    return StudyHistoryPage.fromJson(decoded);
  }
}
