import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/quiz_wizard_data.dart';
import 'package:flutter/material.dart';

/// Icon and accent color used to visually badge a file by its extension.
/// Shared between [GranularRangeSelector] and the quiz wizard's file chips.
({Color color, IconData icon}) fileKindVisual(String kind) {
  switch (kind) {
    case 'pdf':
      return (color: Colors.redAccent, icon: Icons.picture_as_pdf);
    case 'docx':
    case 'doc':
      return (color: Colors.blueAccent, icon: Icons.description);
    case 'csv':
      return (color: Colors.green, icon: Icons.table_chart);
    case 'mp3':
    case 'wav':
    case 'm4a':
      return (color: Colors.purpleAccent, icon: Icons.audiotrack);
    case 'mp4':
    case 'mov':
      return (color: Colors.orangeAccent, icon: Icons.video_library);
    default:
      return (color: Colors.blueGrey, icon: Icons.insert_drive_file);
  }
}

/// Human-readable file size, switching from KB to MB above 1 MB.
String formatFileSize(int bytes) {
  final mb = bytes / (1024 * 1024);
  if (mb >= 1) return '${mb.toStringAsFixed(2)} MB';
  final kb = bytes / 1024;
  return '${kb.toStringAsFixed(0)} KB';
}

/// Callback signature used by [GranularRangeSelector] to report a range
/// change back to the [QuizWizardData] entry that owns the file being
/// configured. Mirrors [QuizWizardData.updateFileRange]'s named parameters
/// exactly so callers can pass that method in directly (bound to the file's
/// index) without an adapter.
typedef RangeUpdateCallback =
    void Function({
      bool? isWholeDocument,
      int? pageStart,
      int? pageEnd,
      int? lineStart,
      int? lineEnd,
      int? audioStartMs,
      int? audioEndMs,
    });

/// "Phase B" of Step 2's file selection: whole-document-by-default range
/// configuration for a single already-attached file. Rendered collapsed by
/// default inside an accordion under that file's chip in the Phase A strip;
/// only expands when the user wants to trim that specific file.
class GranularRangeSelector extends StatelessWidget {
  const GranularRangeSelector({
    super.key,
    required this.file,
    required this.onUpdate,
    required this.isDesktop,
  });

  final AttachedFile file;
  final RangeUpdateCallback onUpdate;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final kind = file.kind.toLowerCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('rangeSelectorTitle'),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: true,
                label: Text(context.tr('wholeDocument')),
                icon: const Icon(Icons.select_all),
              ),
              ButtonSegment(
                value: false,
                label: Text(context.tr('selectRange')),
                icon: const Icon(Icons.tune),
              ),
            ],
            selected: {file.isWholeDocument},
            onSelectionChanged: (set) {
              onUpdate(isWholeDocument: set.first);
            },
          ),
          if (!file.isWholeDocument) ...[
            const SizedBox(height: 16),
            _buildRangeControls(context, kind),
          ],
        ],
      ),
    );
  }

  Widget _buildRangeControls(BuildContext context, String kind) {
    final scheme = Theme.of(context).colorScheme;

    if (kind == 'pdf' || kind == 'docx' || kind == 'doc') {
      return Row(
        children: [
          Expanded(
            child: TextField(
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: '${file.pageStart}'),
              onChanged: (val) {
                final p = int.tryParse(val);
                if (p != null && p >= 1) onUpdate(pageStart: p);
              },
              decoration: InputDecoration(
                labelText: context.tr('pageStartLabel'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(context.tr('rangeUntil'), style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7))),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: '${file.pageEnd}'),
              onChanged: (val) {
                final p = int.tryParse(val);
                if (p != null && p >= file.pageStart) {
                  onUpdate(pageEnd: p);
                }
              },
              decoration: InputDecoration(
                labelText: context.tr('pageEndLabel'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      );
    }

    if (kind == 'csv' || kind == 'txt' || kind == 'md') {
      return Row(
        children: [
          Expanded(
            child: TextField(
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: '${file.lineStart}'),
              onChanged: (val) {
                final l = int.tryParse(val);
                if (l != null && l >= 1) onUpdate(lineStart: l);
              },
              decoration: InputDecoration(
                labelText: context.tr('lineStartLabel'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(context.tr('rangeUntil'), style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7))),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: '${file.lineEnd}'),
              onChanged: (val) {
                final l = int.tryParse(val);
                if (l != null && l >= file.lineStart) {
                  onUpdate(lineEnd: l);
                }
              },
              decoration: InputDecoration(
                labelText: context.tr('lineEndLabel'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      );
    }

    // Audio or video timestamp range.
    final startMin = (file.audioStartMs / 60000).floor();
    final endMin = (file.audioEndMs / 60000).floor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${context.tr('timeRangeLabel')} ${startMin}min ${context.tr('rangeUntil')} ${endMin}min',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        RangeSlider(
          values: RangeValues(startMin.toDouble(), endMin.toDouble()),
          min: 0,
          max: 60,
          divisions: 60,
          labels: RangeLabels('${startMin}m', '${endMin}m'),
          onChanged: (values) {
            onUpdate(
              audioStartMs: (values.start * 60000).toInt(),
              audioEndMs: (values.end * 60000).toInt(),
            );
          },
        ),
      ],
    );
  }
}
