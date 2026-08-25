import 'dart:typed_data';

import 'package:certifications/presentation/widgets/attachment/on_attachment.dart';
import 'package:flutter/material.dart';

import 'package:certifications/presentation/screen_adjuster.dart';
import 'package:certifications/presentation/widgets/page_filter/desktop_page_filter.dart';
import 'package:certifications/presentation/widgets/page_filter/mobile_page_filter.dart';

// Use the file where getPdfInputFromApi(...) is defined.
// If you actually have a manager wrapper, adjust this import accordingly.
import 'package:certifications/domain/services/pdf_frontend_prescan_manager.dart'
    as pre;

// Your app's navigation helper (you mentioned NavigationService.push)
import 'package:certifications/core/utils/my_nagivation.dart'; // NavigationService

class OnPageFilterScreen extends StatefulWidget {
  final String documentId;
  final Uint8List pdfBytes;
  final String fileName;

  /// You can keep this if you use it elsewhere, but it's not required for the check
  final dynamic pdfManagerInstance;

  const OnPageFilterScreen({
    required this.pdfBytes,
    required this.fileName,
    super.key,
    this.pdfManagerInstance = const pre.PdfManager(),
    required this.documentId,
  });

  @override
  State<OnPageFilterScreen> createState() => _OnPageFilterScreenState();
}

class _OnPageFilterScreenState extends State<OnPageFilterScreen> {
  bool _checking = true; // show spinner until we finish the check
  bool _verified = false; // true only when API returns 200
  bool _navigatedAway = false;

  @override
  void initState() {
    super.initState();
    // Kick off the verification *after* first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _verify());
  }

  Future<void> _verify() async {
    try {
      final resp = await pre.getPdfInputFromApi(
        documentId: widget.documentId,
        // baseUrl / selectedPages if your function needs them:
        // baseUrl: 'http://localhost:8001',
        // selectedPages: '1-2',
      );

      if (!mounted) return;

      if (resp.statusCode == 200) {
        setState(() {
          _verified = true;
          _checking = false;
        });
      } else {
        _redirectToAttachment();
      }
    } catch (_) {
      if (!mounted) return;
      _redirectToAttachment();
    }
  }

  void _redirectToAttachment() {
    if (_navigatedAway) return;
    _navigatedAway = true;

    // Push the other screen the way you asked:
    NavigationService.push(const OnAttachmentScreen());

    // Optionally remove this screen so back does not return here:
    // If your NavigationService has pushReplacement, prefer that:
    // NavigationService.pushReplacement(const OnAttachmentScreen());

    // If you want to ensure the current screen is removed even with push():
    // Future.microtask(() {
    //   if (mounted && Navigator.of(context).canPop()) {
    //     Navigator.of(context).pop();
    //   }
    // });
  }

  @override
  Widget build(BuildContext context) {
    // While checking: show a simple loader
    if (_checking) {
      return Scaffold(
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(),
                ),
                SizedBox(height: 12),
                Text('Almost there…'),
              ],
            ),
          ),
        ),
      );
    }

    // Verified OK → render the real screen
    if (_verified) {
      return ScreenAdjuster(
        mobileWidget: MobilePageFilter(
          documentId: widget.documentId,
          pdfBytes: widget.pdfBytes,
          fileName: widget.fileName,
        ),
        desktopWidget: DesktopPageFilter(
          documentId: widget.documentId,
          pdfBytes: widget.pdfBytes,
          fileName: widget.fileName,
        ),
      ).adjust(context);
    }

    // If not verified and we already navigated away, render nothing.
    // (We won't get here normally; kept as safety.)
    return const SizedBox.shrink();
  }
}
