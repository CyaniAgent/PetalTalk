/// 错误处理工具库，提供统一的错误处理机制
///
/// 该库包含：
/// 1. 错误类型枚举 - 定义了应用中可能遇到的各种错误类型
/// 2. 错误处理类 - 提供了处理Dio错误、获取错误消息等功能
/// 3. API调用包装方法 - 简化API调用的错误处理
library;

import 'package:dio/dio.dart';

/// 错误类型枚举，定义了应用中可能遇到的各种错误类型
enum ErrorType {
  /// 网络错误 - 无法连接到服务器或连接超时
  network,

  /// 服务器错误 - 服务器返回5xx状态码
  server,

  /// 认证错误 - 服务器返回401或403状态码
  auth,

  /// 客户端错误 - 服务器返回4xx状态码（除认证错误外）
  client,

  /// 未知错误 - 无法归类的其他错误
  unknown,
}

/// 错误处理工具类，提供统一的错误处理机制
///
/// 使用单例模式，确保在应用中只有一个错误处理实例
class ErrorHandler {
  /// 单例实例，确保全局唯一
  static final ErrorHandler _instance = ErrorHandler._internal();

  /// 工厂构造函数，返回单例实例
  factory ErrorHandler() => _instance;

  /// 内部构造函数，防止外部实例化
  ErrorHandler._internal();

  /// 处理Dio错误，将DioException转换为应用定义的ErrorType
  ///
  /// 参数：
  /// - error: DioException对象，包含错误的详细信息
  ///
  /// 返回值：
  /// - ErrorType枚举值，表示错误的类型
  ErrorType handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return ErrorType.network;
      case DioExceptionType.badResponse:
        if (error.response?.statusCode == 401 ||
            error.response?.statusCode == 403) {
          return ErrorType.auth;
        } else if (error.response?.statusCode != null &&
            error.response!.statusCode! >= 500) {
          return ErrorType.server;
        } else {
          return ErrorType.client;
        }
      default:
        return ErrorType.unknown;
    }
  }

  /// 根据ErrorType获取对应的错误消息
  ///
  /// 参数：
  /// - errorType: ErrorType枚举值，表示错误的类型
  ///
  /// 返回值：
  /// - String: 可读的错误消息，用于显示给用户
  String getErrorMessage(ErrorType errorType) {
    switch (errorType) {
      case ErrorType.network:
        return '网络连接错误，请检查网络设置';
      case ErrorType.server:
        return '服务器错误，请稍后重试';
      case ErrorType.auth:
        return '认证失败，请重新登录';
      case ErrorType.client:
        return '请求错误，请检查请求参数';
      case ErrorType.unknown:
        return '未知错误，请稍后重试';
    }
  }

  /// 处理通用错误，将任意类型的错误转换为可读的错误消息
  ///
  /// 参数：
  /// - error: 任意类型的错误对象
  /// - errorMessage: 可选的自定义错误消息
  ///
  /// 返回值：
  /// - String: 可读的错误消息，用于显示给用户
  static String handleError(dynamic error, [String? errorMessage]) {
    if (error is DioException) {
      final errorType = _instance.handleDioError(error);
      return _instance.getErrorMessage(errorType);
    } else {
      return _instance.getErrorMessage(ErrorType.unknown);
    }
  }

  /// 处理API调用错误，包装API调用并自动处理错误
  ///
  /// 参数：
  /// - apiCall: `Future<T> Function()`类型的回调函数，包含实际的API调用逻辑
  /// - errorMessage: 可选的自定义错误消息
  ///
  /// 返回值：
  /// - `Future<T?>`: 成功时返回API调用的结果，失败时返回null
  /// 注意：不再自动显示错误提示，由调用方决定如何处理错误
  Future<T?> handleApiCall<T>(
    Future<T> Function() apiCall, {
    String? errorMessage,
  }) async {
    try {
      return await apiCall();
    } catch (error) {
      // 仅记录错误，不显示提示
      return null;
    }
  }
}
