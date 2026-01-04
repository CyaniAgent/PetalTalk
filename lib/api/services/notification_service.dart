import '../flarum_api.dart';

class NotificationService {
  final FlarumApi _api = FlarumApi();

  // 获取通知列表
  Future<Map<String, dynamic>?> getNotifications({
    bool? unread,
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final queryParameters = {
        'page[offset]': offset,
        'page[limit]': limit,
        if (unread != null) 'filter[unread]': unread,
      };

      final response = await _api.get(
        '/api/notifications',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('Get notifications error: $e');
      return null;
    }
  }

  // 标记所有通知为已读
  Future<bool> markAllAsRead() async {
    try {
      final response = await _api.post(
        '/api/notifications/read',
        data: {
          'data': {
            'type': 'notifications',
          },
        },
      );

      return response.statusCode == 204;
    } catch (e) {
      print('Mark all notifications as read error: $e');
      return false;
    }
  }

  // 标记单个通知为已读
  Future<bool> markAsRead(String id) async {
    try {
      final response = await _api.patch(
        '/api/notifications/$id',
        data: {
          'data': {
            'type': 'notifications',
            'id': id,
            'attributes': {
              'isRead': true,
            },
          },
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Mark notification as read error: $e');
      return false;
    }
  }
}
