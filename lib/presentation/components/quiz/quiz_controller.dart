// controllers/quiz_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:accredit/core/utils/my_logs.dart';
import 'package:accredit/domain/models/quiz.dart';
import 'package:accredit/domain/models/topic_identifications.dart';



class QuizController extends ChangeNotifier {
  final CertificationFormData formData;
  final ContextInfo payload;

  // Parsed questions (must include 'id')
  late final List<QuestionItem> questions = _parseQuestions(payload.data);

  // UI selections: still index-based for simplicity in the views
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

  /// Builds a backend-friendly payload: [{questionId, selectedIndex, selectedText}, ...]
  List<AnswerSelection> buildSelectionsPayload() {
    final out = <AnswerSelection>[];
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final idx = selections[i];
      final txt = (idx != null && idx >= 0 && idx < q.options.length) ? q.options[idx] : null;
      out.add(AnswerSelection(questionId: q.id, selectedIndex: idx, selectedText: txt));
    }
    return out;
  }

  /// Call when user taps Finish
  QuizResult finish() {
    final spent = timeSpent;
    final result = QuizResult(selectedOptionIndexes: selections, timeSpent: spent);

    final payload = buildSelectionsPayload();
    debug('Finished. Spent: $spent');
    debug('Selections (by index): $selections');
    debug('Submission payload: ${payload.map((e) => e.toJson()).toList()}');

    // TODO: submit `payload.map((e) => e.toJson()).toList()` to your backend.
    // You can include `formData`, `timeSpent`, etc., alongside.

    return result;
  }

  Duration get timeSpent {
    final start = _startAt ?? DateTime.now();
    return DateTime.now().difference(start);
  }

  void setSelection(int index, int? value) {
    selections[index] = value;
    notifyListeners();
  }

  // Helpers
  String formatMMSS(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Robust parser that extracts an `id` for each question.
  /// If your API doesn't send an id, we generate a stable fallback.
  static List<QuestionItem> _parseQuestions(List<dynamic> raw) {
    final out = <QuestionItem>[];
    for (var i = 0; i < raw.length; i++) {
      final e = raw[i];
      if (e is Map<String, dynamic>) {
        // Try common id fields; fallback to index-based id if missing
        final idRaw = (e['id'] ?? e['_id'] ?? e['question_id'] ?? '').toString().trim();
        final id = idRaw.isNotEmpty ? idRaw : 'q_$i';

        final q = (e['question'] ?? e['question_text'] ?? '').toString().trim();
        final optsAny = e['options'];
        final diffAny = e['difficulty'];

        final opts = (optsAny is List)
            ? optsAny.map((o) => o.toString()).toList()
            : <String>[];

        final diff = diffAny == null ? null : int.tryParse(diffAny.toString());

        if (q.isNotEmpty && opts.isNotEmpty) {
          // Ensure your QuestionItem has an `id` field in your model.
          out.add(QuestionItem(id: id, question: q, options: opts, difficulty: diff));
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
