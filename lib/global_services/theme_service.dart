import 'package:flutter/material.dart';

import './appearance_service.dart';

class ThemeService {
  final AppearanceService _appearanceService = AppearanceService();

  /// 获取强调色
  Color getAccentColor(String accentColorName) {
    switch (accentColorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'pink':
        return Colors.pink;
      case 'purple':
        return Colors.purple;
      case 'indigo':
        return Colors.indigo;
      case 'blue':
        return Colors.blue;
      case 'cyan':
        return Colors.cyan;
      case 'teal':
        return Colors.teal;
      case 'green':
        return Colors.green;
      case 'lime':
        return Colors.lime;
      case 'yellow':
        return Colors.yellow;
      case 'amber':
        return Colors.amber;
      case 'orange':
        return Colors.orange;
      case 'deeporange':
        return Colors.deepOrange;
      default:
        return Colors.blue;
    }
  }

  /// 创建亮色主题
  Future<ThemeData> createLightTheme(ColorScheme? lightDynamic) async {
    final useDynamicColor = await _appearanceService.loadUseDynamicColor();
    final accentColorName = await _appearanceService.loadAccentColor();
    final accentColor = getAccentColor(accentColorName);

    final colorScheme = useDynamicColor && lightDynamic != null
        ? lightDynamic
        : ColorScheme.fromSeed(seedColor: accentColor);

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      // 使用系统字体
      fontFamily: 'system',
      appBarTheme: const AppBarTheme(elevation: 0),
    );
  }

  /// 创建暗色主题
  Future<ThemeData> createDarkTheme(ColorScheme? darkDynamic) async {
    final useDynamicColor = await _appearanceService.loadUseDynamicColor();
    final accentColorName = await _appearanceService.loadAccentColor();
    final accentColor = getAccentColor(accentColorName);

    final colorScheme = useDynamicColor && darkDynamic != null
        ? darkDynamic
        : ColorScheme.fromSeed(
            seedColor: accentColor,
            brightness: Brightness.dark,
          );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      // 使用系统字体
      fontFamily: 'system',
      appBarTheme: const AppBarTheme(elevation: 0),
    );
  }

  // 加载主题模式
  Future<ThemeMode> loadThemeMode() async {
    return await _appearanceService.loadThemeMode();
  }

  // 保存主题模式
  Future<void> saveThemeMode(ThemeMode themeMode) async {
    await _appearanceService.saveThemeMode(themeMode);
  }
}
