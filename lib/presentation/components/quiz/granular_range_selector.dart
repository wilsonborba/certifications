import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/quiz_wizard_data.dart';
import 'package:flutter/material.dart';

/// Icon and accent color used to visually badge a file by its extension.
/// Shared between [GranularRangeSelector] and the quiz wizard's file preview.
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

class GranularRangeSelector extends StatelessWidget {
  const GranularRangeSelector({
    super.key,
    required this.wizardData,
    required this.isDesktop,
  });

  final QuizWizardData wizardData;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fileKind = wizardData.fileKind?.toLowerCase() ?? 'pdf';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildFileKindBadge(fileKind),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wizardData.fileName ?? context.tr('unknownFileName'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (wizardData.fileBytes != null)
                      Text(
                        formatFileSize(wizardData.fileBytes!.length),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: context.tr('removeFile'),
                onPressed: () => wizardData.clearFile(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
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
            selected: {wizardData.isWholeDocument},
            onSelectionChanged: (set) {
              wizardData.updateRange(isWholeDocument: set.first);
            },
          ),
          if (!wizardData.isWholeDocument) ...[
            const SizedBox(height: 16),
            _buildRangeControls(context, fileKind),
          ],
        ],
      ),
    );
  }

  Widget _buildFileKindBadge(String kind) {
    final visual = fileKindVisual(kind);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: visual.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(visual.icon, color: visual.color, size: 24),
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
              controller: TextEditingController(text: '${wizardData.pageStart}'),
              onChanged: (val) {
                final p = int.tryParse(val);
                if (p != null && p >= 1) wizardData.updateRange(pageStart: p);
              },
              decoration: InputDecoration(
                labelText: context.tr('pageStartLabel'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(context.tr('rangeUntil'), style: TextStyle(color: scheme.onSurface.withOpacity(0.7))),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: '${wizardData.pageEnd}'),
              onChanged: (val) {
                final p = int.tryParse(val);
                if (p != null && p >= wizardData.pageStart) {
                  wizardData.updateRange(pageEnd: p);
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
              controller: TextEditingController(text: '${wizardData.lineStart}'),
              onChanged: (val) {
                final l = int.tryParse(val);
                if (l != null && l >= 1) wizardData.updateRange(lineStart: l);
              },
              decoration: InputDecoration(
                labelText: context.tr('lineStartLabel'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(context.tr('rangeUntil'), style: TextStyle(color: scheme.onSurface.withOpacity(0.7))),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: '${wizardData.lineEnd}'),
              onChanged: (val) {
                final l = int.tryParse(val);
                if (l != null && l >= wizardData.lineStart) {
                  wizardData.updateRange(lineEnd: l);
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

    // Audio or Video timestamp range
    final startMin = (wizardData.audioStartMs / 60000).floor();
    final endMin = (wizardData.audioEndMs / 60000).floor();

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
            wizardData.updateRange(
              audioStartMs: (values.start * 60000).toInt(),
              audioEndMs: (values.end * 60000).toInt(),
            );
          },
        ),
      ],
    );
  }
}
