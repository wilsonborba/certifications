import 'package:flutter/material.dart';

class PlansView extends StatelessWidget {
  const PlansView({
    super.key,
    required this.isDesktop,
    this.showHeader = true,
    this.onConfigureKeys,
  });

  final bool isDesktop;
  final bool showHeader;
  final VoidCallback? onConfigureKeys;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Text(
            'Plans',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Free for now — bring your own API key and you are ready to go.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withOpacity(0.65),
                ),
          ),
          const SizedBox(height: 18),
        ],
        isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _FreePlanCard(onConfigureKeys: onConfigureKeys)),
                  const SizedBox(width: 18),
                  Expanded(child: _LockedPlanCard(title: 'Plus', badge: 'Not available')),
                  const SizedBox(width: 18),
                  Expanded(child: _LockedPlanCard(title: 'Pro', badge: 'Not available')),
                ],
              )
            : Column(
                children: [
                  _FreePlanCard(onConfigureKeys: onConfigureKeys),
                  const SizedBox(height: 14),
                  _LockedPlanCard(title: 'Plus', badge: 'Not available'),
                  const SizedBox(height: 14),
                  _LockedPlanCard(title: 'Pro', badge: 'Not available'),
                ],
              ),
      ],
    );

    return Material(
      color: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: content,
      ),
    );
  }
}

class _FreePlanCard extends StatelessWidget {
  const _FreePlanCard({this.onConfigureKeys});

  final VoidCallback? onConfigureKeys;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withOpacity(0.15),
            scheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.75),
            blurRadius: 8,
            offset: const Offset(-1, -1),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlanBadge(
            label: 'Free',
            background: scheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Bring your own API key',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use your free-tier Gemini key or a Groq API key. You control usage and billing.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(icon: Icons.bolt, label: 'Unlimited certifications'),
              _InfoChip(icon: Icons.lock_open, label: 'No subscription'),
              _InfoChip(icon: Icons.settings, label: 'Self-managed keys'),
            ],
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: onConfigureKeys,
            icon: const Icon(Icons.key),
            label: const Text('Configure API keys'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedPlanCard extends StatelessWidget {
  const _LockedPlanCard({required this.title, required this.badge});

  final String title;
  final String badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlanBadge(
            label: badge,
            background: scheme.surfaceVariant,
            foreground: scheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Premium features are coming soon. Stay tuned!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withOpacity(0.65),
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _InfoChip(icon: Icons.auto_awesome, label: 'Enhanced AI'),
              _InfoChip(icon: Icons.cloud, label: 'Higher limits'),
              _InfoChip(icon: Icons.star_border, label: 'Priority support'),
            ],
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.lock_outline),
            label: const Text('Not available yet'),
          ),
        ],
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({
    required this.label,
    required this.background,
    this.foreground = Colors.white,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.surfaceVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSurface.withOpacity(0.7)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurface.withOpacity(0.8),
                ),
          ),
        ],
      ),
    );
  }
}
