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

  // Use one ScrollController for both ListView and Scrollbar.
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

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
        remainingSecondsListenable: c.remainingSeconds,
        height: 110,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              const SizedBox(height: 14),
              Expanded(
                // Guarded Scrollbar to avoid "no ScrollPosition attached" on web hover
                child: _AttachedScrollbar(
                  controller: _scrollCtrl,
                  child: ListView.builder(
                    controller: _scrollCtrl, // <-- same controller
                    primary: false,          // <-- since a controller is provided
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
                          setState(() {}); // local rebuild for selection change
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

/// Renders a Scrollbar only when the controller is attached to a ScrollPosition.
/// This avoids the assertion on web when hovering before the first frame attaches.
class _AttachedScrollbar extends StatefulWidget {
  final ScrollController controller;
  final Widget child;
  const _AttachedScrollbar({required this.controller, required this.child});

  @override
  State<_AttachedScrollbar> createState() => _AttachedScrollbarState();
}

class _AttachedScrollbarState extends State<_AttachedScrollbar> {
  VoidCallback? _listener;

  @override
  void initState() {
    super.initState();
    _listener = () {
      if (mounted) setState(() {});
    };
    widget.controller.addListener(_listener!);
  }

  @override
  void didUpdateWidget(covariant _AttachedScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (_listener != null) {
        oldWidget.controller.removeListener(_listener!);
      }
      widget.controller.addListener(_listener!);
    }
  }

  @override
  void dispose() {
    if (_listener != null) {
      widget.controller.removeListener(_listener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasClients = widget.controller.hasClients;
    // If nothing is attached (yet), skip Scrollbar to prevent the assertion.
    return hasClients
        ? Scrollbar(controller: widget.controller, child: widget.child)
        : widget.child;
  }
}
