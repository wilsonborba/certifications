// controllers/quiz_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:accredit/core/utils/my_logs.dart';
import 'package:accredit/domain/models/quiz.dart';
import 'package:accredit/domain/models/topic_identifications.dart';

class QuizController extends ChangeNotifier {
  final CertificationFormData formData;
  final ContextInfo payload;

  // Parsed questions
  late final List<QuestionItem> questions = _parseQuestions(payload.data);

  // Selections
  late final List<int?> selections = List<int?>.filled(questions.length, null);

  // Timer
  late final int totalSeconds = (questions.length * 1) * 60; // 1 min per Q
  final ValueNotifier<int> remainingSeconds = ValueNotifier<int>(0);
  Timer? _ticker;
  DateTime? _startAt;

  QuizController({required this.formData, required this.payload}) {
    _start();
  }

  void _start() {
    _startAt = DateTime.now();
    remainingSeconds.value = totalSeconds;
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
    debug('Time finished — auto-submitting.');
    finish();
  }

  /// Call when user taps Finish
  QuizResult finish() {
    final spent = timeSpent;
    final result = QuizResult(selectedOptionIndexes: selections, timeSpent: spent);
    debug('Finished. Selections: $selections | spent: $spent');
    // TODO: submit result here
    return result;
  }

  Duration get timeSpent {
    final start = _startAt ?? DateTime.now();
    return DateTime.now().difference(start);
  }

  void setSelection(int index, int? value) {
    selections[index] = value;
    notifyListeners(); // Let views rebuild if they listen to the controller
  }

  // Helpers
  String formatMMSS(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static List<QuestionItem> _parseQuestions(List<dynamic> raw) {
    final out = <QuestionItem>[];
    for (final e in raw) {
      if (e is Map<String, dynamic>) {
        final q = (e['question'] ?? e['question_text'] ?? '').toString().trim();
        final optsAny = e['options'];
        final diffAny = e['difficulty'];
        final opts = (optsAny is List) ? optsAny.map((o) => o.toString()).toList() : <String>[];
        final diff = diffAny == null ? null : int.tryParse(diffAny.toString());
        if (q.isNotEmpty && opts.isNotEmpty) {
          out.add(QuestionItem(question: q, options: opts, difficulty: diff));
        }
      }
    }
    return out;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    remainingSeconds.dispose();
    super.dispose();
  }
}
