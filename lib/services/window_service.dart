import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// 窗口管理服务类，封装了窗口相关的操作
class WindowService {
  /// 初始化窗口管理器
  static Future<void> initialize() async {
    await windowManager.ensureInitialized();
  }

  /// 配置并显示窗口
  static Future<void> setupWindow() async {
    // 设置窗口属性
    const WindowOptions windowOptions = WindowOptions(
      size: Size(1200, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      title: "PetalTalk",
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  /// 最小化窗口
  static Future<void> minimize() async {
    await windowManager.minimize();
  }

  /// 最大化/还原窗口
  static Future<void> toggleMaximize() async {
    final bool isMaximized = await windowManager.isMaximized();
    if (isMaximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  /// 关闭窗口
  static Future<void> close() async {
    await windowManager.close();
  }

  /// 开始拖动窗口
  static Future<void> startDragging() async {
    await windowManager.startDragging();
  }

  /// 检查窗口是否最大化
  static Future<bool> isMaximized() async {
    return await windowManager.isMaximized();
  }
}
