import 'package:dio/dio.dart';

import './logger.dart';

/// 错误类型枚举
enum ErrorType {
  /// 网络错误
  network,

  /// 服务器错误
  server,

  /// 认证错误
  auth,

  /// 客户端错误
  client,

  /// 未知错误
  unknown,
}

/// 错误处理工具类，提供统一的错误处理机制
class ErrorHandler {
  /// 单例实例
  static final ErrorHandler _instance = ErrorHandler._internal();

  /// 工厂构造函数
  factory ErrorHandler() => _instance;

  /// 内部构造函数
  ErrorHandler._internal();

  /// 处理Dio错误
  ErrorType handleDioError(DioException error) {
    logger.error('Dio Error:', error);

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

  /// 获取错误消息
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
      default:
        return '未知错误，请稍后重试';
    }
  }

  /// 处理通用错误
  static String handleError(dynamic error, [String? errorMessage]) {
    logger.error(errorMessage ?? 'Error:', error);

    if (error is DioException) {
      final errorType = _instance.handleDioError(error);
      return _instance.getErrorMessage(errorType);
    } else {
      return _instance.getErrorMessage(ErrorType.unknown);
    }
  }

  /// 处理API调用错误
  Future<T?> handleApiCall<T>(
    Future<T> Function() apiCall, {
    String? errorMessage,
  }) async {
    try {
      return await apiCall();
    } catch (error) {
      final message = errorMessage ?? handleError(error);
      logger.error(message, error);
      return null;
    }
  }
}
