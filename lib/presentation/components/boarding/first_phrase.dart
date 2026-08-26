import 'package:certifications/core/utils/app_localizations.dart';
import 'package:flutter/material.dart';

class FirstPhrase extends StatelessWidget {
  final double fontSize;

  const FirstPhrase({super.key, this.fontSize = 50});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${context.tr('landingImagine')}\n',
            style: TextStyle(fontSize: fontSize),
          ),
          TextSpan(
            text: '“${context.tr('landingExample')}”\n',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
          ),
          TextSpan(
            text: context.tr('landingCertification'),
            style: TextStyle(fontSize: fontSize),
          ),
        ],
      ),
    );
  }
}
