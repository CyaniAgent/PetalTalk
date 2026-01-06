import 'package:get/get.dart';

import '../api/flarum_api.dart';
import '../api/services/auth_service.dart';
import '../api/services/discussion_service.dart';
import '../api/services/notification_service.dart';
import '../api/services/post_service.dart';
import '../api/services/user_service.dart';
import '../global_services/appearance_service.dart';
import '../global_services/theme_service.dart';
import '../global_services/window_service.dart';
import '../state/main_state.dart';
import '../state/setting_state.dart';

/// 服务定位器，用于注册和管理应用中的所有服务
class ServiceLocator {
  /// 初始化服务定位器，注册所有服务
  static void init() {
    // API服务
    Get.put(FlarumApi(), permanent: true);
    Get.put(AuthService(), permanent: true);
    Get.put(DiscussionService(), permanent: true);
    Get.put(NotificationService(), permanent: true);
    Get.put(PostService(), permanent: true);
    Get.put(UserService(), permanent: true);

    // 全局服务
    Get.put(WindowService(), permanent: true);
    Get.put(ThemeService(), permanent: true);
    Get.put(AppearanceService(), permanent: true);

    // 状态管理
    Get.put(UiMainController(), permanent: true);
  }
}
