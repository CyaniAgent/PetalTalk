import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../global_services/appearance_service.dart';
import '../../utils/snackbar_utils.dart';
import '../components/setting/setting_panel.dart';
import '../../api/services/auth_service.dart';
import '../../api/flarum_api.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final AppearanceService _appearanceService = AppearanceService();
  final FlarumApi _api = FlarumApi();
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    // 加载当前设置
    _loadCurrentSettings();
  }

  // 更多设置状态
  bool _useDynamicColor = true;
  String _accentColor = 'blue';
  double _fontSize = 16.0;
  bool _compactLayout = false;
  bool _showAvatars = true;

  // 加载当前设置
  Future<void> _loadCurrentSettings() async {
    final themeMode = await _appearanceService.loadThemeMode();
    final useDynamicColor = await _appearanceService.loadUseDynamicColor();
    final accentColor = await _appearanceService.loadAccentColor();
    final fontSize = await _appearanceService.loadFontSize();
    final compactLayout = await _appearanceService.loadCompactLayout();
    final showAvatars = await _appearanceService.loadShowAvatars();

    setState(() {
      _isDarkMode = themeMode != ThemeMode.light;
      _useDynamicColor = useDynamicColor;
      _accentColor = accentColor;
      _fontSize = fontSize;
      _compactLayout = compactLayout;
      _showAvatars = showAvatars;
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

  // 切换动态色彩
  Future<void> _toggleDynamicColor(bool value) async {
    await _appearanceService.saveUseDynamicColor(value);
    setState(() {
      _useDynamicColor = value;
    });
    // 重新加载主题设置
    _loadThemeSettings();
  }

  // 更新强调色
  Future<void> _updateAccentColor(String value) async {
    await _appearanceService.saveAccentColor(value);
    setState(() {
      _accentColor = value;
    });
    // 重新加载主题设置
    _loadThemeSettings();
  }

  // 更新字体大小
  Future<void> _updateFontSize(double value) async {
    await _appearanceService.saveFontSize(value);
    setState(() {
      _fontSize = value;
    });
  }

  // 重新加载主题设置并重启应用
  Future<void> _loadThemeSettings() async {
    // 重新加载主题设置
    final themeMode = await _appearanceService.loadThemeMode();
    // 这里可以添加重启应用的逻辑，或者通过GetX刷新当前页面
    Get.changeThemeMode(themeMode);
    // 通知应用主题已更改
    Get.forceAppUpdate();
  }

  // 根据字符串获取强调色
  Color _getAccentColor(String colorName) {
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

  // 显示强调色选择对话框
  void _showAccentColorDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择强调色'),
          content: SizedBox(
            width: 200,
            height: 250,
            child: GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _buildColorOption('red', Colors.red),
                _buildColorOption('pink', Colors.pink),
                _buildColorOption('purple', Colors.purple),
                _buildColorOption('indigo', Colors.indigo),
                _buildColorOption('blue', Colors.blue),
                _buildColorOption('cyan', Colors.cyan),
                _buildColorOption('teal', Colors.teal),
                _buildColorOption('green', Colors.green),
                _buildColorOption('lime', Colors.lime),
                _buildColorOption('yellow', Colors.yellow),
                _buildColorOption('amber', Colors.amber),
                _buildColorOption('orange', Colors.orange),
                _buildColorOption('deeporange', Colors.deepOrange),
              ],
            ),
          ),
        );
      },
    );
  }

  // 构建颜色选择项
  Widget _buildColorOption(String colorName, Color color) {
    final isSelected = _accentColor == colorName;
    return GestureDetector(
      onTap: () {
        _updateAccentColor(colorName);
        Navigator.pop(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: isSelected ? 3 : 0,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 24)
            : null,
      ),
    );
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
            SwitchListTile(
              title: const Text('动态色彩'),
              subtitle: const Text('使用系统动态色彩主题 (Material Design 3)'),
              value: _useDynamicColor,
              onChanged: _toggleDynamicColor,
            ),
            ListTile(
              title: const Text('强调色'),
              subtitle: const Text('选择应用的主题色'),
              trailing: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getAccentColor(_accentColor),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
              onTap: () => _showAccentColorDialog(),
            ),
            ListTile(
              title: const Text('字体大小'),
              subtitle: Text('当前大小: ${_fontSize.toStringAsFixed(1)}'),
              trailing: SizedBox(
                width: 200,
                child: Slider(
                  value: _fontSize,
                  min: 12.0,
                  max: 24.0,
                  divisions: 24,
                  label: _fontSize.toStringAsFixed(1),
                  onChanged: _updateFontSize,
                ),
              ),
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

    // 添加端点管理设置
    settingItems.insert(1, {
      'icon': Icons.cloud_outlined,
      'title': '端点管理',
      'content': FutureBuilder<List<String>>(
        future: _api.getEndpoints(),
        builder: (context, snapshot) {
          final endpoints = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 当前端点信息
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '当前端点',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _api.baseUrl ?? '未设置',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 添加新端点
              ElevatedButton.icon(
                onPressed: () {
                  // 跳转到端点选择页面
                  Get.offAllNamed('/endpoint');
                },
                icon: const Icon(Icons.add),
                label: const Text('添加新端点'),
              ),
              const SizedBox(height: 16),
              // 端点列表
              if (endpoints.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '已保存的端点',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...endpoints.map((endpoint) {
                      final isCurrent = endpoint == _api.baseUrl;
                      return Card(
                        child: ListTile(
                          title: Text(endpoint),
                          subtitle: isCurrent ? const Text('当前使用') : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isCurrent)
                                TextButton.icon(
                                  onPressed: () async {
                                    // 切换到该端点
                                    await _api.switchEndpoint(endpoint);
                                    // 重新加载当前端点信息
                                    setState(() {});
                                    Get.snackbar('成功', '已切换到新端点');
                                  },
                                  icon: const Icon(Icons.swap_horiz),
                                  label: const Text('切换'),
                                ),
                              IconButton(
                                onPressed: () async {
                                  // 确认删除
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('确认删除'),
                                        content: Text(
                                          '确定要删除端点 $endpoint 吗？此操作将删除该端点的所有数据。',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context, false);
                                            },
                                            child: const Text('取消'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context, true);
                                            },
                                            child: const Text('删除'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  if (confirm == true) {
                                    // 删除端点
                                    await _api.deleteEndpoint(endpoint);
                                    // 重新加载端点列表
                                    setState(() {});
                                    Get.snackbar('成功', '已删除端点');
                                  }
                                },
                                icon: const Icon(Icons.delete),
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
            ],
          );
        },
      ),
    });

    // 添加数据管理设置
    settingItems.add({
      'icon': Icons.data_saver_on,
      'title': '数据管理',
      'content': ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 删除所有数据
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '删除所有数据',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('此操作将删除所有端点的数据并退出登录，不可恢复。'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // 确认删除
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('确认删除所有数据'),
                              content: const Text(
                                '此操作将删除所有端点的数据并退出登录，不可恢复。您确定要继续吗？',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, false);
                                  },
                                  child: const Text('取消'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, true);
                                  },
                                  child: const Text('删除'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                        if (confirm == true) {
                          // 删除所有数据
                          await _api.clearAllData();
                          // 退出登录
                          authService.logout();
                          // 跳转到端点选择页面
                          Get.offAllNamed('/endpoint');
                          Get.snackbar('成功', '已删除所有数据');
                        }
                      },
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('删除所有数据'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    });

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
