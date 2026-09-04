import 'dart:async';
import 'package:flutter/material.dart';

/// Step-aware loading screen shown while the wizard runs its async pipeline
/// (create → upload → ingest → generate). Each step is passed in by the
/// caller so the UI always reflects what is *actually* happening, not a
/// timer-driven guess.
class FuturisticLoading extends StatelessWidget {
  const FuturisticLoading({
    super.key,
    required this.messages,
    this.currentStep = 0,
    // Legacy compat — ignored, kept so old call sites compile without changes.
    this.isActive = true,
    this.switchInterval = const Duration(seconds: 4),
    this.imageAsset,
    this.transparentBackground = false,
    this.questionsGenerated,
    this.questionsTarget,
    this.chunksDone = 0,
    this.chunksTotal = 0,
  });

  /// Ordered list of step labels, e.g. ['Creating study', 'Uploading files', …]
  final List<String> messages;

  /// Index of the step currently executing (0-based).
  final int currentStep;

  /// Real count of questions generated so far, polled from the backend.
  /// When non-null on the last step, replaces the generic rotating
  /// sub-status text with actual "N generated" / "N of M" progress.
  final int? questionsGenerated;

  /// The requested question count, or null when unlimited/unknown.
  final int? questionsTarget;

  /// How many source-material chunks have finished processing, out of how
  /// many. Shown while [questionsGenerated] is still 0 so short documents
  /// (a single chunk) still show visible movement instead of sitting at
  /// "0" for the whole generation call.
  final int chunksDone;
  final int chunksTotal;

  // Ignored — kept for backward compat.
  final bool isActive;
  final Duration switchInterval;
  final String? imageAsset;
  final bool transparentBackground;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = messages.length;

    return Container(
      decoration: transparentBackground
          ? null
          : BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.surfaceContainerHighest.withValues(alpha: 0.8),
                  scheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (imageAsset != null) ...[
                  Image.asset(imageAsset!, height: 64, fit: BoxFit.contain),
                  const SizedBox(height: 28),
                ] else ...[
                  Center(
                    child: _FuturisticOrb(color: scheme.primary),
                  ),
                  const SizedBox(height: 32),
                ],

                // ── Segmented progress bar ──────────────────────────────────
                _SegmentedProgressBar(
                  total: total,
                  current: currentStep,
                  color: scheme.primary,
                ),
                const SizedBox(height: 32),

                // ── Step list ───────────────────────────────────────────────
                ...List.generate(total, (i) {
                  final isDone = i < currentStep;
                  final isActive = i == currentStep;
                  final isPending = i > currentStep;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _StepIcon(
                          isDone: isDone,
                          isActive: isActive,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                messages[i],
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontWeight: isActive
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: isPending
                                          ? scheme.onSurface.withValues(alpha: .35)
                                          : isDone
                                              ? scheme.onSurface.withValues(alpha: .6)
                                              : scheme.onSurface,
                                    ),
                              ),
                              if (isActive && i == total - 1) ...[
                                const SizedBox(height: 6),
                                questionsGenerated != null
                                    ? _RealProgressText(
                                        generated: questionsGenerated!,
                                        target: questionsTarget,
                                        chunksDone: chunksDone,
                                        chunksTotal: chunksTotal,
                                      )
                                    : const _DynamicSubStatusText(),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FuturisticOrb extends StatefulWidget {
  const _FuturisticOrb({required this.color});
  final Color color;

  @override
  State<_FuturisticOrb> createState() => _FuturisticOrbState();
}

class _FuturisticOrbState extends State<_FuturisticOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _spin,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          Transform.rotate(
            angle: _spin.value * 2 * 3.1415926,
            child: SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(widget.color),
              ),
            ),
          ),
          Icon(Icons.auto_awesome, color: widget.color, size: 28),
        ],
      ),
    );
  }
}

/// Real, backend-polled "N questions generated" status, shown instead of
/// [_DynamicSubStatusText]'s canned rotation once actual progress is known.
class _RealProgressText extends StatelessWidget {
  const _RealProgressText({
    required this.generated,
    this.target,
    this.chunksDone = 0,
    this.chunksTotal = 0,
  });

  final int generated;
  final int? target;
  final int chunksDone;
  final int chunksTotal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = generated > 0
        ? (target != null
            ? 'Generating question $generated of $target…'
            : 'Generating questions… $generated so far')
        // No question parsed yet: still show real movement (which part of
        // the source material is being processed) instead of sitting idle.
        : (chunksTotal > 0
            ? 'Reading part ${(chunksDone + 1).clamp(1, chunksTotal)} of $chunksTotal…'
            : 'Analyzing document concepts…');

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              label,
              key: ValueKey<String>(label),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DynamicSubStatusText extends StatefulWidget {
  const _DynamicSubStatusText();

  @override
  State<_DynamicSubStatusText> createState() => _DynamicSubStatusTextState();
}

class _DynamicSubStatusTextState extends State<_DynamicSubStatusText> {
  static const _subSteps = [
    'Analyzing document concepts…',
    'Synthesizing multiple-choice questions…',
    'Generating conceptual diagrams…',
    'Validating choices and citations…',
    'Finalizing quiz package…',
  ];

  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _subSteps.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _subSteps[_currentIndex],
              key: ValueKey<int>(_currentIndex),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedProgressBar extends StatelessWidget {
  const _SegmentedProgressBar({
    required this.total,
    required this.current,
    required this.color,
  });

  final int total;
  final int current;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final filled = i <= current;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            height: 4,
            margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: filled
                  ? color
                  : color.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}

// ── Per-step icon ────────────────────────────────────────────────────────────

class _StepIcon extends StatefulWidget {
  const _StepIcon({
    required this.isDone,
    required this.isActive,
    required this.color,
  });

  final bool isDone;
  final bool isActive;
  final Color color;

  @override
  State<_StepIcon> createState() => _StepIconState();
}

class _StepIconState extends State<_StepIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _StepIcon old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.isActive && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDone) {
      return Icon(Icons.check_circle_rounded,
          size: 22, color: widget.color);
    }
    if (widget.isActive) {
      return AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) => Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: .15 + .15 * _pulse.value),
            border: Border.all(
              color: widget.color.withValues(alpha: .6 + .4 * _pulse.value),
              width: 2,
            ),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
              ),
            ),
          ),
        ),
      );
    }
    // Pending
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.color.withValues(alpha: .2),
          width: 2,
        ),
      ),
    );
  }
}
