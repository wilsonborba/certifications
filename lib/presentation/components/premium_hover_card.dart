import 'package:flutter/material.dart';

/// Shared "Apple-style" translucent hover card used across the app wherever
/// a premium card or elevated interactive surface is needed (Plans, the quiz
/// wizard's upload zone, dashboard tiles, standby study cards, the
/// certificates master/detail list, ...).
///
/// This is the single source of truth for that visual recipe, extracted from
/// the private hover-card widget that used to live only in `plans_view.dart`:
/// - 200ms `easeOutCubic` [AnimatedContainer]
/// - translucent `surfaceContainerHighest` background (0.4 alpha)
/// - 24px rounded corners
/// - 1.0px [ColorScheme.outline] border at rest, 1.8px accent border on hover
/// - soft ambient shadow at rest, deeper accent-tinted shadow on hover
/// - hover state tracked via [MouseRegion]
///
/// Every screen that needs a "premium" card should reuse this widget instead
/// of re-implementing the recipe by hand.
class PremiumHoverCard extends StatefulWidget {
  const PremiumHoverCard({
    super.key,
    required this.child,
    this.accentColor,
    this.onTap,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = 24,
    this.width = double.infinity,
    this.selected = false,
  });

  /// Content rendered inside the card.
  final Widget child;

  /// Border/shadow tint used on hover. Defaults to [ColorScheme.primary].
  final Color? accentColor;

  /// When set, the card becomes tappable (with the matching hover cursor and
  /// ink feedback). When null, the card is purely decorative/hover-reactive.
  final VoidCallback? onTap;

  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double? width;

  /// When true, the card renders as if hovered/focused even without a real
  /// pointer over it, e.g. to highlight the selected row of a master/detail
  /// list.
  final bool selected;

  @override
  State<PremiumHoverCard> createState() => _PremiumHoverCardState();
}

class _PremiumHoverCardState extends State<PremiumHoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.accentColor ?? scheme.primary;
    final active = _hovered || widget.selected;
    final radius = BorderRadius.circular(widget.borderRadius);

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: widget.width,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: radius,
        border: Border.all(
          color: active ? accent : scheme.outline.withValues(alpha: 0.25),
          width: active ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (active ? accent : scheme.onSurface).withValues(
              alpha: active ? 0.15 : 0.04,
            ),
            blurRadius: active ? 28 : 14,
            offset: Offset(0, active ? 12 : 6),
          ),
        ],
      ),
      child: widget.child,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      child: widget.onTap == null
          ? card
          : Material(
              color: Colors.transparent,
              borderRadius: radius,
              child: InkWell(
                borderRadius: radius,
                onTap: widget.onTap,
                child: card,
              ),
            ),
    );
  }
}
