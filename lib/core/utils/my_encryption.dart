import 'package:certifications/core/settings.dart';
import 'package:certifications/core/utils/my_logs.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class MyEncryption {
  Future<String?> getSaltKey() async {
    final sharedKey = app_settings.FERNET_KEY_SECRET;

    if (sharedKey.isNotEmpty) {
      // debug("Salt Key found: $sharedKey");
      return sharedKey;
    }

    final errorMessage = "Salt Key was not found: $sharedKey";
    debug(errorMessage);
    return null;
  }

  Future<String?> decryptPayload(String encryptedPayload) async {
    try {
      final base64Key = await getSaltKey();

      if (base64Key == null) {
        const errorMessage = "Key from decrypt cannot be null";
        debug(errorMessage);
        return null;
      }

      encrypt.Key key;

      try {
        key = encrypt.Key.fromBase64(base64Key);

        if (key.bytes.length != 32) {
          final errorMessage =
              "Fernet Key not valid, it must contains 32 bytes, but it has ${key.bytes.length}.";
          debug(errorMessage);
          // throw Exception("Chave Fernet inválida! Deve ter 32 bytes, mas tem ${key.bytes.length}.");
          return null;
        }
      } catch (e) {
        final errorMessage = "Fernet Key Error: ${e.toString()}";
        debug(errorMessage);
        return null;
      }

      try {
        final fernet = encrypt.Fernet(key);
        final encrypter = encrypt.Encrypter(fernet);

        final decrypted = encrypter.decrypt64(encryptedPayload);

        return decrypted;
      } catch (e) {
        final errorMessage = "Decryption Error: ${e.toString()}";
        debug(errorMessage);
        return null;
      }
    } catch (e) {
      final errorMessage = "Decryption Unknown Error: ${e.toString()}";
      debug(errorMessage);
      return null;
    }
  }

  Future<String?> encryptPayload(String plainText) async {
    try {
      final base64Key = await getSaltKey();

      if (base64Key == null) {
        const errorMessage = "Key from encrypt cannot be null";
        debug(errorMessage);
        return null;
      }

      encrypt.Key key;

      try {
        key = encrypt.Key.fromBase64(base64Key);

        if (key.bytes.length != 32) {
          final errorMessage =
              "Fernet Key not valid, it must contains 32 bytes, but it has ${key.bytes.length}.";
          debug(errorMessage);
          // throw Exception("Chave Fernet inválida! Deve ter 32 bytes, mas tem ${key.bytes.length}.");
          return null;
        }
      } catch (e) {
        final errorMessage = "Fernet Key Error: ${e.toString()}";
        debug(errorMessage);
        return null;
      }

      try {
        final fernet = encrypt.Fernet(key);
        final encrypter = encrypt.Encrypter(fernet);

        final encrypted = encrypter.encrypt(plainText);

        return encrypted.base64;
      } catch (e) {
        final errorMessage = "Encryption Error: ${e.toString()}";
        debug(errorMessage);
        return null;
      }
    } catch (e) {
      final errorMessage = "Encryption Unknown Error: ${e.toString()}";
      debug(errorMessage);
      return null;
    }
  }
}
