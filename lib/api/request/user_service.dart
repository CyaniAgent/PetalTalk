import '../flarum_api.dart';

class UserService {
  final FlarumApi _api = FlarumApi();

  // 获取当前用户信息
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _api.get('/api/users/me');

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  // 获取用户信息
  Future<Map<String, dynamic>?> getUser(String id) async {
    try {
      final response = await _api.get('/api/users/$id');

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  // 更新用户信息
  Future<Map<String, dynamic>?> updateUser({
    required String id,
    Map<String, dynamic>? attributes,
  }) async {
    try {
      final response = await _api.patch(
        '/api/users/$id',
        data: {
          'data': {
            'type': 'users',
            'id': id,
            if (attributes != null) 'attributes': attributes,
          },
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('Update user error: $e');
      return null;
    }
  }
}
