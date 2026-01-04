import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../flarum_api.dart';

class AuthService {
  final FlarumApi _api = FlarumApi();
  static const String _tokenKey = 'flarum_token';
  static const String _userIdKey = 'flarum_user_id';

  // 登录
  Future<Map<String, dynamic>?> login({
    required String identification,
    required String password,
    bool remember = false,
  }) async {
    try {
      final response = await _api.post(
        '/api/token',
        data: {
          'identification': identification,
          'password': password,
          if (remember) 'remember': 1,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      // 登录成功，无论状态码是什么，只要返回了token
      final token = response.data['token'];
      final userId = response.data['userId'];

      if (token != null) {
        // 保存令牌到内存
        _api.setToken(token);

        // 如果需要记住登录状态，保存到本地存储
        if (remember) {
          await _saveLoginInfo(token, userId);
        }

        return {'token': token, 'userId': userId};
      }
      return null;
    } on DioException catch (e) {
      // 打印详细的错误信息，方便调试
      print('Login DioException: ${e.response?.statusCode}');
      print('Login DioException data: ${e.response?.data}');
      print('Login DioException message: ${e.message}');
      
      // 即使发生异常，也要检查响应数据中是否包含token
      if (e.response?.data != null && e.response?.data['token'] != null) {
        final token = e.response?.data['token'];
        final userId = e.response?.data['userId'];
        
        // 保存令牌到内存
        if (token != null) {
          _api.setToken(token);

          // 如果需要记住登录状态，保存到本地存储
          if (remember && userId != null) {
            await _saveLoginInfo(token, userId);
          }
        }

        return {'token': token, 'userId': userId};
      }
      
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  // 从本地存储加载登录信息
  Future<void> loadLoginInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      _api.setToken(token);
    }
  }

  // 保存登录信息到本地存储
  Future<void> _saveLoginInfo(String token, dynamic userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    // 确保userId是字符串类型
    await prefs.setString(_userIdKey, userId.toString());
  }

  // 清除本地存储的登录信息
  Future<void> _clearLoginInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
  }

  // 注销
  Future<void> logout() async {
    _api.clearToken();
    await _clearLoginInfo();
  }

  // 检查是否已登录
  bool isLoggedIn() {
    return _api.token != null;
  }

  // 获取当前令牌
  String? getToken() {
    return _api.token;
  }
}
