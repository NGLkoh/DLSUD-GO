import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService with ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _languageKey = 'language_code';
  static const _textScaleKey = 'text_scale';
  static const _highContrastKey = 'high_contrast';

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');
  double _textScale = 1.0;
  bool _isHighContrast = false;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  double get textScale => _textScale;
  bool get isHighContrast => _isHighContrast;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Theme
    final theme = prefs.getString(_themeKey);
    if (theme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (theme == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }

    final languageCode = prefs.getString(_languageKey);
    if (languageCode != null) {
      _locale = Locale(languageCode);
    }

    _textScale = prefs.getDouble(_textScaleKey) ?? 1.0;
    _isHighContrast = prefs.getBool(_highContrastKey) ?? false;

    notifyListeners();
  }

  // --- UPDATE METHODS ---
  Future<void> updateTheme(ThemeMode newThemeMode) async {
    if (newThemeMode == _themeMode) return;
    _themeMode = newThemeMode;
    final prefs = await SharedPreferences.getInstance();
    String themeStr = newThemeMode == ThemeMode.dark ? 'dark' : (newThemeMode == ThemeMode.light ? 'light' : 'system');
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

  Future<void> updateTextScale(double newScale) async {
    if (newScale == _textScale) return;
    _textScale = newScale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textScaleKey, newScale);
    notifyListeners();
  }

  Future<void> updateHighContrast(bool isHighContrast) async {
    if (isHighContrast == _isHighContrast) return;
    _isHighContrast = isHighContrast;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, isHighContrast);
    notifyListeners();
  }
}