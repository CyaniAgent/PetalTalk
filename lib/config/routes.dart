/// 应用路由配置
library;

import 'package:get/get.dart';

import '../ui/pages/login_page.dart';
import '../ui/pages/home_page.dart';
import '../ui/pages/discussion_detail_page.dart';
import '../ui/pages/about_page.dart';
import '../ui/pages/setting_page.dart';
import '../ui/pages/endpoint_selection_page.dart';
import '../ui/pages/notification_page.dart';
import '../ui/pages/profile/my_account_page.dart';
import '../ui/pages/log_viewer_page.dart';
import '../ui/pages/license_page.dart';
import '../ui/pages/welcome_page.dart';

class AppRoutes {
  /// 初始路由
  static const String initialRoute = '/home';

  /// 欢迎页
  static const String welcome = '/welcome';

  /// 登录页
  static const String login = '/login';

  /// 首页
  static const String home = '/home';

  /// 主题帖详情页
  static const String discussionDetail = '/discussion/:id';

  /// 主题模式页
  static const String themeMode = '/theme-mode';

  /// 关于页
  static const String about = '/about';

  /// 设置页
  static const String settings = '/settings';

  /// 端点选择页
  static const String endpoint = '/endpoint';

  /// 通知页
  static const String notifications = '/notifications';

  /// 日志查看页
  static const String logs = '/logs';

  /// 许可证页
  static const String license = '/license';
}

/// 路由配置列表
final List<GetPage> appRoutes = [
  GetPage(name: AppRoutes.login, page: () => const LoginPage()),
  GetPage(name: AppRoutes.home, page: () => const HomePage()),
  GetPage(
    name: AppRoutes.discussionDetail,
    page: () => const DiscussionDetailPage(),
  ),
  GetPage(name: AppRoutes.about, page: () => const AboutPage()),
  GetPage(name: AppRoutes.settings, page: () => const SettingPage()),
  GetPage(name: AppRoutes.endpoint, page: () => const EndpointSelectionPage()),
  GetPage(name: AppRoutes.notifications, page: () => const NotificationList()),
  GetPage(name: '/profile', page: () => const MyAccountPage()),
  GetPage(name: AppRoutes.logs, page: () => const LogViewerPage()),
  GetPage(name: AppRoutes.license, page: () => const AppLicensePage()),
  GetPage(name: AppRoutes.welcome, page: () => const WelcomePage()),
];
