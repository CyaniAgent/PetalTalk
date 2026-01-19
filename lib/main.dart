/// PetalTalk应用主入口文件
/// 负责应用的初始化和启动
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/initializer.dart';
import 'global_services/window_service.dart';
import 'global_services/theme_service.dart';
import 'config/routes.dart';
import 'core/logger.dart';
import 'utils/snackbar_utils.dart';

/// 应用主入口函数
void main() {
  // 确保Flutter绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 立即启动应用，让框架尽快渲染第一帧
  // heavy initialization moved to _MyAppState._initializeApp
  runApp(const MyApp());
}

/// 应用根组件，管理应用的主题和窗口状态
class MyApp extends StatefulWidget {
  /// 创建MyApp实例
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

/// MyApp的状态管理类
class _MyAppState extends State<MyApp> {
  /// 当前主题模式
  ThemeMode _themeMode = ThemeMode.system;

  /// 初始化加载状态
  bool _isLoading = true;

  /// 窗口是否最大化
  bool _isMaximized = false;

  /// 初始路由
  String _initialRoute = '/home';

  /// 主题服务实例
  /// 主题服务实例 - 也就是late init
  late final ThemeService _themeService;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// 并行执行初始化任务，提高启动速度
  /// 同时加载主题设置和窗口状态
  Future<void> _initializeApp() async {
    // 1. 初始化日志（非阻塞权限请求）
    await logger.initialize();
    logger.info('应用启动 - UI已挂载');
    final stopwatch = Stopwatch()..start();

    // 2. 初始化核心服务（AppInitializer）
    await AppInitializer.init();

    // 3. 获取服务实例（此时 ServiceLocator 已就绪）
    _themeService = Get.find<ThemeService>();

    final prefs = await SharedPreferences.getInstance();
    final hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;

    // 4. 并行加载 UI 相关状态
    final results = await Future.wait([
      _themeService.loadThemeMode(),
      WindowService.isMaximized(),
    ]);

    stopwatch.stop();
    logger.info('应用初始化全流程完成，耗时: ${stopwatch.elapsedMilliseconds}ms');

    if (mounted) {
      setState(() {
        _themeMode = results[0] as ThemeMode;
        _isMaximized = results[1] as bool;
        _initialRoute = hasSeenWelcome ? '/home' : '/welcome';
        _isLoading = false;
      });
    }
  }

  /// 切换窗口最大化/还原状态
  Future<void> _toggleMaximize() async {
    await WindowService.toggleMaximize();
    setState(() {
      _isMaximized = !_isMaximized;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // 统一的基础主题，用于启动动画
      final baseTheme = ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      );
      return MaterialApp(
        theme: baseTheme,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 应用名称和品牌标识 - 添加 Hero 动画
                Hero(
                  tag: 'app-title',
                  child: Text(
                    'PetalTalk',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: baseTheme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // 加载指示器
                LoadingIndicatorM3E(color: baseTheme.colorScheme.primary),
              ],
            ),
          ),
        ),
      );
    }

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return FutureBuilder(
          future: Future.wait([
            _themeService.createLightTheme(lightDynamic),
            _themeService.createDarkTheme(darkDynamic),
          ]),
          builder: (context, AsyncSnapshot<List<ThemeData>> snapshot) {
            // 统一的基础主题，用于启动动画和错误处理
            final baseTheme = ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            );

            // 错误处理
            if (snapshot.hasError) {
              logger.error(
                '主题创建失败: ${snapshot.error}',
                snapshot.error,
                snapshot.stackTrace,
              );
              return MaterialApp(
                theme: baseTheme,
                home: Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '应用启动失败',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '无法加载主题设置，请重试',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            // 重启应用
                            runApp(const MyApp());
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('重试'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // 加载中，显示启动屏幕
            if (snapshot.connectionState != ConnectionState.done) {
              return MaterialApp(
                theme: baseTheme,
                home: Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 应用名称和品牌标识 - 添加 Hero 动画
                        Hero(
                          tag: 'app-title',
                          child: Text(
                            'PetalTalk',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: baseTheme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // 加载指示器
                        LoadingIndicatorM3E(
                          color: baseTheme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        // 加载提示文本
                        Text(
                          '正在加载应用...',
                          style: TextStyle(
                            color: baseTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final finalLightTheme = snapshot.data![0];
            final finalDarkTheme = snapshot.data![1];

            // 主题加载完成，直接显示主应用，移除过渡动画
            return GetMaterialApp(
              title: 'PetalTalk',
              debugShowCheckedModeBanner: false,
              builder: (context, child) {
                // 初始化SnackbarUtils
                SnackbarUtils.init(ScaffoldMessenger.of(context));

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
                            onDoubleTap: _toggleMaximize,
                            child: Container(
                              color:
                                  Theme.of(
                                    context,
                                  ).appBarTheme.backgroundColor ??
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
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
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
                                    onPressed: _toggleMaximize,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    padding: EdgeInsets.zero,
                                    splashRadius: 15,
                                  ),
                                  // 关闭按钮
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 14),
                                    onPressed: () => WindowService.close(),
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
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
              initialRoute: _initialRoute, // 使用动态计算的初始路由
              getPages: appRoutes, // 使用统一的路由配置列表
              navigatorObservers: [FlutterSmartDialog.observer],
            );
          },
        );
      },
    );
  }
}
