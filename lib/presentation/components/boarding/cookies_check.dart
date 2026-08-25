import 'package:accredit/dal/local/local_source_adapter.dart';
import 'package:flutter/material.dart';

class CookieConsentSnack {
  static const String _storageNamespace = 'privacy';
  static const String _storageKey =
      'cookie_consent'; // value: 'all' | 'necessary'
  static const Duration _keepVisible = Duration(
    days: 3650,
  ); // effectively persistent until user clicks

  /// Call once after the first frame; will show the SnackBar only if needed.
  static Future<void> showIfNeeded(BuildContext context) async {
    final store = LocalSourceAdapter(namespace: _storageNamespace);
    final exists = await store.exists(_storageKey);
    if (exists) return;

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final purple = scheme.primary;

    // Compose the content widget so we can reuse the same style for both buttons.
    Widget content = _CookieConsentContent(
      purple: purple,
      onAcceptAll: () async {
        await store.upsert(_storageKey, 'all');
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
      onAcceptNecessary: () async {
        await store.upsert(_storageKey, 'necessary');
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
    );

    final snack = SnackBar(
      // Visuals: black surface, rounded, bottom floating; similar to your AppBar theme
      backgroundColor: Colors.black,
      behavior: SnackBarBehavior.floating,
      elevation: 8,
      duration: _keepVisible, // stays up until user clicks
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      content: content,
    );

    // Show the SnackBar (bottom bar)
    ScaffoldMessenger.of(context).showSnackBar(snack);
  }
}

/// Internal content for the cookie snack bar:
/// - Responsive layout using Wrap so it fits mobile/desktop nicely.
/// - Purple elevated buttons with hover effects (WidgetState* + withValues()).
class _CookieConsentContent extends StatelessWidget {
  const _CookieConsentContent({
    required this.purple,
    required this.onAcceptAll,
    required this.onAcceptNecessary,
  });

  final Color purple;
  final VoidCallback onAcceptAll;
  final VoidCallback onAcceptNecessary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textColor = scheme.onPrimary; // white-ish on purple

    // Shared purple elevated style with hover polish
    ButtonStyle _purpleElevatedStyle() {
      return ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        minimumSize: WidgetStateProperty.all(const Size(64, 40)),
        animationDuration: const Duration(milliseconds: 140),
        backgroundColor: WidgetStateProperty.resolveWith((s) {
          // Slight darken on hover/pressed
          final isHover =
              s.contains(WidgetState.hovered) ||
              s.contains(WidgetState.pressed);
          return isHover ? purple.withValues(alpha: 0.92) : purple;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((_) => textColor),
        elevation: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.hovered) ? 4 : 0,
        ),
        shadowColor: WidgetStateProperty.resolveWith((_) => purple),
      );
    }

    // Text style: readable on black
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Colors.white.withValues(alpha: 0.90),
      height: 1.3,
    );

    return LayoutBuilder(
      builder: (ctx, c) {
        // If narrow, Wrap will put buttons under the text; if wide, inline row.
        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 12,
          spacing: 12,
          children: [
            // Message (expand on wide screens)
            ConstrainedBox(
              constraints: BoxConstraints(
                // Keep message readable; let it wrap on mobile
                maxWidth: c.maxWidth >= 720 ? c.maxWidth * 0.66 : c.maxWidth,
              ),
              child: Text(
                'We use cookies to enhance your browsing experience, provide essential functionality, '
                'and analyze traffic. You can accept all cookies or only the necessary ones.',
                style: bodyStyle,
              ),
            ),

            // Buttons group
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                // Accept only necessary
                ElevatedButton(
                  style: _purpleElevatedStyle(),
                  onPressed: onAcceptNecessary,
                  child: const Text('Accept only necessary'),
                ),
                // Accept all
                ElevatedButton(
                  style: _purpleElevatedStyle(),
                  onPressed: onAcceptAll,
                  child: const Text('Accept all'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
