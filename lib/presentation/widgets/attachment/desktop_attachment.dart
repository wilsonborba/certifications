

import 'package:flutter/material.dart';
import 'package:accredit/presentation/components/attachment/card_pdf_picker.dart';
import 'package:accredit/presentation/components/attachment/top_headers.dart';



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

      body: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              
              child: Column(
          children: [
            TopHeaders(),
            Row(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.grey[200],

                  ),
                ),
                Expanded(
                  child: CardPdfPicker(),
                ),

              ],
            ),
            SizedBox(height: 40),

          ],
        ),
      ));
  }
}
