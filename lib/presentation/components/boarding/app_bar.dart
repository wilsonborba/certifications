import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/presentation/components/preferences/app_preferences_controls.dart';
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
    this.onAbout,
    this.onLogin,
    this.onSignUp,
  });

  final String logoAsset;
  final String logoSemanticLabel;
  final double maxActionLayoutWidth;

  final VoidCallback? onAbout;
  final VoidCallback? onLogin;
  final VoidCallback? onSignUp;

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
        // AppBar's local layout width can be smaller than the window because
        // the Scaffold reserves its automatic end-drawer action. Use the
        // actual viewport, so a desktop never falls into the mobile menu.
        final showFullActions =
            MediaQuery.sizeOf(ctx).width >= maxActionLayoutWidth;

        return AppBar(
          automaticallyImplyLeading: false, // no back button
          centerTitle: false,
          backgroundColor: scheme.surface,
          elevation: 0,
          surfaceTintColor: scheme.surface,
          scrolledUnderElevation: 0,
          // The custom trigger below opens the end drawer. Suppress
          // Scaffold's automatic trailing end-drawer action; otherwise newer
          // Flutter versions render two hamburger buttons.
          actions: const [],
          titleSpacing: 16,
          toolbarHeight: _appBarHeight,
          title: Row(
            children: [
              // Logo at left
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    // keep a little breathing room vs toolbar height
                    maxHeight: 50,
                  ),
                  child: Image.asset(
                    logoAsset,
                    fit: BoxFit.contain,
                    semanticLabel: logoSemanticLabel,
                  ),
                ),
              ),
              const Spacer(),
              if (showFullActions)
                _DesktopActions(
                  purple: purple,
                  onAbout: onAbout,
                  onLogin: onLogin,
                  onSignUp: onSignUp,
                )
              else
                // Use Builder so we get a context under the Scaffold
                Builder(
                  builder: (context) => IconButton(
                    tooltip: context.tr('menu'),
                    icon: Icon(Icons.menu, color: scheme.onSurface),
                    iconSize: 45, // <— bigger icon
                    padding: const EdgeInsets.all(12), // <— bigger tap target
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: () {
                      final scaffold = Scaffold.maybeOf(context);
                      scaffold?.openEndDrawer();
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DesktopActions extends StatelessWidget {
  const _DesktopActions({
    required this.purple,
    this.onAbout,
    this.onLogin,
    this.onSignUp,
  });

  final Color purple;
  final VoidCallback? onAbout;
  final VoidCallback? onLogin;
  final VoidCallback? onSignUp;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Base text style for desktop action labels
    final textStyle = TextStyle(
      color: scheme.onPrimary,
      fontSize: 22,
      fontWeight: FontWeight.w500,
    );

    // Text buttons with smooth hover animations (no deprecated APIs)
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

    // Sign up button with light hover elevation
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
        const AppPreferencesButton(),
        _HoverScale(
          child: TextButton(
            style: _textBtnStyle(purple),
            onPressed: onAbout,
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
    this.onAbout,
    this.onLogin,
    this.onSignUp,
    this.width = 320, // you can tune the drawer width here
  });

  final VoidCallback? onAbout;
  final VoidCallback? onLogin;
  final VoidCallback? onSignUp;
  final double width;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
              // (Optional) Header with logo or title
              // Padding(
              //   padding: const EdgeInsets.all(16),
              //   child: Image.asset('assets/logo.png', height: 28),
              // ),
              _item(
                icon: Icons.info_outline,
                label: context.tr('about'),
                onTap: onAbout,
              ),
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
