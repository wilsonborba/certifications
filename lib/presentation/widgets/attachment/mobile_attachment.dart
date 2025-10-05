import 'package:accredit/presentation/components/attachment/app_bar.dart';
import 'package:accredit/presentation/widgets/topics/on_topics.dart';
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

class MobileAttachment extends BaseAttachment {
  const MobileAttachment({super.key, required Future<List<SourceItem>> items})
      : super(items: items);

  @override
  State<MobileAttachment> createState() => _MobileAttachmentState();
}

class _MobileAttachmentState extends BaseAttachmentState<MobileAttachment> {
  @override
  void initState() {
    super.initState();
  }

  // ---- Layout identical to your original MobileAttachment ----
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AttachmentAppBar(
    onCertificates: () { /* navigate */ },
    onTokens: () { /* navigate */ },
    onSupport: () { /* navigate */ },
    onAbout:   () { /* navigate */ },
    // onLogout: () async { await clearSessionArtifacts(); /* custom redirect */ },
  ),
  endDrawer: AttachmentSideMenu(
    onCertificates: () { /* navigate */ },
    onTokens: () { /* navigate */ },
    onSupport: () { /* navigate */ },
    onAbout:   () { /* navigate */ },
  ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TopHeaders(isDesktop: false),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: FutureBuilder<List<SourceItem>>(
                  future: widget.items,
                  builder: (context, snap) => buildBody(context, snap),
                ),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: CardPdfPicker(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Keep the exact error widget & behavior you had on mobile ----
  @override
  Widget buildError(Object? error) {
    debug('Cards load error: $error');
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

  // ---- Keep the exact TabCardSources props you had on mobile ----
  @override
  Widget buildTabs(ModeBuckets buckets) {
    return TabCardSources(
      leftLabel: 'Playful Mode',
      rightLabel: 'Serious Mode',
      cardWidth: 400,
      spacing: 6,
      toggleWidth: 220,
      toggleHeight: 35,
      leftChild: SourceGroupsList(
        items: buckets.playful,
        tileSize: 60,
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
        tileSize: 60,
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
