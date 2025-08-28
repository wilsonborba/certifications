import 'dart:typed_data';
import 'dart:ui' as ui show ImageByteFormat, Image;
import 'package:crypto/crypto.dart' as crypto;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:accredit/core/utils/my_pdf_frontend_prescan.dart' as pre;
import 'package:printing/printing.dart';

class CardPdfPicker extends StatefulWidget {
  const CardPdfPicker({
    super.key,
    this.width = 520,
    this.height = 720,
    this.cornerRadius = 36,
    this.iconSize = 64,
    this.titleSize = 28,
    this.bodySize = 20,
    this.buttonFontSize = 20,
    this.buttonMinSize = const Size(220, 64),
  });

  final double width;
  final double height;
  final double cornerRadius;
  final double iconSize;
  final double titleSize;
  final double bodySize;
  final double buttonFontSize;
  final Size buttonMinSize;

  @override
  State<CardPdfPicker> createState() => _CardPdfPickerState();
}

class _CardPdfPickerState extends State<CardPdfPicker> {
  Uint8List? _pdfBytes;
  Uint8List? _previewPng; // first page as PNG
  String? _fileName;
  String? _error;
  bool _busy = false;

  Future<void> _pickPdf() async {
    setState(() {
      _error = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true, // important for web
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (file.bytes == null) {
      setState(() => _error = 'Could not read file bytes.');
      return;
    }
    if (!(file.extension?.toLowerCase() == 'pdf')) {
      setState(() => _error = 'Only PDF files are allowed.');
      return;
    }

    setState(() {
      _busy = true;
      _fileName = file.name;
      _pdfBytes = file.bytes!;
      _previewPng = null;
    });

    // ---- Optional “virus check” hook (client-side placeholder) ----
    // You generally cannot do real AV scanning purely on the client.
    // Typical pattern: upload to your backend → scan with a service → accept/reject.
    // As a lightweight client check, you can hash the file and send hash to a reputation API.
    final hash = crypto.sha256.convert(_pdfBytes!).toString();
    final safe = await _fakeCheckFileHashForThreat(hash); // replace later
    if (!safe) {
      setState(() {
        _busy = false;
        _error = 'File flagged by reputation check.';
      });
      return;
    }

    try {
      // Rasterize only page 1 (index 0). Increase dpi for sharper preview.
      final stream = Printing.raster(_pdfBytes!, pages: const [0], dpi: 144);
      final raster = await stream.first;                // PdfRaster
      final ui.Image img = await raster.toImage();      // convert to ui.Image
      final byteData =
          await img.toByteData(format: ui.ImageByteFormat.png);
      final png = byteData!.buffer.asUint8List();

      // (optional) img.dispose();  // if you're on a Flutter version with ui.Image.dispose()

      setState(() {
        _previewPng = png;
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = 'Failed to render preview: $e';
      });
    }
  }
  // Stub: always returns true. Replace with your backend call later.
  Future<bool> _fakeCheckFileHashForThreat(String sha256) {
    // You can pass bytes/name/mime now for full checks:
    return pre.fakeCheckFileHashForThreat(
      sha256,
      bytes: _pdfBytes,           // your picked bytes
      fileName: _fileName,        // optional
      mimeType: 'application/pdf' // optional (from dropzone if you have it)
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          // color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(widget.cornerRadius),
           border: Border.all(color: Colors.black12),
          // boxShadow: const [
          //   BoxShadow(
          //     color: Colors.black26,
          //     blurRadius: 18,
          //     offset: Offset(0, 10),
          //   )
          // ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            children: [
              // Red warning icon
              _fileName == null ? Icon(
                Icons.report_gmailerrorred_outlined,
                size: widget.iconSize,
                color: const Color(0xFFB00020),
              ) : Icon(
                Icons.picture_as_pdf,
                size: widget.iconSize,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                _fileName == null ? 'No Files Attached Yet.' : _fileName!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: widget.titleSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 18),

              // Body (with bold segment)
              _fileName == null ? RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: widget.bodySize,
                    color: Colors.black87,
                    height: 1.35,
                  ),
                  children:  [
                    TextSpan(text: '\n\n'),
                    TextSpan(
                      text: 'Click on button to attach a file',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ) : Text(
                'You can attach another file if you want.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: widget.bodySize,
                  color: Colors.black87,
                  height: 1.35,
                ),
              ),

              const Spacer(),

              // Preview area
              Container(
                height: 350,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black12),
                ),
                alignment: Alignment.center,
                child: _busy
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      )
                    : (_previewPng != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(
                              _previewPng!,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.medium,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          )
                        : Text(
                            'PDF preview will appear here',
                            style: theme.textTheme.bodyMedium!
                                .copyWith(color: Colors.black54),
                          )),
              ),

              const SizedBox(height: 24),

              // Attach button
              SizedBox(
                width: 260,
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _pickPdf,
                  icon: const Icon(Icons.attachment, size: 22),
                  label: Text(
                    'Attach File',
                    style: TextStyle(
                      fontSize: widget.buttonFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: widget.buttonMinSize,
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 6,
                    shadowColor: Colors.black45,
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  "Sorry, we could not upload due to some unknown error.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFB00020),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
