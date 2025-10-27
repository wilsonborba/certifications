// widgets/quiz/base_quiz.dart
import 'dart:async';
import 'package:accredit/core/utils/my_logs.dart';
import 'package:accredit/domain/models/quiz.dart';
import 'package:accredit/domain/models/topic_identifications.dart';
import 'package:flutter/material.dart';


abstract class BaseQuiz extends StatefulWidget {
  final CertificationFormData formData;
  final ContextInfo questionPayload;
  BaseQuiz({super.key, required this.questionPayload, required this.formData});
}

abstract class BaseQuizState<T extends BaseQuiz> extends State<T> {
  // Parsed questions
  late final List<QuestionItem> questions = _parseQuestions(widget.questionPayload.data);

  // Timer
  late final int totalMinutes = questions.length * 1;
  late final int totalSeconds = totalMinutes * 60;
  late final ValueNotifier<int> remainingSeconds = ValueNotifier<int>(totalSeconds);
  Timer? _ticker;
  late final DateTime _startAt;

  // User selections
  late final List<int?> selections = List<int?>.filled(questions.length, null);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    remainingSeconds.dispose();
    super.dispose();
  }

  void _startTimer() {
    _startAt = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      final s = totalSeconds - t.tick;
      if (s <= 0) {
        remainingSeconds.value = 0;
        t.cancel();
        onTimeUp();
      } else {
        remainingSeconds.value = s;
      }
    });
  }

  void onTimeUp() {
    // For now: act as finish
    debug('Time finished — auto-submitting.');
    onFinishPressed();
  }

  void onFinishPressed() async {
    final timeSpent = DateTime.now().difference(_startAt);
    final result = QuizResult(selectedOptionIndexes: selections, timeSpent: timeSpent);
    // For now, just print
    debug('Finished. Selections: $selections | spent: $timeSpent');
    // TODO: plug your submit here
  }

  // Robust parser from List<dynamic>
  List<QuestionItem> _parseQuestions(List<dynamic> raw) {
    final out = <QuestionItem>[];
    for (final e in raw) {
      if (e is Map<String, dynamic>) {
         final q = (e['question'] ?? e['question_text'] ?? '').toString().trim();
        final optsAny = e['options'];
        final diffAny = e['difficulty'];
        final opts = (optsAny is List)
            ? optsAny.map((o) => o.toString()).toList()
            : <String>[];
        final diff = diffAny == null ? null : int.tryParse(diffAny.toString());
        if (q.isNotEmpty && opts.isNotEmpty) {
          out.add(QuestionItem(question: q, options: opts, difficulty: diff));
        }
      }
    }
    return out;
  }

  // Helpers
  String formatMMSS(int secs) {
    final m = (secs ~/ 60).toString().padLeft(1, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
