

import 'package:accredit/domain/models/topic_identifications.dart';
import 'package:accredit/presentation/components/certifications_config/form_config.dart';
import 'package:flutter/material.dart';

abstract class BaseQuiz extends StatefulWidget {
  final CertificationFormData formData;
  final ContextInfo questionPayload;
  BaseQuiz({super.key, required this.questionPayload, required this.formData});
  
}


abstract class BaseQuizState<T extends BaseQuiz> extends State<T> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('No implementation for BaseQuiz'),
      ),
    );
  }
}