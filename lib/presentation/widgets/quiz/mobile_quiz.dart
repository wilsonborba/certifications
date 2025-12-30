// widgets/quiz/mobile_quiz.dart
import 'dart:convert';

import 'package:accredit/core/utils/my_nagivation.dart';
import 'package:accredit/presentation/components/quiz/quiz_controller.dart';
import 'package:accredit/presentation/widgets/accredit/on_accredit.dart';
import 'package:flutter/material.dart';

import 'package:accredit/presentation/components/quiz/big_appbar.dart';
import 'package:accredit/presentation/components/quiz/quiz_cards.dart';

import 'package:http/http.dart' show Response;

class MobileQuiz extends StatefulWidget {
  final QuizController controller;
  const MobileQuiz({super.key, required this.controller});

  @override
  State<MobileQuiz> createState() => _MobileQuizState();
}

class _MobileQuizState extends State<MobileQuiz> {
  QuizController get c => widget.controller;

  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  String? extractCertificationIdFromResponse(Response res) {
    try {
      final decoded = jsonDecode(res.body);

      if (decoded is! Map<String, dynamic>) return null;
      final data = decoded['data'];
      if (data is! Map<String, dynamic>) return null;

      final id = data['certification_id']?.toString().trim();
      if (id == null || id.isEmpty) return null;

      return id;
    } catch (_) {
      return null;
    }
  }

  void showQuizSubmitSnack(
    BuildContext context, {
    required String message,
    bool isError = true,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        duration: Duration(seconds: isError ? 4 : 2),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  Future<bool?> _confirmFinish(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Finish quiz?'),
        content: const Text('Are you sure you want to submit your answers?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C4DFF),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: QuizAppBar(
        title: c.formData.certificationTitle,
        subtitle: "Quiz made for ${c.formData.fullName}",
        remainingSecondsListenable: c.remainingSeconds,
        height: 90,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: c.questions.length,
              itemBuilder: (_, i) {
                final q = c.questions[i];
                return QuestionCard(
                  index: i + 1,
                  item: q,
                  selectedIndex: c.selections[i],
                  onChanged: (val) {
                    c.setSelection(i, val);
                    setState(() {});
                  },
                  onComplain: () => showComplaintDialog(
                    context,
                    questionIndex: i + 1,
                    questionId: q.id,
                    isForPDF: widget.controller.isForPDF,
                    contextId: widget.controller.contextId,
                    pdfQuestionId: q.pdfQuestionId,
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.flag_circle_rounded),
                label: const Text(
                  'Finish',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                onPressed: () async {
                  final ok = await _confirmFinish(context);
                  if (ok != true) return;

                  // Optional: immediate UI feedback
                  showQuizSubmitSnack(
                    context,
                    message: 'Submitting your answers…',
                    isError: false,
                  );

                  final Response? res = await c.finish();

                  if (!context.mounted) return;

                  if (res == null) {
                    showQuizSubmitSnack(
                      context,
                      message:
                          'Submission failed. Please check your connection and try again.',
                    );
                    return;
                  }

                  if (res.statusCode < 200 || res.statusCode >= 300) {
                    showQuizSubmitSnack(
                      context,
                      message:
                          'Submission failed (HTTP ${res.statusCode}). Please try again.',
                    );
                    return;
                  }

                  final certificationId = extractCertificationIdFromResponse(
                    res,
                  );
                  if (certificationId == null) {
                    showQuizSubmitSnack(
                      context,
                      message:
                          'Submission succeeded, but the server did not return a certification ID. Please contact support.',
                    );
                    return;
                  }

                  // Optional: success message
                  showQuizSubmitSnack(
                    context,
                    message: 'Submitted successfully. Redirecting…',
                    isError: false,
                  );

                  NavigationService.push(
                    OnAccreditScreen(certificationId: certificationId),
                  );
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C4DFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
