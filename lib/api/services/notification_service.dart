import '../flarum_api.dart';
import '../models/notification.dart' as notification_model;
import 'package:get/get.dart';
import '../../utils/error_handler.dart';

class NotificationService {
  final FlarumApi _api = Get.find<FlarumApi>();

  // 获取通知列表
  Future<List<notification_model.Notification>?> getNotifications({
    int offset = 0,
  }) async {
    try {
      final response = await _api.get(
        '/api/notifications',
        queryParameters: {'page[offset]': offset, 'include': ''},
      );

      if (response.statusCode == 200) {
        final data = response.data;
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

        return notifications;
      }
      return null;
    } catch (e) {
      ErrorHandler.handleError(e, 'Get notifications');
      return null;
    }
  }
}
