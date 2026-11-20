// certifications#52: the design system. Nova colour tokens drive the Material
// widgets, Ubuntu Sans is the type face with a Thai fallback, surfaces have
// no blur or glass, and the gallery shows the shared logo with the title.
import 'dart:io';

import 'package:certifications/core/utils/my_theme.dart';
import 'package:certifications/presentation/widgets/design_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadFonts() async {
  const base = 'lib/presentation/assets/fonts';
  for (final (family, files) in const [
    ('Ubuntu Sans', ['UbuntuSans-Variable.ttf']),
    (
      'IBM Plex Sans Thai',
      [
        'IBMPlexSansThai-Regular.ttf',
        'IBMPlexSansThai-SemiBold.ttf',
        'IBMPlexSansThai-Bold.ttf',
      ],
    ),
  ]) {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File('$base/$f').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
  // The Material icon font, so icons show in the review images instead of
  // empty boxes (manager request 19d0d0a9).
  final root = File(Platform.resolvedExecutable).parent.parent.parent.parent
      .parent.parent.path;
  final icons = File(
    '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ).readAsBytesSync();
  await (FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(icons))))
      .load();
}

void main() {
  setUpAll(loadFonts);

  for (final (name, theme, active, surface) in [
    ('light', AppTheme.light(), NovaColors.active, NovaColors.surface1),
    ('dark', AppTheme.dark(), NovaColors.activeDark, NovaColors.surface1Dark),
  ]) {
    test('$name theme uses the Nova tokens and Ubuntu Sans', () {
      expect(theme.colorScheme.primary, active);
      expect(theme.colorScheme.surface, surface);
      for (final style in [
        theme.textTheme.bodyLarge!,
        theme.textTheme.displaySmall!,
        theme.textTheme.labelLarge!,
      ]) {
        expect(style.fontFamily, 'Ubuntu Sans');
        expect(style.fontFamilyFallback, ['IBM Plex Sans Thai']);
      }
      // Plain surfaces: no tint over cards, dialogs or the app bar.
      expect(theme.cardTheme.surfaceTintColor, Colors.transparent);
      expect(theme.appBarTheme.surfaceTintColor, Colors.transparent);
    });
  }

  test('the fonts and their licences are bundled', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('family: Ubuntu Sans'));
    expect(pubspec, contains('family: IBM Plex Sans Thai'));
    expect(pubspec, isNot(contains('google_fonts')));
    // The Nova package cannot build on Linux (see NovaColors).
    expect(pubspec, isNot(contains('visa_nova_flutter')));
    for (final f in [
      'UbuntuSans-Variable.ttf',
      'UbuntuSans-LICENCE.txt',
      'IBMPlexSansThai-Regular.ttf',
      'IBMPlexSansThai-LICENSE.txt',
    ]) {
      expect(File('lib/presentation/assets/fonts/$f').existsSync(), isTrue);
    }
  });

  final review = Platform.environment['CERTIFICATIONS_REVIEW_DIR'];
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'the gallery shows the logo, title and components, ${mode.name}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1280, 2000);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(DesignGallery(initialMode: mode));
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull);
        // The shared Asodya logo with the title Certifications only.
        final logo = find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName == logoAsset,
        );
        expect(logo, findsOneWidget);
        expect(find.text('Asodya Certifications'), findsNothing);
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('Certifications'),
          ),
          findsOneWidget,
        );
        for (final type in [FilledButton, TextField, Switch, Checkbox, Chip]) {
          expect(find.byType(type), findsWidgets);
        }
        expect(find.byType(BackdropFilter), findsNothing);
        if (review != null) {
          await tester.runAsync(() async {
            for (final e in find.byType(Image).evaluate()) {
              await precacheImage((e.widget as Image).image, e);
            }
          });
          await tester.pump(const Duration(milliseconds: 200));
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('$review/design_gallery_${mode.name}.png'),
          );
        }
      },
    );
  }
}
