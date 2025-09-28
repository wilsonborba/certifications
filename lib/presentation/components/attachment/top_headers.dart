


import 'package:flutter/material.dart';
class TopHeaders extends StatelessWidget {


  // bool field about isDesktop;
  final bool isDesktop;

  const TopHeaders({super.key, required this.isDesktop});


  desktopTextStyle() {
    return TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );
  }

  mobileTextStyle() {
    return TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isDesktop ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        Padding(padding: EdgeInsets.only(left: 30, top: 30),
        child: 

         Text(
          "Don't know what\nto attach?",
          style: isDesktop ? desktopTextStyle() : mobileTextStyle(),
        )),
        // Let the image live on the right side of the Row
        isDesktop ? Expanded(
          child: Align(
            alignment: Alignment.topRight,
            child: Image.asset(
              'lib/presentation/assets/img/attach_line_purple.png',
              fit: BoxFit.contain,   // or BoxFit.fitHeight
              height: 200,           // pick a static size you like
            ),
          ),
        ): SizedBox(width: 1), // empty widget for mobile
      ],
    );
  }
}
