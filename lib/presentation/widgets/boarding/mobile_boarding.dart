// mobile_boarding.dart
import 'package:flutter/material.dart';
import 'package:lazycopy/core/utils/my_background.dart';
import 'package:lazycopy/presentation/components/boarding/first_phrase.dart';
import 'package:lazycopy/presentation/components/boarding/second_phrase.dart';
import 'package:lazycopy/presentation/components/boarding/middle_button.dart';

class MobileBoarding extends StatelessWidget {
  const MobileBoarding({super.key});

  // fixed sizes for mobile
  static const double mobilePhraseSize = 28;
  static const Size mobileButtonMinSize = Size(160, 60);
  static const double mobileButtonIcon = 22;
  static const double mobileButtonFont = 18;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: LiquidMetalBackground(
              blobCount: 10,
              blurSigma: 22,
              centerFocusRadius: .42,
              speed: 28,
            ),
          ),
          SafeArea(
            child: Center(
              // vertical layout fits mobile better; if you still want horizontal scroll,
              // wrap this Column in SingleChildScrollView(scrollDirection: Axis.horizontal)
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              
              child:  Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Align(
                      alignment: Alignment.topLeft,
                      child: FirstPhrase(fontSize: mobilePhraseSize),
                    ),
                    const SizedBox(height: 100),
                    MiddleButton(
                      label: "New Certification",
                      fontSize: mobileButtonFont,
                      minimumSize: mobileButtonMinSize,
                      iconSize: mobileButtonIcon,
                      onPressed: () {},
                      backgroundColor: Colors.black87,
                    ),
                    const SizedBox(height: 100),
                    const Align(
                      alignment: Alignment.bottomRight,
                      child: SecondPhrase(fontSize: mobilePhraseSize),
                    ),
                  ],
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
