


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
      body: Center(
        child: Text('Desktop  Quiz: ${widget.questionPayload.data} with form ${widget.formData.certificationTitle}'),
      ),
    );
  }
}