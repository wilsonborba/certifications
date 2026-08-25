import 'dart:typed_data';

import 'package:accredit/core/utils/my_dialogs.dart';
import 'package:accredit/core/utils/my_logs.dart';
import 'package:accredit/core/utils/my_nagivation.dart';
import 'package:accredit/domain/models/topic_identifications.dart';
import 'package:accredit/presentation/widgets/certifications_config/on_certifications_config.dart';
import 'package:accredit/presentation/widgets/page_filter/base_page_filter.dart';
import 'package:flutter/material.dart';

import 'package:accredit/domain/services/pdf_frontend_prescan_manager.dart'
    as pre;
import 'package:http/http.dart' as http;

class MobilePageFilter extends StatelessWidget {
  final String documentId;
  final Uint8List pdfBytes;
  final String fileName;
  const MobilePageFilter({
    super.key,
    required this.documentId,
    required this.pdfBytes,
    required this.fileName,
  });

  Future<PdfInputInfo> _fetch(String docId) async {
    final http.Response resp = await pre.getPdfInputFromApi(documentId: docId);
    if (resp.statusCode != 200) throw Exception('bad status');
    return parsePdfInputInfo(resp);
  }

  @override
  Widget build(BuildContext context) {
    return BasePageFilter(
      documentId: documentId,
      pdfBytes: pdfBytes,
      fileName: fileName,
      fetcher: _fetch,
      desktopLayout: false, // stacked layout on mobile
      onContinue: (selected) {
        if (selected.isNotEmpty) {
          if (selected.length >= 31) {
            // NavigationService.push(SinglePagePreviewScreen(pageNumber: selected.first));
            debug('Not allowed: more than 30 pages selected');
            showMyDialog(
              context,
              title: 'Selection Error',
              message:
                  'You can select up to 30 pages only. You selected ${selected.length} pages.',
            );
          } else {
            NavigationService.push(
              OnCertificationConfigScreen(contextId: documentId),
            );
          }
        }
      },
    );
  }
}
