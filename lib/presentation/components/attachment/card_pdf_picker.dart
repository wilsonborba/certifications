import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'dart:ui' as ui show ImageByteFormat, Image;

import 'package:accredit/core/utils/my_logs.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:accredit/domain/services/pdf_frontend_prescan_manager.dart' as pre;
import 'package:printing/printing.dart';

class CardPdfPicker extends StatefulWidget {
  const CardPdfPicker({
    super.key,
    this.width = 520,
    this.height = 720,
    this.cornerRadius = 36,
    this.iconSize = 64,
    this.titleSize = 22,
    this.bodySize = 16,
    this.buttonFontSize = 16,
    this.buttonMinSize = const Size(220, 64),

    // Optional: tweak prescan policy if your manager exposes PreScanConfig
    this.preScanConfig = const pre.PreScanConfig(
      maxBytes: 20 * 1024 * 1024,
      minBytes: 512,
      blockOnJavaScript: true,
      blockOnAutoActions: true,
      expectedMime: 'application/pdf',
    ),

    // API defaults (same as your curl)
    this.apiBase = 'http://127.0.0.1:8001',
    this.ocrForce = false,
    this.ocrLang = 'eng',
    this.ocrDpi = 300,
    this.maxChars = 8000,
    this.overlapChars = 400,
  });

  final double width;
  final double height;
  final double cornerRadius;
  final double iconSize;
  final double titleSize;
  final double bodySize;
  final double buttonFontSize;
  final Size buttonMinSize;

  final pre.PreScanConfig preScanConfig;

  // FastAPI params
  final String apiBase;
  final bool ocrForce;
  final String ocrLang;
  final int ocrDpi;
  final int maxChars;
  final int overlapChars;

  @override
  State<CardPdfPicker> createState() => _CardPdfPickerState();
}

class _CardPdfPickerState extends State<CardPdfPicker> {
  Uint8List? _pdfBytes;
  Uint8List? _previewPng; // first page as PNG
  String? _fileName;
  String? _error;
  bool _busy = false;

  // --- Loading phrase ticker ---
  Timer? _loadingTicker;
  int _loadingIndex = 0;
  final List<String> _loadingPhrases = const [
    'Loading PDF…',
    'Verifying file…',
    'Scanning PDF…',
    'Checking safety…',
    'Preparing preview…',
    'Uploading to server…',
    'Caching (30 min)…',
  ];

  void _startLoadingTicker() {
    _loadingTicker?.cancel();
    _loadingIndex = 0;
    _loadingTicker = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      setState(() {
        _loadingIndex = (_loadingIndex + 1) % _loadingPhrases.length;
      });
    });
  }

  void _stopLoadingTicker() {
    _loadingTicker?.cancel();
    _loadingTicker = null;
    _loadingIndex = 0;
  }

  @override
  void dispose() {
    _stopLoadingTicker();
    super.dispose();
  }

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
    if ((file.extension?.toLowerCase() != 'pdf')) {
      setState(() => _error = 'Only PDF files are allowed.');
      return;
    }

    // Begin full flow on attach: prescan → preview → upload
    setState(() {
      _busy = true;
      _fileName = file.name;
      _pdfBytes = file.bytes!;
      _previewPng = null;
    });
    _startLoadingTicker();

    // 1) Hash + PreScan (client)
    final sha256 = crypto.sha256.convert(_pdfBytes!).toString();
    try {
      final scan = await pre.frontEndPreScan(
        bytes: _pdfBytes!,
        sha256: sha256,
        fileName: _fileName,
        mime: 'application/pdf',
        config: widget.preScanConfig,
      );

      if (!scan.isAcceptable) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _error = 'File did not pass safety checks.';
        });
        _stopLoadingTicker();
        _showDialog(
          title: 'File blocked',
          message: scan.flags.isEmpty
              ? 'Blocked by policy.'
              : scan.flags.take(6).join('\n• '),
        );
        return;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'PreScan failed.';
      });
      _stopLoadingTicker();
      _showDialog(title: 'PreScan error', message: 'An error occurred during file checks.');
      return;
    }

    // 2) Preview (only after prescan passes)
    try {
      final stream = Printing.raster(_pdfBytes!, pages: const [0], dpi: 144);
      final raster = await stream.first;                // PdfRaster
      final ui.Image img = await raster.toImage();      // convert to ui.Image
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final png = byteData!.buffer.asUint8List();
      if (!mounted) return;
      setState(() {
        _previewPng = png; // show preview now
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Failed to render preview: $e';
      });
      _stopLoadingTicker();
      return;
    }

    // 3) Upload to API (no popup on success/200)
    try {
      // Optionally hint the immediate step phrase
      setState(() {
        final idx = _loadingPhrases.indexOf('Uploading to server…');
        if (idx >= 0) _loadingIndex = idx;
      });

      final resp = await pre.loadPdftoApi(
        fileBytes: _pdfBytes!,
        fileName: _fileName!,
        baseUrl: widget.apiBase,
        ocrForce: widget.ocrForce,
        ocrLang: widget.ocrLang,
        ocrDpi: widget.ocrDpi,
        maxChars: widget.maxChars,
        overlapChars: widget.overlapChars,
      );

      final code = resp.statusCode;
      // Only show popups on errors; on 200, do nothing extra
      if (code != 200) {
        String msg = 'Unexpected server response.';
        try {
          final body = resp.body.isNotEmpty ? json.decode(resp.body) : null;
          if (body is Map && body['message'] is String) {
            msg = body['message'] as String;
          }
        } catch (_) {}
        switch (code) {
          case 400:
            _showDialog(title: 'Bad request', message: msg);
            break;
          case 404:
            _showDialog(title: 'Not found', message: msg);
            break;
          case 409:
            _showDialog(title: 'Blocked', message: msg);
            break;
          case 415:
            _showDialog(title: 'Unsupported file', message: msg);
            break;
          case 422:
            _showDialog(title: 'Invalid pages', message: msg);
            break;
          case 503:
            _showDialog(title: 'Service unavailable', message: msg);
            break;
          default:
            _showDialog(title: 'Server error', message: msg);
        }
      }
    } catch (e, st) {
      debug('Upload error: $e\n$st');
      if (!mounted) return;
      _showDialog(title: 'Network error', message: 'Could not reach the server.');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false; // Finish overall busy state
        });
        _stopLoadingTicker();
      }
    }
  }

  // (Kept for consistency; unused now but you can still call if you want a hash-only quick check)
  Future<bool> _fakeCheckFileHashForThreat(String sha256) {
    return pre.fakeCheckFileHashForThreat(
      sha256,
      bytes: _pdfBytes,
      fileName: _fileName,
      mimeType: 'application/pdf',
    );
  }

  void _showDialog({required String title, required String message}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
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
          borderRadius: BorderRadius.circular(widget.cornerRadius),
          border: Border.all(color: Colors.black12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            children: [
              // Top icon
              _fileName == null
                  ? Icon(
                      Icons.report_gmailerrorred_outlined,
                      size: widget.iconSize,
                      color: const Color(0xFFB00020),
                    )
                  : Icon(
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
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 18),

              // Body
              _fileName == null
                  ? RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: widget.bodySize,
                          color: Colors.black87,
                          height: 1.35,
                        ),
                        children: const [
                          TextSpan(text: '\n\n'),
                          TextSpan(
                            text: 'Click on button to attach a file',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      'You can attach another file if you want.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: widget.bodySize,
                        color: Colors.black87,
                        height: 1.35,
                      ),
                    ),

              const SizedBox(height: 10),

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
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 18),
                            // Smooth phrase switcher
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 450),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              transitionBuilder: (child, anim) => FadeTransition(
                                opacity: anim,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.25),
                                    end: Offset.zero,
                                  ).animate(anim),
                                  child: child,
                                ),
                              ),
                              child: Text(
                                _loadingPhrases[_loadingIndex],
                                key: ValueKey<int>(_loadingIndex),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
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

              // Buttons
              _fileName == null
                  ? SizedBox(
                      width: 160,
                      child: ElevatedButton.icon(
                        onPressed: _busy ? null : _pickPdf,
                        icon: const Icon(Icons.attachment, size: 16),
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
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: 160,
                          child: ElevatedButton.icon(
                            onPressed: _busy ? null : _pickPdf,
                            icon: const Icon(Icons.attachment, size: 16),
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
                        SizedBox(
                          width: 160,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              debug('Next button pressed');
                              // No navigation here (by request).
                            },
                            icon: const Icon(Icons.arrow_forward, size: 16),
                            label: Text(
                              'Next',
                              style: TextStyle(
                                fontSize: widget.buttonFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              minimumSize: widget.buttonMinSize,
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              elevation: 6,
                              shadowColor:
                                  Theme.of(context).colorScheme.primaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  "Sorry, we could not upload.",
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
