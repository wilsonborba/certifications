import 'package:flutter/material.dart';
import 'package:accredit/core/utils/my_nagivation.dart';

/// Reusable Topic card for both Desktop & Mobile.
/// Adds hover + press affordances to action buttons.
class TopicsCard extends StatefulWidget {
  final String title;
  final String about;      // e.g., "About"
  final String link;       // open in new tab / replace: false
  final String? imageUrl;

  // Layout knobs so Desktop/Mobile can look slightly different without forking:
  final EdgeInsets padding;
  final double titleFontSize;
  /// 600 -> FontWeight.w600 (we map 100..900 to FontWeight.values[1..9])
  final double titleFontWeight;
  final double buttonMinHeight;
  final double buttonMinWidth;
  final double imageWidth;
  final double imageHeight;
  final double gap;
  final bool showDivider;

  const TopicsCard({
    super.key,
    required this.title,
    required this.about,
    required this.link,
    required this.imageUrl,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.titleFontSize = 18,
    this.titleFontWeight = 600,
    this.buttonMinHeight = 60,
    this.buttonMinWidth = 80,
    this.imageWidth = 120,
    this.imageHeight = 72,
    this.gap = 30,
    this.showDivider = true,
  });

  @override
  State<TopicsCard> createState() => _TopicsCardState();
}

class _TopicsCardState extends State<TopicsCard> {
  bool _imageOk = false;
  ImageProvider? _provider;

  @override
  void initState() {
    super.initState();
    _prepareProvider();
  }

  @override
  void didUpdateWidget(covariant TopicsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _prepareProvider();
    }
  }

  void _prepareProvider() {
    _imageOk = false;
    final url = widget.imageUrl?.trim();
    if (url == null || url.isEmpty) {
      _provider = null;
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      _provider = null;
      return;
    }
    _provider = NetworkImage(url);
  }

  /// Invisible, non-interactive preloader that lets us detect when the
  /// first frame is available (so we avoid layout jank).
  Widget _preloadImage() {
    if (_provider == null) return const SizedBox.shrink();
    return IgnorePointer(
      ignoring: true,
      child: Offstage(
        offstage: true,
        child: Image(
          image: _provider!,
          excludeFromSemantics: true,
          frameBuilder: (context, child, frame, _) {
            if (frame != null && !_imageOk) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _imageOk = true);
              });
            }
            return child;
          },
          errorBuilder: (context, error, stack) {
            if (_imageOk && mounted) setState(() => _imageOk = false);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontSize: widget.titleFontSize,
      fontWeight: FontWeight.values[
        (widget.titleFontWeight / 100).clamp(0, 9).round()
      ],
    );
    final baseColor = Theme.of(context).colorScheme.onSurface;
    final hoverColor = Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 2,
      color: const Color.fromARGB(255, 250, 253, 255),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: widget.padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _preloadImage(),

            // LEFT: title + actions
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle),
                  const Spacer(),

                  Row(
                    children: [
                      // See more -> opens link
                      _HoverableAction(
                        label: 'See more',
                        icon: Icons.remove_red_eye_outlined,
                        minSize: Size(widget.buttonMinWidth, widget.buttonMinHeight),
                        baseColor: baseColor,
                        hoverColor: hoverColor,
                        onTap: () => redirectToUrl(widget.link, replace: false),
                      ),

                      const Spacer(),

                      // Select -> hook up when you have a handler
                      _HoverableAction(
                        label: 'Select',
                        icon: Icons.check_circle_outline,
                        minSize: Size(widget.buttonMinWidth, widget.buttonMinHeight),
                        baseColor: baseColor,
                        hoverColor: hoverColor,
                        onTap: () {
                          // TODO: implement your selection behavior
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // RIGHT: divider + image after first frame renders
            if (_imageOk && _provider != null) ...[
              SizedBox(width: widget.gap),
              if (widget.showDivider) const VerticalDivider(width: 1, thickness: 1),
              SizedBox(width: widget.gap),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image(
                  image: _provider!,
                  width: widget.imageWidth,
                  height: widget.imageHeight,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A tiny reusable button-like control with **hover + press** affordances:
/// - Hover: tint to hoverColor and slide by a couple pixels
/// - Press: slight scale-down
/// - Ripple: InkWell splash, with click cursor on desktop/web
class _HoverableAction extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Size minSize;
  final Color baseColor;
  final Color hoverColor;

  const _HoverableAction({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.minSize,
    required this.baseColor,
    required this.hoverColor,
  });

  @override
  State<_HoverableAction> createState() => _HoverableActionState();
}


class _HoverableActionState extends State<_HoverableAction> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = _hovered ? widget.hoverColor : widget.baseColor;

    // Slight translation on hover; slight scale on press
    final dx = _hovered ? 2.0 : 0.0;     // move right 2px on hover
    final dy = _hovered ? -1.0 : 0.0;    // and up 1px
    final scale = _pressed ? 0.98 : 1.0; // tiny press feedback

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            splashColor: widget.hoverColor.withAlpha((.12 * 255).toInt()),
            highlightColor: Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              constraints: BoxConstraints(
                minWidth: widget.minSize.width,
                minHeight: widget.minSize.height,
              ),
              transform: Matrix4.identity()
                ..translateByDouble(dx, dy, 0, 1.0)           // add w = 1.0
                ..scaleByDouble(scale, scale, scale, 1.0),    // scale across all axes

              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 18, color: color),
                  const SizedBox(width: 8),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 140),
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    child: Text(widget.label),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
