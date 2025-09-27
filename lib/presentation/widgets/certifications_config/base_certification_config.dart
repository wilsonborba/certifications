

import 'package:flutter/material.dart';



/// BaseTopics is a StatefulWidget holding shared logic for Mobile/Desktop
abstract class BaseCertificationConfig extends StatefulWidget {
  final String documentId;
  BaseCertificationConfig({super.key, required this.documentId});
  
}

/// Shared state with common helpers for topics screens.
/// Subclasses get:
/// - controller (paging/search/ticker/grid-height)
/// - data/cache/search helpers
/// - convenience getters (visibleItems/isBusy/windowInfo)
abstract class BaseCertificationConfigState<T extends BaseCertificationConfig> extends State<T> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}