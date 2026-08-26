import 'package:flutter/material.dart';
import 'package:certifications/core/utils/app_localizations.dart';

/// The landing footer deliberately mirrors the landing navigation. It is a
/// footer, not a second navigation model: each destination remains the same.
class BoardingFooter extends StatelessWidget {
  const BoardingFooter({super.key, this.onAbout, this.onLogin, this.onSignUp});

  final VoidCallback? onAbout;
  final VoidCallback? onLogin;
  final VoidCallback? onSignUp;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w600,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: LayoutBuilder(
          builder: (context, constraints) => Flex(
            direction: constraints.maxWidth < 620
                ? Axis.vertical
                : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: constraints.maxWidth < 620
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Text(
                'Certifications',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.4,
                ),
              ),
              SizedBox(height: constraints.maxWidth < 620 ? 18 : 0),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  TextButton(
                    onPressed: onAbout,
                    child: Text(context.tr('about'), style: labelStyle),
                  ),
                  TextButton(
                    onPressed: onLogin,
                    child: Text(context.tr('logIn'), style: labelStyle),
                  ),
                  TextButton(
                    onPressed: onSignUp,
                    child: Text(context.tr('signUp'), style: labelStyle),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
