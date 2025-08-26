


import 'package:flutter/material.dart';
class TopHeaders extends StatelessWidget {
  const TopHeaders({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        Padding(padding: EdgeInsets.only(left: 30, top: 30),
        child: 

         Text(
          "Don't know what\nto attach?",
          style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
        )),
        // Let the image live on the right side of the Row
        Expanded(
          child: Align(
            alignment: Alignment.topRight,
            child: Image.asset(
              'lib/presentation/assets/img/attach_line.png',
              fit: BoxFit.contain,   // or BoxFit.fitHeight
              height: 200,           // pick a static size you like
            ),
          ),
        ),
      ],
    );
  }
}
