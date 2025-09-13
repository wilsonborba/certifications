

import 'dart:convert';

import 'package:accredit/core/utils/my_logs.dart';
import 'package:accredit/domain/models/source_item.dart';
import 'package:accredit/domain/services/card_items_manager.dart';
import 'package:accredit/presentation/components/attachment/source_groups_list.dart';
import 'package:accredit/presentation/components/attachment/tab_card_sources.dart';
import 'package:flutter/material.dart';
import 'package:accredit/presentation/components/attachment/card_pdf_picker.dart';
import 'package:accredit/presentation/components/attachment/top_headers.dart';

import 'dart:math';

int _randomNumber() {
  final random = Random();
  return random.nextInt(10000000); 
}

String playfulPayload = '''
[
 {"mode":"playful","source_name":"apps","has_topic":true,"item_name":"google","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},
 {"mode":"playful","source_name":"apps","has_topic":true,"item_name":"reddit","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},
 {"mode":"playful","source_name":"apps","has_topic":true,"item_name":"spotify","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},
 {"mode":"playful","source_name":"apps","has_topic":true,"item_name":"twitter","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},
 {"mode":"playful","source_name":"apps","has_topic":true,"item_name":"wikipedia","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},
 {"mode":"playful","source_name":"apps","has_topic":true,"item_name":"youtube","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},

 {"mode":"playful","source_name":"newspapers","has_topic":true,"item_name":"the_new_york_times","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},
 {"mode":"playful","source_name":"newspapers","has_topic":true,"item_name":"the_washington_post","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},
 {"mode":"playful","source_name":"newspapers","has_topic":true,"item_name":"the_wall_street_journal","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},
 {"mode":"playful","source_name":"newspapers","has_topic":true,"item_name":"bbc_news","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},
 {"mode":"playful","source_name":"newspapers","has_topic":true,"item_name":"cnn","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},

 {"mode":"playful","source_name":"movies_and_series","has_topic":false,"item_name":"matrix","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},
 {"mode":"playful","source_name":"movies_and_series","has_topic":false,"item_name":"inception","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},
 {"mode":"playful","source_name":"movies_and_series","has_topic":false,"item_name":"interstellar","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},
 {"mode":"playful","source_name":"movies_and_series","has_topic":false,"item_name":"the_dark_knight","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},
 {"mode":"playful","source_name":"movies_and_series","has_topic":false,"item_name":"fight_club","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},
 {"mode":"playful","source_name":"movies_and_series","has_topic":false,"item_name":"pulp_fiction","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},

 {"mode":"playful","source_name":"music","has_topic":false,"item_name":"chris_brown","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},
 {"mode":"playful","source_name":"music","has_topic":false,"item_name":"ariana_grande","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},
 {"mode":"playful","source_name":"music","has_topic":false,"item_name":"beyonce","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},
 {"mode":"playful","source_name":"music","has_topic":false,"item_name":"drake","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"}
]
''';

String seriousPayload = '''
[
 {"mode":"serious","source_name":"books","has_topic":false,"item_name":"the_great_gatsby","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},
 {"mode":"serious","source_name":"books","has_topic":false,"item_name":"pride_and_prejudice","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},
 {"mode":"serious","source_name":"books","has_topic":false,"item_name":"moby_dick","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},
 {"mode":"serious","source_name":"books","has_topic":false,"item_name":"alice_in_wonderland","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},

 {"mode":"serious","source_name":"public_and_government","has_topic":true,"item_name":"data_gov_us","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},
 {"mode":"serious","source_name":"public_and_government","has_topic":true,"item_name":"world_bank","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},
 {"mode":"serious","source_name":"public_and_government","has_topic":true,"item_name":"un_data","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},
 {"mode":"serious","source_name":"public_and_government","has_topic":true,"item_name":"european_union_open_data","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},

 {"mode":"serious","source_name":"scientific_research","has_topic":true,"item_name":"arxiv","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},
 {"mode":"serious","source_name":"scientific_research","has_topic":true,"item_name":"openalex","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},
 {"mode":"serious","source_name":"scientific_research","has_topic":true,"item_name":"pubmed","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},
 {"mode":"serious","source_name":"scientific_research","has_topic":true,"item_name":"science_direct","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},

 {"mode":"serious","source_name":"encyclopedic","has_topic":true,"item_name":"wikipedia","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},
 {"mode":"serious","source_name":"encyclopedic","has_topic":false,"item_name":"stanford_encyclopedia","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},
 {"mode":"serious","source_name":"encyclopedic","has_topic":false,"item_name":"wiktionary","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"},
 {"mode":"serious","source_name":"encyclopedic","has_topic":false,"item_name":"britannica","item_img":"https://avatars.githubusercontent.com/u/${_randomNumber()}"}
]
''';




List<SourceItem> _decodeItems(String jsonStr) {
  final raw = json.decode(jsonStr) as List<dynamic>;
  return raw.map((e) => SourceItem.fromJson(e as Map<String, dynamic>)).toList();
}


class DesktopAttachment extends StatefulWidget {
  
  const DesktopAttachment({super.key});

  @override
  State<DesktopAttachment> createState() => _DesktopAttachmentState();
}

class _DesktopAttachmentState extends State<DesktopAttachment> {

  late Future<List<SourceItem>> _cardsFuture;

   @override
  void initState() {
    super.initState();
    _cardsFuture = _loadCards();
  }


   Future<List<SourceItem>> _loadCards() async {
    final resp = await CardItemsManager().getCards(); // likely Future<Response>
    if (resp.statusCode != 200) {
      throw Exception('Failed to load cards (status ${resp.statusCode})');
    }

    final decoded = json.decode(resp.body);
    // Your sample shows: {"message": "...", "data": [ {id:..., mode:..., ...}, ... ] }
    if (decoded is Map && decoded['data'] is List) {
      final list = decoded['data'] as List<dynamic>;
      return list
          .map((e) => SourceItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Unexpected cards payload shape');
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            const TopHeaders(),
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: FutureBuilder<List<SourceItem>>(
                      future: _cardsFuture,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snap.hasError) {
                          debug('Cards load error: ${snap.error}');
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Failed to load cards'),
                          );
                        }

                        final items = snap.data ?? const <SourceItem>[];

                        // Normalize mode and split: "both" goes to both lists
                        bool _isPlayful(SourceItem s) {
                          final m = (s.mode ?? '').toLowerCase().trim();
                          return m == 'playful' || m == 'both';
                        }

                        bool _isSerious(SourceItem s) {
                          final m = (s.mode ?? '').toLowerCase().trim();
                          return m == 'serious' || m == 'both';
                        }

                        final playfulItems = items.where(_isPlayful).toList();
                        final seriousItems = items.where(_isSerious).toList();

                        debug('Playful count: ${playfulItems.length}, Serious count: ${seriousItems.length}');

                        return TabCardSources(
                          leftLabel: 'Playful Mode',
                          rightLabel: 'Serious Mode',
                          leftChild: SourceGroupsList(
                            items: playfulItems,
                            onTapWithTopic: (item) =>
                                debugPrint('WITH topic → ${item.sourceName}/${item.itemName}'),
                            onTapWithoutTopic: (item) =>
                                debugPrint('NO topic → ${item.sourceName}/${item.itemName}'),
                            onSeeMore: (sourceName) =>
                                debugPrint('See more → $sourceName'),
                          ),
                          rightChild: SourceGroupsList(
                            items: seriousItems,
                            onTapWithTopic: (item) =>
                                debugPrint('WITH topic → ${item.sourceName}/${item.itemName}'),
                            onTapWithoutTopic: (item) =>
                                debugPrint('NO topic → ${item.sourceName}/${item.itemName}'),
                            onSeeMore: (sourceName) =>
                                debugPrint('See more → $sourceName'),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const Expanded(child: CardPdfPicker()),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
