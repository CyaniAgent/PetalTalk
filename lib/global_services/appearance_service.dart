import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppearanceService {
  static const String _useDynamicColorKey = 'use_dynamic_color';
  static const String _accentColorKey = 'accent_color';
  static const String _fontSizeKey = 'font_size';
  static const String _layoutPreferenceKey = 'layout_preference';
  static const String _themeModeKey = 'theme_mode';
  static const String _compactLayoutKey = 'compact_layout';
  static const String _showAvatarsKey = 'show_avatars';

  // 加载主题模式
  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 使用更安全的方式获取存储值，避免直接类型转换错误
    String themeModeValue = 'system'; // 默认值
    
    try {
      // 尝试获取值，不指定类型
      final value = prefs.get(_themeModeKey);
      
      if (value is String) {
        // 如果是String类型，直接使用
        themeModeValue = value;
      } else if (value is int) {
        // 如果是int类型，转换为对应的String
        switch (value) {
          case 0:
            themeModeValue = 'light';
            break;
          case 1:
            themeModeValue = 'dark';
            break;
          case 2:
          default:
            themeModeValue = 'system';
            break;
        }
        // 更新存储为String类型，以便未来使用
        await prefs.setString(_themeModeKey, themeModeValue);
      } else if (value != null) {
        // 如果是其他类型，使用默认值并更新存储
        await prefs.setString(_themeModeKey, themeModeValue);
      }
    } catch (e) {
      // 捕获任何异常，使用默认值并更新存储
      await prefs.setString(_themeModeKey, themeModeValue);
    }
    
    switch (themeModeValue) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  // 保存主题模式
  Future<void> saveThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    String themeModeString;
    switch (themeMode) {
      case ThemeMode.light:
        themeModeString = 'light';
        break;
      case ThemeMode.dark:
        themeModeString = 'dark';
        break;
      case ThemeMode.system:
      default:
        themeModeString = 'system';
        break;
    }
    await prefs.setString(_themeModeKey, themeModeString);
  }

  // 安全获取bool值
  bool _safeGetBool(SharedPreferences prefs, String key, bool defaultValue) {
    try {
      final value = prefs.get(key);
      if (value is bool) {
        return value;
      } else if (value is int) {
        // 如果是int类型，转换为bool
        return value == 1;
      }
    } catch (e) {
      // 忽略异常，返回默认值
    }
    return defaultValue;
  }

  // 安全获取String值
  String _safeGetString(SharedPreferences prefs, String key, String defaultValue) {
    try {
      final value = prefs.get(key);
      if (value is String) {
        return value;
      }
    } catch (e) {
      // 忽略异常，返回默认值
    }
    return defaultValue;
  }

  // 安全获取double值
  double _safeGetDouble(SharedPreferences prefs, String key, double defaultValue) {
    try {
      final value = prefs.get(key);
      if (value is double) {
        return value;
      } else if (value is int) {
        // 如果是int类型，转换为double
        return value.toDouble();
      }
    } catch (e) {
      // 忽略异常，返回默认值
    }
    return defaultValue;
  }

  // 加载是否使用动态颜色
  Future<bool> loadUseDynamicColor() async {
    final prefs = await SharedPreferences.getInstance();
    return _safeGetBool(prefs, _useDynamicColorKey, true);
  }

  // 保存是否使用动态颜色
  Future<void> saveUseDynamicColor(bool useDynamicColor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useDynamicColorKey, useDynamicColor);
  }

  // 加载强调色
  Future<String> loadAccentColor() async {
    final prefs = await SharedPreferences.getInstance();
    return _safeGetString(prefs, _accentColorKey, 'blue');
  }

  // 保存强调色
  Future<void> saveAccentColor(String accentColor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accentColorKey, accentColor);
  }

  // 加载字体大小
  Future<double> loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return _safeGetDouble(prefs, _fontSizeKey, 16.0);
  }

  // 保存字体大小
  Future<void> saveFontSize(double fontSize) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, fontSize);
  }

  // 加载紧凑布局
  Future<bool> loadCompactLayout() async {
    final prefs = await SharedPreferences.getInstance();
    return _safeGetBool(prefs, _compactLayoutKey, false);
  }

  // 保存紧凑布局
  Future<void> saveCompactLayout(bool compactLayout) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_compactLayoutKey, compactLayout);
  }

  // 加载是否显示头像
  Future<bool> loadShowAvatars() async {
    final prefs = await SharedPreferences.getInstance();
    return _safeGetBool(prefs, _showAvatarsKey, true);
  }

  // 保存是否显示头像
  Future<void> saveShowAvatars(bool showAvatars) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showAvatarsKey, showAvatars);
  }

  // 加载布局偏好
  Future<String> loadLayoutPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return _safeGetString(prefs, _layoutPreferenceKey, 'default');
  }

  // 保存布局偏好
  Future<void> saveLayoutPreference(String layoutPreference) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_layoutPreferenceKey, layoutPreference);
  }
}
