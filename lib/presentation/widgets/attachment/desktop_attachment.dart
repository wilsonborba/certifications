

import 'package:flutter/material.dart';



class DesktopAttachment extends StatefulWidget {
  
  const DesktopAttachment({super.key});

  @override
  State<DesktopAttachment> createState() => _DesktopAttachmentState();
}

class _DesktopAttachmentState extends State<DesktopAttachment> {



  @override
  Widget build(BuildContext context) {
    // Implement the mobile landing screen UI here
    return Scaffold(

      body: Container(
        child: Text('Desktop Attachment Screen'),
      ));
  }
}
