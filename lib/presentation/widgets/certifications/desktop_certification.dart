import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:certifications/core/utils/my_background.dart';
import 'package:certifications/core/utils/my_logs.dart';
import 'package:certifications/domain/models/certification.dart';
import 'package:certifications/domain/services/api_certification_manager.dart';
import 'package:certifications/presentation/components/certifications/certificate_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart' as prt;
import 'package:share_plus/share_plus.dart';

class DesktopCertificationScreen extends StatefulWidget {
  final String certificationId;

  const DesktopCertificationScreen({super.key, required this.certificationId});

  @override
  State<DesktopCertificationScreen> createState() =>
      _DesktopCertificationScreenState();
}

class _DesktopCertificationScreenState
    extends State<DesktopCertificationScreen> {
  late Future<Certification> _future;
  final _captureKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _future = _fetchCertification();
  }

  Future<Certification> _fetchCertification() async {
    final manager = CertificationManager();
    final res = await manager.getCertification(widget.certificationId);

    if (res.statusCode != 200) {
      throw Exception('Failed to load certificate: ${res.statusCode}');
    }

    final body = jsonDecode(utf8.decode(res.bodyBytes));
    debug('Certification body: $body');
    return Certification.fromJson(body);
  }

  Future<Uint8List> _capturePng() async {
    final ctx = _captureKey.currentContext;
    if (ctx == null) return Uint8List(0);
    final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return Uint8List(0);
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List() ?? Uint8List(0);
  }

  Future<void> _printCertificate() async {
    final png = await _capturePng();
    if (png.isEmpty) return;
    final doc = pw.Document();
    final img = pw.MemoryImage(png);

    doc.addPage(
      pw.Page(
        build: (_) => pw.Center(
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Image(img, fit: pw.BoxFit.contain),
          ),
        ),
      ),
    );

    await prt.Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  Future<void> _shareCertificate() async {
    final png = await _capturePng();
    if (png.isEmpty) return;
    await Share.shareXFiles([
      XFile.fromData(png, mimeType: 'image/png', name: 'certificate.png'),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              if (!mounted) return;
              final ctx = _captureKey.currentContext;
              if (ctx == null || !ctx.mounted) return;
              await _printCertificate();
            },
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: () async {
              if (!mounted) return;
              final ctx = _captureKey.currentContext;
              if (ctx == null || !ctx.mounted) return;
              await _shareCertificate();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<Certification>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              );
            }

            final cert = snapshot.data!;
            return Stack(
              children: [
                // BACKGROUND (under everything)
                Positioned.fill(
                  child: LiquidMetalBackground(
                    blobCount: 5,
                    blurSigma: 22, // ≈ “70% blur” feel
                    centerFocusRadius:
                        .002, // crisper center (0..1 of shortest side)
                    speed: 28, // px/sec nominal speed
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: CertificateBody(
                      cert: cert,
                      captureKey: _captureKey,
                      maxWidth: 1000,
                      verticalDensity: 1.2,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
