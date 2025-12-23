import 'package:accredit/presentation/widgets/accredit/desktop_accredit.dart';
import 'package:accredit/presentation/widgets/accredit/mobile_accredit.dart';
import 'package:flutter/material.dart';
import 'package:accredit/presentation/screen_adjuster.dart';

class OnAccreditScreen extends StatelessWidget {
  final String certificationId;

  const OnAccreditScreen({super.key, required this.certificationId});

  @override
  Widget build(BuildContext context) {
    return ScreenAdjuster(
      mobileWidget: MobileAccreditScreen(certificationId: certificationId),
      desktopWidget: DesktopAccreditScreen(certificationId: certificationId),
    ).adjust(context);
  }
}
