const String appContextQueryParamName = 'app_context';
const String authExchangeTokenQueryParamName = 'auth_exchange_token';

Map<String, String> buildAppContextQueryParameters(
  String encryptedAppContext, {
  Map<String, String> baseQueryParameters = const {},
}) {
  return {
    ...baseQueryParameters,
    appContextQueryParamName: encryptedAppContext,
  };
}

String? resolveAuthExchangeToken({
  required String? Function(String key) readParam,
}) {
  final authExchangeToken = readParam(authExchangeTokenQueryParamName);
  if (authExchangeToken != null && authExchangeToken.isNotEmpty) {
    return authExchangeToken;
  }

  return null;
}
