/// 服务定位器，负责集中管理应用中的所有服务
/// 使用GetX的依赖注入机制，确保服务的单例性和一致性
library;

import 'package:get/get.dart';

import '../api/flarum_api.dart';
import '../api/services/auth_service.dart';
import '../global_services/window_service.dart';
import '../global_services/theme_service.dart';
import '../state/main_state.dart';

/// 服务定位器类，提供统一的服务注册和管理
class ServiceLocator {
  /// 初始化服务定位器，注册所有必要的服务
  /// 
  /// 该方法会注册以下类型的服务：
  /// 1. API服务 - 用于与后端通信
  /// 2. 全局服务 - 提供跨组件的通用功能
  /// 3. 状态管理服务 - 管理应用的全局状态
  /// 
  /// 所有服务都注册为永久单例，确保在应用生命周期内只创建一次
  static void init() {
    // 注册API服务
    Get.put(FlarumApi(), permanent: true);
    Get.put(AuthService(), permanent: true);

    // 注册全局服务
    Get.put(WindowService(), permanent: true);
    Get.put(ThemeService(), permanent: true);

    // 注册状态管理服务
    Get.put(UiMainController(), permanent: true);
  }
}
