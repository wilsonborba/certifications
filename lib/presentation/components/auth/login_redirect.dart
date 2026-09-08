import 'dart:convert';
import 'package:certifications/core/settings.dart';
import 'package:certifications/core/utils/my_encryption.dart';
import 'package:certifications/core/utils/my_logs.dart';
import 'package:certifications/presentation/components/auth/auth_artifact_params.dart';

MyEncryption encryptor = MyEncryption();

Future<String> urlRedirectionToAuth({bool isToLogin = true}) async {
  debug('Redirecting to login...');

  final appContextJson = jsonEncode(app_settings.applicationInfo);
  debug('App context to encrypt: $appContextJson');

  final encryptedAppContext = await encryptor.encryptPayload(appContextJson);
  if (encryptedAppContext == null || encryptedAppContext.isEmpty) {
    throw Exception('The application context could not be encrypted.');
  }

  final base = Uri.parse(
    isToLogin
        ? app_settings.ASODYA_AUTH_LOGIN_URL
        : app_settings.ASODYA_AUTH_SIGNUP_URL,
  );

  final url = base
      .replace(
        queryParameters: {
          ...buildAppContextQueryParameters(
            encryptedAppContext,
            baseQueryParameters: base.queryParameters,
          ),
        },
      )
      .toString();

  debug('Redirect URL: $url');
  return url;
}
