import 'package:accredit/core/settings.dart';
import 'package:accredit/domain/services/api_certification_manager.dart';
import 'package:accredit/presentation/components/attachment/app_bar.dart';
import 'package:accredit/presentation/components/attachment/want_app.dart';
import 'package:accredit/presentation/widgets/certifications/on_certifications.dart';
import 'package:accredit/presentation/widgets/plans/on_plans.dart';
import 'package:accredit/presentation/widgets/tokens/on_tokens.dart';
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
        onCertificates: () {
          NavigationService.push(const OnCertificationsScreen());
        },
        onPlans: () {
          NavigationService.push(const OnPlansScreen());
        },
        onTokens: () {
          NavigationService.push(OnTokensScreen());
        },
        onSupport: () => redirectToUrl('mailto:support@asodya.com'),
        onAbout: () {
          final url = 'https://${app_settings.ASODYA_MAIN_DOMAIN}';
          redirectToUrl(url, replace: true);
        },
        // onLogout: () async { await clearSessionArtifacts(); /* custom redirect */ },
      ),
      endDrawer: AttachmentSideMenu(
        onCertificates: () {
          NavigationService.push(const OnCertificationsScreen());
        },
        onPlans: () {
          NavigationService.push(const OnPlansScreen());
        },
        onTokens: () {
          NavigationService.push(OnTokensScreen());
        },
        onSupport: () => redirectToUrl('mailto:support@asodya.com'),
        onAbout: () {
          final url = 'https://${app_settings.ASODYA_MAIN_DOMAIN}';
          redirectToUrl(url, replace: true);
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              //const TopHeaders(isDesktop: false),
              const SizedBox(height: 200),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: FutureBuilder<List<SourceItem>>(
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
                          WantText(
                            onRequest: (url) async {
                              final manager = CertificationManager();
                              final response = await manager.requestNewCards(
                                url,
                              );
                              if (response.statusCode == 201) {}
                              // Optionally, you can refresh the list of cards here
                            },
                          ),
                        ],
                      );
                    }

                    // Otherwise, just return the body (loading/error states, etc.)
                    return body;
                  },
                ),
              ),
              const SizedBox(height: 40),
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
          NavigationService.push(OnTopicsScreen(itemName: item.itemName)),
        },
        onTapWithoutTopic: (item) => {
          NavigationService.push(OnTopicsScreen(itemName: item.itemName)),
        },
        onSeeMore: (sourceName) => {},
      ),
      rightChild: SourceGroupsList(
        items: buckets.serious,
        tileSize: 60,
        onTapWithTopic: (item) => {
          NavigationService.push(OnTopicsScreen(itemName: item.itemName)),
        },
        onTapWithoutTopic: (item) => {
          NavigationService.push(OnTopicsScreen(itemName: item.itemName)),
        },
        onSeeMore: (sourceName) => {},
      ),
    );
  }
}
