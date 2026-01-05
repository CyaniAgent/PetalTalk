import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class AppearanceService {
  static const String _themeModeKey = 'theme_mode';
  static const String _fontSizeKey = 'font_size';
  static const String _darkThemeKey = 'dark_theme';
  static const String _useDynamicColorKey = 'use_dynamic_color';
  static const String _accentColorKey = 'accent_color';
  static const String _compactLayoutKey = 'compact_layout';
  static const String _showAvatarsKey = 'show_avatars';

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

  // 使用动态色彩
  Future<void> saveUseDynamicColor(bool useDynamicColor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useDynamicColorKey, useDynamicColor);
  }

  Future<bool> loadUseDynamicColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useDynamicColorKey) ?? true;
  }

  // 强调色
  Future<void> saveAccentColor(String accentColor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accentColorKey, accentColor);
  }

  Future<String> loadAccentColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accentColorKey) ?? 'blue';
  }

  // 紧凑布局
  Future<void> saveCompactLayout(bool compactLayout) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_compactLayoutKey, compactLayout);
  }

  Future<bool> loadCompactLayout() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_compactLayoutKey) ?? false;
  }

  // 显示头像
  Future<void> saveShowAvatars(bool showAvatars) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showAvatarsKey, showAvatars);
  }

  Future<bool> loadShowAvatars() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showAvatarsKey) ?? true;
  }
}
