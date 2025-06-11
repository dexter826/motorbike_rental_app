import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const THEME_KEY = "theme_key";
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;
  SharedPreferences? _prefs;

  ThemeProvider() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _isDarkMode = _prefs?.getBool(THEME_KEY) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing SharedPreferences: $e');
    }
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveThemeToPrefs();
    notifyListeners();
  }

  Future<void> _saveThemeToPrefs() async {
    try {
      if (_prefs != null) {
        await _prefs!.setBool(THEME_KEY, _isDarkMode);
      }
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }
}
