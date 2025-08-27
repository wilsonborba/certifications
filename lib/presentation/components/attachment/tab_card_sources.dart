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
    this.bgColor = const Color(0xFFE6E6E6),
    this.thumbColor = Colors.white,
    this.labelColor = const Color(0xFF444444),
    this.selectedLabelColor = Colors.black,
    this.borderColor = const Color(0x33000000),
    this.elevation = 3,
    this.duration = const Duration(milliseconds: 220),
  });

  final String leftLabel;
  final String rightLabel;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  final double width;
  final double height;
  final double radius;
  final Color bgColor;
  final Color thumbColor;
  final Color labelColor;
  final Color selectedLabelColor;
  final Color borderColor;
  final double elevation;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final Alignment thumbAlign =
        selectedIndex == 0 ? Alignment.centerLeft : Alignment.centerRight;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // Track
          Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: borderColor),
            ),
          ),

          // Sliding thumb
          AnimatedAlign(
            alignment: thumbAlign,
            duration: duration,
            curve: Curves.easeOutCubic,
            child: FractionallySizedBox(
              widthFactor: 0.5, // half of the track
              heightFactor: 1.0,
              child: Material(
                color: thumbColor,
                elevation: elevation,
                borderRadius: BorderRadius.circular(radius - 2),
                child: const SizedBox.expand(),
              ),
            ),
          ),

          // Two hit areas + labels
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
                        fontWeight:
                            selectedIndex == 0 ? FontWeight.w700 : FontWeight.w500,
                        color: selectedIndex == 0 ? selectedLabelColor : labelColor,
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
                        fontWeight:
                            selectedIndex == 1 ? FontWeight.w700 : FontWeight.w500,
                        color: selectedIndex == 1 ? selectedLabelColor : labelColor,
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
    this.cardColor = const Color(0xFFF4F4F4),
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
        Container(
          width: widget.cardWidth,
          constraints: BoxConstraints(minHeight: widget.cardMinHeight),
          decoration: BoxDecoration(
            color: widget.cardColor,
            borderRadius: BorderRadius.circular(widget.cardRadius),
            boxShadow: widget.shadow,
          ),
          child: Padding(
            padding: widget.padding,
            child: AnimatedSwitcher(
              duration: widget.duration,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) {
                // Slide + fade (left->right / right->left based on direction)
                final isLeft = child.key == const ValueKey('left');
                final begin = Offset(isLeft ? -0.06 : 0.06, 0);
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: anim.drive(Tween(begin: begin, end: Offset.zero)
                        .chain(CurveTween(curve: Curves.easeOutCubic))),
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
