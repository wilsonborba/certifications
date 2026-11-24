import 'dart:async';

import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/generation.dart';
import 'package:certifications/domain/services/draft_progress_store.dart';
import 'package:certifications/domain/services/generation_api_service.dart';
import 'package:flutter/material.dart';

class GenerationProgressScreen extends StatefulWidget {
  const GenerationProgressScreen({
    super.key,
    required this.jobId,
    GenerationApiService? api,
    DraftProgressStore? progressStore,
  }) : _api = api,
       _progressStore = progressStore;

  final String jobId;
  final GenerationApiService? _api;
  final DraftProgressStore? _progressStore;

  @override
  State<GenerationProgressScreen> createState() =>
      _GenerationProgressScreenState();
}

class _GenerationProgressScreenState extends State<GenerationProgressScreen> {
  late final GenerationApiService _api = widget._api ?? GenerationApiService();
  final DraftProgressStore _store = DraftProgressStore.instance;
  GenerationJob? _job;
  GenerationEstimate? _estimate;
  final List<GenerationEvent> _events = [];
  Object? _loadError;
  bool _busy = false;
  bool _loading = true;
  Timer? _refreshTimer;

  DraftProgressStore get _progressStore => widget._progressStore ?? _store;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh(initial: true));
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      unawaited(_refresh());
    });
  }

  @override
  void didUpdateWidget(covariant GenerationProgressScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jobId != widget.jobId) {
      _events.clear();
      _estimate = null;
      _job = null;
      unawaited(_refresh(initial: true));
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool initial = false}) async {
    if (_busy) return;
    _busy = true;
    if (initial && mounted) setState(() => _loading = true);
    try {
      final job = await _api.get(widget.jobId);
      final after = _events.isEmpty ? 0 : _events.last.seq;
      try {
        final newEvents = await _api.events(jobId: job.id, after: after);
        if (newEvents.isNotEmpty) _events.addAll(newEvents);
      } catch (_) {
        // The durable job status remains useful when the optional timeline is
        // unavailable or its event stream fails.
      }
      if (_estimate == null) {
        try {
          _estimate = await _api.estimate(
            studyId: job.studyId,
            language: job.language,
            count: job.requestedCount,
          );
        } catch (_) {
          // A measured estimate is optional. Keep it unavailable on API error.
        }
      }
      await _progressStore.saveGenerationJobId(job.studyId, job.id);
      if (!mounted) return;
      setState(() {
        _job = job;
        _loadError = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    } finally {
      _busy = false;
    }
  }

  Future<void> _stop() async {
    final job = _job;
    if (job == null || !job.isActive) return;
    setState(() => _busy = true);
    try {
      final updated = await _api.stop(job.id);
      if (!mounted) return;
      setState(() {
        _job = updated;
        _loadError = null;
      });
      if (mounted) setState(() => _busy = false);
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _continue() async {
    final job = _job;
    if (job == null || !job.canResume) return;
    setState(() => _busy = true);
    try {
      final resumed = await _api.resume(job.id);
      await _progressStore.saveGenerationJobId(resumed.studyId, resumed.id);
      if (!mounted) return;
      setState(() {
        _events.clear();
        _estimate = null;
        _job = resumed;
        _loadError = null;
      });
      if (mounted) setState(() => _busy = false);
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _stageText(BuildContext context, String type) => switch (type) {
    'queued' => context.tr('generationStageQueued'),
    'running' => context.tr('generationStageRunning'),
    'language_correction' => context.tr('generationStageLanguageCorrection'),
    'stop_requested' => context.tr('generationStageStopRequested'),
    'completed' => context.tr('generationStageCompleted'),
    'cancelled' => context.tr('generationStageCancelled'),
    'failed' => context.tr('generationStageFailed'),
    _ => context.tr('generationStageUpdating'),
  };

  String _currentStage(BuildContext context, GenerationJob job) {
    if (job.status != 'running' && job.status != 'queued') {
      return _stageText(context, job.status);
    }
    if (job.stopRequested) return _stageText(context, 'stop_requested');
    for (final event in _events.reversed) {
      if (event.eventType == 'language_correction' ||
          event.eventType == 'running') {
        return _stageText(context, event.eventType);
      }
    }
    return _stageText(context, job.status);
  }

  String _duration(BuildContext context, Duration duration) {
    final seconds = duration.inSeconds.clamp(0, 1 << 31);
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainder = seconds % 60;
    if (hours > 0) {
      return context.trParams('generationDurationHours', {
        'hours': '$hours',
        'minutes': '$minutes',
        'seconds': '$remainder',
      });
    }
    if (minutes > 0) {
      return context.trParams('generationDurationMinutes', {
        'minutes': '$minutes',
        'seconds': '$remainder',
      });
    }
    return context.trParams('generationDurationSeconds', {
      'seconds': '$remainder',
    });
  }

  Duration _nonNegativeSeconds(int seconds) =>
      Duration(seconds: seconds < 0 ? 0 : seconds);

  String _estimateText(BuildContext context, GenerationEstimate? estimate) {
    if (estimate == null || !estimate.isAvailable) {
      return context.tr('generationEstimateUnavailable');
    }
    final processing = _duration(
      context,
      Duration(milliseconds: estimate.estimatedProcessingMs!),
    );
    return context.trParams('generationEstimateAvailable', {
      'duration': processing,
      'samples': '${estimate.sampleCount}',
    });
  }

  String? _serverErrorText(BuildContext context, Object? error) {
    if (error is GenerationApiException) {
      return switch (error.code) {
        'cortex_outcome_unknown' || 'cannot_resume_unknown_cortex_outcome' =>
          context.tr('generationUnknownOutcome'),
        'generation_already_active' => context.tr('generationAlreadyActive'),
        'study_expired' => context.tr('generationStudyExpired'),
        'no_ready_sources' => context.tr('generationNoSources'),
        _ => error.message ?? context.tr('errorGeneric'),
      };
    }
    return error == null ? null : context.tr('errorGeneric');
  }

  @override
  Widget build(BuildContext context) {
    final job = _job;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('generationProgressTitle'))),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : job == null
            ? _loadFailure(context)
            : _progressBody(context, job, scheme),
      ),
    );
  }

  Widget _loadFailure(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _serverErrorText(context, _loadError) ?? context.tr('errorGeneric'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : () => _refresh(initial: true),
            icon: const Icon(Icons.refresh),
            label: Text(context.tr('retry')),
          ),
        ],
      ),
    ),
  );

  Widget _progressBody(
    BuildContext context,
    GenerationJob job,
    ColorScheme scheme,
  ) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final queueEnd = job.startedAt ?? now;
    final queueDuration = _nonNegativeSeconds(queueEnd - job.queuedAt);
    final processingDuration = job.startedAt == null
        ? null
        : _nonNegativeSeconds((job.finishedAt ?? now) - job.startedAt!);
    final errorText = _serverErrorText(context, _loadError);

    return LayoutBuilder(
      builder: (context, viewportConstraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: (viewportConstraints.maxWidth - 32).clamp(0.0, 760.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          job.status == 'completed'
                              ? Icons.check_circle_outline
                              : Icons.auto_awesome,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.tr('generationProgressTitle'),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        IconButton(
                          tooltip: context.tr('refresh'),
                          onPressed: _busy ? null : () => _refresh(),
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _currentStage(context, job),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (job.status == 'queued' || job.status == 'running') ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                    ],
                    const SizedBox(height: 20),
                    if (job.status == 'queued')
                      _InfoLine(
                        label: context.tr('generationQueuePosition'),
                        value: '${job.queuePosition}',
                      ),
                    _InfoLine(
                      label: context.tr('generationQueueElapsed'),
                      value: _duration(context, queueDuration),
                    ),
                    if (processingDuration != null)
                      _InfoLine(
                        label: job.finishedAt == null
                            ? context.tr('generationProcessingElapsed')
                            : context.tr('generationProcessingDuration'),
                        value: _duration(context, processingDuration),
                      ),
                    _InfoLine(
                      label: context.tr('generationEstimateLabel'),
                      value: _estimateText(context, _estimate),
                    ),
                    if (job.savedCount > 0)
                      _InfoLine(
                        label: context.tr('generationSavedCount'),
                        value: '${job.savedCount}',
                      ),
                    if (job.stopRequested && job.status == 'running') ...[
                      const SizedBox(height: 8),
                      Text(
                        context.tr('generationSafeStopPending'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.tertiary,
                        ),
                      ),
                    ],
                    if (job.errorCode.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorText ?? context.tr('generationFailed'),
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: scheme.error),
                      ),
                    ],
                    if (_loadError != null && errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorText,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: scheme.error),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      context.tr('generationTimelineTitle'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_events.isEmpty)
                      Text(context.tr('generationTimelineUnavailable'))
                    else
                      for (final event in _events.reversed)
                        _EventRow(
                          text: _stageText(context, event.eventType),
                          time: DateTime.fromMillisecondsSinceEpoch(
                            event.createdAt * 1000,
                          ).toLocal(),
                        ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        if (job.isActive)
                          OutlinedButton.icon(
                            onPressed: _busy ? null : _stop,
                            icon: const Icon(Icons.stop_circle_outlined),
                            label: Text(context.tr('generationStop')),
                          ),
                        if (job.canResume)
                          FilledButton.icon(
                            onPressed: _busy ? null : _continue,
                            icon: const Icon(Icons.play_arrow),
                            label: Text(context.tr('generationContinue')),
                          ),
                        if (_busy) const CircularProgressIndicator(),
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
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final labelText = Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        );
        final valueText = Text(value);
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [labelText, valueText],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 220, child: labelText),
            const SizedBox(width: 12),
            Expanded(child: valueText),
          ],
        );
      },
    ),
  );
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.text, required this.time});
  final String text;
  final DateTime time;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6, right: 10),
          child: Icon(Icons.circle, size: 7),
        ),
        Expanded(child: Text(text)),
        const SizedBox(width: 12),
        Text(
          MaterialLocalizations.of(
            context,
          ).formatTimeOfDay(TimeOfDay.fromDateTime(time)),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}
