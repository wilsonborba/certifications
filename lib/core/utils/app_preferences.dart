import 'package:certifications/dal/local/local_source_adapter.dart';
import 'package:flutter/material.dart';

class AppPreferences extends ChangeNotifier {
  AppPreferences()
    : _storage = LocalSourceAdapter(namespace: 'certifications.preferences');
  final LocalSourceAdapter _storage;
  ThemeMode themeMode = ThemeMode.system;
  Locale? locale;
  Future<void> load() async {
    final stored = await _storage.read<Map<String, dynamic>>('preferences');
    if (stored == null) return;
    themeMode = ThemeMode.values.firstWhere(
      (item) => item.name == stored['theme'],
      orElse: () => ThemeMode.system,
    );
    final language = stored['language'] as String?;
    locale = language == null ? null : Locale(language);
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode value) async {
    themeMode = value;
    await _save();
    notifyListeners();
  }

  Future<void> setLocale(Locale? value) async {
    locale = value;
    await _save();
    notifyListeners();
  }

  Future<void> _save() => _storage.upsert('preferences', {
    'theme': themeMode.name,
    'language': locale?.languageCode,
  });
}
