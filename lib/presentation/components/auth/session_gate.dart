// ---- 1) Put this widget somewhere in the same file ----
import 'package:certifications/presentation/components/auth/verify_session.dart';
import 'package:certifications/presentation/widgets/attachment/on_attachment.dart';
import 'package:certifications/presentation/widgets/boarding/on_boarding.dart';
import 'package:flutter/material.dart';
import 'package:certifications/core/utils/app_localizations.dart';

class SessionGate extends StatelessWidget {
  const SessionGate({super.key});

  Future<bool> _check() async {
    try {
      return await isThereSession();
    } catch (_) {
      return false; // on error, treat as no session
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _check(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text(context.tr('loading')),
                ],
              ),
            ),
          );
        }

        final hasSession = snap.data == true;
        return hasSession
            ? const OnAttachmentScreen()
            : const OnBoardingScreen();
      },
    );
  }
}
