

import 'package:flutter/material.dart';
import 'package:lazycopy/core/utils/my_background.dart';
import 'package:lazycopy/presentation/components/boarding/first_phrase.dart';
import 'package:lazycopy/presentation/components/boarding/middle_button.dart';
import 'package:lazycopy/presentation/components/boarding/second_phrase.dart';


class DesktopBoarding extends StatefulWidget {
  
  const DesktopBoarding({super.key});

  @override
  State<DesktopBoarding> createState() => _DesktopBoardingState();
}

class _DesktopBoardingState extends State<DesktopBoarding> {



  @override
  Widget build(BuildContext context) {
    // Implement the mobile landing screen UI here
    return Scaffold(

      body: Stack(
          children: [
            // BACKGROUND (under everything)
            const Positioned.fill(
              child: LiquidMetalBackground(
                blobCount: 10,
                blurSigma: 22,        // ≈ “70% blur” feel
                centerFocusRadius: .42, // crisper center (0..1 of shortest side)
                speed: 28,            // px/sec nominal speed
              ),
            ), Center(
        child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              
              child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          
          children: [
               Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                     padding: EdgeInsets.only(left: 10),
                    child: FirstPhrase(fontSize: 50),
                  ),
                ),
            SizedBox(height: 30),
             Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.all(1),
                    child: MiddleButton(
                  label: "New Certification",
                  fontSize: 22,
                  minimumSize: const Size(200, 80),
                  iconSize: 30,
                  onPressed: () {
                    print("Button pressed!");
                  },
                ),
                  ),
                ),
              SizedBox(height: 30),
              const Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.all(1),
                  child: SecondPhrase(fontSize: 50),
                ),
              ),


          ],
        )),
      )]) 
    );
  }
}
