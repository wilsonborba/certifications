// mobile_boarding.dart
import 'package:certifications/core/settings.dart';
import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/core/utils/my_logs.dart';
import 'package:certifications/presentation/components/auth/login_redirect.dart';
import 'package:certifications/presentation/components/auth/verify_session.dart';
import 'package:certifications/presentation/components/boarding/app_bar.dart';
import 'package:certifications/presentation/components/boarding/boarding_marketing.dart';
import 'package:certifications/presentation/components/boarding/value_proposition_section.dart';
import 'package:certifications/presentation/components/boarding/boarding_footer.dart';
import 'package:certifications/presentation/widgets/attachment/on_attachment.dart';
import 'package:flutter/material.dart';
import 'package:certifications/core/utils/my_background.dart';
import 'package:certifications/core/utils/my_nagivation.dart';
import 'package:certifications/presentation/components/boarding/box_explaning.dart';
import 'package:certifications/presentation/components/boarding/first_phrase.dart';
import 'package:certifications/presentation/components/boarding/second_phrase.dart';
import 'package:certifications/presentation/components/boarding/middle_button.dart';
import 'package:certifications/presentation/components/plans/plans_view.dart';

class MobileBoarding extends StatelessWidget {
  const MobileBoarding({super.key});

  String get _aboutUrl => 'https://${app_settings.ASODYA_MAIN_DOMAIN}';
  void _about() => redirectToUrl(_aboutUrl, replace: true);
  Future<void> _login() async =>
      redirectToUrl(await urlRedirectionToAuth(), replace: true);
  Future<void> _signUp() async => redirectToUrl(
    await urlRedirectionToAuth(isToLogin: false),
    replace: true,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BoardingAppBar(
        logoAsset: "lib/presentation/assets/img/temp_logo.png",
        onAbout: _about,
        onLogin: _login,
        onSignUp: _signUp,
      ),
      endDrawer: MobileSideMenu(
        onAbout: _about,
        onLogin: _login,
        onSignUp: _signUp,
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
                    blobCount: 5,
                    blurSigma: 22, // ≈ “70% blur” feel
                    centerFocusRadius:
                        .002, // crisper center (0..1 of shortest side)
                    speed: 28, // px/sec nominal speed
                  ),
                ),
                Center(
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
                              label: context.tr('newStudy'),
                              fontSize: 18,
                              minimumSize: const Size(150, 50),
                              iconSize: 22,
                              onPressed: () async {
                                try {
                                  final hasSession = await isThereSession();

                                  if (hasSession) {
                                    NavigationService.push(
                                      OnAttachmentScreen(),
                                    );
                                  } else {
                                    final url = await urlRedirectionToAuth();
                                    redirectToUrl(
                                      url,
                                      replace: true,
                                    ); // same-tab redirect
                                    // Or: NavigationService.push(MyRedirectingWidget(redirectUrl: url));
                                  }
                                } catch (e) {
                                  debug('Session check/redirect error: $e');
                                  final url = await urlRedirectionToAuth();
                                  redirectToUrl(url, replace: true);
                                }
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 80),
                        const Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: EdgeInsets.only(right: 10, bottom: 100),
                            child: SecondPhrase(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 2) SECTION: background fills the area, content centered, scrolls if needed
            SizedBox(
              height: 1800, // pick a static section height for your design
              width: double.infinity, // fill the viewport width
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
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min, // shrink to content width
                          children: [
                            BoxExplaning(
                              title: context.tr('landingExample'),
                              body: context.tr('playfulBody'),
                              height: 620,
                              width: 350,
                              image:
                                  'lib/presentation/assets/img/no_creeper.png',
                              isSvg: false,
                              imageSource: BadgeImageSource.asset,
                              titleSize: 25,
                              bodySize: 15,
                              imageSize: 130,
                              imageOffset: -40,
                              imageInset: -8,
                              accentColor: Colors.transparent,
                              margin: const EdgeInsets.all(12),
                            ),
                            const SizedBox(width: 24, height: 80),
                            BoxExplaning(
                              title: context.tr('welcomeTitle'),
                              body: context.tr('seriousBody'),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 60,
              ),
              child: PlansView(isDesktop: false),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 24,
              ),
              child: BoardingMarketing(isDesktop: false),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 24,
              ),
              child: ValuePropositionSection(isDesktop: false),
            ),
            BoardingFooter(onAbout: _about, onLogin: _login, onSignUp: _signUp),
          ],
        ),
      ),
    );
  }
}
