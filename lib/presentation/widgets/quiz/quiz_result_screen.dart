import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/quiz.dart';
import 'package:certifications/presentation/components/attachment/app_bar.dart';
import 'package:certifications/presentation/components/premium_hover_card.dart';
import 'package:certifications/presentation/components/quiz/quiz_leaderboard_view.dart';
import 'package:flutter/material.dart';

/// One reviewed question in the finished-quiz summary: the prompt, the
/// choice the taker picked, and (once graded) the correct one.
class QuizReviewQuestion {
  const QuizReviewQuestion({
    required this.id,
    required this.prompt,
    required this.choices,
  });

  final String id;
  final String prompt;
  final List<String> choices;
}

/// Score summary and per-question review shown after finishing a quiz,
/// whichever flow it came from (the study wizard, or a shared link).
class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({
    super.key,
    required this.title,
    required this.grade,
    required this.questions,
    this.quizId,
    this.isDesktop = false,
  });

  final String title;
  final QuizGradeResult grade;
  final List<QuizReviewQuestion> questions;

  /// When set, a "View leaderboard" action is offered for this completed
  /// quiz's id.
  final String? quizId;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final quizId = this.quizId;

    return Scaffold(
      appBar: AttachmentAppBar(title: context.tr('quizResultTitle')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                PremiumHoverCard(
                  accentColor: scheme.primary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            '${grade.score.toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              context.trParams('quizResultSummary', {
                                'correct': '${grade.correctCount}',
                                'total': '${grade.totalQuestions}',
                              }),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                      if (quizId != null) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.leaderboard_outlined),
                            label: Text(context.tr('viewLeaderboard')),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuizLeaderboardScreen(
                                  quizId: quizId,
                                  quizTitle: title,
                                  isDesktop: isDesktop,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  context.tr('quizReviewTitle'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...questions.map((question) {
                  final detail = grade.detailFor(question.id);
                  final isCorrect = detail?.isCorrect ?? false;
                  final correctIndex = detail?.correctIndex;
                  final statusColor = isCorrect ? Colors.green : Colors.redAccent;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PremiumHoverCard(
                      accentColor: statusColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                isCorrect ? Icons.check_circle : Icons.cancel,
                                color: statusColor,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  question.prompt,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...List.generate(question.choices.length, (i) {
                            final isChosen = detail?.chosenIndex == i;
                            final isAnswer = correctIndex == i;
                            Color? color;
                            if (isAnswer) color = Colors.green;
                            if (isChosen && !isAnswer) color = Colors.redAccent;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Icon(
                                    isAnswer
                                        ? Icons.check
                                        : (isChosen ? Icons.close : Icons.circle_outlined),
                                    size: 16,
                                    color: color ?? scheme.onSurface.withValues(alpha: 0.4),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      question.choices[i],
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: (isAnswer || isChosen)
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          if (detail?.explanation != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              detail!.explanation!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.7),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.of(context).popUntil((route) => route.isFirst),
                    child: Text(context.tr('done')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
