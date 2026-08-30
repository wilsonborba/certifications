import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:flutter/material.dart';

/// Prominent "resume where you left off" banner shown above the standby
/// studies list, pointing at the most recently touched draft study.
class DraftResumeHeroCard extends StatelessWidget {
  const DraftResumeHeroCard({
    super.key,
    required this.study,
    required this.isDesktop,
    required this.onResume,
  });

  final Study study;
  final bool isDesktop;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 22 : 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withOpacity(0.16),
            scheme.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary.withOpacity(0.3)),
      ),
      child: _buildContent(context, scheme),
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme scheme) {
    final infoRow = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.play_circle_fill, color: scheme.primary, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('resumeHeroTitle'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                study.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withOpacity(0.75),
                ),
              ),
              Text(
                context.tr('resumeHeroSubtitle'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final button = SizedBox(
      width: isDesktop ? null : double.infinity,
      child: ElevatedButton.icon(
        onPressed: onResume,
        icon: const Icon(Icons.arrow_forward),
        label: Text(context.tr('resumeHeroCta')),
      ),
    );

    // A single Flex that flips direction between desktop/mobile cannot give
    // infoRow's own Expanded child a bounded width in the vertical
    // (mobile) case without introducing the same "unbounded constraints"
    // crash in the other axis, so the two layouts are built explicitly
    // instead of sharing one conditional Flex.
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: infoRow),
          const SizedBox(width: 16),
          button,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [infoRow, const SizedBox(height: 14), button],
    );
  }
}
