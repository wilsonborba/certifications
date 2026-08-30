import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/quiz.dart';
import 'package:certifications/domain/services/quiz_api_service.dart';
import 'package:certifications/domain/services/study_api_service.dart';
import 'package:certifications/presentation/components/attachment/app_bar.dart';
import 'package:certifications/presentation/components/quiz/quiz_leaderboard_view.dart';
import 'package:certifications/presentation/components/quiz/quiz_share_modal.dart';
import 'package:flutter/material.dart';

/// A study that reached `completed` status, paired with its live quiz record
/// (visibility, attempts) fetched from `GET /quizzes/completed/{quiz_id}`.
///
/// The client has no dedicated "list my completed quizzes" endpoint, so this
/// screen enumerates candidates via the existing studies list and treats a
/// completed study's id as the quiz id, per this app's one-quiz-per-study
/// model. If a study's id has no matching completed-quiz record yet, it is
/// left out rather than shown broken.
class _CompletedQuizItem {
  _CompletedQuizItem({required this.studyName, required this.quiz});
  final String studyName;
  Quiz quiz;
}

class OnCompletedQuizzesScreen extends StatefulWidget {
  const OnCompletedQuizzesScreen({super.key});

  @override
  State<OnCompletedQuizzesScreen> createState() => _OnCompletedQuizzesScreenState();
}

class _OnCompletedQuizzesScreenState extends State<OnCompletedQuizzesScreen> {
  final _studyApi = StudyApiService();
  final _quizApi = QuizApiService();
  late Future<List<_CompletedQuizItem>> _future = _load();

  Future<List<_CompletedQuizItem>> _load() async {
    final studies = await _studyApi.list();
    final completed = studies.where((s) => s.status == 'completed');
    final items = <_CompletedQuizItem>[];
    for (final study in completed) {
      try {
        final quiz = await _quizApi.getCompleted(study.id);
        items.add(_CompletedQuizItem(studyName: study.name, quiz: quiz));
      } catch (_) {
        // No matching completed-quiz record for this study id (yet); skip it
        // instead of breaking the whole list for one item.
      }
    }
    return items;
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 768;

    return Scaffold(
      appBar: AttachmentAppBar(title: context.tr('completedQuizzesTitle')),
      body: SafeArea(
        child: FutureBuilder<List<_CompletedQuizItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(context.tr('errorGeneric')));
            }
            final items = snapshot.data ?? const [];
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(context.tr('noCompletedQuizzesYet')),
                    ],
                  ),
                ),
              );
            }
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _CompletedQuizTile(
                      item: items[index],
                      isDesktop: isDesktop,
                      quizApi: _quizApi,
                      onChanged: _reload,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CompletedQuizTile extends StatefulWidget {
  const _CompletedQuizTile({
    required this.item,
    required this.isDesktop,
    required this.quizApi,
    required this.onChanged,
  });

  final _CompletedQuizItem item;
  final bool isDesktop;
  final QuizApiService quizApi;
  final VoidCallback onChanged;

  @override
  State<_CompletedQuizTile> createState() => _CompletedQuizTileState();
}

class _CompletedQuizTileState extends State<_CompletedQuizTile> {
  bool _busy = false;

  Quiz get _quiz => widget.item.quiz;
  String get _title => _quiz.title.isEmpty ? widget.item.studyName : _quiz.title;

  Future<void> _toggleVisibility(bool makePublic) async {
    setState(() => _busy = true);
    try {
      final updated = await widget.quizApi.updateVisibility(
        _quiz.id,
        makePublic ? QuizVisibility.public : QuizVisibility.private,
      );
      if (mounted) {
        setState(() {
          widget.item.quiz = updated;
          _busy = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('errorGeneric'))),
        );
      }
    }
  }

  void _openShareModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => QuizShareModal(quizId: _quiz.id, quizTitle: _title),
    );
  }

  void _openLeaderboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizLeaderboardScreen(
          quizId: _quiz.id,
          quizTitle: _title,
          isDesktop: widget.isDesktop,
        ),
      ),
    );
  }

  Future<void> _delete() async {
    if (_quiz.isDeleteProtected) return;
    setState(() => _busy = true);
    try {
      await widget.quizApi.delete(_quiz.id);
      widget.onChanged();
    } on QuizDeleteForbiddenException {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('deleteProtectedTooltip'))),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('errorGeneric'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPublic = _quiz.visibility == QuizVisibility.public;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_quiz.totalQuestions} ${context.tr('question')} • ${_quiz.totalAttempts} ${context.tr('startQuiz')}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isPublic ? context.tr('visibilityPublic') : context.tr('visibilityPrivate'),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Switch(
                    value: isPublic,
                    onChanged: _busy ? null : _toggleVisibility,
                  ),
                ],
              ),
              IconButton(
                tooltip: context.tr('shareAction'),
                icon: const Icon(Icons.share_outlined),
                onPressed: _busy ? null : _openShareModal,
              ),
              IconButton(
                tooltip: context.tr('leaderboardAction'),
                icon: const Icon(Icons.emoji_events_outlined),
                onPressed: _busy ? null : _openLeaderboard,
              ),
              _quiz.isDeleteProtected
                  ? Tooltip(
                      message: context.tr('deleteProtectedTooltip'),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: null,
                      ),
                    )
                  : IconButton(
                      tooltip: context.tr('delete'),
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: _busy ? null : _delete,
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
