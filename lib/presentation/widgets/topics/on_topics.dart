import 'package:certifications/presentation/widgets/topics/desktop_topics.dart';
import 'package:certifications/presentation/widgets/topics/mobile_topics.dart';
import 'package:flutter/material.dart';
import 'package:certifications/presentation/screen_adjuster.dart';

class OnTopicsScreen extends StatefulWidget {
  final String itemName;
  const OnTopicsScreen({super.key, required this.itemName});

  @override
  State<OnTopicsScreen> createState() => _OnTopicsScreenState();
}

class _OnTopicsScreenState extends State<OnTopicsScreen> {
  @override
  Widget build(BuildContext context) {
    return ScreenAdjuster(
      mobileWidget: MobileTopics(itemName: widget.itemName),
      desktopWidget: DesktopTopics(itemName: widget.itemName),
    ).adjust(context);
  }
}
