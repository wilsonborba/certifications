import 'package:certifications/presentation/widgets/auth/base_sync_auth.dart';
import 'package:flutter/material.dart';
import 'package:certifications/core/utils/app_localizations.dart';

///  renders the topics grid for desktop layout
/// and wires up search/pagination via BaseSyncAuthState (no duplication).
class DesktopSyncAuth extends BaseSyncAuth {
  const DesktopSyncAuth({super.key, String? authExchangeToken})
    : super(authExchangeToken: authExchangeToken);

  @override
  State<DesktopSyncAuth> createState() => _DesktopSyncAuthState();
}

class _DesktopSyncAuthState extends BaseSyncAuthState<DesktopSyncAuth> {
  @override
  Widget build(BuildContext context) {
    return buildLoadingScaffold(title: context.tr('loading'));
  }
}
