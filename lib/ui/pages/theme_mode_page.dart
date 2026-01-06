import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../global_services/appearance_service.dart';

class ThemeModePage extends StatefulWidget {
  const ThemeModePage({super.key});

  @override
  State<ThemeModePage> createState() => _ThemeModePageState();
}

class _ThemeModePageState extends State<ThemeModePage> {
  final AppearanceService _appearanceService = AppearanceService();
  ThemeMode _selectedThemeMode = ThemeMode.system;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final mode = await _appearanceService.loadThemeMode();
    setState(() {
      _selectedThemeMode = mode;
      _isLoading = false;
    });
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    await _appearanceService.saveThemeMode(mode);
    setState(() {
      _selectedThemeMode = mode;
    });
    // 通知主应用更新主题
    Get.snackbar('提示', '主题模式已更新', snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('主题模式')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 使用自定义的单选列表项，避免使用弃用的RadioGroup API
                _buildThemeOption(ThemeMode.system, '跟随系统', '根据系统设置自动切换主题'),
                _buildThemeOption(ThemeMode.light, '浅色模式', '始终使用浅色主题'),
                _buildThemeOption(ThemeMode.dark, '深色模式', '始终使用深色主题'),
              ],
            ),
    );
  }

  /// 构建主题选项列表项
  Widget _buildThemeOption(ThemeMode mode, String title, String subtitle) {
    return InkWell(
      onTap: () => _saveThemeMode(mode),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          children: [
            // 使用自定义的单选按钮样式
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _selectedThemeMode == mode
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                  width: 2,
                ),
                color: _selectedThemeMode == mode
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
              ),
              child: _selectedThemeMode == mode
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
