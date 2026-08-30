import 'package:certifications/core/settings.dart';
import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/core/utils/my_nagivation.dart';
import 'package:certifications/presentation/components/attachment/app_bar.dart';
import 'package:certifications/presentation/components/boarding/app_bar.dart';
import 'package:certifications/presentation/components/plans/plans_view.dart';
import 'package:certifications/presentation/components/auth/login_redirect.dart';
import 'package:certifications/presentation/components/auth/session_gate.dart';
import 'package:certifications/presentation/components/auth/verify_session.dart';
import 'package:flutter/material.dart';

/// The Plans screen is reachable from both the logged-out landing pages
/// (BoardingAppBar's own Plans link) and from the logged-in app shell
/// (AttachmentAppBar's Plans item), plus a direct `/plans` route. It must
/// render the app bar that matches whichever world the visitor is actually
/// in, rather than always showing the logged-out bar: a logged-in user who
/// lands here needs to keep their normal navigation (Studies, Certificates,
/// Support, ...), not see Log in / Sign up buttons.
class OnPlansScreen extends StatefulWidget {
  const OnPlansScreen({super.key});

  static const String route = '/plans';

  @override
  State<OnPlansScreen> createState() => _OnPlansScreenState();
}

class _OnPlansScreenState extends State<OnPlansScreen> {
  late final Future<bool> _sessionFuture = _checkSession();

  Future<bool> _checkSession() async {
    try {
      return await isThereSession();
    } catch (_) {
      return false; // on error, treat as no session (logged-out bar)
    }
  }

  String get _aboutUrl => 'https://${app_settings.ASODYA_MAIN_DOMAIN}';

  void _about() => redirectToUrl(_aboutUrl, replace: false);

  Future<void> _login() async =>
      redirectToUrl(await urlRedirectionToAuth(), replace: true);

  Future<void> _signUp() async => redirectToUrl(
    await urlRedirectionToAuth(isToLogin: false),
    replace: true,
  );

  void _goToStudies() => NavigationService.pushReplacement(const SessionGate());

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return FutureBuilder<bool>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: scheme.surface,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(context.tr('loading')),
                ],
              ),
            ),
          );
        }

        final isLoggedIn = snapshot.data == true;

        return Scaffold(
          backgroundColor: scheme.surface,
          appBar: isLoggedIn
              ? AttachmentAppBar(
                  title: context.tr('plans'),
                  currentTab: 'plans',
                )
              : BoardingAppBar(
                  logoAsset: "lib/presentation/assets/img/temp_logo.png",
                  currentTab: 'plans',
                  onHome: _goToStudies,
                  onAbout: _about,
                  onLogin: _login,
                  onSignUp: _signUp,
                ),
          endDrawer: isLoggedIn
              ? const AttachmentSideMenu(currentTab: 'plans')
              : MobileSideMenu(
                  currentTab: 'plans',
                  onHome: _goToStudies,
                  onAbout: _about,
                  onLogin: _login,
                  onSignUp: _signUp,
                ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: PlansView(
                  isDesktop: isDesktop,
                  showHeader: true,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
