// lib/core/security/pdf_frontend_prescan.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:accredit/dal/remote/api_adapter.dart';
import 'package:http/http.dart';

import 'package:http/http.dart' show Response;
import 'package:http_parser/http_parser.dart';

/// Result of the quick client-side scan.
class FrontendScanResult {
  final bool isAcceptable;
  final List<String> flags;    // reasons/warnings
  final String? sha256;
  final int sizeBytes;

  const FrontendScanResult({
    required this.isAcceptable,
    required this.flags,
    required this.sizeBytes,
    this.sha256,
  });

  String summary() =>
      isAcceptable ? 'OK' : 'Blocked: ${flags.join("; ")}';
}

/// Tweakable limits/policy.
class PreScanConfig {
  /// Hard size cap (bytes). Large PDFs are often unnecessary and slow to handle in the browser.
  final int maxBytes;

  /// Soft minimum size (very tiny files might be bogus).
  final int minBytes;

  /// Block if the PDF declares JavaScript (/JS or /JavaScript).
  final bool blockOnJavaScript;

  /// Block if the PDF declares actions that auto-run (/OpenAction, /AA, /Launch).
  final bool blockOnAutoActions;

  /// MIME expected (if provided from the drop API).
  final String expectedMime;

  const PreScanConfig({
    this.maxBytes = 20 * 1024 * 1024, // 20 MB
    this.minBytes = 512,              // half a KB
    this.blockOnJavaScript = true,
    this.blockOnAutoActions = true,
    this.expectedMime = 'application/pdf',
  });
}

/// Optional local denylist of hashes (populate if you have any).
const Set<String> _deniedSha256 = {
  // 'aaaaaaaa...'
};

Map<String, String> defaultHeadersPdfApi = const {
  'Accept': 'application/json',
};

/// SAME NAME, refactored to use ApiAdapter (multipart POST)
/// Calls: POST {baseUrl}/pdf/topic?ocr_force=...&ocr_lang=...&ocr_dpi=...&max_chars=...&overlap_chars=...
Future<Response> loadPdftoApi({
  required Uint8List fileBytes,
  required String fileName,
  String baseUrl = 'http://127.0.0.1:8001',
  bool ocrForce = false,
  String ocrLang = 'eng',
  int ocrDpi = 300,
  int maxChars = 8000,
  int overlapChars = 400,
  Map<String, String>? extraHeaders,
}) {
  final adapter = ApiAdapter(
    defaultHeaders: {
      ...defaultHeadersPdfApi,
      if (extraHeaders != null) ...extraHeaders,
    },
  );

  // Query params expected by your FastAPI route
  final query = <String, dynamic>{
    'ocr_force': ocrForce.toString(),
    'ocr_lang': ocrLang,
    'ocr_dpi': ocrDpi.toString(),
    'max_chars': maxChars.toString(),
    'overlap_chars': overlapChars.toString(),
  };

  final url = Uri.parse('$baseUrl/pdf/topic');

  // Uses the multipart extension on ApiAdapter (postMultipart)
  return adapter.postMultipart(
    url: url,
    queryParams: query,
    // Optional extra form fields if you ever need them:
    fields: const <String, String>{},
    files: [
      MultipartFileData(
        field: 'file',
        bytes: fileBytes,
        filename: fileName,
        contentType: MediaType('application', 'pdf'),
      ),
    ],
  );
}

/// Public entry: full pre-scan using bytes + metadata.
/// Returns details you can log or show.
Future<FrontendScanResult> frontEndPreScan({
  required Uint8List bytes,
  String? sha256,
  String? fileName,
  String? mime,
  PreScanConfig config = const PreScanConfig(),
}) async {
  final flags = <String>[];

  // 1) Size checks
  if (bytes.length < config.minBytes) {
    flags.add('File too small (${bytes.length} B)');
  }
  if (bytes.length > config.maxBytes) {
    flags.add('File too large (${_fmt(bytes.length)} > ${_fmt(config.maxBytes)})');
  }

  // 2) Hash denylist
  if (sha256 != null && _deniedSha256.contains(sha256)) {
    flags.add('Known bad hash');
  }

  // 3) Extension / MIME hints (best-effort)
  final lowerName = (fileName ?? '').toLowerCase();
  if (lowerName.isNotEmpty && !lowerName.endsWith('.pdf')) {
    flags.add('Name does not end with .pdf');
  }
  if (mime != null && mime.isNotEmpty && mime != config.expectedMime) {
    flags.add('MIME mismatch: $mime');
  }

  // 4) Magic header + trailer
  if (!_hasPdfHeader(bytes)) {
    flags.add('Missing %PDF- header');
  }
  if (!_hasPdfEof(bytes)) {
    flags.add('Missing %%EOF trailer');
  }

  // 5) Lightweight feature scan (ASCII token search in head/tail)
  final tokenHits = _scanForTokens(bytes);
  if ((tokenHits['/js'] == true || tokenHits['/javascript'] == true) &&
      config.blockOnJavaScript) {
    flags.add('Contains JavaScript (/JS)');
  }
  final autoActions = [
    '/openaction',
    '/aa',        // additional actions
    '/launch',    // launch an app
  ].where((t) => tokenHits[t] == true).toList();
  if (autoActions.isNotEmpty && config.blockOnAutoActions) {
    flags.add('Auto actions present: ${autoActions.join(", ")}');
  }
  // Other noteworthy features (warn, don’t block):
  final warnTokens = <String>[
    '/embeddedfile', '/richmedia', '/xfa', '/submitform', '/gotoe', '/uri',
    '/acroform'
  ].where((t) => tokenHits[t] == true).toList();
  if (warnTokens.isNotEmpty) {
    flags.add('Contains advanced features: ${warnTokens.join(", ")}');
  }

  // Policy: block on "hard" flags only
  final hardBlocks = flags.any((f) =>
      f.startsWith('File too small') ||
      f.startsWith('File too large') ||
      f.startsWith('Known bad hash') ||
      f.startsWith('Missing %PDF-') ||
      f.startsWith('Missing %%EOF') ||
      f.startsWith('Contains JavaScript') ||
      f.startsWith('Auto actions present'));

  return FrontendScanResult(
    isAcceptable: !hardBlocks,
    flags: flags,
    sizeBytes: bytes.length,
    sha256: sha256,
  );
}

/// Compatibility helper:
/// If you *only* pass the hash, we only check the denylist.
/// If you pass bytes/name/mime too, we run the full scan.
Future<bool> fakeCheckFileHashForThreat(
  String sha256, {
  Uint8List? bytes,
  String? fileName,
  String? mimeType,
  PreScanConfig config = const PreScanConfig(),
}) async {
  if (bytes == null) {
    // Hash-only quick check
    return !_deniedSha256.contains(sha256);
  }
  final res = await frontEndPreScan(
    bytes: bytes,
    sha256: sha256,
    fileName: fileName,
    mime: mimeType,
    config: config,
  );
  return res.isAcceptable;
}

// ---------- helpers ----------

bool _hasPdfHeader(Uint8List b) {
  if (b.length < 5) return false;
  return b[0] == 0x25 && // %
         b[1] == 0x50 && // P
         b[2] == 0x44 && // D
         b[3] == 0x46 && // F
         b[4] == 0x2D;   // -
}

bool _hasPdfEof(Uint8List b) {
  final start = b.length > 4096 ? b.length - 4096 : 0;
  final tail = const Latin1Decoder(allowInvalid: true).convert(b.sublist(start));
  return tail.contains('%%EOF');
}

Map<String, bool> _scanForTokens(Uint8List b) {
  // To keep it light, scan head + tail up to 1MB each.
  const headLimit = 1024 * 1024;
  final head = b.sublist(0, b.length < headLimit ? b.length : headLimit);
  final tail = b.length <= headLimit
      ? Uint8List(0)
      : b.sublist(b.length - headLimit);

  final hay = (const Latin1Decoder(allowInvalid: true).convert(head) +
              const Latin1Decoder(allowInvalid: true).convert(tail))
          .toLowerCase();

  final tokens = <String>[
    '/js', '/javascript', '/openaction', '/aa', '/launch',
    '/embeddedfile', '/richmedia', '/xfa', '/submitform', '/gotoe', '/uri',
    '/acroform',
  ];

  return {
    for (final t in tokens) t: hay.contains(t),
  };
}

String _fmt(int bytes) {
  const kb = 1024;
  const mb = 1024 * 1024;
  if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
  if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(1)} KB';
  return '$bytes B';
}
