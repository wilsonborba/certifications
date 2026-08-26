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
            text: "Imagine sharing a\n",
            style: TextStyle(fontSize: fontSize),
          ),
          TextSpan(
            text: "“Certified Master of Shrek Quotes”\n",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
          ),
          TextSpan(
            text: "certification.",
            style: TextStyle(fontSize: fontSize),
          ),
        ],
      ),
    );
  }
}
