


import 'package:accredit/presentation/widgets/quiz/base_quiz.dart';
import 'package:flutter/material.dart';

class MobileQuiz extends BaseQuiz {
  MobileQuiz({super.key, required super.questionPayload, required super.formData});
  @override
  State<MobileQuiz> createState() => _MobileQuizState();
}

class _MobileQuizState extends BaseQuizState<MobileQuiz> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Mobile Quiz: ${widget.questionPayload.data} with form ${widget.formData.certificationTitle}'),
      ),
    );
  }
}