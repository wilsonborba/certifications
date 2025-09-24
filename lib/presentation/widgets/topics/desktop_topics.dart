import 'package:accredit/presentation/widgets/topics/base_topics.dart';
import 'package:accredit/core/utils/my_nagivation.dart';
import 'package:flutter/material.dart';

class DesktopTopics extends BaseTopics {
  const DesktopTopics({super.key, required String itemName})
      : super(itemName: itemName);

  @override
  State<DesktopTopics> createState() => _DesktopTopicsState();
}

class _DesktopTopicsState extends BaseTopicsState<DesktopTopics> {
  int _page = 1;
  int _perPage = 8;
  bool _hasMore = true;
  bool _loading = false;
  bool _initialDone = false;

  // Keep last rendered grid height so the spinner can occupy same space
  final GlobalKey _gridKey = GlobalKey();
  double _lastGridHeight = 0;

  List<Map<String, dynamic>> _topics = const [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final saved = await loadSavedPageOr1(widget.itemName);
    _page = saved;
    await _loadPage(_page);
  }

  Future<void> _loadPage(int page) async {
    if (_loading) return;

    setState(() => _loading = true);
    try {
      final (raw, pg, pp, hm) = await loadOrFetchTopicsPage(
        widget.itemName,
        page: page,
        perPage: _perPage,
      );

      final valid = raw
          .where((t) => shouldUseIdentifications(getTopicIdentifications(t)))
          .toList();

      if (!mounted) return;
      setState(() {
        _topics = valid;               // replace page (no append)
        _page   = pg ?? page;
        _perPage = pp ?? _perPage;
        _hasMore = hm;
        _initialDone = true;
      });

      await saveCurrentPage(widget.itemName, _page);

      // After the grid is on screen, remember its height for future spinners
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctx = _gridKey.currentContext;
        final h = ctx?.size?.height ?? 0;
        if (h > 0 && (_lastGridHeight - h).abs() > 0.1) {
          setState(() => _lastGridHeight = h);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initialDone = true; // stop initial infinite spinner on error
      });
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _loadPrev() {
    if (_loading) return;
    if (_page <= 1) return;
    _loadPage(_page - 1);
  }

  void _loadNext() {
    if (_loading) return;
    if (!_hasMore) return;
    _loadPage(_page + 1);
  }

  @override
  Widget build(BuildContext context) {
    final header = Column(
      children: const [
        SizedBox(height: 40),
        Text('Topics', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Divider(height: 1, thickness: 1, indent: 120, endIndent: 120),
        SizedBox(height: 24),
      ],
    );

    final initialLoading = Column(
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text('Loading topics, please wait...', style: TextStyle(fontSize: 16)),
        ),
        SizedBox(height: 16),
        SizedBox(height: 32, width: 32, child: CircularProgressIndicator()),
        SizedBox(height: 24),
      ],
    );

    final emptyState = const Padding(
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 40),
      child: Text(
        'No topics available right now, please check back later, or contact support@asodya.com',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
    );

    // The grid of cards (non-scrollable; page replacement only)
    final grid = Padding(
      key: _gridKey,
      padding: const EdgeInsets.symmetric(horizontal: 400, vertical: 30),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _topics.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
          crossAxisSpacing: 0.0,
          mainAxisSpacing: 12,
          mainAxisExtent: 180,
        ),
        itemBuilder: (ctx, i) {
          final t = _topics[i];
          final ident = getTopicIdentifications(t)!; // already validated
          final title = ident.titleIdentification!;
          final link  = ident.linkIdentification!;
          final img   = safeImageFromIdent(ident); // nullable

          return _TopicCard(
            title: title,
            about: 'About',
            link: link,
            imageUrl: img,
          );
        },
      ),
    );

    // If we are loading a new page AND already have a grid height,
    // show a fixed-height placeholder with a centered spinner to avoid layout jump.
    final gridLoadingPlaceholder = (_loading && _topics.isNotEmpty && _lastGridHeight > 0)
        ? SizedBox(
            height: _lastGridHeight,
            child: const Center(
              child: SizedBox(height: 28, width: 28, child: CircularProgressIndicator()),
            ),
          )
        : const SizedBox.shrink();

    final footer = Column(
      children: [
        const SizedBox(height: 24),
        const Divider(height: 1, thickness: 1, indent: 120, endIndent: 120),
        const SizedBox(height: 10),
        // Two buttons side-by-side: PREV | NEXT
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: (_loading || _page <= 1) ? null : _loadPrev,
              icon: const Icon(Icons.arrow_upward, size: 18),
              label: const Text('Load previous page'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(160, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: (_loading || !_hasMore) ? null : _loadNext,
              icon: const Icon(Icons.arrow_downward, size: 18),
              label: const Text('Load next page'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(160, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              header,

              // 1) Initial loading (first ever load)
              if (!_initialDone && _topics.isEmpty) initialLoading,

              // 2) Empty state (after first load)
              if (_initialDone && _topics.isEmpty && !_loading) emptyState,

              // 3) Grid or fixed-height spinner while a new page is loading
              if (_topics.isNotEmpty && !_loading) grid,
              if (_topics.isNotEmpty && _loading) gridLoadingPlaceholder,

              // 4) Footer with Prev/Next buttons
              footer,
            ],
          ),
        ),
      ),
    );
  }
}

/// Card stays the same, including redirectToUrl(link, replace: false)
class _TopicCard extends StatefulWidget {
  final String title;
  final String about;
  final String link;
  final String? imageUrl;

  const _TopicCard({
    required this.title,
    required this.about,
    required this.link,
    required this.imageUrl,
  });

  @override
  State<_TopicCard> createState() => _TopicCardState();
}

class _TopicCardState extends State<_TopicCard> {
  bool _imageOk = false;
  ImageProvider? _provider;

  @override
  void initState() {
    super.initState();
    _prepareProvider();
  }

  @override
  void didUpdateWidget(covariant _TopicCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _prepareProvider();
    }
  }

  void _prepareProvider() {
    _imageOk = false;
    final url = widget.imageUrl?.trim();
    if (url == null || url.isEmpty || !_isValidHttpUrl(url)) {
      _provider = null;
      return;
    }
    _provider = NetworkImage(url);
  }

  bool _isValidHttpUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
  }

  // preload to confirm successful render before showing on the right side
  Widget _preloadImage() {
    if (_provider == null) return const SizedBox.shrink();
    return Image(
      image: _provider!,
      width: 0,
      height: 0,
      frameBuilder: (context, child, frame, wasSync) {
        if (frame != null && !_imageOk) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _imageOk = true);
          });
        }
        return const SizedBox.shrink();
      },
      errorBuilder: (context, error, stack) {
        if (_imageOk && mounted) setState(() => _imageOk = false);
        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle =
        const TextStyle(fontSize: 18, fontWeight: FontWeight.w600);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _preloadImage(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle),
                  const SizedBox(height: 12),
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
                      FilledButton.icon(
                        onPressed: () =>
                            redirectToUrl(widget.link, replace: false),
                        icon: Icon(
                          Icons.remove_red_eye_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        label: Text(
                          'Visit',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                          minimumSize: const Size(80, 34),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_imageOk && _provider != null) ...[
              const SizedBox(width: 12),
              const VerticalDivider(width: 1, thickness: 1),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image(
                  image: _provider!,
                  width: 120,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
