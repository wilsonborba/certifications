import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/quiz.dart';
import 'package:certifications/domain/services/quiz_api_service.dart';
import 'package:flutter/material.dart';

/// Pure content of a quiz leaderboard (empty state or ranked rows), with no
/// Scaffold/AppBar of its own so it can be embedded inline (the certificates
/// tab's Public sub-tab detail panel, #39) as well as pushed as its own
/// full screen (via [QuizLeaderboardScreen] below).
class QuizLeaderboardView extends StatelessWidget {
  const QuizLeaderboardView({
    super.key,
    required this.entries,
    required this.isDesktop,
  });

  final List<LeaderboardEntry> entries;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, size: 56, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                context.tr('noParticipantsYet'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
            color: isTop3 ? rankColor.withValues(alpha: 0.08) : scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isTop3
                  ? rankColor.withValues(alpha: 0.4)
                  : scheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isTop3 ? rankColor : scheme.surfaceContainerHighest,
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
                      '${context.tr('timePrefix')} ${minutes}m ${seconds}s',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
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
    );
  }
}

/// Fetches `GET /quizzes/completed/{id}/leaderboard` and feeds the result
/// into the presentational [QuizLeaderboardView]. When [embedded] is true,
/// renders just the content (loading/error/list), letting the caller supply
/// its own surrounding chrome; when false (the default), wraps it in its own
/// Scaffold+AppBar so it can be pushed as a standalone screen.
class QuizLeaderboardScreen extends StatefulWidget {
  const QuizLeaderboardScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.isDesktop,
    this.embedded = false,
  });

  final String quizId;
  final String quizTitle;
  final bool isDesktop;
  final bool embedded;

  @override
  State<QuizLeaderboardScreen> createState() => _QuizLeaderboardScreenState();
}

class _QuizLeaderboardScreenState extends State<QuizLeaderboardScreen> {
  final _api = QuizApiService();
  late Future<List<LeaderboardEntry>> _future = _api.getLeaderboard(widget.quizId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LeaderboardEntry>>(
      future: _future,
      builder: (context, snapshot) {
        Widget content;
        if (snapshot.connectionState != ConnectionState.done) {
          content = const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          content = Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.tr('errorGeneric')),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () =>
                        setState(() => _future = _api.getLeaderboard(widget.quizId)),
                    child: Text(context.tr('retry')),
                  ),
                ],
              ),
            ),
          );
        } else {
          content = QuizLeaderboardView(
            entries: snapshot.data ?? const [],
            isDesktop: widget.isDesktop,
          );
        }

        if (widget.embedded) return content;

        return Scaffold(
          appBar: AppBar(title: Text('${context.tr('leaderboard')} - ${widget.quizTitle}')),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(padding: const EdgeInsets.all(20), child: content),
              ),
            ),
          ),
        );
      },
    );
  }
}
