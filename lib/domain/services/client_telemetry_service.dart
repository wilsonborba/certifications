import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:certifications/core/routes.dart';
import 'package:certifications/core/settings.dart';
import 'package:certifications/core/tracking_manifest.dart';
import 'package:certifications/core/utils/my_logs.dart';

class ClientTelemetryService {
  static final ClientTelemetryService _instance =
      ClientTelemetryService._internal();
  factory ClientTelemetryService() => _instance;
  static ClientTelemetryService get instance => _instance;

  ClientTelemetryService._internal();

  final Map<String, DateTime> _recentErrors = {};
  static const Duration _throttleDuration = Duration(seconds: 60);

  ScreenTrail? _tracker;
  HttpTrailTransport? _transport;

  ScreenTrail createTracker({
    http.Client? client,
    String? baseUrl,
    bool? autoFlush,
  }) {
    final origin = Uri.parse(baseUrl ?? app_settings.ASODYA_API_URL).origin;
    final transport = HttpTrailTransport(
      eventsUri: Uri.parse('$origin/apps/api/v1/telemetry/events'),
      errorsUri: Uri.parse('$origin/apps/api/v1/telemetry/errors'),
      includeCredentials: true,
      client: client,
    );
    _transport = transport;
    return ScreenTrail(
      appId: 'certifications',
      buildVersion: Settings.buildVersion,
      screens: certificationsScreens,
      transport: transport,
      recordTypedText: true,
      autoFlush: autoFlush ?? client == null,
    );
  }

  ScreenTrail get tracker => _tracker ??= createTracker();

  void attachClientForTest(http.Client client, {String? baseUrl}) {
    _tracker?.dispose();
    _transport?.close();
    _tracker = createTracker(
      client: client,
      baseUrl: baseUrl,
      autoFlush: false,
    );
  }

  bool _isThrottled(String signature) {
    final now = DateTime.now();
    final lastSeen = _recentErrors[signature];
    if (lastSeen != null && now.difference(lastSeen) < _throttleDuration) {
      return true;
    }
    _recentErrors[signature] = now;
    if (_recentErrors.length > 100) {
      _recentErrors.removeWhere(
        (_, time) => now.difference(time) > _throttleDuration,
      );
    }
    return false;
  }

  void initialize() {
    tracker.installErrorCapture();
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      severe('FlutterError: ${details.exceptionAsString()}');
      reportFlutterError(details);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      severe('PlatformDispatcher error: $error\n$stack');
      reportUncaughtError(error, stack);
      return false;
    };
  }

  void reportFlutterError(FlutterErrorDetails details) {
    try {
      final message = details.exceptionAsString();
      final stack = details.stack?.toString() ?? '';
      final signature = '$message:${details.library}';
      if (_isThrottled(signature)) return;

      _sendTelemetry(
        errorTitle: 'Flutter Error in ${details.library ?? "framework"}',
        errorMessage: message,
        stackTrace: stack,
        errorCode: 'FLUTTER_ERROR',
        details: {
          'context': details.context?.toString(),
          'library': details.library,
          'silent': details.silent,
        },
      );
    } catch (_) {}
  }

  void reportUncaughtError(Object error, StackTrace stack) {
    try {
      final message = error.toString();
      final stackStr = stack.toString();
      final signature = message;
      if (_isThrottled(signature)) return;

      _sendTelemetry(
        errorTitle: 'Uncaught Platform Exception',
        errorMessage: message,
        stackTrace: stackStr,
        errorCode: 'UNCAUGHT_EXCEPTION',
      );
    } catch (_) {}
  }

  void reportHandledError({
    required String title,
    required dynamic error,
    StackTrace? stackTrace,
    String? errorCode,
    String? route,
    String? requestId,
    Map<String, dynamic>? details,
  }) {
    try {
      final message = error.toString();
      final signature = '$title:$message';
      if (_isThrottled(signature)) return;

      _sendTelemetry(
        errorTitle: title,
        errorMessage: message,
        stackTrace: stackTrace?.toString(),
        errorCode: errorCode,
        route: route,
        requestId: requestId,
        details: details,
      );
    } catch (_) {}
  }

  static String? sanitizeRouteForTelemetry(String? rawRoute) {
    if (rawRoute == null || rawRoute.isEmpty) return null;
    final uri = Uri.tryParse(rawRoute);
    if (uri == null) return '/';
    return CertificationsRoute.parse(uri).routeTemplate;
  }

  void _sendTelemetry({
    required String errorTitle,
    required String errorMessage,
    String? stackTrace,
    String? errorCode,
    String? route,
    String? requestId,
    Map<String, dynamic>? details,
  }) {
    final safeRoute = sanitizeRouteForTelemetry(
      route ?? (kIsWeb ? Uri.base.path : null),
    );
    tracker.error(
      '$errorTitle: $errorMessage',
      stackTrace == null || stackTrace.isEmpty
          ? null
          : StackTrace.fromString(stackTrace),
      type: errorCode ?? 'ClientError',
      route: safeRoute,
    );
    unawaited(tracker.flush());
  }
}
