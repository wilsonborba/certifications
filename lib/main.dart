import 'dart:ui';

import 'package:certifications/core/utils/my_logs.dart';
import 'package:certifications/presentation/components/app_error_view.dart';
import 'package:flutter/material.dart';
import 'package:certifications/app.dart';
import 'package:certifications/core/settings.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setUrlStrategy(PathUrlStrategy());

  await Settings().init();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    severe('FlutterError: ${details.exceptionAsString()}');
  };

  ErrorWidget.builder = (details) => AppErrorView.fromFlutterError(details);

  PlatformDispatcher.instance.onError = (error, stack) {
    severe('PlatformDispatcher error: $error');
    return false;
  };

  runApp(const App());
}
