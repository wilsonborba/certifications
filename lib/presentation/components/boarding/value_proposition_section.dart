import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/core/utils/my_nagivation.dart';
import 'package:certifications/presentation/components/auth/login_redirect.dart';
import 'package:certifications/presentation/components/plans/plans_view.dart';
import 'package:flutter/material.dart';

class ValuePropositionSection extends StatelessWidget {
  const ValuePropositionSection({super.key, required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 36 : 20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('valPropTitle'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isDesktop ? 28 : 20,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('valPropSubtitle'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withOpacity(0.75),
              fontSize: isDesktop ? 16 : 13,
            ),
          ),
          const SizedBox(height: 28),
          _ValueTile(
            icon: Icons.auto_awesome,
            title: context.tr('valPropTile1Title'),
            description: context.tr('valPropTile1Desc'),
            isDesktop: isDesktop,
          ),
          const SizedBox(height: 16),
          _ValueTile(
            icon: Icons.upload_file,
            title: context.tr('valPropTile2Title'),
            description: context.tr('valPropTile2Desc'),
            isDesktop: isDesktop,
          ),
          const SizedBox(height: 16),
          _ValueTile(
            icon: Icons.touch_app,
            title: context.tr('valPropTile3Title'),
            description: context.tr('valPropTile3Desc'),
            isDesktop: isDesktop,
          ),
          const SizedBox(height: 16),
          _ValueTile(
            icon: Icons.dashboard,
            title: context.tr('valPropTile4Title'),
            description: context.tr('valPropTile4Desc'),
            isDesktop: isDesktop,
          ),
          const SizedBox(height: 16),
          _ValueTile(
            icon: Icons.emoji_events,
            title: context.tr('valPropTile5Title'),
            description: context.tr('valPropTile5Desc'),
            isDesktop: isDesktop,
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: isDesktop ? null : double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // Same sign-up flow as the boarding app bar / footer's
                    // "Sign up" action.
                    redirectToUrl(
                      await urlRedirectionToAuth(isToLogin: false),
                      replace: true,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  ),
                  child: Text(
                    context.tr('valPropCtaGetStarted'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              SizedBox(
                width: isDesktop ? null : double.infinity,
                child: OutlinedButton(
                  // Same waitlist flow used by the Guided plan card in
                  // PlansView; "Pro" maps to the first paid tier ('guided').
                  onPressed: () => handleWaitlistFlow(context, 'guided'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  ),
                  child: Text(
                    context.tr('valPropCtaJoinWaitlist'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  const _ValueTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDesktop,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: scheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isDesktop ? 16 : 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withOpacity(0.7),
                    fontSize: isDesktop ? 14 : 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
