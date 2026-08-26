import 'package:flutter/material.dart';
import 'package:certifications/domain/services/waitlist_api_service.dart';

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
            'Free during the MVP — start a focused study with managed local capacity.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 18),
        ],
        _FreePlanCard(onConfigureKeys: onConfigureKeys),
      ],
    );

    return Material(
      color: scheme.surface,
      child: Padding(padding: const EdgeInsets.all(16), child: content),
    );
  }
}

class _FreePlanCard extends StatefulWidget {
  const _FreePlanCard({this.onConfigureKeys});

  final VoidCallback? onConfigureKeys;

  @override
  State<_FreePlanCard> createState() => _FreePlanCardState();
}

class _FreePlanCardState extends State<_FreePlanCard> {
  final _waitlist = WaitlistApiService();
  bool _hovered = false;
  bool _submitting = false;
  bool _joined = false;
  String? _message;

  Future<void> _join() async {
    setState(() => _submitting = true);
    try {
      final alreadyJoined = await _waitlist.joinFreePlanWaitlist();
      if (!mounted) return;
      setState(() {
        _joined = true;
        _message = alreadyJoined
            ? 'You are already on the waitlist.'
            : 'You are on the waitlist.';
      });
    } on WaitlistApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 401 && widget.onConfigureKeys != null) {
        widget.onConfigureKeys!();
        return;
      }
      setState(
        () => _message = 'We could not record your request. Please try again.',
      );
    } catch (_) {
      if (mounted)
        setState(
          () =>
              _message = 'We could not record your request. Please try again.',
        );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.surfaceContainerHighest, scheme.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: scheme.outline.withValues(alpha: _hovered ? .72 : .36),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.onSurface.withValues(alpha: _hovered ? .12 : .06),
              blurRadius: _hovered ? 32 : 18,
              offset: Offset(0, _hovered ? 16 : 10),
            ),
            BoxShadow(
              color: scheme.surface.withValues(alpha: .75),
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
              label: 'FREE · MVP',
              background: scheme.primary,
              foreground: scheme.onPrimary,
            ),
            const SizedBox(height: 12),
            Text(
              'Study without configuration',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a study from your material, generate questions, and finish with a shareable certification. No API key or token configuration is required.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: .7),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.memory_outlined,
                  label: 'Tier 0 · default local capacity',
                ),
                _InfoChip(
                  icon: Icons.auto_awesome_outlined,
                  label: 'Tiers 1–2 · small guided allowance',
                ),
                _InfoChip(
                  icon: Icons.lock_outline,
                  label: 'Tiers 3–5 · limited trial capacity',
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: null,
                  icon: Icon(Icons.lock_outline),
                  label: Text('Select plan'),
                ),
                ElevatedButton.icon(
                  onPressed: _submitting || _joined ? null : _join,
                  icon: _submitting
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimary,
                          ),
                        )
                      : Icon(_joined ? Icons.check : Icons.notifications_none),
                  label: Text(
                    _joined ? 'On the waitlist' : 'Join the waitlist',
                  ),
                ),
              ],
            ),
            if (_message != null) ...[
              const SizedBox(height: 14),
              Text(
                _message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: .72),
                ),
              ),
            ],
          ],
        ),
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
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
