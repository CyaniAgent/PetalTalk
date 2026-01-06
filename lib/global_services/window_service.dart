import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowService {
  // 检查是否为桌面平台
  static bool get isDesktop {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  // 初始化窗口管理器
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

  // 设置窗口属性
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

  // 最小化窗口
  static Future<void> minimize() async {
    if (isDesktop) {
      try {
        await windowManager.minimize();
      } catch (_) {
        // 忽略任何异常
      }
    }
  }

  // 最大化窗口
  static Future<void> maximize() async {
    if (isDesktop) {
      try {
        await windowManager.maximize();
      } catch (_) {
        // 忽略任何异常
      }
    }
  }

  // 还原窗口
  static Future<void> restore() async {
    if (isDesktop) {
      try {
        await windowManager.restore();
      } catch (_) {
        // 忽略任何异常
      }
    }
  }

  // 切换最大化/还原状态
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

  // 检查窗口是否最大化
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

  // 开始拖动窗口
  static Future<void> startDragging() async {
    if (isDesktop) {
      try {
        await windowManager.startDragging();
      } catch (_) {
        // 忽略任何异常
      }
    }
  }

  // 关闭窗口
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
