/// 日志级别枚举
enum LogLevel {
  /// 调试级别，仅用于开发
  debug,
  /// 信息级别，用于普通信息
  info,
  /// 警告级别，用于潜在问题
  warning,
  /// 错误级别，用于错误信息
  error,
  /// 严重错误级别，用于致命错误
  critical,
}

/// 日志工具类，提供统一的日志记录机制
class Logger {
  /// 单例实例
  static final Logger _instance = Logger._internal();
  
  /// 工厂构造函数
  factory Logger() => _instance;
  
  /// 内部构造函数
  Logger._internal();
  
  /// 当前日志级别，默认调试级别
  LogLevel _logLevel = LogLevel.debug;
  
  /// 设置日志级别
  void setLogLevel(LogLevel level) {
    _logLevel = level;
  }
  
  /// 记录调试日志
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }
  
  /// 记录信息日志
  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }
  
  /// 记录警告日志
  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }
  
  /// 记录错误日志
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }
  
  /// 记录严重错误日志
  void critical(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.critical, message, error, stackTrace);
  }
  
  /// 实际的日志记录方法
  void _log(LogLevel level, String message, [dynamic error, StackTrace? stackTrace]) {
    // 只记录当前级别及以上的日志
    if (level.index < _logLevel.index) {
      return;
    }
    
    // 格式化日志信息
    final time = DateTime.now().toIso8601String();
    final levelStr = level.toString().split('.').last.toUpperCase();
    
    // 构建日志字符串
    String logStr = '$time [$levelStr] $message';
    
    // 添加错误信息
    if (error != null) {
      logStr += '\nError: $error';
    }
    
    // 添加堆栈跟踪
    if (stackTrace != null) {
      logStr += '\nStack Trace: $stackTrace';
    }
    
    // 在开发环境中打印日志
    if (const bool.fromEnvironment('dart.vm.product') == false) {
      print(logStr);
    }
    
    // TODO: 在生产环境中，可以将日志发送到远程服务器
  }
}

/// 全局日志实例
final logger = Logger();
