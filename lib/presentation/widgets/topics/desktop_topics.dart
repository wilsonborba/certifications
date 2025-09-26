import 'package:accredit/presentation/widgets/topics/base_topics.dart';
import 'package:accredit/core/utils/my_nagivation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

/// DesktopTopics renders the topics grid for desktop layout
/// and provides a search bar that behaves like the paginated topics:
/// - Same pagination (prev/next)
/// - Uses the same backend (/topics and /search routes)
/// - Uses BaseTopicsState helpers (incl. 15-min search cache if you added them)
/// - Shows a rotating loading message for *non-initial* loads
class DesktopTopics extends BaseTopics {
  const DesktopTopics({super.key, required String itemName})
      : super(itemName: itemName);

  @override
  State<DesktopTopics> createState() => _DesktopTopicsState();
}

class _DesktopTopicsState extends BaseTopicsState<DesktopTopics> {
  // --- paging state ---
  int _page = 1;
  int _perPage = 8;
  bool _hasMore = true;
  bool _loading = false;
  bool _initialDone = false;

  // --- search state ---
  final TextEditingController _qCtrl = TextEditingController();
  bool _searchMode = false; // when true, paging loads search pages
  String _query = '';

  // Keep last rendered grid height so the loading spinner can occupy same space
  final GlobalKey _gridKey = GlobalKey();
  double _lastGridHeight = 0;

  // Current page items to render
  List<Map<String, dynamic>> _topics = const [];

  // --- non-initial loading phrase ticker ---
  Timer? _loadingTicker;
  int _loadingIndex = 0;
  final List<String> _loadingPhrases = const [
    'Fetching topics…',
    'Some topics take longer to load…',
    'Checking availability…',
    'Still working on it…',
    'Almost there…',
  ];

  void _startLoadingTickerIfNeeded() {
    // Only show ticker for *non-initial* loads (i.e., when we already showed the big initial banner)
    if (!_initialDone) return;
    _loadingTicker?.cancel();
    _loadingIndex = 0;
    _loadingTicker = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() {
        _loadingIndex = (_loadingIndex + 1) % _loadingPhrases.length;
      });
    });
  }

  void _stopLoadingTicker() {
    _loadingTicker?.cancel();
    _loadingTicker = null;
    _loadingIndex = 0;
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    _stopLoadingTicker();
    super.dispose();
  }

  /// Initial load: restore last saved page for the current item and fetch it.
  Future<void> _bootstrap() async {
    final saved = await loadSavedPageOr1(widget.itemName);
    _page = saved;
    await _loadPage(_page);
  }

  /// Load a topics page (non-search flow).
  Future<void> _loadPage(int page) async {
    if (_loading) return;

    setState(() => _loading = true);
    _startLoadingTickerIfNeeded();
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

      // Persist the last non-search page so we can restore later.
      await saveCurrentPage(widget.itemName, _page);

      // After the grid is on screen, remember its height for future spinners.
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
      _stopLoadingTicker();
      setState(() => _loading = false);
    }
  }

  /// Load a search page (search flow).
  /// Uses BaseTopicsState.loadOrFetchSearchPage(...) which caches results for 15 minutes.
  Future<void> _loadSearchPage(int page) async {
    if (_loading) return;

    setState(() => _loading = true);
    _startLoadingTickerIfNeeded();
    try {
      final (raw, pg, pp, hm) = await loadOrFetchSearchPage(
        widget.itemName,
        query: _query,
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

      // Persist last search page for this item/query (15-minute TTL).
      await saveSearchCurrent(widget.itemName, query: _query, page: _page);

      // Keep spinner height consistent with grid height.
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
      _stopLoadingTicker();
      setState(() => _loading = false);
    }
  }

  /// Pagination: previous page (respects search mode).
  void _loadPrev() {
    if (_loading) return;
    if (_page <= 1) return;
    if (_searchMode) {
      _loadSearchPage(_page - 1);
    } else {
      _loadPage(_page - 1);
    }
  }

  /// Pagination: next page (respects search mode).
  void _loadNext() {
    if (_loading) return;
    if (!_hasMore) return;
    if (_searchMode) {
      _loadSearchPage(_page + 1);
    } else {
      _loadPage(_page + 1);
    }
  }

  /// Start search from the query field; resets page to 1.
  void _startSearch() {
    final q = _qCtrl.text.trim();
    if (q.isEmpty || _loading) return;
    setState(() {
      _searchMode = true;
      _query = q;
      _page = 1; // reset page for the new query
    });
    _loadSearchPage(1);
  }

  /// Clear active search and return to the topics flow (page 1).
  void _clearSearch() {
    if (_loading) return;
    setState(() {
      _searchMode = false;
      _query = '';
      _qCtrl.clear();
      _page = 1;
    });
    _loadPage(1);
  }

  /// Header: stacked title (with side lines) and search row below it.
  Widget _buildHeaderBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 40, left: 24, right: 24, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // TOP: lines + "Topics" + lines (full width)
          Row(
            children: const [
              Expanded(child: Divider(height: 1, thickness: 1)),
              SizedBox(width: 12),
              Text(
                'Topics',
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 12),
              Expanded(child: Divider(height: 1, thickness: 1)),
            ],
          ),

          const SizedBox(height: 24),

          // BOTTOM: search field + Search button (+ Clear) stacked under the title
          // Centered with a max width for better desktop readability.
          Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Row(
                children: [
                  // Search text field expands to take available width
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: TextField(
                        controller: _qCtrl,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _startSearch(),
                        decoration: const InputDecoration(
                          hintText: 'Search topics…',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Search button
                  SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _startSearch,
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('Search'),
                    ),
                  ),
                  // Optional "Clear" button when in search mode
                  if (_searchMode) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Clear'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Responsive grid with 2 columns on wide screens and 1 on narrow screens.
  Widget _buildGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final bool isNarrow = maxW < 1100; // tune this threshold if desired
        final int columns = isNarrow ? 1 : 2;

        return Padding(
          key: _gridKey,
          padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 30),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // outer scroll drives
            itemCount: _topics.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Initial loading state (first ever load)
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

    // Empty state after initial load
    final emptyState = const Padding(
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 40),
      child: Text(
        'No topics available right now, please check back later, or contact support@asodya.com',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
    );

    // Footer with Prev / Next pagination buttons + page window
    final startIndex = ((_page - 1) * _perPage) + (_topics.isEmpty ? 0 : 1);
    final endIndex   = startIndex + _topics.length - (_topics.isEmpty ? 0 : 1);

    final footer = Column(
      children: [
        const SizedBox(height: 24),
        const Divider(height: 1, thickness: 1, indent: 120, endIndent: 120),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Prev
            ElevatedButton.icon(
              onPressed: (_loading || _page <= 1) ? null : _loadPrev,
              icon: const Icon(Icons.arrow_upward, size: 14),
              label: const Text('Load previous page', style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(80, 60),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),

            const SizedBox(width: 16),

            // Center page info (current page + item window)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.transparent),
                color: const Color(0xFFF7F7F7),
              ),
              child: Text(
                _topics.isEmpty
                    ? 'Page $_page'
                    : 'Page $_page | Items $startIndex–$endIndex',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(width: 16),

            // Next
            ElevatedButton.icon(
              onPressed: (_loading || !_hasMore) ? null : _loadNext,
              icon: const Icon(Icons.arrow_downward, size: 14),
              label: const Text('Load next page', style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(80, 60),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 80),
      ],
    );

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 248, 248),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: const Color.fromARGB(255, 36, 36, 36),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with stacked title + search
              _buildHeaderBar(),

              // 1) Initial loading (first ever load)
              if (!_initialDone && _topics.isEmpty) initialLoading,

              // 2) Empty state (after first load)
              if (_initialDone && _topics.isEmpty && !_loading) emptyState,

              // 3) Grid or fixed-height spinner while a new page is loading
              if (_topics.isNotEmpty && !_loading) _buildGrid(context),

              if (_topics.isNotEmpty && _loading)
                SizedBox(
                  height: _lastGridHeight > 0 ? _lastGridHeight : 180,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 28, width: 28, child: CircularProgressIndicator()),
                          const SizedBox(height: 12),
                          // Non-initial rotating phrases
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, .25),
                                  end: Offset.zero,
                                ).animate(anim),
                                child: child,
                              ),
                            ),
                            child: Text(
                              _loadingPhrases[_loadingIndex],
                              key: ValueKey<int>(_loadingIndex),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 4) Footer with Prev/Next buttons + page info
              footer,
            ],
          ),
        ),
      ),
    );
  }
}

/// Single topic card with title, "About", Visit button, and an optional image.
/// The image is only shown after the first frame is available (lightweight preloader).
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

  /// Invisible, non-interactive preloader that still lets us detect when
  /// the first frame is available. It **does not** paint or receive clicks.
  Widget _preloadImage() {
    if (_provider == null) return const SizedBox.shrink();

    return IgnorePointer(
      ignoring: true, // never receives pointer events
      child: Offstage(
        offstage: true, // not painted, but built/layout so frameBuilder runs
        child: Image(
          image: _provider!,
          excludeFromSemantics: true,
          frameBuilder: (context, child, frame, wasSync) {
            if (frame != null && !_imageOk) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _imageOk = true);
              });
            }
            return child; // must return child for frameBuilder contract
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
    const titleStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);

    return Card(
      elevation: 2,
      color: const Color.fromARGB(255, 250, 253, 255),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Invisible preloader (no hit testing, no painting)
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          minimumSize: const Size(80, 60),
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
