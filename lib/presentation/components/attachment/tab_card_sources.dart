import 'package:flutter/material.dart';

/// Rectangular two-option toggle (pill-like thumb slides left/right).
class RectToggle extends StatelessWidget {
  const RectToggle({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    required this.selectedIndex,
    required this.onChanged,
    this.width = 280,
    this.height = 40,
    this.radius = 12,
    this.elevation = 3,
    this.duration = const Duration(milliseconds: 220),

    // Optional overrides (leave null to use theme)
    this.trackColor,
    this.borderColor,
    this.leftActiveColor,
    this.rightActiveColor,
    this.inactiveLabelColor,
  });

  final String leftLabel;
  final String rightLabel;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  final double width;
  final double height;
  final double radius;
  final double elevation;
  final Duration duration;

  // Optional color overrides
  final Color? trackColor;         // background “rail”
  final Color? borderColor;        // rail border
  final Color? leftActiveColor;    // thumb when left selected (defaults to secondary)
  final Color? rightActiveColor;   // thumb when right selected (defaults to primary)
  final Color? inactiveLabelColor; // labels for the unselected side

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Color leftActive  = leftActiveColor  ?? scheme.secondary;
    final Color rightActive = rightActiveColor ?? scheme.primary;
    final Color railColor   = trackColor       ?? scheme.surfaceContainerHigh;
    final Color railBorder  = borderColor      ?? scheme.outlineVariant.withAlpha(230);
    final Color inactiveLbl = inactiveLabelColor ?? scheme.onSurfaceVariant;

    final bool leftSelected  = selectedIndex == 0;
    final bool rightSelected = selectedIndex == 1;

    final Alignment thumbAlign = leftSelected ? Alignment.centerLeft : Alignment.centerRight;
    final Color thumbColor      = leftSelected ? leftActive : rightActive;
    final Color leftTextColor   = leftSelected ? scheme.onSecondary : inactiveLbl;
    final Color rightTextColor  = rightSelected ? scheme.onPrimary : inactiveLbl;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // Track (rail)
          AnimatedContainer(
            duration: duration,
            decoration: BoxDecoration(
              color: railColor,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: railBorder),
            ),
          ),

          // Sliding thumb (uses primary/secondary)
          AnimatedAlign(
            alignment: thumbAlign,
            duration: duration,
            curve: Curves.easeOutCubic,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1.0,
              child: Material(
                color: thumbColor,                 // <- primary/secondary here
                elevation: elevation,
                borderRadius: BorderRadius.circular(radius - 2),
                child: const SizedBox.expand(),
              ),
            ),
          ),

          // Clickable labels
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(radius),
                  onTap: () => onChanged(0),
                  child: Center(
                    child: Text(
                      leftLabel,
                      maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: leftSelected ? FontWeight.w700 : FontWeight.w500,
                        color: leftTextColor, // onSecondary or inactive
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(radius),
                  onTap: () => onChanged(1),
                  child: Center(
                    child: Text(
                      rightLabel,
                      maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: rightSelected ? FontWeight.w700 : FontWeight.w500,
                        color: rightTextColor, // onPrimary or inactive
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


/// Column layout: [RectToggle] on top-left, card below with animated swap.
class TabCardSources extends StatefulWidget {
  const TabCardSources({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftChild,
    required this.rightChild,
    this.cardWidth = 520,
    this.cardMinHeight = 240,
    this.cardRadius = 24,
    this.cardColor = const Color.fromARGB(255, 244, 244, 244),
    this.shadow = const [
      BoxShadow(color: Colors.black26, blurRadius: 18, offset: Offset(0, 10)),
    ],
    this.spacing = 12,
    this.toggleWidth = 280,
    this.toggleHeight = 40,
    this.duration = const Duration(milliseconds: 220),
    this.initialIndex = 0,
    this.padding = const EdgeInsets.all(20),
  });

  final String leftLabel;
  final String rightLabel;
  final Widget leftChild;
  final Widget rightChild;

  final double cardWidth;
  final double cardMinHeight;
  final double cardRadius;
  final Color cardColor;
  final List<BoxShadow> shadow;
  final double spacing;
  final double toggleWidth;
  final double toggleHeight;
  final Duration duration;
  final int initialIndex;
  final EdgeInsets padding;

  @override
  State<TabCardSources> createState() => _TabCardSourcesState();
}

class _TabCardSourcesState extends State<TabCardSources> {
  late int _index = widget.initialIndex.clamp(0, 1);

  @override
  Widget build(BuildContext context) {

    // final Color accent = _index == 0 ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // top-left placement
      children: [
        // The rectangular switcher
        RectToggle(
          leftLabel: widget.leftLabel,
          rightLabel: widget.rightLabel,
          selectedIndex: _index,
          width: widget.toggleWidth,
          height: widget.toggleHeight,
          onChanged: (i) => setState(() => _index = i),
        ),
        SizedBox(height: widget.spacing),

        // The card with animated content swap
          AnimatedContainer(
                duration: widget.duration,
                curve: Curves.easeOutCubic,
                width: widget.cardWidth,
                constraints: BoxConstraints(minHeight: widget.cardMinHeight),
                decoration: BoxDecoration(
                  color: widget.cardColor,
                  borderRadius: BorderRadius.circular(widget.cardRadius),
                  boxShadow: [
                    // colored “glow” that follows the switcher
                    // BoxShadow(
                    //   color: accent.withAlpha(30),
                    //   blurRadius: 28,
                    //   spreadRadius: 2,
                    //   offset: const Offset(0, 14),
                    // ),
                    // subtle base shadow to keep depth consistent
                    BoxShadow(
                      color: Colors.black.withAlpha(100),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: widget.padding,
                  child: AnimatedSwitcher(
                    duration: widget.duration,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, anim) {
                      final isLeft = child.key == const ValueKey('left');
                      final begin = Offset(isLeft ? -0.06 : 0.06, 0);
                      return FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: anim.drive(
                            Tween(begin: begin, end: Offset.zero)
                                .chain(CurveTween(curve: Curves.easeOutCubic)),
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: _index == 0
                        ? _CardContent(key: const ValueKey('left'), child: widget.leftChild)
                        : _CardContent(key: const ValueKey('right'), child: widget.rightChild),
                  ),
                ),
              ),
      ],
    );
  }
}

// Keeps padding/keys clean inside AnimatedSwitcher
class _CardContent extends StatelessWidget {
  const _CardContent({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}
