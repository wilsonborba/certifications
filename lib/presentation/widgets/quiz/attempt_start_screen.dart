import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/services/attempt_api_service.dart';
import 'package:certifications/domain/services/pending_intent_store.dart';
import 'package:certifications/presentation/components/auth/quiz_auth_guard.dart';
import 'package:certifications/presentation/widgets/quiz/attempt_screen.dart';
import 'package:flutter/material.dart';

/// Explicit start step for the accepted /v1/quizzes/:quiz_id route. It does
/// not fetch quiz payloads; the attempt API returns the safe taking view.
class AttemptStartScreen extends StatefulWidget {
  const AttemptStartScreen({
    super.key,
    required this.quizId,
    this.api,
    this.authenticate,
  });

  final String quizId;
  final AttemptApiService? api;
  final Future<bool> Function(PendingQuizIntent intent)? authenticate;

  @override
  State<AttemptStartScreen> createState() => _AttemptStartScreenState();
}

class _AttemptStartScreenState extends State<AttemptStartScreen> {
  late final AttemptApiService _api = widget.api ?? AttemptApiService();
  bool _starting = false;
  String? _error;

  Future<void> _start() async {
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final canProceed =
          await (widget.authenticate ?? ensureAuthenticatedForQuiz)(
            PendingQuizIntent(quizId: widget.quizId),
          );
      if (!mounted || !canProceed) return;
      final attempt = await _api.startAttempt(widget.quizId);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          settings: RouteSettings(
            name: '/v1/attempts/${Uri.encodeComponent(attempt.id)}',
          ),
          builder: (_) => AttemptScreen(attemptId: attempt.id, api: _api),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _starting = false;
          _error = context.tr('errorGeneric');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('attemptTitle'))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('attemptMonitoringBeforeStart'),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(_error!, style: TextStyle(color: scheme.error)),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _starting ? null : _start,
                          icon: _starting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.play_arrow),
                          label: Text(context.tr('startQuiz')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
