// widgets/quiz/mobile_quiz.dart
import 'package:accredit/presentation/components/quiz/big_appbar.dart';
import 'package:accredit/presentation/components/quiz/quiz_cards.dart';
import 'package:flutter/material.dart';
import 'base_quiz.dart';


class MobileQuiz extends BaseQuiz {
  MobileQuiz({super.key, required super.questionPayload, required super.formData});
  @override
  State<MobileQuiz> createState() => _MobileQuizState();
}

class _MobileQuizState extends BaseQuizState<MobileQuiz> {
  @override
  Widget build(BuildContext context) {
    

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: QuizAppBar(
        title: widget.formData.certificationTitle,
        subtitle: "Quiz made for ${widget.formData.fullName}",
        remainingSecondsListenable: remainingSeconds,
        height: 90,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: questions.length,
              itemBuilder: (_, i) {
                final q = questions[i];
                return QuestionCard(
                  index: i + 1,
                  item: q,
                  selectedIndex: selections[i],
                  onChanged: (val) => setState(() => selections[i] = val),
                  onComplain: () => showComplaintDialog(context, questionIndex: i + 1),
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
                label: const Text('Finish', style: TextStyle(fontWeight: FontWeight.w800)),
                onPressed: () async {
                  final ok = await showDialog<bool>(
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
                  if (ok == true) onFinishPressed();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C4DFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
