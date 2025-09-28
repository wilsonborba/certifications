// mobile_boarding.dart
import 'package:accredit/presentation/widgets/attachment/on_attachment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:accredit/core/utils/my_background.dart';
import 'package:accredit/core/utils/my_nagivation.dart';
import 'package:accredit/presentation/components/boarding/box_explaning.dart';
import 'package:accredit/presentation/components/boarding/first_phrase.dart';
import 'package:accredit/presentation/components/boarding/second_phrase.dart';
import 'package:accredit/presentation/components/boarding/middle_button.dart';


class MobileBoarding extends StatelessWidget {
  const MobileBoarding({super.key});



  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              
              child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [ 
             Stack(
          children: [
            // BACKGROUND (under everything)
             Positioned.fill(
              child: LiquidMetalBackground(
                blobCount: 5,
                blurSigma: 22,        // ≈ “70% blur” feel
                centerFocusRadius: .002, // crisper center (0..1 of shortest side)
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
                     padding: EdgeInsets.only(left: 5, top: 100),
                    child: FirstPhrase(fontSize: 18),
                  ),
                ),
            SizedBox(height: 80),
             Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.all(1),
                    child: MiddleButton(
                  label: "New Certification",
                  fontSize: 18,
                  minimumSize: const Size(150, 50),
                  iconSize: 22,
                  onPressed: () {
                    NavigationService.push(OnAttachmentScreen());
                  },
                ),
                  ),
                ),
              SizedBox(height: 80),
              const Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding:  EdgeInsets.only(right: 10, bottom: 100),
                  child: SecondPhrase(fontSize: 18),
                ),
              ),


          ],
        )),
      )
      ]),
// 2) SECTION: background fills the area, content centered, scrolls if needed
SizedBox(
  height: 1800,                  // pick a static section height for your design
  width: double.infinity,       // fill the viewport width
  child: Stack(
    children: [
      // background fills the whole section
      Positioned.fill(
        child: SvgPicture.asset(
          'lib/presentation/assets/img/second_screen_bkg.svg',
          fit: BoxFit.cover,
        ),
      ),

      // centered content; if total row > viewport, it scrolls horizontally
      Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            // gutters so cards never touch the screen edges
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,        // shrink to content width
              children: [
                BoxExplaning(
                  title: 'Playful Side',
                  body:
                      'Turn anything into a badge. From memes to random notes, transform everyday texts into funny certificates you can show off. Lighthearted, creative, and perfect for sharing laughs.',
                  height: 620,
                  width: 350,
                  image: 'lib/presentation/assets/img/no_creeper.png',
                  isSvg: false,
                  imageSource: BadgeImageSource.asset,
                  titleSize: 25,
                  bodySize: 15,
                  imageSize: 130,
                  imageOffset: -40,
                  imageInset: -8,
                  accentColor: Theme.of(context).colorScheme.primary,
                  margin: const EdgeInsets.all(12),
                ),
                const SizedBox(width: 24),
                BoxExplaning(
                  title: 'Serious Mode',
                  body:
                      'When knowledge really counts. Upload books, study materials, or professional texts, then take AI-generated quizzes to prove your skills. Verified results for those who want recognition that matters.',
                  height: 670,
                  width: 350,
                  image: 'lib/presentation/assets/img/stamp.png',
                  isSvg: false,
                  imageSource: BadgeImageSource.asset,
                  titleSize: 25,
                  bodySize: 15,
                  imageSize: 130,
                  imageOffset: -40,
                  imageInset: -8,
                  accentColor: Theme.of(context).colorScheme.primary,
                  margin: const EdgeInsets.all(12),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
)

      
      
      ]) 
    ));
  }
}
