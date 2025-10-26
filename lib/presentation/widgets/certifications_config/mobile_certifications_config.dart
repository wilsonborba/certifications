


import 'package:accredit/presentation/components/certifications_config/form_config.dart';
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
    return  Scaffold(
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
        return Center( // centers horizontally when combined with maxWidth below
          child: SingleChildScrollView(
            child: ConstrainedBox(
              // minHeight = viewport height -> allows vertical centering
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
                maxWidth: 1200, // keeps content nicely centered on desktop
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment
                    .center, // vertical centering (because of minHeight)
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  Text(
                    'Certification Configuration',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 100),

                  // Use Row that sizes to content, not full width
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, // horizontal centering
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                
                     
                      Flexible(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Center(
                            child: CertificationForm(
                              onSubmit: (data) {
                                debugPrint(
                                    'Submitted: ${data.fullName}, ${data.certificationTitle}, '
                                    'phone=${data.phoneE164}, pages=${data.pages}, '
                                    'minutes=${data.minutes}, lang=${data.language}');
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