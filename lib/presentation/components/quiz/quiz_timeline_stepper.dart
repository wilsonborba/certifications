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
    // Short labels for the compact stepper badge; the full descriptive
    // title (context.tr('step1Title') etc.) is shown once already, as the
    // step content's own heading below.
    final steps = [
      context.tr('step1ShortLabel'),
      context.tr('step2ShortLabel'),
      context.tr('step3ShortLabel'),
      context.tr('step4ShortLabel'),
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
                  // A thin connector: it only needs to fill whatever the
                  // step badges (flex: 8 below) don't claim, never compete
                  // with them for space on equal footing.
                  return Expanded(
                    flex: 1,
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

                return Flexible(
                  // A high flex weight relative to the connectors' flex: 1
                  // above, so each badge keeps most of its natural width
                  // (icon + label) and only the thin connector lines give
                  // up space when the row gets tight, instead of every
                  // child splitting the row into equal, too-narrow shares.
                  flex: 8,
                  child: InkWell(
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
                          Flexible(
                            child: Text(
                              steps[stepIdx],
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                color: isActive
                                    ? scheme.primary
                                    : scheme.onSurface.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 12),
          _ResetButton(isDesktop: isDesktop, onConfirmedReset: wizardData.reset),
        ],
      ),
    );
  }
}

/// Destructive "start over" control. Rendered as a clearly labeled button
/// (not a bare icon someone could miss) with a confirm dialog before it
/// actually clears the wizard back to Step 1, since the action cannot be
/// undone.
class _ResetButton extends StatelessWidget {
  const _ResetButton({required this.isDesktop, required this.onConfirmedReset});

  final bool isDesktop;
  final VoidCallback onConfirmedReset;

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('resetWizard')),
        content: Text(ctx.tr('resetWizardConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.tr('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.tr('resetWizard')),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirmedReset();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return OutlinedButton.icon(
      onPressed: () => _confirmReset(context),
      icon: const Icon(Icons.rotate_left, size: 18),
      label: isDesktop ? Text(context.tr('resetWizard')) : const SizedBox.shrink(),
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.error,
        side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 14 : 10, vertical: 10),
      ),
    );
  }
}
