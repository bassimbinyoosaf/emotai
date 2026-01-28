import 'package:flutter/material.dart';

/// Global theme provider for the app.
/// Use `context.read<ThemeNotifier>().toggleTheme()` from any page to switch.
class ThemeNotifier extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.dark;

  void setDark() {
    themeMode = ThemeMode.dark;
    notifyListeners();
  }

  void setLight() {
    themeMode = ThemeMode.light;
    notifyListeners();
  }

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}

/// Centralized theme definitions used by MaterialApp in main.dart
class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = const ColorScheme.light(
      primary: Color(0xFF0A7EA4),
      secondary: Color(0xFF3DA5C8),
      surface: Colors.white,
      background: Color(0xFFF7F9FC),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF2C3E50),
      onBackground: Color(0xFF2C3E50),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Color(0xFF2C3E50),
        centerTitle: true,
      ),
      shadowColor: const Color(0xFF000000),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: const TextTheme(
        // Used by small headings
        labelMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF687076),
        ),
        // Used by result titles
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF11181C),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = const ColorScheme.dark(
      primary: Color(0xFF8B7FFF),
      secondary: Color(0xFFB4A7FF),
      surface: Color(0xFF121417),
      background: Color(0xFF0B0D0F),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      shadowColor: const Color(0xFF000000),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: const TextTheme(
        labelMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white70,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}