import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:accredit/core/utils/my_encryption.dart';
import 'package:accredit/dal/local/local_source_adapter.dart';
import 'package:accredit/domain/models/topic_identifications.dart';
import 'package:accredit/domain/services/api_certification_manager.dart';

/// BaseTopics is a StatefulWidget holding shared logic for Mobile/Desktop
abstract class BaseTopics extends StatefulWidget {
  final String itemName;
  const BaseTopics({super.key, required this.itemName});
}

/// Shared state with common helpers for topics screens.
abstract class BaseTopicsState<T extends BaseTopics> extends State<T> {
  // =========================================================
  //                 DATA / CACHE HELPERS
  // =========================================================
  final LocalSourceAdapter _topicsStorage = LocalSourceAdapter(
    namespace: 'topics',
  );
  final Duration _pageCacheTtl = const Duration(hours: 3);

  final LocalSourceAdapter _searchStorage = LocalSourceAdapter(
    namespace: 'search',
  );
  final Duration _searchTtl = const Duration(minutes: 15);

  // =========================================================
  //                 DEBUG / DIAGNOSTICS
  // =========================================================

  /// If true, do not filter topics by identifications (helps isolate backend vs UI).
  /// Set to true temporarily if you want to confirm topics are coming from API.
  @protected
  bool get debugDisableIdentificationFilter => false;

  void _log(String msg) {
    // debugPrint is safe for Web/Android/iOS and truncates long lines more gracefully.
    debugPrint('[Topics] ${widget.itemName}: $msg');
  }

  void _logError(String msg, Object e, StackTrace st) {
    debugPrint('[Topics][ERROR] ${widget.itemName}: $msg');
    debugPrint('  $e');
    debugPrint('$st');
  }

  String _pageKey(String itemName, int page) => 'topics:$itemName:$page';
  String _currentKey(String itemName) => 'topics:$itemName:current';

  Future<void> saveCurrentPage(String itemName, int page) async {
    final enc = MyEncryption();
    final clear = json.encode({
      'page': page,
      'expiration_time': DateTime.now().add(_pageCacheTtl).toIso8601String(),
    });
    final cipher = await enc.encryptPayload(clear);
    if (cipher != null) {
      await _topicsStorage.upsert(_currentKey(itemName), cipher);
    }
  }

  Future<int> loadSavedPageOr1(String itemName) async {
    final enc = MyEncryption();
    final stored = await _topicsStorage.read<dynamic>(_currentKey(itemName));
    if (stored is! String || stored.isEmpty) return 1;

    final clear = await enc.decryptPayload(stored);
    if (clear == null) return 1;

    final decoded = json.decode(clear);
    if (decoded is! Map) return 1;

    final expStr = decoded['expiration_time'] as String?;
    final page = decoded['page'] as int?;
    final exp = expStr != null ? DateTime.tryParse(expStr) : null;

    if (page != null && exp != null && DateTime.now().isBefore(exp))
      return page;
    return 1;
  }

  Future<void> saveTopicsPageCache({
    required String itemName,
    required int page,
    required List<Map<String, dynamic>> topics,
    required int? perPage,
    required bool hasMore,
  }) async {
    final enc = MyEncryption();
    final clear = json.encode({
      'page': page,
      'per_page': perPage,
      'has_more': hasMore,
      'topics': topics,
      'expiration_time': DateTime.now().add(_pageCacheTtl).toIso8601String(),
    });
    final cipher = await enc.encryptPayload(clear);
    if (cipher != null) {
      await _topicsStorage.upsert(_pageKey(itemName, page), cipher);
    }
  }

  Future<(List<Map<String, dynamic>>, int?, int?, bool)?> loadTopicsPageCache(
    String itemName,
    int page,
  ) async {
    final enc = MyEncryption();
    final stored = await _topicsStorage.read<dynamic>(_pageKey(itemName, page));
    if (stored is! String || stored.isEmpty) return null;

    final clear = await enc.decryptPayload(stored);
    if (clear == null) return null;

    final decoded = json.decode(clear);
    if (decoded is! Map) return null;

    final expStr = decoded['expiration_time'] as String?;
    final exp = expStr != null ? DateTime.tryParse(expStr) : null;
    if (exp == null || DateTime.now().isAfter(exp)) return null;

    final topics = (decoded['topics'] as List).cast<Map<String, dynamic>>();
    final int? pg = decoded['page'] as int?;
    final int? pp = decoded['per_page'] as int?;
    final bool hm = decoded['has_more'] as bool? ?? false;
    return (topics, pg, pp, hm);
  }

  Future<(List<Map<String, dynamic>>, int?, int?, bool)> loadOrFetchTopicsPage(
    String itemName, {
    required int page,
    required int perPage,
  }) async {
    final cached = await loadTopicsPageCache(itemName, page);
    if (cached != null) {
      _log('Cache HIT for topics page=$page');
      return cached;
    }
    _log('Cache MISS for topics page=$page; fetching from API');

    final (topics, pg, pp, hm) = await fetchTopicsForCard(
      itemName,
      page,
      perPage,
    );

    await saveTopicsPageCache(
      itemName: itemName,
      page: pg ?? page,
      topics: topics,
      perPage: pp,
      hasMore: hm,
    );

    return (topics, pg, pp, hm);
  }

  Future<(List<Map<String, dynamic>>, int?, int?, bool)> fetchTopicsForCard(
    String itemName,
    int page,
    int perPage,
  ) async {
    final manager = CertificationManager();

    _log(
      'API getTopicsFromCard(item=$itemName page=$page perPage=$perPage) START',
    );
    final response = await manager.getTopicsFromCard(itemName, page, perPage);
    _log(
      'API getTopicsFromCard END status=${response.statusCode} bodyLen=${response.body.length}',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch topics for $itemName (status=${response.statusCode}) body=${_safeBodySnippet(response.body)}',
      );
    }

    final decoded = response.body.isNotEmpty
        ? json.decode(response.body)
        : null;
    if (decoded is! Map || decoded['data'] == null) {
      throw Exception('Unexpected topics payload shape (missing data)');
    }

    final data = decoded['data'];
    if (data is! Map || data['topics'] is! List) {
      throw Exception('Unexpected topics payload shape (missing topics list)');
    }

    final topics = (data['topics'] as List).cast<Map<String, dynamic>>();
    final int? _page = data['page'] is int ? data['page'] as int : null;
    final int? _perPage = data['per_page'] is int
        ? data['per_page'] as int
        : null;
    final bool hasMore = (data['has_more'] is bool)
        ? data['has_more'] as bool
        : false;

    return (topics, _page, _perPage, hasMore);
  }

  String _safeBodySnippet(String body, {int max = 300}) {
    if (body.isEmpty) return '';
    if (body.length <= max) return body;
    return body.substring(0, max);
  }

  Identifications? getTopicIdentifications(Map<String, dynamic> topic) {
    final ident = topic['identifications'];
    if (ident is Map) {
      return Identifications.fromJson(ident.cast<String, dynamic>());
    }
    return null;
  }

  /// Returns null if acceptable; otherwise a reason string (for diagnostics).
  String? _whyRejected(Identifications? ident) {
    if (ident == null) return 'identifications is null or not a map';
    final id = ident.inputIdentification.trim();
    final title = (ident.titleIdentification ?? '').trim();
    final link = (ident.linkIdentification ?? '').trim();

    if (id.isEmpty) return 'inputIdentification empty';
    if (title.isEmpty) return 'titleIdentification empty';
    if (link.isEmpty) return 'linkIdentification empty';
    return null;
  }

  bool shouldUseIdentifications(Identifications? ident) {
    return _whyRejected(ident) == null;
  }

  String? safeImageFromIdent(Identifications ident) {
    final s = ident.imgLinkIdentification?.trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  // =========================================================
  //                 SEARCH CACHE HELPERS
  // =========================================================

  String _searchPageKey(String itemName, String query, int page) =>
      'search:$itemName:${query.trim().toLowerCase()}:$page';
  String _searchCurrentKey(String itemName) => 'search:$itemName:current';

  Future<void> saveSearchCurrent(
    String itemName, {
    required String query,
    required int page,
  }) async {
    final enc = MyEncryption();
    final clear = json.encode({
      'query': query,
      'page': page,
      'expiration_time': DateTime.now().add(_searchTtl).toIso8601String(),
    });
    final cipher = await enc.encryptPayload(clear);
    if (cipher != null) {
      await _searchStorage.upsert(_searchCurrentKey(itemName), cipher);
    }
  }

  Future<(List<Map<String, dynamic>>, int?, int?, bool)?> loadSearchPageCache(
    String itemName,
    String query,
    int page,
  ) async {
    final enc = MyEncryption();
    final stored = await _searchStorage.read<dynamic>(
      _searchPageKey(itemName, query, page),
    );
    if (stored is! String || stored.isEmpty) return null;

    final clear = await enc.decryptPayload(stored);
    if (clear == null) return null;

    final decoded = json.decode(clear);
    if (decoded is! Map) return null;

    final expStr = decoded['expiration_time'] as String?;
    final exp = expStr != null ? DateTime.tryParse(expStr) : null;
    if (exp == null || DateTime.now().isAfter(exp)) return null;

    final topics = (decoded['topics'] as List).cast<Map<String, dynamic>>();
    final int? pg = decoded['page'] as int?;
    final int? pp = decoded['per_page'] as int?;
    final bool hm = decoded['has_more'] as bool? ?? false;
    return (topics, pg, pp, hm);
  }

  Future<void> saveSearchPageCache({
    required String itemName,
    required String query,
    required int page,
    required List<Map<String, dynamic>> topics,
    required int? perPage,
    required bool hasMore,
  }) async {
    final enc = MyEncryption();
    final clear = json.encode({
      'query': query,
      'page': page,
      'per_page': perPage,
      'has_more': hasMore,
      'topics': topics,
      'expiration_time': DateTime.now().add(_searchTtl).toIso8601String(),
    });
    final cipher = await enc.encryptPayload(clear);
    if (cipher != null) {
      await _searchStorage.upsert(
        _searchPageKey(itemName, query, page),
        cipher,
      );
    }
  }

  Future<(List<Map<String, dynamic>>, int?, int?, bool)> loadOrFetchSearchPage(
    String itemName, {
    required String query,
    required int page,
    required int perPage,
    String mode = 'fulltext',
    bool fillPage = true,
    int maxExtraPages = 2,
  }) async {
    final cached = await loadSearchPageCache(itemName, query, page);
    if (cached != null) {
      _log('Cache HIT for search q="$query" page=$page');
      return cached;
    }
    _log('Cache MISS for search q="$query" page=$page; fetching from API');

    final (topics, pg, pp, hm) = await fetchSearchForCard(
      itemName,
      query,
      page,
      perPage,
      mode,
      fillPage,
      maxExtraPages,
    );

    await saveSearchPageCache(
      itemName: itemName,
      query: query,
      page: pg ?? page,
      topics: topics,
      perPage: pp,
      hasMore: hm,
    );

    return (topics, pg, pp, hm);
  }

  Future<(List<Map<String, dynamic>>, int?, int?, bool)> fetchSearchForCard(
    String itemName,
    String query,
    int page,
    int perPage, [
    String mode = 'fulltext',
    bool fillPage = true,
    int maxExtraPages = 2,
  ]) async {
    final manager = CertificationManager();

    _log(
      'API searchTopics(item=$itemName q="$query" page=$page perPage=$perPage) START',
    );
    final response = await manager.searchTopics(
      itemName,
      query,
      page,
      perPage,
      mode,
      fillPage,
      maxExtraPages,
    );
    _log(
      'API searchTopics END status=${response.statusCode} bodyLen=${response.body.length}',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to search topics for $itemName (status=${response.statusCode}) body=${_safeBodySnippet(response.body)}',
      );
    }

    final decoded = response.body.isNotEmpty
        ? json.decode(response.body)
        : null;
    if (decoded is! Map || decoded['data'] == null) {
      throw Exception('Unexpected search payload shape (missing data)');
    }

    final data = decoded['data'];
    if (data is! Map || data['topics'] is! List) {
      throw Exception('Unexpected search payload shape (missing topics list)');
    }

    final topics = (data['topics'] as List).cast<Map<String, dynamic>>();
    final int? _page = data['page'] is int ? data['page'] as int : null;
    final int? _perPage = data['per_page'] is int
        ? data['per_page'] as int
        : null;
    final bool hasMore = (data['has_more'] is bool)
        ? data['has_more'] as bool
        : false;

    return (topics, _page, _perPage, hasMore);
  }

  // =========================================================
  //                    SHARED CONTROLLER
  // =========================================================

  int page = 1;
  int perPage = 8;
  bool hasMore = true;
  bool loading = false;
  bool initialDone = false;

  // Search
  final TextEditingController qCtrl = TextEditingController();
  bool searchMode = false;
  int searchPage = 1;
  bool searchHasMore = false;
  bool searchLoading = false;

  // Visible data
  List<Map<String, dynamic>> topics = const [];
  List<Map<String, dynamic>> searchResults = const [];

  // Grid height memory (spinner placeholder)
  final GlobalKey gridKey = GlobalKey();
  double lastGridHeight = 0;

  // Non-initial loading phrase ticker
  Timer? _loadingTicker;
  int loadingIndex = 0;
  final List<String> loadingPhrases = const [
    'Fetching topics…',
    'Some topics take longer to load…',
    'Checking availability…',
    'Still working on it…',
    'Almost there…',
  ];

  @protected
  int get initialPerPage => 8;

  @override
  void initState() {
    super.initState();
    perPage = initialPerPage;
    _bootstrap();
  }

  @override
  void dispose() {
    qCtrl.dispose();
    _stopLoadingTicker();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final saved = await loadSavedPageOr1(widget.itemName);
      page = saved;
      _log(
        'bootstrap -> starting at page=$page perPage=$perPage (kIsWeb=$kIsWeb)',
      );
      await loadPage(page);
    } catch (e, st) {
      _logError('bootstrap failed', e, st);
      if (!mounted) return;
      setState(() => initialDone = true);
    }
  }

  // ---------- ticker ----------
  void _startLoadingTickerIfNeeded() {
    if (!initialDone) return;
    _loadingTicker?.cancel();
    loadingIndex = 0;
    _loadingTicker = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() {
        loadingIndex = (loadingIndex + 1) % loadingPhrases.length;
      });
    });
  }

  void _stopLoadingTicker() {
    _loadingTicker?.cancel();
    _loadingTicker = null;
    loadingIndex = 0;
  }

  // =========================================================
  //                    TOPICS PAGING
  // =========================================================

  @protected
  Future<void> loadPage(int targetPage) async {
    if (loading || searchLoading) return;

    setState(() => loading = true);
    _startLoadingTickerIfNeeded();

    try {
      _log('loadPage($targetPage) START');
      final (raw, pg, pp, hm) = await loadOrFetchTopicsPage(
        widget.itemName,
        page: targetPage,
        perPage: perPage,
      );

      final List<Map<String, dynamic>> valid;
      if (debugDisableIdentificationFilter) {
        valid = raw;
        _log('Filter DISABLED -> using raw topics');
      } else {
        valid = raw
            .where((t) => shouldUseIdentifications(getTopicIdentifications(t)))
            .toList();
      }

      _log(
        'Topics counts: raw=${raw.length}, valid=${valid.length} (hasMore=$hm)',
      );

      // If everything was filtered out, log one example to see why.
      if (!debugDisableIdentificationFilter &&
          raw.isNotEmpty &&
          valid.isEmpty) {
        final sample = raw.first;
        final ident = getTopicIdentifications(sample);
        final reason = _whyRejected(ident) ?? 'unknown';
        _log(
          'All topics filtered out. Sample rejection reason="$reason". Sample topic keys=${sample.keys.toList()}',
        );
        _log('Sample identifications raw=${sample['identifications']}');
      }

      if (!mounted) return;
      setState(() {
        topics = valid;
        page = pg ?? targetPage;
        perPage = pp ?? perPage;
        hasMore = hm;
        initialDone = true;
      });

      await saveCurrentPage(widget.itemName, page);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final h = gridKey.currentContext?.size?.height ?? 0;
        if (h <= 0) return;
        if ((lastGridHeight - h).abs() > 0.1) {
          setState(() => lastGridHeight = h);
        }
      });

      _log('loadPage($targetPage) DONE -> page=$page perPage=$perPage');
    } catch (e, st) {
      _logError('loadPage($targetPage) failed', e, st);
      if (!mounted) return;
      setState(() => initialDone = true);
    } finally {
      if (!mounted) return;
      _stopLoadingTicker();
      setState(() => loading = false);
    }
  }

  @protected
  void loadPrev() {
    if (searchMode) {
      loadSearchPrev();
      return;
    }
    if (loading || page <= 1) return;
    loadPage(page - 1);
  }

  @protected
  void loadNext() {
    if (searchMode) {
      loadSearchNext();
      return;
    }
    if (loading || !hasMore) return;
    loadPage(page + 1);
  }

  // =========================================================
  //                        SEARCH
  // =========================================================

  @protected
  Future<void> startSearch() async {
    final q = qCtrl.text.trim();
    if (q.isEmpty) return;

    setState(() {
      searchMode = true;
      searchPage = 1;
    });

    await saveSearchCurrent(widget.itemName, query: q, page: 1);
    await loadSearchPage(1);
  }

  @protected
  Future<void> clearSearch() async {
    if (searchLoading) return;
    setState(() {
      searchMode = false;
      searchResults = const [];
      searchPage = 1;
      searchHasMore = false;
      qCtrl.clear();
    });
  }

  @protected
  Future<void> loadSearchPage(int targetPage) async {
    if (searchLoading || loading) return;

    final q = qCtrl.text.trim();
    if (q.isEmpty) {
      await clearSearch();
      return;
    }

    setState(() => searchLoading = true);
    _startLoadingTickerIfNeeded();

    try {
      _log('loadSearchPage($targetPage) START q="$q"');

      final (topicsRaw, pg, pp, hm) = await loadOrFetchSearchPage(
        widget.itemName,
        query: q,
        page: targetPage,
        perPage: perPage,
      );

      final List<Map<String, dynamic>> valid;
      if (debugDisableIdentificationFilter) {
        valid = topicsRaw;
        _log('Filter DISABLED -> using raw search results');
      } else {
        valid = topicsRaw
            .where((t) => shouldUseIdentifications(getTopicIdentifications(t)))
            .toList();
      }

      _log(
        'Search counts: raw=${topicsRaw.length}, valid=${valid.length} (hasMore=$hm)',
      );

      if (!debugDisableIdentificationFilter &&
          topicsRaw.isNotEmpty &&
          valid.isEmpty) {
        final sample = topicsRaw.first;
        final ident = getTopicIdentifications(sample);
        final reason = _whyRejected(ident) ?? 'unknown';
        _log(
          'All search results filtered out. Sample rejection reason="$reason". Sample topic keys=${sample.keys.toList()}',
        );
        _log('Sample identifications raw=${sample['identifications']}');
      }

      if (!mounted) return;
      setState(() {
        searchResults = valid;
        searchPage = pg ?? targetPage;
        perPage = pp ?? perPage;
        searchHasMore = hm;
        initialDone = true;
      });

      await saveSearchCurrent(widget.itemName, query: q, page: searchPage);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final h = gridKey.currentContext?.size?.height ?? 0;
        if (h <= 0) return;
        if ((lastGridHeight - h).abs() > 0.1) {
          setState(() => lastGridHeight = h);
        }
      });

      _log(
        'loadSearchPage($targetPage) DONE -> searchPage=$searchPage perPage=$perPage',
      );
    } catch (e, st) {
      _logError('loadSearchPage($targetPage) failed', e, st);
      if (!mounted) return;
      setState(() => initialDone = true);
    } finally {
      if (!mounted) return;
      _stopLoadingTicker();
      setState(() => searchLoading = false);
    }
  }

  @protected
  void loadSearchPrev() {
    if (searchLoading || searchPage <= 1) return;
    loadSearchPage(searchPage - 1);
  }

  @protected
  void loadSearchNext() {
    if (searchLoading || !searchHasMore) return;
    loadSearchPage(searchPage + 1);
  }

  // =========================================================
  //                    CONVENIENCE GETTERS
  // =========================================================

  @protected
  bool get isBusy => searchMode ? searchLoading : loading;

  @protected
  List<Map<String, dynamic>> get visibleItems =>
      searchMode ? searchResults : topics;

  /// Returns (startIndex, endIndex, currentPage, hasMoreForCurrentMode)
  @protected
  (int start, int end, int curPage, bool curHasMore) get windowInfo {
    final items = visibleItems;
    final curPage = searchMode ? searchPage : page;
    final curHasMore = searchMode ? searchHasMore : hasMore;

    final startIndex = ((curPage - 1) * perPage) + (items.isEmpty ? 0 : 1);
    final endIndex = startIndex + items.length - (items.isEmpty ? 0 : 1);
    return (startIndex, endIndex, curPage, curHasMore);
  }
}
