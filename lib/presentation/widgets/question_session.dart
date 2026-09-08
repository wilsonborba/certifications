import 'dart:async';
import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:certifications/domain/services/draft_progress_store.dart';
import 'package:certifications/domain/services/quiz_api_service.dart';
import 'package:certifications/domain/services/study_api_service.dart';
import 'package:flutter/material.dart';
import 'package:certifications/presentation/components/attachment/app_bar.dart';
import 'package:certifications/presentation/components/quiz/futuristic_loading.dart';
import 'package:certifications/presentation/components/quiz/question_citations.dart';
import 'package:certifications/presentation/components/quiz/question_visual.dart';
import 'package:certifications/presentation/widgets/quiz/quiz_result_screen.dart';

class QuestionSession extends StatefulWidget {
  const QuestionSession({
    super.key,
    required this.studyId,
    required this.studyName,
    required this.difficulty,
    required this.useWeb,
    this.questionCount = 10,
    this.initialQuestions,
  });
  final String studyId;
  final String studyName;
  final String difficulty;
  final bool useWeb;
  final int questionCount;
  final List<StudyQuestion>? initialQuestions;
  @override
  State<QuestionSession> createState() => _QuestionSessionState();
}

class _QuestionSessionState extends State<QuestionSession> {
  final api = StudyApiService();
  final quizApi = QuizApiService();
  late final Future<List<StudyQuestion>> future = widget.initialQuestions != null
      ? Future.value(widget.initialQuestions!)
      : api.generateQuestions(
          studyId: widget.studyId,
          difficulty: widget.difficulty,
          useWeb: widget.useWeb,
          idempotencyKey: '${DateTime.now().microsecondsSinceEpoch}-question',
          questionCount: widget.questionCount,
        );
  final Map<String, int> _answers = {};
  int index = 0;
  bool _finishing = false;
  String? _error;

  // Cached per question.id so navigating back to an already-viewed question
  // reuses the already-downloaded diagram instead of re-fetching it.
  final Map<String, Future<List<int>>> _diagramCache = {};

  Future<List<int>> _diagramBytes(StudyQuestion question) {
    return _diagramCache.putIfAbsent(question.id, () async {
      final response = await ApiAdapter().get(
        Uri.parse(api.diagramUrl(widget.studyId, question.id)),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Diagram request failed: ${response.statusCode}');
      }
      return response.bodyBytes;
    });
  }

  Timer? _timer;
  int _secondsElapsed = 0;

  /// Total time budget for the whole quiz, set once the question count is
  /// known (90s/question, 3-60 minutes). When the countdown reaches zero the
  /// quiz auto-submits with whatever was answered so far.
  int? _timeLimitSeconds;

  @override
  void initState() {
    super.initState();
    _startTimer();
    future.then((questions) {
      if (mounted) {
        setState(() => _timeLimitSeconds = _computeTimeLimit(questions.length));
      }
    });
  }

  int _computeTimeLimit(int questionCount) =>
      (questionCount * 90).clamp(180, 3600);

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsElapsed++);
      final limit = _timeLimitSeconds;
      if (limit != null && _secondsElapsed >= limit && !_finishing) {
        _timer?.cancel();
        future.then((questions) {
          if (mounted) _finish(questions);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final clamped = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = (clamped ~/ 60).toString().padLeft(2, '0');
    final seconds = (clamped % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  bool _cancelling = false;

  Future<void> _cancelQuiz() async {
    // Same double-tap guard as _attemptFinish: without it, tapping the
    // cancel icon twice quickly can stack two confirmation dialogs and,
    // worse, race two Navigator.popUntil calls against each other.
    if (_cancelling) return;
    _cancelling = true;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('cancelQuizTitle') != 'cancelQuizTitle' ? ctx.tr('cancelQuizTitle') : 'Cancel Quiz?'),
        content: Text(
          ctx.tr('cancelQuizMessage') != 'cancelQuizMessage'
              ? ctx.tr('cancelQuizMessage')
              : 'Are you sure you want to cancel this quiz? All study progress and uploaded documents will be permanently erased.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.tr('cancel') != 'cancel' ? ctx.tr('cancel') : 'No, Keep Going'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.tr('confirm') != 'confirm' ? ctx.tr('confirm') : 'Yes, Cancel & Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) {
      _cancelling = false;
      return;
    }

    try {
      await api.deleteStudy(widget.studyId);
      await DraftProgressStore.instance.clear(widget.studyId);
    } catch (_) {}

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _attemptFinish(List<StudyQuestion> questions) async {
    // Cheap early-out so a double-tap doesn't pop the confirmation dialog
    // twice - not load-bearing for the race below, _finish() is.
    if (_finishing) return;

    final unansweredCount = questions.length - _answers.length;
    if (unansweredCount > 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(ctx.tr('unansweredTitle') != 'unansweredTitle' ? ctx.tr('unansweredTitle') : 'Unanswered Questions'),
          content: Text(
            ctx.tr('unansweredMessage') != 'unansweredMessage'
                ? ctx.tr('unansweredMessage')
                : 'You have $unansweredCount unanswered question(s). Submitting now will grade them as incorrect. Do you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.tr('review') != 'review' ? ctx.tr('review') : 'Review Questions'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.tr('submitAnyway') != 'submitAnyway' ? ctx.tr('submitAnyway') : 'Submit Anyway'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }
    await _finish(questions);
  }

  Future<void> _finish(List<StudyQuestion> questions) async {
    // The single authoritative guard against this running twice
    // concurrently, covering BOTH ways it can be reached: a manual tap on
    // "Finish" (via _attemptFinish above) and the countdown timer's direct
    // auto-submit call (_startTimer, which intentionally bypasses the
    // unanswered-questions dialog). If both land at nearly the same moment -
    // e.g. the timer expires right as the user taps Finish - the loser must
    // bail out here before doing any work, not just have its *button*
    // disabled: two concurrent Navigator.pushReplacement calls to
    // QuizResultScreen corrupt the Navigator's internal Overlay, which
    // surfaces as unrelated-looking crashes elsewhere in the tree
    // ("_elements.contains(element) is not true", or any EditableText
    // suddenly unable to find its Overlay ancestor).
    if (_finishing) return;
    // Stop the per-second timer BEFORE the async submit/create/navigate
    // sequence starts, not just in dispose(): submitAnswers + createCompleted
    // together reliably take well over a second, so without this the timer
    // is guaranteed to fire its own setState/rebuild at least once *during*
    // that window, every single time - landing right as
    // Navigator.pushReplacement below reconciles the Overlay, which is what
    // corrupts it ("_elements.contains(element) is not true", or any
    // EditableText suddenly unable to find its Overlay ancestor). This is
    // why the crash was 100% reproducible rather than an occasional race.
    _timer?.cancel();
    setState(() {
      _finishing = true;
      _error = null;
    });
    try {
      // Ensure all questions exist in payload even if unpicked (-1 default)
      final submissionMap = <String, int>{};
      for (final q in questions) {
        submissionMap[q.id] = _answers[q.id] ?? -1;
      }

      final grade = await api.submitAnswers(
        studyId: widget.studyId,
        answers: submissionMap,
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
      _startTimer(); // submission failed - the user is still on this screen, so resume the countdown instead of leaving it frozen
      setState(() {
        _finishing = false;
        _error = context.tr('errorGeneric');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AttachmentAppBar(title: context.tr('question')),
      endDrawer: const AttachmentSideMenu(),
      body: FutureBuilder<List<StudyQuestion>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return FuturisticLoading(
              currentStep: 3,
              messages: [
                context.tr('loadingCreatingStudy'),
                context.tr('loadingUploadingFiles'),
                context.tr('loadingProcessingContent'),
                context.tr('loadingAlmostReady'),
              ],
            );
          }
          if (snapshot.hasError || (snapshot.data?.isEmpty ?? true))
            return Center(child: Text(context.tr('errorGeneric')));
          final questions = snapshot.data!;
          final question = questions[index];
          final selected = _answers[question.id];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  // ── Header: Progress & Live Timer ─────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${index + 1} / ${questions.length}',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Builder(builder: (context) {
                            final limit = _timeLimitSeconds;
                            final remaining = limit == null ? null : limit - _secondsElapsed;
                            final low = remaining != null && remaining <= 60;
                            final timerColor = low ? Colors.redAccent : scheme.primary;
                            return Row(
                              children: [
                                Icon(Icons.timer_outlined, size: 20, color: timerColor),
                                const SizedBox(width: 6),
                                Text(
                                  _formatDuration(remaining ?? _secondsElapsed),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: timerColor,
                                  ),
                                ),
                              ],
                            );
                          }),
                          const SizedBox(width: 14),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.redAccent, size: 22),
                            tooltip: context.tr('cancelQuiz') != 'cancelQuiz' ? context.tr('cancelQuiz') : 'Cancel Quiz',
                            onPressed: _cancelQuiz,
                          ),
                        ],
                      ),
                    ],
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
                    key: ValueKey(question.id),
                    visual: question.visual,
                    diagramBytes: question.visual['kind'] == 'd2'
                        ? _diagramBytes(question)
                        : null,
                  ),
                  QuestionCitations(citations: question.citations),
                  ...List.generate(
                    question.choices.length,
                    (choice) {
                      final isSelected = selected == choice;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: _finishing
                                ? null
                                : () => setState(() => _answers[question.id] = choice),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? scheme.primary.withValues(alpha: 0.15)
                                    : scheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? scheme.primary
                                      : scheme.outlineVariant.withValues(alpha: 0.5),
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? scheme.primary : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected ? scheme.primary : scheme.outline,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      question.choices[choice],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        color: isSelected ? scheme.primary : scheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (index > 0)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _finishing ? null : () => setState(() => index--),
                            icon: const Icon(Icons.arrow_back),
                            label: Text(context.tr('previous') != 'previous' ? context.tr('previous') : 'Previous'),
                          ),
                        ),
                      if (index > 0) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _finishing
                              ? null
                              : () {
                                  if (index + 1 == questions.length) {
                                    _attemptFinish(questions);
                                  } else {
                                    setState(() => index++);
                                  }
                                },
                          icon: _finishing
                              ? const SizedBox.shrink()
                              : Icon(index + 1 == questions.length ? Icons.check_circle_outline : Icons.arrow_forward),
                          label: _finishing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  index + 1 == questions.length
                                      ? context.tr('finish')
                                      : context.tr('next'),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          );
        },
      ),
    );
  }
}
