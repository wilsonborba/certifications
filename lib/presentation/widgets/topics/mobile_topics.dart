import 'dart:convert';
import 'dart:async';

import 'package:accredit/core/utils/my_encryption.dart';
import 'package:accredit/presentation/widgets/topics/base_topics.dart';
import 'package:accredit/core/utils/my_nagivation.dart';

import 'package:accredit/dal/local/local_source_adapter.dart';
import 'package:accredit/domain/services/card_items_manager.dart';
import 'package:flutter/material.dart';

class MobileTopics extends BaseTopics {
  const MobileTopics({super.key, required String itemName})
      : super(itemName: itemName);

  @override
  State<MobileTopics> createState() => _MobileTopicsState();
}

class _MobileTopicsState extends BaseTopicsState<MobileTopics> {
  // ---------- Paging (topics mode) ----------
  int _page = 1;
  int _perPage = 4; // mobile-optimized page size
  bool _hasMore = true;
  bool _loading = false;
  bool _initialDone = false;

  // ---------- Search state ----------
  final TextEditingController _qCtrl = TextEditingController();
  bool _searchMode = false;             // true when search results are visible
  int _searchPage = 1;                  // search current page
  bool _searchHasMore = false;
  bool _searchLoading = false;

  // ---------- Grid height memory (spinner placeholder) ----------
  final GlobalKey _gridKey = GlobalKey();
  double _lastGridHeight = 0;

  // ---------- Data ----------
  List<Map<String, dynamic>> _topics = const [];        // current topics page
  List<Map<String, dynamic>> _searchResults = const []; // current search page

  // ---------- Search cache (15 minutes) ----------
  // We keep a small encrypted local cache per (itemName, query, page).
  final LocalSourceAdapter _searchStorage = LocalSourceAdapter(namespace: 'search');
  final Duration _searchCacheTtl = const Duration(minutes: 15);

  // ---------- Loading phrase ticker (non-initial loads only) ----------
  Timer? _loadingTicker;
  int _loadingIndex = 0;
  // Generic phrases that work for any data source/state
  final List<String> _loadingPhrases = const [
    'Fetching topics…',
    'Some topics take longer to load…',
    'Checking availability…',
    'Still working on it…',
    'Almost there…',
  ];

  void _startLoadingTickerIfNeeded() {
    // Only rotate phrases during **non-initial** loads
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

  String _searchKey(String itemName, String query, int page) =>
      'search:$itemName:${query.trim().toLowerCase()}:$page';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    _stopLoadingTicker(); // ensure ticker is cleaned up
    super.dispose();
  }

  // ---------- Initial bootstrap: load last page from cache (topics mode) ----------
  Future<void> _bootstrap() async {
    final saved = await loadSavedPageOr1(widget.itemName);
    _page = saved;
    await _loadPage(_page);
  }

  // ---------- Fetch topics page (non-search) ----------
  Future<void> _loadPage(int page) async {
    if (_loading || _searchLoading) return;

    setState(() => _loading = true);
    _startLoadingTickerIfNeeded(); // start rotating phrases on non-initial loads
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
        _topics     = valid;               // replace page
        _page       = pg ?? page;
        _perPage    = pp ?? _perPage;
        _hasMore    = hm;
        _initialDone = true;
      });

      await saveCurrentPage(widget.itemName, _page);

      // Remember the grid height for smooth spinner swaps
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
        _initialDone = true; // stop endless spinner on error
      });
    } finally {
      if (!mounted) return;
      _stopLoadingTicker();
      setState(() => _loading = false);
    }
  }

  // ---------- Navigation (topics) ----------
  void _loadPrev() {
    if (_searchMode) {
      _loadSearchPrev();
      return;
    }
    if (_loading || _page <= 1) return;
    _loadPage(_page - 1);
  }

  void _loadNext() {
    if (_searchMode) {
      _loadSearchNext();
      return;
    }
    if (_loading || !_hasMore) return;
    _loadPage(_page + 1);
  }

  // ---------- SEARCH API (uses CardItemsManager.searchTopics) ----------
  // GET /search/{itemName}?q=&page=&per_page=&mode=&fill_page=&max_extra_pages=
  Future<(List<Map<String, dynamic>>, int?, int?, bool)> _fetchSearchPage({
    required String itemName,
    required String query,
    required int page,
    required int perPage,
  }) async {
    final manager = CardItemsManager();
    // You can tune these defaults if desired.
    const String mode = 'fulltext';
    const bool fillPage = true;
    const int maxExtraPages = 2;

    final resp = await manager.searchTopics(
      itemName,
      query,
      page,
      perPage,
      mode,
      fillPage,
      maxExtraPages,
    );

    if (resp.statusCode != 200) {
      throw Exception('Search failed (${resp.statusCode}) for "$query"');
    }

    final decoded = resp.body.isNotEmpty ? json.decode(resp.body) : null;
    if (decoded is! Map || decoded['data'] == null) {
      throw Exception('Unexpected search payload shape for "$query"');
    }

    final data = decoded['data'];
    if (data is! Map || data['topics'] is! List) {
      throw Exception('Unexpected search data shape for "$query"');
    }

    final raw = (data['topics'] as List).cast<Map<String, dynamic>>();
    final topics = raw
        .where((t) => shouldUseIdentifications(getTopicIdentifications(t)))
        .toList();

    final int? _page = data['page'] is int ? data['page'] as int : null;
    final int? _per  = data['per_page'] is int ? data['per_page'] as int : null;
    final bool _hm   = (data['has_more'] is bool) ? data['has_more'] as bool : false;

    return (topics, _page, _per, _hm);
  }

  // ---------- SEARCH CACHE (15 minutes) ----------
  Future<void> _saveSearchCache({
    required String itemName,
    required String query,
    required int page,
    required List<Map<String, dynamic>> topics,
    required int? perPage,
    required bool hasMore,
  }) async {
    final key = _searchKey(itemName, query, page);
    final clear = json.encode({
      'page': page,
      'per_page': perPage,
      'has_more': hasMore,
      'topics': topics,
      'expiration_time': DateTime.now().add(_searchCacheTtl).toIso8601String(),
    });
    final enc = MyEncryption();
    final cipher = await enc.encryptPayload(clear);
    if (cipher != null) {
      await _searchStorage.upsert(key, cipher);
    }
  }

  Future<(List<Map<String, dynamic>>, int?, int?, bool)?>
      _loadSearchCache(String itemName, String query, int page) async {
    final key = _searchKey(itemName, query, page);
    final enc = MyEncryption();

    final stored = await _searchStorage.read<dynamic>(key);
    if (stored is! String || stored.isEmpty) return null;

    final clear = await enc.decryptPayload(stored);
    if (clear == null) return null;

    final decoded = json.decode(clear);
    if (decoded is! Map) return null;

    final expStr = decoded['expiration_time'] as String?;
    final exp    = expStr != null ? DateTime.tryParse(expStr) : null;
    if (exp == null || DateTime.now().isAfter(exp)) return null;

    final topics = (decoded['topics'] as List).cast<Map<String, dynamic>>();
    final int? pg = decoded['page'] as int?;
    final int? pp = decoded['per_page'] as int?;
    final bool hm = decoded['has_more'] as bool? ?? false;
    return (topics, pg, pp, hm);
  }

  // ---------- SEARCH FLOW ----------
  Future<void> _startSearch() async {
    final q = _qCtrl.text.trim();
    if (q.isEmpty) return;

    setState(() {
      _searchMode = true;
      _searchPage = 1;
    });

    await _loadSearchPage(1);
  }

  Future<void> _clearSearch() async {
    setState(() {
      _searchMode = false;
      _searchResults = const [];
      _searchPage = 1;
      _searchHasMore = false;
    });
  }

  Future<void> _loadSearchPage(int page) async {
    if (_searchLoading || _loading) return;
    final q = _qCtrl.text.trim();
    if (q.isEmpty) {
      _clearSearch();
      return;
    }

    setState(() => _searchLoading = true);
    _startLoadingTickerIfNeeded(); // start rotating phrases on non-initial loads
    try {
      // 1) Try cache first
      final cached = await _loadSearchCache(widget.itemName, q, page);
      if (cached != null) {
        final (topics, pg, _pp, hm) = cached;
        if (!mounted) return;
        setState(() {
          _searchResults = topics;
          _searchPage = pg ?? page;
          _searchHasMore = hm;
          _initialDone = true;
        });
      } else {
        // 2) Fetch → cache → render
        final (topics, pg, pp, hm) = await _fetchSearchPage(
          itemName: widget.itemName,
          query: q,
          page: page,
          perPage: _perPage,
        );

        await _saveSearchCache(
          itemName: widget.itemName,
          query: q,
          page: pg ?? page,
          topics: topics,
          perPage: pp ?? _perPage,
          hasMore: hm,
        );

        if (!mounted) return;
        setState(() {
          _searchResults = topics;
          _searchPage = pg ?? page;
          _searchHasMore = hm;
          _initialDone = true;
        });
      }

      // Remember grid height for smooth spinner swap
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
        _initialDone = true;
      });
    } finally {
      if (!mounted) return;
      _stopLoadingTicker();
      setState(() => _searchLoading = false);
    }
  }

  void _loadSearchPrev() {
    if (_searchLoading || _searchPage <= 1) return;
    _loadSearchPage(_searchPage - 1);
  }

  void _loadSearchNext() {
    if (_searchLoading || !_searchHasMore) return;
    _loadSearchPage(_searchPage + 1);
  }

  // ---------- Header: Title + Search (stacked for mobile) ----------
  Widget _buildHeaderBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // "Topics" with side dividers (mobile-friendly)
          Row(
            children: const [
              Expanded(child: Divider(height: 1, thickness: 1)),
              SizedBox(width: 12),
              Text('Topics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(width: 12),
              Expanded(child: Divider(height: 1, thickness: 1)),
            ],
          ),
          const SizedBox(height: 12),

          // Search input + button (stacked for mobile comfort)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: _qCtrl,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _startSearch(),
                    decoration: const InputDecoration(
                      hintText: 'Search topics…',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _startSearch,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Search'),
                ),
              ),
              if (_searchMode) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Clear search',
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.close),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Grid builder (1 column on mobile) ----------
  Widget _buildGrid(BuildContext context) {
    final items = _searchMode ? _searchResults : _topics;

    return Padding(
      key: _gridKey,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(), // outer scroll drives
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          childAspectRatio: 1.0,
          crossAxisSpacing: 0.0,
          mainAxisSpacing: 12,
          mainAxisExtent: 180, // consistent height with desktop cards
        ),
        itemBuilder: (ctx, i) {
          final t = items[i];
          final ident = getTopicIdentifications(t)!; // filtered/validated
          final title = ident.titleIdentification!;
          final link  = ident.linkIdentification!;
          final img   = safeImageFromIdent(ident);

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

  // ---------- Footer with paging controls + page info ----------
  Widget _buildFooter() {
    // Compute visible index window for current grid (1-based).
    final items = _searchMode ? _searchResults : _topics;
    final curPage = _searchMode ? _searchPage : _page;
    final curHasMore = _searchMode ? _searchHasMore : _hasMore;
    final isLoading = _searchMode ? _searchLoading : _loading;

    final startIndex = ((curPage - 1) * _perPage) + (items.isEmpty ? 0 : 1);
    final endIndex = startIndex + items.length - (items.isEmpty ? 0 : 1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              // Prev
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (isLoading || curPage <= 1)
                      ? null
                      : _loadPrev,
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  label: const Text('Previous', style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Center info chip (Page N • X–Y)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.transparent),
                  color: const Color(0xFFF7F7F7),
                ),
                child: Text(
                  items.isEmpty
                      ? 'Page $curPage'
                      : 'Page $curPage | $startIndex–$endIndex',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(width: 8),

              // Next
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (isLoading || !curHasMore)
                      ? null
                      : _loadNext,
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
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _searchMode ? _searchLoading : _loading;
    final hasAnyItems =
        (_searchMode ? _searchResults : _topics).isNotEmpty;

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
              // Header with title + search
              _buildHeaderBar(),

              // 1) Initial loading (first ever load)
              if (!_initialDone && !hasAnyItems) initialLoading,

              // 2) Empty state after load, no items
              if (_initialDone && !hasAnyItems && !isBusy) emptyState,

              // 3) Grid or fixed-height spinner while loading next page
              if (hasAnyItems && !isBusy) _buildGrid(context),

              if (hasAnyItems && isBusy)
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
                          // Smooth rotating phrases during non-initial loads
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

              // 4) Footer with paging + page info
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

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

  /// Invisible preloader so it never steals taps/hover, but lets us know when
  /// the first frame is ready.
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
            // Invisible, non-interactive preloader
            _preloadImage(),

            // LEFT: text/content
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

            // RIGHT: divider + image AFTER the first frame renders
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
