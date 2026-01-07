/// 帖子服务，负责处理帖子相关的API操作
/// 
/// 该服务提供：
/// 1. 获取帖子列表
/// 2. 获取单个帖子
/// 3. 获取主题帖的所有帖子
/// 4. 回复主题帖
/// 5. 更新帖子
library;

import '../flarum_api.dart';
import 'package:get/get.dart';
import '../../utils/error_handler.dart';

/// 帖子服务类，处理帖子相关的所有API操作
class PostService {
  /// Flarum API客户端实例
  final FlarumApi _api = Get.find<FlarumApi>();

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
    try {
      final response = await _api.get(
        '/api/posts',
        queryParameters: {'page[offset]': offset, 'page[limit]': limit},
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      ErrorHandler.handleError(e, 'Get posts');
      return null;
    }
  }

  /// 获取单个帖子详情
  /// 
  /// 参数：
  /// - id: 帖子ID
  /// 
  /// 返回值：
  /// - `Future<Map<String, dynamic>?>`: 包含帖子详情的响应数据，失败返回null
  Future<Map<String, dynamic>?> getPost(String id) async {
    try {
      final response = await _api.get('/api/posts/$id');

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      ErrorHandler.handleError(e, 'Get post');
      return null;
    }
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
        return response.data;
      }
      return null;
    } catch (e) {
      ErrorHandler.handleError(e, 'Get posts for discussion');
      return null;
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
        return response.data;
      }
      return null;
    } catch (e) {
      ErrorHandler.handleError(e, 'Reply to discussion');
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
        return response.data;
      }
      return null;
    } catch (e) {
      ErrorHandler.handleError(e, 'Update post');
      return null;
    }
  }
}
