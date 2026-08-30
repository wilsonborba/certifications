import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/core/utils/my_nagivation.dart';
import 'package:certifications/domain/services/waitlist_store.dart';
import 'package:certifications/presentation/components/auth/login_redirect.dart';
import 'package:certifications/presentation/components/auth/verify_session.dart';
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
      const _GuidedPlanCard(),
      const _AdvancedPlanCard(),
    ];
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              Text(
                context.tr('plans'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('plansIntro'),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurface.withValues(alpha: .72),
                ),
              ),
              const SizedBox(height: 24),
            ],
            isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: cards
                        .map(
                          (card) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
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
                            padding: const EdgeInsets.only(bottom: 16),
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

/// Free Plan Card (Current Plan)
class _FreePlanCard extends StatefulWidget {
  const _FreePlanCard();

  @override
  State<_FreePlanCard> createState() => _FreePlanCardState();
}

class _FreePlanCardState extends State<_FreePlanCard> {
  bool _hovered = false;

  Future<void> _handleUse() async {
    redirectToUrl(await urlRedirectionToAuth(), replace: true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLoggedIn = readCsrfToken() != null && readCsrfToken()!.isNotEmpty;

    return _PlanShell(
      hovered: _hovered,
      accentColor: scheme.primary,
      onEnter: () => setState(() => _hovered = true),
      onExit: () => setState(() => _hovered = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PlanBadge(
                label: context.tr('planFree'),
                background: scheme.primaryContainer,
                foreground: scheme.onPrimaryContainer,
              ),
              if (isLoggedIn)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.primary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 14, color: scheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        context.tr('currentPlan'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    context.tr('planFreeTag'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('planStudyTitle'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('planStudyBody'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: .75),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: isLoggedIn
                ? OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(context.tr('activePlan')),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: scheme.primary.withValues(alpha: 0.5)),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _handleUse,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(context.tr('usePlan')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Guided Plan Card
class _GuidedPlanCard extends StatefulWidget {
  const _GuidedPlanCard();

  @override
  State<_GuidedPlanCard> createState() => _GuidedPlanCardState();
}

class _GuidedPlanCardState extends State<_GuidedPlanCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final store = WaitlistStore.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final joined = store.isJoined('guided');

        return _PlanShell(
          hovered: _hovered,
          accentColor: Colors.blueAccent,
          onEnter: () => setState(() => _hovered = true),
          onExit: () => setState(() => _hovered = false),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PlanBadge(
                label: context.tr('planGuided'),
                background: Colors.blueAccent.withValues(alpha: 0.18),
                foreground: Colors.blueAccent,
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('planGuided'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('planGuidedBody'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: .75),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.language_outlined,
                    label: context.tr('chipWebSearch'),
                  ),
                  _InfoChip(
                    icon: Icons.picture_as_pdf_outlined,
                    label: context.tr('chipPdfSupport'),
                  ),
                  _InfoChip(
                    icon: Icons.speed_outlined,
                    label: context.tr('chipPriorityQueue'),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: joined
                    ? FilledButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.check_circle_rounded),
                        label: Text(context.tr('waitlistJoined')),
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.primaryContainer,
                          foregroundColor: scheme.onPrimaryContainer,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () => handleWaitlistFlow(context, 'guided'),
                        icon: const Icon(Icons.notifications_active_outlined),
                        label: Text(context.tr('joinWaitlist')),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Advanced Plan Card
class _AdvancedPlanCard extends StatefulWidget {
  const _AdvancedPlanCard();

  @override
  State<_AdvancedPlanCard> createState() => _AdvancedPlanCardState();
}

class _AdvancedPlanCardState extends State<_AdvancedPlanCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final store = WaitlistStore.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final joined = store.isJoined('advanced');

        return _PlanShell(
          hovered: _hovered,
          accentColor: Colors.deepPurpleAccent,
          onEnter: () => setState(() => _hovered = true),
          onExit: () => setState(() => _hovered = false),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PlanBadge(
                label: context.tr('planAdvanced'),
                background: Colors.deepPurpleAccent.withValues(alpha: 0.18),
                foreground: Colors.deepPurpleAccent,
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('planAdvanced'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('planAdvancedBody'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: .75),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.play_circle_outline_rounded,
                    label: context.tr('chipYoutubeQuizzes'),
                  ),
                  _InfoChip(
                    icon: Icons.layers_outlined,
                    label: context.tr('chipMultiPdf'),
                  ),
                  _InfoChip(
                    icon: Icons.tune_outlined,
                    label: context.tr('chipCustomPrompts'),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: joined
                    ? FilledButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.check_circle_rounded),
                        label: Text(context.tr('waitlistJoined')),
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.primaryContainer,
                          foregroundColor: scheme.onPrimaryContainer,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () => handleWaitlistFlow(context, 'advanced'),
                        icon: const Icon(Icons.notifications_active_outlined),
                        label: Text(context.tr('joinWaitlist')),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Joins [planId]'s waitlist: reuses the saved/authenticated email when
/// available, otherwise prompts for one. Shared with [ValuePropositionSection]
/// so the landing page's waitlist CTA follows the exact same flow.
Future<void> handleWaitlistFlow(BuildContext context, String planId) async {
  final store = WaitlistStore.instance;
  final isLoggedIn = readCsrfToken() != null && readCsrfToken()!.isNotEmpty;

  if (isLoggedIn || (store.savedEmail != null && store.savedEmail!.isNotEmpty)) {
    final email = store.savedEmail ?? 'authenticated_user';
    await store.joinWaitlist(planId, email);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('waitlistSuccess')),
          duration: const Duration(seconds: 3),
        ),
      );
    }
    return;
  }

  final email = await showDialog<String>(
    context: context,
    builder: (_) => const _WaitlistDialog(),
  );

  if (email != null && email.isNotEmpty) {
    await store.joinWaitlist(planId, email);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('waitlistSuccess')),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

class _PlanShell extends StatelessWidget {
  const _PlanShell({
    required this.child,
    this.hovered = false,
    this.accentColor,
    this.onEnter,
    this.onExit,
  });
  final Widget child;
  final bool hovered;
  final Color? accentColor;
  final VoidCallback? onEnter;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = accentColor ?? scheme.primary;

    return MouseRegion(
      onEnter: onEnter == null ? null : (_) => onEnter!(),
      onExit: onExit == null ? null : (_) => onExit!(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: hovered ? accent : scheme.outline.withValues(alpha: 0.25),
            width: hovered ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: (hovered ? accent : scheme.onSurface).withValues(alpha: hovered ? 0.15 : 0.04),
              blurRadius: hovered ? 28 : 14,
              offset: Offset(0, hovered ? 12 : 6),
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
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: WaitlistStore.instance.savedEmail ?? '');
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(_email.text.trim());
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
                onFieldSubmitted: (_) => _submit(),
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('cancel')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(context.tr('submit')),
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
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              softWrap: true,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: .85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
