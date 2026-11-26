import 'dart:convert';
import 'package:certifications/core/settings.dart';
import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/models/quiz.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:certifications/domain/models/study_selection.dart';
import 'package:http_parser/http_parser.dart';

class StudyApiException implements Exception {
  const StudyApiException(this.statusCode, {this.message, this.requestId});
  final int statusCode;
  final String? message;
  final String? requestId;

  @override
  String toString() =>
      'StudyApiException(statusCode: $statusCode, message: $message, requestId: $requestId)';
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

  Future<Study> create(String name) async {
    final response = await _adapter.post(
      Uri.parse(_base),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'title': name}),
    );
    final summary = _study(response);
    return get(summary.id);
  }

  Future<Study> get(String id) async =>
      _study(await _adapter.get(Uri.parse('$_base/$id')));

  /// Lists only Reports entries the authenticated caller may read.
  Future<List<ReportPickerItem>> listReports() async {
    final response = await _adapter.get(
      Uri.parse(
        '${app_settings.ASODYA_API_URL}/apps/certifications/v1/reports/picker',
      ),
    );
    return _pickerItems(response).map(ReportPickerItem.fromJson).toList();
  }

  Future<List<ReportDatasetPickerItem>> listReportDatasets(
    ReportPickerItem report,
  ) async {
    final uri =
        Uri.parse(
          '${app_settings.ASODYA_API_URL}/apps/certifications/v1/reports/picker',
        ).replace(
          queryParameters: {'project': report.project, 'report': report.report},
        );
    final response = await _adapter.get(uri);
    return _pickerItems(response)
        .map(ReportDatasetPickerItem.fromJson)
        .where((dataset) => dataset.canView)
        .toList();
  }

  /// Attaches one all-only Reports dataset to the prepared study. Reports
  /// rechecks caller access and visibility; the browser supplies no identity
  /// or FSM authority fields.
  Future<StudySource> attachReportDataset({
    required String studyId,
    required ReportDatasetPickerItem dataset,
  }) async {
    if (!dataset.canView) {
      throw const StudyApiException(
        403,
        message: 'Report dataset is not readable',
      );
    }
    final response = await _adapter.post(
      Uri.parse('$_base/$studyId/sources'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'kind': 'report',
        'filename': dataset.title,
        'external_ref': dataset.externalRef,
        'is_restricted': false,
      }),
    );
    final source = StudySource.fromJson(_data(response));
    if (source.id.isEmpty ||
        source.sourceKind != 'report' ||
        source.selectionKind != 'all' ||
        source.selectionSpec.isNotEmpty ||
        source.externalRef != dataset.externalRef) {
      throw const FormatException('Invalid attached Reports source response');
    }
    return source;
  }

  /// Renames a study using the Rust API's title field.
  Future<Study> rename(String studyId, String name) async => _study(
    await _adapter.patch(
      Uri.parse('$_base/$studyId'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'title': name}),
    ),
  );

  Future<void> delete(String studyId) async {
    final response = await _adapter.delete(Uri.parse('$_base/$studyId'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StudyApiException(response.statusCode);
    }
  }

  Future<StudySource> upload({
    required String studyId,
    required String filename,
    required List<int> bytes,
    required String mimeType,
    void Function(double progress)? onProgress,
  }) async {
    final isText = const {
      'text/plain',
      'text/markdown',
      'text/csv',
    }.contains(mimeType.toLowerCase().split(';').first.trim());
    final response = isText
        ? await _adapter.postJsonWithProgress(
            url: Uri.parse('$_base/$studyId/sources'),
            body: {
              'filename': filename,
              'mime_type': mimeType,
              'content_text': StudySelection.normalizeText(utf8.decode(bytes)),
            },
            onProgress: onProgress,
          )
        : await _adapter.postMultipart(
            url: Uri.parse('$_base/$studyId/sources'),
            fields: {'filename': filename, 'mime_type': mimeType},
            files: [
              MultipartFileData(
                field: 'file',
                bytes: bytes,
                filename: filename,
                contentType: MediaType.parse(mimeType),
              ),
            ],
            onProgress: onProgress,
          );
    return StudySource.fromJson(_data(response));
  }

  Future<StudySource> select({
    required String studyId,
    required String sourceId,
    required String kind,
    required String spec,
  }) async => StudySource.fromJson(
    _data(
      await _adapter.patch(
        Uri.parse('$_base/$studyId/sources/$sourceId/selection'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'kind': kind, 'spec': spec}),
      ),
    ),
  );

  Future<StudySource> getSource(String studyId, String sourceId) async =>
      StudySource.fromJson(
        _data(
          await _adapter.get(Uri.parse('$_base/$studyId/sources/$sourceId')),
        ),
      );

  Future<StudySourcePreview> previewSource(
    String studyId,
    String sourceId,
  ) async => StudySourcePreview.fromJson(
    _data(
      await _adapter.get(
        Uri.parse('$_base/$studyId/sources/$sourceId/preview'),
      ),
    ),
  );

  Future<void> streamAnalysis(
    String studyId, {
    required void Function(StudyAnalysisEvent event) onEvent,
    Future<void>? abortTrigger,
  }) async {
    final response = await _adapter.postEventStream(
      url: Uri.parse('$_base/$studyId/analysis/stream'),
      abortTrigger: abortTrigger,
      onEvent: (name, data) {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          onEvent(StudyAnalysisEvent(name, decoded));
        }
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _parseException(response);
    }
  }

  Future<void> deleteSource(String studyId, String sourceId) async {
    final response = await _adapter.delete(
      Uri.parse('$_base/$studyId/sources/$sourceId'),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StudyApiException(response.statusCode);
    }
  }

  Future<void> deleteStudy(String studyId) async {
    final response = await _adapter.delete(Uri.parse('$_base/$studyId'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StudyApiException(response.statusCode);
    }
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
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StudyApiException(response.statusCode);
    }
    return ((jsonDecode(response.body) as Map<String, dynamic>)['data'] as List)
        .cast<Map<String, dynamic>>()
        .map(StudyQuestion.fromJson)
        .toList();
  }

  Future<List<StudyQuestion>> getQuestions(String studyId) async {
    final response = await _adapter.get(Uri.parse('$_base/$studyId/questions'));
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
        requestId =
            response.headers['x-request-id'] ??
            response.headers['X-Request-ID'];
      }
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        message =
            decoded['detail']?.toString() ?? decoded['message']?.toString();
        requestId = decoded['request_id']?.toString() ?? requestId;
      }
    } catch (_) {}
    return StudyApiException(
      response.statusCode,
      message: message,
      requestId: requestId,
    );
  }

  Study _study(dynamic response) => Study.fromJson(_data(response));
  List<Study> _list(String body, int code) {
    if (code < 200 || code >= 300) throw StudyApiException(code);
    final payload = jsonDecode(body) as Map<String, dynamic>;
    final items = payload['items'] ?? payload['data'];
    if (items is! List) {
      throw const FormatException('Studies response is missing items');
    }
    return items.cast<Map<String, dynamic>>().map(Study.fromJson).toList();
  }

  Map<String, dynamic> _data(dynamic response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _parseException(response);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object response');
    }
    final data = decoded['data'];
    if (data is Map<String, dynamic>) return data;
    return decoded;
  }

  List<Map<String, dynamic>> _pickerItems(dynamic response) {
    final data = _data(response);
    final items = data['items'];
    if (items is! List || items.any((item) => item is! Map)) {
      throw const FormatException('Reports picker response is missing items');
    }
    return items.map((item) => (item as Map).cast<String, dynamic>()).toList();
  }
}
