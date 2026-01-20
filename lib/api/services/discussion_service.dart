/// 主题帖服务，负责处理主题帖相关的API操作
///
/// 该服务提供：
/// 1. 获取主题帖列表
/// 2. 获取单个主题帖详情
/// 3. 创建新主题帖
library;

import '../flarum_api.dart';
import 'package:get/get.dart';
import '../../core/logger.dart';
import '../../utils/error_handler.dart';
import '../../core/cache_service.dart';

/// 主题帖服务类，处理主题帖相关的所有API操作
class DiscussionService {
  /// Flarum API客户端实例
  final FlarumApi _api = Get.find<FlarumApi>();

  /// 缓存服务实例
  final CacheService _cacheService = Get.find<CacheService>();

  /// 获取主题帖列表
  ///
  /// 参数：
  /// - offset: 偏移量，用于分页
  /// - limit: 每页数量，默认20
  ///
  /// 返回值：
  /// - `Future<Map<String, dynamic>?>`: 包含主题帖列表的响应数据，失败返回null
  Future<Map<String, dynamic>?> getDiscussions({
    int offset = 0,
    int limit = 20,
    String? query,
  }) async {
    // 生成缓存键
    final cacheKey = 'cache_discussions_${offset}_${limit}_${query ?? ''}';

    try {
      // 准备查询参数
      final Map<String, dynamic> queryParams = {
        'page[offset]': offset,
        'page[limit]': limit,
      };

      if (query != null && query.isNotEmpty) {
        queryParams['filter[q]'] = query;
      }
      final response = await _api.get(
        '/api/discussions',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final newData = response.data;

        // 尝试获取当前缓存数据并更新
        try {
          final cachedData = await _cacheService.getCache<Map<String, dynamic>>(
            cacheKey,
          );
          // 比较数据是否一致，不一致则更新缓存
          if (cachedData == null ||
              _areDiscussionsDifferent(cachedData, newData)) {
            await _cacheService.setCache(key: cacheKey, data: newData);
          }
        } catch (cacheError) {
          // 缓存操作失败，记录错误但继续执行
          final cacheDetailedError = ErrorHandler.createDetailedError(
            cacheError,
            errorMessage: '主题帖缓存操作失败',
            context: {'cacheKey': cacheKey, 'offset': offset, 'limit': limit},
          );
          logger.error('主题帖缓存操作失败: $cacheDetailedError', cacheError);
        }

        return newData;
      } else {
        // 创建详细错误信息
        final detailedError = ErrorHandler.createDetailedError(
          Exception('API响应失败'),
          errorMessage: '获取主题帖列表失败',
          context: {
            'statusCode': response.statusCode,
            'offset': offset,
            'limit': limit,
          },
        );
        logger.error('获取主题帖列表失败: $detailedError');
      }
      return null;
    } catch (e) {
      // 创建详细错误信息
      final detailedError = ErrorHandler.createDetailedError(
        e,
        errorMessage: '获取主题帖列表发生异常',
        context: {'offset': offset, 'limit': limit},
      );

      logger.error('获取主题帖列表发生异常: $detailedError', e);
      ErrorHandler.handleError(e, 'Get discussions');

      // 如果网络请求失败，尝试使用缓存数据（包括过期缓存）
      try {
        return await _cacheService.getCache<Map<String, dynamic>>(cacheKey);
      } catch (cacheError) {
        // 缓存读取失败，记录错误
        final cacheDetailedError = ErrorHandler.createDetailedError(
          cacheError,
          errorMessage: '获取主题帖缓存失败',
          context: {'cacheKey': cacheKey, 'offset': offset, 'limit': limit},
        );
        logger.error('获取主题帖缓存失败: $cacheDetailedError', cacheError);
        return null;
      }
    }
  }

  /// 比较两个主题帖列表数据是否不同
  ///
  /// 参数：
  /// - oldData: 旧数据
  /// - newData: 新数据
  ///
  /// 返回值：
  /// - bool: 如果数据不同返回true，否则返回false
  bool _areDiscussionsDifferent(
    Map<String, dynamic> oldData,
    Map<String, dynamic> newData,
  ) {
    // 比较数据列表长度
    final oldDiscussions = oldData['data'] as List;
    final newDiscussions = newData['data'] as List;

    if (oldDiscussions.length != newDiscussions.length) {
      return true;
    }

    // 比较每条数据的id和attributes
    for (int i = 0; i < oldDiscussions.length; i++) {
      final oldItem = oldDiscussions[i] as Map<String, dynamic>;
      final newItem = newDiscussions[i] as Map<String, dynamic>;

      // 比较id
      if (oldItem['id'] != newItem['id']) {
        return true;
      }

      // 比较attributes
      final oldAttrs = oldItem['attributes'] as Map<String, dynamic>;
      final newAttrs = newItem['attributes'] as Map<String, dynamic>;

      // 比较关键属性
      if (oldAttrs['title'] != newAttrs['title'] ||
          oldAttrs['commentCount'] != newAttrs['commentCount'] ||
          oldAttrs['lastPostedAt'] != newAttrs['lastPostedAt']) {
        return true;
      }
    }

    return false;
  }

  /// 获取单个主题帖详情
  ///
  /// 参数：
  /// - id: 主题帖ID
  ///
  /// 返回值：
  /// - `Future<Map<String, dynamic>?>`: 包含主题帖详情的响应数据，失败返回null
  Future<Map<String, dynamic>?> getDiscussion(String id) async {
    // 生成缓存键
    final cacheKey = 'cache_discussion_$id';

    try {
      // 优先请求网络数据
      final response = await _api.get('/api/discussions/$id');

      if (response.statusCode == 200) {
        final newData = response.data;

        // 尝试获取当前缓存数据并更新
        try {
          final cachedData = await _cacheService.getCache<Map<String, dynamic>>(
            cacheKey,
          );
          // 比较数据是否一致，不一致则更新缓存
          if (cachedData == null ||
              _areDiscussionDetailsDifferent(cachedData, newData)) {
            await _cacheService.setCache(key: cacheKey, data: newData);
          }
        } catch (cacheError) {
          // 缓存操作失败，记录错误但继续执行
          final cacheDetailedError = ErrorHandler.createDetailedError(
            cacheError,
            errorMessage: '主题帖详情缓存操作失败',
            context: {'cacheKey': cacheKey, 'discussionId': id},
          );
          logger.error('主题帖详情缓存操作失败: $cacheDetailedError', cacheError);
        }

        return newData;
      } else {
        // 创建详细错误信息
        final detailedError = ErrorHandler.createDetailedError(
          Exception('API响应失败'),
          errorMessage: '获取主题帖详情失败',
          context: {'statusCode': response.statusCode, 'discussionId': id},
        );
        logger.error('获取主题帖详情失败: $detailedError');
      }
      return null;
    } catch (e) {
      // 创建详细错误信息
      final detailedError = ErrorHandler.createDetailedError(
        e,
        errorMessage: '获取主题帖详情发生异常',
        context: {'discussionId': id},
      );

      logger.error('获取主题帖详情发生异常: $detailedError', e);
      ErrorHandler.handleError(e, 'Get discussion');

      // 如果网络请求失败，尝试使用缓存数据（包括过期缓存）
      try {
        return await _cacheService.getCache<Map<String, dynamic>>(cacheKey);
      } catch (cacheError) {
        // 缓存读取失败，记录错误
        final cacheDetailedError = ErrorHandler.createDetailedError(
          cacheError,
          errorMessage: '获取主题帖详情缓存失败',
          context: {'cacheKey': cacheKey, 'discussionId': id},
        );
        logger.error('获取主题帖详情缓存失败: $cacheDetailedError', cacheError);
        return null;
      }
    }
  }

  /// 比较两个主题帖详情数据是否不同
  ///
  /// 参数：
  /// - oldData: 旧数据
  /// - newData: 新数据
  ///
  /// 返回值：
  /// - bool: 如果数据不同返回true，否则返回false
  bool _areDiscussionDetailsDifferent(
    Map<String, dynamic> oldData,
    Map<String, dynamic> newData,
  ) {
    final oldDiscussion = oldData['data'] as Map<String, dynamic>;
    final newDiscussion = newData['data'] as Map<String, dynamic>;

    // 比较id
    if (oldDiscussion['id'] != newDiscussion['id']) {
      return true;
    }

    // 比较attributes
    final oldAttrs = oldDiscussion['attributes'] as Map<String, dynamic>;
    final newAttrs = newDiscussion['attributes'] as Map<String, dynamic>;

    // 比较关键属性
    if (oldAttrs['title'] != newAttrs['title'] ||
        oldAttrs['commentCount'] != newAttrs['commentCount'] ||
        oldAttrs['lastPostedAt'] != newAttrs['lastPostedAt'] ||
        oldAttrs['lastReadAt'] != newAttrs['lastReadAt'] ||
        oldAttrs['subscription'] != newAttrs['subscription']) {
      return true;
    }

    return false;
  }

  /// 创建新主题帖
  ///
  /// 参数：
  /// - title: 主题帖标题
  /// - content: 主题帖内容
  /// - tags: 可选的标签列表
  ///
  /// 返回值：
  /// - `Future<Map<String, dynamic>?>`: 包含创建结果的响应数据，失败返回null
  Future<Map<String, dynamic>?> createDiscussion({
    required String title,
    required String content,
    List<String>? tags,
  }) async {
    try {
      final response = await _api.post(
        '/api/discussions',
        data: {
          'data': {
            'type': 'discussions',
            'attributes': {'title': title, 'content': content},
            if (tags != null && tags.isNotEmpty)
              'relationships': {
                'tags': {
                  'data': tags
                      .map((tag) => {'type': 'tags', 'id': tag})
                      .toList(),
                },
              },
          },
        },
      );

      if (response.statusCode == 201) {
        return response.data;
      } else {
        // 创建详细错误信息
        final detailedError = ErrorHandler.createDetailedError(
          Exception('API响应失败'),
          errorMessage: '创建主题帖失败',
          context: {
            'statusCode': response.statusCode,
            'title': title,
            'tagsCount': tags?.length ?? 0,
          },
        );
        logger.error('创建主题帖失败: $detailedError');
      }
      return null;
    } catch (e) {
      // 创建详细错误信息
      final detailedError = ErrorHandler.createDetailedError(
        e,
        errorMessage: '创建主题帖发生异常',
        context: {'title': title, 'tagsCount': tags?.length ?? 0},
      );

      logger.error('创建主题帖发生异常: $detailedError', e);
      ErrorHandler.handleError(e, 'Create discussion');
      return null;
    }
  }

  /// 关注或取消关注主题帖
  ///
  /// 参数：
  /// - id: 主题帖ID
  /// - subscription: 订阅类型，'follow'表示关注，'ignore'表示忽略，null表示取消订阅
  ///
  /// 返回值：
  /// - `Future<Map<String, dynamic>?>`: 包含操作结果的响应数据，失败返回null
  Future<Map<String, dynamic>?> followDiscussion({
    required String id,
    required String subscription,
  }) async {
    try {
      final response = await _api.patch(
        '/api/discussions/$id',
        data: {
          'data': {
            'type': 'discussions',
            'id': id,
            'attributes': {'subscription': subscription},
          },
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        // 创建详细错误信息
        final detailedError = ErrorHandler.createDetailedError(
          Exception('API响应失败'),
          errorMessage: '关注主题帖失败',
          context: {
            'statusCode': response.statusCode,
            'discussionId': id,
            'subscription': subscription,
          },
        );
        logger.error('关注主题帖失败: $detailedError');
      }
      return null;
    } catch (e) {
      // 创建详细错误信息
      final detailedError = ErrorHandler.createDetailedError(
        e,
        errorMessage: '关注主题帖发生异常',
        context: {'discussionId': id, 'subscription': subscription},
      );

      logger.error('关注主题帖发生异常: $detailedError', e);
      ErrorHandler.handleError(e, 'Follow discussion');
      return null;
    }
  }
}
