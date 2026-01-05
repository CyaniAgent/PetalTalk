import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/appearance_service.dart';
import '../../utils/snackbar_utils.dart';
import '../widgets/setting_page.dart';
import '../../api/services/auth_service.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

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

  // 切换紧凑布局
  Future<void> _toggleCompactLayout(bool value) async {
    await _appearanceService.saveCompactLayout(value);
    setState(() {
      _compactLayout = value;
    });
  }

  // 切换显示头像
  Future<void> _toggleShowAvatars(bool value) async {
    await _appearanceService.saveShowAvatars(value);
    setState(() {
      _showAvatars = value;
    });
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
            SwitchListTile(
              title: const Text('紧凑布局'),
              subtitle: const Text('减少元素间距，显示更多内容'),
              value: _compactLayout,
              onChanged: _toggleCompactLayout,
            ),
            SwitchListTile(
              title: const Text('显示头像'),
              subtitle: const Text('在主题帖和回复中显示用户头像'),
              value: _showAvatars,
              onChanged: _toggleShowAvatars,
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
