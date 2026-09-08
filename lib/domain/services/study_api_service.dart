import 'dart:convert';
import 'package:certifications/core/settings.dart';
import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/models/quiz.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:http_parser/http_parser.dart';

class StudyApiException implements Exception {
  const StudyApiException(this.statusCode, {this.message, this.requestId});
  final int statusCode;
  final String? message;
  final String? requestId;

  @override
  String toString() => 'StudyApiException(statusCode: $statusCode, message: $message, requestId: $requestId)';
}

class StudyApiService {
  StudyApiService({ApiAdapter? adapter})
    : _adapter =
          adapter ??
          ApiAdapter(defaultHeaders: const {'Accept': 'application/json'});
  final ApiAdapter _adapter;
  String get _base =>
      '${app_settings.ASODYA_API_URL}/apps/certifications/v1/studies';
  Future<List<Study>> list() async {
    final response = await _adapter.get(Uri.parse(_base));
    return _list(response.body, response.statusCode);
  }

  Future<Study> create(String name) async => _study(
    await _adapter.post(
      Uri.parse(_base),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    ),
  );
  Future<Study> get(String id) async =>
      _study(await _adapter.get(Uri.parse('$_base/$id')));

  /// Renames a study. Follows the same PATCH-a-sub-resource shape used by
  /// [select] below, applied to the study itself.
  Future<Study> rename(String studyId, String name) async => _study(
    await _adapter.patch(
      Uri.parse('$_base/$studyId'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    ),
  );

  Future<void> delete(String studyId) async {
    final response = await _adapter.delete(Uri.parse('$_base/$studyId'));
    if (response.statusCode != 204 &&
        (response.statusCode < 200 || response.statusCode >= 300)) {
      throw StudyApiException(response.statusCode);
    }
  }
  Future<StudySource> upload({
    required String studyId,
    required String kind,
    required String filename,
    required List<int> bytes,
    required String mimeType,
  }) async {
    final response = await _adapter.postMultipart(
      url: Uri.parse('$_base/$studyId/sources'),
      queryParams: {'kind': kind},
      files: [
        MultipartFileData(
          field: 'file',
          bytes: bytes,
          filename: filename,
          contentType: MediaType.parse(mimeType),
        ),
      ],
    );
    return StudySource.fromJson(_data(response));
  }

  Future<StudySource> select({
    required String studyId,
    required String sourceId,
    required Map<String, int> selection,
  }) async => StudySource.fromJson(
    _data(
      await _adapter.patch(
        Uri.parse('$_base/$studyId/sources/$sourceId/selection'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'selection': selection}),
      ),
    ),
  );
  Future<StudySource> ingest(String studyId, String sourceId) async =>
      StudySource.fromJson(
        _data(
          await _adapter.post(
            Uri.parse('$_base/$studyId/sources/$sourceId/ingest'),
          ),
        ),
      );
  Future<void> deleteSource(String studyId, String sourceId) async {
    final response = await _adapter.delete(
      Uri.parse('$_base/$studyId/sources/$sourceId'),
    );
    if (response.statusCode != 204)
      throw StudyApiException(response.statusCode);
  }

  Future<void> deleteStudy(String studyId) async {
    final response = await _adapter.delete(
      Uri.parse('$_base/$studyId'),
    );
    if (response.statusCode != 204)
      throw StudyApiException(response.statusCode);
  }

  Future<List<StudyQuestion>> generateQuestions({
    required String studyId,
    required String difficulty,
    required String idempotencyKey,
    required bool useWeb,
    /// Number of questions to generate, 1-20.
    int questionCount = 10,
  }) async {
    final response = await _adapter.post(
      Uri.parse('$_base/$studyId/questions/generate'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'difficulty': difficulty,
        'idempotency_key': idempotencyKey,
        'use_web': useWeb,
        'question_count': questionCount,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300)
      throw StudyApiException(response.statusCode);
    return ((jsonDecode(response.body) as Map<String, dynamic>)['data'] as List)
        .cast<Map<String, dynamic>>()
        .map(StudyQuestion.fromJson)
        .toList();
  }

  Future<List<StudyQuestion>> getQuestions(String studyId) async {
    final response = await _adapter.get(
      Uri.parse('$_base/$studyId/questions'),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StudyApiException(response.statusCode);
    }
    return ((jsonDecode(response.body) as Map<String, dynamic>)['data'] as List)
        .cast<Map<String, dynamic>>()
        .map(StudyQuestion.fromJson)
        .toList();
  }

  /// Grades a full set of answers server-side (the client never has the
  /// correct answers ahead of this call) and returns the score plus a
  /// per-question breakdown.
  Future<QuizGradeResult> submitAnswers({
    required String studyId,
    required Map<String, int> answers,
  }) async {
    final response = await _adapter.post(
      Uri.parse('$_base/$studyId/questions/submit'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'answers': [
          for (final entry in answers.entries)
            {'question_id': entry.key, 'choice_index': entry.value},
        ],
      }),
    );
    return QuizGradeResult.fromJson(_data(response));
  }

  /// Polled by the wizard's loading screen while [generateQuestions] is
  /// in flight to show real progress (questions generated so far, out of
  /// how many chunks of source material) instead of a static spinner.
  Future<GenerationProgress> getGenerationProgress(String studyId) async {
    final response = await _adapter.get(
      Uri.parse('$_base/$studyId/questions/progress'),
    );
    return GenerationProgress.fromJson(_data(response));
  }

  String diagramUrl(String studyId, String questionId) =>
      '$_base/$studyId/questions/$questionId/visual';

  StudyApiException _parseException(dynamic response) {
    String? message;
    String? requestId;
    try {
      if (response.headers != null) {
        requestId = response.headers['x-request-id'] ?? response.headers['X-Request-ID'];
      }
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        message = decoded['detail']?.toString() ?? decoded['message']?.toString();
        requestId = decoded['request_id']?.toString() ?? requestId;
      }
    } catch (_) {}
    return StudyApiException(response.statusCode, message: message, requestId: requestId);
  }

  Study _study(dynamic response) => Study.fromJson(_data(response));
  List<Study> _list(String body, int code) {
    if (code < 200 || code >= 300) throw StudyApiException(code);
    final payload = jsonDecode(body) as Map<String, dynamic>;
    return (payload['data'] as List)
        .cast<Map<String, dynamic>>()
        .map(Study.fromJson)
        .toList();
  }

  Map<String, dynamic> _data(dynamic response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _parseException(response);
    }
    return (jsonDecode(response.body) as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
  }
}
