/// 缓存服务，负责管理应用的缓存数据
///
/// 该服务提供：
/// 1. 通用的缓存存储和获取功能
/// 2. 缓存过期时间管理
/// 3. 支持不同类型数据的缓存
/// 4. 缓存清理功能
///
/// 使用单例模式，确保在应用中只有一个缓存服务实例
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 缓存服务类，处理应用的所有缓存逻辑
class CacheService {
  /// 单例实例，确保全局唯一
  static final CacheService _instance = CacheService._internal();

  /// 工厂构造函数，返回单例实例
  factory CacheService() => _instance;

  /// 内部构造函数，防止外部实例化
  CacheService._internal();

  /// 默认缓存过期时间：30分钟
  static const Duration _defaultExpiry = Duration(minutes: 30);

  /// SharedPreferences实例
  late SharedPreferences _prefs;

  /// 初始化缓存服务
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 存储缓存数据
  ///
  /// 参数：
  /// - key: 缓存键，使用唯一标识符
  /// - data: 要缓存的数据
  /// - expiry: 缓存过期时间，默认30分钟
  Future<void> setCache<T>({
    required String key,
    required T data,
    Duration expiry = _defaultExpiry,
  }) async {
    final cacheData = {
      'data': data,
      'expiry': DateTime.now().add(expiry).millisecondsSinceEpoch,
    };

    final jsonString = jsonEncode(cacheData);
    await _prefs.setString(key, jsonString);
  }

  /// 获取缓存数据
  ///
  /// 参数：
  /// - key: 缓存键
  ///
  /// 返回值：
  /// - `Future<T?>`: 缓存数据，如果缓存不存在或已过期则返回null
  Future<T?> getCache<T>(String key) async {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) {
      return null;
    }

    try {
      final cacheData = jsonDecode(jsonString) as Map<String, dynamic>;
      final expiry = cacheData['expiry'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      // 检查缓存是否过期
      if (now > expiry) {
        // 缓存已过期，删除缓存
        await _prefs.remove(key);
        return null;
      }

      return cacheData['data'] as T;
    } catch (e) {
      // 解析失败，删除无效缓存
      await _prefs.remove(key);
      return null;
    }
  }

  /// 删除特定缓存
  ///
  /// 参数：
  /// - key: 要删除的缓存键
  Future<void> removeCache(String key) async {
    await _prefs.remove(key);
  }

  /// 清理所有过期缓存
  Future<void> clearExpiredCache() async {
    final keys = _prefs.getKeys();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final key in keys) {
      if (key.startsWith('cache_')) {
        final jsonString = _prefs.getString(key);
        if (jsonString != null) {
          try {
            final cacheData = jsonDecode(jsonString) as Map<String, dynamic>;
            final expiry = cacheData['expiry'] as int;

            if (now > expiry) {
              await _prefs.remove(key);
            }
          } catch (e) {
            // 解析失败，删除无效缓存
            await _prefs.remove(key);
          }
        }
      }
    }
  }

  /// 清理所有缓存
  Future<void> clearAllCache() async {
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('cache_')) {
        await _prefs.remove(key);
      }
    }
  }
}
