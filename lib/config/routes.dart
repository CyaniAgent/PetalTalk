import 'package:get/get.dart';

import '../ui/pages/login_page.dart';
import '../ui/pages/home_page.dart';
import '../ui/pages/discussion_detail_page.dart';
import '../ui/pages/theme_mode_page.dart';
import '../ui/pages/about_page.dart';
// TODO: 消息通知功能待实现
// import '../ui/pages/message_page.dart';
import '../ui/pages/setting_page.dart';
import '../ui/pages/endpoint_selection_page.dart';
import '../ui/pages/create_discussion_page.dart';

/// 应用路由配置
class AppRoutes {
  /// 初始路由
  static const String initialRoute = '/endpoint';
  
  /// 登录页
  static const String login = '/login';
  
  /// 首页
  static const String home = '/home';
  
  /// 主题帖详情页
  static const String discussionDetail = '/discussion/:id';
  
  /// 创建主题帖页
  static const String createDiscussion = '/create-discussion';
  
  /// 主题模式页
  static const String themeMode = '/theme-mode';
  
  /// 关于页
  static const String about = '/about';
  
  /// 设置页
  static const String settings = '/settings';
  
  /// 端点选择页
  static const String endpoint = '/endpoint';
}

/// 路由配置列表
final List<GetPage> appRoutes = [
  GetPage(name: AppRoutes.login, page: () => const LoginPage()),
  GetPage(name: AppRoutes.home, page: () => const HomePage()),
  GetPage(
    name: AppRoutes.discussionDetail,
    page: () => const DiscussionDetailPage(),
  ),
  GetPage(
    name: AppRoutes.createDiscussion,
    page: () => const CreateDiscussionPage(),
  ),
  GetPage(name: AppRoutes.themeMode, page: () => const ThemeModePage()),
  GetPage(name: AppRoutes.about, page: () => const AboutPage()),
  // TODO: 消息通知功能待实现
  // GetPage(name: AppRoutes.messages, page: () => const MessagePage()),
  GetPage(name: AppRoutes.settings, page: () => const SettingPage()),
  GetPage(name: AppRoutes.endpoint, page: () => const EndpointSelectionPage()),
];
