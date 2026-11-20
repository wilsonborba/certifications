import 'package:certifications/core/settings.dart';
import 'package:certifications/core/utils/my_logs.dart';
import 'package:certifications/core/utils/my_nagivation.dart';
import 'package:certifications/presentation/components/auth/login_redirect.dart';
import 'package:certifications/presentation/components/auth/verify_session.dart';
import 'package:certifications/presentation/components/boarding/app_bar.dart';
import 'package:certifications/presentation/components/boarding/boarding_footer.dart';
import 'package:certifications/presentation/components/plans/plans_view.dart'
    show handleWaitlistFlow;
import 'package:certifications/presentation/widgets/attachment/on_attachment.dart';
import 'package:certifications/presentation/widgets/landing/landing_body.dart';
import 'package:flutter/material.dart';

void _about() =>
    redirectToUrl('https://${app_settings.ASODYA_MAIN_DOMAIN}', replace: true);

Future<void> _login() async =>
    redirectToUrl(await urlRedirectionToAuth(), replace: true);

Future<void> _signUp() async =>
    redirectToUrl(await urlRedirectionToAuth(isToLogin: false), replace: true);

/// Starts a new study: the attachment flow with a session, the sign-up
/// otherwise (the same flow as the earlier landing).
Future<void> startStudy() async {
  try {
    if (await isThereSession()) {
      NavigationService.push(const OnAttachmentScreen());
      return;
    }
  } catch (e) {
    debug('Session check error: $e');
  }
  redirectToUrl(await urlRedirectionToAuth(isToLogin: false), replace: true);
}

LandingActions _actions(BuildContext context) => LandingActions(
  onStart: startStudy,
  onWaitlist: () => handleWaitlistFlow(context, 'guided'),
);

/// The public pages of Certifications: the top bar with the shared Asodya
/// logo, the side menu on narrow windows, one scroll view and the footer.
class LandingScaffold extends StatelessWidget {
  const LandingScaffold({super.key, required this.child});

  final Widget child;

  static Widget footer() =>
      const BoardingFooter(onAbout: _about, onLogin: _login, onSignUp: _signUp);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const BoardingAppBar(
      logoAsset: 'lib/presentation/assets/img/temp_logo.png',
      onAbout: _about,
      onLogin: _login,
      onSignUp: _signUp,
    ),
    endDrawer: const MobileSideMenu(
      onAbout: _about,
      onLogin: _login,
      onSignUp: _signUp,
    ),
    body: SingleChildScrollView(child: child),
  );
}

/// The landing page.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) => LandingScaffold(
    child: LandingBody(
      actions: _actions(context),
      footer: LandingScaffold.footer(),
    ),
  );
}

/// The page of one topic of the icon row.
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key, required this.topicId});

  final String topicId;

  @override
  Widget build(BuildContext context) => LandingScaffold(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LearnBody(topicId: topicId, onStart: startStudy),
        LandingScaffold.footer(),
      ],
    ),
  );
}
