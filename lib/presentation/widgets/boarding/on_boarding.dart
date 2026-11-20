import 'package:certifications/presentation/components/boarding/cookies_check.dart';
import 'package:flutter/material.dart';
import 'package:certifications/presentation/widgets/landing/landing_scaffold.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  @override
  void initState() {
    super.initState();
    // Show cookie bar only if consent not found
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Important: call after build so ScaffoldMessenger is ready
      CookieConsentSnack.showIfNeeded(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // If your ScreenAdjuster returns a Scaffold itself, that's fine.
    // If not, ensure there's a Scaffold above this widget in the tree.
    // One responsive landing for every width (certifications#53).
    return const LandingScreen();
  }
}
