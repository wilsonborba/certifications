import 'package:accredit/presentation/components/certifications/certifications_view.dart';
import 'package:flutter/material.dart';

class MobileCertifications extends StatefulWidget {
  const MobileCertifications({super.key});

  @override
  State<MobileCertifications> createState() => _MobileCertificationsState();
}

class _MobileCertificationsState extends State<MobileCertifications> {
  @override
  Widget build(BuildContext context) {
    return const CertificationsView(isDesktop: false);
  }
}
