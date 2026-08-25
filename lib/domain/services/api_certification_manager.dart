import 'dart:convert';

import 'package:accredit/core/settings.dart';

import 'package:accredit/core/utils/my_logs.dart';
import 'package:accredit/dal/local/local_source_adapter.dart';
import 'package:accredit/dal/remote/api_adapter.dart';
import 'package:accredit/domain/models/quiz.dart';
import 'package:accredit/domain/models/topic_identifications.dart';
import 'package:accredit/presentation/components/auth/verify_session.dart';

import 'package:http/http.dart';

// session_headers.dart
import 'package:http/http.dart' as http;

class SessionHeaderManager {
  /// Builds headers with the current CSRF token when available.
  Future<Map<String, String>> buildAuthedHeaders(
    Map<String, String> base,
  ) async {
    final headers = {...base};

    try {
      final csrfToken = readCsrfToken();
      if (csrfToken != null) {
        headers['X-CSRF-Token'] = csrfToken;
      }
    } catch (e) {
      debug('Error reading CSRF token: $e');
    }

    return headers;
  }
}

// certification_manager.dart

class CertificationManager {
  final String baseApi = app_settings.ASODYA_API_URL;
  final String apiEntity = '/apps';
  final String appName = '/certifications';
  final String appVersion = '/v1';

  late final String baseUrl;

  CertificationManager() {
    baseUrl = "$baseApi$apiEntity$appName$appVersion";
  }

  // Keep base headers immutable; build per-request headers via SessionHeaderManager.
  static const Map<String, String> _baseHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  final SessionHeaderManager _session = SessionHeaderManager();

  Future<http.Response> _authedRequest({
    required String method,
    required Uri url,
    Map<String, String>? headers,
    dynamic body,
    Map<String, dynamic>? queryParams,
    Encoding? encoding,
    bool updateNanOnSuccessOnly = true,
  }) async {
    final mergedBase = {..._baseHeaders, if (headers != null) ...headers};
    final authedHeaders = await _session.buildAuthedHeaders(mergedBase);

    debug('HTTP ${method.toUpperCase()} $url headers: $authedHeaders');

    final api = ApiAdapter(defaultHeaders: authedHeaders);

    final res = await api.request(
      method: method,
      url: url,
      headers: const {}, // already merged into defaultHeaders above
      body: body,
      queryParams: queryParams,
      encoding: encoding,
    );

    return res;
  }

  Future<http.Response> _authedGet(
    Uri url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) => _authedRequest(
    method: 'GET',
    url: url,
    headers: headers,
    queryParams: queryParams,
  );

  Future<http.Response> _authedPost(
    Uri url, {
    Map<String, String>? headers,
    dynamic body,
    Encoding? encoding,
    Map<String, dynamic>? queryParams,
  }) => _authedRequest(
    method: 'POST',
    url: url,
    headers: headers,
    body: body,
    encoding: encoding,
    queryParams: queryParams,
  );

  Future<http.Response> _authedPut(
    Uri url, {
    Map<String, String>? headers,
    dynamic body,
    Encoding? encoding,
    Map<String, dynamic>? queryParams,
  }) => _authedRequest(
    method: 'PUT',
    url: url,
    headers: headers,
    body: body,
    encoding: encoding,
    queryParams: queryParams,
  );

  Future<http.Response> _authedPatch(
    Uri url, {
    Map<String, String>? headers,
    dynamic body,
    Encoding? encoding,
    Map<String, dynamic>? queryParams,
  }) => _authedRequest(
    method: 'PATCH',
    url: url,
    headers: headers,
    body: body,
    encoding: encoding,
    queryParams: queryParams,
  );

  Future<http.Response> _authedDelete(
    Uri url, {
    Map<String, String>? headers,
    dynamic body,
    Encoding? encoding,
    Map<String, dynamic>? queryParams,
  }) => _authedRequest(
    method: 'DELETE',
    url: url,
    headers: headers,
    body: body,
    encoding: encoding,
    queryParams: queryParams,
  );

  // -------------------------
  // Your existing API methods
  // -------------------------

  Future<http.Response> applyComplain(
    String text,
    dynamic questionId,
    bool isForPDF,
    dynamic contextId,
    dynamic pdfQuestionId,
  ) async {
    debug('Applying complaint (isForPDF=$isForPDF)');

    final Uri uriPath;
    final Map<String, dynamic> payload;

    if (!isForPDF) {
      // DB Postgres
      uriPath = Uri.parse('$baseUrl/context/complaints');
      payload = {'question_id': questionId, 'complaint_text': text};
    } else {
      // temp on Redis/Valkey
      uriPath = Uri.parse('$baseUrl/pdf/context/complaints');
      payload = {
        'document_id': contextId,
        'complaint_text': text,
        'pdf_question_id': pdfQuestionId,
      };
    }

    return _authedPost(uriPath, body: jsonEncode(payload));
  }

  Future<http.Response> submitQuiz(
    List<AnswerSelection> payload,
    Duration timeSpent,
    CertificationFormData formData,
    bool isForPDF,
    String contextId,
  ) async {
    final Map<String, dynamic> body = {
      'answers': payload.map((e) => e.toJson()).toList(),
      'time_spent_seconds': timeSpent.inSeconds,
      'certification_title': formData.certificationTitle,
      'full_name': formData.fullName,
      'language': formData.language,
      'is_for_pdf': isForPDF,
    };

    if (isForPDF) {
      body['document_id'] = contextId;
    }

    return _authedPost(
      Uri.parse('$baseUrl/quiz/revision'),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> getCertification(String certificationId) {
    return _authedGet(
      Uri.parse('$baseUrl/quiz/certifications/$certificationId'),
    );
  }

  Future<http.Response> getUserCertifications() {
    return _authedGet(Uri.parse('$baseUrl/quiz/certifications'));
  }

  Future<http.Response> getCards() {
    return _authedGet(Uri.parse('$baseUrl/all_items'));
  }

  Future<http.Response> getTopicsFromCard(
    String itemName,
    int page,
    int perPage,
  ) {
    return _authedGet(
      Uri.parse('$baseUrl/topics/$itemName'),
      queryParams: {'page': page, 'per_page': perPage},
    );
  }

  Future<http.Response> searchTopics(
    String itemName,
    String query,
    int page,
    int perPage,
    String mode,
    bool fillPage,
    int maxExtraPages,
  ) {
    return _authedGet(
      Uri.parse('$baseUrl/search/$itemName'),
      queryParams: {
        'q': query,
        'page': page,
        'per_page': perPage,
        'mode': mode,
        // If backend expects true/false strings:
        'fill_page': fillPage.toString(),
        'max_extra_pages': maxExtraPages,
      },
    );
  }

  Future<http.Response> requestNewCards(String url) {
    final body = {'url': url};

    return _authedPost(
      Uri.parse('$baseUrl/topics/solicitate_new'),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> createUserToken(
    String
    provider, // kept for signature compatibility (not used in your original body)
    String name,
    String apiKey,
    bool isDefault,
  ) async {
    final body = {
      'token_name': name,
      'token_value': apiKey,
      'is_default': isDefault,
      // If your backend actually needs provider, add it:
      'provider_name': provider,
    };

    final res = await _authedPost(
      Uri.parse('$baseUrl/tokens/create_token'),
      body: jsonEncode(body),
    );

    debug('createUserToken response body: ${res.body}');
    return res;
  }

  Future<http.Response> deleteUserToken(String tokenName) async {
    final res = await _authedDelete(
      Uri.parse('$baseUrl/tokens/delete_token/$tokenName'),
    );

    debug('deleteUserToken response body: ${res.body}');
    return res;
  }

  Future<http.Response> getAllUserTokens() async {
    final res = await _authedGet(Uri.parse('$baseUrl/tokens/user_tokens'));

    debug('getAllUserTokens response body: ${res.body}');
    return res;
  }

  Future<http.Response> getUserUsage({
    String? providerModelDescription,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _authedGet(
      Uri.parse('$baseUrl/tokens/usage'),
      queryParams: {
        if (providerModelDescription != null &&
            providerModelDescription.isNotEmpty)
          'provider_model_description': providerModelDescription,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      },
    );
  }

  Future<http.Response> setDefaultUserToken(String tokenName) async {
    final body = {'token_name': tokenName};

    final res = await _authedPatch(
      Uri.parse('$baseUrl/tokens/set_default'),
      body: jsonEncode(body),
    );
    debug('setDefaultUserToken response body: ${res.body}');
    return res;
  }

  // -------------------------
  // Optional: multipart helper
  // -------------------------
  //
  // If you later add endpoints that upload files, prefer to funnel them through
  // a single authed multipart method so cookies + csrf handling are applied
  // consistently.
  Future<http.Response> postMultipart({
    required Uri url,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    Map<String, String>? fields,
    List<MultipartFileData>? files,
    bool updateNanOnSuccessOnly = true,
  }) async {
    final mergedBase = {..._baseHeaders, if (headers != null) ...headers};
    final authedHeaders = await _session.buildAuthedHeaders(mergedBase);

    debug('HTTP POST(MULTIPART) $url headers: $authedHeaders');

    final api = ApiAdapter(defaultHeaders: authedHeaders);

    final res = await api.postMultipart(
      url: url,
      queryParams: queryParams,
      headers: const {}, // already merged into defaultHeaders above
      fields: fields,
      files: files,
    );

    return res;
  }
}
