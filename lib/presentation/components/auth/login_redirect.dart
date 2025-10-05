import 'dart:convert';
import 'package:accredit/core/settings.dart';
import 'package:accredit/core/utils/my_encryption.dart';
import 'package:accredit/core/utils/my_logs.dart';

MyEncryption encryptor = MyEncryption();

Future<String> urlRedirectionToLogin() async {
  debug('Redirecting to login...');

  // 1) Prepare payload as JSON string
  final payloadJson = jsonEncode(app_settings.applicationInfo);
  debug('Payload to encrypt: $payloadJson');

  // 2) Encrypt
  final encrypted = await encryptor.encryptPayload(payloadJson);

  // 3) Build URL safely (this encodes +,/,… as %2B,%2F,…)
  final base = Uri.parse(app_settings.ASODYA_AUTH_LOGIN_URL); // e.g. http://localhost:7000/log_in
  final url = base.replace(queryParameters: {
    ...base.queryParameters,
    app_settings.AUTH_PARAM_KEY_NAME: encrypted,
  }).toString();

  debug('Redirect URL: $url');
  return url;
}