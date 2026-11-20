import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The colour tokens of the Visa Product Design System (Nova), default and
/// dark themes, as published in visa_nova_flutter 8.3.1 (Apache-2.0). The
/// package itself cannot be used: every release lists font files whose
/// names differ in case from the shipped files, so the asset bundle fails
/// on case-sensitive file systems (certifications#52).
abstract final class NovaColors {
  // Brand accent in the Nova active slots (certifications#53, owner design
  // review 2026-11-20): Certifications' own colour from the shared logo and
  // the bubbles, not Visa blue. Light: purple fill with white text (5.3:1).
  // Dark: a light purple fill with dark text, readable as text on the dark
  // surfaces.
  static const active = Color(0xFFA201FF);
  static const activeHover = Color(0xFF8C00DD);
  static const activePressed = Color(0xFF7400B8);
  static const onActive = Color(0xFFFFFFFF);
  static const surface1 = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF5F5F5);
  static const surface3 = Color(0xFFF0F0F0);
  static const text = Color(0xFF000000);
  static const textSubtle = Color(0xFF4A4A4A);
  static const border = Color(0x1A000000);
  static const disabled = Color(0x33000000);

  static const activeDark = Color(0xFFD18BFF);
  static const activeHoverDark = Color(0xFFDDA6FF);
  static const activePressedDark = Color(0xFFC06BFF);
  static const onActiveDark = Color(0xFF1A0026);
  static const surface1Dark = Color(0xFF0A0A0A);
  static const surface2Dark = Color(0xFF1A1A1A);
  static const surface3Dark = Color(0xFF2E2E2E);
  static const textDark = Color(0xFFFFFFFF);
  static const textSubtleDark = Color(0xFFD9D9D9);
  static const borderDark = Color(0x1AFFFFFF);
  static const disabledDark = Color(0x33FFFFFF);

  static const positiveSurface = Color(0xFFD6F2C4);
  static const positiveText = Color(0xFF2D6C4B);
  static const warningSurface = Color(0xFFFFEF99);
  static const warningText = Color(0xFF9B6603);
  static const negativeSurface = Color(0xFFFFD6E9);
  static const negativeGraphics = Color(0xFFD65151);
  static const negativeText = Color(0xFFB3202A);
  static const infoSurface = Color(0xFFC7EDFF);
  static const infoText = Color(0xFF005E8A);
}

/// The design system of Certifications (certifications#52): the Visa Product
/// Design System (Nova) colours and component shapes on Material widgets,
/// Ubuntu Sans with IBM Plex Sans Thai for Thai, and Apple-like plain
/// surfaces without blur or glass. The colourful landing animation stays
/// isolated in `my_background.dart`.
abstract final class AppTheme {
  static const fontFamily = 'Ubuntu Sans';
  static const fontFallback = ['IBM Plex Sans Thai'];

  /// Corner radii: small for inputs, large for cards and dialogs.
  static const radiusSmall = 8.0;
  static const radiusLarge = 16.0;

  static const _light = ColorScheme.light(
    primary: NovaColors.active,
    onPrimary: NovaColors.onActive,
    secondary: NovaColors.textSubtle,
    onSecondary: NovaColors.surface1,
    surface: NovaColors.surface1,
    onSurface: NovaColors.text,
    onSurfaceVariant: NovaColors.textSubtle,
    surfaceContainerLowest: NovaColors.surface1,
    surfaceContainerLow: NovaColors.surface2,
    surfaceContainer: NovaColors.surface2,
    surfaceContainerHigh: NovaColors.surface3,
    surfaceContainerHighest: NovaColors.surface3,
    outline: NovaColors.border,
    outlineVariant: NovaColors.disabled,
    error: NovaColors.negativeText,
    onError: NovaColors.surface1,
  );

  static const _dark = ColorScheme.dark(
    primary: NovaColors.activeDark,
    onPrimary: NovaColors.onActiveDark,
    secondary: NovaColors.textSubtleDark,
    onSecondary: NovaColors.surface1Dark,
    surface: NovaColors.surface1Dark,
    onSurface: NovaColors.textDark,
    onSurfaceVariant: NovaColors.textSubtleDark,
    surfaceContainerLowest: NovaColors.surface1Dark,
    surfaceContainerLow: NovaColors.surface2Dark,
    surfaceContainer: NovaColors.surface2Dark,
    surfaceContainerHigh: NovaColors.surface3Dark,
    surfaceContainerHighest: NovaColors.surface3Dark,
    outline: NovaColors.borderDark,
    outlineVariant: NovaColors.disabledDark,
    error: NovaColors.negativeGraphics,
    onError: NovaColors.surface1Dark,
  );

  static ThemeData light() => _build(_light, scaffoldBg: NovaColors.surface2);

  static ThemeData dark() => _build(_dark, scaffoldBg: NovaColors.surface1Dark);

  static ThemeData _build(ColorScheme scheme, {required Color scaffoldBg}) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,
    );
    // Button labels keep the type face: a bare TextStyle would replace it.
    final label = base.textTheme.labelLarge!.copyWith(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,
      fontWeight: FontWeight.w600,
    );
    return base.copyWith(
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: base.textTheme.apply(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFallback,
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: label,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: const StadiumBorder(),
          textStyle: label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary),
          shape: const StadiumBorder(),
          textStyle: label,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(48, 48),
          shape: const StadiumBorder(),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
    );
  }
}

bool _licensesAdded = false;

/// Adds the font licences to the licence page of the application.
void registerDesignLicenses() {
  if (_licensesAdded) return;
  _licensesAdded = true;
  const base = 'lib/presentation/assets/fonts';
  LicenseRegistry.addLicense(() async* {
    for (final (package, file) in const [
      ('Ubuntu Sans', '$base/UbuntuSans-LICENCE.txt'),
      ('IBM Plex Sans Thai', '$base/IBMPlexSansThai-LICENSE.txt'),
    ]) {
      yield LicenseEntryWithLineBreaks([
        package,
      ], await rootBundle.loadString(file));
    }
  });
}
