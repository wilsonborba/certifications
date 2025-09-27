


import 'package:accredit/presentation/widgets/certifications_config/base_certification_config.dart';
import 'package:flutter/material.dart';

class DesktopCertificationConfig extends BaseCertificationConfig {
  DesktopCertificationConfig({super.key, required super.documentId});

  @override
  State<DesktopCertificationConfig> createState() => _DesktopCertificationConfigState();
}

class _DesktopCertificationConfigState extends BaseCertificationConfigState<DesktopCertificationConfig> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}