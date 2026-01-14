import 'package:accredit/presentation/widgets/certifications_config/on_certifications_config.dart';
import 'package:flutter/material.dart';
import 'package:accredit/core/utils/my_nagivation.dart';

class TopicsCard extends StatefulWidget {
  final String itemName;
  final String identification;
  final String title;
  final String about;
  final String link;
  final String? imageUrl;

  final EdgeInsets padding;
  final double titleFontSize;
  final double titleFontWeight; // 100..900 mapped to FontWeight
  final double buttonMinHeight;
  final double buttonMinWidth;
  final double imageWidth;
  final double imageHeight;
  final double gap;
  final bool showDivider;

  const TopicsCard({
    super.key,
    required this.itemName,
    required this.identification,
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
  bool _hovered = false;

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
    final cs = Theme.of(context).colorScheme;

    final titleStyle = TextStyle(
      fontSize: widget.titleFontSize,
      color: cs.onSurface,
      fontWeight: FontWeight.values[(widget.titleFontWeight / 100).clamp(0, 9).round()],
    );

    // soft, tactile card
    final borderColor = cs.primary.withAlpha((.14 * 255).toInt());

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
        ..translateByDouble(0.0, _hovered ? -1.0 : 0.0, 0.0, 1.0)
        ..scaleByDouble(
          _hovered ? 1.005 : 1.0,
          _hovered ? 1.005 : 1.0,
          1.0,
          1.0,
        ),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: [
            // soft drop shadow for tactile feel
            BoxShadow(color: Colors.black.withAlpha((.05 * 255).toInt()), blurRadius: 18, offset: const Offset(0, 10)),
            // subtle highlight (neumorphic feel)
            BoxShadow(color: Colors.white.withAlpha((.7 * 255).toInt()), blurRadius: 6, offset: const Offset(-1, -1), spreadRadius: -2),
          ],
        ),
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
                    // Accent capsule
                    Container(
                      height: 4,
                      width: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [cs.primary, cs.primary.withAlpha((.6 * 255).toInt())],
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.about,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurface.withAlpha((0.6 * 255).toInt()),
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HoverableAction(
                          label: 'See more',
                          icon: Icons.remove_red_eye_outlined,
                          minSize: Size(
                            widget.buttonMinWidth,
                            widget.buttonMinHeight,
                          ),
                          baseColor: cs.onSurface,
                          hoverColor: cs.primary,
                          onTap: () => redirectToUrl(
                            widget.link,
                            replace: false,
                          ),
                        ),
                        _HoverableAction(
                          label: 'Select',
                          icon: Icons.check_circle_outline,
                          minSize: Size(
                            widget.buttonMinWidth,
                            widget.buttonMinHeight,
                          ),
                          baseColor: cs.onSurface,
                          hoverColor: cs.primary,
                          onTap: () {
                            NavigationService.push(
                              OnCertificationConfigScreen(
                                itemName: widget.itemName,
                                contextId: widget.identification,
                                isForPDF: false,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // RIGHT: divider + image
              if (_imageOk && _provider != null) ...[
                SizedBox(width: widget.gap),
                if (widget.showDivider)
                  VerticalDivider(width: 1, thickness: 1, color: cs.outlineVariant),
                SizedBox(width: widget.gap),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
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
      ),
    );
  }
}

/// Hoverable pill action with subtle gradient tint and tactile feedback
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
    final cs = Theme.of(context).colorScheme;
    final fg = _hovered ? cs.primary : widget.baseColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
            transform: Matrix4.identity()
        ..translateByDouble(_hovered ? 2.0 : 0.0, _hovered ? -1.0 : 0.0, 0.0, 1.0)
        ..scaleByDouble(
          _pressed ? 0.98 : 1.0,
          _pressed ? 0.98 : 1.0,
          1.0,
          1.0,
        ),
      decoration: BoxDecoration(
        color: _hovered ? cs.primary.withAlpha((.08 * 255).toInt()) : cs.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.primary.withAlpha((.22 * 255).toInt())),
        boxShadow: [
          if (_hovered) BoxShadow(color: cs.primary.withAlpha((.18 * 255).toInt()), blurRadius: 14, offset: const Offset(0, 8)),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          splashColor: cs.primary.withAlpha((.14 * 255).toInt()),
          highlightColor: Colors.transparent,
          onHover: (v) => setState(() => _hovered = v),
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: () {
            setState(() => _pressed = false);
            widget.onTap();
          },
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: widget.minSize.width, minHeight: widget.minSize.height),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 18, color: fg),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w700),
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
