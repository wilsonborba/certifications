import 'package:accredit/presentation/screen_adjuster.dart';
import 'package:accredit/presentation/widgets/plans/desktop_plans.dart';
import 'package:accredit/presentation/widgets/plans/mobile_plans.dart';
import 'package:flutter/material.dart';

class OnPlansScreen extends StatelessWidget {
  const OnPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenAdjuster(
      mobileWidget: const MobilePlans(),
      desktopWidget: const DesktopPlans(),
    ).adjust(context);
  }
}
