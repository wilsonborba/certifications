import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum BadgeImageSource { asset, network }

class BoxExplaning extends StatelessWidget {
  /// Title and body text
  final String title;
  final String body;
  final double width;
  final double height;

  /// Text sizes (you control them; they’re static)
  final double titleSize;
  final double bodySize;

  /// Card styling
  final Color cardColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final List<BoxShadow> boxShadow;

  /// Overlapping image (top-right)
  final String image;
  final bool isSvg;
  final BadgeImageSource imageSource;
  final double imageSize; // width & height
  final double imageOffset; // how much it hangs outside the card (px)
  final double imageInset;  // gap from the top-right corner inside the Stack

  /// Optional little accent border under the card (like your green edge)
  final Color accentColor;
  final double accentThickness;

  const BoxExplaning({
    super.key,
    required this.title,
    required this.body,
    required this.image,
    required this.accentColor,
    this.width = 400,
    this.height = 250,
    this.isSvg = false,
    this.imageSource = BadgeImageSource.asset,
    this.titleSize = 20,
    this.bodySize = 14,
    this.cardColor = Colors.transparent,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 16),
    this.margin = const EdgeInsets.all(0),
    this.boxShadow = const [
      BoxShadow(
        blurRadius: 12,
        offset: Offset(0, 6),
        color: Colors.transparent,
      ),
    ],
    this.imageSize = 52,
    this.imageOffset = 6,
    this.imageInset = 8,
    this.accentThickness = 2,
  });

  Widget _buildImage() {
    final Widget img;
    if (isSvg) {
      img = imageSource == BadgeImageSource.asset
          ? SvgPicture.asset(image, width: imageSize, height: imageSize)
          : SvgPicture.network(image, width: imageSize, height: imageSize);
    } else {
      img = imageSource == BadgeImageSource.asset
          ? Image.asset(image, width: imageSize, height: imageSize)
          : Image.network(image, width: imageSize, height: imageSize);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        // boxShadow: [
        //   // soft halo behind image
        //   BoxShadow(
        //     color: Colors.black.withAlpha((0.08 * 255).toInt()),
        //     blurRadius: 14,
        //     offset: const Offset(0, 6),
        //   ),
        // ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: img,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Resolve incoming padding (so we can add image-aware padding on the right)
    final EdgeInsets resolvedPadding = padding.resolve(Directionality.of(context));

    // Make sure text never collides under the image:
    // reserve space on the right approximately proportional to image width.
    final double reservedRight =
        (imageSize * 0.70) + resolvedPadding.right + imageInset;

    // Colors (youthful + tactile)
    final Color glassFill = cs.surface.withAlpha((0.75 * 255).toInt()); // soft white
    final Color hairlineA = cs.primary.withAlpha((0.70 * 255).toInt());
    final Color hairlineB = cs.primary.withAlpha((0.35 * 255).toInt());
    final Color innerStroke = Colors.white.withAlpha((0.65 * 255).toInt());
    final Color titleColor = cs.onSurface;  // black-ish
    final Color bodyColor = cs.onSurface.withAlpha((0.82 * 255).toInt());

    // We fake a gradient border by nesting containers:
    // [Gradient shell] -> padding(1) -> [Glass card]
    final double shellRadius = borderRadius;

    return Container(
      margin: margin,
      width: width,
      height: height,
      // keep parent transparent to preserve your “transparent vibe”
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Accent underglow (your "linear border" vibe) — thin, blurred, and subtle.
          Positioned(
            left: 14,
            right: 14,
            bottom: -8,
            child: IgnorePointer(
              child: Container(
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      accentColor.withAlpha((0.0 * 255).toInt()),
                      (accentColor == Colors.transparent
                              ? cs.primary
                              : accentColor)
                          .withAlpha((0.35 * 255).toInt()),
                      accentColor.withAlpha((0.0 * 255).toInt()),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (accentColor == Colors.transparent
                              ? cs.primary
                              : accentColor)
                          .withAlpha((0.25 * 255).toInt()),
                      blurRadius: 20,
                      spreadRadius: -2,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Gradient shell (1px) → inner glass card
          ClipRRect(
            borderRadius: BorderRadius.circular(shellRadius),
            child: Stack(
              children: [
                // Gradient shell (acts like a 1–1.5px border)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [hairlineA, hairlineB],
                    ),
                  ),
                ),

                // Inner "glass" card with blur and subtle inner stroke
                Padding(
                  padding: const EdgeInsets.all(1.2), // shell thickness
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(borderRadius),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: glassFill,
                          borderRadius: BorderRadius.circular(borderRadius),
                          border: Border.all(
                            color: innerStroke, // hairline inner stroke
                            width: 0.8,
                          ),
                          boxShadow: [
                            // soft elevation
                            BoxShadow(
                              color: Colors.black.withAlpha((0.06 * 255).toInt()),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                            // gentle highlight to feel tactile
                            BoxShadow(
                              color: Colors.white.withAlpha((0.65 * 255).toInt()),
                              blurRadius: 6,
                              spreadRadius: -2,
                              offset: const Offset(-1, -1),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: resolvedPadding.left,
                            top: resolvedPadding.top,
                            right: reservedRight,
                            bottom: resolvedPadding.bottom,
                          ),
                          child: _CardContent(
                            title: title,
                            body: body,
                            titleSize: titleSize,
                            bodySize: bodySize,
                            titleColor: titleColor,
                            bodyColor: bodyColor,
                            primary: cs.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Top-right image — exact position using your offsets
          Positioned(
            top: imageOffset,
            right: imageOffset,
            child:  _buildImage(),
            
          ),
        ],
      ),
    );
  }
}

/// The inner column: accent bar + title + body
class _CardContent extends StatelessWidget {
  final String title;
  final String body;
  final double titleSize;
  final double bodySize;
  final Color titleColor;
  final Color bodyColor;
  final Color primary;

  const _CardContent({
    required this.title,
    required this.body,
    required this.titleSize,
    required this.bodySize,
    required this.titleColor,
    required this.bodyColor,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cons) {
        // Extra guard: inside horizontal scrollers, width can be unconstrained.
        final maxW = cons.maxWidth.isFinite ? cons.maxWidth : MediaQuery.of(context).size.width;

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // tiny accent bar
              Container(
                height: 4,
                width: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [
                      primary.withAlpha((0.95 * 255).toInt()),
                      primary.withAlpha((0.55 * 255).toInt()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                title,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  color: titleColor,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),

              Text(
                body,
                softWrap: true,
                maxLines: null,
                overflow: TextOverflow.visible,
                textAlign: TextAlign.left,
                textWidthBasis: TextWidthBasis.parent,
                style: TextStyle(
                  fontSize: bodySize,
                  fontWeight: FontWeight.w500,
                  height: 1.38,
                  color: bodyColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
