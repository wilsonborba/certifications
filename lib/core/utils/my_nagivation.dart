// lib/core/utils/my_redirect_widget.dart
// Minimal redirect widget that uses the safe helper in my_route_parser.dart.


import 'package:flutter/material.dart';
import 'package:accredit/core/utils/my_router_parser.dart';



void redirectToUrl(String url) {
  // delegate to the web-safe implementation in my_route_parser.dart
  replaceLocation(url);
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Redirecting...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
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
