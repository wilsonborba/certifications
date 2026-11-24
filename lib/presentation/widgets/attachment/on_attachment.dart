import 'package:certifications/presentation/widgets/study_dashboard/on_study_dashboard.dart';
import 'package:certifications/presentation/widgets/quiz_wizard/on_quiz_wizard.dart';
import 'package:flutter/material.dart';

/// Document-only entry point. Non-document source cards are intentionally absent.
class OnAttachmentScreen extends StatelessWidget {
  const OnAttachmentScreen({super.key, this.preparedStudyId});

  final String? preparedStudyId;

  @override
  Widget build(BuildContext context) {
    final studyId = preparedStudyId;
    if (studyId != null && studyId.isNotEmpty) {
      return OnQuizWizardScreen(studyId: studyId, onGenerate: () {});
    }
    return const OnStudyDashboardScreen();
  }
}
