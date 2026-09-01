import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/quiz_wizard_data.dart';
import 'package:certifications/presentation/components/quiz/quiz_timeline_stepper.dart';
import 'package:certifications/presentation/widgets/quiz_wizard/quiz_wizard_steps.dart';
import 'package:flutter/material.dart';

class DesktopQuizWizard extends StatelessWidget {
  const DesktopQuizWizard({
    super.key,
    required this.wizardData,
    required this.onGenerate,
    this.generateError,
  });

  final QuizWizardData wizardData;
  final VoidCallback onGenerate;

  /// When set, an error message is shown above the generate button in Step 4.
  final String? generateError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: AnimatedBuilder(
          animation: wizardData,
          builder: (context, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                QuizTimelineStepper(wizardData: wizardData, isDesktop: true),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: scheme.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: scheme.outlineVariant.withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _buildCurrentStepView(context),
                  ),
                ),
                const SizedBox(height: 20),
                _buildNavigationFooter(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrentStepView(BuildContext context) {
    switch (wizardData.currentStep) {
      case 0:
        return Step1ThemeView(wizardData: wizardData, isDesktop: true);
      case 1:
        return Step2SourceView(wizardData: wizardData, isDesktop: true);
      case 2:
        return Step3FormatView(wizardData: wizardData, isDesktop: true);
      case 3:
        return Step4ReviewView(
          wizardData: wizardData,
          onGenerate: onGenerate,
          generateError: generateError,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavigationFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (wizardData.currentStep > 0)
          OutlinedButton.icon(
            onPressed: () => wizardData.previousStep(),
            icon: const Icon(Icons.arrow_back),
            label: Text(context.tr('close')),
          )
        else
          const SizedBox.shrink(),
        if (wizardData.currentStep < 3)
          ElevatedButton.icon(
            onPressed: _isCurrentStepValid
                ? () => wizardData.nextStep()
                : null,
            icon: const Icon(Icons.arrow_forward),
            label: Text(context.tr('next')),
          ),
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
