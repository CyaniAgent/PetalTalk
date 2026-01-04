import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import '../../api/flarum_api.dart';

class EndpointSelectionPage extends StatefulWidget {
  const EndpointSelectionPage({Key? key}) : super(key: key);

  @override
  State<EndpointSelectionPage> createState() => _EndpointSelectionPageState();
}

class _EndpointSelectionPageState extends State<EndpointSelectionPage> {
  final TextEditingController _endpointController = TextEditingController();
  final FlarumApi _api = FlarumApi();
  bool _isLoading = false;
  final bool _canSelectEndpoint = true; // 控制是否可以选择端点

  @override
  void initState() {
    super.initState();
    // 默认端点
    _endpointController.text = 'https://flarum.imikufans.cn/';
  }

  // 保存端点设置
  Future<void> _saveEndpoint() async {
    final endpoint = _endpointController.text.trim();

    if (endpoint.isEmpty) {
      Get.snackbar('提示', '请输入端点URL', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // 验证URL格式
    final uri = Uri.tryParse(endpoint);
    if (uri == null || !uri.hasAbsolutePath) {
      Get.snackbar('提示', '请输入有效的URL', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // 确保URL不包含尾部斜杠
    final cleanedUrl = endpoint.endsWith('/')
        ? endpoint.substring(0, endpoint.length - 1)
        : endpoint;

    setState(() {
      _isLoading = true;
    });

    // 保存端点到本地存储
    await _api.saveEndpoint(cleanedUrl);

    setState(() {
      _isLoading = false;
    });

    // 保存成功，跳转到首页
    Get.offAllNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 应用标题
                  Text(
                    'Flarum 客户端',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '连接到您的 Flarum 社区',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.visible,
                  ),
                  const SizedBox(height: 48),

                  // 端点输入框
                  TextField(
                    controller: _endpointController,
                    enabled: _canSelectEndpoint,
                    decoration: InputDecoration(
                      labelText: 'Flarum 端点 URL',
                      hintText: '例如: https://flarum.example.com',
                      prefixIcon: const Icon(Icons.link),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saveEndpoint(),
                  ),
                  const SizedBox(height: 8),

                  // 提示文字
                  Text(
                    '请输入您的 Flarum 社区 URL，确保包含 http:// 或 https://',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.visible,
                  ),
                  const SizedBox(height: 32),

                  // 保存按钮
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveEndpoint,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('连接'),
                  ),
                  const SizedBox(height: 16),

                  // 跳过按钮（如果不允许选择端点）
                  if (!_canSelectEndpoint)
                    TextButton(
                      onPressed: () {
                        // 使用默认端点直接进入
                        Get.offAllNamed('/home');
                      },
                      child: const Text('使用默认端点'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
