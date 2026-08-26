import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/core/utils/app_preferences.dart';
import 'package:flutter/material.dart';

/// Compact controls for desktop app bars. The sheet contains the full
/// hand-built language list and the light/dark switch shared by all routes.
class AppPreferencesButton extends StatelessWidget {
  const AppPreferencesButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: context.tr('appearanceAndLanguage'),
      icon: Icon(Icons.tune_rounded, color: scheme.onSurface),
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        backgroundColor: scheme.surface,
        builder: (_) => const _PreferencesSheet(),
      ),
    );
  }
}

class AppPreferencesPanel extends StatelessWidget {
  const AppPreferencesPanel({super.key});

  @override
  Widget build(BuildContext context) =>
      const _PreferencesContent(compact: true);
}

class _PreferencesSheet extends StatelessWidget {
  const _PreferencesSheet();
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: const _PreferencesContent(),
    ),
  );
}

class _PreferencesContent extends StatelessWidget {
  const _PreferencesContent({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final preferences = AppPreferencesScope.maybeOf(context);
    if (preferences == null) return const SizedBox.shrink();
    final selected = preferences.locale?.languageCode;
    final languages = <({String code, String label, String native})>[
      (code: 'en', label: 'English', native: 'English'),
      (code: 'pt', label: 'Português', native: 'Português'),
      (code: 'th', label: 'Thai', native: 'ไทย'),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          Text(
            context.tr('appearanceAndLanguage'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
        ],
        _PreferenceShell(
          child: SwitchListTile.adaptive(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            secondary: const Icon(Icons.dark_mode_outlined),
            title: Text(context.tr('darkTheme')),
            subtitle: Text(context.tr('themeDescription')),
            value: preferences.themeMode == ThemeMode.dark,
            onChanged: (dark) =>
                preferences.setTheme(dark ? ThemeMode.dark : ThemeMode.light),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          context.tr('language'),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: scheme.onSurface.withValues(alpha: .72),
          ),
        ),
        const SizedBox(height: 8),
        _PreferenceShell(
          child: Column(
            children: languages.map((item) {
              final isSelected = selected == item.code;
              return _LanguageTile(
                label: item.label,
                native: item.native,
                selected: isSelected,
                onTap: () => preferences.setLocale(Locale(item.code)),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _PreferenceShell extends StatelessWidget {
  const _PreferenceShell({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withValues(alpha: .45)),
      ),
      child: child,
    );
  }
}

class _LanguageTile extends StatefulWidget {
  const _LanguageTile({
    required this.label,
    required this.native,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String native;
  final bool selected;
  final VoidCallback onTap;
  @override
  State<_LanguageTile> createState() => _LanguageTileState();
}

class _LanguageTileState extends State<_LanguageTile> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.selected || hovered
                ? scheme.surfaceContainerHighest
                : scheme.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.language_rounded, color: scheme.onSurface),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      widget.native,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: .65),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.selected)
                Icon(Icons.check_circle, color: scheme.onSurface),
            ],
          ),
        ),
      ),
    );
  }
}
