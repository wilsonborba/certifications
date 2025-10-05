import 'package:accredit/core/utils/my_encryption.dart';
import 'package:accredit/dal/local/local_source_adapter.dart';
import 'package:accredit/core/utils/my_logs.dart';

// assumes your existing readCookie(String name) is available.

/// Checks session presence using:
/// 1) a readable cookie (default: "hint")
/// 2) a namespaced localStorage entry via LocalSourceAdapter (default ns: "auth", key: "n-a-n")
///
/// Returns true only if BOTH are present and non-empty.
/// NOTE: If the cookie is HttpOnly, JS (and therefore Flutter web) cannot read it, so this returns false.
Future<bool> isThereSession({
  String cookieName = 'hint',
  String storageNamespace = 'ath',
  String storageKey = 'n-a-n',
}) async {
  try {
    // 1) Cookie check
    final cookieValue = readCookie(cookieName);
    if (cookieValue == null || cookieValue.isEmpty) {
      debug('Session check: cookie "$cookieName" missing or empty.');
      return false;
    }

    // 2) LocalStorage (via adapter) check
    final adapter = LocalSourceAdapter(namespace: storageNamespace);

    // Prefer read() to ensure we don't just have a present-but-empty value.
    final value = await adapter.read<dynamic>(storageKey);
    if (value == null) {
      debug('Session check: "$storageNamespace::$storageKey" not found.');
      return false;
    }

    // Treat empty strings / empty containers as not valid session indicators
    if (value is String && value.trim().isEmpty) {
      debug('Session check: "$storageNamespace::$storageKey" is empty string.');
      return false;
    }
    if (value is Map && value.isEmpty) {
      debug('Session check: "$storageNamespace::$storageKey" is an empty Map.');
      return false;
    }
    if (value is List && value.isEmpty) {
      debug('Session check: "$storageNamespace::$storageKey" is an empty List.');
      return false;
    }

    debug('Session check OK for cookie "$cookieName" and "$storageNamespace::$storageKey".');
    return true;
  } catch (e) {
    debug('Session check error: $e');
    return false;
  }
}


  Future<String?> readNextAuthNounce() async {
    final LocalSourceAdapter localSourceAdapter = LocalSourceAdapter(namespace: 'ath');
    final encryptedNounce = await localSourceAdapter.read('n-a-n');
    // decrypt nounce here 
    final encryption = MyEncryption();
    return encryption.decryptPayload(encryptedNounce);
  }

  saveNextAuthNounce(String nan) async {
    final LocalSourceAdapter localSourceAdapter = LocalSourceAdapter(namespace: 'ath');
    await localSourceAdapter.upsert('n-a-n', nan);
    debug('next auth nounce saved: $nan');
  }