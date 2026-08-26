import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:certifications/domain/services/study_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_svg/flutter_svg.dart';

class QuestionSession extends StatefulWidget {
  const QuestionSession({
    super.key,
    required this.studyId,
    required this.difficulty,
  });
  final String studyId;
  final String difficulty;
  @override
  State<QuestionSession> createState() => _QuestionSessionState();
}

class _QuestionSessionState extends State<QuestionSession> {
  final api = StudyApiService();
  late final Future<List<StudyQuestion>> future = api.generateQuestions(
    studyId: widget.studyId,
    difficulty: widget.difficulty,
    idempotencyKey: '${DateTime.now().microsecondsSinceEpoch}-question',
  );
  int index = 0;
  int? selected;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('question'))),
    body: FutureBuilder<List<StudyQuestion>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError || (snapshot.data?.isEmpty ?? true))
          return Center(child: Text(context.tr('errorGeneric')));
        final questions = snapshot.data!;
        final question = questions[index];
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
                _Visual(question: question, api: api, studyId: widget.studyId),
                ...List.generate(
                  question.choices.length,
                  (choice) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: OutlinedButton(
                      onPressed: () => setState(() => selected = choice),
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
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: selected == null
                      ? null
                      : () {
                          if (index + 1 == questions.length) {
                            Navigator.pop(context);
                          } else {
                            setState(() {
                              index++;
                              selected = null;
                            });
                          }
                        },
                  child: Text(
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

class _Visual extends StatelessWidget {
  const _Visual({
    required this.question,
    required this.api,
    required this.studyId,
  });
  final StudyQuestion question;
  final StudyApiService api;
  final String studyId;
  @override
  Widget build(BuildContext context) {
    final kind = question.visual['kind'];
    if (kind == 'latex')
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Semantics(
          label: question.visual['description'] as String?,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Math.tex(question.visual['source'] as String),
          ),
        ),
      );
    if (kind == 'd2')
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: SizedBox(
          height: 260,
          child: SvgPicture.network(
            api.diagramUrl(studyId, question.id),
            placeholderBuilder: (_) =>
                const Center(child: CircularProgressIndicator()),
            errorBuilder: (_, __, ___) =>
                Center(child: Text(context.tr('diagramUnavailable'))),
          ),
        ),
      );
    return const SizedBox.shrink();
  }
}
