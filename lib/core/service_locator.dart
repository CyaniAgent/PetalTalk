/// 服务定位器，负责集中管理应用中的所有服务
/// 使用GetX的依赖注入机制，确保服务的单例性和一致性
library;

import 'package:get/get.dart';

import '../api/flarum_api.dart';
import '../api/services/auth_service.dart';
import '../api/services/discussion_service.dart';
import '../api/services/notification_service.dart';
import '../api/services/post_service.dart';
import '../global_services/window_service.dart';
import '../global_services/theme_service.dart';
import '../global_services/notification_service.dart';
import '../state/main_state.dart';
import './cache_service.dart';

/// 服务定位器类，提供统一的服务注册和管理
class ServiceLocator {
  /// 初始化服务定位器，注册所有必要的服务
  ///
  /// 该方法会注册以下类型的服务：
  /// 1. 全局服务 - 提供跨组件的通用功能
  /// 2. 状态管理服务 - 管理应用的全局状态
  /// 3. API服务 - 用于与后端通信
  ///
  /// 关键服务注册为永久单例，确保在应用生命周期内只创建一次
  /// 非关键服务使用懒加载，只有在实际使用时才创建实例
  static void init() {
    // 先注册基础服务和全局服务，确保它们在依赖它们的服务之前被注册

    // 注册关键全局服务（永久单例）
    Get.put(WindowService(), permanent: true);
    Get.put(ThemeService(), permanent: true);
    Get.put(CacheService(), permanent: true);
    Get.put(GlobalNotificationService(), permanent: true);

    // 注册核心API服务（依赖CacheService，永久单例）
    Get.put(FlarumApi(), permanent: true);

    // 注册状态管理服务（永久单例）
    Get.put(UiMainController(), permanent: true);

    // 注册非关键API服务（懒加载，只有在实际使用时才创建实例）
    Get.lazyPut(() => AuthService(), fenix: true);
    Get.lazyPut(() => DiscussionService(), fenix: true);
    Get.lazyPut(() => NotificationService(), fenix: true);
    Get.lazyPut(() => PostService(), fenix: true);
  }
}
