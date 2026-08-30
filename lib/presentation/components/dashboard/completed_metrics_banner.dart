import 'package:certifications/core/utils/app_localizations.dart';
import 'package:flutter/material.dart';

class CompletedMetricsBanner extends StatelessWidget {
  const CompletedMetricsBanner({
    super.key,
    required this.totalStudies,
    required this.totalSizeBytes,
    required this.completedQuizzesCount,
    required this.averageScorePercent,
    required this.isDesktop,
    this.onTapCompletedQuizzes,
  });

  final int totalStudies;
  final int totalSizeBytes;
  final int completedQuizzesCount;
  final double averageScorePercent;
  final bool isDesktop;

  /// Opens the completed-quizzes list (visibility, sharing, leaderboard).
  /// Null hides the tap affordance on the "completed quizzes" tile.
  final VoidCallback? onTapCompletedQuizzes;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sizeMb = (totalSizeBytes / (1024 * 1024)).toStringAsFixed(1);

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withOpacity(0.12),
            scheme.surface.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.green.withOpacity(0.4)),
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
          Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MetricTile(
                icon: Icons.book,
                label: context.tr('studyNotebooksLabel'),
                value: '$totalStudies',
                isDesktop: isDesktop,
              ),
              if (!isDesktop) const SizedBox(height: 12),
              _MetricTile(
                icon: Icons.sd_storage,
                label: context.tr('storageUsedLabel'),
                value: '$sizeMb MB',
                isDesktop: isDesktop,
              ),
              if (!isDesktop) const SizedBox(height: 12),
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
              if (!isDesktop) const SizedBox(height: 12),
              _MetricTile(
                icon: Icons.emoji_events,
                label: context.tr('averageScoreLabel'),
                value: '${averageScorePercent.toStringAsFixed(0)}%',
                isDesktop: isDesktop,
              ),
            ],
          ),
        ],
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

    final tile = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: isDesktop ? MainAxisSize.min : MainAxisSize.max,
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
                  color: scheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          if (onTap != null) ...[
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 16, color: scheme.onSurface.withOpacity(0.4)),
          ],
        ],
      ),
    );

    if (onTap == null) return tile;
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: tile,
        ),
      ),
    );
  }
}
