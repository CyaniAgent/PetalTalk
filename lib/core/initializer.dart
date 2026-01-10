/// 应用初始化器，负责处理应用启动前的所有初始化工作
///
/// 该类在应用启动时被调用，执行以下初始化步骤：
/// 1. 确保Flutter绑定已初始化
/// 2. 初始化服务定位器，注册所有必要服务
/// 3. 初始化并设置窗口
/// 4. 加载端点配置和登录信息
/// 5. 确保应用有有效的端点配置
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/flarum_api.dart';
import '../config/constants.dart';
import '../core/service_locator.dart';
import '../global_services/window_service.dart';
import './cache_service.dart';

/// 应用初始化器类，提供统一的应用初始化入口
class AppInitializer {
  /// 初始化应用，执行所有必要的启动前准备工作
  ///
  /// 该方法是一个异步方法，确保所有初始化工作完成后才启动应用
  ///
  /// 返回值：`Future<void>` - 表示初始化完成
  static Future<void> init() async {
    // 确保Flutter绑定已初始化，这是使用Flutter插件的前提
    WidgetsFlutterBinding.ensureInitialized();

    // 初始化服务定位器，注册所有必要的服务
    ServiceLocator.init();

    // 获取已注册的服务实例
    final api = Get.find<FlarumApi>();

    // 初始化并设置应用窗口
    await WindowService.initialize();
    await WindowService.setupWindow();

    // 初始化缓存服务
    final cacheService = Get.find<CacheService>();
    await cacheService.initialize();

    // 加载端点配置，确定应用要连接的后端服务器
    await api.loadEndpoint();

    // 检查是否有保存的端点配置
    final prefs = await SharedPreferences.getInstance();
    final hasEndpoint = prefs.getString(Constants.currentEndpointKey) != null;

    // 如果没有保存的端点，使用默认端点并保存
    if (!hasEndpoint) {
      await api.saveEndpoint(api.baseUrl!);
    }
  }
}
