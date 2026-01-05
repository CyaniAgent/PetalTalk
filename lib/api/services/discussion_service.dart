import '../flarum_api.dart';

class DiscussionService {
  final FlarumApi _api = FlarumApi();

  // 获取主题帖列表
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
      // 使用调试信息而非print语句，便于后续替换为日志系统
      // 实际项目中建议使用日志库如logger
      // ignore: avoid_print
      assert(() {
        print('Get discussions error: $e');
        return true;
      }());
      return null;
    }
  }

  // 获取单个主题帖
  Future<Map<String, dynamic>?> getDiscussion(String id) async {
    try {
      final response = await _api.get('/api/discussions/$id');

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      // 使用调试信息而非print语句，便于后续替换为日志系统
      // ignore: avoid_print
      assert(() {
        print('Get discussion error: $e');
        return true;
      }());
      return null;
    }
  }

  // 创建主题帖
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
      // 使用调试信息而非print语句，便于后续替换为日志系统
      // ignore: avoid_print
      assert(() {
        print('Create discussion error: $e');
        return true;
      }());
      return null;
    }
  }
}
