import 'package:certifications/core/settings.dart';
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
    required this.activityDates,
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

  /// When each study was created, used to plot studies-per-day.
  final List<DateTime> activityDates;
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
    final quotaMb = (app_settings.userTotalStorageBytes / (1024 * 1024)).toStringAsFixed(0);
    final availableBytes = (app_settings.userTotalStorageBytes - totalSizeBytes).clamp(0, app_settings.userTotalStorageBytes);
    final availableMb = (availableBytes / (1024 * 1024)).toStringAsFixed(1);

    final metricTiles = [
      _MetricTile(
        icon: Icons.book,
        label: context.tr('studyNotebooksLabel'),
        value: '$totalStudies',
        isDesktop: isDesktop,
      ),
      _MetricTile(
        icon: Icons.sd_storage,
        label: context.tr('storageUsedLabel'),
        value: '$sizeMb / $quotaMb MB',
        isDesktop: isDesktop,
        tooltip: context.trParams('storageAvailableTooltip', {'available': availableMb, 'total': quotaMb}),
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
        // A literal en dash placeholder here is a deliberate UI design
        // choice for "no data yet", not prose: showing 0% would read as a
        // real (bad) score rather than the honest absence of any.
        label: context.tr('averageScoreLabel'),
        value: hasScoreData ? '${averageScorePercent.toStringAsFixed(0)}%' : '–',
        isDesktop: isDesktop,
        tooltip: hasScoreData ? null : context.tr('noScoreDataTooltip'),
      ),
    ];

    final Widget tilesLayout = isDesktop
        ? Wrap(
            spacing: 12,
            runSpacing: 12,
            children: metricTiles,
          )
        : LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: metricTiles
                    .map((tile) => SizedBox(width: itemWidth, child: tile))
                    .toList(),
              );
            },
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActivityBarChart(dates: activityDates, isDesktop: isDesktop),
        const SizedBox(height: 20),
        tilesLayout,
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

/// One bucketed day in the activity chart.
class _DayBucket {
  const _DayBucket({required this.day, required this.count});
  final DateTime day;
  final int count;
}

/// Cartesian bar chart: studies and quizzes created/completed per day over recent days.
class _ActivityBarChart extends StatefulWidget {
  const _ActivityBarChart({required this.dates, required this.isDesktop});

  final List<DateTime> dates;
  final bool isDesktop;

  @override
  State<_ActivityBarChart> createState() => _ActivityBarChartState();
}

class _ActivityBarChartState extends State<_ActivityBarChart> {
  int get _daySpan => widget.isDesktop ? 14 : 7;
  int? _hoveredIndex;

  List<_DayBucket> _buckets() {
    final span = _daySpan;
    final today = DateTime.now();
    final startDay = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: span - 1));
    final counts = List<int>.filled(span, 0);
    for (final date in widget.dates) {
      final day = DateTime(date.year, date.month, date.day);
      final index = day.difference(startDay).inDays;
      if (index >= 0 && index < span) counts[index]++;
    }
    return [
      for (var i = 0; i < span; i++)
        _DayBucket(day: startDay.add(Duration(days: i)), count: counts[i]),
    ];
  }

  String _shortDate(DateTime day) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[day.month - 1]} ${day.day}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final buckets = _buckets();
    final maxCount = buckets.fold<int>(1, (m, b) => b.count > m ? b.count : m);
    // Show every label on desktop and on mobile since mobile shows 7 days.
    final labelStride = 1;

    return SizedBox(
      height: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('studiesActivityLabel'),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < buckets.length; i++)
                  Expanded(
                    child: _BarColumn(
                      bucket: buckets[i],
                      maxCount: maxCount,
                      showLabel: i % labelStride == 0,
                      hovered: _hoveredIndex == i,
                      dateLabel: _shortDate(buckets[i].day),
                      onHoverChanged: (hovered) =>
                          setState(() => _hoveredIndex = hovered ? i : null),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarColumn extends StatelessWidget {
  const _BarColumn({
    required this.bucket,
    required this.maxCount,
    required this.showLabel,
    required this.hovered,
    required this.dateLabel,
    required this.onHoverChanged,
  });

  final _DayBucket bucket;
  final int maxCount;
  final bool showLabel;
  final bool hovered;
  final String dateLabel;
  final ValueChanged<bool> onHoverChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fraction = maxCount == 0 ? 0.0 : bucket.count / maxCount;

    return Tooltip(
      message: '$dateLabel · ${bucket.count}',
      child: MouseRegion(
        onEnter: (_) => onHoverChanged(true),
        onExit: (_) => onHoverChanged(false),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (bucket.count > 0)
                Text(
                  '${bucket.count}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: hovered ? scheme.primary : scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              const SizedBox(height: 4),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: fraction),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => FractionallySizedBox(
                    alignment: Alignment.bottomCenter,
                    heightFactor: value.clamp(0.04, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: hovered
                            ? scheme.primary
                            : scheme.primary.withValues(alpha: bucket.count == 0 ? 0.08 : 0.55),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              if (showLabel)
                Text(
                  dateLabel,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isDesktop ? 16 : 14,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                    fontSize: isDesktop ? 12 : 11,
                  ),
                ),
              ],
            ),
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
