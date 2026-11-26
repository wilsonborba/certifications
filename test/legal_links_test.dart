import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/core/utils/app_preferences.dart';
import 'package:certifications/presentation/components/preferences/app_preferences_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');

Widget _localizedApp(Locale locale, AppPreferences preferences, Widget home) =>
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        FallbackCupertinoLocalizationsDelegate(),
        FallbackMaterialLocalizationsDelegate(),
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      builder: (context, child) => AppPreferencesScope(
        preferences: preferences,
        child: child ?? const SizedBox.shrink(),
      ),
      home: home,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final launches = <String>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_urlLauncherChannel, (call) async {
        if (call.method == 'launch') {
          final arguments = call.arguments as Map<Object?, Object?>;
          launches.add(arguments['url'] as String);
          return true;
        }
        return false;
      });

  tearDown(() => launches.clear());
  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_urlLauncherChannel, null);
  });

  for (final testCase in [
    (
      locale: const Locale('en'),
      terms: 'Terms of Service',
      privacy: 'Privacy Policy',
    ),
    (
      locale: const Locale('pt'),
      terms: 'Termos de Serviço',
      privacy: 'Política de Privacidade',
    ),
    (
      locale: const Locale('th'),
      terms: 'ข้อกำหนดการให้บริการ',
      privacy: 'นโยบายความเป็นส่วนตัว',
    ),
  ]) {
    testWidgets('legal links are localized in ${testCase.locale}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final preferences = AppPreferences();
      addTearDown(preferences.dispose);
      await tester.pumpWidget(
        _localizedApp(
          testCase.locale,
          preferences,
          const Scaffold(body: AppPreferencesPanel()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(testCase.terms), findsOneWidget);
      expect(find.text(testCase.privacy), findsOneWidget);
      expect(tester.takeException(), isNull);

      if (testCase.locale.languageCode == 'en') {
        await tester.tap(find.text(testCase.terms));
        await tester.pumpAndSettle();
        await tester.tap(find.text(testCase.privacy));
        await tester.pumpAndSettle();
        expect(launches, [
          'https://asodya.com/terms-of-service',
          'https://asodya.com/privacy-policy',
        ]);
      }
    });
  }

  testWidgets('desktop preferences sheet exposes both legal links', (
    tester,
  ) async {
    final preferences = AppPreferences();
    addTearDown(preferences.dispose);
    await tester.pumpWidget(
      _localizedApp(
        const Locale('en'),
        preferences,
        const AppPreferencesButton(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(IconButton), findsOneWidget);
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
  });
}
