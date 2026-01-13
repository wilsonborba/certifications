

import 'package:accredit/core/settings.dart';
import 'package:accredit/core/utils/my_logs.dart';
import 'package:accredit/presentation/components/auth/login_redirect.dart';
import 'package:accredit/presentation/components/auth/verify_session.dart';
import 'package:accredit/presentation/components/boarding/app_bar.dart';
import 'package:accredit/presentation/widgets/attachment/on_attachment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:accredit/core/utils/my_background.dart';
import 'package:accredit/core/utils/my_nagivation.dart';
import 'package:accredit/presentation/components/boarding/box_explaning.dart';
import 'package:accredit/presentation/components/boarding/first_phrase.dart';
import 'package:accredit/presentation/components/boarding/middle_button.dart';
import 'package:accredit/presentation/components/boarding/second_phrase.dart';
import 'package:accredit/presentation/components/plans/plans_view.dart';



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
      appBar: BoardingAppBar(
        logoAsset: "lib/presentation/assets/img/temp_logo.png",
         onAbout: (){
          final url = 'https://${app_settings.ASODYA_MAIN_DOMAIN}';
          redirectToUrl(url, replace: true);
        },
        onLogin: () async {
           final url = await urlRedirectionToAuth();
           redirectToUrl(url, replace: true);

        },
        onSignUp: () async {
          final url = await urlRedirectionToAuth(isToLogin: false);
          redirectToUrl(url, replace: true);
        },
      ),
      endDrawer: MobileSideMenu(
         onAbout: (){
          final url = 'https://${app_settings.ASODYA_MAIN_DOMAIN}';
          redirectToUrl(url, replace: true);
        },
        onLogin: () async {
           final url = await urlRedirectionToAuth();
                      redirectToUrl(url, replace: true);

        },
        onSignUp: () async {
          final url = await urlRedirectionToAuth(isToLogin: false);
          redirectToUrl(url, replace: true);
        },
      ),
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
                     padding: EdgeInsets.only(left: 10, top: 80),
                    child: FirstPhrase(fontSize: 50),
                  ),
                ),
            SizedBox(height: 80),
             Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.all(1),
                    child: MiddleButton(
                  label: "New Certification",
                  fontSize: 22,
                  minimumSize: const Size(200, 80),
                  iconSize: 30,
                  onPressed: () async {
                    try {
                      final hasSession = await isThereSession(
                        cookieName: 'hint',
                        storageNamespace: 'ath',
                        storageKey: 'n-a-n',
                      );

                      if (hasSession) {
                        NavigationService.push(OnAttachmentScreen());
                      } else {
                        final url = await urlRedirectionToAuth();
                        redirectToUrl(url, replace: true); // same-tab redirect
                        // Or: NavigationService.push(MyRedirectingWidget(redirectUrl: url));
                      }
                    } catch (e) {
                      debug('Session check/redirect error: $e');
                      final url = await urlRedirectionToAuth();
                      redirectToUrl(url, replace: true);
                    }
                  }
                ),
                  ),
                ),
              SizedBox(height: 80),
              const Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding:  EdgeInsets.only(right: 10, bottom: 80),
                  child: SecondPhrase(fontSize: 50),
                ),
              ),


          ],
        )),
      )
      ]),
// 2) SECTION: background fills the area, content centered, scrolls if needed
SizedBox(
  height: 1200,                  // pick a static section height for your design
  width: double.infinity,       // fill the viewport width
  child: Stack(
    children: [
      // background fills the whole section
      // Positioned.fill(
      //   child: SvgPicture.asset(
      //     'lib/presentation/assets/img/second_screen_bkg.svg',
      //     fit: BoxFit.cover,
      //   ),
      // ),

      // centered content; if total row > viewport, it scrolls horizontally
      Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            // gutters so cards never touch the screen edges
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
            child: Row(
              mainAxisSize: MainAxisSize.min,        // shrink to content width
              children: [
                BoxExplaning(
                  title: 'Playful Side',
                  body:
                      'Turn anything into a badge. From memes to random notes, transform everyday texts into funny certificates you can show off. Lighthearted, creative, and perfect for sharing laughs.',
                  height: 820,
                  width: 600,
                  image: 'lib/presentation/assets/img/no_creeper.png',
                  isSvg: false,
                  imageSource: BadgeImageSource.asset,
                  titleSize: 45,
                  bodySize: 30,
                  imageSize: 180,
                  imageOffset: -60,
                  imageInset: -20,
                  accentColor: Colors.transparent,
                  margin: const EdgeInsets.all(12),
                ),
                const SizedBox(width: 24),
                BoxExplaning(
                  title: 'Serious Mode',
                  body:
                      'When knowledge really counts. Upload books, study materials, or professional texts, then take AI-generated quizzes to prove your skills. Verified results for those who want recognition that matters.',
                  height: 820,
                  width: 600,
                  image: 'lib/presentation/assets/img/stamp.png',
                  isSvg: false,
                  imageSource: BadgeImageSource.asset,
                  titleSize: 45,
                  bodySize: 30,
                  imageSize: 200,
                  imageOffset: -70,
                  imageInset: -30,
                  accentColor: Colors.transparent,
                  margin: const EdgeInsets.all(12),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
),
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 80),
  child: PlansView(
    isDesktop: true,
    onConfigureKeys: () async {
      final url = await urlRedirectionToAuth();
      redirectToUrl(url, replace: true);
    },
  ),
),

      
      
      ]) 
    ));
  }
}
