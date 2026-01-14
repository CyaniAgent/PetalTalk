import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../global_services/appearance_service.dart';
import '../../utils/snackbar_utils.dart';
import '../components/setting/setting_panel.dart';
import '../../api/services/auth_service.dart';
import '../../api/flarum_api.dart';
import '../../core/logger.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final AppLogger _logger = AppLogger();
  final AppearanceService _appearanceService = AppearanceService();
  final FlarumApi _api = FlarumApi();

  // 使用Rx变量实现响应式状态管理
  final RxBool _isDarkMode = false.obs;
  final RxBool _useDynamicColor = true.obs;
  final RxString _accentColor = 'blue'.obs;
  final RxBool _enableNotifications = true.obs;
  final RxBool _enableMessageNotifications = true.obs;
  final RxBool _enableMentionNotifications = true.obs;
  final RxBool _enableReplyNotifications = true.obs;
  final RxBool _enableSystemNotifications = true.obs;
  final RxString _logLevel = 'error'.obs;
  final RxInt _maxLogSize = 10.obs;
  final RxBool _enableLogExport = true.obs;
  final RxBool _useBrowserHeaders = true.obs;

  @override
  void initState() {
    super.initState();
    _logger.info('SettingPage初始化');
    // 加载当前设置
    _loadCurrentSettings();
  }

  @override
  void dispose() {
    _logger.info('SettingPage销毁');
    super.dispose();
  }

  // 加载当前设置
  Future<void> _loadCurrentSettings() async {
    _logger.debug('开始加载当前设置');
    try {
      // 并行加载所有设置，提高性能
      final settings = await Future.wait([
        _appearanceService.loadThemeMode(),
        _appearanceService.loadUseDynamicColor(),
        _appearanceService.loadAccentColor(),
        _appearanceService.loadEnableNotifications(),
        _appearanceService.loadEnableMessageNotifications(),
        _appearanceService.loadEnableMentionNotifications(),
        _appearanceService.loadEnableReplyNotifications(),
        _appearanceService.loadEnableSystemNotifications(),
        _appearanceService.loadLogLevel(),
        _appearanceService.loadMaxLogSize(),
        _appearanceService.loadEnableLogExport(),
        _appearanceService.loadUseBrowserHeaders(),
      ]);

      // 直接更新Rx变量的值，不需要setState
      _isDarkMode.value = settings[0] != ThemeMode.light;
      _useDynamicColor.value = settings[1] as bool;
      _accentColor.value = settings[2] as String;
      _enableNotifications.value = settings[3] as bool;
      _enableMessageNotifications.value = settings[4] as bool;
      _enableMentionNotifications.value = settings[5] as bool;
      _enableReplyNotifications.value = settings[6] as bool;
      _enableSystemNotifications.value = settings[7] as bool;
      _logLevel.value = settings[8] as String;
      _maxLogSize.value = settings[9] as int;
      _enableLogExport.value = settings[10] as bool;
      _useBrowserHeaders.value = settings[11] as bool;

      _logger.info(
        '当前设置加载完成: 深色模式 = ${_isDarkMode.value}, 动态色彩 = ${_useDynamicColor.value}, 强调色 = ${_accentColor.value}, 通知启用 = ${_enableNotifications.value}',
      );
    } catch (e, stackTrace) {
      _logger.error('加载当前设置出错', e, stackTrace);
      SnackbarUtils.showSnackbar('加载设置失败', type: SnackbarType.error);
    }
  }

  // 切换深色模式
  Future<void> _toggleDarkMode(bool value) async {
    _logger.debug('切换深色模式: $value');
    try {
      final themeMode = value ? ThemeMode.dark : ThemeMode.light;
      await _appearanceService.saveThemeMode(themeMode);
      _isDarkMode.value = value;
      Get.changeThemeMode(themeMode);
      _logger.info('深色模式切换成功: $value');
    } catch (e, stackTrace) {
      _logger.error('切换深色模式出错', e, stackTrace);
      SnackbarUtils.showSnackbar('切换深色模式失败', type: SnackbarType.error);
    }
  }

  // 切换动态色彩
  Future<void> _toggleDynamicColor(bool value) async {
    _logger.debug('切换动态色彩: $value');
    try {
      await _appearanceService.saveUseDynamicColor(value);
      _useDynamicColor.value = value;
      _logger.info('动态色彩切换成功: $value');

      // 显示重启确认对话框
      if (mounted) {
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('主题设置已更改'),
              content: const Text('您需要重启应用才能使新的主题设置生效。'),
              actions: [
                TextButton(
                  onPressed: () {
                    Get.back(result: false);
                  },
                  child: const Text('稍后重启'),
                ),
                TextButton(
                  onPressed: () {
                    Get.back(result: true);
                  },
                  child: const Text('立即重启'),
                ),
              ],
            );
          },
        ).then((value) {
          if (value == true && mounted) {
            // 立即重启应用
            _logger.debug('用户选择立即重启应用');
            _loadThemeSettings();
          } else {
            _logger.debug('用户选择稍后重启应用');
          }
        });
      }
    } catch (e, stackTrace) {
      _logger.error('切换动态色彩出错', e, stackTrace);
      SnackbarUtils.showSnackbar('切换动态色彩失败', type: SnackbarType.error);
    }
  }

  // 更新强调色
  Future<void> _updateAccentColor(String value) async {
    _logger.debug('更新强调色: $value');
    try {
      await _appearanceService.saveAccentColor(value);
      _accentColor.value = value;
      // 重新加载主题设置
      _loadThemeSettings();
      _logger.info('强调色更新成功: $value');
    } catch (e, stackTrace) {
      _logger.error('更新强调色出错', e, stackTrace);
      SnackbarUtils.showSnackbar('更新强调色失败', type: SnackbarType.error);
    }
  }

  // 切换是否启用所有通知
  Future<void> _toggleEnableNotifications(bool value) async {
    _logger.debug('切换启用所有通知: $value');
    try {
      await _appearanceService.saveEnableNotifications(value);
      _enableNotifications.value = value;
      // 如果禁用所有通知，同时禁用所有子类型通知
      if (!value) {
        _enableMessageNotifications.value = false;
        _enableMentionNotifications.value = false;
        _enableReplyNotifications.value = false;
        _enableSystemNotifications.value = false;
        // 保存子类型通知设置
        _appearanceService.saveEnableMessageNotifications(false);
        _appearanceService.saveEnableMentionNotifications(false);
        _appearanceService.saveEnableReplyNotifications(false);
        _appearanceService.saveEnableSystemNotifications(false);
      }
      _logger.info('启用所有通知设置成功: $value');
    } catch (e, stackTrace) {
      _logger.error('切换启用所有通知出错', e, stackTrace);
      SnackbarUtils.showSnackbar('切换通知设置失败', type: SnackbarType.error);
    }
  }

  // 切换是否启用消息通知
  Future<void> _toggleMessageNotifications(bool value) async {
    _logger.debug('切换消息通知: $value');
    try {
      await _appearanceService.saveEnableMessageNotifications(value);
      _enableMessageNotifications.value = value;
      // 如果启用了某个子类型通知，同时启用所有通知
      if (value && !_enableNotifications.value) {
        _enableNotifications.value = true;
        _appearanceService.saveEnableNotifications(true);
      }
      _logger.info('消息通知设置成功: $value');
    } catch (e, stackTrace) {
      _logger.error('切换消息通知出错', e, stackTrace);
      SnackbarUtils.showSnackbar('切换消息通知失败', type: SnackbarType.error);
    }
  }

  // 切换是否启用提及通知
  Future<void> _toggleMentionNotifications(bool value) async {
    _logger.debug('切换提及通知: $value');
    try {
      await _appearanceService.saveEnableMentionNotifications(value);
      _enableMentionNotifications.value = value;
      // 如果启用了某个子类型通知，同时启用所有通知
      if (value && !_enableNotifications.value) {
        _enableNotifications.value = true;
        _appearanceService.saveEnableNotifications(true);
      }
      _logger.info('提及通知设置成功: $value');
    } catch (e, stackTrace) {
      _logger.error('切换提及通知出错', e, stackTrace);
      SnackbarUtils.showSnackbar('切换提及通知失败', type: SnackbarType.error);
    }
  }

  // 切换是否启用回复通知
  Future<void> _toggleReplyNotifications(bool value) async {
    _logger.debug('切换回复通知: $value');
    try {
      await _appearanceService.saveEnableReplyNotifications(value);
      _enableReplyNotifications.value = value;
      // 如果启用了某个子类型通知，同时启用所有通知
      if (value && !_enableNotifications.value) {
        _enableNotifications.value = true;
        _appearanceService.saveEnableNotifications(true);
      }
      _logger.info('回复通知设置成功: $value');
    } catch (e, stackTrace) {
      _logger.error('切换回复通知出错', e, stackTrace);
      SnackbarUtils.showSnackbar('切换回复通知失败', type: SnackbarType.error);
    }
  }

  // 切换是否启用系统通知
  Future<void> _toggleSystemNotifications(bool value) async {
    _logger.debug('切换系统通知: $value');
    try {
      await _appearanceService.saveEnableSystemNotifications(value);
      _enableSystemNotifications.value = value;
      // 如果启用了某个子类型通知，同时启用所有通知
      if (value && !_enableNotifications.value) {
        _enableNotifications.value = true;
        _appearanceService.saveEnableNotifications(true);
      }
      _logger.info('系统通知设置成功: $value');
    } catch (e, stackTrace) {
      _logger.error('切换系统通知出错', e, stackTrace);
      SnackbarUtils.showSnackbar('切换系统通知失败', type: SnackbarType.error);
    }
  }

  // 重新加载主题设置并重启应用
  Future<void> _loadThemeSettings() async {
    _logger.debug('重新加载主题设置');
    try {
      // 重新加载主题设置
      final themeMode = await _appearanceService.loadThemeMode();
      // 这里可以添加重启应用的逻辑，或者通过GetX刷新当前页面
      Get.changeThemeMode(themeMode);
      // 通知应用主题已更改
      Get.forceAppUpdate();
      _logger.info('主题设置重新加载成功');
    } catch (e, stackTrace) {
      _logger.error('重新加载主题设置出错', e, stackTrace);
    }
  }

  // 更新日志级别
  Future<void> _updateLogLevel(String value) async {
    _logger.debug('更新日志级别: $value');
    try {
      await _appearanceService.saveLogLevel(value);
      _logger.setLogLevel(value);
      _logLevel.value = value;
      _logger.info('日志级别更新成功: $value');
    } catch (e, stackTrace) {
      _logger.error('更新日志级别出错', e, stackTrace);
      SnackbarUtils.showSnackbar('更新日志级别失败', type: SnackbarType.error);
    }
  }

  // 更新最大日志大小
  Future<void> _updateMaxLogSize(int value) async {
    _logger.debug('更新最大日志大小: $value MB');
    try {
      await _appearanceService.saveMaxLogSize(value);
      await _logger.setMaxLogSize(value);
      _maxLogSize.value = value;
      _logger.info('最大日志大小更新成功: $value MB');
    } catch (e, stackTrace) {
      _logger.error('更新最大日志大小出错', e, stackTrace);
      SnackbarUtils.showSnackbar('更新最大日志大小失败', type: SnackbarType.error);
    }
  }

  // 切换日志导出
  Future<void> _toggleLogExport(bool value) async {
    _logger.debug('切换日志导出: $value');
    try {
      await _appearanceService.saveEnableLogExport(value);
      _enableLogExport.value = value;
      _logger.info('日志导出设置成功: $value');
    } catch (e, stackTrace) {
      _logger.error('切换日志导出出错', e, stackTrace);
      SnackbarUtils.showSnackbar('切换日志导出失败', type: SnackbarType.error);
    }
  }

  // 查看日志
  void _viewLogs() {
    _logger.debug('查看日志');
    try {
      Get.toNamed('/logs');
      _logger.info('跳转到日志查看页面');
    } catch (e, stackTrace) {
      _logger.error('查看日志出错', e, stackTrace);
      SnackbarUtils.showSnackbar('查看日志失败', type: SnackbarType.error);
    }
  }

  // 导出日志
  Future<void> _exportLogs() async {
    _logger.debug('导出日志');
    try {
      final file = await _logger.exportLogs();
      if (file != null) {
        _logger.info('日志导出成功: ${file.path}');
        SnackbarUtils.showSnackbar('日志已导出到: ${file.path}');
      } else {
        _logger.warning('日志导出失败: 文件为null');
        SnackbarUtils.showSnackbar('日志导出失败', type: SnackbarType.error);
      }
    } catch (e, stackTrace) {
      _logger.error('导出日志出错', e, stackTrace);
      SnackbarUtils.showSnackbar('日志导出失败', type: SnackbarType.error);
    }
  }

  // 删除日志
  Future<void> _deleteLogs() async {
    _logger.debug('删除日志');
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('确认删除日志'),
            content: const Text('确定要删除所有日志吗？此操作不可恢复。'),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back(result: false);
                },
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  Get.back(result: true);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('删除'),
              ),
            ],
          );
        },
      );
      if (confirm == true) {
        await _logger.deleteLogs();
        _logger.info('日志删除成功');
        SnackbarUtils.showSnackbar('日志已删除');
      }
    } catch (e, stackTrace) {
      _logger.error('删除日志出错', e, stackTrace);
      SnackbarUtils.showSnackbar('删除日志失败', type: SnackbarType.error);
    }
  }

  // 切换是否使用浏览器请求头
  Future<void> _toggleUseBrowserHeaders(bool value) async {
    _logger.debug('切换使用浏览器请求头: $value');
    try {
      await _appearanceService.saveUseBrowserHeaders(value);
      _useBrowserHeaders.value = value;
      _logger.info('使用浏览器请求头设置成功: $value');
      SnackbarUtils.showSnackbar('API请求设置已更新');
    } catch (e, stackTrace) {
      _logger.error('切换使用浏览器请求头出错', e, stackTrace);
      SnackbarUtils.showSnackbar('切换API请求设置失败', type: SnackbarType.error);
    }
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
    _logger.debug('显示强调色选择对话框');
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
    final isSelected = _accentColor.value == colorName;
    return GestureDetector(
      onTap: () {
        _updateAccentColor(colorName);
        Get.back();
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
    final AuthService authService = Get.find<AuthService>();

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
                SnackbarUtils.showDevelopmentInProgress();
              },
            ),
            ListTile(
              title: const Text('密码修改'),
              subtitle: const Text('修改您的登录密码'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                SnackbarUtils.showDevelopmentInProgress();
              },
            ),
            ListTile(
              title: const Text('绑定邮箱'),
              subtitle: const Text('绑定或修改邮箱地址'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                SnackbarUtils.showDevelopmentInProgress();
              },
            ),
          ],
        ),
      },
      {
        'icon': Icons.notifications,
        'title': '通知设置',
        'content': Obx(
          () => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text('启用通知'),
                subtitle: const Text('接收所有类型的通知'),
                value: _enableNotifications.value,
                onChanged: _toggleEnableNotifications,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('消息通知'),
                subtitle: const Text('接收新消息通知'),
                value: _enableMessageNotifications.value,
                onChanged: _enableNotifications.value
                    ? _toggleMessageNotifications
                    : null,
              ),
              SwitchListTile(
                title: const Text('提及通知'),
                subtitle: const Text('当有人@你时通知'),
                value: _enableMentionNotifications.value,
                onChanged: _enableNotifications.value
                    ? _toggleMentionNotifications
                    : null,
              ),
              SwitchListTile(
                title: const Text('回复通知'),
                subtitle: const Text('当有人回复你时通知'),
                value: _enableReplyNotifications.value,
                onChanged: _enableNotifications.value
                    ? _toggleReplyNotifications
                    : null,
              ),
              SwitchListTile(
                title: const Text('系统通知'),
                subtitle: const Text('接收系统通知'),
                value: _enableSystemNotifications.value,
                onChanged: _enableNotifications.value
                    ? _toggleSystemNotifications
                    : null,
              ),
            ],
          ),
        ),
      },
      {
        'icon': Icons.palette,
        'title': '外观设置',
        'content': Obx(
          () => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text('深色模式'),
                subtitle: const Text('开启或关闭深色主题'),
                value: _isDarkMode.value,
                onChanged: _toggleDarkMode,
              ),
              SwitchListTile(
                title: const Text('动态色彩'),
                subtitle: const Text('使用系统动态色彩主题 (Material Design 3)'),
                value: _useDynamicColor.value,
                onChanged: _toggleDynamicColor,
              ),
              ListTile(
                title: const Text('强调色'),
                subtitle: const Text('选择应用的主题色'),
                trailing: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getAccentColor(_accentColor.value),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
                onTap: _useDynamicColor.value
                    ? null
                    : () => _showAccentColorDialog(),
                enabled: !_useDynamicColor.value,
              ),
            ],
          ),
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
                SnackbarUtils.showDevelopmentInProgress();
              },
            ),
            ListTile(
              title: const Text('区域设置'),
              subtitle: const Text('中国'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                SnackbarUtils.showDevelopmentInProgress();
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
                SnackbarUtils.showDevelopmentInProgress();
              },
            ),
            ListTile(
              title: const Text('使用教程'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                SnackbarUtils.showDevelopmentInProgress();
              },
            ),
            ListTile(
              title: const Text('反馈问题'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                SnackbarUtils.showDevelopmentInProgress();
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
                                    _loadCurrentSettings();
                                    SnackbarUtils.showSnackbar('已切换到新端点');
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
                                              Get.back(result: false);
                                            },
                                            child: const Text('取消'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Get.back(result: true);
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                            child: const Text('删除'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  if (confirm == true) {
                                    // 删除端点
                                    await _api.deleteEndpoint(endpoint);
                                    // 重新加载端点列表
                                    _loadCurrentSettings();
                                    SnackbarUtils.showSnackbar('已删除端点');
                                  }
                                },
                                icon: const Icon(Icons.delete),
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
            ],
          );
        },
      ),
    });

    // 添加日志设置
    settingItems.add({
      'icon': Icons.history,
      'title': '日志设置',
      'content': Obx(
        () => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 日志管理操作
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '日志管理',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _viewLogs,
                          icon: const Icon(Icons.visibility),
                          label: const Text('查看日志'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _exportLogs,
                          icon: const Icon(Icons.download),
                          label: const Text('导出日志'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _deleteLogs,
                          icon: const Icon(Icons.delete),
                          label: const Text('删除日志'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 日志级别设置
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '日志级别',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '设置日志记录的详细程度',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<String>(
                      selected: <String>{_logLevel.value},
                      onSelectionChanged: (Set<String> newSelection) {
                        _updateLogLevel(newSelection.first);
                      },
                      segments: const <ButtonSegment<String>>[
                        ButtonSegment<String>(
                          value: 'error',
                          label: Text('错误'),
                          icon: Icon(Icons.error_outline),
                        ),
                        ButtonSegment<String>(
                          value: 'warning',
                          label: Text('警告'),
                          icon: Icon(Icons.warning_amber_outlined),
                        ),
                        ButtonSegment<String>(
                          value: 'info',
                          label: Text('信息'),
                          icon: Icon(Icons.info_outline),
                        ),
                        ButtonSegment<String>(
                          value: 'debug',
                          label: Text('调试'),
                          icon: Icon(Icons.bug_report_outlined),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 最大日志大小设置
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '最大日志大小',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '设置日志文件的最大占用空间 (MB)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _maxLogSize.value.toDouble(),
                            min: 1,
                            max: 50,
                            divisions: 49,
                            label: '${_maxLogSize.value} MB',
                            onChanged: (value) {
                              _maxLogSize.value = value.toInt();
                            },
                            onChangeEnd: (value) {
                              _updateMaxLogSize(value.toInt());
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text('${_maxLogSize.value} MB'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 启用日志导出
            SwitchListTile(
              title: const Text('启用日志导出'),
              subtitle: const Text('允许将日志导出到文件'),
              value: _enableLogExport.value,
              onChanged: _toggleLogExport,
            ),
          ],
        ),
      ),
    });

    // 添加API请求设置
    settingItems.add({
      'icon': Icons.cloud_upload,
      'title': 'API请求设置',
      'content': Obx(
        () => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 使用浏览器请求头
            SwitchListTile(
              title: const Text('使用浏览器请求头'),
              subtitle: const Text('模仿正常浏览器请求，包括User-Agent、Referer等头信息'),
              value: _useBrowserHeaders.value,
              onChanged: _toggleUseBrowserHeaders,
            ),
          ],
        ),
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
                                    Get.back(result: false);
                                  },
                                  child: const Text('取消'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Get.back(result: true);
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('删除'),
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
                          SnackbarUtils.showSnackbar('已删除所有数据');
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
