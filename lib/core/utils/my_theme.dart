import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── PALETA DE CORES ──────────────────────────────────────────────────────
  // is
  static const Color primary = Color.fromRGBO(131, 0, 192, 1); // vibrant purple
  static const Color secondary = Color.fromRGBO(0, 255, 102, 1); // neon green
  static const Color surface = Color(0xFFF5F5F5); // light grey
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.black;
  static const Color onSurface = Colors.black;
  static const Color error = Colors.red;
  static const Color onError = Colors.white;

  // ─── COLOR SCHEME (tema claro) ─────────────────────────────────────────────
  static final ColorScheme colorScheme =
      ColorScheme.fromSeed(
        seedColor: primary,
        secondary: secondary,
        brightness: Brightness.light,
      ).copyWith(
        surface: surface,
        onSurface: onSurface,
        onSecondary: onSecondary,
        error: error,
        onError: onError,
      );

  // ─── COLOR SCHEME (tema escuro) ─────────────────────────────────────────────
  static final ColorScheme darkColorScheme = ColorScheme.fromSeed(
    seedColor: primary,
    secondary: secondary,
    brightness: Brightness.dark,
  ).copyWith(error: error, onError: onError);

  // ─── TEMA CLARO ─────────────────────────────────────────────────────────────
  static ThemeData light() {
    return ThemeData.from(
      colorScheme: colorScheme,
      textTheme: GoogleFonts.poppinsTextTheme(),
      useMaterial3: true,
    ).copyWith(
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: GoogleFonts.ubuntu(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          textStyle: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: secondary, width: 2),
        ),
        labelStyle: GoogleFonts.ubuntu(color: primary),
        hintStyle: GoogleFonts.ubuntu(
          color: onSurface.withAlpha((0.6 * 255).round()),
        ),
      ),
      iconTheme: IconThemeData(color: primary),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
      ),
    );
  }

  // ─── TEMA ESCURO ────────────────────────────────────────────────────────────
  static ThemeData dark() {
    return ThemeData.from(
      colorScheme: darkColorScheme,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      useMaterial3: true,
    ).copyWith(
      scaffoldBackgroundColor: darkColorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: darkColorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: darkColorScheme.onSurface),
        titleTextStyle: GoogleFonts.ubuntu(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkColorScheme.onSurface,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          textStyle: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondary,
          textStyle: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkColorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: secondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        labelStyle: GoogleFonts.ubuntu(color: secondary),
        hintStyle: GoogleFonts.ubuntu(
          color: darkColorScheme.onSurface.withAlpha((0.6 * 255).round()),
        ),
      ),
      iconTheme: IconThemeData(color: secondary),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondary,
        foregroundColor: onSecondary,
      ),
    );
  }
}
