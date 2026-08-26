import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/services/waitlist_api_service.dart';
import 'package:flutter/material.dart';

class PlansView extends StatelessWidget {
  const PlansView({super.key, required this.isDesktop, this.showHeader = true});

  final bool isDesktop;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cards = <Widget>[
      const _FreePlanCard(),
      _PlaceholderPlanCard(
        title: context.tr('planGuided'),
        body: context.tr('planGuidedBody'),
      ),
      _PlaceholderPlanCard(
        title: context.tr('planAdvanced'),
        body: context.tr('planAdvancedBody'),
      ),
    ];
    return Material(
      color: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              Text(
                context.tr('plans'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('plansIntro'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: .65),
                ),
              ),
              const SizedBox(height: 18),
            ],
            isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: cards
                        .map(
                          (card) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: card,
                            ),
                          ),
                        )
                        .toList(),
                  )
                : Column(
                    children: cards
                        .map(
                          (card) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: card,
                          ),
                        )
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }
}

class _FreePlanCard extends StatefulWidget {
  const _FreePlanCard();

  @override
  State<_FreePlanCard> createState() => _FreePlanCardState();
}

class _FreePlanCardState extends State<_FreePlanCard> {
  bool _hovered = false;
  bool _joined = false;
  String? _message;

  Future<void> _openWaitlist() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (_) => const _WaitlistDialog(),
    );
    if (!mounted || accepted != true) return;
    setState(() {
      _joined = true;
      _message = context.tr('waitlistSuccess');
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _PlanShell(
      hovered: _hovered,
      onEnter: () => setState(() => _hovered = true),
      onExit: () => setState(() => _hovered = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlanBadge(
            label: context.tr('planFree'),
            background: scheme.primary,
            foreground: scheme.onPrimary,
          ),
          const SizedBox(height: 14),
          Text(
            context.tr('planStudyTitle'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('planStudyBody'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: .72),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.memory_outlined,
                label: context.tr('tier0Capacity'),
              ),
              _InfoChip(
                icon: Icons.auto_awesome_outlined,
                label: context.tr('tier12Allowance'),
              ),
              _InfoChip(
                icon: Icons.lock_outline,
                label: context.tr('tier35Trial'),
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
                icon: const Icon(Icons.lock_outline),
                label: Text(context.tr('selectPlan')),
              ),
              ElevatedButton.icon(
                onPressed: _joined ? null : _openWaitlist,
                icon: Icon(
                  _joined
                      ? Icons.check_rounded
                      : Icons.notifications_none_rounded,
                ),
                label: Text(context.tr('joinWaitlist')),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _message == null
                ? const SizedBox(height: 0)
                : Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      _message!,
                      key: ValueKey(_message),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: .72),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderPlanCard extends StatelessWidget {
  const _PlaceholderPlanCard({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _PlanShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlanBadge(
            label: context.tr('planComingSoon'),
            background: scheme.surfaceContainerHighest,
            foreground: scheme.onSurface,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: .7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('planUnavailable'),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: scheme.onSurface.withValues(alpha: .6),
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.lock_outline),
            label: Text(context.tr('selectPlan')),
          ),
        ],
      ),
    );
  }
}

class _PlanShell extends StatelessWidget {
  const _PlanShell({
    required this.child,
    this.hovered = false,
    this.onEnter,
    this.onExit,
  });
  final Widget child;
  final bool hovered;
  final VoidCallback? onEnter;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: onEnter == null ? null : (_) => onEnter!(),
      onExit: onExit == null ? null : (_) => onExit!(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.surfaceContainerHighest, scheme.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: scheme.outline.withValues(alpha: hovered ? .72 : .36),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.onSurface.withValues(alpha: hovered ? .12 : .06),
              blurRadius: hovered ? 32 : 18,
              offset: Offset(0, hovered ? 16 : 10),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _WaitlistDialog extends StatefulWidget {
  const _WaitlistDialog();

  @override
  State<_WaitlistDialog> createState() => _WaitlistDialogState();
}

class _WaitlistDialogState extends State<_WaitlistDialog> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _waitlist = WaitlistApiService();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _waitlist.joinFreePlanWaitlist(email: _email.text);
      if (mounted) Navigator.of(context).pop(true);
    } on WaitlistApiException {
      if (mounted) setState(() => _error = context.tr('waitlistFailure'));
    } catch (_) {
      if (mounted) setState(() => _error = context.tr('waitlistFailure'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      backgroundColor: scheme.surface,
      title: Text(context.tr('waitlistTitle')),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('waitlistBody')),
              const SizedBox(height: 18),
              TextFormField(
                controller: _email,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submitting ? null : _submit(),
                decoration: InputDecoration(
                  labelText: context.tr('email'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                      ? null
                      : context.tr('emailInvalid');
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: scheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(context.tr('cancel')),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.onPrimary,
                  ),
                )
              : Text(context.tr('submit')),
        ),
      ],
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: foreground,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
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
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSurface.withValues(alpha: .7)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              softWrap: true,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: .8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
