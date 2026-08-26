import 'package:certifications/core/settings.dart';
import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/core/utils/app_preferences.dart';
import 'package:certifications/core/utils/my_background.dart';
import 'package:certifications/core/utils/my_nagivation.dart';
import 'package:flutter/material.dart';

class StudyHome extends StatelessWidget {
  const StudyHome({super.key, required this.preferences});
  final AppPreferences preferences;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        const Positioned.fill(child: LiquidMetalBackground()),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: _PreferencesShelf(preferences: preferences),
                    ),
                    const Spacer(),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: LayoutBuilder(
                          builder: (context, constraints) => Flex(
                            direction: constraints.maxWidth < 700
                                ? Axis.vertical
                                : Axis.horizontal,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Expanded(child: _HeroCopy()),
                              SizedBox(width: 40, height: 32),
                              Expanded(child: _StartCard()),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.tr('appName'),
          style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 1.4),
        ),
        const SizedBox(height: 18),
        Text(
          context.tr('welcomeTitle'),
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          context.tr('welcomeBody'),
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _StartCard extends StatelessWidget {
  const _StartCard();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        context.tr('openStudies'),
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      Text(
        context.tr('welcomeBody'),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: 28),
      ElevatedButton(
        onPressed: () => redirectToUrl(
          app_settings.ASODYA_AUTH_LOGIN_URL,
          removeSlash: true,
        ),
        child: Text(context.tr('signIn')),
      ),
    ],
  );
}

class _PreferencesShelf extends StatelessWidget {
  const _PreferencesShelf({required this.preferences});
  final AppPreferences preferences;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            context.tr('language'),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: preferences.locale?.languageCode,
              hint: Text(context.tr('system')),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(context.tr('system')),
                ),
                ...AppLocalizations.supportedLocales.map(
                  (locale) => DropdownMenuItem(
                    value: locale.languageCode,
                    child: Text(locale.languageCode.toUpperCase()),
                  ),
                ),
              ],
              onChanged: (value) =>
                  preferences.setLocale(value == null ? null : Locale(value)),
            ),
          ),
          const VerticalDivider(),
          Text(
            context.tr('theme'),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          SegmentedButton<ThemeMode>(
            selected: {preferences.themeMode},
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(context.tr('system')),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(context.tr('light')),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(context.tr('dark')),
              ),
            ],
            onSelectionChanged: (value) => preferences.setTheme(value.first),
          ),
        ],
      ),
    ),
  );
}
