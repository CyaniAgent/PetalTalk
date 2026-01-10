/// 错误处理工具库，提供统一的错误处理机制
///
/// 该库包含：
/// 1. 错误类型枚举 - 定义了应用中可能遇到的各种错误类型
/// 2. 错误优先级枚举 - 定义了错误的严重程度
/// 3. 错误信息模型 - 包含详细的错误信息结构
/// 4. 错误处理类 - 提供了处理Dio错误、获取错误消息等功能
/// 5. API调用包装方法 - 简化API调用的错误处理
library;

import 'package:dio/dio.dart';
import '../core/logger.dart';

/// 错误优先级枚举，定义了错误的严重程度
enum ErrorPriority {
  /// 低优先级 - 不影响核心功能，仅影响部分用户体验
  low,

  /// 中优先级 - 影响部分功能，但可以恢复
  medium,

  /// 高优先级 - 影响核心功能，需要立即处理
  high,
}

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

  /// 缓存错误 - 缓存读写失败
  cache,

  /// 解析错误 - 数据解析失败
  parsing,

  /// 未知错误 - 无法归类的其他错误
  unknown,
}

/// 详细的错误信息模型，包含完整的错误上下文
class DetailedError {
  /// 错误类型
  final ErrorType type;

  /// 错误优先级
  final ErrorPriority priority;

  /// 错误消息
  final String message;

  /// 原始错误对象
  final dynamic originalError;

  /// 错误堆栈跟踪
  final StackTrace? stackTrace;

  /// 错误码（可选）
  final int? errorCode;

  /// 错误发生的时间
  final DateTime timestamp;

  /// 错误上下文信息（可选）
  final Map<String, dynamic>? context;

  DetailedError({
    required this.type,
    required this.priority,
    required this.message,
    required this.originalError,
    this.stackTrace,
    this.errorCode,
    this.context,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    return 'DetailedError(type: $type, priority: $priority, message: $message, errorCode: $errorCode)';
  }
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
      case ErrorType.cache:
        return '缓存错误，请重试';
      case ErrorType.parsing:
        return '数据解析错误，请稍后重试';
      case ErrorType.unknown:
        return '未知错误，请稍后重试';
    }
  }

  /// 根据ErrorType获取对应的错误优先级
  ///
  /// 参数：
  /// - errorType: ErrorType枚举值，表示错误的类型
  ///
  /// 返回值：
  /// - ErrorPriority枚举值，表示错误的优先级
  ErrorPriority getErrorPriority(ErrorType errorType) {
    switch (errorType) {
      case ErrorType.network:
        return ErrorPriority.medium;
      case ErrorType.server:
        return ErrorPriority.high;
      case ErrorType.auth:
        return ErrorPriority.high;
      case ErrorType.client:
        return ErrorPriority.medium;
      case ErrorType.cache:
        return ErrorPriority.low;
      case ErrorType.parsing:
        return ErrorPriority.medium;
      case ErrorType.unknown:
        return ErrorPriority.medium;
    }
  }

  /// 处理通用错误，将任意类型的错误转换为详细的错误信息
  ///
  /// 参数：
  /// - error: 任意类型的错误对象
  /// - errorMessage: 可选的自定义错误消息
  /// - context: 可选的错误上下文信息
  ///
  /// 返回值：
  /// - DetailedError: 包含详细错误信息的对象
  static DetailedError createDetailedError(
    dynamic error, {
    String? errorMessage,
    Map<String, dynamic>? context,
  }) {
    ErrorType errorType;
    String message;
    int? errorCode;

    if (error is DioException) {
      errorType = _instance.handleDioError(error);
      message = errorMessage ?? _instance.getErrorMessage(errorType);
      errorCode = error.response?.statusCode;
    } else if (error is FormatException || error is TypeError) {
      errorType = ErrorType.parsing;
      message = errorMessage ?? _instance.getErrorMessage(errorType);
    } else {
      errorType = ErrorType.unknown;
      message = errorMessage ?? _instance.getErrorMessage(errorType);
    }

    return DetailedError(
      type: errorType,
      priority: _instance.getErrorPriority(errorType),
      message: message,
      originalError: error,
      stackTrace: error is Error ? error.stackTrace : null,
      errorCode: errorCode,
      context: context,
    );
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
    return createDetailedError(error, errorMessage: errorMessage).message;
  }

  /// 处理API调用错误，包装API调用并自动处理错误
  ///
  /// 参数：
  /// - apiCall: `Future<T> Function()`类型的回调函数，包含实际的API调用逻辑
  /// - errorMessage: 可选的自定义错误消息
  /// - context: 可选的错误上下文信息
  ///
  /// 返回值：
  /// - `Future<T?>`: 成功时返回API调用的结果，失败时返回null
  /// 注意：不再自动显示错误提示，由调用方决定如何处理错误
  Future<T?> handleApiCall<T>(
    Future<T> Function() apiCall, {
    String? errorMessage,
    Map<String, dynamic>? context,
  }) async {
    try {
      return await apiCall();
    } catch (error) {
      // 创建详细错误信息
      final detailedError = createDetailedError(
        error,
        errorMessage: errorMessage,
        context: context,
      );

      // 记录详细错误日志
      logger.error('API调用错误: $detailedError', error, detailedError.stackTrace);

      return null;
    }
  }

  /// 重试API调用，在失败时自动重试
  ///
  /// 参数：
  /// - apiCall: `Future<T> Function()`类型的回调函数，包含实际的API调用逻辑
  /// - retryCount: 重试次数，默认为3次
  /// - retryDelay: 重试间隔，默认为1秒
  /// - errorMessage: 可选的自定义错误消息
  /// - context: 可选的错误上下文信息
  ///
  /// 返回值：
  /// - `Future<T?>`: 成功时返回API调用的结果，失败时返回null
  Future<T?> retryApiCall<T>(
    Future<T> Function() apiCall, {
    int retryCount = 3,
    Duration retryDelay = const Duration(seconds: 1),
    String? errorMessage,
    Map<String, dynamic>? context,
  }) async {
    for (int i = 0; i < retryCount; i++) {
      try {
        return await apiCall();
      } catch (error) {
        // 如果是最后一次重试，返回null
        if (i == retryCount - 1) {
          return await handleApiCall(
            apiCall,
            errorMessage: errorMessage,
            context: context,
          );
        }

        // 等待一段时间后重试
        await Future.delayed(retryDelay);
      }
    }

    return null;
  }
}
