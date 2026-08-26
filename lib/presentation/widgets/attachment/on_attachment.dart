import 'package:certifications/presentation/screen_adjuster.dart';
import 'package:certifications/presentation/widgets/attachment/desktop_attachment.dart';
import 'package:certifications/presentation/widgets/attachment/mobile_attachment.dart';
import 'package:flutter/material.dart';

/// Document-only entry point. Non-document source cards are intentionally absent.
class OnAttachmentScreen extends StatelessWidget {
  const OnAttachmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenAdjuster(
      mobileWidget: const MobileAttachment(),
      desktopWidget: const DesktopAttachment(),
    ).adjust(context);
  }
}
