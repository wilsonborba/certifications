import 'package:certifications/core/settings.dart';
import 'package:certifications/core/utils/my_router_parser.dart';
import 'package:certifications/presentation/components/auth/session_gate.dart';
import 'package:certifications/presentation/components/auth/auth_artifact_params.dart';
import 'package:certifications/presentation/widgets/certifications/on_certification.dart';
import 'package:certifications/presentation/widgets/auth/on_sync_auth.dart';
import 'package:flutter/material.dart';
import 'package:certifications/core/utils/my_logs.dart';
import 'package:certifications/core/utils/my_nagivation.dart';
import 'package:certifications/core/utils/my_theme.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    debug('Building App widget');

    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      onGenerateRoute: (settings) {
        final parser = MyRouteParser(settings: settings);
        final routePath = parser.path;
        final segments = parser.segments;
        final authExchangeToken = resolveAuthExchangeToken(
          readParam: parser.parsedParams,
        );

        if (routePath == 'sync') {
          return MaterialPageRoute(
            settings: const RouteSettings(name: OnSyncAuthScreen.route),
            builder: (_) =>
                OnSyncAuthScreen(authExchangeToken: authExchangeToken),
          );
        } else if (routePath == 'certifications' && segments.length > 1) {
          final certificationId = segments[1];
          return MaterialPageRoute(
            builder: (_) =>
                OnCertificationScreen(certificationId: certificationId),
          );
        } else {
          return MaterialPageRoute(builder: (_) => const SessionGate());
        }
      },
    );
  }
}
