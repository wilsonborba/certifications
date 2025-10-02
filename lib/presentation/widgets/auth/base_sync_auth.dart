import 'package:accredit/core/utils/my_logs.dart';
import 'package:accredit/domain/services/api_auth_manager.dart';
import 'package:flutter/material.dart';

/// a StatefulWidget holding shared logic for Mobile/Desktop
abstract class BaseSyncAuth extends StatefulWidget {

  final String? tokenizedParam;

  const BaseSyncAuth({super.key, this.tokenizedParam});

  
}

/// Shared state with common helpers for sync auth screens.
/// Subclasses get:
/// - controller (paging/search/ticker/grid-height)
/// - data/cache/search helpers
/// - convenience getters (visibleItems/isBusy/windowInfo)
abstract class BaseSyncAuthState<T extends BaseSyncAuth> extends State<T> {








  exchangeToken() async {
    final manager = ApiAuthManager();
    if (widget.tokenizedParam != null) {
      try {
        final response = await manager.exchange(widget.tokenizedParam!);
       if (response.statusCode != 200) {
          throw Exception('Failed to exchange token (status ${response.statusCode})');
        }
        debug('Token exchange successful: ${response.body}');
      } catch (e) {
        debug('Error during token exchange: $e');
      }
    } else {
      debug('No tokenizedParam provided for token exchange');
    }
  }

  @override
  void initState() {
    super.initState();
    exchangeToken();
  }

  @override
  void dispose() {
    // controller.dispose();
    super.dispose();
  }
}