import 'package:flutter/material.dart';

class SecondPhrase extends StatelessWidget {
  final double fontSize;

  const SecondPhrase({super.key, this.fontSize = 50});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: "Or your layer is serious certifications?\n",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
          ),
          TextSpan(
            text: "This is your growth hack entry point.",
            style: TextStyle(fontSize: fontSize),
          ),
        ],
      ),
    );
  }
}
