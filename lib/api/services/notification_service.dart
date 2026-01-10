/// 通知服务，负责处理通知相关的API操作
///
/// 该服务提供获取用户通知列表的功能，并将API响应转换为类型安全的通知模型
library;

import '../flarum_api.dart';
import '../models/notification.dart' as notification_model;
import 'package:get/get.dart';
import '../../utils/error_handler.dart';
import '../../core/logger.dart';
import '../../core/cache_service.dart';

/// 通知服务类，处理通知相关的所有API操作
class NotificationService {
  /// Flarum API客户端实例
  final FlarumApi _api = Get.find<FlarumApi>();

  /// 缓存服务实例
  final CacheService _cacheService = Get.find<CacheService>();

  /// 获取通知列表
  /// 
  /// 参数：
  /// - offset: 偏移量，用于分页
  /// 
  /// 返回值：
  /// - `Future<List<notification_model.Notification>?>`: 包含通知模型的列表，失败返回null
  Future<List<notification_model.Notification>?> getNotifications({
    int offset = 0,
  }) async {
    // 生成缓存键
    final cacheKey = 'cache_notifications_$offset';
    
    try {
      logger.info('开始获取通知列表，偏移量: $offset');
      final response = await _api.get(
        '/api/notifications',
        queryParameters: {'page[offset]': offset},
      );

      if (response.statusCode == 200) {
        final newData = response.data;
        final List<dynamic> notificationsJson = newData['data'];
        final List<dynamic> includedJson = newData['included'] ?? [];

        logger.debug('通知列表API响应成功，数据数量: ${notificationsJson.length}');
        
        // 尝试获取当前缓存数据
        Map<String, dynamic>? cachedResponse;
        try {
          cachedResponse = await _cacheService
              .getCache<Map<String, dynamic>>(cacheKey);
        } catch (cacheError) {
          // 缓存读取失败，记录错误但继续执行
          final cacheDetailedError = ErrorHandler.createDetailedError(
            cacheError,
            errorMessage: '获取通知缓存失败',
            context: {'cacheKey': cacheKey, 'offset': offset},
          );
          logger.error('获取通知缓存失败: $cacheDetailedError', cacheError);
        }
        
        // 比较数据是否一致，不一致则更新缓存
        if (cachedResponse == null ||
            _areNotificationsDifferent(cachedResponse, newData)) {
          // 将完整的响应数据存入缓存，有效期30分钟
          try {
            await _cacheService.setCache(key: cacheKey, data: newData);
            logger.debug('通知列表缓存更新成功，缓存键: $cacheKey');
          } catch (cacheError) {
            // 缓存写入失败，记录错误但继续执行
            final cacheDetailedError = ErrorHandler.createDetailedError(
              cacheError,
              errorMessage: '更新通知缓存失败',
              context: {'cacheKey': cacheKey, 'offset': offset, 'dataCount': notificationsJson.length},
            );
            logger.error('更新通知缓存失败: $cacheDetailedError', cacheError);
          }
        }

        // 构建included数据的索引映射，便于快速查找
        final Map<String, Map<String, dynamic>> includedData = {};
        for (final item in includedJson) {
          final key = '${item['type']}_${item['id']}';
          includedData[key] = item;
        }

        // 解析通知数据
        final notifications = notificationsJson
            .map(
              (json) =>
                  notification_model.Notification.fromJson(json, includedData),
            )
            .toList();

        logger.info('成功解析通知列表，共 ${notifications.length} 条通知');
        return notifications;
      } else {
        logger.warning('通知列表API响应失败，状态码: ${response.statusCode}');
        
        // 创建详细错误信息
        final detailedError = ErrorHandler.createDetailedError(
          Exception('API响应失败'),
          errorMessage: '获取通知列表失败',
          context: {
            'statusCode': response.statusCode,
            'offset': offset,
            'responseData': response.data,
          },
        );
        logger.error('API响应失败详细信息: $detailedError');
      }
      return null;
    } catch (e, stackTrace) {
      // 创建详细错误信息
      final detailedError = ErrorHandler.createDetailedError(
        e,
        errorMessage: '获取通知列表发生异常',
        context: {'offset': offset},
      );
      
      logger.error('获取通知列表发生异常: $detailedError', e, stackTrace);

      // 如果网络请求失败，尝试使用缓存数据（包括过期缓存）
      try {
        final cachedResponse = await _cacheService.getCache<Map<String, dynamic>>(
          cacheKey,
        );
        if (cachedResponse != null) {
          logger.info('网络请求失败，使用缓存获取通知列表，缓存键: $cacheKey');

          final data = cachedResponse;
          final List<dynamic> notificationsJson = data['data'];
          final List<dynamic> includedJson = data['included'] ?? [];

          // 构建included数据的索引映射，便于快速查找
          final Map<String, Map<String, dynamic>> includedData = {};
          for (final item in includedJson) {
            final key = '${item['type']}_${item['id']}';
            includedData[key] = item;
          }

          // 解析通知数据
          final notifications = notificationsJson
              .map(
                (json) =>
                    notification_model.Notification.fromJson(json, includedData),
              )
              .toList();

          logger.info('成功从缓存解析通知列表，共 ${notifications.length} 条通知');
          return notifications;
        } else {
          logger.warning('缓存中没有找到通知数据，缓存键: $cacheKey');
        }
      } catch (cacheError) {
        // 缓存读取失败，记录错误
        final cacheDetailedError = ErrorHandler.createDetailedError(
          cacheError,
          errorMessage: '获取通知缓存失败',
          context: {'cacheKey': cacheKey, 'offset': offset},
        );
        logger.error('获取通知缓存失败: $cacheDetailedError', cacheError);
      }
      
      // 所有尝试都失败，返回null
      return null;
    }
  }

  /// 比较两个通知列表数据是否不同
  ///
  /// 参数：
  /// - oldData: 旧数据
  /// - newData: 新数据
  ///
  /// 返回值：
  /// - bool: 如果数据不同返回true，否则返回false
  bool _areNotificationsDifferent(
    Map<String, dynamic> oldData,
    Map<String, dynamic> newData,
  ) {
    final oldNotifications = oldData['data'] as List;
    final newNotifications = newData['data'] as List;

    // 比较数据列表长度
    if (oldNotifications.length != newNotifications.length) {
      return true;
    }

    // 比较每条数据的id和attributes
    for (int i = 0; i < oldNotifications.length; i++) {
      final oldItem = oldNotifications[i] as Map<String, dynamic>;
      final newItem = newNotifications[i] as Map<String, dynamic>;

      // 比较id
      if (oldItem['id'] != newItem['id']) {
        return true;
      }

      // 比较attributes
      final oldAttrs = oldItem['attributes'] as Map<String, dynamic>;
      final newAttrs = newItem['attributes'] as Map<String, dynamic>;

      // 比较关键属性
      if (oldAttrs['contentType'] != newAttrs['contentType'] ||
          oldAttrs['readAt'] != newAttrs['readAt'] ||
          oldAttrs['createdAt'] != newAttrs['createdAt'] ||
          oldAttrs['isRead'] != newAttrs['isRead']) {
        return true;
      }
    }

    return false;
  }
}
