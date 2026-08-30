import 'dart:math' as math;

import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/presentation/components/premium_hover_card.dart';
import 'package:flutter/material.dart';

/// Top block of the dashboard: a genuinely interactive summary of the
/// user's studies, built entirely from real data (no hardcoded placeholder
/// numbers). Shows a real, deliberate empty state instead of an all-zero
/// chart when the user has no studies yet.
class CompletedMetricsBanner extends StatelessWidget {
  const CompletedMetricsBanner({
    super.key,
    required this.totalStudies,
    required this.standbyCount,
    required this.completedQuizzesCount,
    required this.totalSizeBytes,
    required this.averageScorePercent,
    required this.hasScoreData,
    required this.isDesktop,
    this.onTapCompletedQuizzes,
  });

  final int totalStudies;
  final int standbyCount;
  final int completedQuizzesCount;
  final int totalSizeBytes;
  final double averageScorePercent;

  /// Whether [averageScorePercent] reflects real data. When false, the tile
  /// shows a dash placeholder instead of a misleading 0%.
  final bool hasScoreData;
  final bool isDesktop;

  /// Opens the completed-quizzes list (visibility, sharing, leaderboard).
  /// Null hides the tap affordance on the "completed quizzes" tile.
  final VoidCallback? onTapCompletedQuizzes;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.12),
            scheme.surface.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: scheme.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                context.tr('completedMetrics'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isDesktop ? 20 : 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt, color: Colors.green, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      context.tr('cortexConnected'),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (totalStudies == 0)
            _EmptyDashboardState(isDesktop: isDesktop)
          else
            _buildPopulated(context, scheme),
        ],
      ),
    );
  }

  Widget _buildPopulated(BuildContext context, ColorScheme scheme) {
    final sizeMb = (totalSizeBytes / (1024 * 1024)).toStringAsFixed(1);
    final donut = _StudiesDonutChart(
      total: totalStudies,
      standby: standbyCount,
      completed: completedQuizzesCount,
      onTap: onTapCompletedQuizzes,
    );

    final tiles = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _MetricTile(
          icon: Icons.book,
          label: context.tr('studyNotebooksLabel'),
          value: '$totalStudies',
          isDesktop: isDesktop,
        ),
        _MetricTile(
          icon: Icons.sd_storage,
          label: context.tr('storageUsedLabel'),
          value: '$sizeMb MB',
          isDesktop: isDesktop,
        ),
        _MetricTile(
          icon: Icons.assignment_turned_in,
          label: context.tr('completedQuizzesLabel'),
          value: '$completedQuizzesCount',
          isDesktop: isDesktop,
          onTap: onTapCompletedQuizzes,
          tooltip: onTapCompletedQuizzes == null
              ? null
              : context.tr('viewCompletedQuizzes'),
        ),
        _MetricTile(
          icon: Icons.emoji_events,
          label: context.tr('averageScoreLabel'),
          // A literal en dash placeholder here is a deliberate UI design
          // choice for "no data yet", not prose: showing 0% would read as a
          // real (bad) score rather than the honest absence of any.
          value: hasScoreData ? '${averageScorePercent.toStringAsFixed(0)}%' : '–',
          isDesktop: isDesktop,
          tooltip: hasScoreData ? null : context.tr('noScoreDataTooltip'),
        ),
      ],
    );

    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: donut),
          const SizedBox(height: 20),
          tiles,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        donut,
        const SizedBox(width: 28),
        Expanded(child: tiles),
      ],
    );
  }
}

/// Real, deliberate empty state (icon + message) shown instead of an
/// all-zero chart when the user has not created any study yet.
class _EmptyDashboardState extends StatelessWidget {
  const _EmptyDashboardState({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 24 : 12),
      child: Column(
        children: [
          Icon(
            Icons.insights_outlined,
            size: 44,
            color: scheme.onSurface.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('dashboardEmptyState'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small animated donut chart breaking down the user's studies into standby
/// vs. completed. Hovering (desktop) or long-pressing shows a breakdown
/// tooltip; tapping opens the completed quizzes list, a real transition
/// rather than a purely decorative chart.
class _StudiesDonutChart extends StatelessWidget {
  const _StudiesDonutChart({
    required this.total,
    required this.standby,
    required this.completed,
    this.onTap,
  });

  final int total;
  final int standby;
  final int completed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final standbyFraction = total == 0 ? 0.0 : standby / total;
    final completedFraction = total == 0 ? 0.0 : completed / total;
    const size = 120.0;

    return Tooltip(
      message: context.trParams('studiesBreakdownTooltip', {
        'standby': '$standby',
        'completed': '$completed',
      }),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.16),
                  blurRadius: 24,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, progress, _) {
                return CustomPaint(
                  painter: _DonutPainter(
                    standbyFraction: standbyFraction,
                    completedFraction: completedFraction,
                    progress: progress,
                    trackColor: scheme.onSurface.withValues(alpha: 0.06),
                    standbyColor: scheme.primary.withValues(alpha: 0.32),
                    completedColor: scheme.primary,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          context.tr('studyNotebooksLabel'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.standbyFraction,
    required this.completedFraction,
    required this.progress,
    required this.trackColor,
    required this.standbyColor,
    required this.completedColor,
  });

  final double standbyFraction;
  final double completedFraction;
  final double progress;
  final Color trackColor;
  final Color standbyColor;
  final Color completedColor;

  // A small angular gap keeps adjacent segments (and a segment butting up
  // against itself on a full loop) visually separated instead of reading as
  // one solid, featureless ring.
  static const _gap = 0.045;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.1;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);

    const startAngle = -math.pi / 2;
    final segments = [
      if (standbyFraction > 0) (fraction: standbyFraction, color: standbyColor),
      if (completedFraction > 0) (fraction: completedFraction, color: completedColor),
    ];
    final isFullLoop = (standbyFraction + completedFraction) >= 0.999;

    var angle = startAngle;
    for (final segment in segments) {
      final sweep = 2 * math.pi * segment.fraction * progress;
      if (sweep <= 0) continue;
      final drawnSweep = (segments.length > 1 || isFullLoop)
          ? math.max(sweep - _gap, sweep * 0.5)
          : sweep;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;
      canvas.drawArc(rect, angle, drawnSweep, false, paint);
      angle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.standbyFraction != standbyFraction ||
      oldDelegate.completedFraction != completedFraction;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDesktop,
    this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDesktop;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final tile = PremiumHoverCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 16,
      width: null,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: scheme.primary, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          if (onTap != null) ...[
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 16, color: scheme.onSurface.withValues(alpha: 0.4)),
          ],
        ],
      ),
    );

    if (tooltip == null) return tile;
    return Tooltip(message: tooltip!, child: tile);
  }
}
