


import 'package:accredit/presentation/widgets/certifications_config/base_certification_config.dart';
import 'package:flutter/material.dart';

class MobileCertificationConfig extends BaseCertificationConfig {
  MobileCertificationConfig({super.key, required super.documentId});

  @override
  State<MobileCertificationConfig> createState() => _MobileCertificationConfigState();
}

class _MobileCertificationConfigState extends BaseCertificationConfigState<MobileCertificationConfig> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}