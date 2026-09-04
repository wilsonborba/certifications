import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The only colour authority for product UI. The colourful landing animation
/// remains intentionally isolated in `my_background.dart`.
abstract final class AppTheme {
  static const _light = ColorScheme.light(
    primary: Color(0xFF111111),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF3D3D3D),
    onSecondary: Color(0xFFFFFFFF),
    surface: Color(0xFFF7F7F7),          // cards / elevated surfaces: near-white
    onSurface: Color(0xFF0D0D0D),        // near-black for strong text contrast
    surfaceContainerHighest: Color(0xFFDEDEDE), // input fills, chips: clearly distinct
    outline: Color(0xFF7A7A7A),          // borders: darker so they show on gray bg
    error: Color(0xFF8B1E1E),
    onError: Color(0xFFFFFFFF),
  );
  static const _dark = ColorScheme.dark(
    primary: Color(0xFFF5F5F5),
    onPrimary: Color(0xFF111111),
    secondary: Color(0xFFC8C8C8),
    onSecondary: Color(0xFF171717),
    surface: Color(0xFF111111),
    onSurface: Color(0xFFF5F5F5),
    surfaceContainerHighest: Color(0xFF242424),
    outline: Color(0xFF777777),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
  );
  static ThemeData light() => _build(_light, scaffoldBg: const Color(0xFFE2E2E2));
  static ThemeData dark() => _build(_dark, scaffoldBg: _dark.surface);
  static ThemeData _build(ColorScheme scheme, {required Color scaffoldBg}) => ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scaffoldBg,
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: scheme.outline.withValues(alpha: .42)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 50),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 50),
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
  );
}
