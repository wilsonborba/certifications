// on_quiz_screen.dart
import 'package:accredit/presentation/components/quiz/quiz_controller.dart';
import 'package:flutter/material.dart';
import 'package:accredit/presentation/screen_adjuster.dart';
import 'package:accredit/domain/models/topic_identifications.dart';
import 'package:accredit/presentation/widgets/quiz/desktop_quiz.dart';
import 'package:accredit/presentation/widgets/quiz/mobile_quiz.dart';


class OnQuizScreen extends StatefulWidget {
  final CertificationFormData formData;
  final ContextInfo questionPayload;
  const OnQuizScreen({super.key, required this.questionPayload, required this.formData});

  @override
  State<OnQuizScreen> createState() => _OnQuizScreenState();
}

class _OnQuizScreenState extends State<OnQuizScreen> {
  late final QuizController controller;

  @override
  void initState() {
    super.initState();
    controller = QuizController(formData: widget.formData, payload: widget.questionPayload);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenAdjuster<Widget>(
      mobileWidget: MobileQuiz(controller: controller),
      desktopWidget: DesktopQuiz(controller: controller),
    ).adjust(context);
  }
}
