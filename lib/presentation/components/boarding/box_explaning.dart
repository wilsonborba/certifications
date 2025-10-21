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
    this.cardColor = Colors.transparent, // near-black
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: img,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Make sure text never goes under the image by padding the right side.
    final EdgeInsets resolvedPadding = padding.resolve(Directionality.of(context));
    final contentRightPadding = resolvedPadding.right + imageSize * 0.6;

    

    return Container(
      margin: margin,
      width: width,
      height: height,
 
      child: Center( child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Base card with accent "shadow" border
          Container(
            width: width - 100,
            height: height - 200,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.black,
                width: accentThickness,
              ),
              boxShadow: boxShadow,
              
            ),
            child: Stack(
              children: [
                // Accent strip (like the green underglow)
                Positioned(
                  right: 0,
                  bottom: 8,
                  left: 8,
                  child: Container(
                    height: height - 200,
                    width: width - 300,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                  ),
                ),
                // Card content
                Padding(
                  padding: EdgeInsets.only(
                    left: resolvedPadding.left,
                    top: resolvedPadding.top,
                    right: contentRightPadding,
                    bottom: resolvedPadding.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Title
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Body
                      Padding(
                        padding: EdgeInsets.only(left: 20, top: 10),
                        child:  LayoutBuilder(
                          builder: (context, constraints) {
                            // If parent is unconstrained (e.g. inside a horizontal scroller),
                            // fall back to the screen width so Text gets a finite max width.
                            final maxW = constraints.maxWidth.isFinite
                                ? constraints.maxWidth
                                : MediaQuery.of(context).size.width;

                            return ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: maxW),
                              child: Text(
                                body,
                                softWrap: true,
                                maxLines: null,                // allow multiple lines
                                overflow: TextOverflow.visible,
                                textAlign: TextAlign.left,
                                textWidthBasis: TextWidthBasis.parent,
                                style: TextStyle(
                                  fontSize: bodySize,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black, // or .withOpacity(0.9)
                                  height: 1.35,
                                ),
                              ),
                            );
                          },
                      )),
                    ],
                  ),
                ),
                
              ],
            ),
          ),

          Positioned(
            top: imageOffset,
            right: imageOffset,
            child:  _buildImage(),
            
          ),
          
        ],
      )),
    );
  }
}