/// 验证窗口组件，用于处理需要网页验证的场景
///
/// 该组件提供：
/// 1. 跨平台网页验证支持（桌面和移动）
/// 2. 自动检测验证cookie
/// 3. 安全的验证流程
/// 4. 响应式设计，适配不同平台
///
/// 工作原理：
/// - 在桌面平台使用webview_windows库
/// - 在移动平台使用webview_flutter库
/// - 定期检查页面cookie，获取验证信息
/// - 验证成功后返回验证cookie值
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart' as windows;
import 'package:webview_flutter/webview_flutter.dart' as mobile;
import 'package:get/get.dart';

/// 验证窗口组件，用于显示网页验证界面并自动获取验证cookie
class VerificationWindow extends StatefulWidget {
  /// 验证页面的URL
  final String url;

  /// 创建验证窗口实例
  ///
  /// [url] - 需要加载的验证页面URL
  const VerificationWindow({super.key, required this.url});

  /// 显示验证窗口对话框
  ///
  /// [url] - 需要加载的验证页面URL
  ///
  /// 返回值：
  /// - String?: 验证成功返回验证cookie值，验证失败或取消返回null
  static Future<String?> show(String url) async {
    return await Get.dialog<String?>(
      VerificationWindow(url: url),
      barrierDismissible: false,
    );
  }

  @override
  State<VerificationWindow> createState() => _VerificationWindowState();
}

/// VerificationWindow的状态管理类
class _VerificationWindowState extends State<VerificationWindow> {
  /// 桌面平台WebView控制器
  late windows.WebviewController _windowsController;
  
  /// 移动平台WebView控制器
  late mobile.WebViewController _mobileController;

  /// 用于定期检查cookie的定时器
  Timer? _cookieTimer;
  
  /// WebView初始化状态
  bool _isWebviewInitialized = false;
  
  /// 是否为Windows平台
  final bool _isWindows = Platform.isWindows;

  @override
  void initState() {
    super.initState();
    // 根据平台初始化不同的WebView
    if (_isWindows) {
      _initWindowsWebview();
    } else {
      _initMobileWebview();
    }
  }

  /// 初始化Windows平台WebView
  ///
  /// 负责创建和配置Windows平台的WebView控制器
  Future<void> _initWindowsWebview() async {
    _windowsController = windows.WebviewController();
    try {
      await _windowsController.initialize();
      await _windowsController.setBackgroundColor(Colors.transparent);
      await _windowsController.setPopupWindowPolicy(
        windows.WebviewPopupWindowPolicy.deny,
      );

      if (!mounted) return;
      setState(() {
        _isWebviewInitialized = true;
      });

      await _windowsController.loadUrl(widget.url);

      // 开始检查验证cookie
      _startCookieCheck();
    } catch (e) {
      if (mounted) {
        Get.back();
      }
    }
  }

  /// 初始化移动平台WebView
  ///
  /// 负责创建和配置移动平台的WebView控制器
  Future<void> _initMobileWebview() async {
    _mobileController = mobile.WebViewController()
      ..setJavaScriptMode(mobile.JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        mobile.NavigationDelegate(
          onPageFinished: (String url) {
            _startCookieCheck();
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    if (!mounted) return;
    setState(() {
      _isWebviewInitialized = true;
    });
  }

  /// 开始定期检查验证cookie
  ///
  /// 每1秒检查一次页面cookie，寻找验证cookie
  void _startCookieCheck() {
    _cookieTimer?.cancel();
    _cookieTimer = Timer.periodic(const Duration(milliseconds: 1000), (
      timer,
    ) async {
      try {
        String? cookiesString;
        if (_isWindows) {
          if (!_windowsController.value.isInitialized) return;
          cookiesString = await _windowsController.executeScript(
            'document.cookie',
          );
        } else {
          cookiesString =
              await _mobileController.runJavaScriptReturningResult(
                    'document.cookie',
                  )
                  as String?;
          // 移动平台有时会返回带引号的字符串
          if (cookiesString != null &&
              cookiesString.startsWith('"') &&
              cookiesString.endsWith('"')) {
            cookiesString = cookiesString.substring(
              1,
              cookiesString.length - 1,
            );
          }
        }

        if (cookiesString != null && cookiesString.isNotEmpty) {
          final cookies = cookiesString.split(';');
          for (final cookie in cookies) {
            final parts = cookie.trim().split('=');
            if (parts.isNotEmpty && parts[0] == 'acw_sc__v2') {
              if (parts.length > 1) {
                _onVerificationSuccess(parts[1]);
                return;
              }
            }
          }
        }
      } catch (_) {
        // 忽略JavaScript执行错误
      }
    });
  }

  /// 验证成功处理方法
  ///
  /// [cookieValue] - 获取到的验证cookie值
  void _onVerificationSuccess(String cookieValue) {
    _cookieTimer?.cancel();
    if (mounted) {
      Get.back(result: cookieValue);
    }
  }

  @override
  void dispose() {
    // 清理资源
    _cookieTimer?.cancel();
    if (_isWindows) {
      _windowsController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        elevation: 8,
        child: Container(
          width: _isWindows ? 800 : double.infinity,
          height: _isWindows ? 600 : double.infinity,
          margin: _isWindows ? EdgeInsets.zero : const EdgeInsets.all(16),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              // 标题栏
              Container(
                height: 48,
                color: Colors.grey[200],
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Security Verification',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),
              // WebView区域
              Expanded(
                child: _isWebviewInitialized
                    ? (_isWindows
                          ? windows.Webview(_windowsController)
                          : mobile.WebViewWidget(controller: _mobileController))
                    : const Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
