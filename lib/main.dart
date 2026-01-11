/// PetalTalk应用主入口文件
/// 负责应用的初始化和启动
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:m3e_collection/m3e_collection.dart';

import 'core/initializer.dart';
import 'global_services/window_service.dart';
import 'global_services/theme_service.dart';
import 'config/routes.dart';
import 'core/logger.dart';

/// 应用主入口函数
void main() async {
  // 记录应用启动开始时间
  final stopwatch = Stopwatch()..start();
  logger.info('应用启动开始');

  // 初始化应用
  await AppInitializer.init();
  logger.info('应用初始化完成，耗时: ${stopwatch.elapsedMilliseconds}ms');

  // 启动应用
  runApp(const MyApp());

  // 记录应用启动完成时间
  stopwatch.stop();
  logger.info('应用启动完成，总耗时: ${stopwatch.elapsedMilliseconds}ms');
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

  /// 主题服务实例
  final ThemeService _themeService = Get.find<ThemeService>();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// 并行执行初始化任务，提高启动速度
  /// 同时加载主题设置和窗口状态
  Future<void> _initializeApp() async {
    final results = await Future.wait([
      _themeService.loadThemeMode(),
      WindowService.isMaximized(),
    ]);

    setState(() {
      _themeMode = results[0] as ThemeMode;
      _isMaximized = results[1] as bool;
      _isLoading = false;
    });
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
      return const MaterialApp(
        home: Scaffold(body: Center(child: LoadingIndicatorM3E())),
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
            if (snapshot.connectionState != ConnectionState.done) {
              return const MaterialApp(
                home: Scaffold(body: Center(child: LoadingIndicatorM3E())),
              );
            }

            final finalLightTheme = snapshot.data![0];
            final finalDarkTheme = snapshot.data![1];

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
                                    onPressed: () async {
                                      await _toggleMaximize();
                                    },
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
              initialRoute: '/home', // 始终从首页开始，初始化器已确保有端点
              getPages: appRoutes, // 使用统一的路由配置列表
              navigatorObservers: [FlutterSmartDialog.observer],
            );
          },
        );
      },
    );
  }
}
