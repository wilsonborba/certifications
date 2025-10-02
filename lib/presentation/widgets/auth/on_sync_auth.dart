

import 'package:accredit/presentation/widgets/auth/desktop_sync_auth.dart';
import 'package:accredit/presentation/widgets/auth/mobile_sync_auth.dart';
import 'package:flutter/material.dart';
import 'package:accredit/presentation/screen_adjuster.dart';

class OnSyncAuthScreen extends StatefulWidget {
    static const String route = '/sync';
    final String? tokenizedParam;

   const OnSyncAuthScreen({super.key, this.tokenizedParam});
  @override
  State<OnSyncAuthScreen> createState() => _OnSyncAuthScreenState();
}

class _OnSyncAuthScreenState extends State<OnSyncAuthScreen> {


   @override
  Widget build(BuildContext context) {
       return ScreenAdjuster(
          mobileWidget: MobileSyncAuth(tokenizedParam: widget.tokenizedParam),
          desktopWidget:  DesktopSyncAuth(tokenizedParam: widget.tokenizedParam ),
       ).adjust(context);
}

}