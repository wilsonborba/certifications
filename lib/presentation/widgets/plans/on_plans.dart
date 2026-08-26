import 'package:certifications/core/settings.dart';
import 'package:certifications/core/utils/my_nagivation.dart';
import 'package:certifications/presentation/components/boarding/app_bar.dart';
import 'package:certifications/presentation/components/plans/plans_view.dart';
import 'package:certifications/presentation/components/auth/login_redirect.dart';
import 'package:certifications/presentation/components/auth/session_gate.dart';
import 'package:flutter/material.dart';

class OnPlansScreen extends StatelessWidget {
  const OnPlansScreen({super.key});

  static const String route = '/plans';

  String get _aboutUrl => 'https://${app_settings.ASODYA_MAIN_DOMAIN}';

  void _about() => redirectToUrl(_aboutUrl, replace: false);

  Future<void> _login() async =>
      redirectToUrl(await urlRedirectionToAuth(), replace: true);

  Future<void> _signUp() async => redirectToUrl(
    await urlRedirectionToAuth(isToLogin: false),
    replace: true,
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    void _home() => NavigationService.pushReplacement(const SessionGate());

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: BoardingAppBar(
        logoAsset: "lib/presentation/assets/img/temp_logo.png",
        currentTab: 'plans',
        onHome: _home,
        onAbout: _about,
        onLogin: _login,
        onSignUp: _signUp,
      ),
      endDrawer: MobileSideMenu(
        currentTab: 'plans',
        onHome: _home,
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
  }
}
