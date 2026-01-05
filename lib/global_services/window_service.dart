import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowService {
  // 初始化窗口管理器
  static Future<void> initialize() async {
    await windowManager.ensureInitialized();
  }

  // 设置窗口属性
  static Future<void> setupWindow() async {
    WindowOptions windowOptions = WindowOptions(
      minimumSize: const Size(1300, 800),
      size: const Size(1300, 800),
      title: 'PetalTalk',
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // 最小化窗口
  static Future<void> minimize() async {
    await windowManager.minimize();
  }

  // 最大化窗口
  static Future<void> maximize() async {
    await windowManager.maximize();
  }

  // 还原窗口
  static Future<void> restore() async {
    await windowManager.restore();
  }

  // 切换最大化/还原状态
  static Future<void> toggleMaximize() async {
    bool isMaximized = await windowManager.isMaximized();
    if (isMaximized) {
      await windowManager.restore();
    } else {
      await windowManager.maximize();
    }
  }

  // 检查窗口是否最大化
  static Future<bool> isMaximized() async {
    return await windowManager.isMaximized();
  }

  // 开始拖动窗口
  static Future<void> startDragging() async {
    await windowManager.startDragging();
  }

  // 关闭窗口
  static Future<void> close() async {
    await windowManager.close();
  }
}
