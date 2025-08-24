

import 'package:flutter/material.dart';
import 'package:lazycopy/presentation/screen_adjuster.dart';
import 'package:lazycopy/presentation/widgets/boarding/mobile_boarding.dart';
import 'package:lazycopy/presentation/widgets/fallback.dart';



class OnBoardingScreen  extends StatelessWidget {

   const OnBoardingScreen({super.key});

   @override
  Widget build(BuildContext context) {
       return ScreenAdjuster(
          mobileWidget: MobileBoarding(),
          desktopWidget:  FallbackDesktop(),
       ).adjust(context);
}

}