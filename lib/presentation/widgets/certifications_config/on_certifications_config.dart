// on_certification_config_screen.dart
import 'package:flutter/material.dart';
import 'package:certifications/presentation/screen_adjuster.dart';
import 'package:certifications/presentation/widgets/certifications_config/desktop_certifications_config.dart';
import 'package:certifications/presentation/widgets/certifications_config/mobile_certifications_config.dart';

class OnCertificationConfigScreen extends StatefulWidget {
  final String? itemName; // for topic mode
  final String contextId; // documentId (PDF) OR inputIdentification (topic)
  final bool isForPDF; // true = PDF mode, false = topic mode

  const OnCertificationConfigScreen({
    super.key,
    required this.contextId,
    this.isForPDF = true,
    this.itemName,
  });

  @override
  State<OnCertificationConfigScreen> createState() =>
      _OnCertificationConfigScreenState();
}

class _OnCertificationConfigScreenState
    extends State<OnCertificationConfigScreen> {
  @override
  Widget build(BuildContext context) {
    return ScreenAdjuster(
      mobileWidget: MobileCertificationConfig(
        documentId: widget.contextId,
        isForPDF: widget.isForPDF,
        itemName: widget.itemName,
      ),
      desktopWidget: DesktopCertificationConfig(
        documentId: widget.contextId,
        isForPDF: widget.isForPDF,
        itemName: widget.itemName,
      ),
    ).adjust(context);
  }
}
