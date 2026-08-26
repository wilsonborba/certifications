import 'package:certifications/core/settings.dart';
import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/core/utils/app_preferences.dart';
import 'package:certifications/core/utils/my_nagivation.dart';
import 'package:certifications/presentation/components/auth/session_gate.dart';
import 'package:certifications/presentation/components/auth/verify_session.dart';
import 'package:certifications/presentation/components/preferences/app_preferences_controls.dart';
import 'package:certifications/presentation/widgets/plans/on_plans.dart';
import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// BoardingAppBar + MobileSideMenu
/// - Desktop (>= maxActionLayoutWidth): inline actions (About, Log in, Sign up)
/// - Mobile  (< maxActionLayoutWidth): burger icon that opens a right side Drawer
/// - Drawer closes when tapping outside, swiping, or pressing the X item
/// - Uses modern WidgetState/WidgetStateProperty and Color.withValues(...)
/// ---------------------------------------------------------------------------
/// Usage:
/// Scaffold(
///   appBar: BoardingAppBar(
///     logoAsset: 'assets/logo.png',
///     onAbout: () => context.go('/about'),
///     onLogin: () => context.go('/login'),
///     onSignUp: () => context.go('/signup'),
///   ),
///   endDrawer: MobileSideMenu(               // <— add this to enable the side menu
///     onAbout: () => context.go('/about'),
///     onLogin: () => context.go('/login'),
///     onSignUp: () => context.go('/signup'),
///   ),
///   endDrawerEnableOpenDragGesture: true,    // optional: swipe from right to open
///   body: ...,
/// );
/// ---------------------------------------------------------------------------

const double _appBarHeight = 100;

class BoardingAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BoardingAppBar({
    super.key,
    required this.logoAsset,
    this.logoSemanticLabel = 'App logo',
    this.maxActionLayoutWidth = 720, // breakpoint for desktop vs mobile actions
    this.currentTab,
    this.onHome,
    this.onAbout,
    this.onPlans,
    this.onLogin,
    this.onSignUp,
    this.onLogout,
  });

  final String logoAsset;
  final String logoSemanticLabel;
  final double maxActionLayoutWidth;
  final String? currentTab;

  final VoidCallback? onHome;
  final VoidCallback? onAbout;
  final VoidCallback? onPlans;
  final VoidCallback? onLogin;
  final VoidCallback? onSignUp;
  final VoidCallback? onLogout;

  @override
  Size get preferredSize => const Size.fromHeight(_appBarHeight);

  // Picks primary from theme; override at the Theme if needed.
  Color _purpleOf(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final purple = _purpleOf(context);

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final showFullActions =
            MediaQuery.sizeOf(ctx).width >= maxActionLayoutWidth;

        return AppBar(
          automaticallyImplyLeading: false, // no back button
          centerTitle: false,
          backgroundColor: scheme.surface,
          elevation: 0,
          surfaceTintColor: scheme.surface,
          scrolledUnderElevation: 0,
          titleSpacing: 16,
          toolbarHeight: _appBarHeight,
          title: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              NavigationService.pushReplacement(const SessionGate());
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 50,
                ),
                child: Image.asset(
                  logoAsset,
                  fit: BoxFit.contain,
                  semanticLabel: logoSemanticLabel,
                ),
              ),
            ),
          ),
          actions: [
            if (showFullActions)
              _DesktopActions(
                purple: purple,
                currentTab: currentTab,
                onHome: onHome,
                onAbout: onAbout,
                onPlans: onPlans,
                onLogin: onLogin,
                onSignUp: onSignUp,
                onLogout: onLogout,
              )
            else
              Builder(
                builder: (context) => IconButton(
                  tooltip: context.tr('menu'),
                  icon: Icon(Icons.menu, color: scheme.onSurface),
                  iconSize: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onPressed: () {
                    final scaffold = Scaffold.maybeOf(context);
                    scaffold?.openEndDrawer();
                  },
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

class _DesktopActions extends StatelessWidget {
  const _DesktopActions({
    required this.purple,
    this.currentTab,
    this.onHome,
    this.onAbout,
    this.onPlans,
    this.onLogin,
    this.onSignUp,
    this.onLogout,
  });

  final Color purple;
  final String? currentTab;
  final VoidCallback? onHome;
  final VoidCallback? onAbout;
  final VoidCallback? onPlans;
  final VoidCallback? onLogin;
  final VoidCallback? onSignUp;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLoggedIn = readCsrfToken() != null && readCsrfToken()!.isNotEmpty;

    void _defaultAbout() => redirectToUrl('https://${app_settings.ASODYA_MAIN_DOMAIN}', replace: false);
    void _defaultHome() => NavigationService.pushReplacement(const SessionGate());
    void _defaultPlans() => NavigationService.push(const OnPlansScreen());

    final textStyle = TextStyle(
      color: scheme.onPrimary,
      fontSize: 22,
      fontWeight: FontWeight.w500,
    );

    ButtonStyle _textBtnStyle(Color purple) {
      return ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16),
        ),
        minimumSize: WidgetStateProperty.all(const Size(48, 40)),
        animationDuration: const Duration(milliseconds: 140),
        overlayColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.hovered)
              ? purple.withValues(alpha: 0.12)
              : scheme.surface.withValues(alpha: 0),
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.hovered)
              ? scheme.onSurface
              : scheme.onSurface.withValues(alpha: .72),
        ),
        textStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontSize: s.contains(WidgetState.hovered) ? 23 : 22,
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

    final signUpStyle = ButtonStyle(
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 20),
      ),
      minimumSize: WidgetStateProperty.all(const Size(100, 60)),
      animationDuration: const Duration(milliseconds: 140),
      backgroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.hovered)
            ? purple.withValues(alpha: 0.92)
            : purple,
      ),
      foregroundColor: WidgetStateProperty.resolveWith((_) => scheme.onPrimary),
      elevation: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.hovered) ? 4 : 0,
      ),
      shadowColor: WidgetStateProperty.resolveWith((_) => purple),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _InlineDesktopPreferences(),
        if (isLoggedIn) ...[
          if (currentTab != 'studies')
            _HoverScale(
              child: TextButton(
                style: _textBtnStyle(purple),
                onPressed: onHome ?? _defaultHome,
                child: Text(context.tr('studies')),
              ),
            ),
          if (currentTab != 'plans')
            _HoverScale(
              child: TextButton(
                style: _textBtnStyle(purple),
                onPressed: onPlans ?? _defaultPlans,
                child: Text(context.tr('plans')),
              ),
            ),
          if (currentTab != 'about')
            _HoverScale(
              child: TextButton(
                style: _textBtnStyle(purple),
                onPressed: onAbout ?? _defaultAbout,
                child: Text(context.tr('about')),
              ),
            ),
          const SizedBox(width: 8),
          _UserProfileButton(onLogout: onLogout ?? () async => defaultLogout()),
        ] else ...[
          if (currentTab != 'plans')
            _HoverScale(
              child: TextButton(
                style: _textBtnStyle(purple),
                onPressed: onPlans ?? _defaultPlans,
                child: Text(context.tr('plans')),
              ),
            ),
          if (currentTab != 'about')
            _HoverScale(
              child: TextButton(
                style: _textBtnStyle(purple),
                onPressed: onAbout ?? _defaultAbout,
                child: Text(context.tr('about')),
              ),
            ),
          _HoverScale(
            child: TextButton(
              style: _textBtnStyle(purple),
              onPressed: onLogin,
              child: Text(context.tr('logIn')),
            ),
          ),
          const SizedBox(width: 8),
          _HoverScale(
            child: ElevatedButton(
              style: signUpStyle,
              onPressed: onSignUp,
              child: Text(context.tr('signUp'), style: textStyle),
            ),
          ),
        ],
        const SizedBox(width: 8),
      ],
    );
  }
}

/// Small hover scale wrapper (desktop/web), noop on touch
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

/// Right-side (end) Drawer used on mobile layout.
/// Closes on backdrop tap, swipe, or pressing the 'Close ✕' tile.
class MobileSideMenu extends StatelessWidget {
  const MobileSideMenu({
    super.key,
    this.currentTab,
    this.onHome,
    this.onAbout,
    this.onPlans,
    this.onLogin,
    this.onSignUp,
    this.onLogout,
    this.width = 320, // you can tune the drawer width here
  });

  final String? currentTab;
  final VoidCallback? onHome;
  final VoidCallback? onAbout;
  final VoidCallback? onPlans;
  final VoidCallback? onLogin;
  final VoidCallback? onSignUp;
  final VoidCallback? onLogout;
  final double width;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLoggedIn = readCsrfToken() != null && readCsrfToken()!.isNotEmpty;

    void _defaultAbout() => redirectToUrl('https://${app_settings.ASODYA_MAIN_DOMAIN}', replace: false);
    void _defaultHome() => NavigationService.pushReplacement(const SessionGate());
    void _defaultPlans() => NavigationService.push(const OnPlansScreen());

    void _close() => Navigator.of(context).maybePop();

    ListTile _item({
      required IconData icon,
      required String label,
      required VoidCallback? onTap,
    }) {
      return ListTile(
        leading: Icon(icon, color: scheme.onSurface),
        title: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: scheme.onSurface),
        ),
        onTap: () {
          _close();
          onTap?.call();
        },
      );
    }

    return Drawer(
      backgroundColor: scheme.surface,
      child: SafeArea(
        left: false,
        bottom: false,
        child: SizedBox(
          width: width, // constrain the drawer width for a “panel” feel
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isLoggedIn && currentTab != 'studies')
                _item(
                  icon: Icons.school_outlined,
                  label: context.tr('studies'),
                  onTap: onHome ?? _defaultHome,
                ),
              if (currentTab != 'plans')
                _item(
                  icon: Icons.view_carousel_outlined,
                  label: context.tr('plans'),
                  onTap: onPlans ?? _defaultPlans,
                ),
              if (currentTab != 'about')
                _item(
                  icon: Icons.info_outline,
                  label: context.tr('about'),
                  onTap: onAbout ?? _defaultAbout,
                ),
              if (isLoggedIn) ...[
                const Divider(height: 1),
                _item(
                  icon: Icons.person_outline,
                  label: context.tr('profile'),
                  onTap: null,
                ),
                _item(
                  icon: Icons.logout,
                  label: context.tr('logout'),
                  onTap: onLogout ?? () async => defaultLogout(),
                ),
              ] else ...[
                _item(
                  icon: Icons.login,
                  label: context.tr('logIn'),
                  onTap: onLogin,
                ),
                _item(
                  icon: Icons.person_add_alt_1,
                  label: context.tr('signUp'),
                  onTap: onSignUp,
                ),
              ],
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: AppPreferencesPanel(),
              ),

              const Spacer(),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.close, color: scheme.onSurface),
                title: Text(
                  context.tr('close'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: scheme.onSurface),
                ),

                onTap: _close, // explicit close
              ),
            ],
          ),
        ),
      ),
    );
  }
}
