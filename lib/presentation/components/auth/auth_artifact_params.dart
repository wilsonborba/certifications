const String appContextQueryParamName = 'app_context';
const String authExchangeTokenQueryParamName = 'auth_exchange_token';
const String legacyAuthArtifactQueryParamName = 'tokenized';

Map<String, String> buildAppContextQueryParameters(
  String encryptedAppContext, {
  Map<String, String> baseQueryParameters = const {},
}) {
  return {
    ...baseQueryParameters,
    appContextQueryParamName: encryptedAppContext,
    // TODO(auth): remove the legacy parameter after the auth frontend is updated.
    legacyAuthArtifactQueryParamName: encryptedAppContext,
  };
}

String? resolveAuthExchangeToken({
  required String? Function(String key) readParam,
}) {
  final authExchangeToken = readParam(authExchangeTokenQueryParamName);
  if (authExchangeToken != null && authExchangeToken.isNotEmpty) {
    return authExchangeToken;
  }

  final legacyAuthExchangeToken = readParam(legacyAuthArtifactQueryParamName);
  if (legacyAuthExchangeToken != null && legacyAuthExchangeToken.isNotEmpty) {
    return legacyAuthExchangeToken;
  }

  return null;
}
