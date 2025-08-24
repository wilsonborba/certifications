import 'package:flutter/material.dart';

class ScreenAdjuster<T> {
  final T mobileWidget;
  final T desktopWidget;
  final double threshold;

  ScreenAdjuster({
    required this.mobileWidget,
    required this.desktopWidget,
    this.threshold = 760, // Default threshold for distinguishing small and wide screens
  });

  T adjust(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < threshold ? mobileWidget : desktopWidget;
  }
}