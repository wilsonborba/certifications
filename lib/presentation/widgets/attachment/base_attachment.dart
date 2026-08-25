import 'package:accredit/presentation/components/quiz/futuristic_loading.dart';
import 'package:flutter/material.dart';
import 'package:accredit/domain/models/source_item.dart';
import 'package:accredit/domain/models/mode_buckets.dart';

/// BaseAttachment is a StatefulWidget holding shared logic for Mobile/Desktop
abstract class BaseAttachment extends StatefulWidget {
  final Future<List<SourceItem>> items;
  const BaseAttachment({super.key, required this.items});
}

/// Shared state with common helpers. Subclasses implement:
/// - buildError(Object? error)
/// - buildTabs(ModeBuckets buckets)
abstract class BaseAttachmentState<T extends BaseAttachment> extends State<T> {
  // ---- Business Logic (shared) ----
  String normalizedMode(SourceItem s) => (s.mode).toLowerCase().trim();

  ModeBuckets partitionByMode(List<SourceItem> items) {
    final playful = <SourceItem>[];
    final serious = <SourceItem>[];

    for (final s in items) {
      final m = normalizedMode(s);
      final isPlayful = m == 'playful' || m == 'both';
      final isSerious = m == 'serious' || m == 'both';

      if (isPlayful) playful.add(s);
      if (isSerious) serious.add(s);
    }
    return ModeBuckets(playful: playful, serious: serious);
  }

  // ---- Body dispatcher (shared) ----
  Widget buildBody(BuildContext context, AsyncSnapshot<List<SourceItem>> snap) {
    if (snap.connectionState == ConnectionState.waiting) {
      return buildLoading(snap.connectionState == ConnectionState.waiting);
    }
    if (snap.hasError) {
      return buildError(snap.error);
    }

    final items = snap.data ?? const <SourceItem>[];
    if (items.isEmpty) {
      return buildEmpty();
    }

    final buckets = partitionByMode(items);
    return buildTabs(buckets);
  }

  // ---- UI pieces (mostly shared) ----
  Widget buildLoading(bool loading) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: FuturisticLoading(
        messages: [
          "We are loading your sources…",
          "Just a moment, fetching data…",
          "Preparing your cards…",
          "Almost there, hang tight…",
          "Tip: You have 1 minute per question!",
          "Tip: You can answer between 1 up to 15 questions.",
        ],
        isActive: loading,
        transparentBackground: true,
        //imageAsset: "lib/presentation/assets/img/temp_logo.png", // optional, remove if not used
      ),
    );
  }

  Widget buildEmpty() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Text('No cards available'),
    );
  }

  // Subclasses must provide these to keep their exact behavior/props
  Widget buildError(Object? error);
  Widget buildTabs(ModeBuckets buckets);
}
