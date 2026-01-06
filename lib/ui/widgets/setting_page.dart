import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../pages/state/setting_state.dart';

class UiSettingPage extends StatefulWidget {
  final List<Map<String, dynamic>> settingItems;
  final String title;
  final bool showLogoutButton;
  final VoidCallback? onLogout;
  final VoidCallback? onAbout;

  const UiSettingPage({
    Key? key,
    required this.settingItems,
    this.title = '设置',
    this.showLogoutButton = false,
    this.onLogout,
    this.onAbout,
  }) : super(key: key);

  @override
  State<UiSettingPage> createState() => _UiSettingPageState();
}

class _UiSettingPageState extends State<UiSettingPage> {
  late final UiSettingController settingController;
  final RxInt selectedIndex = 0.obs;
  final double wideScreenThreshold = 768;

  @override
  void initState() {
    super.initState();
    settingController = Get.put(UiSettingController());
    settingController.showLogoutButton = widget.showLogoutButton;
  }

  @override
  void dispose() {
    Get.delete<UiSettingController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth > wideScreenThreshold;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          widget.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      body: isWideScreen
          ? Row(
              children: [
                // 左侧导航菜单
                Obx(
                  () => NavigationDrawer(
                    selectedIndex: selectedIndex.value,
                    onDestinationSelected: (int index) {
                      // 只有点击设置项时才更新选中索引
                      if (index < widget.settingItems.length) {
                        selectedIndex.value = index;
                      }
                      // 处理退出登录
                      else if (settingController.userLogin.value &&
                          index == widget.settingItems.length) {
                        if (widget.onLogout != null) {
                          widget.onLogout!();
                        } else {
                          settingController.loginOut();
                        }
                      }
                      // 处理关于
                      else if (settingController.userLogin.value &&
                          index == widget.settingItems.length + 1) {
                        if (widget.onAbout != null) {
                          widget.onAbout!();
                        } else {
                          Get.snackbar('提示', '关于');
                        }
                      }
                      // 处理未登录状态下的关于
                      else if (index == widget.settingItems.length) {
                        if (widget.onAbout != null) {
                          widget.onAbout!();
                        } else {
                          Get.snackbar('提示', '关于');
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
                      }).toList(),
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
                ...widget.settingItems.map((item) {
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
                            // 跳转到一个新页面，显示该项的内容
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
                        onTap: widget.onLogout != null
                            ? widget.onLogout
                            : settingController.loginOut,
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
                    onTap: widget.onAbout != null
                        ? widget.onAbout
                        : () => Get.toNamed('/about'),
                    leading: const Icon(Icons.info_outlined),
                    title: const Text('关于'),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
              ],
            ),
    );
  }
}
