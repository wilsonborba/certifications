import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/core/utils/my_logs.dart';
import 'package:certifications/core/utils/my_nagivation.dart';
import 'package:certifications/domain/services/api_asodya_manager.dart';
import 'package:certifications/domain/services/pending_intent_store.dart';
import 'package:certifications/presentation/components/auth/login_redirect.dart';
import 'package:certifications/presentation/components/auth/verify_session.dart';
import 'package:certifications/presentation/components/quiz/futuristic_loading.dart';
import 'package:certifications/presentation/widgets/attachment/on_attachment.dart';
import 'package:certifications/presentation/widgets/quiz/on_shared_quiz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;
import 'package:flutter/foundation.dart' show kIsWeb;

/// a StatefulWidget holding shared logic for Mobile/Desktop
abstract class BaseSyncAuth extends StatefulWidget {
  final String? authExchangeToken;

  const BaseSyncAuth({super.key, this.authExchangeToken});
}

abstract class BaseSyncAuthState<T extends BaseSyncAuth> extends State<T> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _exchangeTokenAndRoute();
  }

  Future<void> _exchangeTokenAndRoute() async {
    final authExchangeToken = widget.authExchangeToken;

    if (authExchangeToken == null || authExchangeToken.isEmpty) {
      debug('No auth exchange token provided, checking existing session...');
      try {
        final hasSession = await isThereSession(cookieName: 'csrf');

        if (hasSession) {
          // pushReplacement (not push): this screen must not linger as a
          // stale route[0] under the landing screen — popUntil((r) =>
          // r.isFirst) elsewhere in the app (quiz cancel, quiz done) relies
          // on the landing screen actually being the first route.
          NavigationService.pushReplacement(await _landingScreenAfterAuth());
          WidgetsBinding.instance.addPostFrameCallback((_) {
            cleanUrlAfterNav(path: '/');
          });
        } else {
          _toLogin();
        }
      } catch (e) {
        debug('Error checking session: $e');
        _toLogin();
      }

      return;
    }

    try {
      final resp = await ApiAsodyaManager().exchangeAuthExchangeToken(
        authExchangeToken,
      );

      if (!mounted) return;

      if (resp.statusCode == 200) {
        debug('Token exchange successful: ${resp.body}');

        _navOnce(() async {
          // If you use MaterialApp.router, this avoids URL updates during the push:
          // Router.neglect(context, () {
          //   NavigationService.pushReplacement(const OnAttachmentScreen());
          // });
          NavigationService.pushReplacement(await _landingScreenAfterAuth());
          WidgetsBinding.instance.addPostFrameCallback((_) {
            cleanUrlAfterNav(path: '/');
          });
        });
      } else {
        debug(
          'Auth exchange token exchange failed with status ${resp.statusCode}. Redirecting to login.',
        );
        _toLogin();
      }
    } catch (e) {
      if (!mounted) return;
      debug('Error during auth exchange token exchange: $e');
      _toLogin();
    }
  }

  /// The screen to land on right after authentication succeeds. If the
  /// visitor was redirected here mid-way through taking a shared quiz
  /// (#40), resumes exactly that instead of the generic logged-in home.
  Future<Widget> _landingScreenAfterAuth() async {
    final intent = await PendingIntentStore.instance.consumeQuizIntent();
    final shareToken = intent?.shareToken;
    if (shareToken != null) {
      return OnSharedQuizScreen(shareToken: shareToken, resumed: true);
    }
    // A pending intent captured by quiz id (found while browsing, not via a
    // share link) has no dedicated resume screen yet; land on the normal
    // logged-in home rather than guessing a destination.
    return const OnAttachmentScreen();
  }

  void _toLogin() async {
    _navOnce(() async {
      // External redirect (web-safe)
      redirectToUrl(
        await urlRedirectionToAuth(),
        replace: true,
        removeSlash: true,
      );
    });
  }

  // Ensure we navigate only once & never during build
  void _navOnce(VoidCallback cb) {
    if (_navigated) return;
    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      cb();
    });
  }

  void cleanUrlAfterNav({String path = '/'}) {
    if (!kIsWeb) return;

    void _setViaHistory() {
      final loc = web.window.location;
      web.window.history.replaceState(null, '', '${loc.origin}$path');
    }

    // 1) Do it now…
    _setViaHistory();

    // 2) …and once the next frame lands, also tell Flutter’s Router.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        SystemNavigator.routeInformationUpdated(
          uri: Uri.parse(path),
          replace: true,
        );
      } catch (e) {
        debug('routeInformationUpdated failed (non-router app?): $e');
      }
      // belt-and-suspenders in case a rebuild reverts it again
      _setViaHistory();
    });
  }

  /// Call this from your subclass build to show a loading page
  Widget buildLoadingScaffold({String? title}) {
    return Scaffold(
      body: Center(
        child: FuturisticLoading(
          messages: [
            context.tr('redirecting'),
            context.tr('pleaseWaitRedirect'),
            context.tr('supportTip'),
          ],
          isActive: true,
          transparentBackground: true,
        ),
      ),
    );
  }
}
