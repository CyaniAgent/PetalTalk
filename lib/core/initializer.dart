import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/flarum_api.dart';
import '../api/services/auth_service.dart';
import '../config/constants.dart';
import '../core/service_locator.dart';
import '../global_services/window_service.dart';

/// 应用初始化器，负责处理应用启动前的初始化工作
class AppInitializer {
  /// 初始化应用
  static Future<void> init() async {
    // 确保Flutter绑定已初始化
    WidgetsFlutterBinding.ensureInitialized();

    // 初始化服务定位器
    ServiceLocator.init();

    // 获取服务实例
    final api = Get.find<FlarumApi>();
    final authService = Get.find<AuthService>();

    // 初始化并设置窗口
    await WindowService.initialize();
    await WindowService.setupWindow();

    // 加载端点配置
    await api.loadEndpoint();

    // 加载登录信息
    await authService.loadLoginInfo();

    // 检查是否有保存的端点
    final prefs = await SharedPreferences.getInstance();
    final hasEndpoint = prefs.getString(Constants.currentEndpointKey) != null;

    // 如果没有保存的端点，使用默认端点并保存
    if (!hasEndpoint) {
      await api.saveEndpoint(api.baseUrl!);
    }
  }
}
