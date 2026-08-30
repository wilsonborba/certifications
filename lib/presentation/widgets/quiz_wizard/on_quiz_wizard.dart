import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/quiz_wizard_data.dart';
import 'package:certifications/domain/services/draft_progress_store.dart';
import 'package:certifications/presentation/components/attachment/app_bar.dart';
import 'package:certifications/presentation/widgets/quiz_wizard/desktop_quiz_wizard.dart';
import 'package:certifications/presentation/widgets/quiz_wizard/mobile_quiz_wizard.dart';
import 'package:flutter/material.dart';

class OnQuizWizardScreen extends StatefulWidget {
  const OnQuizWizardScreen({
    super.key,
    required this.onGenerate,
    this.studyId,
    this.initialName,
    this.initialStep = 0,
  });

  final VoidCallback onGenerate;

  /// The draft study being resumed, if any. When set, the wizard's current
  /// step is persisted against this id via [DraftProgressStore] as the user
  /// navigates, so a later "Resume" lands back on the same step.
  final String? studyId;

  /// Pre-fills the topic step, e.g. when resuming a draft study.
  final String? initialName;

  /// Wizard step (0-3) to land on when opened, e.g. the step a draft study
  /// was left on.
  final int initialStep;

  @override
  State<OnQuizWizardScreen> createState() => _OnQuizWizardScreenState();
}

class _OnQuizWizardScreenState extends State<OnQuizWizardScreen> {
  late final wizardData = QuizWizardData()
    ..name = widget.initialName ?? ''
    ..currentStep = widget.initialStep.clamp(0, 3);

  @override
  void initState() {
    super.initState();
    if (widget.studyId != null) {
      wizardData.addListener(_persistDraftState);
    }
  }

  void _persistDraftState() {
    final studyId = widget.studyId;
    if (studyId != null) {
      DraftProgressStore.instance.saveStep(studyId, wizardData.currentStep);
      DraftProgressStore.instance.saveVisibility(studyId, wizardData.visibility);
    }
  }

  @override
  void dispose() {
    wizardData.removeListener(_persistDraftState);
    wizardData.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 768;

    return Scaffold(
      appBar: AttachmentAppBar(title: context.tr('wizardTitle')),
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
