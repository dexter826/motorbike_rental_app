import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: Color.fromARGB(255, 0, 85, 154),
      scaffoldBackgroundColor: Color(0xFFF5F9FF),
      cardColor: Colors.white,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color.fromARGB(255, 0, 85, 154),
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Color.fromARGB(255, 0, 85, 154),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color.fromARGB(255, 0, 85, 154),
          foregroundColor: Colors.white,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color.fromARGB(255, 0, 85, 154)),
        bodyMedium: TextStyle(color: Color.fromARGB(255, 0, 85, 154)),
        titleLarge: TextStyle(color: Color.fromARGB(255, 0, 85, 154)),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: Color.fromARGB(255, 0, 85, 154)),
        hintStyle: TextStyle(color: Color(0xFF1976D2)),
        fillColor: Color(0xFFECEFF1),
        filled: true,
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color.fromARGB(255, 0, 85, 154)),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Color.fromARGB(255, 0, 85, 154),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color.fromARGB(255, 0, 85, 154),
      ),
      dividerColor: Colors.grey[300]!,
      colorScheme: ColorScheme.light(
        primary: Color.fromARGB(255, 0, 85, 154),
        error: Colors.red,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: Color(0xFF1565C0),
      scaffoldBackgroundColor: Color(0xFF0A1929),
      cardColor: Color(0xFF132F4C),
      cardTheme: CardThemeData(
        color: Color(0xFF132F4C),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A1929),
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF1976D2),
          foregroundColor: Colors.white,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFE3F2FD)),
        bodyMedium: TextStyle(color: Color(0xFFE3F2FD)),
        titleLarge: TextStyle(color: Color(0xFFE3F2FD)),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: Color(0xFF90CAF9)),
        hintStyle: TextStyle(color: Color(0xFF64B5F6)),
        fillColor: Color(0xFF263238),
        filled: true,
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF90CAF9)),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Color(0xFF90CAF9),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF90CAF9),
      ),
      dividerColor: Colors.grey[700]!,
      colorScheme: ColorScheme.dark(
        primary: Color(0xFF1976D2),
        error: Colors.redAccent,
      ),
    );
  }
}
