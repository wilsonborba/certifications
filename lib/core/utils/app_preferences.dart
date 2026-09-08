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

/// Makes the persisted interface choices available to every route and app bar
/// without duplicating local theme/language state in individual screens.
class AppPreferencesScope extends InheritedNotifier<AppPreferences> {
  const AppPreferencesScope({
    super.key,
    required AppPreferences preferences,
    required super.child,
  }) : super(notifier: preferences);

  static AppPreferences of(BuildContext context) {
    final scope = maybeOf(context);
    // The scope is installed by App.builder. Keeping a safe fallback makes
    // preference controls harmless when rendered in an isolated preview or
    // error surface, instead of crashing the whole app with a null check.
    return scope ?? AppPreferences();
  }

  static AppPreferences? maybeOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppPreferencesScope>();
    return scope?.notifier;
  }
}
