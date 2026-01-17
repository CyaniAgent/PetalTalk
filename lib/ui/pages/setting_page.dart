/// 设置页面，用于管理应用的各种设置选项
///
/// 该页面包含账号设置、端点管理、通知设置、外观设置、语言设置、
/// 帮助与反馈、日志设置、API请求设置和数据管理等功能。
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../global_services/appearance_service.dart';
import '../../utils/snackbar_utils.dart';
import '../components/setting/setting_panel.dart';
import '../../api/services/auth_service.dart';
import '../../api/flarum_api.dart';
import '../../core/logger.dart';
import 'license_page.dart';

/// 设置页面的主组件
class SettingPage extends StatefulWidget {
  /// 创建设置页面实例
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

/// 设置页面的状态管理类
class _SettingPageState extends State<SettingPage> {
  /// 日志记录器实例
  final AppLogger _logger = AppLogger();

  /// 外观服务实例，用于管理应用外观设置
  final AppearanceService _appearanceService = AppearanceService();

  /// API客户端实例，用于管理应用端点
  final FlarumApi _api = FlarumApi();

  /// 使用Rx变量实现响应式状态管理

  /// 深色模式开关状态
  final RxBool _isDarkMode = false.obs;

  /// 动态色彩开关状态
  final RxBool _useDynamicColor = true.obs;

  /// 当前选择的强调色
  final RxString _accentColor = 'blue'.obs;

  /// 是否启用所有通知
  final RxBool _enableNotifications = true.obs;

  /// 是否启用消息通知
  final RxBool _enableMessageNotifications = true.obs;

  /// 是否启用提及通知
  final RxBool _enableMentionNotifications = true.obs;

  /// 是否启用回复通知
  final RxBool _enableReplyNotifications = true.obs;

  /// 是否启用系统通知
  final RxBool _enableSystemNotifications = true.obs;

  /// 当前日志级别
  final RxString _logLevel = 'error'.obs;

  /// 最大日志大小（MB）
  final RxInt _maxLogSize = 10.obs;

  /// 是否启用日志导出
  final RxBool _enableLogExport = true.obs;

  /// 是否使用浏览器请求头
  final RxBool _useBrowserHeaders = true.obs;

  /// 当前选择的字体系列
  final RxString _fontFamily = 'Google Sans'.obs;

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
      // 并行加载所有设置
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
        _appearanceService.loadFontFamily(),
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
      _fontFamily.value = settings[12] as String;

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

  // 更新字体系列
  Future<void> _updateFontFamily(String value) async {
    _logger.debug('更新字体系列: $value');
    try {
      await _appearanceService.saveFontFamily(value);
      _fontFamily.value = value;
      _logger.info('字体系列更新成功: $value');

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
      _logger.error('更新字体系列出错', e, stackTrace);
      SnackbarUtils.showSnackbar('更新字体系列失败', type: SnackbarType.error);
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

  /// 构建颜色选择项组件
  ///
  /// [colorName] - 颜色名称
  /// [color] - 对应的Color对象
  ///
  /// 返回一个可点击的颜色选择组件，选中时显示勾选图标
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

  /// 显示强调色选择对话框
  ///
  /// 显示一个包含多种颜色选项的网格，用户可以选择应用的强调色
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

  /// 显示字体选择对话框
  ///
  /// 显示一个包含多种字体选项的单选列表，用户可以选择应用的字体
  void _showFontFamilyDialog() {
    _logger.debug('显示字体选择对话框');
    final List<String> fonts = ['Google Sans', 'MiSans', 'Star Rail Font'];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择字体'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final font in fonts)
                  RadioListTile<String>(
                    title: Text(font, style: TextStyle(fontFamily: font)),
                    value: font,
                    groupValue: _fontFamily.value,
                    onChanged: (value) {
                      if (value != null) {
                        _updateFontFamily(value);
                        Get.back();
                      }
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('取消')),
          ],
        );
      },
    );
  }

  /// 构建账号设置内容
  ///
  /// 包含个人资料、密码修改和绑定邮箱等账号相关设置
  Widget _buildAccountSettings() {
    return ListView(
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
    );
  }

  /// 构建端点管理内容
  ///
  /// 包含当前端点信息、添加新端点和管理已保存端点等功能
  Widget _buildEndpointSettings() {
    return FutureBuilder<List<String>>(
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
    );
  }

  /// 构建通知设置内容
  ///
  /// 包含总通知开关和各种类型通知的单独开关
  Widget _buildNotificationSettings() {
    return Obx(
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
    );
  }

  /// 构建外观设置内容
  ///
  /// 包含深色模式、动态色彩、强调色和字体设置等功能
  Widget _buildAppearanceSettings() {
    return Obx(
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
          ListTile(
            title: const Text('字体设置'),
            subtitle: Obx(() => Text('当前字体: ${_fontFamily.value}')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showFontFamilyDialog(),
          ),
        ],
      ),
    );
  }

  /// 构建帮助与反馈内容
  ///
  /// 包含常见问题、使用教程、反馈问题和开源许可证等链接
  Widget _buildHelpSettings() {
    return ListView(
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
          title: const Text('开源许可证'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Get.to(() => const AppLicensePage());
          },
        ),
      ],
    );
  }

  /// 构建日志设置内容
  ///
  /// 包含日志管理、日志级别设置、最大日志大小设置和日志导出开关等功能
  Widget _buildLogSettings() {
    return Obx(
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
                  Text('日志管理', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
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
                  Text('日志级别', style: Theme.of(context).textTheme.titleMedium),
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
    );
  }

  /// 构建API请求设置内容
  ///
  /// 包含使用浏览器请求头等API相关设置
  Widget _buildApiSettings() {
    return Obx(
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
    );
  }

  /// 构建数据管理内容
  ///
  /// 包含删除所有数据等数据管理功能
  Widget _buildDataSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 删除所有数据
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('删除所有数据', style: Theme.of(context).textTheme.titleMedium),
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
                        final AuthService authService = Get.find<AuthService>();
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
    );
  }

  /// 构建所有设置项列表
  ///
  /// 返回一个包含所有设置面板的列表，每个设置面板包含标题、图标和内容组件
  List<Map<String, dynamic>> _buildSettingItems() {
    return [
      {
        'icon': Icons.person,
        'title': '账号设置',
        'content': _buildAccountSettings(),
      },
      {
        'icon': Icons.cloud_outlined,
        'title': '端点管理',
        'content': _buildEndpointSettings(),
      },
      {
        'icon': Icons.notifications,
        'title': '通知设置',
        'content': _buildNotificationSettings(),
      },
      {
        'icon': Icons.palette,
        'title': '外观设置',
        'content': _buildAppearanceSettings(),
      },
      {
        'icon': Icons.help_outline,
        'title': '帮助与反馈',
        'content': _buildHelpSettings(),
      },
      {'icon': Icons.history, 'title': '日志设置', 'content': _buildLogSettings()},
      {
        'icon': Icons.cloud_upload,
        'title': 'API请求设置',
        'content': _buildApiSettings(),
      },
      {
        'icon': Icons.data_saver_on,
        'title': '数据管理',
        'content': _buildDataSettings(),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Get.find<AuthService>();

    return UiSettingPage(
      settingItems: _buildSettingItems(),
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
