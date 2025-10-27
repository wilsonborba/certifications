// widgets/quiz/desktop_quiz.dart
import 'package:accredit/presentation/components/quiz/big_appbar.dart';
import 'package:accredit/presentation/components/quiz/quiz_cards.dart';
import 'package:accredit/presentation/widgets/quiz/base_quiz.dart';
import 'package:flutter/material.dart';


class DesktopQuiz extends BaseQuiz {
  DesktopQuiz({super.key, required super.questionPayload, required super.formData});
  @override
  State<DesktopQuiz> createState() => _DesktopQuizState();
}

class _DesktopQuizState extends BaseQuizState<DesktopQuiz> {
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: QuizAppBar(
        title: widget.formData.certificationTitle,
        subtitle: "Quiz made for ${widget.formData.fullName}",
        remainingSecondsListenable: remainingSeconds,
        height: 110,
      ),
      body: LayoutBuilder(
        builder: (_, cons) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  Expanded(
                    child: Scrollbar(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
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
                  ),
                  const SizedBox(height: 6),
                  _FinishBar(
                    onFinishTap: () async {
                      final confirmed = await _confirmFinish(context);
                      if (confirmed == true) {
                        onFinishPressed();
                      }
                    },
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          );
        },
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C4DFF)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }
}

class _FinishBar extends StatelessWidget {
  final VoidCallback onFinishTap;
  const _FinishBar({required this.onFinishTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Row(
        children: [
          const Spacer(),
          ElevatedButton.icon(
            icon: const Icon(Icons.flag_circle_rounded),
            label: const Text(
              'Finish',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            onPressed: onFinishTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C4DFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
