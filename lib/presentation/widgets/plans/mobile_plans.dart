import 'package:accredit/core/settings.dart';
import 'package:accredit/core/utils/my_nagivation.dart';
import 'package:accredit/presentation/components/attachment/app_bar.dart';
import 'package:accredit/presentation/components/plans/plans_view.dart';
import 'package:accredit/presentation/widgets/certifications/on_certifications.dart';
import 'package:accredit/presentation/widgets/plans/on_plans.dart';
import 'package:accredit/presentation/widgets/tokens/on_tokens.dart';
import 'package:flutter/material.dart';

class MobilePlans extends StatelessWidget {
  const MobilePlans({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AttachmentAppBar(
        title: 'Plans',
        onCertificates: () {
          NavigationService.push(const OnCertificationsScreen());
        },
        onPlans: () {
          NavigationService.push(const OnPlansScreen());
        },
        onTokens: () {
          NavigationService.push(const OnTokensScreen());
        },
        onSupport: () => redirectToUrl('mailto:support@asodya.com'),
        onAbout: () {
          final url = 'https://${app_settings.ASODYA_MAIN_DOMAIN}';
          redirectToUrl(url, replace: true);
        },
      ),
      endDrawer: AttachmentSideMenu(
        onCertificates: () {
          NavigationService.push(const OnCertificationsScreen());
        },
        onPlans: () {
          NavigationService.push(const OnPlansScreen());
        },
        onTokens: () {
          NavigationService.push(const OnTokensScreen());
        },
        onSupport: () => redirectToUrl('mailto:support@asodya.com'),
        onAbout: () {
          final url = 'https://${app_settings.ASODYA_MAIN_DOMAIN}';
          redirectToUrl(url, replace: true);
        },
      ),
      body: PlansView(
        isDesktop: false,
        onConfigureKeys: () {
          NavigationService.push(const OnTokensScreen());
        },
      ),
    );
  }
}
