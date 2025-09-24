import 'package:accredit/presentation/widgets/topics/base_topics.dart';
import 'package:accredit/core/utils/my_nagivation.dart';
import 'package:flutter/material.dart';

class MobileTopics extends BaseTopics {
  const MobileTopics({super.key, required String itemName})
      : super(itemName: itemName);

  @override
  State<MobileTopics> createState() => _MobileTopicsState();
}

class _MobileTopicsState extends BaseTopicsState<MobileTopics> {
  int _page = 1;
  int _perPage = 4; // tune for mobile; 8 or 10 works well vertically
  bool _hasMore = true;
  bool _loading = false;
  bool _initialDone = false;

  // Keep last grid height so spinner occupies same space
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
        _topics   = valid;         // replace, do not append
        _page     = pg ?? page;
        _perPage  = pp ?? _perPage;
        _hasMore  = hm;
        _initialDone = true;
      });

      await saveCurrentPage(widget.itemName, _page);

      // remember height after layout for smooth spinner swap
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final h = _gridKey.currentContext?.size?.height ?? 0;
        if (h > 0 && (_lastGridHeight - h).abs() > 0.1) {
          setState(() => _lastGridHeight = h);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initialDone = true; // stop “loading forever” on error
      });
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _loadPrev() {
    if (_loading || _page <= 1) return;
    _loadPage(_page - 1);
  }

  void _loadNext() {
    if (_loading || !_hasMore) return;
    _loadPage(_page + 1);
  }

  Widget _buildGrid(BuildContext context) {
    // Mobile = 1 column; compact padding; supports narrow screens and rotation
    return Padding(
      key: _gridKey,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(), // outer scroll drives
        itemCount: _topics.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          childAspectRatio: 1.0,
          crossAxisSpacing: 0.0,
          mainAxisSpacing: 12,
          mainAxisExtent: 180, // same card height as desktop for consistency
        ),
        itemBuilder: (ctx, i) {
          final t = _topics[i];
          final ident = getTopicIdentifications(t)!; // validated via filter
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
  }

  @override
  Widget build(BuildContext context) {
    final header = Column(
      children: const [
        SizedBox(height: 16),
        Text('Topics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
        SizedBox(height: 8),
      ],
    );

    final initialLoading = Column(
      children: const [
        Padding(
          padding: EdgeInsets.only(top: 24),
          child: Text('Loading topics, please wait...', style: TextStyle(fontSize: 14)),
        ),
        SizedBox(height: 16),
        SizedBox(height: 28, width: 28, child: CircularProgressIndicator()),
        SizedBox(height: 16),
      ],
    );

    final emptyState = const Padding(
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Text(
        'No topics available right now, please check back later,\n'
        'or contact support@asodya.com',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14),
      ),
    );

    final footer = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_loading || _page <= 1) ? null : _loadPrev,
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  label: const Text('Previous', style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_loading || !_hasMore) ? null : _loadNext,
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  label: const Text('Next', style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 248, 248),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: const Color(0xFF242424),

      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              header,

              if (!_initialDone && _topics.isEmpty) initialLoading,

              if (_initialDone && _topics.isEmpty && !_loading) emptyState,

              if (_topics.isNotEmpty && !_loading) _buildGrid(context),

              if (_topics.isNotEmpty && _loading)
                SizedBox(
                  height: _lastGridHeight > 0 ? _lastGridHeight : 180,
                  child: const Center(
                    child: SizedBox(height: 28, width: 28, child: CircularProgressIndicator()),
                  ),
                ),

              footer,
            ],
          ),
        ),
      ),
    );
  }
}

/// Reuse the same card from Desktop to keep behavior identical.
/// If you prefer a slightly smaller image on mobile, you can tweak the size here.
class _TopicCard extends StatefulWidget {
  final String title;
  final String about;   // static label "About"
  final String link;    // open in new tab / replace: false
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

  /// Invisible, non-interactive preloader so it never steals taps/hover.
  Widget _preloadImage() {
    if (_provider == null) return const SizedBox.shrink();

    return IgnorePointer(
      ignoring: true,
      child: Offstage(
        offstage: true,
        child: Image(
          image: _provider!,
          excludeFromSemantics: true,
          frameBuilder: (context, child, frame, wasSync) {
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
    final titleStyle = const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

    return Card(
      elevation: 2,
      color: const Color(0xFFFAFDFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _preloadImage(),
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
                  const SizedBox(height: 10),
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
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          minimumSize: const Size(80, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_imageOk && _provider != null) ...[
              const SizedBox(width: 10),
              const VerticalDivider(width: 1, thickness: 1),
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image(
                  image: _provider!,
                  width: 96,   // slightly smaller on mobile
                  height: 64,
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
