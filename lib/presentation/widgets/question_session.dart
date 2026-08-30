import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:certifications/domain/services/draft_progress_store.dart';
import 'package:certifications/domain/services/quiz_api_service.dart';
import 'package:certifications/domain/services/study_api_service.dart';
import 'package:flutter/material.dart';
import 'package:certifications/presentation/components/attachment/app_bar.dart';
import 'package:certifications/presentation/components/quiz/question_visual.dart';
import 'package:certifications/presentation/widgets/quiz/quiz_result_screen.dart';

class QuestionSession extends StatefulWidget {
  const QuestionSession({
    super.key,
    required this.studyId,
    required this.studyName,
    required this.difficulty,
    required this.useWeb,
  });
  final String studyId;
  final String studyName;
  final String difficulty;
  final bool useWeb;
  @override
  State<QuestionSession> createState() => _QuestionSessionState();
}

class _QuestionSessionState extends State<QuestionSession> {
  final api = StudyApiService();
  final quizApi = QuizApiService();
  late final Future<List<StudyQuestion>> future = api.generateQuestions(
    studyId: widget.studyId,
    difficulty: widget.difficulty,
    useWeb: widget.useWeb,
    idempotencyKey: '${DateTime.now().microsecondsSinceEpoch}-question',
  );
  final Map<String, int> _answers = {};
  int index = 0;
  bool _finishing = false;
  String? _error;

  Future<void> _finish(List<StudyQuestion> questions) async {
    setState(() {
      _finishing = true;
      _error = null;
    });
    try {
      final grade = await api.submitAnswers(
        studyId: widget.studyId,
        answers: _answers,
      );
      final visibility = await DraftProgressStore.instance.getVisibility(
        widget.studyId,
      );
      final quizData = {
        'questions': [
          for (final question in questions)
            {
              'id': question.id,
              'prompt': question.prompt,
              'choices': question.choices,
              'visual': question.visual,
              'correct_index': grade.detailFor(question.id)?.correctIndex,
              'explanation': grade.detailFor(question.id)?.explanation,
            },
        ],
      };
      final quiz = await quizApi.createCompleted(
        title: widget.studyName,
        visibility: visibility,
        totalQuestions: questions.length,
        quizData: quizData,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            title: widget.studyName,
            grade: grade,
            quizId: quiz.id,
            questions: [
              for (final question in questions)
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AttachmentAppBar(title: context.tr('question')),
    body: FutureBuilder<List<StudyQuestion>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError || (snapshot.data?.isEmpty ?? true))
          return Center(child: Text(context.tr('errorGeneric')));
        final questions = snapshot.data!;
        final question = questions[index];
        final selected = _answers[question.id];
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  '${index + 1} / ${questions.length}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  question.prompt,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                QuestionVisual(
                  visual: question.visual,
                  diagramUrl: question.visual['kind'] == 'd2'
                      ? api.diagramUrl(widget.studyId, question.id)
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
                            ? Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest
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
                          if (index + 1 == questions.length) {
                            _finish(questions);
                          } else {
                            setState(() => index++);
                          }
                        },
                  child: _finishing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          index + 1 == questions.length
                              ? context.tr('finish')
                              : context.tr('next'),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
