

import 'package:accredit/presentation/widgets/page_filter/desktop_page_filter.dart';
import 'package:accredit/presentation/widgets/page_filter/mobile_page_filter.dart';
import 'package:flutter/material.dart';
import 'package:accredit/presentation/screen_adjuster.dart';



class OnPageFilterScreen extends StatefulWidget {
  final String documentId;
  const OnPageFilterScreen({super.key, required this.documentId});

  @override
  State<OnPageFilterScreen> createState() => _OnPageFilterScreenState();
}

class _OnPageFilterScreenState extends State<OnPageFilterScreen> {

     @override
  Widget build(BuildContext context) {
       return ScreenAdjuster(
          mobileWidget: MobilePageFilter(documentId: widget.documentId),
          desktopWidget:  DesktopPageFilter(documentId: widget.documentId),
       ).adjust(context);
}
}