import 'package:flutter/material.dart';
import '../core/logger.dart';

/// Snackbar类型枚举
enum SnackbarType { success, error, warning, info }

class SnackbarUtils {
  /// 静态全局ScaffoldMessengerState实例，用于在没有BuildContext时显示Snackbar
  static ScaffoldMessengerState? _scaffoldMessenger;

  /// 初始化全局ScaffoldMessengerState
  /// 应该在应用启动时调用，例如在MaterialApp的builder中
  static void init(ScaffoldMessengerState scaffoldMessenger) {
    _scaffoldMessenger = scaffoldMessenger;
  }

  /// 显示MD3风格的提示
  static void showSnackbar(
    String message, {
    SnackbarType type = SnackbarType.info,
    String actionLabel = '',
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 2),
  }) {
    // 检查全局ScaffoldMessengerState是否已初始化
    if (_scaffoldMessenger == null) {
      // 记录警告日志，便于调试
      logger.warning(
        'SnackbarUtils: _scaffoldMessenger is null. Please call SnackbarUtils.init() first.',
      );
      // 生产环境中静默失败，避免崩溃
      return;
    }

    _scaffoldMessenger!.showSnackBar(
      SnackBar(
        content: Text(message),
        action: actionLabel.isNotEmpty && onAction != null
            ? SnackBarAction(label: actionLabel, onPressed: onAction)
            : null,
        duration: duration,
        // MD3风格配置
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// 显示成功提示
  static void showSuccess(
    String message, {
    String actionLabel = '',
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 2),
  }) {
    showSnackbar(
      message,
      type: SnackbarType.success,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// 显示错误提示
  static void showError(
    String message, {
    String actionLabel = '',
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    showSnackbar(
      message,
      type: SnackbarType.error,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// 显示警告提示
  static void showWarning(
    String message, {
    String actionLabel = '',
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 2),
  }) {
    showSnackbar(
      message,
      type: SnackbarType.warning,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// 显示信息提示
  static void showInfo(
    String message, {
    String actionLabel = '',
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 2),
  }) {
    showSnackbar(
      message,
      type: SnackbarType.info,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// 显示"功能开发中"提示
  static void showDevelopmentInProgress() {
    showInfo('功能开发中', duration: const Duration(seconds: 1));
  }
}
