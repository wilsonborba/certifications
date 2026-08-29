import 'package:certifications/core/utils/app_localizations.dart';
import 'package:flutter/material.dart';

class LeaderboardEntry {
  LeaderboardEntry({
    required this.rank,
    required this.userName,
    required this.score,
    required this.timeSpentSeconds,
    required this.completedAt,
  });

  final int rank;
  final String userName;
  final double score;
  final int timeSpentSeconds;
  final String completedAt;
}

class QuizLeaderboardView extends StatelessWidget {
  const QuizLeaderboardView({
    super.key,
    required this.quizTitle,
    required this.entries,
    required this.isDesktop,
  });

  final String quizTitle;
  final List<LeaderboardEntry> entries;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('${context.tr('leaderboard')} - $quizTitle'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: entries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.emoji_events, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum participante concluiu este simulado ainda.',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final isTop3 = entry.rank <= 3;
                        Color rankColor = scheme.primary;
                        if (entry.rank == 1) rankColor = Colors.amber;
                        if (entry.rank == 2) rankColor = Colors.grey;
                        if (entry.rank == 3) rankColor = Colors.brown;

                        final minutes = (entry.timeSpentSeconds / 60).floor();
                        final seconds = entry.timeSpentSeconds % 60;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: isTop3
                                ? rankColor.withOpacity(0.08)
                                : scheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isTop3
                                  ? rankColor.withOpacity(0.4)
                                  : scheme.outlineVariant.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isTop3 ? rankColor : scheme.surfaceVariant,
                                ),
                                child: Center(
                                  child: Text(
                                    '#${entry.rank}',
                                    style: TextStyle(
                                      color: isTop3 ? Colors.white : scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.userName,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Tempo: ${minutes}m ${seconds}s',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: scheme.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${entry.score.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
