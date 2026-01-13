import 'package:accredit/core/utils/my_logs.dart';
import 'package:accredit/core/utils/my_nagivation.dart';
import 'package:accredit/domain/services/api_asodya_manager.dart';
import 'package:accredit/presentation/components/auth/login_redirect.dart';
import 'package:accredit/presentation/components/auth/verify_session.dart';
import 'package:accredit/presentation/components/auth/verify_tokens.dart';
import 'package:accredit/presentation/components/quiz/futuristic_loading.dart';
import 'package:accredit/presentation/widgets/attachment/on_attachment.dart';
import 'package:accredit/presentation/widgets/tokens/on_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;
import 'package:flutter/foundation.dart' show kIsWeb;

/// a StatefulWidget holding shared logic for Mobile/Desktop
abstract class BaseSyncAuth extends StatefulWidget {
  final String? tokenizedParam;

  const BaseSyncAuth({super.key, this.tokenizedParam});
}

abstract class BaseSyncAuthState<T extends BaseSyncAuth> extends State<T> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _exchangeTokenAndRoute();
  }

  Future<void> _exchangeTokenAndRoute() async {
    final token = widget.tokenizedParam;

    if (token == null || token.isEmpty) {
      debug('No tokenizedParam provided, checking existing session...');
      try {
        final hasSession = await isThereSession(
          cookieName: 'hint',
          storageNamespace: 'ath',
          storageKey: 'n-a-n',
        );

        final hasTokens = await isThereTokens();

        if (hasSession && hasTokens) {
          NavigationService.push(const OnAttachmentScreen());
          WidgetsBinding.instance.addPostFrameCallback((_) {
            cleanUrlAfterNav(path: '/');
          });
        } else if (hasSession && !hasTokens) {
          debug('Session exists but no tokens found. Redirecting to login.');
          NavigationService.push(const OnTokensScreen());
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
      final resp = await ApiAsodyaManager().exchange(token);

      if (!mounted) return;

      final hasTokens = await isThereTokens();

      if (resp.statusCode == 200 && hasTokens) {
        debug('Token exchange successful: ${resp.body}');

        _navOnce(() {
          // If you use MaterialApp.router, this avoids URL updates during the push:
          // Router.neglect(context, () {
          //   NavigationService.pushReplacement(const OnAttachmentScreen());
          // });
          NavigationService.pushReplacement(const OnAttachmentScreen());
          WidgetsBinding.instance.addPostFrameCallback((_) {
            cleanUrlAfterNav(path: '/');
          });
        });
      } else if (resp.statusCode == 200 && !hasTokens) {
        debug(
          'Token exchange successful but no tokens, redirecting to tokens screen.',
        );
        _navOnce(() {
          NavigationService.pushReplacement(const OnTokensScreen());
          WidgetsBinding.instance.addPostFrameCallback((_) {
            cleanUrlAfterNav(path: '/');
          });
        });
      } else {
        debug(
          'Token exchange failed with status ${resp.statusCode}. Redirecting to login.',
        );
        _toLogin();
      }
    } catch (e) {
      if (!mounted) return;
      debug('Error during token exchange: $e');
      _toLogin();
    }
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
  Widget buildLoadingScaffold({String title = 'Syncing…'}) {
    return Scaffold(
      body: const Center(
        child: FuturisticLoading(
          messages: [
            'Redirecting...',
            'Please wait while we take you there.',
            'Tip: If you encounter any issues, please contact support@asodya.com for assistance.',
          ],
          isActive: true,
          transparentBackground: true,
        ),
      ),
    );
  }
}
