

import 'package:accredit/core/settings.dart';
import 'package:accredit/core/utils/my_router_parser.dart';
import 'package:accredit/presentation/components/auth/session_gate.dart';
import 'package:accredit/presentation/widgets/auth/on_sync_auth.dart';
import 'package:flutter/material.dart';
import 'package:accredit/core/utils/my_logs.dart';
import 'package:accredit/core/utils/my_nagivation.dart';
import 'package:accredit/core/utils/my_theme.dart';
import 'package:accredit/presentation/widgets/boarding/on_boarding.dart';




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
        final tokenizedParam =
            parser.parsedParams(app_settings.AUTH_PARAM_KEY_NAME);

        if (routePath == 'sync') {
          return MaterialPageRoute(
            settings: const RouteSettings(name: OnSyncAuthScreen.route),
            builder: (_) => OnSyncAuthScreen(tokenizedParam: tokenizedParam),
          );
        }
        
         else {
          return MaterialPageRoute(
            builder: (_) => const SessionGate(),
          );
        }
      }
    );
  }
}
