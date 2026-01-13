/// 认证服务，负责处理用户登录、注销和认证状态管理
///
/// 该服务提供：
/// 1. 用户登录功能
/// 2. 用户注销功能
/// 3. 认证状态检查
/// 4. 登录信息的加载和保存
library;

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../flarum_api.dart';
import '../../config/constants.dart';
import 'package:get/get.dart';
import '../../utils/error_handler.dart';
import '../../core/logger.dart';

/// 认证服务类，处理用户认证相关的所有功能
class AuthService {
  /// Flarum API客户端实例
  final FlarumApi _api = Get.find<FlarumApi>();

  /// 用户登录方法
  ///
  /// 参数：
  /// - identification: 用户名或邮箱
  /// - password: 用户密码
  /// - remember: 是否记住登录状态
  ///
  /// 返回值：
  /// - `Future<Map<String, dynamic>?>`: 登录成功返回包含token和userId的映射，失败返回null
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
        if (remember && _api.baseUrl != null) {
          await _saveLoginInfo(_api.baseUrl!, token, userId);
        }

        return {'token': token, 'userId': userId};
      }
      return null;
    } on DioException catch (e) {
      // 创建详细错误信息
      final detailedError = ErrorHandler.createDetailedError(
        e,
        errorMessage: '登录失败',
        context: {'operation': 'login', 'identification': identification},
      );

      logger.error('登录失败: $detailedError', e);
      ErrorHandler.handleError(e, 'Login');

      // 即使发生异常，也要检查响应数据中是否包含token
      if (e.response?.data != null && e.response?.data['token'] != null) {
        final token = e.response?.data['token'];
        final userId = e.response?.data['userId'];

        // 保存令牌到内存
        if (token != null) {
          _api.setToken(token);

          // 如果需要记住登录状态，保存到本地存储
          if (remember && _api.baseUrl != null && userId != null) {
            await _saveLoginInfo(_api.baseUrl!, token, userId);
          }
        }

        return {'token': token, 'userId': userId};
      }

      return null;
    } catch (e) {
      // 创建详细错误信息
      final detailedError = ErrorHandler.createDetailedError(
        e,
        errorMessage: '登录发生未知错误',
        context: {'operation': 'login', 'identification': identification},
      );

      logger.error('登录发生未知错误: $detailedError', e);
      ErrorHandler.handleError(e, 'Login');
      return null;
    }
  }

  /// 保存登录信息到本地存储
  ///
  /// 参数：
  /// - endpoint: 当前端点URL
  /// - token: 用户令牌
  /// - userId: 用户ID
  ///
  /// 返回值：
  /// - `Future<void>`
  Future<void> _saveLoginInfo(
    String endpoint,
    String token,
    dynamic userId,
  ) async {
    try {
      // 保存令牌
      await _api.saveToken(endpoint, token);

      // 保存用户ID，使用端点特定的键
      await _saveUserId(endpoint, userId);
    } catch (storageError) {
      // 本地存储失败，记录错误但不影响登录流程
      final storageDetailedError = ErrorHandler.createDetailedError(
        storageError,
        errorMessage: '保存登录信息失败',
        context: {'operation': 'saveLoginInfo', 'userId': userId},
      );
      logger.error('保存登录信息失败: $storageDetailedError', storageError);
    }
  }

  /// 保存用户ID到本地存储，使用端点特定的键
  ///
  /// 参数：
  /// - endpoint: 端点URL
  /// - userId: 用户ID
  Future<void> _saveUserId(String endpoint, dynamic userId) async {
    final prefs = await SharedPreferences.getInstance();
    final endpointHash = endpoint.hashCode.toString();
    final userIdKey =
        '${Constants.endpointDataPrefix}${endpointHash}_${Constants.userIdKey}';
    // 确保userId是字符串类型
    await prefs.setString(userIdKey, userId.toString());
  }

  /// 清除本地存储的登录信息
  ///
  /// 该方法会：
  /// 1. 清除当前端点的认证令牌
  /// 2. 清除当前端点的用户ID
  Future<void> _clearLoginInfo() async {
    if (_api.baseUrl != null) {
      // 使用FlarumApi的方法清除当前端点的令牌
      await _api.clearTokenForEndpoint(_api.baseUrl!);

      // 清除用户ID
      final prefs = await SharedPreferences.getInstance();
      final endpointHash = _api.baseUrl!.hashCode.toString();
      final userIdKey =
          '${Constants.endpointDataPrefix}${endpointHash}_${Constants.userIdKey}';
      await prefs.remove(userIdKey);
    }
  }

  /// 用户注销
  ///
  /// 该方法会：
  /// 1. 清除内存中的认证令牌
  /// 2. 清除本地存储中的登录信息
  Future<void> logout() async {
    _api.clearToken();
    await _clearLoginInfo();
  }

  /// 检查用户是否已登录
  ///
  /// 返回值：
  /// - bool: 已登录返回true，未登录返回false
  bool isLoggedIn() {
    return _api.token != null;
  }

  /// 获取当前认证令牌
  ///
  /// 返回值：
  /// - String?: 当前认证令牌，未登录返回null
  String? getToken() {
    return _api.token;
  }
}
