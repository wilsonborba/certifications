import 'dart:collection';
import 'package:accredit/domain/models/source_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

String _prettyTitle(String raw) {
    // "movies_and_series" -> "Movies And Series"
    final s = raw.replaceAll('_', ' ').trim();
    if (s.isEmpty) return raw;
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      final lower = w.toLowerCase();
      return '${lower[0].toUpperCase()}${lower.substring(1)}';
    }).join(' ');
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
    this.rowSpacing = 12,
    this.tileSpacing = 12,
    this.titleTextStyle = const TextStyle(
      fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
    this.dividerColor = const Color(0x22000000),
    this.dividerThickness = 1,
  });

  final List<SourceItem> items;
  final ItemTap onTapWithTopic;
  final ItemTap onTapWithoutTopic;
  final SeeMoreTap onSeeMore;

  final int maxPerRow;                 // show up to N tiles, then a "See more"
  final double tileSize;               // square tile (w = h)
  final double tileRadius;             // rounded corners
  final double sectionSpacing;         // gap between sections
  final double rowSpacing;             // gap between title/divider/row
  final double tileSpacing;            // gap between tiles in row
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
      children.add(Divider(
        height: dividerThickness, thickness: dividerThickness, color: dividerColor,
      ));
      children.add(SizedBox(height: rowSpacing));

      // row of up to maxPerRow tiles + optional "See more"
      final showCount = groupItems.length.clamp(0, maxPerRow);
      final rowTiles = <Widget>[];

      for (var i = 0; i < showCount; i++) {
        final item = groupItems[i];
        rowTiles.add(_SourceTile(
          item: item,
          size: tileSize,
          radius: tileRadius,
          onTap: () => (item.hasTopic ? onTapWithTopic : onTapWithoutTopic)(item),
        ));
        if (i != showCount - 1) rowTiles.add(SizedBox(width: tileSpacing));
      }

      // add "See more" if there are more than maxPerRow
      if (groupItems.length > maxPerRow) {
        if (rowTiles.isNotEmpty) rowTiles.add(SizedBox(width: tileSpacing));
        rowTiles.add(_SeeMoreTile(
          size: tileSize,
          radius: tileRadius,
          onTap: () => onSeeMore(source),
        ));
      }

      children.add(SingleChildScrollView(
        scrollDirection: Axis.horizontal,   // if row overflows, allow manual scroll
        child: Row(children: rowTiles),
      ));
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
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
      onExit:  (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
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
                      maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13,
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
                        color: _hover ? scheme.primary : Colors.transparent, width: 2),
                      borderRadius: BorderRadius.circular(widget.radius),
                    ),
                  ),
                ),
              ],
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
      color: scheme.surfaceContainerHighest ,
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
  const _NetworkImageAuto({
    required this.url,
    this.fit = BoxFit.contain,
  });

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
      url.startsWith('data:') &&
      url.toLowerCase().contains('image/svg+xml');

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
      errorBuilder: (c, e, s) =>
          const Center(child: Icon(Icons.broken_image, size: 32, color: Colors.black26)),
      loadingBuilder: (c, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
    );
  }
}