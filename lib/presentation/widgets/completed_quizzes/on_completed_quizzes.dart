import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/quiz.dart';
import 'package:certifications/domain/services/quiz_api_service.dart';
import 'package:certifications/presentation/components/attachment/app_bar.dart';
import 'package:certifications/presentation/components/quiz/quiz_leaderboard_view.dart';
import 'package:certifications/presentation/components/quiz/quiz_share_modal.dart';
import 'package:certifications/presentation/components/search/live_search_field.dart';
import 'package:flutter/material.dart';

/// Lists every completed quiz the user owns via the real
/// `GET /quizzes/completed` endpoint (list_completed_quizzes, already
/// filters by owner), replacing the previous workaround of deriving a quiz
/// id from the studies list and treating a study id as a quiz id one-to-one.
class OnCompletedQuizzesScreen extends StatefulWidget {
  const OnCompletedQuizzesScreen({super.key});

  @override
  State<OnCompletedQuizzesScreen> createState() => _OnCompletedQuizzesScreenState();
}

class _OnCompletedQuizzesScreenState extends State<OnCompletedQuizzesScreen> {
  final _quizApi = QuizApiService();
  late Future<List<Quiz>> _future = _quizApi.listCompleted();
  String _searchQuery = '';

  void _reload() => setState(() => _future = _quizApi.listCompleted());

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 768;

    return Scaffold(
      appBar: AttachmentAppBar(title: context.tr('completedQuizzesTitle')),
      endDrawer: const AttachmentSideMenu(),
      body: SafeArea(
        child: FutureBuilder<List<Quiz>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(context.tr('errorGeneric')));
            }
            final quizzes = snapshot.data ?? const [];
            final filtered = _searchQuery.isEmpty
                ? quizzes
                : quizzes
                      .where((q) => q.title.toLowerCase().contains(_searchQuery.toLowerCase()))
                      .toList();

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (quizzes.isNotEmpty) ...[
                        LiveSearchField(
                          hintText: context.tr('searchQuizzesHint'),
                          onChanged: (value) => setState(() => _searchQuery = value),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Expanded(
                        child: quizzes.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.emoji_events_outlined, size: 48, color: Colors.grey),
                                    const SizedBox(height: 12),
                                    Text(context.tr('noCompletedQuizzesYet')),
                                  ],
                                ),
                              )
                            : filtered.isEmpty
                            ? Center(
                                child: Text(
                                  context.trParams('noSearchResultsLabel', {'query': _searchQuery}),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (context, index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _CompletedQuizTile(
                                    quiz: filtered[index],
                                    isDesktop: isDesktop,
                                    quizApi: _quizApi,
                                    onChanged: _reload,
                                  ),
                                ),
                              ),
                      ),
                    ],
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
    required this.quiz,
    required this.isDesktop,
    required this.quizApi,
    required this.onChanged,
  });

  final Quiz quiz;
  final bool isDesktop;
  final QuizApiService quizApi;
  final VoidCallback onChanged;

  @override
  State<_CompletedQuizTile> createState() => _CompletedQuizTileState();
}

class _CompletedQuizTileState extends State<_CompletedQuizTile> {
  bool _busy = false;
  late Quiz _quiz = widget.quiz;

  String get _title => _quiz.title.isEmpty ? _quiz.id : _quiz.title;

  Future<void> _toggleVisibility(bool makePublic) async {
    setState(() => _busy = true);
    try {
      final updated = await widget.quizApi.updateVisibility(
        _quiz.id,
        makePublic ? QuizVisibility.public : QuizVisibility.private,
      );
      if (mounted) {
        setState(() {
          _quiz = updated;
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
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
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
              color: scheme.onSurface.withValues(alpha: 0.6),
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
