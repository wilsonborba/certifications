import 'dart:convert';

import 'package:certifications/core/utils/my_encryption.dart';
import 'package:certifications/core/utils/my_logs.dart';
import 'package:certifications/dal/local/local_source_adapter.dart';

import 'package:certifications/domain/models/source_item.dart';
import 'package:certifications/domain/services/api_certification_manager.dart';
import 'package:flutter/material.dart';
import 'package:certifications/presentation/screen_adjuster.dart';
import 'package:certifications/presentation/widgets/attachment/desktop_attachment.dart';
import 'package:certifications/presentation/widgets/attachment/mobile_attachment.dart';

class OnAttachmentScreen extends StatefulWidget {
  const OnAttachmentScreen({super.key});

  @override
  State<OnAttachmentScreen> createState() => _OnAttachmentScreenState();
}

class _OnAttachmentScreenState extends State<OnAttachmentScreen> {
  late final Future<List<SourceItem>> _cardsFuture;

  final LocalSourceAdapter _localSourceAdapter = LocalSourceAdapter(
    namespace: 'attachment',
  );

  @override
  void initState() {
    super.initState();
    _cardsFuture = _fetchCards();
  }

  Future<List<SourceItem>> _fetchCards() async {
    // 1) try encrypted cache first
    final cached = await _loadEncryptedCardsIfFresh();
    if (cached != null) return cached;

    // 2) fetch from API
    final resp = await CertificationManager().getCards();
    if (resp.statusCode != 200) {
      throw Exception('Failed to load cards (status ${resp.statusCode})');
    }

    final decoded = json.decode(resp.body);
    if (decoded is Map && decoded['data'] is List) {
      final list = decoded['data'] as List<dynamic>;
      final items = list
          .map((e) => SourceItem.fromJson(e as Map<String, dynamic>))
          .toList();

      debug('Fetched ${items.length} items from API');

      // 3) save encrypted
      await _saveEncryptedCards(items);

      return items;
    }

    throw Exception('Unexpected cards payload shape');
  }

  List<Map<String, dynamic>> _serializeItems(List<SourceItem> items) {
    return items
        .map(
          (e) => {
            'mode': e.mode,
            'source_name': e.sourceName,
            'has_topic': e.hasTopic,
            'item_name': e.itemName,
            'item_img': e.itemImg,
            'expiration_time': e.expirationTime?.toIso8601String(),
          },
        )
        .toList();
  }

  List<SourceItem> _deserializeItems(dynamic decoded) {
    if (decoded is List) {
      return decoded.map((e) {
        final m = e as Map<String, dynamic>;
        final item = SourceItem.fromJson(m);

        final expRaw = m['expiration_time'];
        if (expRaw is String) {
          item.expirationTime = DateTime.tryParse(expRaw);
        }
        return item;
      }).toList();
    }
    throw Exception('Unexpected decrypted payload shape');
  }

  Future<void> _saveEncryptedCards(List<SourceItem> items) async {
    final encryption = MyEncryption();

    // stamp a shared expiration (3 hours) onto each item like before
    final expirationTime = DateTime.now().add(const Duration(hours: 3));
    for (final item in items) {
      item.expirationTime = expirationTime;
    }

    final clearMaps = _serializeItems(items);
    final clearJson = json.encode({'data': clearMaps}); // keep same shape

    final encrypted = await encryption.encryptPayload(clearJson);
    if (encrypted == null) {
      throw Exception('Failed to encrypt cards payload');
    }

    // store ONLY the ciphertext (base64)
    await _localSourceAdapter.upsert('cards', encrypted);
    debug('Cached items (encrypted) with expiration at $expirationTime');
  }

  Future<List<SourceItem>?> _loadEncryptedCardsIfFresh() async {
    final encryption = MyEncryption();

    // Read as dynamic to support both the NEW (String ciphertext) and OLD (List plaintext) cache.
    final stored = await _localSourceAdapter.read<dynamic>('cards');
    if (stored == null) return null;

    List<SourceItem>? items;

    if (stored is String) {
      // New format: encrypted base64 blob
      final clear = await encryption.decryptPayload(stored);
      if (clear == null) {
        debug('Failed to decrypt cached cards; ignoring cache');
        return null;
      }

      final decoded = json.decode(clear);
      items = _deserializeItems(decoded['data']);
    } else if (stored is List) {
      // Legacy format: plaintext list<map> from old cache
      try {
        items = _deserializeItems(stored);
        debug('Loaded legacy plaintext cache; will migrate to encrypted.');
        // Opportunistic migration to encrypted format so we don’t see this again.
        await _saveEncryptedCards(items);
      } catch (e) {
        debug('Failed to parse legacy plaintext cache: $e');
        items = null;
      }
    } else {
      // Unexpected shape
      debug('Unexpected cached type for key "cards": ${stored.runtimeType}');
      return null;
    }

    if (items == null || items.isEmpty) return null;

    // Freshness check via first item’s expiration_time
    final exp = items.first.expirationTime;
    if (exp is DateTime && DateTime.now().isBefore(exp)) {
      debug('Using cached cards (encrypted or migrated, not expired)');
      return items;
    }

    debug('Cached cards expired or missing expiration; refetching.');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ScreenAdjuster(
      mobileWidget: MobileAttachment(items: _cardsFuture),
      desktopWidget: DesktopAttachment(items: _cardsFuture),
    ).adjust(context);
  }
}
