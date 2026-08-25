// desktop_certifications_config.dart
import 'package:accredit/core/utils/my_nagivation.dart';
import 'package:accredit/presentation/components/certifications_config/form_config.dart';
import 'package:accredit/presentation/widgets/certifications_config/base_certification_config.dart';
import 'package:accredit/presentation/widgets/quiz/on_quiz.dart';

import 'package:flutter/material.dart';

class DesktopCertificationConfig extends BaseCertificationConfig {
  final bool isForPDF;
  final String? itemName;

  DesktopCertificationConfig({
    super.key,
    required super.documentId,
    required this.isForPDF,
    this.itemName,
  });

  @override
  State<DesktopCertificationConfig> createState() =>
      _DesktopCertificationConfigState();
}

class _DesktopCertificationConfigState
    extends BaseCertificationConfigState<DesktopCertificationConfig> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 248, 248),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: const Color.fromARGB(255, 36, 36, 36),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  maxWidth: 1200,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Certification Configuration',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 100),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: Image.asset(
                                'lib/presentation/assets/img/her.png',
                                fit: BoxFit.contain,
                                height: 500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 32),
                        Flexible(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: CertificationForm(
                                onSubmit: (formData) {
                                  NavigationService.push(
                                    OnQuizScreen(
                                      formData: formData,
                                      contextId: widget.documentId,
                                      isForPDF: widget.isForPDF,
                                      itemName: widget.itemName,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
