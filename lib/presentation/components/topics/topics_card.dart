import 'package:flutter/material.dart';
import 'package:accredit/core/utils/my_nagivation.dart';

/// Reusable Topic card for both Desktop & Mobile.
/// Tweak layout with the optional sizing params.
class TopicsCard extends StatefulWidget {
  final String title;
  final String about;      // e.g., "About"
  final String link;       // open in new tab / replace: false
  final String? imageUrl;

  // Layout knobs so Desktop/Mobile can look slightly different without forking:
  final EdgeInsets padding;
  final double titleFontSize;
  final double titleFontWeight; // 600 → FontWeight.w600
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
    this.gap = 12,
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

            // LEFT: title + about/visit
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                  SizedBox(height: widget.gap),

                  Row(
                    children: [
                      Text(
                        widget.about,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => redirectToUrl(widget.link, replace: false),
                        icon: Icon(
                          Icons.remove_red_eye_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        label: Text(
                          'Visit',
                          style: TextStyle(
                            fontSize: (widget.titleFontSize - 4).clamp(12, 16).toDouble(),
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          minimumSize: Size(widget.buttonMinWidth, widget.buttonMinHeight),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // RIGHT: divider + image ONLY after the first frame renders
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
