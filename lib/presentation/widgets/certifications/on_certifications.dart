import 'package:certifications/presentation/screen_adjuster.dart';
import 'package:certifications/presentation/widgets/certifications/desktop_certifications.dart';
import 'package:certifications/presentation/widgets/certifications/mobile_certifications.dart';
import 'package:flutter/material.dart';

class OnCertificationsScreen extends StatefulWidget {
  const OnCertificationsScreen({super.key});

  @override
  State<OnCertificationsScreen> createState() => _OnCertificationsScreenState();
}

class _OnCertificationsScreenState extends State<OnCertificationsScreen> {
  @override
  Widget build(BuildContext context) {
    return ScreenAdjuster(
      mobileWidget: const MobileCertifications(),
      desktopWidget: const DesktopCertifications(),
    ).adjust(context);
  }
}
