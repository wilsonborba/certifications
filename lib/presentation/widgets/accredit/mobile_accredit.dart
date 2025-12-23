import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:accredit/domain/models/certification.dart';
import 'package:accredit/domain/services/api_certification_manager.dart';
import 'package:accredit/presentation/components/accredit/certificate_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart' as prt;
import 'package:share_plus/share_plus.dart';

class MobileAccreditScreen extends StatefulWidget {
  final String certificationId;

  const MobileAccreditScreen({super.key, required this.certificationId});

  @override
  State<MobileAccreditScreen> createState() => _MobileAccreditScreenState();
}

class _MobileAccreditScreenState extends State<MobileAccreditScreen> {
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
    return Certification.fromJson(body);
  }

  Future<Uint8List> _capturePng() async {
    final boundary =
        _captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<void> _printCertificate() async {
    final png = await _capturePng();
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
        title: const Text('Certificate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              if (!mounted) return;
              if (!_captureKey.currentContext!.mounted) return;
              await _printCertificate();
            },
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: () async {
              if (!mounted) return;
              if (!_captureKey.currentContext!.mounted) return;
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
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: CertificateBody(
                  cert: cert,
                  captureKey: _captureKey,
                  maxWidth: 700,
                  verticalDensity: 1.0,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
