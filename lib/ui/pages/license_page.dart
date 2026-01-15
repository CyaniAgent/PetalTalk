import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/logger.dart';

class AppLicensePage extends StatefulWidget {
  const AppLicensePage({super.key});

  @override
  State<AppLicensePage> createState() => _AppLicensePageState();
}

class _AppLicensePageState extends State<AppLicensePage> {
  final AppLogger _logger = AppLogger();
  String _projectLicense = '';
  bool _isLoading = true;
  Map<String, String> _dependencyLicenses = {};

  @override
  void initState() {
    super.initState();
    _logger.info('LicensePage初始化');
    _loadLicenses();
  }

  // 加载许可证
  Future<void> _loadLicenses() async {
    try {
      // 加载自己项目的许可证
      await _loadProjectLicense();
      // 加载依赖的许可证
      await _loadDependencyLicenses();
    } catch (e, stackTrace) {
      _logger.error('加载许可证出错', e, stackTrace);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 加载自己项目的许可证
  Future<void> _loadProjectLicense() async {
    try {
      // 尝试从assets加载许可证文件
      _projectLicense = await rootBundle.loadString('LICENSE');
      _logger.info('项目许可证加载成功');
    } catch (e, stackTrace) {
      _logger.error('加载项目许可证出错', e, stackTrace);
      // 如果从assets加载失败，使用默认的MIT许可证
      _projectLicense = '''MIT License

Copyright (c) 2026 SakuraCake

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.''';
    }
  }

  // 加载依赖的许可证
  Future<void> _loadDependencyLicenses() async {
    try {
      final Map<String, String> licenses = {};

      // 定义依赖列表及其对应的许可证文件名
      final dependencies = {
        'Flutter': 'flutter.txt',
        'GetX': 'get.txt',
        'logger': 'logger.txt',
        // 可以根据需要添加更多依赖
      };

      // 逐个加载许可证文件
      for (final entry in dependencies.entries) {
        final packageName = entry.key;
        final fileName = entry.value;
        try {
          final licenseContent = await rootBundle.loadString(
            'assets/licenses/$fileName',
          );
          licenses[packageName] = licenseContent;
        } catch (e) {
          _logger.warning('加载依赖 $packageName 的许可证失败: $e');
        }
      }

      _dependencyLicenses = licenses;
      _logger.info('依赖许可证加载成功');
    } catch (e, stackTrace) {
      _logger.error('加载依赖许可证出错', e, stackTrace);
      _dependencyLicenses = {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('许可证信息')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 项目许可证
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '项目许可证',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              _projectLicense,
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 依赖许可证
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '依赖许可证',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_dependencyLicenses.isEmpty)
                            const Text('暂无依赖许可证信息')
                          else
                            ExpansionPanelList.radio(
                              expansionCallback: (int index, bool isExpanded) {
                                setState(() {
                                  // 这里可以添加展开/收起状态管理
                                });
                              },
                              children: _dependencyLicenses.entries
                                  .map(
                                    (entry) => ExpansionPanelRadio(
                                      value: entry.key,
                                      headerBuilder: (context, isExpanded) =>
                                          ListTile(title: Text(entry.key)),
                                      body: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: colorScheme
                                                .surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: SelectableText(
                                            entry.value,
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
