

import 'dart:convert';

import 'package:accredit/domain/models/source_item.dart';
import 'package:accredit/presentation/components/attachment/source_groups_list.dart';
import 'package:accredit/presentation/components/attachment/tab_card_sources.dart';
import 'package:flutter/material.dart';
import 'package:accredit/presentation/components/attachment/card_pdf_picker.dart';
import 'package:accredit/presentation/components/attachment/top_headers.dart';

const playfulPayload = '''
[
 {"mode":"playful","source_name":"apps","has_topic":true,"item_name":"google","item_img":"https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg"},
 {"mode":"playful","source_name":"apps","has_topic":true,"item_name":"reddit","item_img":"https://static.vecteezy.com/system/resources/previews/023/986/983/non_2x/reddit-logo-reddit-logo-transparent-reddit-icon-transparent-free-free-png.png"},
  {"mode":"playful","source_name":"apps","has_topic":true,"item_name":"spotify","item_img":"https://upload.wikimedia.org/wikipedia/commons/1/19/Spotify_logo_without_text.svg"},
  {"mode":"playful","source_name":"apps","has_topic":true,"item_name":"twitter","item_img":"https://upload.wikimedia.org/wikipedia/en/6/60/Twitter_Logo_as_of_2021.svg"},
  {"mode":"playful","source_name":"apps","has_topic":true,"item_name":"wikipedia","item_img":"https://upload.wikimedia.org/wikipedia/commons/6/63/Wikipedia-logo.png"},
  {"mode":"playful","source_name":"apps","has_topic":true,"item_name":"youtube","item_img":"https://upload.wikimedia.org/wikipedia/commons/b/b8/YouTube_Logo_2017.svg"},
  {"mode":"playful","source_name":"newspapers","has_topic":true,"item_name":"the_new_york_times","item_img":"https://upload.wikimedia.org/wikipedia/commons/4/40/New_York_Times_logo_variation.jpg"},
  {"mode":"playful","source_name":"newspapers","has_topic":true,"item_name":"the_washington_post","item_img":"https://upload.wikimedia.org/wikipedia/commons/0/0f/The_Washington_Post_logo_variation.jpg"},
  {"mode":"playful","source_name":"newspapers","has_topic":true,"item_name":"the_wall_street_journal","item_img":"https://cdn.imgbin.com/8/8/2/imgbin-the-wall-street-journal-logo-others-Ask3b1NRacW5Abagzn0PZAnSm.jpg"},
 {"mode":"playful","source_name":"newspapers","has_topic":true,"item_name":"bbc_news","item_img":"https://upload.wikimedia.org/wikipedia/commons/thumb/6/62/BBC_News_2019.svg/1200px-BBC_News_2019.svg.png"},
 {"mode":"playful","source_name":"newspapers","has_topic":true,"item_name":"cnn","item_img":"https://upload.wikimedia.org/wikipedia/commons/thumb/9/9d/CNN_Logo_%282014%29.svg/1200px-CNN_Logo_%282014%29.svg.png"},
 {"mode":"playful","source_name":"movies_and_series","has_topic":false,"item_name":"matrix","item_img":"https://m.media-amazon.com/images/M/MV5BN2NmN2VhMTQtMDNiOS00NDlhLTliMjgtODE2ZTY0ODQyNDRhXkEyXkFqcGc@._V1_.jpg"},
 {"mode":"playful","source_name":"movies_and_series","has_topic":false,"item_name":"inception","item_img":"https://m.media-amazon.com/images/M/MV5BMTc5NjY5NjY5Nl5BMl5BanBnXkFtZTcwNjY5NjY5Mw@@._V1_.jpg"},
  {"mode":"playful","source_name":"movies_and_series","has_topic":false,"item_name":"interstellar","item_img":"https://m.media-amazon.com/images/M/MV5BMjIxNTU4MzY4MF5BMl5BanBnXkFtZTgwNzUxNzE3MjE@._V1_.jpg"},
  {"mode":"playful","source_name":"movies_and_series","has_topic":false,"item_name":"the_dark_knight","item_img":"https://m.media-amazon.com/images/M/MV5BMTMxNTMwODM0NF5BMl5BanBnXkFtZTcwODAyMTk2Mw@@._V1_.jpg"},
  {"mode":"playful","source_name":"movies_and_series","has_topic":false,"item_name":"fight_club","item_img":"https://m.media-amazon.com/images/M/MV5BMmEzNTQwZDMtYzYzMy00ZTg3LWIyNWQtYTRmYjI2YzE0ZWRiXkEyXkFqcGdeQXVyNDYyMDk5MTU@._V1_.jpg"},
  {"mode":"playful","source_name":"movies_and_series","has_topic":false,"item_name":"pulp_fiction","item_img":"https://m.media-amazon.com/images/M/MV5BNGNhMDIzZTUtOTdiOS00YzYwLWI2NTEtODM0ZTAzZjNjNTc4XkEyXkFqcGdeQXVyNjU0OTQ0OTY@._V1_.jpg"}
]
''';

const seriousPayload = '''
[
  
  {"mode": "serious", "source_name": "books", "has_topic": false, "item_name": "the_great_gatsby", "item_img": "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5c/The_Great_Gatsby_%281924%29.jpg/1200px-The_Great_Gatsby_%281924%29.jpg"},
  {"mode": "serious", "source_name": "books", "has_topic": false, "item_name": "pride_and_prejudice", "item_img": "https://upload.wikimedia.org/wikipedia/commons/thumb/1/15/PrideAndPrejudiceTitlePage.jpg/800px-PrideAndPrejudiceTitlePage.jpg"},
  {"mode": "serious", "source_name": "books", "has_topic": false, "item_name": "moby_dick", "item_img": "https://upload.wikimedia.org/wikipedia/commons/4/41/Moby-Dick_FE_title_page.jpg"},
  {"mode": "serious", "source_name": "books", "has_topic": false, "item_name": "alice_in_wonderland", "item_img": "https://upload.wikimedia.org/wikipedia/commons/8/8b/Alice_in_Wonderland_%281st_ed_illustration%29.png"},

  
  {"mode": "serious", "source_name": "public_and_government", "has_topic": true, "item_name": "data_gov_us", "item_img": "https://www.data.gov/images/data-gov-logo.png"},
  {"mode": "serious", "source_name": "public_and_government", "has_topic": true, "item_name": "world_bank", "item_img": "https://upload.wikimedia.org/wikipedia/commons/5/5a/World_Bank_logo.svg"},
  {"mode": "serious", "source_name": "public_and_government", "has_topic": true, "item_name": "un_data", "item_img": "https://upload.wikimedia.org/wikipedia/commons/2/2f/United_Nations_emblem_blue.svg"},
  {"mode": "serious", "source_name": "public_and_government", "has_topic": true, "item_name": "european_union_open_data", "item_img": "https://upload.wikimedia.org/wikipedia/commons/b/b7/European_Union_logo_2020.svg"},

  
  {"mode": "serious", "source_name": "scientific_research", "has_topic": true, "item_name": "arxiv", "item_img": "https://commons.wikimedia.org/wiki/File:ArXiv_logo_2022.png"},
  {"mode": "serious", "source_name": "scientific_research", "has_topic": true, "item_name": "openalex", "item_img": "https://upload.wikimedia.org/wikipedia/commons/6/6b/OpenAlex-logo-5.2de7053c.png"},
  {"mode": "serious", "source_name": "scientific_research", "has_topic": true, "item_name": "pubmed", "item_img": "https://upload.wikimedia.org/wikipedia/commons/4/4a/PubMed_logo.png"},
  {"mode": "serious", "source_name": "scientific_research", "has_topic": true, "item_name": "science_direct", "item_img": "https://upload.wikimedia.org/wikipedia/commons/1/1c/ScienceDirect_logo.png"},

  
  {"mode": "serious", "source_name": "encyclopedic", "has_topic": true, "item_name": "wikipedia", "item_img": "https://upload.wikimedia.org/wikipedia/commons/6/63/Wikipedia-logo.png"},
  {"mode": "serious", "source_name": "encyclopedic", "has_topic": false, "item_name": "stanford_encyclopedia", "item_img": "https://plato.stanford.edu/icons/seop-logo.svg"},
  {"mode": "serious", "source_name": "encyclopedic", "has_topic": false, "item_name": "wiktionary", "item_img": "https://upload.wikimedia.org/wikipedia/commons/3/3b/Wiktionary-logo-en.svg"},
  {"mode": "serious", "source_name": "encyclopedic", "has_topic": false, "item_name": "britannica", "item_img": "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Britannica_encyclopaedia_logo.svg/800px-Britannica_encyclopaedia_logo.svg.png"}
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
