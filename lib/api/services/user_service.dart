import 'package:get/get.dart';
import '../flarum_api.dart';
import '../../core/logger.dart';

/// 用户服务，负责获取和管理用户信息
class UserService {
  final FlarumApi _api = Get.find<FlarumApi>();

  /// 获取指定用户的信息
  ///
  /// [userId] 用户ID
  /// [include] 需要包含的关联数据，例如 'groups'
  Future<Map<String, dynamic>?> getUserProfile(
    String userId, {
    String include = 'groups',
  }) async {
    try {
      final response = await _api.get(
        '/api/users/$userId',
        queryParameters: {'include': include},
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e, stackTrace) {
      logger.error('获取用户信息失败: $userId', e, stackTrace);
      return null;
    }
  }

  /// 获取当前登录用户的详尽映射数据
  Future<Map<String, dynamic>?> getCurrentUserProfileMap(String userId) async {
    return getUserProfile(userId);
  }
}
