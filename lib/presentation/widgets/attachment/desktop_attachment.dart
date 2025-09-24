import 'package:flutter/material.dart';

import 'package:accredit/core/utils/my_logs.dart';
import 'package:accredit/core/utils/my_nagivation.dart';
import 'package:accredit/domain/models/source_item.dart';
import 'package:accredit/domain/models/mode_buckets.dart';

import 'package:accredit/presentation/components/attachment/top_headers.dart';
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
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            const TopHeaders(isDesktop: true),
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: FutureBuilder<List<SourceItem>>(
                      future: widget.items,
                      builder: (context, snap) => buildBody(context, snap),
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
          fetchTopicsForCard(item.itemName).then((topics) {
            debug('Topics for ${item.itemName}: $topics');
            // Handle topics (e.g., show a dialog or navigate)
          }).catchError((error) {
            warning('Failed to fetch topics for ${item.itemName}: $error');
            // Handle error (e.g., show a snackbar)
          })},
        onTapWithoutTopic: (item) => {
          debug('Tapped on item without topic: ${item.itemName}')
        },
        onSeeMore: (sourceName) => {},
      ),
      rightChild: SourceGroupsList(
        items: buckets.serious,
        onTapWithTopic: (item) => {
          fetchTopicsForCard(item.itemName).then((topics) {
            debug('Topics for ${item.itemName}: $topics');
            // Handle topics (e.g., show a dialog or navigate)
          }).catchError((error) {
            warning('Failed to fetch topics for ${item.itemName}: $error');
            // Handle error (e.g., show a snackbar)
          })
        },
        onTapWithoutTopic: (item) => {
          debug('Tapped on item without topic: ${item.itemName}')
        },
        onSeeMore: (sourceName) => {},
      ),
    );
  }
}
