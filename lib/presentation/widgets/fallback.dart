import 'package:flutter/material.dart';

class FallbackDesktop extends StatelessWidget {
  const FallbackDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'This app is designed for mobile devices only. \n'
          'The current resolution is not supported.',
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
