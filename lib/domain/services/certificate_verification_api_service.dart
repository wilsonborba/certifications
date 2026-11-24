import 'dart:convert';

import 'package:certifications/core/settings.dart';
import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/models/certificate_verification.dart';

class CertificateApiException implements Exception {
  const CertificateApiException(this.statusCode);
  final int statusCode;

  @override
  String toString() => 'CertificateApiException(statusCode: $statusCode)';
}

class CertificateFile {
  const CertificateFile({required this.contentType, required this.bytes});
  final String contentType;
  final List<int> bytes;
}

/// Public verification and certificate artifact access from the Rust API.
/// The downloadable payload is returned without an activity-summary field.
class CertificateVerificationApiService {
  CertificateVerificationApiService({ApiAdapter? adapter})
    : _adapter = adapter ?? ApiAdapter();

  final ApiAdapter _adapter;
  String get _base => '${app_settings.ASODYA_API_URL}/apps/certifications/v1';

  Future<CertificateVerification> verify(String code) async {
    final response = await _adapter.get(
      Uri.parse('$_base/certificates/${Uri.encodeComponent(code)}'),
    );
    _ensureSuccess(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Expected a JSON object from certificate API',
      );
    }
    return CertificateVerification.fromJson(decoded);
  }

  Future<CertificateFile> downloadPdf(String code) async =>
      _download(code, 'pdf', 'application/pdf');

  Future<CertificateFile> downloadImage(String code) async =>
      _download(code, 'image', 'image/svg+xml');

  Future<CertificateFile> _download(
    String code,
    String format,
    String expectedContentType,
  ) async {
    final response = await _adapter.get(
      Uri.parse(
        '$_base/certificates/${Uri.encodeComponent(code)}/files/$format',
      ),
    );
    _ensureSuccess(response);
    final contentType = response.headers['content-type']?.split(';').first;
    if (contentType != expectedContentType) {
      throw const FormatException('Unexpected certificate file content type');
    }
    return CertificateFile(
      contentType: contentType!,
      bytes: response.bodyBytes,
    );
  }

  void _ensureSuccess(dynamic response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CertificateApiException(response.statusCode);
    }
  }
}
