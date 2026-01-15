/// 日志工具类，负责应用中的日志输出和管理
///
/// 该类提供：
/// 1. 不同级别的日志输出（DEBUG, INFO, WARNING, ERROR）
/// 2. 控制台和文件双输出
/// 3. 动态日志级别调整
/// 4. 日志文件管理（大小限制、清理等）
library;

import 'dart:async';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import '../config/constants.dart';

/// 日志工具类，管理应用中的所有日志输出
class AppLogger {
  /// 单例实例
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  /// 日志实例
  late Logger _logger;

  /// 文件输出实例
  late final AppFileOutput _fileOutput;

  /// 当前日志级别
  Level _currentLevel = Level.error;

  /// 日志文件路径
  String? _logFilePath;

  /// 初始化日志配置
  Future<void> initialize() async {
    // 创建控制台输出
    final consoleOutput = ConsoleOutput();

    // 创建文件输出
    _fileOutput = await _createFileOutput();

    // 初始化日志器
    _logger = Logger(
      level: _currentLevel, // 初始日志级别
      output: AppMultiOutput([consoleOutput, _fileOutput]),
      printer: SimplePrinter(),
    );
  }

  /// 创建文件输出
  Future<AppFileOutput> _createFileOutput() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _logFilePath = '${directory.path}/app_logs.txt';
      final file = File(_logFilePath!);

      // 确保文件存在
      if (!file.existsSync()) {
        file.createSync(recursive: true);
      }

      // 检查文件大小，超过限制则清理
      await _checkAndCleanLogFile(file);

      return AppFileOutput(
        file: file,
        overrideExisting: false,
        mode: FileMode.append,
      );
    } catch (e) {
      // 如果文件创建失败，返回控制台输出
      return AppFileOutput(
        file: File('./app_logs.txt'),
        overrideExisting: false,
        mode: FileMode.append,
      );
    }
  }

  /// 检查并清理日志文件
  Future<void> _checkAndCleanLogFile(File file) async {
    try {
      final stat = await file.stat();
      final maxSize = Constants.defaultMaxLogSize * 1024 * 1024; // MB to bytes

      if (stat.size > maxSize) {
        // 超过限制，保留最后50%内容
        final lines = await file.readAsLines();
        final keepLines = (lines.length * 0.5).round();
        final newContent = lines.skip(lines.length - keepLines).join('\n');
        await file.writeAsString(newContent);
      }
    } catch (e) {
      // 忽略清理错误
    }
  }

  /// 设置日志级别
  void setLogLevel(String level) {
    switch (level.toLowerCase()) {
      case 'debug':
        _currentLevel = Level.debug;
        break;
      case 'info':
        _currentLevel = Level.info;
        break;
      case 'warning':
      case 'warn':
        _currentLevel = Level.warning;
        break;
      case 'error':
        _currentLevel = Level.error;
        break;
      default:
        _currentLevel = Level.error;
    }

    // 创建控制台输出
    final consoleOutput = ConsoleOutput();

    // 重新创建日志器以更新级别
    _logger = Logger(
      level: _currentLevel,
      output: AppMultiOutput([consoleOutput, _fileOutput]),
      printer: SimplePrinter(),
    );
  }

  /// 获取日志文件路径
  String? get logFilePath => _logFilePath;

  /// 查看日志内容
  Future<List<String>> viewLogs() async {
    try {
      if (_logFilePath == null) await initialize();
      final file = File(_logFilePath!);
      if (file.existsSync()) {
        return file.readAsLines();
      }
    } catch (e) {
      // 忽略错误
    }
    return [];
  }

  /// 导出日志
  Future<File?> exportLogs() async {
    try {
      if (_logFilePath == null) await initialize();
      final sourceFile = File(_logFilePath!);
      if (sourceFile.existsSync()) {
        // 创建导出目录
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final exportPath = '${directory.path}/logs_$timestamp.txt';
        final exportFile = File(exportPath);

        // 复制文件
        await sourceFile.copy(exportPath);
        return exportFile;
      }
    } catch (e) {
      // 忽略错误
    }
    return null;
  }

  /// 删除日志
  Future<void> deleteLogs() async {
    try {
      if (_logFilePath == null) await initialize();
      final file = File(_logFilePath!);
      if (file.existsSync()) {
        await file.writeAsString('');
      }
    } catch (e) {
      // 忽略错误
    }
  }

  /// 设置最大日志大小
  Future<void> setMaxLogSize(int maxSizeMB) async {
    try {
      if (_logFilePath == null) await initialize();
      final file = File(_logFilePath!);
      if (file.existsSync()) {
        final maxSize = maxSizeMB * 1024 * 1024; // MB to bytes
        final stat = await file.stat();
        if (stat.size > maxSize) {
          await _checkAndCleanLogFile(file);
        }
      }
    } catch (e) {
      // 忽略错误
    }
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

/// 文件输出类
class AppFileOutput extends LogOutput {
  final File file;
  final bool overrideExisting;
  final FileMode mode;
  IOSink? _sink;

  AppFileOutput({
    required this.file,
    this.overrideExisting = false,
    this.mode = FileMode.write,
  });

  @override
  Future<void> init() async {
    if (_sink != null) return;
    if (overrideExisting) {
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
    file.createSync(recursive: true);
    _sink = file.openWrite(mode: mode);
  }

  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      _sink?.writeln(line);
    }
  }

  @override
  Future<void> destroy() async {
    await _sink?.close();
  }
}

/// 多输出类
class AppMultiOutput extends LogOutput {
  final List<LogOutput> outputs;

  AppMultiOutput(this.outputs);

  @override
  Future<void> init() async {
    for (var output in outputs) {
      await output.init();
    }
  }

  @override
  void output(OutputEvent event) {
    for (var output in outputs) {
      output.output(event);
    }
  }

  @override
  Future<void> destroy() async {
    for (var output in outputs) {
      await output.destroy();
    }
  }
}
