

import 'package:flutter/material.dart';
import 'package:accredit/presentation/screen_adjuster.dart';
import 'package:accredit/presentation/widgets/boarding/desktop_boarding.dart';
import 'package:accredit/presentation/widgets/boarding/mobile_boarding.dart';




class OnBoardingScreen  extends StatelessWidget {

   const OnBoardingScreen({super.key});

   @override
  Widget build(BuildContext context) {
       return ScreenAdjuster(
          mobileWidget: MobileBoarding(),
          desktopWidget:  DesktopBoarding(),
       ).adjust(context);
}

}