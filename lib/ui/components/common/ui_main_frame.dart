import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../state/main_state.dart';

class UiMainFrame extends StatefulWidget {
  final List<Map<String, dynamic>> navItems;
  final bool enableGradientBg;

  const UiMainFrame({
    super.key,
    required this.navItems,
    this.enableGradientBg = false,
  });

  @override
  State<UiMainFrame> createState() => _UiMainFrameState();
}

class _UiMainFrameState extends State<UiMainFrame> {
  late final UiMainController _mainController;

  @override
  void initState() {
    super.initState();
    // 查找或创建控制器，避免重复创建导致状态重置
    _mainController = Get.isRegistered<UiMainController>()
        ? Get.find<UiMainController>()
        : Get.put(UiMainController());
    _mainController.enableGradientBg.value = widget.enableGradientBg;
    // 每次都设置导航栏配置，确保页面列表正确
    _mainController.setNavBarConfig(widget.navItems);
  }

  @override
  void dispose() {
    // 不要删除控制器，避免窗口大小变化时状态重置
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final double screenWidth = mediaQuery.size.width;
    final Size screenSize = mediaQuery.size;
    final bool isWideScreen = screenWidth > 600; // 宽屏阈值

    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBody: !isWideScreen, // 宽屏时不需要延伸Body
      body: isWideScreen
          ? Row(
              children: [
                // 侧边栏
                NavigationRail(
                  backgroundColor: Colors.transparent,
                  selectedIndex: _mainController.selectedIndex.value,
                  onDestinationSelected: (value) =>
                      _mainController.setSelectedIndex(value),
                  labelType: NavigationRailLabelType.all,
                  destinations: _mainController.navigationBars.map((e) {
                    return NavigationRailDestination(
                      icon: Badge(
                        label:
                            _mainController.dynamicBadgeType.value ==
                                DynamicBadgeMode.number
                            ? Text(e['count'].toString())
                            : null,
                        padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
                        isLabelVisible:
                            _mainController.dynamicBadgeType.value !=
                                DynamicBadgeMode.hidden &&
                            e['count'] > 0,
                        child: e['icon'],
                      ),
                      selectedIcon: e['selectIcon'],
                      label: Text(e['label']),
                    );
                  }).toList(),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                // 主内容区域
                Expanded(
                  child: Stack(
                    children: [
                      if (_mainController.enableGradientBg.value)
                        Align(
                          alignment: Alignment.topLeft,
                          child: Opacity(
                            opacity: brightness == Brightness.dark ? 0.3 : 0.6,
                            child: Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.primary.withValues(alpha: 0.7),
                                    colorScheme.surface,
                                    colorScheme.surface.withValues(alpha: 0.3),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: const [0.1, 0.3, 5],
                                ),
                              ),
                            ),
                          ),
                        ),
                      PageView(
                        physics: const NeverScrollableScrollPhysics(),
                        controller: _mainController.pageController,
                        onPageChanged: (index) {
                          _mainController.selectedIndex.value = index;
                          setState(() {});
                        },
                        children: _mainController.pages,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Stack(
              children: [
                if (_mainController.enableGradientBg.value)
                  Align(
                    alignment: Alignment.topLeft,
                    child: Opacity(
                      opacity: brightness == Brightness.dark ? 0.3 : 0.6,
                      child: Container(
                        width: screenSize.width,
                        height: screenSize.height,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary.withValues(alpha: 0.7),
                              colorScheme.surface,
                              colorScheme.surface.withValues(alpha: 0.3),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.1, 0.3, 5],
                          ),
                        ),
                      ),
                    ),
                  ),
                PageView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: _mainController.pageController,
                  onPageChanged: (index) {
                    _mainController.selectedIndex.value = index;
                    setState(() {});
                  },
                  children: _mainController.pages,
                ),
              ],
            ),
      // 窄屏时显示底部导航栏
      bottomNavigationBar:
          !isWideScreen && _mainController.navigationBars.length > 1
          ? StreamBuilder(
              stream: _mainController.bottomBarStream.stream.distinct(),
              initialData: true,
              builder: (context, AsyncSnapshot snapshot) {
                return AnimatedSlide(
                  curve: Curves.easeInOutCubicEmphasized,
                  duration: const Duration(milliseconds: 500),
                  offset: Offset(0, snapshot.data ? 0 : 1),
                  child: NavigationBar(
                    onDestinationSelected: (value) =>
                        _mainController.setSelectedIndex(value),
                    selectedIndex: _mainController.selectedIndex.value,
                    destinations: <Widget>[
                      ..._mainController.navigationBars.map((e) {
                        return NavigationDestination(
                          icon: Badge(
                            label:
                                _mainController.dynamicBadgeType.value ==
                                    DynamicBadgeMode.number
                                ? Text(e['count'].toString())
                                : null,
                            padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
                            isLabelVisible:
                                _mainController.dynamicBadgeType.value !=
                                    DynamicBadgeMode.hidden &&
                                e['count'] > 0,
                            child: e['icon'],
                          ),
                          selectedIcon: e['selectIcon'],
                          label: e['label'],
                        );
                      }),
                    ],
                  ),
                );
              },
            )
          : null,
    );
  }
}
