import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:certifications/core/settings.dart';
import 'package:certifications/core/utils/my_logs.dart';

class ClientTelemetryService {
  static final ClientTelemetryService _instance = ClientTelemetryService._internal();
  factory ClientTelemetryService() => _instance;
  static ClientTelemetryService get instance => _instance;

  ClientTelemetryService._internal();

  final Map<String, DateTime> _recentErrors = {};
  static const Duration _throttleDuration = Duration(seconds: 60);

  bool _isThrottled(String signature) {
    final now = DateTime.now();
    final lastSeen = _recentErrors[signature];
    if (lastSeen != null && now.difference(lastSeen) < _throttleDuration) {
      return true;
    }
    _recentErrors[signature] = now;
    if (_recentErrors.length > 100) {
      _recentErrors.removeWhere((_, time) => now.difference(time) > _throttleDuration);
    }
    return false;
  }

  void initialize() {
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

  void _sendTelemetry({
    required String errorTitle,
    required String errorMessage,
    String? stackTrace,
    String? errorCode,
    String? route,
    String? requestId,
    Map<String, dynamic>? details,
  }) {
    unawaited(
      Future(() async {
        try {
          final settings = app_settings;
          final uri = Uri.parse('${settings.ASODYA_API_URL}/apps/api/v1/client-error');

          final payload = {
            'app_name': 'certifications',
            'app_version': '1.0.0+1',
            'environment': settings.developmentMode ? 'development' : 'production',
            'route': route ?? (kIsWeb ? Uri.base.path : null),
            'error_title': errorTitle,
            'error_message': errorMessage,
            'error_code': errorCode,
            'stack_trace': stackTrace,
            'request_id': requestId,
            'client_timestamp': DateTime.now().toUtc().toIso8601String(),
            'details': details ?? {},
            'extra': {},
          };

          await http.post(
            uri,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          ).timeout(const Duration(seconds: 5));
        } catch (_) {
          // Silent failure by design: telemetry must never crash the frontend
        }
      }),
    );
  }
}
