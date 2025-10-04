

import 'package:accredit/presentation/components/boarding/cookies_check.dart';
import 'package:flutter/material.dart';
import 'package:accredit/presentation/screen_adjuster.dart';
import 'package:accredit/presentation/widgets/boarding/desktop_boarding.dart';
import 'package:accredit/presentation/widgets/boarding/mobile_boarding.dart';



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
    return ScreenAdjuster(
      mobileWidget: MobileBoarding(),
      desktopWidget: DesktopBoarding(),
    ).adjust(context);
  }
}