
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';

  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoaded = false;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  bool get isLoaded => _isLoaded;
  Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedTheme = prefs.getString(_themeKey);

      _themeMode = savedTheme == 'dark'
          ? ThemeMode.dark
          : ThemeMode.light;
    } catch (e) {
      debugPrint('Error al cargar el tema: $e');
      _themeMode = ThemeMode.light;
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }
  Future<void> toggleTheme() async {
    await setThemeMode(
      isDarkMode ? ThemeMode.light : ThemeMode.dark,
    );
  }
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        _themeKey,
        mode == ThemeMode.dark ? 'dark' : 'light',
      );
    } catch (e) {
      debugPrint('Error al guardar el tema: $e');
    }
  }
}
