import 'dart:convert';

import 'package:certifications/core/settings.dart';
import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/models/generation.dart';

class GenerationApiException implements Exception {
  const GenerationApiException(this.statusCode, {this.code, this.message});
  final int statusCode;
  final String? code;
  final String? message;

  @override
  String toString() =>
      'GenerationApiException(statusCode: $statusCode, code: $code)';
}

class GenerationApiService {
  GenerationApiService({ApiAdapter? adapter})
    : _adapter = adapter ?? ApiAdapter();

  final ApiAdapter _adapter;
  String get _base => '${app_settings.ASODYA_API_URL}/apps/certifications/v1';

  Future<GenerationJob> start(
    String studyId,
    StartGenerationRequest input,
  ) async {
    final response = await _adapter.post(
      Uri.parse('$_base/studies/${Uri.encodeComponent(studyId)}/generations'),
      headers: const {'Content-Type': 'application/json'},
      body: input.toJson(),
    );
    return GenerationJob.fromJson(_decodeMap(response));
  }

  Future<GenerationJob> get(String jobId) async {
    final response = await _adapter.get(
      Uri.parse('$_base/generations/${Uri.encodeComponent(jobId)}'),
    );
    return GenerationJob.fromJson(_decodeMap(response));
  }

  Future<GenerationEstimate> estimate({
    required String studyId,
    required String language,
    required int count,
  }) async {
    final response = await _adapter.get(
      Uri.parse('$_base/studies/${Uri.encodeComponent(studyId)}/estimate'),
      queryParams: {'language': language, 'count': count},
    );
    return GenerationEstimate.fromJson(_decodeMap(response));
  }

  Future<List<GenerationEvent>> events({
    required String jobId,
    int after = 0,
  }) async {
    final parsed = <GenerationEvent>[];
    final response = await _adapter.getEventStream(
      url: Uri.parse(
        '$_base/generations/${Uri.encodeComponent(jobId)}/events?after=$after',
      ),
      onEvent: (_, data) {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          parsed.add(GenerationEvent.fromJson(decoded));
        }
      },
    );
    _ensureSuccess(response);
    return parsed;
  }

  Future<GenerationJob> stop(String jobId) async {
    final response = await _adapter.post(
      Uri.parse('$_base/generations/${Uri.encodeComponent(jobId)}/stop'),
    );
    return GenerationJob.fromJson(_decodeMap(response));
  }

  /// Requeues a stopped/failed job with a new server job ID and queue slot.
  Future<GenerationJob> resume(String jobId) async {
    final response = await _adapter.post(
      Uri.parse('$_base/generations/${Uri.encodeComponent(jobId)}/resume'),
    );
    return GenerationJob.fromJson(_decodeMap(response));
  }

  Map<String, dynamic> _decodeMap(dynamic response) {
    _ensureSuccess(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object from generation API');
    }
    return decoded;
  }

  void _ensureSuccess(dynamic response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    String? code;
    String? message;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        code = error is String
            ? error
            : error is Map<String, dynamic>
            ? (error['code'] as String?)
            : decoded['code'] as String?;
        message = decoded['message'] as String?;
      }
    } catch (_) {}
    throw GenerationApiException(
      response.statusCode,
      code: code,
      message: message,
    );
  }
}
