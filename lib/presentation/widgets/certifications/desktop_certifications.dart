import 'package:accredit/presentation/components/certifications/certifications_view.dart';
import 'package:flutter/material.dart';

class DesktopCertifications extends StatefulWidget {
  const DesktopCertifications({super.key});

  @override
  State<DesktopCertifications> createState() => _DesktopCertificationsState();
}

class _DesktopCertificationsState extends State<DesktopCertifications> {
  @override
  Widget build(BuildContext context) {
    return const CertificationsView(isDesktop: true);
  }
}
