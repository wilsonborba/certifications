import 'package:accredit/domain/models/topic_identifications.dart';
import 'package:accredit/presentation/components/certifications_config/form_config.dart';
import 'package:accredit/presentation/widgets/quiz/desktop_quiz.dart';
import 'package:accredit/presentation/widgets/quiz/mobile_quiz.dart';
import 'package:flutter/material.dart';
import 'package:accredit/presentation/screen_adjuster.dart';



class OnQuizScreen extends StatefulWidget {
  final CertificationFormData formData;
  final ContextInfo questionPayload;

  const OnQuizScreen({super.key, required this.questionPayload, required this.formData});

  @override
  State<OnQuizScreen> createState() => _OnQuizScreenState();

}


class _OnQuizScreenState extends State<OnQuizScreen> {
  @override
  Widget build(BuildContext context) {
     return ScreenAdjuster(
        mobileWidget: MobileQuiz(questionPayload: widget.questionPayload, formData: widget.formData),
        desktopWidget: DesktopQuiz(questionPayload: widget.questionPayload, formData: widget.formData),
      ).adjust(context);
  }
}

