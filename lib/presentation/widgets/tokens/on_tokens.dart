import 'package:accredit/presentation/widgets/tokens/desktop_tokens.dart';
import 'package:accredit/presentation/widgets/tokens/mobile_tokens.dart';
import 'package:flutter/material.dart';
import 'package:accredit/presentation/screen_adjuster.dart';

class OnTokensScreen extends StatefulWidget {
  const OnTokensScreen({super.key});

  @override
  State<OnTokensScreen> createState() => _OnTokensScreenState();
}

class _OnTokensScreenState extends State<OnTokensScreen> {
  @override
  Widget build(BuildContext context) {
    // If your ScreenAdjuster returns a Scaffold itself, that's fine.
    // If not, ensure there's a Scaffold above this widget in the tree.
    return ScreenAdjuster(
      mobileWidget: MobileTokens(),
      desktopWidget: DesktopTokens(),
    ).adjust(context);
  }
}
