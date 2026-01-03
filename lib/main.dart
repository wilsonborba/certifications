import 'package:flutter/material.dart';
import 'package:accredit/app.dart';
import 'package:accredit/core/settings.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setUrlStrategy(PathUrlStrategy());

  await Settings.loadEnv();
  await Settings().init();

  runApp(const App());
}
