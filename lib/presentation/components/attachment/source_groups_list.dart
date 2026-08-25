import 'dart:collection';
import 'package:accredit/domain/models/source_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

String _prettyTitle(String raw) {
  // "movies_and_series" -> "Movies And Series"
  final s = raw.replaceAll('_', ' ').trim();
  if (s.isEmpty) return raw;
  return s
      .split(' ')
      .map((w) {
        if (w.isEmpty) return w;
        final lower = w.toLowerCase();
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .join(' ');
}

typedef ItemTap = void Function(SourceItem item);
typedef SeeMoreTap = void Function(String sourceName);

class SourceGroupsList extends StatelessWidget {
  const SourceGroupsList({
    super.key,
    required this.items,
    required this.onTapWithTopic,
    required this.onTapWithoutTopic,
    required this.onSeeMore,
    this.maxPerRow = 3,
    this.tileSize = 96,
    this.tileRadius = 16,
    this.sectionSpacing = 28,
    this.rowSpacing = 20,
    this.tileSpacing = 12,
    this.titleTextStyle = const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: Colors.black87,
    ),
    this.dividerColor = const Color(0x22000000),
    this.dividerThickness = 1,
  });

  final List<SourceItem> items;
  final ItemTap onTapWithTopic;
  final ItemTap onTapWithoutTopic;
  final SeeMoreTap onSeeMore;

  final int maxPerRow;
  final double tileSize;
  final double tileRadius;
  final double sectionSpacing;
  final double rowSpacing;
  final double tileSpacing;
  final TextStyle titleTextStyle;
  final Color dividerColor;
  final double dividerThickness;

  @override
  Widget build(BuildContext context) {
    // Group in insertion order by sourceName
    final groups = LinkedHashMap<String, List<SourceItem>>();
    for (final it in items) {
      groups.putIfAbsent(it.sourceName, () => <SourceItem>[]).add(it);
    }

    final children = <Widget>[];
    var first = true;

    groups.forEach((source, groupItems) {
      if (!first) children.add(SizedBox(height: sectionSpacing));
      first = false;

      children.add(Text(_prettyTitle(source), style: titleTextStyle));
      children.add(SizedBox(height: rowSpacing * 0.5));
      children.add(
        Divider(
          height: dividerThickness,
          thickness: dividerThickness,
          color: dividerColor,
        ),
      );
      children.add(SizedBox(height: rowSpacing));

      // NEW: stateful, animated, infinite “carousel” row:
      children.add(
        _GroupCarouselRow(
          sourceName: source,
          items: groupItems,
          maxPerRow: maxPerRow,
          tileSpacing: tileSpacing,
          tileSize: tileSize,
          tileRadius: tileRadius,
          onTapWithTopic: onTapWithTopic,
          onTapWithoutTopic: onTapWithoutTopic,
          onSeeMore: onSeeMore, // still exposed; we call it after rotating
        ),
      );
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _GroupCarouselRow extends StatefulWidget {
  const _GroupCarouselRow({
    required this.sourceName,
    required this.items,
    required this.maxPerRow,
    required this.tileSpacing,
    required this.tileSize,
    required this.tileRadius,
    required this.onTapWithTopic,
    required this.onTapWithoutTopic,
    required this.onSeeMore,
  });

  final String sourceName;
  final List<SourceItem> items;
  final int maxPerRow;
  final double tileSpacing;
  final double tileSize;
  final double tileRadius;
  final ItemTap onTapWithTopic;
  final ItemTap onTapWithoutTopic;
  final SeeMoreTap onSeeMore;

  @override
  State<_GroupCarouselRow> createState() => _GroupCarouselRowState();
}

class _GroupCarouselRowState extends State<_GroupCarouselRow> {
  int _offset = 0;

  List<SourceItem> _windowed() {
    final list = widget.items;
    final n = list.length;
    final m = widget.maxPerRow.clamp(0, n);
    if (n <= widget.maxPerRow) return List<SourceItem>.from(list);

    final out = <SourceItem>[];
    for (var i = 0; i < m; i++) {
      out.add(list[(_offset + i) % n]);
    }
    return out;
  }

  void _advance() {
    final n = widget.items.length;
    if (n == 0) return;
    if (n <= widget.maxPerRow) return; // nothing to rotate

    setState(() {
      _offset = (_offset + widget.maxPerRow) % n;
    });

    // Optional: still let parent know a "see more" happened.
    // You can remove this if you don't want the external callback.
    widget.onSeeMore(widget.sourceName);
  }

  Widget _buildScrollableRow(List<SourceItem> visible, {Key? key}) {
    final rowTiles = <Widget>[];
    for (var i = 0; i < visible.length; i++) {
      final item = visible[i];
      rowTiles.add(
        _SourceTile(
          item: item,
          size: widget.tileSize,
          radius: widget.tileRadius,
          onTap: () => (item.hasTopic
              ? widget.onTapWithTopic
              : widget.onTapWithoutTopic)(item),
        ),
      );
      if (i != visible.length - 1) {
        rowTiles.add(
          SizedBox(width: widget.tileSpacing, height: widget.tileSpacing),
        );
      }
    }

    final canRotate = widget.items.length > widget.maxPerRow;
    if (canRotate) {
      if (rowTiles.isNotEmpty) {
        rowTiles.add(
          SizedBox(width: widget.tileSpacing, height: widget.tileSpacing),
        );
      }
      rowTiles.add(
        _SeeMoreTile(
          size: widget.tileSize,
          radius: widget.tileRadius,
          onTap: _advance,
        ),
      );
    }

    // IMPORTANT: add outer padding & fixed height to avoid shadow clipping
    // and provide breathing room around rounded icons.
    return Padding(
      key: key,
      padding: EdgeInsets.symmetric(
        horizontal: widget.tileSpacing, // side gutter
        vertical: widget.tileSpacing, // top/bottom gutter
      ),
      child: SizedBox(
        height: widget.tileSize + widget.tileSpacing * 2, // room for shadows
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: rowTiles),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _windowed();

    // Build the row tiles for the current window
    final rowTiles = <Widget>[];
    for (var i = 0; i < visible.length; i++) {
      final item = visible[i];
      rowTiles.add(
        _SourceTile(
          item: item,
          size: widget.tileSize,
          radius: widget.tileRadius,
          onTap: () => (item.hasTopic
              ? widget.onTapWithTopic
              : widget.onTapWithoutTopic)(item),
        ),
      );
      if (i != visible.length - 1) {
        rowTiles.add(
          SizedBox(width: widget.tileSpacing, height: widget.tileSpacing),
        );
      }
    }

    // Append an always-present See More tile only when rotation makes sense
    final canRotate = widget.items.length > widget.maxPerRow;
    if (canRotate) {
      if (rowTiles.isNotEmpty)
        rowTiles.add(
          SizedBox(width: widget.tileSpacing, height: widget.tileSpacing),
        );
      rowTiles.add(
        _SeeMoreTile(
          size: widget.tileSize,
          radius: widget.tileRadius,
          onTap: _advance,
        ),
      );
    }

    // Animate the “shift left” using AnimatedSwitcher
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (child, anim) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeInOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.12, 0), // small, silky slide from right
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      // Stack previous + current instead of replacing layout abruptly.
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.centerLeft,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      child: _buildScrollableRow(visible, key: ValueKey<int>(_offset)),
    );
  }
}

class _SourceTile extends StatefulWidget {
  const _SourceTile({
    required this.item,
    required this.size,
    required this.radius,
    required this.onTap,
  });

  final SourceItem item;
  final double size;
  final double radius;
  final VoidCallback onTap;

  @override
  State<_SourceTile> createState() => _SourceTileState();
}

class _SourceTileState extends State<_SourceTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: Padding(
        // NEW: space so the shadow can render fully
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Material(
          color: Colors.white,
          elevation: _hover ? 6 : 3,
          borderRadius: BorderRadius.circular(widget.radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _NetworkImageAuto(url: widget.item.itemImg),
                  // hover overlay with name
                  AnimatedOpacity(
                    opacity: _hover ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 140),
                    child: Container(
                      color: Colors.black.withAlpha(100),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        _prettyTitle(widget.item.itemName),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  // subtle border to signal interactivity
                  IgnorePointer(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _hover ? scheme.primary : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(widget.radius),
                      ),
                    ),
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

class _SeeMoreTile extends StatelessWidget {
  const _SeeMoreTile({
    required this.size,
    required this.radius,
    required this.onTap,
  });

  final double size;
  final double radius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Text(
              'See\nmore',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NetworkImageAuto extends StatelessWidget {
  const _NetworkImageAuto({required this.url, this.fit = BoxFit.contain});

  final String url;
  final BoxFit fit;

  // Decide by the LAST extension in the PATH (ignores query params).
  bool get _isSvgByExt {
    final uri = Uri.tryParse(url);
    final path = (uri?.path ?? url).trim();
    final file = path.split('/').isNotEmpty ? path.split('/').last : path;
    final dot = file.lastIndexOf('.');
    if (dot == -1) return false;
    final ext = file.substring(dot + 1).toLowerCase(); // last extension wins
    return ext == 'svg' || ext == 'svgz';
  }

  // Also consider data URIs like: data:image/svg+xml;...
  bool get _isSvgByDataUri =>
      url.startsWith('data:') && url.toLowerCase().contains('image/svg+xml');

  bool get _isSvg => _isSvgByExt || _isSvgByDataUri;

  @override
  Widget build(BuildContext context) {
    if (_isSvg) {
      return SvgPicture.network(
        url,
        fit: fit,
        placeholderBuilder: (c) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (c, e, s) => const Center(
        child: Icon(Icons.broken_image, size: 32, color: Colors.black26),
      ),
      loadingBuilder: (c, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
    );
  }
}
