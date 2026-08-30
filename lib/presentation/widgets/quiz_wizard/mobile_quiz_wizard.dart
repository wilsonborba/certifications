import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/quiz_wizard_data.dart';
import 'package:certifications/presentation/components/quiz/quiz_timeline_stepper.dart';
import 'package:certifications/presentation/widgets/quiz_wizard/quiz_wizard_steps.dart';
import 'package:flutter/material.dart';

/// Mobile layout for the quiz creation wizard: single-column stacking,
/// full-width controls, and larger touch targets, tailored for narrow
/// screens rather than the desktop card grid.
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
    final scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: wizardData,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            QuizTimelineStepper(wizardData: wizardData, isDesktop: false),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: scheme.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: scheme.outlineVariant.withOpacity(0.3),
                    ),
                  ),
                  child: _buildCurrentStepView(context),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildNavigationFooter(context),
          ],
        );
      },
    );
  }

  Widget _buildCurrentStepView(BuildContext context) {
    switch (wizardData.currentStep) {
      case 0:
        return Step1ThemeView(wizardData: wizardData, isDesktop: false);
      case 1:
        return Step2SourceView(wizardData: wizardData, isDesktop: false);
      case 2:
        return Step3FormatView(wizardData: wizardData, isDesktop: false);
      case 3:
        return Step4ReviewView(wizardData: wizardData, onGenerate: onGenerate);
      default:
        return const SizedBox.shrink();
    }
  }

  /// Full-width, stacked buttons (rather than the desktop's side-by-side
  /// row) so both targets stay comfortably tappable on narrow screens.
  Widget _buildNavigationFooter(BuildContext context) {
    return Column(
      children: [
        if (wizardData.currentStep < 3)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isCurrentStepValid ? () => wizardData.nextStep() : null,
              icon: const Icon(Icons.arrow_forward),
              label: Text(context.tr('next')),
            ),
          ),
        if (wizardData.currentStep > 0) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => wizardData.previousStep(),
              icon: const Icon(Icons.arrow_back),
              label: Text(context.tr('close')),
            ),
          ),
        ],
      ],
    );
  }

  bool get _isCurrentStepValid {
    switch (wizardData.currentStep) {
      case 0:
        return wizardData.isStep1Valid;
      case 1:
        return wizardData.isStep2Valid;
      case 2:
        return wizardData.isStep3Valid;
      default:
        return true;
    }
  }
}
