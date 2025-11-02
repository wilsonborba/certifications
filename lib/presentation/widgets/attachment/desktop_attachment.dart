
import 'package:accredit/core/settings.dart';
import 'package:accredit/domain/services/api_certification_manager.dart';
import 'package:accredit/presentation/components/attachment/app_bar.dart';
import 'package:accredit/presentation/components/attachment/want_app.dart';
import 'package:accredit/presentation/widgets/topics/on_topics.dart';
import 'package:flutter/material.dart';

import 'package:accredit/core/utils/my_logs.dart';
import 'package:accredit/core/utils/my_nagivation.dart';
import 'package:accredit/domain/models/source_item.dart';
import 'package:accredit/domain/models/mode_buckets.dart';


import 'package:accredit/presentation/components/attachment/tab_card_sources.dart';
import 'package:accredit/presentation/components/attachment/source_groups_list.dart';
import 'package:accredit/presentation/components/attachment/card_pdf_picker.dart';

import 'base_attachment.dart';

class DesktopAttachment extends BaseAttachment {
  
  const DesktopAttachment({super.key, required Future<List<SourceItem>> items})
      : super(items: items);

  @override
  State<DesktopAttachment> createState() => _DesktopAttachmentState();
}

class _DesktopAttachmentState extends BaseAttachmentState<DesktopAttachment> {
  @override
  void initState() {
    super.initState();
  }

  // ---- Layout identical to your original DesktopAttachment ----
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AttachmentAppBar(
    onCertificates: () { /* navigate */ },
    onTokens: () { /* navigate */ },
    onSupport: () => redirectToUrl('mailto:support@asodya.com'),
    onAbout:  (){
          final url = 'https://${app_settings.ASODYA_MAIN_DOMAIN}';
          redirectToUrl(url, replace: true);
        }, //QuizContextManager().getContext("from", "Flutter", forceNewGeneration: true, amountQuestion: 5); },
    // onLogout: () async { await clearSessionArtifacts(); /* custom redirect */ },
  ),
  endDrawer: AttachmentSideMenu(
    onCertificates: () { /* navigate */ },
    onTokens: () { /* navigate */ },
    onSupport: () => redirectToUrl('mailto:support@asodya.com'),
    onAbout:   (){
          final url = 'https://${app_settings.ASODYA_MAIN_DOMAIN}';
          redirectToUrl(url, replace: true);
        },
  ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            //const TopHeaders(isDesktop: true),
            const SizedBox(height: 200),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      FutureBuilder<List<SourceItem>>(
                        future: widget.items,
                        builder: (context, snapshot) {
                          final body = buildBody(context, snapshot);

                          // Only show WantText if the future completed successfully
                          if (snapshot.connectionState == ConnectionState.done &&
                              snapshot.hasData) {
                            return Column(
                              children: [
                                body,
                                const SizedBox(height: 10),
                                WantText(onRequest: (url) async {
                                  final manager = CardItemsManager();
                                  final response =
                                      await manager.requestNewCards(url);
                                      if (response.statusCode == 201) {}
      // Optionally, you can refresh the list of cards here
                                }),
                              ],
                            );
                          }

                          // Otherwise, just return the body (loading/error states, etc.)
                          return body;
                        },
                      ),
                    ],
                  )
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

  // ---- Keep the exact error widget & behavior you had on desktop ----
  @override
  Widget buildError(Object? error) {
    warning('Cards load error: $error');
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Failed to load cards'),
          const SizedBox(height: 8),
          const Text(
            "Please contact our support at support@asodya.com if the issue persists.",
            style: TextStyle(fontSize: 12, color: Colors.redAccent),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => redirectToUrl('mailto:support@asodya.com'),
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  // ---- Keep the exact TabCardSources props you had on desktop ----
  @override
  Widget buildTabs(ModeBuckets buckets) {
    return TabCardSources(
      leftLabel: 'Playful Mode',
      rightLabel: 'Serious Mode',
      leftChild: SourceGroupsList(
        items: buckets.playful,
       onTapWithTopic: (item) => {
                  NavigationService.push(OnTopicsScreen(itemName: item.itemName))
                },
                onTapWithoutTopic: (item) => {
                  NavigationService.push(OnTopicsScreen(itemName: item.itemName))
                },
        onSeeMore: (sourceName) => {},
      ),
      rightChild: SourceGroupsList(
        items: buckets.serious,
        onTapWithTopic: (item) => {
                  NavigationService.push(OnTopicsScreen(itemName: item.itemName))
                },
                onTapWithoutTopic: (item) => {
                  NavigationService.push(OnTopicsScreen(itemName: item.itemName))
                },
        onSeeMore: (sourceName) => {},
      ),
    );
  }
}
