import 'dart:convert';
import 'dart:typed_data';

import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/quiz_wizard_data.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

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
    case 'xlsx':
      return (color: Colors.green, icon: Icons.table_chart);
    case 'png':
    case 'jpg':
    case 'jpeg':
    case 'webp':
      return (color: Colors.teal, icon: Icons.image_outlined);
    case 'mp3':
    case 'wav':
    case 'm4a':
      return (color: Colors.purpleAccent, icon: Icons.audiotrack);
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

/// Preview for an attached source. Narrow selection remains unavailable
/// until the backend publishes a contract that enforces its meaning.
class GranularRangeSelector extends StatelessWidget {
  const GranularRangeSelector({
    super.key,
    required this.file,
    required this.isDesktop,
  });

  final AttachedFile file;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final kind = file.kind.toLowerCase();
    final isPdf = kind == 'pdf';
    final isText = kind == 'txt' || kind == 'md';
    final isAudio = kind == 'mp3' || kind == 'wav' || kind == 'm4a';

    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('sourcePreviewTitle'),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          if (isPdf || isText || isAudio)
            Text(
              isAudio
                  ? context.tr('audioRangeUnavailable')
                  : context.tr('narrowSelectionUnavailable'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            )
          else
            Text(
              context.tr('wholeDocumentOnly'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          if (isPdf) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: isDesktop ? 480 : 360,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SfPdfViewer.memory(
                  Uint8List.fromList(file.bytes),
                  enableTextSelection: false,
                  canShowScrollHead: false,
                  canShowScrollStatus: true,
                ),
              ),
            ),
          ] else if (isText) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 360),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  utf8.decode(file.bytes, allowMalformed: true),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
