/// 窗口服务，负责管理应用窗口的各种操作
///
/// 该服务提供：
/// 1. 跨平台窗口管理功能
/// 2. 桌面平台检测
/// 3. 窗口状态控制（最小化、最大化、还原、关闭等）
/// 4. 窗口拖动支持
///
/// 注意：该服务的大部分功能仅在桌面平台（Windows、macOS、Linux）上有效
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// 窗口服务类，提供跨平台窗口管理功能
class WindowService {
  /// 检查当前平台是否为桌面平台
  ///
  /// 返回值：
  /// - bool: 如果是桌面平台（Windows、macOS、Linux）返回true，否则返回false
  static bool get isDesktop {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// 初始化窗口管理器
  ///
  /// 该方法仅在桌面平台上执行，负责初始化窗口管理器
  static Future<void> initialize() async {
    // 只在桌面平台上尝试初始化
    if (isDesktop) {
      try {
        // 使用try-catch包裹所有可能的调用
        await windowManager.ensureInitialized();
      } catch (_) {
        // 忽略任何异常
      }
    }
  }

  /// 设置窗口属性
  ///
  /// 该方法仅在桌面平台上执行，负责：
  /// 1. 配置窗口的最小尺寸、初始尺寸等属性
  /// 2. 设置窗口标题和样式
  /// 3. 显示并聚焦窗口
  static Future<void> setupWindow() async {
    if (isDesktop) {
      try {
        WindowOptions windowOptions = WindowOptions(
          minimumSize: const Size(800, 600),
          size: const Size(1300, 800),
          title: 'PetalTalk',
          center: true,
          backgroundColor: Colors.transparent,
          skipTaskbar: false,
          titleBarStyle: TitleBarStyle.hidden,
        );
        windowManager.waitUntilReadyToShow(windowOptions, () async {
          try {
            await windowManager.show();
            await windowManager.focus();
          } catch (_) {
            // 忽略任何异常
          }
        });
      } catch (_) {
        // 忽略任何异常
      }
    }
  }

  /// 最小化窗口
  ///
  /// 该方法仅在桌面平台上执行
  static Future<void> minimize() async {
    if (isDesktop) {
      try {
        await windowManager.minimize();
      } catch (_) {
        // 忽略任何异常
      }
    }
  }

  /// 最大化窗口
  ///
  /// 该方法仅在桌面平台上执行
  static Future<void> maximize() async {
    if (isDesktop) {
      try {
        await windowManager.maximize();
      } catch (_) {
        // 忽略任何异常
      }
    }
  }

  /// 还原窗口（从最大化或最小化状态）
  ///
  /// 该方法仅在桌面平台上执行
  static Future<void> restore() async {
    if (isDesktop) {
      try {
        await windowManager.restore();
      } catch (_) {
        // 忽略任何异常
      }
    }
  }

  /// 切换窗口的最大化/还原状态
  ///
  /// 如果窗口当前是最大化状态，则还原为正常大小
  /// 如果窗口当前是正常大小，则最大化
  ///
  /// 该方法仅在桌面平台上执行
  static Future<void> toggleMaximize() async {
    if (isDesktop) {
      try {
        bool isMaximized = await windowManager.isMaximized();
        if (isMaximized) {
          await windowManager.restore();
        } else {
          await windowManager.maximize();
        }
      } catch (_) {
        // 忽略任何异常
      }
    }
  }

  /// 检查窗口是否处于最大化状态
  ///
  /// 返回值：
  /// - `Future<bool>`: 窗口处于最大化状态返回true，否则返回false
  ///
  /// 该方法仅在桌面平台上执行，非桌面平台始终返回false
  static Future<bool> isMaximized() async {
    if (isDesktop) {
      try {
        return await windowManager.isMaximized();
      } catch (_) {
        // 忽略任何异常
      }
    }
    return false;
  }

  /// 开始拖动窗口
  ///
  /// 该方法仅在桌面平台上执行，用于实现自定义标题栏的拖动功能
  static Future<void> startDragging() async {
    if (isDesktop) {
      try {
        await windowManager.startDragging();
      } catch (_) {
        // 忽略任何异常
      }
    }
  }

  /// 关闭应用窗口
  ///
  /// 该方法仅在桌面平台上执行
  static Future<void> close() async {
    if (isDesktop) {
      try {
        await windowManager.close();
      } catch (_) {
        // 忽略任何异常
      }
    }
  }
}
