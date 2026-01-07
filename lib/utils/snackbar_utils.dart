import 'package:flutter/material.dart';

class SnackbarUtils {
  /// 显示MD3风格的提示
  static void showMaterialSnackbar(
    BuildContext context,
    String message, {
    String actionLabel = '',
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
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

  /// 显示"功能开发中"提示
  static void showDevelopmentInProgress(BuildContext context) {
    showMaterialSnackbar(
      context,
      '功能开发中',
      duration: const Duration(seconds: 1),
    );
  }
}
