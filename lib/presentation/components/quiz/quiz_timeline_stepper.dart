import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/quiz_wizard_data.dart';
import 'package:flutter/material.dart';

class QuizTimelineStepper extends StatelessWidget {
  const QuizTimelineStepper({
    super.key,
    required this.wizardData,
    required this.isDesktop,
  });

  final QuizWizardData wizardData;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final steps = [
      context.tr('step1Title'),
      context.tr('step2Title'),
      context.tr('step3Title'),
      context.tr('step4Title'),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 12,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: List.generate(steps.length * 2 - 1, (index) {
                if (index.isOdd) {
                  final stepIdx = index ~/ 2;
                  final isPassed = wizardData.currentStep > stepIdx;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      height: isPassed ? 3 : 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isPassed
                            ? scheme.primary
                            : scheme.outlineVariant.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }

                final stepIdx = index ~/ 2;
                final isCompleted = wizardData.currentStep > stepIdx;
                final isActive = wizardData.currentStep == stepIdx;

                return InkWell(
                  onTap: () {
                    // Allow clicking on completed or current steps to navigate
                    if (isCompleted || isActive || stepIdx == wizardData.currentStep + 1) {
                      wizardData.setStep(stepIdx);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 12 : 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? scheme.primary.withOpacity(0.15)
                          : isCompleted
                              ? scheme.primary.withOpacity(0.08)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive
                            ? scheme.primary
                            : isCompleted
                                ? scheme.primary.withOpacity(0.4)
                                : scheme.outlineVariant.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          width: isDesktop ? 26 : 22,
                          height: isDesktop ? 26 : 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? scheme.primary
                                : isCompleted
                                    ? scheme.primary.withOpacity(0.2)
                                    : scheme.surfaceVariant,
                          ),
                          child: Center(
                            child: isCompleted
                                ? Icon(
                                    Icons.check,
                                    size: isDesktop ? 16 : 14,
                                    color: scheme.primary,
                                  )
                                : Text(
                                    '${stepIdx + 1}',
                                    style: TextStyle(
                                      color: isActive
                                          ? scheme.onPrimary
                                          : scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isDesktop ? 13 : 11,
                                    ),
                                  ),
                          ),
                        ),
                        if (isDesktop) ...[
                          const SizedBox(width: 8),
                          Text(
                            steps[stepIdx],
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                              color: isActive
                                  ? scheme.primary
                                  : scheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 12),
          Tooltip(
            message: context.tr('resetWizard'),
            child: IconButton(
              icon: const Icon(Icons.rotate_left),
              color: scheme.onSurface.withOpacity(0.7),
              onPressed: () => wizardData.reset(),
            ),
          ),
        ],
      ),
    );
  }
}
