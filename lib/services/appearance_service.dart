import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class AppearanceService {
  static const String _themeModeKey = 'theme_mode';
  static const String _fontSizeKey = 'font_size';
  static const String _darkThemeKey = 'dark_theme';

  // 主题模式
  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_themeModeKey) ?? ThemeMode.system.index;
    return ThemeMode.values[index];
  }

  // 字体大小
  Future<void> saveFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, size);
  }

  Future<double> loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_fontSizeKey) ?? 16.0;
  }

  // 深色主题偏好
  Future<void> saveDarkTheme(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_darkThemeKey, themeName);
  }

  Future<String> loadDarkTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_darkThemeKey) ?? '默认';
  }
}
