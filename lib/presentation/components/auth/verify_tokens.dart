import 'dart:convert';
import 'package:accredit/domain/services/api_certification_manager.dart';
import 'package:accredit/core/utils/my_logs.dart';

Future<bool> isThereTokens() async {
  final CertificationManager certificationManager = CertificationManager();

  try {
    final tokensResponse = await certificationManager.getAllUserTokens();

    final bodyStr = tokensResponse.body.trim();
    if (bodyStr.isEmpty) return false;

    final decoded = jsonDecode(bodyStr);

    // Expecting: { "data": [...], "message": "..." }
    if (decoded is! Map<String, dynamic>) {
      debug('Unexpected tokens response shape (not a JSON object): $decoded');
      return false;
    }

    final data = decoded['data'];

    if (data == null) return false;

    // If backend returns list of token rows
    if (data is List) {
      return data.isNotEmpty;
    }

    // Defensive: if backend ever changes to return a single object
    if (data is Map<String, dynamic>) {
      return data.isNotEmpty;
    }

    debug('Unexpected "data" type: ${data.runtimeType}');
    return false;
  } catch (e) {
    warning('Error validating tokens response: $e');
    return false;
  }
}
