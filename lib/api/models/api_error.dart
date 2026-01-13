/// API错误模型
library;

class ApiError {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiError({required this.message, this.statusCode, this.data});

  @override
  String toString() {
    return 'ApiError(message: $message, statusCode: $statusCode, data: $data)';
  }
}
