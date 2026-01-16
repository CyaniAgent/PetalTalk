import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart' as windows;
import 'package:webview_flutter/webview_flutter.dart' as mobile;
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
  // Desktop controller
  late windows.WebviewController _windowsController;
  // Mobile controller
  late mobile.WebViewController _mobileController;

  Timer? _cookieTimer;
  bool _isWebviewInitialized = false;
  bool _isWindows = Platform.isWindows;

  @override
  void initState() {
    super.initState();
    if (_isWindows) {
      _initWindowsWebview();
    } else {
      _initMobileWebview();
    }
  }

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

      // Start checking for the verification cookie
      _startCookieCheck();
    } catch (e) {
      if (mounted) {
        Get.back();
      }
    }
  }

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
          // mobile returns quoted string sometimes
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
              // Title Bar
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
              // WebView Area
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
