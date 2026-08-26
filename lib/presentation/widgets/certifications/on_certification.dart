import 'package:certifications/presentation/widgets/certifications/desktop_certification.dart';
import 'package:certifications/presentation/widgets/certifications/mobile_certification.dart';
import 'package:flutter/material.dart';
import 'package:certifications/presentation/screen_adjuster.dart';

class OnCertificationScreen extends StatelessWidget {
  final String certificationId;

  const OnCertificationScreen({super.key, required this.certificationId});

  @override
  Widget build(BuildContext context) {
    return ScreenAdjuster(
      mobileWidget: MobileCertificationScreen(certificationId: certificationId),
      desktopWidget: DesktopCertificationScreen(
        certificationId: certificationId,
      ),
    ).adjust(context);
  }
}
