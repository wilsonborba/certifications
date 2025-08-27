

import 'package:flutter/material.dart';
import 'package:accredit/presentation/screen_adjuster.dart';
import 'package:accredit/presentation/widgets/attachment/desktop_attachment.dart';
import 'package:accredit/presentation/widgets/attachment/mobile_attachment.dart';




class OnBoardingScreen  extends StatelessWidget {

   const OnBoardingScreen({super.key});

   @override
  Widget build(BuildContext context) {
       return ScreenAdjuster(
          mobileWidget: MobileAttachment(),
          desktopWidget:  DesktopAttachment(),
       ).adjust(context);
}

}