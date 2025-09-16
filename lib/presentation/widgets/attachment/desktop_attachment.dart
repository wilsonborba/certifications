import 'package:accredit/core/utils/my_nagivation.dart';
import 'package:accredit/domain/models/mode_buckets.dart';
import 'package:flutter/material.dart';

import 'package:accredit/core/utils/my_logs.dart';
import 'package:accredit/domain/models/source_item.dart';

import 'package:accredit/presentation/components/attachment/source_groups_list.dart';
import 'package:accredit/presentation/components/attachment/tab_card_sources.dart';
import 'package:accredit/presentation/components/attachment/card_pdf_picker.dart';
import 'package:accredit/presentation/components/attachment/top_headers.dart';

class DesktopAttachment extends StatefulWidget {
  final Future<List<SourceItem>> items;
  const DesktopAttachment({super.key, required this.items});

  @override
  State<DesktopAttachment> createState() => _DesktopAttachmentState();
}

class _DesktopAttachmentState extends State<DesktopAttachment> {
  

  @override
  void initState() {
    super.initState();
    
  }


  /// ---- Business Logic ----
  String _normalizedMode(SourceItem s) =>
      (s.mode ?? '').toLowerCase().trim(); // guards & consistent

  ModeBuckets _partitionByMode(List<SourceItem> items) {
    final playful = <SourceItem>[];
    final serious = <SourceItem>[];

    for (final s in items) {
      final m = _normalizedMode(s);
      final isPlayful = m == 'playful' || m == 'both';
      final isSerious = m == 'serious' || m == 'both';

      if (isPlayful) playful.add(s);
      if (isSerious) serious.add(s);
    }

    // debug('Partitioned → playful: ${playful.length}, serious: ${serious.length}');
    return ModeBuckets(playful: playful, serious: serious);
  }

  /// ---- UI Composition ----
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
                      builder: (context, snap) => _buildBody(context, snap),
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

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<List<SourceItem>> snap,
  ) {
    if (snap.connectionState == ConnectionState.waiting) {
      return _buildLoading();
    }
    if (snap.hasError) {
      return _buildError(snap.error);
    }

    final items = snap.data ?? const <SourceItem>[];
    if (items.isEmpty) {
      return _buildEmpty();
    }

    final buckets = _partitionByMode(items);
    return _buildTabs(buckets);
  }

  /// ---- UI Pieces ----
  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildError(Object? error) {
    debug('Cards load error: $error');
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Failed to load cards'),
          const SizedBox(height: 8),
          Text(
            "Please contact our support at support@asodya.com if the issue persists.",
            style: const TextStyle(fontSize: 12, color: Colors.redAccent),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              // Implement contact support action, e.g., open email client
              redirectToUrl('mailto:support@asodya.com');
            },
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Text('No cards available'),
    );
  }

  Widget _buildTabs(ModeBuckets buckets) {
    return TabCardSources(
      leftLabel: 'Playful Mode',
      rightLabel: 'Serious Mode',
      leftChild: SourceGroupsList(
        items: buckets.playful,
        onTapWithTopic: (item) =>
            {},
        onTapWithoutTopic: (item) =>
            {},
        onSeeMore: (sourceName) => {},
      ),
      rightChild: SourceGroupsList(
        items: buckets.serious,
        onTapWithTopic: (item) =>
            {},
        onTapWithoutTopic: (item) =>
            {},
        onSeeMore: (sourceName) => {},
      ),
    );
  }
}

