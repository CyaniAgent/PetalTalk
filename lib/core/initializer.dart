/// 应用初始化器，负责处理应用启动前的所有初始化工作
///
/// 该类在应用启动时被调用，执行以下初始化步骤：
/// 1. 确保Flutter绑定已初始化
/// 2. 初始化服务定位器，注册所有必要服务
/// 3. 初始化并设置窗口
/// 4. 加载端点配置和登录信息
/// 5. 确保应用有有效的端点配置
library;

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/flarum_api.dart';
import '../config/constants.dart';
import '../core/service_locator.dart';
import '../global_services/window_service.dart';
import '../global_services/notification_service.dart';
import './cache_service.dart';
import './logger.dart';

/// 应用初始化器类，提供统一的应用初始化入口
class AppInitializer {
  /// 初始化应用，执行所有必要的启动前准备工作
  ///
  /// 该方法是一个异步方法，确保所有初始化工作完成后才启动应用
  ///
  /// 返回值：`Future<void>` - 表示初始化完成
  static Future<void> init() async {
    // 记录初始化开始时间
    final stopwatch = Stopwatch()..start();
    logger.info('初始化开始');

    // 初始化服务定位器，注册所有必要的服务
    ServiceLocator.init();
    logger.info('服务定位器初始化完成，耗时: ${stopwatch.elapsedMilliseconds}ms');

    // 获取已注册的服务实例
    final api = Get.find<FlarumApi>();
    final cacheService = Get.find<CacheService>();

    // 并行初始化独立服务，提高初始化速度
    await Future.wait([
      // 初始化窗口（桌面平台）
      _initWindow(),

      // 初始化缓存服务
      cacheService.initialize().then((_) {
        logger.info('缓存服务初始化完成，耗时: ${stopwatch.elapsedMilliseconds}ms');
      }),

      // 初始化通知服务
      GlobalNotificationService().initialize().then((_) {
        logger.info('通知服务初始化完成，耗时: ${stopwatch.elapsedMilliseconds}ms');
      }),

      // 加载端点配置，确定应用要连接的后端服务器
      api.loadEndpoint().then((_) {
        logger.info('端点配置加载完成，耗时: ${stopwatch.elapsedMilliseconds}ms');
      }),
    ]);

    // 检查是否有保存的端点配置
    final prefs = await SharedPreferences.getInstance();
    final hasEndpoint = prefs.getString(Constants.currentEndpointKey) != null;

    // 如果没有保存的端点，使用默认端点并保存
    if (!hasEndpoint) {
      await api.saveEndpoint(api.baseUrl!);
      logger.info('默认端点保存完成，耗时: ${stopwatch.elapsedMilliseconds}ms');
    }

    // 记录初始化完成时间
    stopwatch.stop();
    logger.info('初始化完成，总耗时: ${stopwatch.elapsedMilliseconds}ms');
  }

  /// 初始化窗口，仅在桌面平台上执行
  static Future<void> _initWindow() async {
    if (WindowService.isDesktop) {
      await WindowService.initialize();
      await WindowService.setupWindow();
    }
  }
}
