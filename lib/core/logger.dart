/// 日志工具类，负责应用中的日志输出和管理
///
/// 该类提供：
/// 1. 不同级别的日志输出（DEBUG, INFO, WARNING, ERROR）
/// 2. DEBUG模式配置
/// 3. 控制台输出格式化
library;

import 'package:logger/logger.dart';

/// 日志工具类，管理应用中的所有日志输出
class AppLogger {
  /// 单例实例
  static final AppLogger _instance = AppLogger._internal();

  /// 日志实例
  late final Logger _logger;

  /// 工厂构造函数，返回单例实例
  factory AppLogger() {
    return _instance;
  }

  /// 内部构造函数，初始化日志配置
  AppLogger._internal() {
    // 创建日志格式化器
    final formatter = PrettyPrinter(
      methodCount: 2, // 显示2行调用栈
      errorMethodCount: 5, // 显示5行错误调用栈
      lineLength: 80, // 行宽度80
      colors: true, // 彩色输出
      printEmojis: true, // 显示emoji
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart, // 显示时间
    );

    // 创建控制台输出
    final output = ConsoleOutput();

    // 初始化日志器
    _logger = Logger(
      level: Level.debug, // 日志级别为DEBUG
      printer: formatter,
      output: output,
    );
  }

  /// 输出DEBUG级别的日志
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// 输出INFO级别的日志
  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// 输出WARNING级别的日志
  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// 输出ERROR级别的日志
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}

/// 全局日志实例，方便使用
final logger = AppLogger();
