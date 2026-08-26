import 'package:certifications/core/settings.dart';
import 'package:certifications/core/utils/my_nagivation.dart';
import 'package:certifications/presentation/components/attachment/app_bar.dart';
import 'package:certifications/presentation/components/attachment/card_pdf_picker.dart';
import 'package:certifications/presentation/widgets/certifications/on_certifications.dart';
import 'package:certifications/presentation/widgets/plans/on_plans.dart';
import 'package:certifications/presentation/widgets/tokens/on_tokens.dart';
import 'package:flutter/material.dart';

class MobileAttachment extends StatelessWidget {
  const MobileAttachment({super.key});

  @override
  Widget build(BuildContext context) {
    void openCertificates() =>
        NavigationService.push(const OnCertificationsScreen());
    void openPlans() => NavigationService.push(const OnPlansScreen());
    void openTokens() => NavigationService.push(OnTokensScreen());
    void openSupport() => redirectToUrl('mailto:support@asodya.com');
    void openAbout() => redirectToUrl(
      'https://${app_settings.ASODYA_MAIN_DOMAIN}',
      replace: true,
    );

    return Scaffold(
      appBar: AttachmentAppBar(
        onCertificates: openCertificates,
        onPlans: openPlans,
        onTokens: openTokens,
        onSupport: openSupport,
        onAbout: openAbout,
      ),
      endDrawer: AttachmentSideMenu(
        onCertificates: openCertificates,
        onPlans: openPlans,
        onTokens: openTokens,
        onSupport: openSupport,
        onAbout: openAbout,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Center(
              child: CardPdfPicker(
                width: constraints.maxWidth.clamp(0.0, 360.0).toDouble(),
                height: 640,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
