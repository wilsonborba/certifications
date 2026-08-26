import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/core/utils/app_preferences.dart';
import 'package:certifications/core/utils/my_nagivation.dart';
import 'package:certifications/core/utils/my_router_parser.dart';
import 'package:certifications/core/utils/my_theme.dart';
import 'package:certifications/presentation/components/auth/auth_artifact_params.dart';
import 'package:certifications/presentation/components/auth/session_gate.dart';
import 'package:certifications/presentation/widgets/auth/on_sync_auth.dart';
import 'package:certifications/presentation/widgets/certifications/on_certification.dart';
import 'package:flutter/material.dart';

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final preferences = AppPreferences();
  @override
  void initState() {
    super.initState();
    preferences.load();
  }

  @override
  void dispose() {
    preferences.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: preferences,
    builder: (_, __) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: preferences.themeMode,
      locale: preferences.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      builder: (context, child) => AppPreferencesScope(
        preferences: preferences,
        child: child ?? const SizedBox.shrink(),
      ),
      navigatorKey: NavigationService.navigatorKey,
      onGenerateRoute: (settings) {
        final parser = MyRouteParser(settings: settings);
        final authExchangeToken = resolveAuthExchangeToken(
          readParam: parser.parsedParams,
        );
        if (parser.path == 'sync') {
          return MaterialPageRoute(
            settings: const RouteSettings(name: OnSyncAuthScreen.route),
            builder: (_) =>
                OnSyncAuthScreen(authExchangeToken: authExchangeToken),
          );
        }
        if (parser.path == 'certifications' && parser.segments.length > 1) {
          return MaterialPageRoute(
            builder: (_) =>
                OnCertificationScreen(certificationId: parser.segments[1]),
          );
        }
        return MaterialPageRoute(builder: (_) => const SessionGate());
      },
    ),
  );
}
