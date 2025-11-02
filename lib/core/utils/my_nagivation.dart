// lib/core/utils/my_redirect_widget.dart
// Minimal redirect widget that uses the safe helper in my_route_parser.dart.


import 'package:accredit/core/utils/my_logs.dart';
import 'package:accredit/dal/local/local_source_adapter.dart';
import 'package:accredit/presentation/components/auth/login_redirect.dart';
import 'package:accredit/presentation/components/quiz/futuristic_loading.dart';
import 'package:flutter/material.dart';
import 'package:accredit/core/utils/my_router_parser.dart';

/// Clears cookies + local storage. Call this for Logout.
Future<void> clearSessionArtifacts() async {
  // cookies
  deleteCookies(const ['hint', 'sid']);
  // local storage: ath::n-a-n
  try {
    await LocalSourceAdapter(namespace: 'ath').delete('n-a-n');
  } catch (e) {
    // ignore missing; just log
    debug('localStorage delete ath::n-a-n failed (maybe missing): $e');
  }
}

Future<void> defaultLogout() async {
    await clearSessionArtifacts();
    // send to auth login screen (same flow you already use elsewhere)
    try {
      final url = await urlRedirectionToAuth();
      redirectToUrl(url, replace: true, removeSlash: true);
    } catch (e) {
      debug('default logout redirect failed: $e');
    }
  }



void redirectToUrl(String url, {bool replace = true, bool removeSlash = false}) {
  // delegate to the web-safe implementation in my_route_parser.dart
  if (replace) {
    replaceLocation(url, removeSlash: removeSlash);
  } else {
    redirectLocation(url);
  }
}



class MyRedirectingWidget extends StatelessWidget {
  static const String route = '/';

  final String redirectUrl;

  const MyRedirectingWidget({
    super.key,
    required this.redirectUrl,
  });

  @override
  Widget build(BuildContext context) {
    // schedule the redirect after the first frame — avoids side-effects during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      redirectToUrl(redirectUrl);
    });

    return const Scaffold(
      body: Center(
        child: FuturisticLoading(
          messages:  [
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

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<dynamic>? push(Widget page) {
    return navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  static Future<dynamic>? pushReplacement(Widget page) {
    return navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  static void pop() {
    navigatorKey.currentState?.pop();
  }
}
