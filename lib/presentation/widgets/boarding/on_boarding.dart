import 'package:flutter/material.dart';
import 'package:certifications/presentation/screen_adjuster.dart';
import 'package:certifications/presentation/widgets/boarding/desktop_boarding.dart';
import 'package:certifications/presentation/widgets/boarding/mobile_boarding.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

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
