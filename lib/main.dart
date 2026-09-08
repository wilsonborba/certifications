import 'package:certifications/presentation/components/app_error_view.dart';
import 'package:flutter/material.dart';
import 'package:certifications/app.dart';
import 'package:certifications/core/settings.dart';
import 'package:certifications/domain/services/client_telemetry_service.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setUrlStrategy(PathUrlStrategy());

  await Settings().init();

  ClientTelemetryService.instance.initialize();

  ErrorWidget.builder = (details) => AppErrorView.fromFlutterError(details);

  runApp(const App());
}
