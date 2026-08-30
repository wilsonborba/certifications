import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:certifications/domain/services/pending_intent_store.dart';
import 'package:certifications/domain/services/quiz_api_service.dart';
import 'package:certifications/presentation/components/auth/quiz_auth_guard.dart';
import 'package:certifications/presentation/components/premium_hover_card.dart';
import 'package:certifications/presentation/widgets/quiz/shared_quiz_answer.dart';
import 'package:flutter/material.dart';

/// Landing point for a quiz share link (`/quizzes/shared/{token}`) and for
/// resuming a pending quiz intent right after login/signup (#40). Browsing
/// this preview is anonymous-friendly (once the companion backend fix for
/// anonymous reads lands on certifications_api); actually starting the quiz
/// is gated behind [ensureAuthenticatedForQuiz].
class OnSharedQuizScreen extends StatefulWidget {
  const OnSharedQuizScreen({super.key, required this.shareToken, this.resumed = false});

  final String shareToken;

  /// True when this screen was opened by resuming a pending intent right
  /// after the visitor authenticated, rather than from a fresh link visit.
  final bool resumed;

  @override
  State<OnSharedQuizScreen> createState() => _OnSharedQuizScreenState();
}

class _OnSharedQuizScreenState extends State<OnSharedQuizScreen> {
  final _quizApi = QuizApiService();
  late final Future<Map<String, dynamic>> _future = _quizApi.getShared(widget.shareToken);
  bool _starting = false;

  Future<void> _start(Map<String, dynamic> data) async {
    setState(() => _starting = true);
    final title = (data['title'] as String?) ?? context.tr('sharedQuizTitle');
    final canProceed = await ensureAuthenticatedForQuiz(
      PendingQuizIntent(shareToken: widget.shareToken, quizTitle: title),
    );
    if (!mounted) return;
    // canProceed == false means the visitor is being redirected to auth
    // right now; there is nothing left to update on this screen.
    if (!canProceed) return;
    setState(() => _starting = false);

    final quizData = (data['quiz_data'] as Map?)?.cast<String, dynamic>() ?? const {};
    final questions = ((quizData['questions'] as List? ?? const [])
            .cast<Map<String, dynamic>>())
        .map(StudyQuestion.fromJson)
        .toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SharedQuizAnswerScreen(
          shareToken: widget.shareToken,
          quizId: data['quiz_id'] as String? ?? '',
          title: title,
          questions: questions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('sharedQuizTitle'))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.link_off, size: 48, color: scheme.onSurface.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text(context.tr('sharedQuizUnavailable'), textAlign: TextAlign.center),
                        ],
                      ),
                    );
                  }

                  final data = snapshot.data ?? const {};
                  final title = (data['title'] as String?) ?? context.tr('sharedQuizTitle');
                  final description = (data['description'] as String?) ?? '';
                  final totalQuestions = (data['total_questions'] as num?)?.toInt() ?? 0;

                  return PremiumHoverCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.resumed) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle, size: 14, color: Colors.green),
                                const SizedBox(width: 6),
                                Text(
                                  context.tr('sharedQuizResumedBanner'),
                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(description, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Icon(Icons.quiz_outlined, size: 18, color: scheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              context.trParams('sharedQuizQuestionCount', {'count': '$totalQuestions'}),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _starting ? null : () => _start(data),
                            icon: _starting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.play_arrow),
                            label: Text(context.tr('startQuiz')),
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
