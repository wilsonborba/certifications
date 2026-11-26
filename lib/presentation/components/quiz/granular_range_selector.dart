import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/quiz_wizard_data.dart';
import 'package:certifications/domain/models/study_selection.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

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

/// Preview for an attached source with selections matching the Rust API.
class GranularRangeSelector extends StatefulWidget {
  const GranularRangeSelector({
    super.key,
    required this.file,
    required this.isDesktop,
  });

  final AttachedFile file;
  final bool isDesktop;

  @override
  State<GranularRangeSelector> createState() => _GranularRangeSelectorState();
}

class _GranularRangeSelectorState extends State<GranularRangeSelector> {
  static int _nextPdfViewId = 0;

  late final TextEditingController _spec = TextEditingController(
    text: widget.file.selectionSpec,
  );
  String? _pdfViewType;
  String? _pdfObjectUrl;

  @override
  void initState() {
    super.initState();
    if (widget.file.kind.toLowerCase() == 'pdf') {
      final viewId = ++_nextPdfViewId;
      _pdfViewType = 'study-source-pdf-$viewId';
      final blob = web.Blob(
        [Uint8List.fromList(widget.file.bytes).toJS].toJS,
        web.BlobPropertyBag(type: 'application/pdf'),
      );
      _pdfObjectUrl = web.URL.createObjectURL(blob);
      ui_web.platformViewRegistry.registerViewFactory(_pdfViewType!, (int _) {
        final frame = web.HTMLIFrameElement()
          ..src = _pdfObjectUrl!
          ..title = 'PDF source preview';
        frame.style
          ..border = '0'
          ..width = '100%'
          ..height = '100%';
        return frame;
      });
    }
  }

  String? get _canonical {
    final kind = widget.file.kind.toLowerCase();
    if (kind == 'pdf') {
      return StudySelection.pages(
        _spec.text,
        pageCount: widget.file.totalPages,
      );
    }
    if (kind == 'txt' || kind == 'md' || kind == 'csv') {
      return StudySelection.passage(
        _spec.text,
        StudySelection.normalizeText(utf8.decode(widget.file.bytes)),
      );
    }
    if (kind == 'mp3' || kind == 'wav' || kind == 'm4a') {
      return StudySelection.audio(_spec.text);
    }
    return null;
  }

  @override
  void dispose() {
    _spec.dispose();
    if (_pdfObjectUrl case final url?) web.URL.revokeObjectURL(url);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.file;
    final scheme = Theme.of(context).colorScheme;
    final kind = file.kind.toLowerCase();
    final isPdf = kind == 'pdf';
    final isText = kind == 'txt' || kind == 'md' || kind == 'csv';
    final isAudio = kind == 'mp3' || kind == 'wav' || kind == 'm4a';
    final canSelect = isPdf || isText || isAudio;

    return Container(
      padding: EdgeInsets.all(widget.isDesktop ? 20 : 14),
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
          if (canSelect) ...[
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: file.isWholeDocument,
              title: Text(context.tr('wholeDocumentOnly')),
              onChanged: (value) => setState(() {
                file.isWholeDocument = value ?? true;
                file.selectionKind = file.isWholeDocument
                    ? 'all'
                    : isPdf
                    ? 'pages'
                    : isText
                    ? 'passages'
                    : 'intervals';
                file.selectionSpec = file.isWholeDocument ? '' : _spec.text;
              }),
            ),
            if (!file.isWholeDocument) ...[
              TextField(
                controller: _spec,
                decoration: InputDecoration(
                  labelText: isPdf
                      ? context.tr('selectionPagesLabel')
                      : isText
                      ? context.tr('selectionPassageLabel')
                      : context.tr('selectionAudioLabel'),
                  hintText: isPdf
                      ? '1-3,5'
                      : isText
                      ? 'p1:0-25'
                      : 'ms:0-12500,30000-45000',
                  helperText: _canonical == null
                      ? context.tr('selectionInvalid')
                      : null,
                  errorText: _canonical == null
                      ? context.tr('selectionInvalid')
                      : null,
                ),
                onChanged: (value) => setState(() {
                  file.selectionSpec = value;
                  file.selectionKind = isPdf
                      ? 'pages'
                      : isText
                      ? 'passages'
                      : 'intervals';
                  file.isWholeDocument = false;
                }),
              ),
            ],
          ] else
            Text(
              context.tr('wholeDocumentOnly'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          if (isPdf) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: widget.isDesktop ? 480 : 360,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: HtmlElementView(viewType: _pdfViewType!),
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
                  StudySelection.normalizeText(
                    utf8.decode(file.bytes, allowMalformed: true),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
