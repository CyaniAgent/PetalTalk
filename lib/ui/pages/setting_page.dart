import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/appearance_service.dart';
import '../../utils/snackbar_utils.dart';
import '../widgets/setting_page.dart';
import '../../api/services/auth_service.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final AppearanceService _appearanceService = AppearanceService();
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    // 加载当前设置
    _loadCurrentSettings();
  }

  // 加载当前设置
  Future<void> _loadCurrentSettings() async {
    final themeMode = await _appearanceService.loadThemeMode();
    setState(() {
      _isDarkMode = themeMode != ThemeMode.light;
    });
  }

  // 切换深色模式
  Future<void> _toggleDarkMode(bool value) async {
    final themeMode = value ? ThemeMode.dark : ThemeMode.light;
    await _appearanceService.saveThemeMode(themeMode);
    setState(() {
      _isDarkMode = value;
    });
    Get.changeThemeMode(themeMode);
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    // 设置项列表
    final List<Map<String, dynamic>> settingItems = [
      {
        'icon': Icons.person,
        'title': '账号设置',
        'content': ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              title: const Text('个人资料'),
              subtitle: const Text('编辑您的个人信息'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                SnackbarUtils.showDevelopmentInProgress(context);
              },
            ),
            ListTile(
              title: const Text('密码修改'),
              subtitle: const Text('修改您的登录密码'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                SnackbarUtils.showDevelopmentInProgress(context);
              },
            ),
            ListTile(
              title: const Text('绑定邮箱'),
              subtitle: const Text('绑定或修改邮箱地址'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                SnackbarUtils.showDevelopmentInProgress(context);
              },
            ),
          ],
        ),
      },
      {
        'icon': Icons.notifications,
        'title': '通知设置',
        'content': ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: const Text('消息通知'),
              subtitle: const Text('接收新消息通知'),
              value: true,
              onChanged: (value) {
                print('消息通知: $value');
              },
            ),
            SwitchListTile(
              title: const Text('提及通知'),
              subtitle: const Text('当有人@你时通知'),
              value: true,
              onChanged: (value) {
                print('提及通知: $value');
              },
            ),
            SwitchListTile(
              title: const Text('回复通知'),
              subtitle: const Text('当有人回复你时通知'),
              value: true,
              onChanged: (value) {
                print('回复通知: $value');
              },
            ),
            SwitchListTile(
              title: const Text('系统通知'),
              subtitle: const Text('接收系统通知'),
              value: true,
              onChanged: (value) {
                print('系统通知: $value');
              },
            ),
          ],
        ),
      },
      {
        'icon': Icons.palette,
        'title': '外观设置',
        'content': ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: const Text('深色模式'),
              subtitle: const Text('开启或关闭深色主题'),
              value: _isDarkMode,
              onChanged: _toggleDarkMode,
            ),
          ],
        ),
      },
      {
        'icon': Icons.language,
        'title': '语言设置',
        'content': ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              title: const Text('系统语言'),
              subtitle: const Text('简体中文'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                SnackbarUtils.showDevelopmentInProgress(context);
              },
            ),
            ListTile(
              title: const Text('区域设置'),
              subtitle: const Text('中国'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                SnackbarUtils.showDevelopmentInProgress(context);
              },
            ),
          ],
        ),
      },
      {
        'icon': Icons.help_outline,
        'title': '帮助与反馈',
        'content': ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              title: const Text('常见问题'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                SnackbarUtils.showDevelopmentInProgress(context);
              },
            ),
            ListTile(
              title: const Text('使用教程'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                SnackbarUtils.showDevelopmentInProgress(context);
              },
            ),
            ListTile(
              title: const Text('反馈问题'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                SnackbarUtils.showDevelopmentInProgress(context);
              },
            ),
            ListTile(
              title: const Text('关于我们'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.toNamed('/about');
              },
            ),
          ],
        ),
      },
    ];

    return UiSettingPage(
      settingItems: settingItems,
      title: '设置',
      showLogoutButton: authService.isLoggedIn(),
      onLogout: () {
        authService.logout();
        Get.offAllNamed('/login');
      },
      onAbout: () {
        Get.toNamed('/about');
      },
    );
  }
}
