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
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        title: Text(widget.title, style: textTheme.titleMedium),
      ),
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
                      else if (settingController.userLogin.value &&
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
                      else if (settingController.userLogin.value &&
                          index == widget.settingItems.length + 1) {
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
                      // 设置项
                      ...widget.settingItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final isSelected = selectedIndex.value == index;

                        return NavigationDrawerDestination(
                          icon: isSelected
                              ? Icon(item['icon'])
                              : Icon(item['icon'], fill: 0.0),
                          label: Text(item['title']),
                        );
                      }),
                      // 退出登录按钮 - 仅在登录状态下显示
                      if (settingController.userLogin.value &&
                          widget.showLogoutButton)
                        NavigationDrawerDestination(
                          icon: const Icon(Icons.logout_outlined),
                          label: const Text('退出登录'),
                        ),
                      // 关于按钮
                      NavigationDrawerDestination(
                        icon: const Icon(Icons.info_outlined),
                        label: const Text('关于'),
                      ),
                    ],
                  ),
                ),
                // 右侧内容区域
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Obx(
                          () => widget
                              .settingItems[selectedIndex.value]['content'],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : ListView(
              children: [
                ...widget.settingItems.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final item = entry.value;
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    elevation: 2,
                    child: Column(
                      children: [
                        ListTile(
                          onTap: () {
                            _logger.debug(
                              '窄屏模式 - 点击设置项: ${item['title']}, 索引=$index',
                            );
                            // 更新选中索引，确保设置页面与选项同步
                            selectedIndex.value = index;
                            _logger.info('切换到设置项: ${item['title']}');
                            // 跳转到一个新页面，显示该项的内容
                            _logger.debug('跳转到设置详情页面');
                            Get.to(
                              () => Scaffold(
                                appBar: AppBar(title: Text(item['title'])),
                                body: item['content'],
                              ),
                            );
                          },
                          leading: Icon(item['icon']),
                          title: Text(item['title']),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),
                Obx(
                  () => Visibility(
                    visible:
                        settingController.userLogin.value &&
                        widget.showLogoutButton,
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 2,
                      child: ListTile(
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
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  elevation: 2,
                  child: ListTile(
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
                ),
                SizedBox(height: padding.bottom + 20),
              ],
            ),
    );
  }
}
