import 'package:accredit/core/utils/my_logs.dart';
import 'package:accredit/core/utils/my_nagivation.dart';

import 'package:accredit/presentation/components/auth/login_redirect.dart';
import 'package:flutter/material.dart';



const double _appBarHeight = 80;

/// ===== AppBar ===============================================================

class AttachmentAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AttachmentAppBar({
    super.key,
    this.title = 'Certifications',
    this.maxActionLayoutWidth = 800,
    this.onCertificates,
    this.onPlans,
    this.onTokens,
    this.onSupport,
    this.onAbout,
    this.onLogout, // if null, a safe default logout (clear + redirect) is used
  });

  final String title;
  final double maxActionLayoutWidth;

  final VoidCallback? onCertificates;
  final VoidCallback? onPlans;
  final VoidCallback? onTokens;
  final VoidCallback? onSupport;
  final VoidCallback? onAbout;
  final Future<void> Function()? onLogout;

  @override
  Size get preferredSize => const Size.fromHeight(_appBarHeight);

  Color _accentOf(BuildContext context) => Theme.of(context).colorScheme.primary;


  @override
  Widget build(BuildContext context) {
    
    final accent = _accentOf(context);

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final wide = constraints.maxWidth >= maxActionLayoutWidth;

        return AppBar(
          automaticallyImplyLeading: false, // no back arrow
          centerTitle: false,
          backgroundColor: Colors.black,
          elevation: 0,
          surfaceTintColor: Colors.black,
          scrolledUnderElevation: 0,
          toolbarHeight: _appBarHeight,
          titleSpacing: 16,
          title: Row(
            children: [
              // Left-aligned title
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              if (wide)
                _AttachmentDesktopActions(
                  accent: accent,
                  onCertificates: onCertificates,
                  onPlans: onPlans,
                  onTokens: onTokens,
                  onSupport: onSupport,
                  onAbout: onAbout,
                  onLogout: onLogout ?? defaultLogout,
                )
              else
                Builder(
                  builder: (context) => IconButton(
                    tooltip: 'Menu',
                    icon: const Icon(Icons.menu, color: Colors.white),
                    iconSize: 45,
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: () => Scaffold.maybeOf(context)?.openEndDrawer(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AttachmentDesktopActions extends StatelessWidget {
  const _AttachmentDesktopActions({
    required this.accent,
    this.onCertificates,
    this.onPlans,
    this.onTokens,
    this.onSupport,
    this.onAbout,
    required this.onLogout,
  });

  final Color accent;
  final VoidCallback? onCertificates;
  final VoidCallback? onPlans;
  final VoidCallback? onTokens;
  final VoidCallback? onSupport;
  final VoidCallback? onAbout;
  final Future<void> Function() onLogout;

  ButtonStyle _textBtnStyle(Color accent) {
    return ButtonStyle(
      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16)),
      minimumSize: WidgetStateProperty.all(const Size(48, 40)),
      animationDuration: const Duration(milliseconds: 140),
      overlayColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.hovered) ? accent.withValues(alpha: 0.12) : Colors.transparent,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.hovered) ? Colors.white : Colors.white70,
      ),
      textStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: s.contains(WidgetState.hovered) ? 16 : 15,
          fontWeight: s.contains(WidgetState.hovered) ? FontWeight.w600 : FontWeight.w500,
          decoration: s.contains(WidgetState.hovered) ? TextDecoration.underline : TextDecoration.none,
        ),
      ),
    );
  }

  Widget _item(String label, VoidCallback? onTap) {
    return _HoverScale(
      child: TextButton(
        style: _textBtnStyle(accent),
        onPressed: onTap, // null = disabled (used for Profile)
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logoutStyle = _textBtnStyle(accent).copyWith(
      foregroundColor: WidgetStateProperty.all(Colors.redAccent),
      overlayColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.hovered) ? Colors.redAccent.withValues(alpha: 0.12) : Colors.transparent,
      ),
      textStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: s.contains(WidgetState.hovered) ? 16 : 15,
          fontWeight: s.contains(WidgetState.hovered) ? FontWeight.w600 : FontWeight.w500,
          decoration: s.contains(WidgetState.hovered) ? TextDecoration.underline : TextDecoration.none,
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _item('Certificates', onCertificates),
        _item('Tokens', onTokens),
        _item('Plans', onPlans),
        _item('Support', onSupport),
        _item('About', onAbout),
        const SizedBox(width: 8),
        _HoverScale(
          child: TextButton(
            style: logoutStyle,
            onPressed: () => onLogout(),
            child: const Text('Logout'),
          ),
        ),
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
    this.onCertificates,
    this.onPlans,
    this.onTokens,
    this.onSupport,
    this.onAbout,
    this.onLogout,
    this.width = 320,
  });

  final VoidCallback? onCertificates;
  final VoidCallback? onPlans;
  final VoidCallback? onTokens;
  final VoidCallback? onSupport;
  final VoidCallback? onAbout;
  final Future<void> Function()? onLogout;
  final double width;

  void _close(BuildContext context) => Navigator.of(context).maybePop();

  ListTile _tile(BuildContext ctx, IconData icon, String label, VoidCallback? onTap) {
    final scheme = Theme.of(ctx).colorScheme;
    return ListTile(
      leading: Icon(icon, color: scheme.onPrimary),
      title: Text(
        label,
        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(color: scheme.onPrimary),
      ),
      onTap: onTap == null ? null : () { _close(ctx); onTap(); },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: const Color(0xFF121212),
      child: SafeArea(
        left: false,
        bottom: false,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _tile(context, Icons.workspace_premium_outlined, 'Certificates', onCertificates),
              _tile(context, Icons.stacked_line_chart_outlined, 'Plans', onPlans),
              _tile(context, Icons.token_outlined, 'Tokens', onTokens),
              _tile(context, Icons.person_outline, 'Profile', null), // disabled
              _tile(context, Icons.support_agent_outlined, 'Support', onSupport),
              _tile(context, Icons.info_outline, 'About', onAbout),
              const Spacer(),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.logout, color: scheme.onPrimary),
                title: Text(
                  'Logout',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onPrimary),
                ),
                onTap: () async {
                  _close(context);
                  if (onLogout != null) {
                    await onLogout!();
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
      onExit:  (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
