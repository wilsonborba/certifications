

import 'package:flutter/material.dart';
import 'package:lazycopy/core/utils/my_logs.dart';
import 'package:lazycopy/core/utils/my_nagivation.dart';
import 'package:lazycopy/core/utils/my_theme.dart';
import 'package:lazycopy/presentation/widgets/boarding/on_boarding.dart';




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
      home: OnBoardingScreen(),
    );
  }
}
