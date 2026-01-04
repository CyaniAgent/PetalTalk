import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widgets/setting_page.dart';
import '../../api/services/auth_service.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({Key? key}) : super(key: key);

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
                Get.snackbar(
                  '提示',
                  '功能开发中',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            ListTile(
              title: const Text('密码修改'),
              subtitle: const Text('修改您的登录密码'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.snackbar(
                  '提示',
                  '功能开发中',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            ListTile(
              title: const Text('绑定邮箱'),
              subtitle: const Text('绑定或修改邮箱地址'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.snackbar(
                  '提示',
                  '功能开发中',
                  snackPosition: SnackPosition.BOTTOM,
                );
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
            ListTile(
              title: const Text('主题模式'),
              subtitle: const Text('跟随系统'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.toNamed('/theme-mode');
              },
            ),
            ListTile(
              title: const Text('字体大小'),
              subtitle: const Text('默认'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.snackbar(
                  '提示',
                  '功能开发中',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            ListTile(
              title: const Text('深色主题'),
              subtitle: const Text('默认'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.snackbar(
                  '提示',
                  '功能开发中',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
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
                Get.snackbar(
                  '提示',
                  '功能开发中',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            ListTile(
              title: const Text('区域设置'),
              subtitle: const Text('中国'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.snackbar(
                  '提示',
                  '功能开发中',
                  snackPosition: SnackPosition.BOTTOM,
                );
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
                Get.snackbar(
                  '提示',
                  '功能开发中',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            ListTile(
              title: const Text('使用教程'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.snackbar(
                  '提示',
                  '功能开发中',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            ListTile(
              title: const Text('反馈问题'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.snackbar(
                  '提示',
                  '功能开发中',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            ListTile(
              title: const Text('关于我们'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.snackbar(
                  '提示',
                  '功能开发中',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Flarum 客户端 v1.0.0',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
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
