import 'package:flutter/material.dart';

class KidsColors {
  static const seed = Color(0xFF3B82F6);
  static const success = Color(0xFF22C55E);
  static const warn = Color(0xFFF97316);
  static const surface = Color(0xFFFFFBF2);
  static const ink = Color(0xFF1F2937);
}

ThemeData buildKidsTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: KidsColors.seed,
    surface: KidsColors.surface,
    brightness: Brightness.light,
  );

  // Kids UX: min 18 sp dla tekstu ciała, wyraźne nagłówki. Nie skalujemy
  // globalnie (TextTheme.apply wywraca się na stylach bez jawnego fontSize);
  // zamiast tego definiujemy jawnie kluczowe style.
  const textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.w800,
      color: KidsColors.ink,
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: KidsColors.ink,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: KidsColors.ink,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: KidsColors.ink,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: KidsColors.ink,
    ),
    titleMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: KidsColors.ink,
    ),
    bodyLarge: TextStyle(fontSize: 20, color: KidsColors.ink),
    bodyMedium: TextStyle(fontSize: 18, color: KidsColors.ink),
    labelLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: KidsColors.ink,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: KidsColors.surface,
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: KidsColors.surface,
      foregroundColor: KidsColors.ink,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: KidsColors.ink,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: KidsColors.seed,
        foregroundColor: Colors.white,
        disabledBackgroundColor: KidsColors.seed.withValues(alpha: 0.35),
        disabledForegroundColor: Colors.white,
        minimumSize: const Size(64, 56),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 2,
    ),
  );
}
