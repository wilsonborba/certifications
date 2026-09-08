// lib/core/utils/my_redirect_widget.dart
// Minimal redirect widget that uses the safe helper in my_route_parser.dart.

import 'package:certifications/core/utils/my_logs.dart';
import 'package:certifications/core/settings.dart';
import 'package:certifications/dal/local/local_source_adapter.dart';
import 'package:flutter/material.dart';
import 'package:certifications/domain/services/api_asodya_manager.dart';
import 'package:certifications/presentation/components/auth/login_redirect.dart';
import 'package:certifications/core/utils/my_router_parser.dart';

/// Clears cookies + local storage. Call this for Logout.
Future<void> clearSessionArtifacts() async {
  try {
    await ApiAsodyaManager().logOut();
  } catch (e) {
    debug('backend logOut failed: $e');
  }
  // cookies
  deleteCookies(const ['csrf', 'sid']);
}

Future<void> defaultLogout() async {
  await clearSessionArtifacts();
  // send to auth login screen with encrypted applicationInfo context
  try {
    final loginUrl = await urlRedirectionToAuth();
    redirectToUrl(
      loginUrl,
      replace: true,
      removeSlash: true,
    );
  } catch (e) {
    debug('default logout redirect fallback to base auth: $e');
    redirectToUrl(
      app_settings.ASODYA_AUTH_LOGIN_URL,
      replace: true,
      removeSlash: true,
    );
  }
}


void redirectToUrl(
  String url, {
  bool replace = true,
  bool removeSlash = false,
}) {
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

  const MyRedirectingWidget({super.key, required this.redirectUrl});

  @override
  Widget build(BuildContext context) {
    // schedule the redirect after the first frame — avoids side-effects during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      redirectToUrl(redirectUrl);
    });

    return Scaffold(body: Center(child: CircularProgressIndicator()));
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
