import 'package:accredit/core/utils/my_logs.dart';
import 'package:accredit/dal/local/local_source_adapter.dart';

String? readCsrfToken() => readCookie('csrf');

/// Checks session presence using a readable CSRF cookie.
/// The actual session cookie (`sid`) is HttpOnly and intentionally not readable
/// from Flutter web.
Future<bool> isThereSession({String cookieName = 'csrf'}) async {
  try {
    final cookieValue = readCookie(cookieName);
    if (cookieValue == null || cookieValue.isEmpty) {
      debug('Session check: cookie "$cookieName" missing or empty.');
      return false;
    }
    debug('Session check OK for cookie "$cookieName".');
    return true;
  } catch (e) {
    debug('Session check error: $e');
    return false;
  }
}
