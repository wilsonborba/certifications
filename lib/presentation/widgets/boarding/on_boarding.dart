import 'package:flutter/material.dart';
import 'package:certifications/presentation/widgets/landing/landing_scaffold.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // If your ScreenAdjuster returns a Scaffold itself, that's fine.
    // If not, ensure there's a Scaffold above this widget in the tree.
    // One responsive landing for every width (certifications#53).
    return const LandingScreen();
  }
}
