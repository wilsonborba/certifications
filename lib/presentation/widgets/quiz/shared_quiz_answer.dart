import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:certifications/domain/services/quiz_api_service.dart';
import 'package:certifications/presentation/components/attachment/app_bar.dart';
import 'package:certifications/presentation/components/quiz/question_visual.dart';
import 'package:certifications/presentation/widgets/quiz/quiz_result_screen.dart';
import 'package:flutter/material.dart';

/// Answering flow for a quiz reached through a shared link (#40), started
/// once the visitor is authenticated. Mirrors [QuestionSession] but grades
/// and submits against the shared-quiz endpoints instead of the study ones,
/// since the taker does not own (and may not even have access to) the study
/// that originally generated these questions.
class SharedQuizAnswerScreen extends StatefulWidget {
  const SharedQuizAnswerScreen({
    super.key,
    required this.shareToken,
    required this.quizId,
    required this.title,
    required this.questions,
  });

  final String shareToken;
  final String quizId;
  final String title;
  final List<StudyQuestion> questions;

  @override
  State<SharedQuizAnswerScreen> createState() => _SharedQuizAnswerScreenState();
}

class _SharedQuizAnswerScreenState extends State<SharedQuizAnswerScreen> {
  final _quizApi = QuizApiService();
  final DateTime _startedAt = DateTime.now();
  final Map<String, int> _answers = {};
  int _index = 0;
  bool _finishing = false;
  String? _error;

  // Cached per question.id so navigating back to an already-viewed question
  // reuses the already-downloaded diagram instead of re-fetching it.
  final Map<String, Future<List<int>>> _diagramCache = {};

  Future<List<int>> _diagramBytes(StudyQuestion question) {
    return _diagramCache.putIfAbsent(question.id, () async {
      final response = await ApiAdapter().get(
        Uri.parse(_quizApi.sharedDiagramUrl(widget.shareToken, question.id)),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Diagram request failed: ${response.statusCode}');
      }
      return response.bodyBytes;
    });
  }

  Future<String?> _promptForName() => showDialog<String>(
    context: context,
    builder: (context) {
      final controller = TextEditingController();
      return AlertDialog(
        title: Text(context.tr('yourNameLabel')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: context.tr('anonymous')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(context.tr('submit')),
          ),
        ],
      );
    },
  );

  Future<void> _finish() async {
    setState(() {
      _finishing = true;
      _error = null;
    });
    try {
      final grade = await _quizApi.gradeSharedAnswers(
        widget.shareToken,
        _answers,
      );
      if (!mounted) return;
      final userName = await _promptForName();
      if (!mounted) return;
      final timeSpentSeconds = DateTime.now().difference(_startedAt).inSeconds;
      await _quizApi.submitSharedAttempt(widget.shareToken, {
        'user_name': (userName == null || userName.isEmpty) ? 'Anonymous' : userName,
        'score': grade.score,
        'correct_count': grade.correctCount,
        'wrong_count': grade.wrongCount,
        'time_spent_seconds': timeSpentSeconds,
        'answers_json': _answers,
      });
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            title: widget.title,
            grade: grade,
            quizId: widget.quizId,
            questions: [
              for (final question in widget.questions)
                QuizReviewQuestion(
                  id: question.id,
                  prompt: question.prompt,
                  choices: question.choices,
                ),
            ],
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _finishing = false;
        _error = context.tr('errorGeneric');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.questions;
    final question = questions[_index];
    final selected = _answers[question.id];

    return Scaffold(
      appBar: AttachmentAppBar(title: context.tr('question')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                '${_index + 1} / ${questions.length}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 16),
              Text(
                question.prompt,
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              QuestionVisual(
                key: ValueKey(question.id),
                visual: question.visual,
                diagramBytes: question.visual['kind'] == 'd2'
                    ? _diagramBytes(question)
                    : null,
              ),
              ...List.generate(
                question.choices.length,
                (choice) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OutlinedButton(
                    onPressed: _finishing
                        ? null
                        : () => setState(() => _answers[question.id] = choice),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      backgroundColor: selected == choice
                          ? Theme.of(context).colorScheme.surfaceContainerHighest
                          : null,
                    ),
                    child: Text(question.choices[choice]),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: selected == null || _finishing
                    ? null
                    : () {
                        if (_index + 1 == questions.length) {
                          _finish();
                        } else {
                          setState(() => _index++);
                        }
                      },
                child: _finishing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _index + 1 == questions.length
                            ? context.tr('finish')
                            : context.tr('next'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
