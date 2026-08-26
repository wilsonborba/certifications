import 'package:flutter/material.dart';
import 'package:certifications/core/utils/app_localizations.dart';

class SecondPhrase extends StatelessWidget {
  final double fontSize;

  const SecondPhrase({super.key, this.fontSize = 50});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${context.tr('landingSeriousQuestion')}\n',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
          ),
          TextSpan(
            text: context.tr('landingSeriousBody'),
            style: TextStyle(fontSize: fontSize),
          ),
        ],
      ),
    );
  }
}
