import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import 'api/flarum_api.dart';
import 'api/services/auth_service.dart';
import 'services/window_service.dart';
import 'services/theme_service.dart';
import 'services/appearance_service.dart';
import 'routes/routes.dart';

void main() async {
  // 确保Flutter绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化并设置窗口
  await WindowService.initialize();
  await WindowService.setupWindow();

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
  final ThemeService _themeService = ThemeService();

  // 主题偏好设置
  bool _useDynamicColor = true;
  String _accentColor = 'blue';

  // 预创建的主题对象
  ThemeData? _lightTheme;
  ThemeData? _darkTheme;

  @override
  void initState() {
    super.initState();
    _loadThemeSettings();
    _checkWindowState();
  }

  Future<void> _loadThemeSettings() async {
    final themeMode = await _themeService.loadThemeMode();
    final appearanceService = AppearanceService();
    final useDynamicColor = await appearanceService.loadUseDynamicColor();
    final accentColor = await appearanceService.loadAccentColor();

    // 预创建默认主题
    final lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      useMaterial3: true,
      fontFamily: 'system',
      appBarTheme: const AppBarTheme(elevation: 0),
    );

    final darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      fontFamily: 'system',
      appBarTheme: const AppBarTheme(elevation: 0),
    );

    setState(() {
      _themeMode = themeMode;
      _useDynamicColor = useDynamicColor;
      _accentColor = accentColor;
      _lightTheme = lightTheme;
      _darkTheme = darkTheme;
      _isLoading = false;
    });
  }

  // 检查窗口初始状态
  Future<void> _checkWindowState() async {
    bool isMaximized = await WindowService.isMaximized();
    setState(() {
      _isMaximized = isMaximized;
    });
  }

  // 切换窗口最大化/还原
  Future<void> _toggleMaximize() async {
    await WindowService.toggleMaximize();
    setState(() {
      _isMaximized = !_isMaximized;
    });
  }

  /// 根据字符串名称获取强调色
  Color _getAccentColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'pink':
        return Colors.pink;
      case 'purple':
        return Colors.purple;
      case 'indigo':
        return Colors.indigo;
      case 'blue':
        return Colors.blue;
      case 'cyan':
        return Colors.cyan;
      case 'teal':
        return Colors.teal;
      case 'green':
        return Colors.green;
      case 'lime':
        return Colors.lime;
      case 'yellow':
        return Colors.yellow;
      case 'amber':
        return Colors.amber;
      case 'orange':
        return Colors.orange;
      case 'deeporange':
        return Colors.deepOrange;
      default:
        return Colors.blue;
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
        // 根据用户偏好和动态颜色创建最终主题
        final accentColor = _getAccentColorFromString(_accentColor);

        // 亮色主题
        final finalLightTheme = _lightTheme!.copyWith(
          colorScheme: _useDynamicColor && lightDynamic != null
              ? lightDynamic
              : ColorScheme.fromSeed(seedColor: accentColor),
        );

        // 暗色主题
        final finalDarkTheme = _darkTheme!.copyWith(
          colorScheme: _useDynamicColor && darkDynamic != null
              ? darkDynamic
              : ColorScheme.fromSeed(
                  seedColor: accentColor,
                  brightness: Brightness.dark,
                ),
        );

        return GetMaterialApp(
          title: 'PetalTalk',
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            // 检测是否为桌面平台
            final bool isDesktop =
                Platform.isWindows || Platform.isMacOS || Platform.isLinux;
            // 仅在桌面平台显示标题栏
            const double titleBarHeight = 30.0;
            final double actualTitleBarHeight = isDesktop
                ? titleBarHeight
                : 0.0;

            return SizedBox.expand(
              child: Stack(
                children: [
                  // 应用主体内容，添加顶部偏移以避免被标题栏遮挡
                  Positioned.fill(
                    top: actualTitleBarHeight,
                    child: FlutterSmartDialog.init()(context, child),
                  ),
                  // 仅在桌面平台显示自定义标题栏
                  if (isDesktop)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: titleBarHeight,
                      child: GestureDetector(
                        // 实现窗口拖动
                        onPanStart: (details) async {
                          await WindowService.startDragging();
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
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
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
                                onPressed: () => WindowService.minimize(),
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
                                onPressed: () => WindowService.close(),
                                color: Theme.of(context).colorScheme.onSurface,
                                padding: EdgeInsets.zero,
                                splashRadius: 15,
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
          theme: finalLightTheme,
          darkTheme: finalDarkTheme,
          themeMode: _themeMode,
          initialRoute: AppRoutes.initialRoute, // 使用统一的初始路由配置
          getPages: appRoutes, // 使用统一的路由配置列表
          navigatorObservers: [FlutterSmartDialog.observer],
        );
      },
    );
  }
}
