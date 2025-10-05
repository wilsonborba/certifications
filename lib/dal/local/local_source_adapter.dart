
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:accredit/core/utils/my_logs.dart';
import 'dart:convert';
import 'package:web/web.dart' as web; 



  String? readCookie(String name) {
    final cookies = web.document.cookie; // e.g. "foo=bar; baz=qux"
    if (cookies == null || cookies.isEmpty) return null;

    for (final cookie in cookies.split(';')) {
      final parts = cookie.trim().split('=');
      if (parts.length == 2 && parts[0] == name) {
        return parts[1];
      }
    }
    return null;
  }




class LocalSourceAdapter {




LocalSourceAdapter({required this.namespace});

  final String namespace;

  String _ns(String key) => '$namespace::$key';

  web.Storage get _store {
    final storage = web.window.localStorage;
    if (storage == null) {
      throw StateError('localStorage is not available.');
    }
    return storage;
  }

  Future<void> create(String key, dynamic value) async {
    final k = _ns(key);
    if (_store.getItem(k) != null) {
      throw StateError('Key already exists: $key');
    }
    _store.setItem(k, jsonEncode(value));
  }

  Future<void> upsert(String key, dynamic value) async {
    _store.setItem(_ns(key), jsonEncode(value));
  }

  Future<T?> read<T>(String key) async {
    final raw = _store.getItem(_ns(key));
    if (raw == null) return null;
    return jsonDecode(raw) as T;
  }

  Future<void> update<T>(String key, T Function(T current) transform) async {
    final k = _ns(key);
    final raw = _store.getItem(k);
    if (raw == null) throw StateError('Key not found: $key');
    final current = jsonDecode(raw) as T;
    final next = transform(current);
    _store.setItem(k, jsonEncode(next));
  }

  Future<void> delete(String key) async {
    _store.removeItem(_ns(key));
  }

  Future<List<String>> keys() async {
    final prefix = '$namespace::';
    final s = _store;
    final out = <String>[];
    final len = s.length;
    for (var i = 0; i < len; i++) {
      final fullKey = s.key(i);
      if (fullKey == null) continue;
      if (fullKey.startsWith(prefix)) {
        out.add(fullKey.substring(prefix.length));
      }
    }
    return out;
  }

  Future<Map<String, dynamic>> readAll() async {
    final out = <String, dynamic>{};
    for (final k in await keys()) {
      out[k] = await read(k);
    }
    return out;
  }

  Future<void> upsertAll(Map<String, dynamic> entries) async {
    entries.forEach((k, v) => _store.setItem(_ns(k), jsonEncode(v)));
  }

  Future<void> clearNamespace() async {
    final s = _store;
    for (final k in await keys()) {
      s.removeItem(_ns(k));
    }
  }

  Future<bool> exists(String key) async {
    return _store.getItem(_ns(key)) != null;
  }


  Future<String> getEnvData(String key) async {
    try {
      // Retrieve the value from the environment variables
      final value = dotenv.env[key.toUpperCase()];
      if (value == null) {
        throw Exception("Key [$key] not found in environment!");
      }
      return value;
    } catch (e) {
      // Handle any errors that occur during retrieval
      debug("Error retrieving environment variable: $e");
      rethrow;
    }
  }

}
