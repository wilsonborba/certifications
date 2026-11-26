import 'dart:convert';

import 'package:certifications/core/settings.dart';
import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/models/attempt.dart';

class AttemptApiException implements Exception {
  const AttemptApiException(this.statusCode);
  final int statusCode;

  @override
  String toString() => 'AttemptApiException(statusCode: $statusCode)';
}

/// Authenticated attempt operations. Opening a saved attempt uses [getAttempt];
/// callers must invoke [startAttempt] only from the explicit start action.
class AttemptApiService {
  AttemptApiService({ApiAdapter? adapter}) : _adapter = adapter ?? ApiAdapter();

  final ApiAdapter _adapter;
  String get _base => '${app_settings.ASODYA_API_URL}/apps/certifications/v1';

  Future<AttemptView> startAttempt(String quizId) async {
    final response = await _adapter.post(
      Uri.parse('$_base/quizzes/${Uri.encodeComponent(quizId)}/attempts'),
    );
    return AttemptView.fromJson(_decodeMap(response));
  }

  Future<AttemptView> getAttempt(String attemptId) async {
    final response = await _adapter.get(
      Uri.parse('$_base/attempts/${Uri.encodeComponent(attemptId)}'),
    );
    return AttemptView.fromJson(_decodeMap(response));
  }

  Future<void> saveAnswer({
    required String attemptId,
    required String questionId,
    required String selectedOptionId,
  }) async {
    final response = await _adapter.put(
      Uri.parse(
        '$_base/attempts/${Uri.encodeComponent(attemptId)}/answers/${Uri.encodeComponent(questionId)}',
      ),
      headers: const {'Content-Type': 'application/json'},
      body: {'selected_option_id': selectedOptionId},
    );
    _ensureSuccess(response);
  }

  Future<int> recordActivityEvents({
    required String attemptId,
    required List<AttemptActivityEvent> events,
  }) async {
    final response = await _adapter.post(
      Uri.parse('$_base/attempts/${Uri.encodeComponent(attemptId)}/events'),
      headers: const {'Content-Type': 'application/json'},
      body: {'events': events.map((event) => event.toJson()).toList()},
    );
    return (_decodeMap(response)['inserted'] as num).toInt();
  }

  Future<Map<String, dynamic>> submitAttempt(String attemptId) async {
    final response = await _adapter.post(
      Uri.parse('$_base/attempts/${Uri.encodeComponent(attemptId)}/submit'),
    );
    return _decodeMap(response);
  }

  Map<String, dynamic> _decodeMap(dynamic response) {
    _ensureSuccess(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object from attempt API');
    }
    return decoded;
  }

  void _ensureSuccess(dynamic response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AttemptApiException(response.statusCode);
    }
  }
}
