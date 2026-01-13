import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/logger.dart';
import '../../utils/snackbar_utils.dart';

/// 日志查看页面
class LogViewerPage extends StatefulWidget {
  const LogViewerPage({super.key});

  @override
  State<LogViewerPage> createState() => _LogViewerPageState();
}

class _LogViewerPageState extends State<LogViewerPage> {
  final AppLogger _logger = AppLogger();

  /// 日志内容列表
  List<String> _logLines = [];

  /// 加载状态
  bool _isLoading = true;

  /// 滚动控制器
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 加载日志内容
  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _logLines = await _logger.viewLogs();
      _logger.info('加载日志成功，共 ${_logLines.length} 行');

      // 滚动到底部
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e, stackTrace) {
      _logger.error('加载日志失败', e, stackTrace);
      SnackbarUtils.showSnackbar('加载日志失败', type: SnackbarType.error);
      _logLines = ['加载日志失败: $e'];
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 刷新日志
  Future<void> _refreshLogs() async {
    await _loadLogs();
  }

  /// 清空日志
  Future<void> _clearLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认清空日志'),
          content: const Text('确定要清空所有日志吗？此操作不可恢复。'),
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
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('清空'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _logger.deleteLogs();
        _logger.info('日志清空成功');
        setState(() {
          _logLines = [];
        });
        SnackbarUtils.showSnackbar('日志已清空');
      } catch (e, stackTrace) {
        _logger.error('清空日志失败', e, stackTrace);
        SnackbarUtils.showSnackbar('清空日志失败', type: SnackbarType.error);
      }
    }
  }

  /// 复制日志到剪贴板
  Future<void> _copyLogs() async {
    try {
      final logs = _logLines.join('\n');
      await Clipboard.setData(ClipboardData(text: logs));
      _logger.info('日志复制成功');
      SnackbarUtils.showSnackbar('日志已复制到剪贴板');
    } catch (e, stackTrace) {
      _logger.error('复制日志失败', e, stackTrace);
      SnackbarUtils.showSnackbar('复制日志失败', type: SnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日志查看'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLogs,
            tooltip: '刷新日志',
          ),
          IconButton(
            icon: const Icon(Icons.copy_all),
            onPressed: _copyLogs,
            tooltip: '复制日志',
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _clearLogs,
            tooltip: '清空日志',
            color: Colors.red,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logLines.isEmpty
          ? const Center(child: Text('没有日志内容'))
          : RefreshIndicator(
              onRefresh: _refreshLogs,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _logLines.length,
                itemBuilder: (context, index) {
                  final line = _logLines[index];

                  // 根据日志级别设置不同颜色
                  Color textColor = Theme.of(
                    context,
                  ).textTheme.bodyMedium!.color!;
                  if (line.contains('ERROR') || line.contains('error')) {
                    textColor = Colors.red;
                  } else if (line.contains('WARNING') ||
                      line.contains('warning') ||
                      line.contains('WARN')) {
                    textColor = Colors.orange;
                  } else if (line.contains('INFO') || line.contains('info')) {
                    textColor = Colors.blue;
                  } else if (line.contains('DEBUG') || line.contains('debug')) {
                    textColor = Colors.green;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    child: Text(
                      line,
                      style: TextStyle(
                        color: textColor,
                        fontFamily: 'Monospace',
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  );
                },
              ),
            ),
    );
  }
}
