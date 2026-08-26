import 'package:certifications/presentation/widgets/auth/base_sync_auth.dart';
import 'package:flutter/material.dart';
import 'package:certifications/core/utils/app_localizations.dart';

///  renders the topics grid for mobile layout
/// and wires up search/pagination via BaseSyncAuthState (no duplication).
class MobileSyncAuth extends BaseSyncAuth {
  const MobileSyncAuth({super.key, String? authExchangeToken})
    : super(authExchangeToken: authExchangeToken);

  @override
  State<MobileSyncAuth> createState() => _MobileSyncAuthState();
}

class _MobileSyncAuthState extends BaseSyncAuthState<MobileSyncAuth> {
  @override
  Widget build(BuildContext context) {
    return buildLoadingScaffold(title: context.tr('loading'));
  }
}
