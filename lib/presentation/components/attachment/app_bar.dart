import 'package:certifications/core/settings.dart';
import 'package:certifications/core/utils/my_logs.dart';
import 'package:certifications/core/utils/my_nagivation.dart';
import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/core/utils/app_preferences.dart';

import 'package:certifications/presentation/components/auth/login_redirect.dart';
import 'package:certifications/presentation/components/preferences/app_preferences_controls.dart';
import 'package:certifications/presentation/widgets/certificates/on_certificates.dart';
import 'package:certifications/presentation/widgets/plans/on_plans.dart';
import 'package:certifications/presentation/widgets/support/on_support.dart';
import 'package:certifications/presentation/components/auth/session_gate.dart';
import 'package:flutter/material.dart';

const double _appBarHeight = 80;

/// ===== AppBar ===============================================================

class AttachmentAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AttachmentAppBar({
    super.key,
    this.title = 'Certifications',
    this.maxActionLayoutWidth = 800,
    this.currentTab = 'studies',
    this.onCertificates,
    this.onPlans,
    this.onSupport,
    this.onAbout,
    this.onLogout, // if null, a safe default logout (clear + redirect) is used
  });

  final String title;
  final double maxActionLayoutWidth;
  final String? currentTab;

  /// Opens the Certificates tab. Defaults to pushing [OnCertificatesScreen]
  /// when not overridden, so the nav item is never silently disabled.
  final VoidCallback? onCertificates;
  final VoidCallback? onPlans;
  final VoidCallback? onSupport;
  final VoidCallback? onAbout;
  final Future<void> Function()? onLogout;

  @override
  Size get preferredSize => const Size.fromHeight(_appBarHeight);

  Color _accentOf(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  @override
  Widget build(BuildContext context) {
    final accent = _accentOf(context);

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final wide = MediaQuery.sizeOf(ctx).width >= maxActionLayoutWidth;

        return AppBar(
          automaticallyImplyLeading: false, // no back arrow
          centerTitle: false,
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          surfaceTintColor: Theme.of(context).colorScheme.surface,
          scrolledUnderElevation: 0,
          toolbarHeight: _appBarHeight,
          titleSpacing: 16,
          title: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              NavigationService.pushReplacement(const SessionGate());
            },
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          actions: [
            if (wide)
              _AttachmentDesktopActions(
                accent: accent,
                currentTab: currentTab,
                onCertificates: onCertificates,
                onPlans: onPlans,
                onSupport: onSupport,
                onAbout: onAbout,
                onLogout: onLogout ?? defaultLogout,
              )
            else
              Builder(
                builder: (context) => IconButton(
                  tooltip: context.tr('menu'),
                  icon: Icon(
                    Icons.menu,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  iconSize: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onPressed: () => Scaffold.maybeOf(context)?.openEndDrawer(),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _InlineDesktopPreferences extends StatelessWidget {
  const _InlineDesktopPreferences();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final preferences = AppPreferencesScope.maybeOf(context);
    if (preferences == null) return const SizedBox.shrink();

    final isDark = preferences.themeMode == ThemeMode.dark;
    final currentLocale = preferences.locale?.languageCode ?? 'en';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: context.tr('darkTheme'),
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            color: scheme.onSurface.withValues(alpha: 0.85),
          ),
          onPressed: () {
            preferences.setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
          },
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: scheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LangChip(
                label: 'EN',
                selected: currentLocale == 'en',
                onTap: () => preferences.setLocale(const Locale('en')),
              ),
              _LangChip(
                label: 'PT',
                selected: currentLocale == 'pt',
                onTap: () => preferences.setLocale(const Locale('pt')),
              ),
              _LangChip(
                label: 'TH',
                selected: currentLocale == 'th',
                onTap: () => preferences.setLocale(const Locale('th')),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? scheme.onPrimary : scheme.onSurface.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}

class _UserProfileButton extends StatelessWidget {
  const _UserProfileButton({this.onLogout});
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      tooltip: context.tr('profile'),
      icon: Icon(
        Icons.account_circle_outlined,
        color: scheme.onSurface,
        size: 32,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, color: scheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 12),
              Text(
                context.tr('profile'),
                style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          onTap: () {
            if (onLogout != null) {
              onLogout!();
            } else {
              defaultLogout();
            }
          },
          child: Row(
            children: [
              Icon(Icons.logout, color: scheme.error),
              const SizedBox(width: 12),
              Text(
                context.tr('logout'),
                style: TextStyle(color: scheme.error, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AttachmentDesktopActions extends StatelessWidget {
  const _AttachmentDesktopActions({
    required this.accent,
    this.currentTab,
    this.onCertificates,
    this.onPlans,
    this.onSupport,
    this.onAbout,
    required this.onLogout,
  });

  final Color accent;
  final String? currentTab;
  final VoidCallback? onCertificates;
  final VoidCallback? onPlans;
  final VoidCallback? onSupport;
  final VoidCallback? onAbout;
  final Future<void> Function() onLogout;

  ButtonStyle _textBtnStyle(BuildContext context, Color accent) {
    return ButtonStyle(
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 16),
      ),
      minimumSize: WidgetStateProperty.all(const Size(48, 40)),
      animationDuration: const Duration(milliseconds: 140),
      overlayColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.hovered)
            ? accent.withValues(alpha: 0.12)
            : Theme.of(context).colorScheme.surface.withValues(alpha: 0),
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.hovered)
            ? Theme.of(context).colorScheme.onSurface
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: .72),
      ),
      textStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: s.contains(WidgetState.hovered) ? 16 : 15,
          fontWeight: s.contains(WidgetState.hovered)
              ? FontWeight.w600
              : FontWeight.w500,
          decoration: s.contains(WidgetState.hovered)
              ? TextDecoration.underline
              : TextDecoration.none,
        ),
      ),
    );
  }

  Widget _item(BuildContext context, String label, VoidCallback? onTap) {
    return _HoverScale(
      child: TextButton(
        style: _textBtnStyle(context, accent),
        onPressed: onTap, // null = disabled (used for Profile)
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    void _defaultAbout() => redirectToUrl('https://${app_settings.ASODYA_MAIN_DOMAIN}', replace: false);
    void _defaultPlans() => NavigationService.push(const OnPlansScreen());
    void _defaultStudies() => NavigationService.pushReplacement(const SessionGate());
    void _defaultCertificates() => NavigationService.push(const OnCertificatesScreen());
    void _defaultSupport() => NavigationService.push(const OnSupportScreen());

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _InlineDesktopPreferences(),
        if (currentTab != 'studies')
          _item(context, context.tr('studies'), _defaultStudies),
        if (currentTab != 'certificates')
          _item(context, context.tr('certificates'), onCertificates ?? _defaultCertificates),
        if (currentTab != 'plans')
          _item(context, context.tr('plans'), onPlans ?? _defaultPlans),
        if (currentTab != 'support')
          _item(context, context.tr('support'), onSupport ?? _defaultSupport),
        if (currentTab != 'about')
          _item(context, context.tr('about'), onAbout ?? _defaultAbout),
        const SizedBox(width: 8),
        _UserProfileButton(onLogout: () async => onLogout()),
        const SizedBox(width: 8),
      ],
    );
  }
}

/// Mobile end-drawer for small screens.
/// Place this in the page Scaffold as `endDrawer: AttachmentSideMenu(...)`.
class AttachmentSideMenu extends StatelessWidget {
  const AttachmentSideMenu({
    super.key,
    this.currentTab,
    this.onCertificates,
    this.onPlans,
    this.onSupport,
    this.onAbout,
    this.onLogout,
    this.width = 320,
  });

  final String? currentTab;
  final VoidCallback? onCertificates;
  final VoidCallback? onPlans;
  final VoidCallback? onSupport;
  final VoidCallback? onAbout;
  final Future<void> Function()? onLogout;
  final double width;

  void _close(BuildContext context) => Navigator.of(context).maybePop();

  ListTile _tile(
    BuildContext ctx,
    IconData icon,
    String label,
    VoidCallback? onTap,
  ) {
    final scheme = Theme.of(ctx).colorScheme;
    return ListTile(
      leading: Icon(icon, color: scheme.onSurface),
      title: Text(
        label,
        style: Theme.of(
          ctx,
        ).textTheme.titleMedium?.copyWith(color: scheme.onSurface),
      ),
      onTap: onTap == null
          ? null
          : () {
              _close(ctx);
              onTap();
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    void _defaultAbout() => redirectToUrl('https://${app_settings.ASODYA_MAIN_DOMAIN}', replace: false);
    void _defaultPlans() => NavigationService.push(const OnPlansScreen());
    void _defaultStudies() => NavigationService.pushReplacement(const SessionGate());
    void _defaultCertificates() => NavigationService.push(const OnCertificatesScreen());
    void _defaultSupport() => NavigationService.push(const OnSupportScreen());

    return Drawer(
      backgroundColor: scheme.surface,
      child: SafeArea(
        left: false,
        bottom: false,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (currentTab != 'studies')
                _tile(
                  context,
                  Icons.school_outlined,
                  context.tr('studies'),
                  _defaultStudies,
                ),
              if (currentTab != 'certificates')
                _tile(
                  context,
                  Icons.workspace_premium_outlined,
                  context.tr('certificates'),
                  onCertificates ?? _defaultCertificates,
                ),
              if (currentTab != 'plans')
                _tile(
                  context,
                  Icons.stacked_line_chart_outlined,
                  context.tr('plans'),
                  onPlans ?? _defaultPlans,
                ),
              if (currentTab != 'support')
                _tile(
                  context,
                  Icons.support_agent_outlined,
                  context.tr('support'),
                  onSupport ?? _defaultSupport,
                ),
              if (currentTab != 'about')
                _tile(context, Icons.info_outline, context.tr('about'), onAbout ?? _defaultAbout),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: AppPreferencesPanel(),
              ),
              const Spacer(),
              const Divider(height: 1),
              _tile(
                context,
                Icons.person_outline,
                context.tr('profile'),
                null,
              ),
              ListTile(
                leading: Icon(Icons.logout, color: scheme.onSurface),
                title: Text(
                  context.tr('logout'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: scheme.onSurface),
                ),
                onTap: () async {
                  _close(context);
                  final logout = onLogout;
                  if (logout != null) {
                    await logout();
                  } else {
                    await clearSessionArtifacts();
                    try {
                      final url = await urlRedirectionToAuth();
                      redirectToUrl(url, replace: true, removeSlash: true);
                    } catch (e) {
                      debug('drawer default logout redirect failed: $e');
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small hover-scale wrapper (desktop/web), noop on touch.
class _HoverScale extends StatefulWidget {
  const _HoverScale({required this.child});
  final Widget child;

  @override
  State<_HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<_HoverScale> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
