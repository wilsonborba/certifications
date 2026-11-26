import 'dart:convert';
import 'package:certifications/core/settings.dart';
import 'package:http/http.dart' as http;

typedef ApiRequestFn =
    Future<http.Response> Function({
      required String method,
      required Uri url,
      Map<String, String>? headers,
      dynamic body,
      Map<String, dynamic>? queryParams,
    });

/// Typed adapter for the Area 11 Certifications backend/gateway API inventory.
///
/// All endpoints sit under `/apps/certifications/v1` (the gateway strips the prefix
/// and forwards the suffix to the Rust backend).
class CertificationsApiClient {
  final ApiRequestFn _request;
  final http.Client _httpClient;
  final String _baseUrl;

  CertificationsApiClient({
    ApiRequestFn? request,
    http.Client? client,
    String? baseUrl,
  }) : _httpClient = client ?? http.Client(),
       _request = request ?? _defaultRequest(client ?? http.Client()),
       _baseUrl =
           (baseUrl ?? '${app_settings.ASODYA_API_URL}/apps/certifications/v1')
               .replaceAll(RegExp(r'/+$'), '');

  static ApiRequestFn _defaultRequest(http.Client client) {
    return ({
      required String method,
      required Uri url,
      Map<String, String>? headers,
      dynamic body,
      Map<String, dynamic>? queryParams,
    }) async {
      final resolved = (queryParams == null || queryParams.isEmpty)
          ? url
          : url.replace(
              queryParameters: {
                for (final e in queryParams.entries)
                  if (e.value != null) e.key: '${e.value}',
              },
            );
      final encoded = body == null
          ? null
          : (body is String ? body : jsonEncode(body));
      final mergedHeaders = {
        if (encoded != null) 'Content-Type': 'application/json',
        ...?headers,
      };
      return switch (method.toUpperCase()) {
        'GET' => client.get(resolved, headers: mergedHeaders),
        'POST' => client.post(resolved, headers: mergedHeaders, body: encoded),
        'PATCH' => client.patch(
          resolved,
          headers: mergedHeaders,
          body: encoded,
        ),
        'PUT' => client.put(resolved, headers: mergedHeaders, body: encoded),
        'DELETE' => client.delete(resolved, headers: mergedHeaders),
        _ => throw ArgumentError('Unsupported HTTP method: $method'),
      };
    };
  }

  Future<http.Response> _apiRequest({
    required String method,
    required Uri url,
    Map<String, String>? headers,
    dynamic body,
    Map<String, dynamic>? queryParams,
  }) => _request(
    method: method,
    url: url,
    headers: headers,
    body: body,
    queryParams: queryParams,
  );

  Uri endpoint(String suffix) {
    final clean = suffix.startsWith('/') ? suffix : '/$suffix';
    return Uri.parse('$_baseUrl$clean');
  }

  // Preparations & sources
  Future<http.Response> listStudies({
    int? page,
    int? limit,
    int? offset,
    String? q,
    int? createdFrom,
    int? createdTo,
    String? status,
    String? quizId,
    String? tag,
  }) => _apiRequest(
    method: 'GET',
    url: endpoint('/studies'),
    queryParams: {
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
      if (q != null) 'q': q,
      if (createdFrom != null) 'created_from': createdFrom,
      if (createdTo != null) 'created_to': createdTo,
      if (status != null) 'status': status,
      if (quizId != null) 'quiz_id': quizId,
      if (tag != null) 'tag': tag,
    },
  );

  Future<http.Response> createStudy(Map<String, dynamic> body) =>
      _apiRequest(method: 'POST', url: endpoint('/studies'), body: body);

  Future<http.Response> getStudy(String studyId) =>
      _apiRequest(method: 'GET', url: endpoint('/studies/$studyId'));

  Future<http.Response> patchStudy(String studyId, Map<String, dynamic> body) =>
      _apiRequest(
        method: 'PATCH',
        url: endpoint('/studies/$studyId'),
        body: body,
      );

  Future<http.Response> deleteStudy(String studyId) =>
      _apiRequest(method: 'DELETE', url: endpoint('/studies/$studyId'));

  Future<http.Response> createPreparedStudy(Map<String, dynamic> body) =>
      _apiRequest(
        method: 'POST',
        url: endpoint('/studies/prepared'),
        body: body,
      );

  Future<http.Response> getStudyEstimate(String studyId) =>
      _apiRequest(method: 'GET', url: endpoint('/studies/$studyId/estimate'));

  Future<http.Response> getStudyTagSuggestions(String studyId) => _apiRequest(
    method: 'GET',
    url: endpoint('/studies/$studyId/tags/suggestions'),
  );

  Future<http.Response> uploadStudySourceMultipart(
    String studyId, {
    required List<int> bytes,
    required String filename,
  }) async {
    final req =
        http.MultipartRequest('POST', endpoint('/studies/$studyId/sources'))
          ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: filename),
          );
    final streamed = await _httpClient.send(req);
    return http.Response.fromStream(streamed);
  }

  Future<http.Response> getSource(String studyId, String sourceId) =>
      _apiRequest(
        method: 'GET',
        url: endpoint('/studies/$studyId/sources/$sourceId'),
      );

  Future<http.Response> previewSource(String studyId, String sourceId) =>
      _apiRequest(
        method: 'GET',
        url: endpoint('/studies/$studyId/sources/$sourceId/preview'),
      );

  Future<http.Response> patchSourceSelection(
    String studyId,
    String sourceId,
    Map<String, dynamic> body,
  ) => _apiRequest(
    method: 'PATCH',
    url: endpoint('/studies/$studyId/sources/$sourceId/selection'),
    body: body,
  );

  Future<http.Response> deleteSource(String studyId, String sourceId) =>
      _apiRequest(
        method: 'DELETE',
        url: endpoint('/studies/$studyId/sources/$sourceId'),
      );

  Future<http.Response> analyzeStudy(String studyId) =>
      _apiRequest(method: 'POST', url: endpoint('/studies/$studyId/analysis'));

  Future<http.Response> getStudyAnalysis(String studyId) =>
      _apiRequest(method: 'GET', url: endpoint('/studies/$studyId/analysis'));

  // Generation
  Future<http.Response> startGeneration(
    String studyId,
    Map<String, dynamic> body,
  ) => _apiRequest(
    method: 'POST',
    url: endpoint('/studies/$studyId/generations'),
    body: body,
  );

  Future<http.Response> getGeneration(String generationId) =>
      _apiRequest(method: 'GET', url: endpoint('/generations/$generationId'));

  Uri generationEventsUri(String generationId) =>
      endpoint('/generations/$generationId/events');

  Future<http.Response> stopGeneration(String generationId) => _apiRequest(
    method: 'POST',
    url: endpoint('/generations/$generationId/stop'),
  );

  Future<http.Response> resumeGeneration(String generationId) => _apiRequest(
    method: 'POST',
    url: endpoint('/generations/$generationId/resume'),
  );

  // Author questions & publication
  Future<http.Response> listStudyQuestions(String studyId) =>
      _apiRequest(method: 'GET', url: endpoint('/studies/$studyId/questions'));

  Future<http.Response> createStudyQuestion(
    String studyId,
    Map<String, dynamic> body,
  ) => _apiRequest(
    method: 'POST',
    url: endpoint('/studies/$studyId/questions'),
    body: body,
  );

  Future<http.Response> patchStudyQuestion(
    String studyId,
    String questionId,
    Map<String, dynamic> body,
  ) => _apiRequest(
    method: 'PATCH',
    url: endpoint('/studies/$studyId/questions/$questionId'),
    body: body,
  );

  Future<http.Response> deleteStudyQuestion(
    String studyId,
    String questionId,
  ) => _apiRequest(
    method: 'DELETE',
    url: endpoint('/studies/$studyId/questions/$questionId'),
  );

  Future<http.Response> importStudyQuestions(
    String studyId,
    Map<String, dynamic> body,
  ) => _apiRequest(
    method: 'POST',
    url: endpoint('/studies/$studyId/questions/import'),
    body: body,
  );

  Future<http.Response> publishStudy(
    String studyId,
    Map<String, dynamic> body,
  ) => _apiRequest(
    method: 'POST',
    url: endpoint('/studies/$studyId/publication'),
    body: body,
  );

  Future<http.Response> generateQuestionVisual(
    String studyId,
    String questionId,
    Map<String, dynamic> body,
  ) => _apiRequest(
    method: 'POST',
    url: endpoint('/studies/$studyId/questions/$questionId/visual'),
    body: body,
  );

  Future<http.Response> getReportsPicker() =>
      _apiRequest(method: 'GET', url: endpoint('/reports/picker'));

  // Public catalog & quizzes
  Future<http.Response> getCatalog({String? q, int? page, int? limit}) =>
      _apiRequest(
        method: 'GET',
        url: endpoint('/catalog'),
        queryParams: {
          if (q != null && q.isNotEmpty) 'q': q,
          if (page != null) 'page': page,
          if (limit != null) 'limit': limit,
        },
      );

  Future<http.Response> getCatalogQuestions({
    String? q,
    int? page,
    int? limit,
  }) => _apiRequest(
    method: 'GET',
    url: endpoint('/catalog/questions'),
    queryParams: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
    },
  );

  /// Searches the public question catalog using the CertAPI #49 contract.
  /// The projection intentionally contains no answer, explanation, citation,
  /// or source fields; consumers should render only fields returned by the
  /// server.
  Future<http.Response> searchPublicQuestions({
    String? q,
    String? language,
    String? origin,
    required int limit,
    required int offset,
  }) {
    if (limit < 1 || limit > 50) {
      throw ArgumentError.value(limit, 'limit', 'Must be between 1 and 50');
    }
    if (offset < 0) {
      throw ArgumentError.value(offset, 'offset', 'Must be non-negative');
    }
    return _apiRequest(
      method: 'GET',
      url: endpoint('/catalog/questions'),
      queryParams: {
        if (q != null && q.isNotEmpty) 'q': q,
        if (language != null && language.isNotEmpty) 'language': language,
        if (origin != null && origin.isNotEmpty) 'origin': origin,
        'limit': limit,
        'offset': offset,
      },
    );
  }

  /// Reuses an explicit page-sized set of current public immutable versions.
  /// The backend revalidates public membership and derives provenance.
  Future<http.Response> reuseStudyQuestions(
    String studyId,
    List<String> questionVersionIds,
  ) {
    if (questionVersionIds.isEmpty || questionVersionIds.length > 50) {
      throw ArgumentError.value(
        questionVersionIds.length,
        'questionVersionIds.length',
        'Must be between 1 and 50',
      );
    }
    return _apiRequest(
      method: 'POST',
      url: endpoint('/studies/$studyId/questions/reuse'),
      body: {'question_version_ids': questionVersionIds},
    );
  }

  Future<http.Response> getQuiz(String quizId) =>
      _apiRequest(method: 'GET', url: endpoint('/quizzes/$quizId'));

  Future<http.Response> getQuizStatistics(String quizId) =>
      _apiRequest(method: 'GET', url: endpoint('/quizzes/$quizId/statistics'));

  Future<http.Response> deleteQuiz(String quizId) =>
      _apiRequest(method: 'DELETE', url: endpoint('/quizzes/$quizId'));

  // Attempts
  Future<http.Response> startAttempt(String quizId) =>
      _apiRequest(method: 'POST', url: endpoint('/quizzes/$quizId/attempts'));

  Future<http.Response> listAttempts({int? page, int? limit}) => _apiRequest(
    method: 'GET',
    url: endpoint('/attempts'),
    queryParams: {
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
    },
  );

  Future<http.Response> getAttempt(String attemptId) =>
      _apiRequest(method: 'GET', url: endpoint('/attempts/$attemptId'));

  Future<http.Response> putAttemptAnswer(
    String attemptId,
    String questionId,
    Map<String, dynamic> body,
  ) => _apiRequest(
    method: 'PUT',
    url: endpoint('/attempts/$attemptId/answers/$questionId'),
    body: body,
  );

  Future<http.Response> postAttemptEvent(
    String attemptId,
    Map<String, dynamic> body,
  ) => _apiRequest(
    method: 'POST',
    url: endpoint('/attempts/$attemptId/events'),
    body: body,
  );

  Future<http.Response> submitAttempt(String attemptId) =>
      _apiRequest(method: 'POST', url: endpoint('/attempts/$attemptId/submit'));

  Future<http.Response> getAttemptResults(String attemptId) =>
      _apiRequest(method: 'GET', url: endpoint('/attempts/$attemptId/results'));

  Future<http.Response> getMyStatistics() =>
      _apiRequest(method: 'GET', url: endpoint('/me/statistics'));

  // Identity & certificates
  Future<http.Response> getMyIdentity() =>
      _apiRequest(method: 'GET', url: endpoint('/me/identity'));

  Future<http.Response> confirmMyIdentity(Map<String, dynamic> body) =>
      _apiRequest(method: 'PUT', url: endpoint('/me/identity'), body: body);

  Future<http.Response> issueCertificate(String attemptId) => _apiRequest(
    method: 'POST',
    url: endpoint('/attempts/$attemptId/certificate'),
  );

  Future<http.Response> verifyCertificate(String certificateCode) =>
      _apiRequest(
        method: 'GET',
        url: endpoint('/certificates/$certificateCode'),
      );

  Uri certificateFileUri(String certificateCode, String format) =>
      endpoint('/certificates/$certificateCode/files/$format');

  // Admin routes (Area 11)
  Future<http.Response> getAdminSettings() =>
      _apiRequest(method: 'GET', url: endpoint('/admin/settings'));

  Future<http.Response> patchAdminSettings(Map<String, dynamic> body) =>
      _apiRequest(
        method: 'PATCH',
        url: endpoint('/admin/settings'),
        body: body,
      );

  Future<http.Response> listAdminSchemaVersions(String schema) => _apiRequest(
    method: 'GET',
    url: endpoint('/admin/schemas/$schema/versions'),
  );

  Future<http.Response> createAdminSchemaVersion(
    String schema,
    Map<String, dynamic> body,
  ) => _apiRequest(
    method: 'POST',
    url: endpoint('/admin/schemas/$schema/versions'),
    body: body,
  );

  Future<http.Response> getAdminSchemaVersion(String schema, String version) =>
      _apiRequest(
        method: 'GET',
        url: endpoint('/admin/schemas/$schema/versions/$version'),
      );

  Future<http.Response> patchAdminSchemaVersion(
    String schema,
    String version,
    Map<String, dynamic> body,
  ) => _apiRequest(
    method: 'PATCH',
    url: endpoint('/admin/schemas/$schema/versions/$version'),
    body: body,
  );

  Future<http.Response> deleteAdminSchemaVersion(
    String schema,
    String version,
  ) => _apiRequest(
    method: 'DELETE',
    url: endpoint('/admin/schemas/$schema/versions/$version'),
  );

  Future<http.Response> patchAdminSchemaVersionStatus(
    String schema,
    String version,
    Map<String, dynamic> body,
  ) => _apiRequest(
    method: 'PATCH',
    url: endpoint('/admin/schemas/$schema/versions/$version/status'),
    body: body,
  );

  Future<http.Response> patchAdminQuizOrigin(
    String quizId,
    Map<String, dynamic> body,
  ) => _apiRequest(
    method: 'PATCH',
    url: endpoint('/admin/quizzes/$quizId/origin'),
    body: body,
  );

  Future<http.Response> patchAdminHolder(
    String holderId,
    Map<String, dynamic> body,
  ) => _apiRequest(
    method: 'PATCH',
    url: endpoint('/admin/holders/$holderId'),
    body: body,
  );

  Future<http.Response> revokeAdminCertificate(
    String code,
    Map<String, dynamic> body,
  ) => _apiRequest(
    method: 'POST',
    url: endpoint('/admin/certificates/$code/revocation'),
    body: body,
  );

  Future<http.Response> getAdminCleanup() =>
      _apiRequest(method: 'GET', url: endpoint('/admin/cleanup'));

  Future<http.Response> retryAdminCleanup(String cleanupId) => _apiRequest(
    method: 'POST',
    url: endpoint('/admin/cleanup/$cleanupId/retry'),
  );

  Future<http.Response> getAdminStatistics() =>
      _apiRequest(method: 'GET', url: endpoint('/admin/statistics'));
}
