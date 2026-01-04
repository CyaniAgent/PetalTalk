import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import 'api/flarum_api.dart';
import 'api/services/auth_service.dart';
import 'services/appearance_service.dart';
import 'ui/pages/login_page.dart';
import 'ui/pages/home_page.dart';
import 'ui/pages/discussion_detail_page.dart';
import 'ui/pages/theme_mode_page.dart';
import 'ui/pages/about_page.dart';
// TODO: 消息通知功能待实现
// import 'ui/pages/message_page.dart';
import 'ui/pages/setting_page.dart';
import 'ui/pages/endpoint_selection_page.dart';

void main() async {
  // 确保Flutter绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 创建必要的服务实例
  final api = FlarumApi();
  final authService = AuthService();

  // 加载端点配置
  await api.loadEndpoint();

  // 加载登录信息
  await authService.loadLoginInfo();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThemeSettings();
  }

  Future<void> _loadThemeSettings() async {
    final appearanceService = AppearanceService();
    final themeMode = await appearanceService.loadThemeMode();
    setState(() {
      _themeMode = themeMode;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return GetMaterialApp(
          title: 'Flarum App',
          debugShowCheckedModeBanner: false,
          // 使用chinese_font_library解决中文字体渲染问题
          builder: FlutterSmartDialog.init(),
          theme: ThemeData(
            colorScheme:
                lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
            // 使用系统字体
            fontFamily: 'system',
          ),
          darkTheme: ThemeData(
            colorScheme:
                darkDynamic ??
                ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: Brightness.dark,
                ),
            useMaterial3: true,
            // 使用系统字体
            fontFamily: 'system',
          ),
          themeMode: _themeMode,
          initialRoute: '/endpoint', // 初始路由改为端点选择页
          getPages: [
            GetPage(name: '/login', page: () => const LoginPage()),
            GetPage(name: '/home', page: () => const HomePage()),
            GetPage(
              name: '/discussion/:id',
              page: () => const DiscussionDetailPage(),
            ),
            GetPage(name: '/theme-mode', page: () => const ThemeModePage()),
            GetPage(name: '/about', page: () => const AboutPage()),
            // TODO: 消息通知功能待实现
            // GetPage(name: '/messages', page: () => const MessagePage()),
            GetPage(name: '/settings', page: () => const SettingPage()),
            GetPage(
              name: '/endpoint',
              page: () => const EndpointSelectionPage(),
            ),
          ],
          navigatorObservers: [FlutterSmartDialog.observer],
        );
      },
    );
  }
}
