// widgets/quiz/desktop_quiz.dart
import 'package:accredit/presentation/components/quiz/quiz_controller.dart';
import 'package:flutter/material.dart';

import 'package:accredit/presentation/components/quiz/big_appbar.dart';
import 'package:accredit/presentation/components/quiz/quiz_cards.dart';

class DesktopQuiz extends StatefulWidget {
  final QuizController controller;
  const DesktopQuiz({super.key, required this.controller});

  @override
  State<DesktopQuiz> createState() => _DesktopQuizState();
}

class _DesktopQuizState extends State<DesktopQuiz> {
  QuizController get c => widget.controller;

  Future<bool?> _confirmFinish(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Finish quiz?'),
        content: const Text('Are you sure you want to submit your answers?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C4DFF)),
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
        remainingSecondsListenable: c.remainingSeconds, // same controller
        height: 110,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              const SizedBox(height: 14),
              Expanded(
                child: Scrollbar(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: c.questions.length,
                    itemBuilder: (_, i) {
                      final q = c.questions[i];
                      return QuestionCard(
                        index: i + 1,
                        item: q,
                        selectedIndex: c.selections[i],
                        onChanged: (val) {
                          c.setSelection(i, val);
                          setState(() {}); // local rebuild of this view only
                        },
                        onComplain: () => showComplaintDialog(context, questionIndex: i + 1),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SafeArea(
                top: false,
                child: Row(
                  children: [
                    const Spacer(),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.flag_circle_rounded),
                      label: const Text('Finish', style: TextStyle(fontWeight: FontWeight.w800)),
                      onPressed: () async {
                        final ok = await _confirmFinish(context);
                        if (ok == true) c.finish();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C4DFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
