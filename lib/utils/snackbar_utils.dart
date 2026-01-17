/// Snackbar工具类，提供MD3风格的全局提示功能
///
/// 该工具类提供：
/// 1. 全局Snackbar管理，无需每次传递BuildContext
/// 2. 支持多种提示类型（成功、错误、警告、信息）
/// 3. MD3风格的现代设计
/// 4. 可配置的动作按钮
/// 5. 灵活的持续时间设置
/// 6. 安全的初始化检查
library;

import 'package:flutter/material.dart';
import '../core/logger.dart';

/// Snackbar类型枚举，定义不同类型的提示样式
enum SnackbarType { 
  /// 成功提示，通常显示绿色样式
  success, 
  
  /// 错误提示，通常显示红色样式
  error, 
  
  /// 警告提示，通常显示黄色样式
  warning, 
  
  /// 信息提示，通常显示蓝色样式
  info 
}

/// Snackbar工具类，提供全局的MD3风格提示功能
class SnackbarUtils {
  /// 静态全局ScaffoldMessengerState实例，用于在没有BuildContext时显示Snackbar
  static ScaffoldMessengerState? _scaffoldMessenger;

  /// 初始化全局ScaffoldMessengerState
  ///
  /// 应该在应用启动时调用，例如在MaterialApp的builder中
  /// 
  /// [scaffoldMessenger] - 全局ScaffoldMessengerState实例
  static void init(ScaffoldMessengerState scaffoldMessenger) {
    _scaffoldMessenger = scaffoldMessenger;
  }

  /// 显示MD3风格的提示
  ///
  /// [message] - 要显示的消息内容
  /// [type] - 提示类型，默认为信息类型
  /// [actionLabel] - 动作按钮文本，为空则不显示动作按钮
  /// [onAction] - 动作按钮点击回调
  /// [duration] - 提示显示持续时间，默认为2秒
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
  ///
  /// [message] - 要显示的成功消息
  /// [actionLabel] - 动作按钮文本，为空则不显示动作按钮
  /// [onAction] - 动作按钮点击回调
  /// [duration] - 提示显示持续时间，默认为2秒
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
  ///
  /// [message] - 要显示的错误消息
  /// [actionLabel] - 动作按钮文本，为空则不显示动作按钮
  /// [onAction] - 动作按钮点击回调
  /// [duration] - 提示显示持续时间，默认为3秒
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
  ///
  /// [message] - 要显示的警告消息
  /// [actionLabel] - 动作按钮文本，为空则不显示动作按钮
  /// [onAction] - 动作按钮点击回调
  /// [duration] - 提示显示持续时间，默认为2秒
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
  ///
  /// [message] - 要显示的信息消息
  /// [actionLabel] - 动作按钮文本，为空则不显示动作按钮
  /// [onAction] - 动作按钮点击回调
  /// [duration] - 提示显示持续时间，默认为2秒
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
  ///
  /// 用于快速显示功能正在开发中的提示，持续时间为1秒
  static void showDevelopmentInProgress() {
    showInfo('功能开发中', duration: const Duration(seconds: 1));
  }
}
