import 'package:accredit/core/utils/my_logs.dart';
import 'package:accredit/core/utils/my_nagivation.dart';
import 'package:accredit/domain/services/api_auth_manager.dart';
import 'package:accredit/presentation/components/auth/login_redirect.dart';
import 'package:accredit/presentation/widgets/attachment/on_attachment.dart';
import 'package:flutter/material.dart';

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
      debug('No tokenizedParam provided. Redirecting to login.');
      _toLogin();
      return;
    }

    try {
      final resp = await ApiAuthManager().exchange(token);

      if (!mounted) return;

      if (resp.statusCode == 200) {
        debug('Token exchange successful: ${resp.body}');
        _navOnce(() {
          // Go to your next screen inside the app.
          NavigationService.pushReplacement(const OnAttachmentScreen());
        });
      } else {
        debug('Token exchange failed with status ${resp.statusCode}. Redirecting to login.');
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
      redirectToUrl(await urlRedirectionToLogin(), replace: true, removeSlash: true);
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

  /// Call this from your subclass build to show a loading page
  Widget buildLoadingScaffold({String title = 'Syncing…'}) {
    return Scaffold(
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Please wait…'),
          ],
        ),
      ),
    );
  }
}
