import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/appearance_service.dart';

class ThemeModePage extends StatefulWidget {
  const ThemeModePage({Key? key}) : super(key: key);

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
      appBar: AppBar(
        title: const Text('主题模式'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('跟随系统'),
                  subtitle: const Text('根据系统设置自动切换主题'),
                  value: ThemeMode.system,
                  groupValue: _selectedThemeMode,
                  onChanged: (value) {
                    if (value != null) {
                      _saveThemeMode(value);
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('浅色模式'),
                  subtitle: const Text('始终使用浅色主题'),
                  value: ThemeMode.light,
                  groupValue: _selectedThemeMode,
                  onChanged: (value) {
                    if (value != null) {
                      _saveThemeMode(value);
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('深色模式'),
                  subtitle: const Text('始终使用深色主题'),
                  value: ThemeMode.dark,
                  groupValue: _selectedThemeMode,
                  onChanged: (value) {
                    if (value != null) {
                      _saveThemeMode(value);
                    }
                  },
                ),
              ],
            ),
    );
  }
}
