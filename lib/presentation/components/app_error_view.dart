import 'dart:convert';

import 'package:certifications/core/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:certifications/core/utils/app_localizations.dart';
import 'package:http/http.dart' as http;

class AppErrorView extends StatefulWidget {
  const AppErrorView({
    super.key,
    required this.title,
    required this.message,
    required this.details,
    required this.showDetails,
  });

  factory AppErrorView.fromFlutterError(FlutterErrorDetails details) {
    final exception = details.exceptionAsString();
    final stack = details.stack?.toString();
    return AppErrorView(
      title: app_settings.developmentMode
          ? 'Development error'
          : 'Something went wrong',
      message: app_settings.developmentMode
          ? exception
          : 'The application hit an unexpected problem. You can send a report to help diagnose it.',
      details: {
        'exception': exception,
        'library': details.library,
        'context': details.context?.toDescription(),
        if (stack != null) 'stack_trace': stack,
      },
      showDetails: app_settings.developmentMode,
    );
  }

  final String title;
  final String message;
  final Map<String, Object?> details;
  final bool showDetails;

  @override
  State<AppErrorView> createState() => _AppErrorViewState();
}

class _AppErrorViewState extends State<AppErrorView> {
  bool _sending = false;
  String? _statusMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Card(
              elevation: 16,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.report_problem_rounded,
                          color: colors.error,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.message,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.55,
                      ),
                    ),
                    if (widget.showDetails) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: SelectableText(
                          const JsonEncoder.withIndent(
                            '  ',
                          ).convert(_stringifiedDetails()),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: colors.onSurface,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                    if (_statusMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _statusMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (widget.showDetails)
                          FilledButton.icon(
                            onPressed: _copyDetails,
                            icon: const Icon(Icons.copy_all_rounded),
                            label: Text(context.tr('memory')),
                          ),
                        if (!widget.showDetails)
                          FilledButton.icon(
                            onPressed: _sending ? null : _sendReport,
                            icon: _sending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded),
                            label: Text(context.tr('retry')),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copyDetails() async {
    await Clipboard.setData(
      ClipboardData(
        text: const JsonEncoder.withIndent('  ').convert(_stringifiedDetails()),
      ),
    );
    if (!mounted) return;
    setState(() {
      _statusMessage = 'Error context copied to clipboard.';
    });
  }

  Future<void> _sendReport() async {
    setState(() {
      _sending = true;
      _statusMessage = null;
    });

    try {
      final uri = Uri.parse(
        '${app_settings.ASODYA_API_URL}/apps/api/v1/client-error-report',
      );
      final response = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'app_name': 'Certifications',
          'environment': app_settings.developmentMode
              ? 'development'
              : 'production',
          'route': null,
          'error_title': widget.title,
          'error_message': widget.message,
          'error_code': 'flutter_render_error',
          'details': _stringifiedDetails(),
        }),
      );
      setState(() {
        _statusMessage = response.statusCode >= 200 && response.statusCode < 300
            ? 'The error report was sent successfully.'
            : 'The error report could not be sent right now.';
      });
    } catch (_) {
      setState(() {
        _statusMessage = 'The error report could not be sent right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Map<String, String> _stringifiedDetails() {
    return widget.details.map((key, value) => MapEntry(key, '${value ?? ''}'));
  }
}
