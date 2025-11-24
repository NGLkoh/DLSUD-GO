import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService with ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _languageKey = 'language_code';

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString(_themeKey);
    final languageCode = prefs.getString(_languageKey);

    if (theme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (theme == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }

    if (languageCode != null) {
      _locale = Locale(languageCode);
    }

    notifyListeners();
  }

  Future<void> updateTheme(ThemeMode newThemeMode) async {
    if (newThemeMode == _themeMode) return;
    _themeMode = newThemeMode;

    final prefs = await SharedPreferences.getInstance();
    String themeStr;
    if (newThemeMode == ThemeMode.dark) {
      themeStr = 'dark';
    } else if (newThemeMode == ThemeMode.light) {
      themeStr = 'light';
    } else {
      themeStr = 'system';
    }
    await prefs.setString(_themeKey, themeStr);

    notifyListeners();
  }

  Future<void> updateLanguage(Locale newLocale) async {
    if (newLocale == _locale) return;
    _locale = newLocale;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, newLocale.languageCode);

    notifyListeners();
  }
}
