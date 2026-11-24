import 'package:certifications/core/routes.dart';
import 'package:certifications/core/tracking_manifest.dart';
import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/core/utils/app_preferences.dart';
import 'package:certifications/core/utils/my_nagivation.dart';
import 'package:certifications/core/utils/my_router_parser.dart';
import 'package:certifications/core/utils/my_theme.dart';
import 'package:certifications/domain/services/client_telemetry_service.dart';
import 'package:certifications/presentation/components/auth/auth_artifact_params.dart';
import 'package:certifications/presentation/components/auth/session_gate.dart';
import 'package:certifications/presentation/widgets/auth/on_sync_auth.dart';
import 'package:certifications/presentation/widgets/certificates/certificate_verification_screen.dart';
import 'package:certifications/presentation/widgets/plans/on_plans.dart';
import 'package:certifications/presentation/widgets/quiz/on_shared_quiz.dart';
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
        FallbackMaterialLocalizationsDelegate(),
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      builder: (context, child) => AppPreferencesScope(
        preferences: preferences,
        child: child ?? const SizedBox.shrink(),
      ),
      navigatorKey: NavigationService.navigatorKey,
      navigatorObservers: [
        ScreenTrailObserver(ClientTelemetryService.instance.tracker),
      ],
      onGenerateRoute: (settings) {
        final currentUri = Uri.tryParse(getLocationHref());
        final currentScreen = currentUri == null
            ? null
            : CertificationsRoute.parse(currentUri).screen;
        final segmentPath = Uri.tryParse(settings.name ?? '')?.path;
        if (currentScreen == CertificationsScreen.certificate &&
            (segmentPath == '/' ||
                segmentPath == '/v1' ||
                segmentPath == '/v1/certificates')) {
          // Flutter's default deep-link stack traverses intermediate paths.
          // Keep those placeholders from invoking the signed-in dashboard
          // while a public certificate link is being opened.
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const SizedBox.shrink(),
          );
        }
        final parser = MyRouteParser(settings: settings);
        final parsedUri = Uri.tryParse(settings.name ?? '') ?? Uri(path: '/');
        final route = CertificationsRoute.parse(parsedUri);
        final authExchangeToken = resolveAuthExchangeToken(
          readParam: parser.parsedParams,
        );
        if (route.screen == CertificationsScreen.syncAuth) {
          return MaterialPageRoute(
            settings: const RouteSettings(name: OnSyncAuthScreen.route),
            builder: (_) =>
                OnSyncAuthScreen(authExchangeToken: authExchangeToken),
          );
        }
        if (route.screen == CertificationsScreen.plans) {
          return MaterialPageRoute(
            settings: const RouteSettings(name: OnPlansScreen.route),
            builder: (_) => const OnPlansScreen(),
          );
        }
        // Quiz share links (#40): anonymous-friendly preview, auth-gated
        // only at the point of actually starting the quiz.
        if (route.screen == CertificationsScreen.sharedQuiz &&
            route.id != null) {
          return MaterialPageRoute(
            settings: RouteSettings(name: route.routeTemplate),
            builder: (_) => OnSharedQuizScreen(shareToken: route.id!),
          );
        }
        if (route.screen == CertificationsScreen.certificate &&
            route.id != null) {
          return MaterialPageRoute(
            settings: RouteSettings(name: route.routeTemplate),
            builder: (_) => CertificateVerificationScreen(code: route.id!),
          );
        }
        return MaterialPageRoute(
          settings: RouteSettings(name: route.routeTemplate),
          builder: (_) => const SessionGate(),
        );
      },
    ),
  );
}
