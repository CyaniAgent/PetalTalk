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

    // 尝试使用缓存数据
    List<notification_model.Notification>? cachedNotifications;
    try {
      final cachedResponse = await _cacheService.getCache<Map<String, dynamic>>(
        cacheKey,
      );
      if (cachedResponse != null) {
        logger.info('尝试使用缓存获取通知列表，缓存键: $cacheKey');
        cachedNotifications = _parseNotificationResponse(cachedResponse);
        logger.debug('成功解析缓存通知列表，共 ${cachedNotifications.length} 条通知');
      }
    } catch (cacheError) {
      // 缓存读取失败，记录错误但继续执行
      final cacheDetailedError = ErrorHandler.createDetailedError(
        cacheError,
        errorMessage: '获取通知缓存失败',
        context: {'cacheKey': cacheKey, 'offset': offset},
      );
      logger.error('获取通知缓存失败: $cacheDetailedError', cacheError);
    }

    // 调用API获取最新数据
    Future<List<notification_model.Notification>> apiCall() async {
      logger.info('开始获取通知列表，偏移量: $offset');
      final response = await _api.get(
        '/api/notifications',
        queryParameters: {'page[offset]': offset},
      );

      if (response.statusCode == 200) {
        final newData = response.data;
        final List<dynamic> notificationsJson = newData['data'];
        logger.debug('通知列表API响应成功，数据数量: ${notificationsJson.length}');

        // 比较数据是否一致，不一致则更新缓存
        bool shouldUpdateCache = true;
        try {
          final cachedResponse = await _cacheService
              .getCache<Map<String, dynamic>>(cacheKey);
          if (cachedResponse != null) {
            shouldUpdateCache = _areNotificationsDifferent(
              cachedResponse,
              newData,
            );
          }
        } catch (cacheError) {
          // 缓存读取失败，默认更新缓存
          shouldUpdateCache = true;
        }

        if (shouldUpdateCache) {
          // 将完整的响应数据存入缓存，有效期30分钟
          try {
            await _cacheService.setCache(key: cacheKey, data: newData);
            logger.debug('通知列表缓存更新成功，缓存键: $cacheKey');
          } catch (cacheError) {
            // 缓存写入失败，记录错误但继续执行
            final cacheDetailedError = ErrorHandler.createDetailedError(
              cacheError,
              errorMessage: '更新通知缓存失败',
              context: {
                'cacheKey': cacheKey,
                'offset': offset,
                'dataCount': notificationsJson.length,
              },
            );
            logger.error('更新通知缓存失败: $cacheDetailedError', cacheError);
          }
        }

        return _parseNotificationResponse(newData);
      } else {
        logger.warning('通知列表API响应失败，状态码: ${response.statusCode}');
        throw Exception('API响应失败，状态码: ${response.statusCode}');
      }
    }

    // 使用ErrorHandler处理API调用
    final apiNotifications = await ErrorHandler().handleApiCall(
      apiCall,
      errorMessage: '获取通知列表失败',
      context: {'offset': offset},
    );

    // 如果API调用成功，返回API结果
    if (apiNotifications != null) {
      logger.info('成功获取最新通知列表，共 ${apiNotifications.length} 条通知');
      return apiNotifications;
    }

    // 如果API调用失败，返回缓存数据（如果有）
    if (cachedNotifications != null) {
      logger.info('API调用失败，返回缓存通知列表，共 ${cachedNotifications.length} 条通知');
      return cachedNotifications;
    }

    // 所有尝试都失败，返回null
    logger.warning('获取通知列表失败，没有可用的缓存数据');
    return null;
  }

  /// 解析通知响应数据为通知模型列表
  List<notification_model.Notification> _parseNotificationResponse(
    Map<String, dynamic> responseData,
  ) {
    final List<dynamic> notificationsJson = responseData['data'];
    final List<dynamic> includedJson = responseData['included'] ?? [];

    // 构建included数据的索引映射，便于快速查找
    final Map<String, Map<String, dynamic>> includedData = {};
    for (final item in includedJson) {
      final key = '${item['type']}_${item['id']}';
      includedData[key] = item;
    }

    // 解析通知数据
    return notificationsJson
        .map(
          (json) =>
              notification_model.Notification.fromJson(json, includedData),
        )
        .toList();
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
