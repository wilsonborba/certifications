

import 'dart:convert';

import 'package:accredit/domain/models/source_item.dart';
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



  @override
  Widget build(BuildContext context) {
    final playful = _decodeItems(playfulPayload);
    final serious = _decodeItems(seriousPayload);
    return Scaffold(

      body: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              
              child: Column(
          children: [
            TopHeaders(),
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: TabCardSources(
                      leftLabel: 'Playful Mode',     // won’t wrap
                      rightLabel: 'Serious Mode',    // won’t wrap
                      leftChild: SourceGroupsList(
                        items: playful,
                        onTapWithTopic: (item) {
                          // go to topic flow
                          debugPrint('WITH topic → ${item.sourceName}/${item.itemName}');
                        },
                        onTapWithoutTopic: (item) {
                          // go to alternate flow (no topic)
                          debugPrint('NO topic → ${item.sourceName}/${item.itemName}');
                        },
                        onSeeMore: (sourceName) {
                          // navigate to "more" page for that source
                          debugPrint('See more → $sourceName');
                        },
                      ),
                      rightChild: SourceGroupsList(
                        items: serious,
                        onTapWithTopic: (item) {
                          // go to topic flow
                          debugPrint('WITH topic → ${item.sourceName}/${item.itemName}');
                        },
                        onTapWithoutTopic: (item) {
                          // go to alternate flow (no topic)
                          debugPrint('NO topic → ${item.sourceName}/${item.itemName}');
                        },
                        onSeeMore: (sourceName) {
                          // navigate to "more" page for that source
                          debugPrint('See more → $sourceName');
                        },
                      )
                    ),
                  ),
                ),
                Expanded(
                  child: CardPdfPicker(),
                ),

              ],
            ),
            SizedBox(height: 40),

          ],
        ),
      ));
  }
}
