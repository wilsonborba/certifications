// controllers/quiz_controller.dart
import 'dart:async';
import 'package:accredit/domain/services/api_asodya_manager.dart';
import 'package:accredit/domain/services/api_certification_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:accredit/core/utils/my_logs.dart';
import 'package:accredit/domain/models/quiz.dart';
import 'package:accredit/domain/models/topic_identifications.dart';
import 'package:http/http.dart';

class QuizController extends ChangeNotifier {
  final CertificationFormData formData;
  final ContextInfo payload;
  final bool isForPDF;
  final String contextId;

  // Parsed questions (must include 'id')
  late final List<QuestionItem> questions = _parseQuestions(payload.data);

  // UI selections: still index-based for simplicity in the views
  late final List<int?> selections = List<int?>.filled(questions.length, null);

  // Timer
  late final int totalSeconds =
      (questions.isEmpty ? 1 : questions.length) * 60; // 1 min per Q, min 60s
  final ValueNotifier<int> remainingSeconds = ValueNotifier<int>(0);
  Timer? _ticker;
  DateTime? _startAt;

  // Submit guards
  bool _submitting = false;
  Completer<Response?>?
  _finishCompleter; // ✅ Changed from Completer<QuizResult>

  QuizController({
    required this.formData,
    required this.payload,
    required this.isForPDF,
    required this.contextId,
  }) {
    _start();
  }

  void _start() {
    _startAt = DateTime.now();
    remainingSeconds.value = totalSeconds;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      final elapsed = t.tick;
      final s = totalSeconds - elapsed;
      if (s <= 0) {
        remainingSeconds.value = 0;
        t.cancel();
        // Avoid re-entrancy; let finish() handle guard
        onTimeUp();
      } else {
        remainingSeconds.value = s;
      }
    });
  }

  Future<void> onTimeUp() async {
    debug('Time finished — auto-submitting.');
    await finish();
  }

  /// Backend-friendly payload: [{questionId, selectedIndex, selectedText}, ...]
  List<AnswerSelection> buildSelectionsPayload() {
    final out = <AnswerSelection>[];
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];

      final questionId = isForPDF ? q.pdfQuestionId : q.id;

      final idx = selections[i];
      final txt = (idx != null && idx >= 0 && idx < q.options.length)
          ? q.options[idx]
          : null;
      out.add(
        AnswerSelection(
          questionId: questionId,
          selectedIndex: idx,
          selectedText: txt,
        ),
      );
    }
    return out;
  }

  /// Idempotent submission. If called twice, returns the same Future.
  Future<Response?> finish() async {
    if (_finishCompleter != null) {
      return _finishCompleter!.future;
    }
    _finishCompleter = Completer<Response?>(); // ✅ Changed type parameter

    if (_submitting) {
      return _finishCompleter!.future;
    }
    _submitting = true;

    _ticker?.cancel();
    _ticker = null;

    final spent = timeSpent;

    final payload = buildSelectionsPayload();

    Response? quizSubmissionR;

    try {
      await ApiAsodyaManager().updateUserInfo(
        formData.fullName,
        formData.phoneE164,
      );

      await Future.delayed(const Duration(seconds: 3));

      quizSubmissionR = await CertificationManager().submitQuiz(
        payload,
        timeSpent,
        formData,
        isForPDF,
        contextId,
      );

      _finishCompleter!.complete(quizSubmissionR); // ✅ Complete with Response
      return quizSubmissionR;
    } catch (e, st) {
      debug('Submit failed: $e\n$st');
      _finishCompleter!.complete(null); // ✅ Complete with null on error
      return null;
    } finally {
      _submitting = false;
    }
  }

  Duration get timeSpent {
    final start = _startAt ?? DateTime.now();
    return DateTime.now().difference(start);
  }

  void setSelection(int index, int? value) {
    if (index < 0 || index >= selections.length) return;
    selections[index] = value;
    notifyListeners();
  }

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
        final idRaw = (e['id'] ?? e['_id'] ?? e['question_id'] ?? '')
            .toString()
            .trim();
        final id = idRaw.isNotEmpty ? idRaw : 'q_$i';

        final q = (e['question'] ?? e['question_text'] ?? '').toString().trim();
        final optsAny = e['options'];
        final diffAny = e['difficulty'];

        final opts = (optsAny is List)
            ? optsAny.map((o) => o.toString()).toList()
            : <String>[];

        final diff = diffAny == null ? null : int.tryParse(diffAny.toString());

        final pdfQuestionId = e['pdf_question_id'];

        if (q.isNotEmpty && opts.isNotEmpty) {
          out.add(
            QuestionItem(
              id: id,
              question: q,
              options: opts,
              difficulty: diff,
              pdfQuestionId: pdfQuestionId,
            ),
          );
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
