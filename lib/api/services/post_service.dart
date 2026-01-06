import '../flarum_api.dart';
import 'package:get/get.dart';
import '../../utils/error_handler.dart';

class PostService {
  final FlarumApi _api = Get.find<FlarumApi>();

  // 获取帖子列表
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

  // 获取单个帖子
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

  // 获取主题帖的所有帖子
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

  // 回复主题帖
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

  // 更新帖子
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
