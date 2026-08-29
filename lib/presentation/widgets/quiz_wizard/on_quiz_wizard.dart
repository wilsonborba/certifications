import 'package:certifications/domain/models/quiz_wizard_data.dart';
import 'package:certifications/presentation/components/attachment/app_bar.dart';
import 'package:certifications/presentation/widgets/quiz_wizard/desktop_quiz_wizard.dart';
import 'package:certifications/presentation/widgets/quiz_wizard/mobile_quiz_wizard.dart';
import 'package:flutter/material.dart';

class OnQuizWizardScreen extends StatefulWidget {
  const OnQuizWizardScreen({super.key, required this.onGenerate});
  final VoidCallback onGenerate;

  @override
  State<OnQuizWizardScreen> createState() => _OnQuizWizardScreenState();
}

class _OnQuizWizardScreenState extends State<OnQuizWizardScreen> {
  final wizardData = QuizWizardData();

  @override
  void dispose() {
    wizardData.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 768;

    return Scaffold(
      appBar: const AttachmentAppBar(title: 'Criar Novo Quiz'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isDesktop
              ? DesktopQuizWizard(
                  wizardData: wizardData,
                  onGenerate: widget.onGenerate,
                )
              : MobileQuizWizard(
                  wizardData: wizardData,
                  onGenerate: widget.onGenerate,
                ),
        ),
      ),
    );
  }
}
