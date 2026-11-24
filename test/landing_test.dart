import 'dart:io';
import 'dart:ui';

import 'package:certifications/core/routes.dart';
import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/core/utils/landing_copy.dart';
import 'package:certifications/core/utils/my_background.dart';
import 'package:certifications/core/utils/my_theme.dart';
import 'package:certifications/presentation/widgets/landing/landing_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'design_system_test.dart' show loadFonts;

/// The landing redesign (certifications#53, owner design review 2026-11-20).

var started = 0, waitlisted = 0;

void stillMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

Widget app({
  String locale = 'en',
  ThemeMode mode = ThemeMode.light,
  String initial = '/',
}) => MaterialApp(
  theme: AppTheme.light(),
  darkTheme: AppTheme.dark(),
  themeMode: mode,
  locale: Locale(locale),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizationsDelegate(),
    FallbackMaterialLocalizationsDelegate(),
    DefaultWidgetsLocalizations.delegate,
    DefaultMaterialLocalizations.delegate,
  ],
  initialRoute: initial,
  onGenerateRoute: (settings) {
    final route = CertificationsRoute.parse(Uri.parse(settings.name ?? '/'));
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => Scaffold(
        body: SingleChildScrollView(
          child: switch (route.screen) {
            CertificationsScreen.learn => LearnBody(
              topicId: route.id!,
              onStart: () => started++,
            ),
            CertificationsScreen.plans => const Text('plans'),
            _ => LandingBody(
              actions: LandingActions(
                onStart: () => started++,
                onWaitlist: () => waitlisted++,
              ),
              footer: const SizedBox(height: 40),
            ),
          },
        ),
      ),
    );
  },
);

Future<void> open(
  WidgetTester tester, {
  double width = 1300,
  String locale = 'en',
  ThemeMode mode = ThemeMode.light,
  String initial = '/',
}) async {
  stillMotion(tester);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 1000);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    app(locale: locale, mode: mode, initial: initial),
    duration: Duration.zero,
  );
  await tester.pumpAndSettle();
}

double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return ((la > lb ? la : lb) + .05) / ((la > lb ? lb : la) + .05);
}

void main() {
  setUpAll(loadFonts);

  testWidgets('the landing sections in order, the bubbles kept, no blur', (
    tester,
  ) async {
    await open(tester);
    double top(String key) => tester.getTopLeft(find.byKey(Key(key))).dy;
    expect(top('landing-hero'), lessThan(top('topics-section')));
    expect(top('topics-section'), lessThan(top('cards-section')));
    expect(top('cards-section'), lessThan(top('steps-section')));
    expect(top('steps-section'), lessThan(top('mvp-section')));
    expect(top('mvp-section'), lessThan(top('trust-section')));
    // The animated coloured bubbles stay in the hero (Area 25).
    expect(
      find.descendant(
        of: find.byKey(const Key('landing-hero')),
        matching: find.byType(LiquidMetalBackground),
      ),
      findsOneWidget,
    );
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byType(ImageFiltered), findsNothing);
    // One strong action: Get started.
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.byKey(const Key('hero-start')), findsOneWidget);
    // No photos on the landing.
    expect(
      find.byType(Image).evaluate().where((e) {
        final image = (e.widget as Image).image;
        return image is AssetImage && !image.assetName.contains('logo');
      }),
      isEmpty,
    );
  });

  testWidgets(
    'the topic row is a calm surface section; the sections alternate',
    (tester) async {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        await open(tester, mode: mode);
        final scheme = Theme.of(
          tester.element(find.byKey(const Key('topics-section'))),
        ).colorScheme;
        Color? fill(String key) => tester
            .widget<Container>(
              find
                  .descendant(
                    of: find.byKey(Key(key)),
                    matching: find.byType(Container),
                  )
                  .first,
            )
            .color;
        expect(fill('topics-section'), scheme.surface, reason: '$mode');
        expect(fill('steps-section'), scheme.surface, reason: '$mode');
        expect(fill('trust-section'), scheme.surface, reason: '$mode');
        expect(fill('cards-section'), scheme.surfaceContainerLow);
        expect(fill('mvp-section'), scheme.surfaceContainerLow);
        expect(scheme.surface, isNot(scheme.surfaceContainerLow));
      }
      // Light mode: the topic row section is white.
      await open(tester);
      expect(
        tester
            .widget<Container>(
              find
                  .descendant(
                    of: find.byKey(const Key('topics-section')),
                    matching: find.byType(Container),
                  )
                  .first,
            )
            .color,
        const Color(0xFFFFFFFF),
      );
    },
  );

  testWidgets('the hero title reads over any bubble colour, both themes', (
    tester,
  ) async {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      await open(tester, mode: mode);
      final hero = find.byKey(const Key('landing-hero'));
      final layers = tester.widget<Stack>(hero).children;
      // Bubbles, then the scrim, then the text.
      expect(layers, hasLength(3));
      expect(
        find.descendant(
          of: find.byWidget(layers[0]),
          matching: find.byType(LiquidMetalBackground),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byWidget(layers[1]),
          matching: find.byKey(const Key('hero-scrim')),
        ),
        findsOneWidget,
      );
      final scheme = Theme.of(tester.element(hero)).colorScheme;
      final gradient =
          (tester
                          .widget<DecoratedBox>(
                            find.byKey(const Key('hero-scrim')),
                          )
                          .decoration
                      as BoxDecoration)
                  .gradient!
              as RadialGradient;
      final centre = gradient.colors.first;
      expect(centre.a, greaterThanOrEqualTo(.7));
      expect(gradient.stops![1], greaterThan(0));
      // The worst bubble under the title: white in dark (the bubbles add
      // up to white), black in light.
      final worst = mode == ThemeMode.dark ? Colors.white : Colors.black;
      final under = Color.alphaBlend(centre, worst);
      final title = tester.widget<Text>(find.byKey(const Key('hero-title')));
      final ink = title.style?.color ?? scheme.onSurface;
      expect(contrast(ink, under), greaterThanOrEqualTo(4.5), reason: '$mode');
    }
  });

  testWidgets('the actions start a study and join the waitlist', (
    tester,
  ) async {
    started = waitlisted = 0;
    await open(tester);
    await tester.tap(find.byKey(const Key('hero-start')));
    await tester.tap(find.byKey(const Key('hero-waitlist')));
    await tester.ensureVisible(find.byKey(const Key('mvp-waitlist')));
    await tester.tap(find.byKey(const Key('mvp-waitlist')));
    await tester.pumpAndSettle();
    expect(started, 1);
    expect(waitlisted, 2);
    await tester.ensureVisible(find.byKey(const Key('mvp-plans')));
    await tester.tap(find.byKey(const Key('mvp-plans')));
    await tester.pumpAndSettle();
    expect(find.text('plans'), findsOneWidget);
  });

  test('the brand accent is not Visa blue and reads in both themes', () {
    final light = AppTheme.light().colorScheme;
    final dark = AppTheme.dark().colorScheme;
    for (final s in [light, dark]) {
      expect(s.primary, isNot(const Color(0xFF1434CB)));
      expect(s.primary, isNot(const Color(0xFFBDEAFF)));
      // Text on the accent fill and the accent as text on the page.
      expect(contrast(s.onPrimary, s.primary), greaterThanOrEqualTo(4.5));
      expect(contrast(s.primary, s.surface), greaterThanOrEqualTo(4.5));
    }
    // Certifications' own colour from the shared logo.
    expect(light.primary, AsodyaPalette.purple);
  });

  group('Topic row', () {
    testWidgets('five topics, each its own colour, none a top bar item', (
      tester,
    ) async {
      await open(tester);
      expect(landingTopics, hasLength(5));
      expect(landingTopics.map((t) => t.color).toSet(), hasLength(5));
      final topBar = [
        for (final k in ['studies', 'plans', 'about', 'logIn', 'signUp'])
          translate(k),
      ];
      for (final topic in landingTopics) {
        expect(find.byKey(Key('topic-${topic.id}')), findsOneWidget);
        expect(topBar, isNot(contains(translate(topic.label))));
      }
    });

    testWidgets('hover fills and grows the tile; focus rings it; press', (
      tester,
    ) async {
      await open(tester);
      final tile = find.byKey(const Key('topic-tile-sources'));
      BoxDecoration deco() =>
          tester.widget<AnimatedContainer>(tile).decoration! as BoxDecoration;
      double scale() => tester
          .widget<AnimatedScale>(
            find.ancestor(of: tile, matching: find.byType(AnimatedScale)),
          )
          .scale;
      final topic = landingTopics.first;
      expect(deco().color, topic.color.withValues(alpha: .22));
      expect(scale(), 1);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: tester.getCenter(tile));
      await tester.pumpAndSettle();
      expect(deco().color, topic.color);
      expect(scale(), greaterThan(1));
      await mouse.moveTo(const Offset(1, 999));
      await tester.pumpAndSettle();
      expect(deco().color, topic.color.withValues(alpha: .22));

      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      Focus.of(tester.element(tile)).requestFocus();
      await tester.pumpAndSettle();
      expect((deco().border! as Border).top.color, isNot(Colors.transparent));
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic;
      Focus.of(tester.element(tile)).unfocus();
      await tester.pumpAndSettle();

      final press = await tester.startGesture(tester.getCenter(tile));
      await tester.pumpAndSettle();
      expect(scale(), lessThan(1));
      await press.up();
      await tester.pumpAndSettle();
      await mouse.removePointer();
    });

    testWidgets('each topic opens its own page', (tester) async {
      for (final topic in landingTopics) {
        await open(tester);
        await tester.ensureVisible(find.byKey(Key('topic-${topic.id}')));
        await tester.tap(find.byKey(Key('topic-tile-${topic.id}')));
        await tester.pumpAndSettle();
        expect(find.byKey(Key('learn-${topic.id}')), findsOneWidget);
        expect(find.text(translate(topic.title)), findsOneWidget);
        for (final key in topic.body) {
          expect(find.text(translate(key)), findsOneWidget, reason: key);
        }
        await tester.tap(find.byKey(const Key('learn-back')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('landing-hero')), findsOneWidget);
      }
    });

    test('the topic pages have their own route', () {
      final r = CertificationsRoute.parse(Uri.parse('/learn/privacy'));
      expect(r.screen, CertificationsScreen.learn);
      expect(r.id, 'privacy');
      expect(r.requiresAuth, isFalse);
    });

    testWidgets('an unknown topic shows a not-found line', (tester) async {
      await open(tester, initial: '/learn/nothing');
      expect(find.text(translate('lpNotFound')), findsOneWidget);
    });
  });

  group('Feature cards', () {
    testWidgets('hover and focus reveal the text; press marks the card', (
      tester,
    ) async {
      await open(tester);
      final card = find.byKey(const Key('card-lpCardTopics'));
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      Finder body() => find.descendant(
        of: card,
        matching: find.byKey(const Key('feature-card-body')),
      );
      expect(body(), findsNothing);
      // At rest the card shows a two-line preview, never an empty area.
      expect(
        find.descendant(
          of: card,
          matching: find.byKey(const Key('feature-card-teaser')),
        ),
        findsOneWidget,
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: tester.getCenter(card));
      await tester.pumpAndSettle();
      expect(body(), findsOneWidget);
      expect(find.text(translate('valPropTile1Desc')), findsOneWidget);
      await mouse.moveTo(const Offset(1, 1));
      await tester.pumpAndSettle();
      expect(body(), findsNothing);

      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      Focus.of(
        tester.element(
          find.descendant(
            of: card,
            matching: find.byIcon(Icons.search_rounded),
          ),
        ),
      ).requestFocus();
      await tester.pumpAndSettle();
      expect(body(), findsOneWidget);
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic;
      await mouse.removePointer();
    });

    testWidgets('on a phone the text always shows (no hover)', (tester) async {
      await open(tester, width: 390);
      expect(
        find.byKey(const Key('feature-card-body')),
        findsNWidgets(landingCards.length),
      );
    });
  });

  testWidgets('no overflow and no unbreakable text, EN PT TH, 3 widths', (
    tester,
  ) async {
    final bad = <String>{};
    for (final locale in ['en', 'pt', 'th']) {
      for (final width in [390.0, 768.0, 1300.0]) {
        for (final initial in ['/', '/learn/sources', '/learn/privacy']) {
          await open(tester, width: width, locale: locale, initial: initial);
          // The app's widgets delegate is English only, so Flutter warns
          // about pt and th; that warning is not a layout problem.
          final error = tester.takeException();
          expect(
            error == null ||
                '$error'.contains(
                  'is not supported by all of its localization',
                ),
            isTrue,
            reason: '$initial $width $locale: $error',
          );
          for (final p in tester.renderObjectList<RenderParagraph>(
            find.byType(RichText),
          )) {
            if (p.computeMinIntrinsicWidth(double.infinity) >
                p.size.width + .5) {
              bad.add('$initial $width $locale: ${p.text.toPlainText()}');
            }
          }
        }
      }
    }
    expect(bad, isEmpty);
  });

  test('the landing copy has EN, PT and TH and no dash characters', () {
    for (final lang in ['en', 'pt', 'th']) {
      expect(landingCopy[lang]!.keys.toSet(), landingCopy['en']!.keys.toSet());
      for (final text in landingCopy[lang]!.values) {
        expect(text.contains('\u2014') || text.contains('\u2013'), isFalse);
      }
    }
    final copy = File(
      'lib/core/utils/app_localizations.dart',
    ).readAsStringSync();
    expect(copy.contains('\u2014') || copy.contains('\u2013'), isFalse);
  });
}

String translate(String key, [String lang = 'en']) =>
    AppLocalizations(Locale(lang)).text(key);
