import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/snackbar_utils.dart';

import '../../../state/setting_state.dart';
import '../../../core/logger.dart';
import '../../../config/constants.dart';

class UiSettingPage extends StatefulWidget {
  final List<Map<String, dynamic>> settingItems;
  final String title;
  final bool showLogoutButton;
  final VoidCallback? onLogout;
  final VoidCallback? onAbout;

  const UiSettingPage({
    super.key,
    required this.settingItems,
    this.title = '设置',
    this.showLogoutButton = false,
    this.onLogout,
    this.onAbout,
  });

  @override
  State<UiSettingPage> createState() => _UiSettingPageState();
}

class _UiSettingPageState extends State<UiSettingPage> {
  final AppLogger _logger = AppLogger();
  late final UiSettingController settingController;
  final RxInt selectedIndex = 0.obs;
  final double wideScreenThreshold = Constants.wideScreenThreshold;

  @override
  void initState() {
    super.initState();
    _logger.info('UiSettingPage初始化');
    _logger.debug(
      '设置项数量: ${widget.settingItems.length}, 显示退出按钮: ${widget.showLogoutButton}, 标题: ${widget.title}',
    );
    settingController = Get.put(UiSettingController());
    settingController.showLogoutButton = widget.showLogoutButton;
    _logger.debug('设置退出按钮显示状态: ${widget.showLogoutButton}');
    _logger.info('UiSettingPage初始化完成');
  }

  @override
  void dispose() {
    _logger.info('UiSettingPage销毁');
    _logger.debug('删除UiSettingController');
    Get.delete<UiSettingController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final double screenWidth = mediaQuery.size.width;
    final EdgeInsets padding = mediaQuery.padding;
    final bool isWideScreen = screenWidth > wideScreenThreshold;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: isWideScreen
          ? Row(
              children: [
                // 左侧导航菜单
                Obx(
                  () => NavigationDrawer(
                    selectedIndex: selectedIndex.value,
                    onDestinationSelected: (int index) {
                      _logger.debug('宽屏模式 - 导航项选择: 索引=$index');
                      // 只有点击设置项时才更新选中索引
                      if (index < widget.settingItems.length) {
                        _logger.info(
                          '切换到设置项: ${widget.settingItems[index]['title']}',
                        );
                        selectedIndex.value = index;
                      }
                      // 处理退出登录
                      else if (widget.showLogoutButton &&
                          index == widget.settingItems.length) {
                        _logger.info('执行退出登录操作');
                        if (widget.onLogout != null) {
                          _logger.debug('使用外部onLogout回调');
                          widget.onLogout!();
                        } else {
                          _logger.debug('使用settingController.loginOut()');
                          settingController.loginOut();
                        }
                      }
                      // 处理关于
                      else if (index ==
                          widget.settingItems.length +
                              (widget.showLogoutButton ? 1 : 0)) {
                        _logger.info('执行关于操作');
                        if (widget.onAbout != null) {
                          _logger.debug('使用外部onAbout回调');
                          widget.onAbout!();
                        } else {
                          _logger.debug('显示关于提示');
                          SnackbarUtils.showSnackbar('关于');
                        }
                      }
                      // 处理未登录状态下的关于
                      else if (index == widget.settingItems.length) {
                        _logger.info('执行关于操作（未登录状态）');
                        if (widget.onAbout != null) {
                          _logger.debug('使用外部onAbout回调');
                          widget.onAbout!();
                        } else {
                          _logger.debug('显示关于提示');
                          SnackbarUtils.showSnackbar('关于');
                        }
                      }
                    },
                    children: [
                      // Header with back button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            const BackButton(),
                            const SizedBox(width: 8),
                            Text(
                              widget.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 设置项
                      ...widget.settingItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final isSelected = selectedIndex.value == index;

                        return NavigationDrawerDestination(
                          icon: isSelected
                              ? Icon(item['icon'])
                              : Icon(
                                  item['icon'],
                                ), // Removed fill: 0.0 generally, will handle outlined in setting_page.dart
                          label: Text(item['title']),
                        );
                      }),
                      // 退出登录按钮 - 仅在登录状态下显示
                      if (widget.showLogoutButton)
                        const NavigationDrawerDestination(
                          icon: Icon(Icons.logout_outlined),
                          label: Text('退出登录'),
                        ),
                      // 关于按钮
                      const NavigationDrawerDestination(
                        icon: Icon(Icons.info_outlined),
                        label: Text('关于'),
                      ),
                    ],
                  ),
                ),
                // 右侧内容区域
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Obx(() {
                          final content = widget
                              .settingItems[selectedIndex.value]['content'];
                          return SizedBox(
                            height: double.infinity,
                            child: SingleChildScrollView(child: content),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : CustomScrollView(
              slivers: [
                SliverAppBar.large(
                  title: Text(widget.title),
                  centerTitle: false,
                  leading: const BackButton(),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = widget.settingItems[index];
                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          onTap: () {
                            _logger.debug(
                              '窄屏模式 - 点击设置项: ${item['title']}, 索引=$index',
                            );
                            selectedIndex.value = index;
                            _logger.info('切换到设置项: ${item['title']}');
                            Get.to(
                              () => Scaffold(
                                appBar: AppBar(title: Text(item['title'])),
                                body: item['content'] is ListView
                                    ? item['content']
                                    : SingleChildScrollView(
                                        child: item['content'],
                                      ),
                              ),
                            );
                          },
                          leading: Icon(item['icon']),
                          title: Text(
                            item['title'],
                            style: textTheme.titleMedium,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                        if (index < widget.settingItems.length - 1)
                          const Divider(indent: 72, endIndent: 24, height: 1),
                      ],
                    );
                  }, childCount: widget.settingItems.length),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      if (widget.showLogoutButton) ...[
                        const Divider(),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          onTap: () {
                            _logger.info('窄屏模式 - 执行退出登录操作');
                            if (widget.onLogout != null) {
                              _logger.debug('使用外部onLogout回调');
                              widget.onLogout!();
                            } else {
                              _logger.debug('使用settingController.loginOut()');
                              settingController.loginOut();
                            }
                          },
                          leading: const Icon(Icons.logout_outlined),
                          title: const Text('退出登录'),
                        ),
                      ],
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        onTap: () {
                          _logger.info('窄屏模式 - 执行关于操作');
                          if (widget.onAbout != null) {
                            _logger.debug('使用外部onAbout回调');
                            widget.onAbout!();
                          } else {
                            _logger.debug('跳转到关于页面');
                            Get.toNamed('/about');
                          }
                        },
                        leading: const Icon(Icons.info_outlined),
                        title: const Text('关于'),
                      ),
                      SizedBox(height: padding.bottom + 20),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
