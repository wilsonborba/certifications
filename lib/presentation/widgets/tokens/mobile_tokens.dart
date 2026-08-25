import 'package:certifications/presentation/components/tokens/tokens_view.dart';
import 'package:flutter/material.dart';

class MobileTokens extends StatefulWidget {
  const MobileTokens({super.key});

  @override
  State<MobileTokens> createState() => _MobileTokensState();
}

class _MobileTokensState extends State<MobileTokens> {
  @override
  Widget build(BuildContext context) {
    return const TokensView(isDesktop: false);
  }
}
