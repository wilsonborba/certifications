import 'dart:convert';

import 'package:accredit/core/utils/my_encryption.dart';
import 'package:accredit/dal/local/local_source_adapter.dart';
import 'package:accredit/domain/models/topic_identifications.dart';
import 'package:accredit/domain/services/card_items_manager.dart';
import 'package:flutter/material.dart';

/// BaseTopics is a StatefulWidget holding shared logic for Mobile/Desktop
abstract class BaseTopics extends StatefulWidget {
  final String itemName;
  const BaseTopics({super.key, required this.itemName});
}

/// Shared state with common helpers for topics screens.
/// Subclasses inherit `fetchTopicsForCard` and helpers.
abstract class BaseTopicsState<T extends BaseTopics> extends State<T> {
  /// Fetch topics for an item.
  /// Returns a record: (topics, page, perPage, hasMore)
  final LocalSourceAdapter _topicsStorage = LocalSourceAdapter(namespace: 'topics');
  final Duration _pageCacheTtl = const Duration(hours: 3);
  final LocalSourceAdapter _searchStorage = LocalSourceAdapter(namespace: 'search');
  final Duration _searchTtl = const Duration(minutes: 15);

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
    final page   = decoded['page'] as int?;
    final exp    = expStr != null ? DateTime.tryParse(expStr) : null;

    if (page != null && exp != null && DateTime.now().isBefore(exp)) return page;
    return 1;
  }

  /// Save a full page payload: topics + page + per_page + has_more + expiration
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

  /// Load a full page payload if present and not expired. Returns null if stale/missing.
  Future<(List<Map<String, dynamic>>, int?, int?, bool)?>
      loadTopicsPageCache(String itemName, int page) async {
    final enc = MyEncryption();
    final stored = await _topicsStorage.read<dynamic>(_pageKey(itemName, page));
    if (stored is! String || stored.isEmpty) return null;

    final clear = await enc.decryptPayload(stored);
    if (clear == null) return null;

    final decoded = json.decode(clear);
    if (decoded is! Map) return null;

    final expStr = decoded['expiration_time'] as String?;
    final exp    = expStr != null ? DateTime.tryParse(expStr) : null;
    if (exp == null || DateTime.now().isAfter(exp)) return null;

    final topics  = (decoded['topics'] as List).cast<Map<String, dynamic>>();
    final int? pg = decoded['page'] as int?;
    final int? pp = decoded['per_page'] as int?;
    final bool hm = decoded['has_more'] as bool? ?? false;
    return (topics, pg, pp, hm);
  }

  /// Load a page from cache first; if missing/stale, fetch → cache → return.
  Future<(List<Map<String, dynamic>>, int?, int?, bool)> loadOrFetchTopicsPage(
    String itemName, {
    required int page,
    required int perPage,
  }) async {
    final cached = await loadTopicsPageCache(itemName, page);
    if (cached != null) return cached;

    final (topics, pg, pp, hm) =
        await fetchTopicsForCard(itemName, page, perPage);

    // persist the freshly fetched page
    await saveTopicsPageCache(
      itemName: itemName,
      page: pg ?? page,
      topics: topics,
      perPage: pp,
      hasMore: hm,
    );

    return (topics, pg, pp, hm);
  }
  Future<(List<Map<String, dynamic>>, int?, int?, bool)> fetchTopicsForCard(String itemName, int page, int perPage) async {
    
    final manager = CardItemsManager();
    final response = await manager.getTopicsFromCard(itemName,  page, perPage);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch topics for $itemName');
    }

    final decoded = response.body.isNotEmpty ? json.decode(response.body) : null;
    if (decoded is! Map || decoded['data'] == null) {
      throw Exception('Unexpected topics payload shape for $itemName');
    }

    final data = decoded['data'];
    if (data is! Map || data['topics'] is! List) {
      throw Exception('Unexpected topics payload shape for $itemName');
    }

    final topics = (data['topics'] as List).cast<Map<String, dynamic>>();
    final int? _page = data['page'] is int ? data['page'] as int : null;
    final int? _perPage = data['per_page'] is int ? data['per_page'] as int : null;
    final bool hasMore = (data['has_more'] is bool) ? data['has_more'] as bool : false;

    //debug('Fetched ${topics.length} topics (objects) for $itemName from API');
    return (topics, _page, _perPage, hasMore);
  }

  /// Helper to parse identifications object
  Identifications? getTopicIdentifications(Map<String, dynamic> topic) {
    if (topic['identifications'] is Map) {
      final idMap = topic['identifications'] as Map<String, dynamic>;
      return Identifications.fromJson(idMap);
    }
    return null;
  }

  // In base_topics.dart (inside BaseTopicsState)
bool shouldUseIdentifications(Identifications? ident) {
    if (ident == null) return false;

    final id    = ident.inputIdentification.trim();
    final title = (ident.titleIdentification ?? '').trim();
    final link  = (ident.linkIdentification ?? '').trim();

    // Required: input_identification, title_identification, link_identification
    if (id.isEmpty) return false;
    if (title.isEmpty) return false;
    if (link.isEmpty) return false;

    // img_link_identification may be empty/null (no image)
    return true;
  }

  String? safeImageFromIdent(Identifications ident) {
    final s = ident.imgLinkIdentification?.trim();
    return (s == null || s.isEmpty) ? null : s;
  }






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

  Future<(List<Map<String, dynamic>>, int?, int?, bool)?>
      loadSearchPageCache(String itemName, String query, int page) async {
    final enc = MyEncryption();
    final stored = await _searchStorage.read<dynamic>(_searchPageKey(itemName, query, page));
    if (stored is! String || stored.isEmpty) return null;

    final clear = await enc.decryptPayload(stored);
    if (clear == null) return null;

    final decoded = json.decode(clear);
    if (decoded is! Map) return null;

    final expStr = decoded['expiration_time'] as String?;
    final exp    = expStr != null ? DateTime.tryParse(expStr) : null;
    if (exp == null || DateTime.now().isAfter(exp)) return null;

    final topics  = (decoded['topics'] as List).cast<Map<String, dynamic>>();
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
      await _searchStorage.upsert(_searchPageKey(itemName, query, page), cipher);
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
    // 1) cache first
    final cached = await loadSearchPageCache(itemName, query, page);
    if (cached != null) return cached;

    // 2) fetch via CardItemsManager
    final (topics, pg, pp, hm) =
        await fetchSearchForCard(itemName, query, page, perPage, mode, fillPage, maxExtraPages);

    // 3) persist
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

  // Uses the EXISTING CardItemsManager (no new manager)
  Future<(List<Map<String, dynamic>>, int?, int?, bool)> fetchSearchForCard(
    String itemName,
    String query,
    int page,
    int perPage, [
    String mode = 'fulltext',
    bool fillPage = true,
    int maxExtraPages = 2,
  ]) async {
    final manager = CardItemsManager();
    final response = await manager.searchTopics(itemName, query, page, perPage, mode, fillPage, maxExtraPages);

    if (response.statusCode != 200) {
      throw Exception('Failed to search topics for $itemName');
    }

    final decoded = response.body.isNotEmpty ? json.decode(response.body) : null;
    if (decoded is! Map || decoded['data'] == null) {
      throw Exception('Unexpected search payload shape for $itemName');
    }

    final data = decoded['data'];
    if (data is! Map || data['topics'] is! List) {
      throw Exception('Unexpected search payload shape for $itemName');
    }

    final topics = (data['topics'] as List).cast<Map<String, dynamic>>();
    final int? _page = data['page'] is int ? data['page'] as int : null;
    final int? _perPage = data['per_page'] is int ? data['per_page'] as int : null;
    final bool hasMore = (data['has_more'] is bool) ? data['has_more'] as bool : false;

    return (topics, _page, _perPage, hasMore);
  }

}
