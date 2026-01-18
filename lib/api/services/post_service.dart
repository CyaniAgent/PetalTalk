/// 帖子服务，负责处理帖子相关的API操作
///
/// 该服务提供：
/// 1. 获取帖子列表
/// 2. 获取单个帖子
/// 3. 获取主题帖的所有帖子
/// 4. 回复主题帖
/// 5. 更新帖子
/// 6. 点赞/取消点赞
library;

import '../flarum_api.dart';
import 'package:get/get.dart';
import '../../core/logger.dart';
import '../../utils/error_handler.dart';
import '../../core/cache_service.dart';

/// 帖子服务类，处理帖子相关的所有API操作
class PostService {
  /// Flarum API客户端实例
  final FlarumApi _api = Get.find<FlarumApi>();

  /// 缓存服务实例
  final CacheService _cacheService = Get.find<CacheService>();

  /// 获取帖子列表
  ///
  /// 参数：
  /// - offset: 偏移量，用于分页
  /// - limit: 每页数量，默认20
  ///
  /// 返回值：
  /// - `Future<Map<String, dynamic>?>`: 包含帖子列表的响应数据，失败返回null
  Future<Map<String, dynamic>?> getPosts({
    int offset = 0,
    int limit = 20,
  }) async {
    // 生成缓存键
    final cacheKey = 'cache_posts_${offset}_$limit';

    try {
      final response = await _api.get(
        '/api/posts',
        queryParameters: {'page[offset]': offset, 'page[limit]': limit},
      );

      if (response.statusCode == 200) {
        final newData = response.data;

        // 尝试获取当前缓存数据
        Map<String, dynamic>? cachedData;
        try {
          cachedData = await _cacheService.getCache<Map<String, dynamic>>(
            cacheKey,
          );
        } catch (cacheError) {
          // 缓存读取失败，记录错误但继续执行
          final cacheDetailedError = ErrorHandler.createDetailedError(
            cacheError,
            errorMessage: '获取帖子缓存失败',
            context: {'cacheKey': cacheKey, 'offset': offset, 'limit': limit},
          );
          logger.error('获取帖子缓存失败: $cacheDetailedError', cacheError);
        }

        // 比较数据是否一致，不一致则更新缓存
        if (cachedData == null || _arePostsDifferent(cachedData, newData)) {
          try {
            await _cacheService.setCache(key: cacheKey, data: newData);
          } catch (cacheError) {
            // 缓存写入失败，记录错误但继续执行
            final cacheDetailedError = ErrorHandler.createDetailedError(
              cacheError,
              errorMessage: '更新帖子缓存失败',
              context: {'cacheKey': cacheKey, 'offset': offset, 'limit': limit},
            );
            logger.error('更新帖子缓存失败: $cacheDetailedError', cacheError);
          }
        }

        return newData;
      } else {
        // 创建详细错误信息
        final detailedError = ErrorHandler.createDetailedError(
          Exception('API响应失败'),
          errorMessage: '获取帖子列表失败',
          context: {
            'statusCode': response.statusCode,
            'offset': offset,
            'limit': limit,
          },
        );
        logger.error('获取帖子列表失败: $detailedError');
      }
      return null;
    } catch (e) {
      // 创建详细错误信息
      final detailedError = ErrorHandler.createDetailedError(
        e,
        errorMessage: '获取帖子列表发生异常',
        context: {'offset': offset, 'limit': limit},
      );

      logger.error('获取帖子列表发生异常: $detailedError', e);
      ErrorHandler.handleError(e, 'Get posts');

      // 如果网络请求失败，尝试使用缓存数据（包括过期缓存）
      try {
        return await _cacheService.getCache<Map<String, dynamic>>(cacheKey);
      } catch (cacheError) {
        // 缓存读取失败，记录错误
        final cacheDetailedError = ErrorHandler.createDetailedError(
          cacheError,
          errorMessage: '获取帖子缓存失败',
          context: {'cacheKey': cacheKey, 'offset': offset, 'limit': limit},
        );
        logger.error('获取帖子缓存失败: $cacheDetailedError', cacheError);
        return null;
      }
    }
  }

  /// 比较两个帖子列表数据是否不同
  ///
  /// 参数：
  /// - oldData: 旧数据
  /// - newData: 新数据
  ///
  /// 返回值：
  /// - bool: 如果数据不同返回true，否则返回false
  bool _arePostsDifferent(
    Map<String, dynamic> oldData,
    Map<String, dynamic> newData,
  ) {
    final oldPosts = oldData['data'] as List;
    final newPosts = newData['data'] as List;

    // 比较数据列表长度
    if (oldPosts.length != newPosts.length) {
      return true;
    }

    // 比较每条数据的id和attributes
    for (int i = 0; i < oldPosts.length; i++) {
      final oldItem = oldPosts[i] as Map<String, dynamic>;
      final newItem = newPosts[i] as Map<String, dynamic>;

      // 比较id
      if (oldItem['id'] != newItem['id']) {
        return true;
      }

      // 比较attributes
      final oldAttrs = oldItem['attributes'] as Map<String, dynamic>;
      final newAttrs = newItem['attributes'] as Map<String, dynamic>;

      // 比较关键属性
      if (oldAttrs['content'] != newAttrs['content'] ||
          oldAttrs['createdAt'] != newAttrs['createdAt'] ||
          oldAttrs['updatedAt'] != newAttrs['updatedAt']) {
        return true;
      }
    }

    return false;
  }

  /// 获取单个帖子详情
  ///
  /// 参数：
  /// - id: 帖子ID
  ///
  /// 返回值：
  /// - `Future<Map<String, dynamic>?>`: 包含帖子详情的响应数据，失败返回null
  Future<Map<String, dynamic>?> getPost(String id) async {
    logger.info('获取单个帖子详情，帖子ID: $id');
    // 生成缓存键
    final cacheKey = 'cache_post_$id';

    try {
      final response = await _api.get('/api/posts/$id');

      if (response.statusCode == 200) {
        final newData = response.data;
        logger.debug('获取帖子详情成功，帖子ID: $id');

        // 获取当前缓存数据
        final cachedData = await _cacheService.getCache<Map<String, dynamic>>(
          cacheKey,
        );

        // 比较数据是否一致，不一致则更新缓存
        if (cachedData == null ||
            _arePostDetailsDifferent(cachedData, newData)) {
          logger.debug('更新帖子详情缓存，帖子ID: $id');
          await _cacheService.setCache(key: cacheKey, data: newData);
        }

        return newData;
      }
      logger.warning('获取帖子详情失败，帖子ID: $id，状态码: ${response.statusCode}');
      return null;
    } catch (e) {
      final detailedError = ErrorHandler.createDetailedError(
        e,
        errorMessage: '获取帖子详情发生异常',
        context: {'postId': id},
      );
      logger.error('获取帖子详情发生异常: $detailedError', e);
      ErrorHandler.handleError(e, 'Get post');
      // 如果网络请求失败，使用缓存数据（包括过期缓存）
      logger.debug('尝试使用缓存获取帖子详情，缓存键: $cacheKey');
      return await _cacheService.getCache<Map<String, dynamic>>(cacheKey);
    }
  }

  /// 比较两个帖子详情数据是否不同
  ///
  /// 参数：
  /// - oldData: 旧数据
  /// - newData: 新数据
  ///
  /// 返回值：
  /// - bool: 如果数据不同返回true，否则返回false
  bool _arePostDetailsDifferent(
    Map<String, dynamic> oldData,
    Map<String, dynamic> newData,
  ) {
    final oldPost = oldData['data'] as Map<String, dynamic>;
    final newPost = newData['data'] as Map<String, dynamic>;

    // 比较id
    if (oldPost['id'] != newPost['id']) {
      return true;
    }

    // 比较attributes
    final oldAttrs = oldPost['attributes'] as Map<String, dynamic>;
    final newAttrs = newPost['attributes'] as Map<String, dynamic>;

    // 比较关键属性
    if (oldAttrs['content'] != newAttrs['content'] ||
        oldAttrs['createdAt'] != newAttrs['createdAt'] ||
        oldAttrs['updatedAt'] != newAttrs['updatedAt'] ||
        oldAttrs['number'] != newAttrs['number']) {
      return true;
    }

    return false;
  }

  /// 获取主题帖的所有帖子
  ///
  /// 参数：
  /// - discussionId: 主题帖ID
  /// - offset: 偏移量，用于分页
  /// - limit: 每页数量，默认20
  ///
  /// 返回值：
  /// - `Future<Map<String, dynamic>?>`: 包含帖子列表的响应数据，失败返回null
  Future<Map<String, dynamic>?> getPostsForDiscussion(
    String discussionId, {
    int offset = 0,
    int limit = 20,
  }) async {
    logger.info('获取主题帖的帖子列表，主题帖ID: $discussionId，偏移量: $offset，每页数量: $limit');
    // 生成缓存键
    final cacheKey =
        'cache_posts_for_discussion_${discussionId}_${offset}_$limit';

    try {
      final response = await _api.get(
        '/api/posts',
        queryParameters: {
          'filter[discussion]': discussionId,
          'page[offset]': offset,
          'page[limit]': limit,
        },
      );

      if (response.statusCode == 200) {
        final newData = response.data;
        logger.debug('获取主题帖帖子列表成功，主题帖ID: $discussionId');

        // 获取当前缓存数据
        final cachedData = await _cacheService.getCache<Map<String, dynamic>>(
          cacheKey,
        );

        // 比较数据是否一致，不一致则更新缓存
        if (cachedData == null || _arePostsDifferent(cachedData, newData)) {
          logger.debug('更新主题帖帖子列表缓存，主题帖ID: $discussionId');
          await _cacheService.setCache(key: cacheKey, data: newData);
        }

        return newData;
      }
      logger.warning(
        '获取主题帖帖子列表失败，主题帖ID: $discussionId，状态码: ${response.statusCode}',
      );
      return null;
    } catch (e) {
      final detailedError = ErrorHandler.createDetailedError(
        e,
        errorMessage: '获取主题帖帖子列表发生异常',
        context: {
          'discussionId': discussionId,
          'offset': offset,
          'limit': limit,
        },
      );
      logger.error('获取主题帖帖子列表发生异常: $detailedError', e);
      ErrorHandler.handleError(e, 'Get posts for discussion');
      // 如果网络请求失败，使用缓存数据（包括过期缓存）
      logger.debug('尝试使用缓存获取主题帖帖子列表，缓存键: $cacheKey');
      return await _cacheService.getCache<Map<String, dynamic>>(cacheKey);
    }
  }

  /// 回复主题帖
  ///
  /// 参数：
  /// - discussionId: 主题帖ID
  /// - content: 回复内容
  ///
  /// 返回值：
  /// - `Future<Map<String, dynamic>?>`: 包含回复结果的响应数据，失败返回null
  Future<Map<String, dynamic>?> replyToDiscussion({
    required String discussionId,
    required String content,
  }) async {
    logger.info('回复主题帖，主题帖ID: $discussionId');
    try {
      final response = await _api.post(
        '/api/posts',
        data: {
          'data': {
            'type': 'posts',
            'attributes': {'content': content},
            'relationships': {
              'discussion': {
                'data': {'type': 'discussions', 'id': discussionId},
              },
            },
          },
        },
      );

      if (response.statusCode == 201) {
        logger.debug('回复主题帖成功，主题帖ID: $discussionId');
        return response.data;
      }
      logger.warning(
        '回复主题帖失败，主题帖ID: $discussionId，状态码: ${response.statusCode}',
      );
      return null;
    } catch (e) {
      final detailedError = ErrorHandler.createDetailedError(
        e,
        errorMessage: '回复主题帖发生异常',
        context: {'discussionId': discussionId},
      );
      logger.error('回复主题帖发生异常: $detailedError', e);
      ErrorHandler.handleError(e, 'Reply to discussion');
      return null;
    }
  }

  /// 点赞或取消点赞帖子
  ///
  /// 参数：
  /// - id: 帖子ID
  /// - isLiked: 是否点赞
  ///
  /// 返回值：
  /// - `Future<Map<String, dynamic>?>`: 包含操作结果的响应数据，失败返回null
  Future<Map<String, dynamic>?> likePost({
    required String id,
    required bool isLiked,
  }) async {
    logger.info('${isLiked ? "点赞" : "取消点赞"}帖子，帖子ID: $id');
    try {
      final response = await _api.patch(
        '/api/posts/$id',
        data: {
          'data': {
            'type': 'posts',
            'id': id,
            'attributes': {'isLiked': isLiked},
          },
        },
      );

      if (response.statusCode == 200) {
        logger.debug('${isLiked ? "点赞" : "取消点赞"}成功，帖子ID: $id');
        return response.data;
      }
      logger.warning(
        '${isLiked ? "点赞" : "取消点赞"}失败，帖子ID: $id，状态码: ${response.statusCode}',
      );
      return null;
    } catch (e) {
      final detailedError = ErrorHandler.createDetailedError(
        e,
        errorMessage: '${isLiked ? "点赞" : "取消点赞"}发生异常',
        context: {'postId': id, 'isLiked': isLiked},
      );
      logger.error('${isLiked ? "点赞" : "取消点赞"}发生异常: $detailedError', e);
      ErrorHandler.handleError(e, 'Like post');
      return null;
    }
  }

  /// 更新帖子
  ///
  /// 参数：
  /// - id: 帖子ID
  /// - content: 更新后的内容
  ///
  /// 返回值：
  /// - `Future<Map<String, dynamic>?>`: 包含更新结果的响应数据，失败返回null
  Future<Map<String, dynamic>?> updatePost({
    required String id,
    required String content,
  }) async {
    logger.info('更新帖子，帖子ID: $id');
    try {
      final response = await _api.patch(
        '/api/posts/$id',
        data: {
          'data': {
            'type': 'posts',
            'id': id,
            'attributes': {'content': content},
          },
        },
      );

      if (response.statusCode == 200) {
        logger.debug('更新帖子成功，帖子ID: $id');
        return response.data;
      }
      logger.warning('更新帖子失败，帖子ID: $id，状态码: ${response.statusCode}');
      return null;
    } catch (e) {
      final detailedError = ErrorHandler.createDetailedError(
        e,
        errorMessage: '更新帖子发生异常',
        context: {'postId': id},
      );
      logger.error('更新帖子发生异常: $detailedError', e);
      ErrorHandler.handleError(e, 'Update post');
      return null;
    }
  }
}
