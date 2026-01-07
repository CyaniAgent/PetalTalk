/// 主题帖服务，负责处理主题帖相关的API操作
/// 
/// 该服务提供：
/// 1. 获取主题帖列表
/// 2. 获取单个主题帖详情
/// 3. 创建新主题帖
library;

import '../flarum_api.dart';
import 'package:get/get.dart';
import '../../utils/error_handler.dart';

/// 主题帖服务类，处理主题帖相关的所有API操作
class DiscussionService {
  /// Flarum API客户端实例
  final FlarumApi _api = Get.find<FlarumApi>();

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
  }) async {
    try {
      final response = await _api.get(
        '/api/discussions',
        queryParameters: {'page[offset]': offset, 'page[limit]': limit},
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      ErrorHandler.handleError(e, 'Get discussions');
      return null;
    }
  }

  /// 获取单个主题帖详情
  /// 
  /// 参数：
  /// - id: 主题帖ID
  /// 
  /// 返回值：
  /// - `Future<Map<String, dynamic>?>`: 包含主题帖详情的响应数据，失败返回null
  Future<Map<String, dynamic>?> getDiscussion(String id) async {
    try {
      final response = await _api.get('/api/discussions/$id');

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      ErrorHandler.handleError(e, 'Get discussion');
      return null;
    }
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
            'attributes': {'title': title},
            'relationships': {
              'firstPost': {
                'data': {
                  'type': 'posts',
                  'attributes': {'content': content},
                },
              },
              if (tags != null && tags.isNotEmpty)
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
      }
      return null;
    } catch (e) {
      ErrorHandler.handleError(e, 'Create discussion');
      return null;
    }
  }
}
