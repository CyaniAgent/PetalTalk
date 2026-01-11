/// 主题服务，负责管理应用的主题设置和主题创建
///
/// 该服务提供：
/// 1. 主题模式管理
/// 2. 亮色主题创建
/// 3. 暗色主题创建
/// 4. 强调色管理
library;

import 'dart:io';
import 'package:flutter/material.dart';

import './appearance_service.dart';

/// 主题服务类，处理主题相关的所有功能
class ThemeService {
  /// 外观服务实例，用于加载外观设置
  final AppearanceService _appearanceService = AppearanceService();

  /// 根据颜色名称获取对应的强调色
  ///
  /// 参数：
  /// - accentColorName: 强调色名称（如'blue'、'red'等）
  ///
  /// 返回值：
  /// - Color: 对应的颜色值
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
  ///
  /// 参数：
  /// - lightDynamic: 系统提供的动态颜色方案（如果支持）
  ///
  /// 返回值：
  /// - `Future<ThemeData>`: 配置好的亮色主题
  Future<ThemeData> createLightTheme(ColorScheme? lightDynamic) async {
    // 并行加载主题设置，提高性能
    final settings = await Future.wait([
      _appearanceService.loadUseDynamicColor(),
      _appearanceService.loadAccentColor(),
    ]);
    
    final useDynamicColor = settings[0] as bool;
    final accentColorName = settings[1] as String;
    final accentColor = getAccentColor(accentColorName);

    final colorScheme = useDynamicColor && lightDynamic != null
        ? lightDynamic
        : ColorScheme.fromSeed(seedColor: accentColor);

    // 根据平台设置字体，Windows上优先使用Noto Sans SC
    final fontFamily = Platform.isWindows ? 'Noto Sans SC' : 'system';

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: fontFamily,
      appBarTheme: const AppBarTheme(elevation: 0),
    );
  }

  /// 创建暗色主题
  ///
  /// 参数：
  /// - darkDynamic: 系统提供的动态颜色方案（如果支持）
  ///
  /// 返回值：
  /// - `Future<ThemeData>`: 配置好的暗色主题
  Future<ThemeData> createDarkTheme(ColorScheme? darkDynamic) async {
    // 并行加载主题设置，提高性能
    final settings = await Future.wait([
      _appearanceService.loadUseDynamicColor(),
      _appearanceService.loadAccentColor(),
    ]);
    
    final useDynamicColor = settings[0] as bool;
    final accentColorName = settings[1] as String;
    final accentColor = getAccentColor(accentColorName);

    final colorScheme = useDynamicColor && darkDynamic != null
        ? darkDynamic
        : ColorScheme.fromSeed(
            seedColor: accentColor,
            brightness: Brightness.dark,
          );

    // 根据平台设置字体，Windows上优先使用Noto Sans SC
    final fontFamily = Platform.isWindows ? 'Noto Sans SC' : 'system';

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: fontFamily,
      appBarTheme: const AppBarTheme(elevation: 0),
    );
  }

  /// 加载主题模式
  ///
  /// 返回值：
  /// - `Future<ThemeMode>`: 当前保存的主题模式
  Future<ThemeMode> loadThemeMode() async {
    return await _appearanceService.loadThemeMode();
  }

  /// 保存主题模式
  ///
  /// 参数：
  /// - themeMode: 要保存的主题模式
  Future<void> saveThemeMode(ThemeMode themeMode) async {
    await _appearanceService.saveThemeMode(themeMode);
  }
}
