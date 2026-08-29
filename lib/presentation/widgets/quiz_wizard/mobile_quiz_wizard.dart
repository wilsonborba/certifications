import 'package:certifications/presentation/widgets/quiz_wizard/desktop_quiz_wizard.dart';
import 'package:flutter/material.dart';
import 'package:certifications/domain/models/quiz_wizard_data.dart';

class MobileQuizWizard extends StatelessWidget {
  const MobileQuizWizard({
    super.key,
    required this.wizardData,
    required this.onGenerate,
  });

  final QuizWizardData wizardData;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    // Reuses DesktopQuizWizard responsive views wrapped with single-column mobile padding
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      child: DesktopQuizWizard(
        wizardData: wizardData,
        onGenerate: onGenerate,
      ),
    );
  }
}
