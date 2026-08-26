import 'package:certifications/presentation/widgets/study_list.dart';
import 'package:flutter/material.dart';

/// Document-only entry point. Non-document source cards are intentionally absent.
class OnAttachmentScreen extends StatelessWidget {
  const OnAttachmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StudyList();
  }
}
