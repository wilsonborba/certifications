import 'dart:convert';

import 'package:certifications/dal/remote/certifications_api_client.dart';
import 'package:certifications/domain/models/authoring.dart';
import 'package:http/http.dart' as http;

class QuestionAuthoringException implements Exception {
  const QuestionAuthoringException(this.statusCode, {this.message});

  final int statusCode;
  final String? message;

  @override
  String toString() =>
      'QuestionAuthoringException(statusCode: $statusCode, message: $message)';
}

/// Typed owner-authoring operations backed by the Certifications Rust routes.
class QuestionAuthoringService {
  QuestionAuthoringService({CertificationsApiClient? client})
    : _client = client ?? CertificationsApiClient();

  final CertificationsApiClient _client;

  Future<List<AuthoringQuestion>> list(String studyId) async {
    final payload = _decode(await _client.listStudyQuestions(studyId));
    final items = payload['items'];
    if (items is! List) {
      throw const FormatException(
        'Expected question items from Certifications',
      );
    }
    return items.map(_questionFromObject).toList(growable: false);
  }

  Future<AuthoringQuestion> create({
    required String studyId,
    required String language,
    required String prompt,
    required List<AuthoringAlternative> alternatives,
    required String correctId,
    required String explanation,
    String citationRef = '',
  }) async {
    final payload = _decode(
      await _client.createStudyQuestion(studyId, {
        'language': language,
        'prompt': prompt,
        'alternatives': alternatives.map((item) => item.toJson()).toList(),
        'correct_id': correctId,
        'explanation': explanation,
        'citation_ref': citationRef,
      }),
    );
    return AuthoringQuestion.fromJson(payload);
  }

  Future<AuthoringQuestion> update({
    required String studyId,
    required AuthoringQuestion question,
    required String language,
    required String prompt,
    required List<AuthoringAlternative> alternatives,
    required String correctId,
    required String explanation,
    required String citationRef,
  }) async {
    final payload = _decode(
      await _client.patchStudyQuestion(
        studyId,
        question.id,
        question.toUpdateJson(
          language: language,
          prompt: prompt,
          alternatives: alternatives,
          correctId: correctId,
          explanation: explanation,
          citationRef: citationRef,
        ),
      ),
    );
    return AuthoringQuestion.fromJson(payload);
  }

  Future<CsvImportResult> previewCsv({
    required String studyId,
    required String csvText,
  }) async => CsvImportResult.fromJson(
    _decode(
      await _client.importStudyQuestions(studyId, {
        'csv_text': csvText,
        'confirm': false,
      }),
    ),
  );

  Future<CsvImportResult> confirmCsv({
    required String studyId,
    required String csvText,
  }) async => CsvImportResult.fromJson(
    _decode(
      await _client.importStudyQuestions(studyId, {
        'csv_text': csvText,
        'confirm': true,
      }),
    ),
  );

  Future<PublishedQuiz> publish({
    required String studyId,
    required String title,
    required List<String> tags,
  }) async => PublishedQuiz.fromJson(
    _decode(
      await _client.publishStudy(studyId, {
        'title': title,
        if (tags.isNotEmpty) 'tags': tags,
      }),
    ),
  );

  Future<PreparedQuestionVisualJob> prepareVisualJob({
    required String studyId,
    required AuthoringQuestion question,
    required String templateId,
    required int templateVersion,
    required Map<String, List<String>> mapping,
    required Map<String, dynamic> config,
    required List<Map<String, dynamic>> rows,
  }) async {
    final prepared = PreparedQuestionVisualJob.fromJson(
      _decode(
        await _client.prepareQuestionVisualJob(studyId, question.id, {
          'template_id': templateId,
          'template_version': templateVersion,
          'mapping': mapping,
          'config': config,
          'rows': rows,
          'width': 800,
          'height': 480,
          'scale': 2,
          'ttl_seconds': 900,
        }),
      ),
    );
    if (prepared.questionId != question.id ||
        prepared.questionVersionId != question.versionId ||
        prepared.templateId != templateId ||
        prepared.templateVersion != templateVersion) {
      throw const FormatException(
        'Prepared visual job does not match question',
      );
    }
    return prepared;
  }

  Future<QuestionVisual> uploadVisual({
    required String studyId,
    required AuthoringQuestion question,
    required PreparedQuestionVisualJob job,
    required List<int> pngBytes,
  }) async {
    if (job.questionId != question.id ||
        job.questionVersionId != question.versionId ||
        pngBytes.length > 4 * 1024 * 1024) {
      throw const FormatException('Question visual upload is out of bounds');
    }
    return QuestionVisual.fromJson(
      _decode(
        await _client.uploadQuestionVisual(studyId, question.id, {
          'question_version_id': job.questionVersionId,
          'render_job_id': job.jobId,
          'expected_width': job.width,
          'expected_height': job.height,
          'expected_scale': job.scale,
          'png_base64': base64Encode(pngBytes),
        }),
      ),
    );
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String? message;
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          final error = body['error'];
          message = error is String
              ? error
              : error is Map<String, dynamic>
              ? (error['message'] as String?) ?? (error['code'] as String?)
              : body['message'] as String?;
        }
      } on FormatException {
        // Status remains authoritative when the server body is not JSON.
      }
      throw QuestionAuthoringException(response.statusCode, message: message);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected JSON object from Certifications');
    }
    return decoded;
  }

  AuthoringQuestion _questionFromObject(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid question object from Certifications',
      );
    }
    return AuthoringQuestion.fromJson(value);
  }
}
