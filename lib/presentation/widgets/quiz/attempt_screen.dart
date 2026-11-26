import 'dart:async';

import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/attempt.dart';
import 'package:certifications/domain/services/attempt_api_service.dart';
import 'package:flutter/material.dart';

/// A taking view backed only by the server's answer-key-free attempt DTO.
/// Opening this route resumes with GET; only the quiz preview's explicit
/// Start action calls POST to create an attempt.
class AttemptScreen extends StatefulWidget {
  const AttemptScreen({super.key, required this.attemptId, this.api});

  final String attemptId;
  final AttemptApiService? api;

  @override
  State<AttemptScreen> createState() => _AttemptScreenState();
}

class _AttemptScreenState extends State<AttemptScreen>
    with WidgetsBindingObserver {
  late final AttemptApiService _api = widget.api ?? AttemptApiService();
  AttemptView? _attempt;
  Map<String, String?> _answers = {};
  int _index = 0;
  bool _loading = true;
  bool _saving = false;
  bool _submitting = false;
  bool _submitted = false;
  String? _error;
  DateTime? _awaySince;
  DateTime? _focusLostAt;
  DateTime? _hiddenAt;
  Stopwatch? _awayStopwatch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _awayStopwatch?.stop();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final attempt = await _api.getAttempt(widget.attemptId);
      if (!mounted) return;
      setState(() {
        _attempt = attempt;
        _answers = {
          for (final question in attempt.questions)
            question.questionId: question.selectedOptionId,
        };
        _submitted = attempt.status != 'in_progress';
        _loading = false;
      });
      if (attempt.status == 'completed') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openResults();
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = context.tr('errorGeneric');
        _loading = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final attempt = _attempt;
    if (attempt == null || _submitted || attempt.status != 'in_progress') {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      final now = DateTime.now();
      _awaySince ??= now;
      _awayStopwatch ??= Stopwatch()..start();
      _focusLostAt ??= now;
      return;
    }
    if (state == AppLifecycleState.hidden) {
      final now = DateTime.now();
      _awaySince ??= now;
      _awayStopwatch ??= Stopwatch()..start();
      _hiddenAt ??= now;
      return;
    }
    if (state == AppLifecycleState.resumed) {
      final since = _awaySince;
      if (since == null) return;
      final focusLostAt = _focusLostAt;
      final hiddenAt = _hiddenAt;
      _awaySince = null;
      _focusLostAt = null;
      _hiddenAt = null;
      final returnedAt = DateTime.now();
      final stopwatch = _awayStopwatch;
      stopwatch?.stop();
      _awayStopwatch = null;
      final duration = stopwatch?.elapsedMilliseconds ?? 0;
      unawaited(
        _recordReturn(
          attempt,
          since,
          focusLostAt,
          hiddenAt,
          returnedAt,
          duration,
        ),
      );
    }
  }

  Future<void> _recordReturn(
    AttemptView attempt,
    DateTime awaySince,
    DateTime? focusLostAt,
    DateTime? hiddenAt,
    DateTime returnedAt,
    int duration,
  ) async {
    try {
      final events = <AttemptActivityEvent>[
        if (focusLostAt != null)
          AttemptActivityEvent(
            eventKind: 'focus_lost',
            dedupKey:
                '${attempt.id}:focus_lost:${focusLostAt.microsecondsSinceEpoch}',
            occurredAt: focusLostAt.millisecondsSinceEpoch ~/ 1000,
          ),
        if (hiddenAt != null)
          AttemptActivityEvent(
            eventKind: 'page_hidden',
            dedupKey:
                '${attempt.id}:page_hidden:${hiddenAt.microsecondsSinceEpoch}',
            occurredAt: hiddenAt.millisecondsSinceEpoch ~/ 1000,
          ),
        AttemptActivityEvent(
          eventKind: 'away_duration',
          dedupKey:
              '${attempt.id}:away_duration:${awaySince.microsecondsSinceEpoch}:${returnedAt.microsecondsSinceEpoch}',
          durationMs: duration,
          occurredAt: returnedAt.millisecondsSinceEpoch ~/ 1000,
        ),
        AttemptActivityEvent(
          eventKind: 'page_return',
          dedupKey:
              '${attempt.id}:page_return:${returnedAt.microsecondsSinceEpoch}',
          occurredAt: returnedAt.millisecondsSinceEpoch ~/ 1000,
        ),
      ];
      await _api.recordActivityEvents(attemptId: attempt.id, events: events);
    } catch (_) {
      // Browser lifecycle delivery is best effort; a missing event is never
      // presented as evidence that the user stayed on the page.
    }
  }

  Future<void> _select(AttemptQuestion question, String optionId) async {
    final attempt = _attempt;
    if (attempt == null || _saving || _submitting || _submitted) return;
    final previous = _answers[question.questionId];
    setState(() {
      _saving = true;
      _error = null;
      _answers[question.questionId] = optionId;
    });
    try {
      await _api.saveAnswer(
        attemptId: attempt.id,
        questionId: question.questionId,
        selectedOptionId: optionId,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _answers[question.questionId] = previous;
          _error = context.tr('errorGeneric');
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submit() async {
    final attempt = _attempt;
    if (attempt == null || _submitting || _submitted || _saving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('attemptSubmitTitle')),
        content: Text(context.tr('attemptSubmitConfirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('submit')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _api.submitAttempt(attempt.id);
      if (mounted) await _openResults();
    } catch (_) {
      if (mounted) setState(() => _error = context.tr('errorGeneric'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openResults() async {
    final attempt = _attempt;
    if (attempt == null || !mounted) return;
    await Navigator.of(context).pushReplacementNamed(
      '/v1/attempts/${Uri.encodeComponent(attempt.id)}/results',
    );
  }

  @override
  Widget build(BuildContext context) {
    final attempt = _attempt;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('attemptTitle'))),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : attempt == null
            ? Center(child: Text(_error ?? context.tr('errorGeneric')))
            : _buildAttempt(context, attempt),
      ),
    );
  }

  Widget _buildAttempt(BuildContext context, AttemptView attempt) {
    if (attempt.questions.isEmpty) {
      return Center(child: Text(context.tr('attemptNoQuestions')));
    }
    if (_submitted) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              context.tr('attemptSubmitted'),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    final question = attempt.questions[_index];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.visibility_outlined),
                    const SizedBox(width: 12),
                    Expanded(child: Text(attempt.monitoringNotice)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.trParams('attemptQuestionPosition', {
                'current': '${_index + 1}',
                'total': '${attempt.questions.length}',
              }),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 12),
            Text(
              question.prompt,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            RadioGroup<String>(
              groupValue: _answers[question.questionId],
              onChanged: (value) {
                if (!_saving && !_submitting && value != null) {
                  _select(question, value);
                }
              },
              child: Column(
                children: [
                  for (final raw in question.alternatives)
                    if (raw is Map &&
                        raw['id'] is String &&
                        raw['text'] is String)
                      RadioListTile<String>(
                        value: raw['id'] as String,
                        title: Text(raw['text'] as String),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                ],
              ),
            ),
            if (_saving) const LinearProgressIndicator(),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 12,
              spacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: _index == 0 || _saving
                      ? null
                      : () => setState(() => _index--),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(context.tr('previous')),
                ),
                if (_index < attempt.questions.length - 1)
                  FilledButton.icon(
                    onPressed: _saving ? null : () => setState(() => _index++),
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(context.tr('next')),
                  )
                else
                  FilledButton.icon(
                    onPressed: _saving || _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(context.tr('submit')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
