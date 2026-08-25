import 'package:certifications/presentation/components/tokens/tokens_view.dart';
import 'package:flutter/material.dart';

class DesktopTokens extends StatefulWidget {
  const DesktopTokens({super.key});

  @override
  State<DesktopTokens> createState() => _DesktopTokensState();
}

class _DesktopTokensState extends State<DesktopTokens> {
  @override
  Widget build(BuildContext context) {
    return const TokensView(isDesktop: true);
  }
}
