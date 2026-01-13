import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:get/get.dart';

class VerificationWindow extends StatefulWidget {
  final String url;

  const VerificationWindow({super.key, required this.url});

  /// Shows the verification window dialog.
  /// Returns the verification cookie value if successful, or null if cancelled/failed.
  static Future<String?> show(String url) async {
    return await Get.dialog<String?>(
      VerificationWindow(url: url),
      barrierDismissible: false,
    );
  }

  @override
  State<VerificationWindow> createState() => _VerificationWindowState();
}

class _VerificationWindowState extends State<VerificationWindow> {
  final _controller = WebviewController();
  Timer? _cookieTimer;
  bool _isWebviewInitialized = false;

  @override
  void initState() {
    super.initState();
    _initWebview();
  }

  Future<void> _initWebview() async {
    try {
      await _controller.initialize();
      await _controller.setBackgroundColor(Colors.transparent);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);

      if (!mounted) return;
      setState(() {
        _isWebviewInitialized = true;
      });

      await _controller.loadUrl(widget.url);

      // Start checking for the verification cookie
      _startCookieCheck();
    } catch (e) {
      // Handle initialization error (e.g., runtime not installed)
      if (mounted) {
        Get.back(); // Close dialog on error
      }
    }
  }

  void _startCookieCheck() {
    _cookieTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) async {
      if (!_controller.value.isInitialized) return;

      try {
        // webview_windows doesn't support getCookies, use JS to get document.cookie
        final cookiesString = await _controller.executeScript(
          'document.cookie',
        );

        if (cookiesString != null && cookiesString.isNotEmpty) {
          // Parse "key=value; key2=value2"
          final cookies = cookiesString.toString().split(';');
          for (final cookie in cookies) {
            final parts = cookie.trim().split('=');
            if (parts.isNotEmpty && parts[0] == 'acw_sc__v2') {
              // Found it!
              if (parts.length > 1) {
                _onVerificationSuccess(parts[1]);
                return;
              }
            }
          }
        }
      } catch (_) {
        // Ignore JS errors
      }
    });
  }

  void _onVerificationSuccess(String cookieValue) {
    _cookieTimer?.cancel();
    if (mounted) {
      Get.back(result: cookieValue);
    }
  }

  @override
  void dispose() {
    _cookieTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 桌面端建议给一个合适的大小
    return Center(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        elevation: 8,
        child: Container(
          width: 800,
          height: 600,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              // Title Bar
              Container(
                height: 40,
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
                      icon: const Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),
              // WebView Area
              Expanded(
                child: _isWebviewInitialized
                    ? Webview(_controller)
                    : const Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
