import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:window_manager/window_manager.dart';

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
import 'ui/pages/create_discussion_page.dart';

void main() async {
  // 确保Flutter绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化window_manager
  await windowManager.ensureInitialized();

  // 设置窗口属性
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    title: "PetalTalk",
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

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
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    _loadThemeSettings();
    _checkWindowState();
  }

  Future<void> _loadThemeSettings() async {
    final appearanceService = AppearanceService();
    final themeMode = await appearanceService.loadThemeMode();
    setState(() {
      _themeMode = themeMode;
      _isLoading = false;
    });
  }

  // 检查窗口初始状态
  Future<void> _checkWindowState() async {
    bool isMaximized = await windowManager.isMaximized();
    setState(() {
      _isMaximized = isMaximized;
    });
  }

  // 切换窗口最大化/还原
  Future<void> _toggleMaximize() async {
    bool isMaximized = await windowManager.isMaximized();
    if (isMaximized) {
      await windowManager.unmaximize();
      setState(() {
        _isMaximized = false;
      });
    } else {
      await windowManager.maximize();
      setState(() {
        _isMaximized = true;
      });
    }
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
          title: 'PetalTalk',
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            const titleBarHeight = 30.0;

            return SizedBox.expand(
              child: Stack(
                children: [
                  // 应用主体内容，添加顶部padding以避免被标题栏遮挡
                  Positioned.fill(
                    top: titleBarHeight,
                    child: FlutterSmartDialog.init()(context, child),
                  ),
                  // 自定义标题栏，固定在顶部
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: titleBarHeight,
                    child: GestureDetector(
                      // 实现窗口拖动
                      onPanStart: (details) async {
                        await windowManager.startDragging();
                      },
                      // 双击标题栏最大化/还原
                      onDoubleTap: () => _toggleMaximize(),
                      child: Container(
                        color:
                            Theme.of(context).appBarTheme.backgroundColor ??
                            Theme.of(context).colorScheme.surface,
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'PetalTalk',
                                  style: TextStyle(
                                    color:
                                        Theme.of(
                                          context,
                                        ).appBarTheme.foregroundColor ??
                                        Theme.of(context).colorScheme.onSurface,
                                    fontSize: 14,
                                    decoration: TextDecoration.none,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                            // 最小化按钮
                            IconButton(
                              icon: const Icon(Icons.minimize, size: 14),
                              onPressed: () => windowManager.minimize(),
                              color: Theme.of(context).colorScheme.onSurface,
                              padding: EdgeInsets.zero,
                              splashRadius: 15,
                            ),
                            // 最大化/还原按钮，根据窗口状态动态改变图标
                            IconButton(
                              icon: Icon(
                                _isMaximized
                                    ? Icons.fullscreen_exit
                                    : Icons.fullscreen,
                                size: 14,
                              ),
                              onPressed: () => _toggleMaximize(),
                              color: Theme.of(context).colorScheme.onSurface,
                              padding: EdgeInsets.zero,
                              splashRadius: 15,
                            ),
                            // 关闭按钮
                            IconButton(
                              icon: const Icon(Icons.close, size: 14),
                              onPressed: () => windowManager.close(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          theme: ThemeData(
            colorScheme:
                lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
            // 使用系统字体
            fontFamily: 'system',
            appBarTheme: const AppBarTheme(elevation: 0),
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
            appBarTheme: const AppBarTheme(elevation: 0),
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
            GetPage(
              name: '/create-discussion',
              page: () => const CreateDiscussionPage(),
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
