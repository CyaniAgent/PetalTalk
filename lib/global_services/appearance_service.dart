import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/logger.dart';
import '../config/constants.dart';

class AppearanceService {
  final AppLogger _logger = AppLogger();
  // 使用Constants类中的常量，不再重复定义
  // 主题相关键
  static const String _themeModeKey = Constants.themeModeKey;
  static const String _useDynamicColorKey = Constants.useDynamicColorKey;
  static const String _accentColorKey = Constants.accentColorKey;
  // 通知设置键
  static const String _enableNotificationsKey =
      Constants.enableNotificationsKey;
  static const String _enableMessageNotificationsKey =
      Constants.enableMessageNotificationsKey;
  static const String _enableMentionNotificationsKey =
      Constants.enableMentionNotificationsKey;
  static const String _enableReplyNotificationsKey =
      Constants.enableReplyNotificationsKey;
  static const String _enableSystemNotificationsKey =
      Constants.enableSystemNotificationsKey;

  // 加载主题模式
  Future<ThemeMode> loadThemeMode() async {
    _logger.debug('开始加载主题模式');
    final prefs = await SharedPreferences.getInstance();

    // 使用更安全的方式获取存储值，避免直接类型转换错误
    String themeModeValue = Constants.defaultThemeMode; // 默认值

    try {
      // 尝试获取值，不指定类型
      final value = prefs.get(_themeModeKey);
      _logger.debug('获取主题模式存储值: $value (类型: ${value?.runtimeType})');

      if (value is String) {
        // 如果是String类型，直接使用
        themeModeValue = value;
        _logger.debug('使用String类型主题模式: $themeModeValue');
      } else if (value is int) {
        // 如果是int类型，转换为对应的String
        _logger.debug('将int类型主题模式 $value 转换为String');
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
        _logger.info('已将主题模式存储从int转换为String: $themeModeValue');
      } else if (value != null) {
        // 如果是其他类型，使用默认值并更新存储
        await prefs.setString(_themeModeKey, themeModeValue);
        _logger.warning('未知主题模式类型 ${value.runtimeType}，使用默认值并更新存储');
      }
    } catch (e, stackTrace) {
      // 捕获任何异常，使用默认值并更新存储
      await prefs.setString(_themeModeKey, themeModeValue);
      _logger.error('加载主题模式出错', e, stackTrace);
    }

    final result = themeModeValue == 'light'
        ? ThemeMode.light
        : themeModeValue == 'dark'
        ? ThemeMode.dark
        : ThemeMode.system;

    _logger.info('加载主题模式完成: $result');
    return result;
  }

  // 保存主题模式
  Future<void> saveThemeMode(ThemeMode themeMode) async {
    _logger.debug('开始保存主题模式: $themeMode');
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
        themeModeString = 'system';
        break;
    }
    await prefs.setString(_themeModeKey, themeModeString);
    _logger.info('保存主题模式完成: $themeModeString');
  }

  // 安全获取bool值
  bool _safeGetBool(SharedPreferences prefs, String key, bool defaultValue) {
    try {
      final value = prefs.get(key);
      _logger.debug(
        '安全获取bool值 - 键: $key, 值: $value, 类型: ${value?.runtimeType}',
      );
      if (value is bool) {
        return value;
      } else if (value is int) {
        // 如果是int类型，转换为bool
        final result = value == 1;
        _logger.debug('将int $value转换为bool: $result');
        return result;
      }
    } catch (e, stackTrace) {
      _logger.error('安全获取bool值出错 - 键: $key', e, stackTrace);
      // 忽略异常，返回默认值
    }
    _logger.debug('返回默认bool值 - 键: $key, 默认值: $defaultValue');
    return defaultValue;
  }

  // 安全获取String值
  String _safeGetString(
    SharedPreferences prefs,
    String key,
    String defaultValue,
  ) {
    try {
      final value = prefs.get(key);
      _logger.debug(
        '安全获取String值 - 键: $key, 值: $value, 类型: ${value?.runtimeType}',
      );
      if (value is String) {
        return value;
      }
    } catch (e, stackTrace) {
      _logger.error('安全获取String值出错 - 键: $key', e, stackTrace);
      // 忽略异常，返回默认值
    }
    _logger.debug('返回默认String值 - 键: $key, 默认值: $defaultValue');
    return defaultValue;
  }

  // 加载是否使用动态颜色
  Future<bool> loadUseDynamicColor() async {
    _logger.debug('开始加载动态颜色设置');
    final prefs = await SharedPreferences.getInstance();
    final result = _safeGetBool(
      prefs,
      _useDynamicColorKey,
      Constants.defaultUseDynamicColor,
    );
    _logger.info('加载动态颜色设置完成: $result');
    return result;
  }

  // 保存是否使用动态颜色
  Future<void> saveUseDynamicColor(bool useDynamicColor) async {
    _logger.debug('开始保存动态颜色设置: $useDynamicColor');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useDynamicColorKey, useDynamicColor);
    _logger.info('保存动态颜色设置完成: $useDynamicColor');
  }

  // 加载强调色
  Future<String> loadAccentColor() async {
    _logger.debug('开始加载强调色设置');
    final prefs = await SharedPreferences.getInstance();
    final result = _safeGetString(
      prefs,
      _accentColorKey,
      Constants.defaultAccentColor,
    );
    _logger.info('加载强调色设置完成: $result');
    return result;
  }

  // 保存强调色
  Future<void> saveAccentColor(String accentColor) async {
    _logger.debug('开始保存强调色设置: $accentColor');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accentColorKey, accentColor);
    _logger.info('保存强调色设置完成: $accentColor');
  }

  // 加载是否启用通知
  Future<bool> loadEnableNotifications() async {
    _logger.debug('开始加载全局通知设置');
    final prefs = await SharedPreferences.getInstance();
    final result = _safeGetBool(
      prefs,
      _enableNotificationsKey,
      Constants.defaultEnableNotifications,
    );
    _logger.info('加载全局通知设置完成: $result');
    return result;
  }

  // 保存是否启用通知
  Future<void> saveEnableNotifications(bool enableNotifications) async {
    _logger.debug('开始保存全局通知设置: $enableNotifications');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enableNotificationsKey, enableNotifications);
    _logger.info('保存全局通知设置完成: $enableNotifications');
  }

  // 加载是否启用消息通知
  Future<bool> loadEnableMessageNotifications() async {
    _logger.debug('开始加载消息通知设置');
    final prefs = await SharedPreferences.getInstance();
    final result = _safeGetBool(prefs, _enableMessageNotificationsKey, true);
    _logger.info('加载消息通知设置完成: $result');
    return result;
  }

  // 保存是否启用消息通知
  Future<void> saveEnableMessageNotifications(bool enable) async {
    _logger.debug('开始保存消息通知设置: $enable');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enableMessageNotificationsKey, enable);
    _logger.info('保存消息通知设置完成: $enable');
  }

  // 加载是否启用提及通知
  Future<bool> loadEnableMentionNotifications() async {
    _logger.debug('开始加载提及通知设置');
    final prefs = await SharedPreferences.getInstance();
    final result = _safeGetBool(prefs, _enableMentionNotificationsKey, true);
    _logger.info('加载提及通知设置完成: $result');
    return result;
  }

  // 保存是否启用提及通知
  Future<void> saveEnableMentionNotifications(bool enable) async {
    _logger.debug('开始保存提及通知设置: $enable');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enableMentionNotificationsKey, enable);
    _logger.info('保存提及通知设置完成: $enable');
  }

  // 加载是否启用回复通知
  Future<bool> loadEnableReplyNotifications() async {
    _logger.debug('开始加载回复通知设置');
    final prefs = await SharedPreferences.getInstance();
    final result = _safeGetBool(prefs, _enableReplyNotificationsKey, true);
    _logger.info('加载回复通知设置完成: $result');
    return result;
  }

  // 保存是否启用回复通知
  Future<void> saveEnableReplyNotifications(bool enable) async {
    _logger.debug('开始保存回复通知设置: $enable');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enableReplyNotificationsKey, enable);
    _logger.info('保存回复通知设置完成: $enable');
  }

  // 加载是否启用系统通知
  Future<bool> loadEnableSystemNotifications() async {
    _logger.debug('开始加载系统通知设置');
    final prefs = await SharedPreferences.getInstance();
    final result = _safeGetBool(prefs, _enableSystemNotificationsKey, true);
    _logger.info('加载系统通知设置完成: $result');
    return result;
  }

  // 保存是否启用系统通知
  Future<void> saveEnableSystemNotifications(bool enable) async {
    _logger.debug('开始保存系统通知设置: $enable');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enableSystemNotificationsKey, enable);
    _logger.info('保存系统通知设置完成: $enable');
  }

  // 日志相关设置键
  static const String _logLevelKey = Constants.logLevelKey;
  static const String _maxLogSizeKey = Constants.maxLogSizeKey;
  static const String _enableLogExportKey = Constants.enableLogExportKey;

  // 加载日志级别
  Future<String> loadLogLevel() async {
    _logger.debug('开始加载日志级别设置');
    final prefs = await SharedPreferences.getInstance();
    final result = _safeGetString(
      prefs,
      _logLevelKey,
      Constants.defaultLogLevel,
    );
    _logger.info('加载日志级别设置完成: $result');
    return result;
  }

  // 保存日志级别
  Future<void> saveLogLevel(String logLevel) async {
    _logger.debug('开始保存日志级别设置: $logLevel');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_logLevelKey, logLevel);
    _logger.info('保存日志级别设置完成: $logLevel');
  }

  // 加载最大日志大小
  Future<int> loadMaxLogSize() async {
    _logger.debug('开始加载最大日志大小设置');
    final prefs = await SharedPreferences.getInstance();
    try {
      final value = prefs.get(_maxLogSizeKey);
      _logger.debug('获取最大日志大小存储值: $value (类型: ${value?.runtimeType})');
      if (value is int) {
        _logger.info('加载最大日志大小设置完成: $value');
        return value;
      } else if (value is String) {
        // 如果是String类型，转换为int
        final result = int.tryParse(value) ?? Constants.defaultMaxLogSize;
        _logger.info('加载最大日志大小设置完成: $result');
        return result;
      }
    } catch (e, stackTrace) {
      _logger.error('加载最大日志大小出错', e, stackTrace);
    }
    _logger.info('加载最大日志大小设置完成，使用默认值: ${Constants.defaultMaxLogSize}');
    return Constants.defaultMaxLogSize;
  }

  // 保存最大日志大小
  Future<void> saveMaxLogSize(int maxLogSize) async {
    _logger.debug('开始保存最大日志大小设置: $maxLogSize');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maxLogSizeKey, maxLogSize);
    _logger.info('保存最大日志大小设置完成: $maxLogSize');
  }

  // 加载是否启用日志导出
  Future<bool> loadEnableLogExport() async {
    _logger.debug('开始加载日志导出设置');
    final prefs = await SharedPreferences.getInstance();
    final result = _safeGetBool(
      prefs,
      _enableLogExportKey,
      Constants.defaultEnableLogExport,
    );
    _logger.info('加载日志导出设置完成: $result');
    return result;
  }

  // 保存是否启用日志导出
  Future<void> saveEnableLogExport(bool enable) async {
    _logger.debug('开始保存日志导出设置: $enable');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enableLogExportKey, enable);
    _logger.info('保存日志导出设置完成: $enable');
  }
}
