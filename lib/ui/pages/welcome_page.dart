import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import '../../api/flarum_api.dart';
import '../../global_services/appearance_service.dart';
import '../../utils/snackbar_utils.dart';
import '../../config/constants.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // 禁止手动滑动，必须通过按钮
        children: [
          _buildWelcomePage(),
          _buildEndpointPage(),
          _buildAppearancePage(),
          _buildAboutPage(),
          _buildAllSetPage(),
        ],
      ),
    );
  }

  // --- Page 1: Welcome ---
  Widget _buildWelcomePage() {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '0.0.0';

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/icons/logo.png', width: 120, height: 120),
              const SizedBox(height: 32),
              Text(
                '欢迎使用 PetalTalk!',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '版本: $version',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 64),
              FilledButton(
                onPressed: _nextPage,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                ),
                child: const Text('开始'),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Page 2: Endpoint Configuration ---
  Widget _buildEndpointPage() {
    return _EndpointStep(onNext: _nextPage);
  }

  // --- Page 3: Appearance Settings ---
  Widget _buildAppearancePage() {
    return _AppearanceStep(onNext: _nextPage);
  }

  // --- Page 4: About Info ---
  Widget _buildAboutPage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '关于 PetalTalk',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            const Text(
              'PetalTalk 是一个优雅、高效的 Flarum 社区客户端.\n\n' // Corrected escaped newline
              '开发者: CyaniAgent\n' // Corrected escaped newline
              '基于 Flutter 框架开发\n',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            const Text(
              '特别感谢:\n' // Corrected escaped newline
              'Flarum - 开源论坛软件\n' // Corrected escaped newline
              'Flutter - 跨平台应用框架\n',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 64),
            FilledButton(onPressed: _nextPage, child: const Text('下一步')),
          ],
        ),
      ),
    );
  }

  // --- Page 5: All Set & Animation ---
  Widget _buildAllSetPage() {
    return _AllSetStep();
  }
}

// --- Endpoint Step Widget ---
class _EndpointStep extends StatefulWidget {
  final VoidCallback onNext;

  const _EndpointStep({required this.onNext});

  @override
  State<_EndpointStep> createState() => _EndpointStepState();
}

class _EndpointStepState extends State<_EndpointStep> {
  final TextEditingController _endpointController = TextEditingController();
  final FlarumApi _api = FlarumApi();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _endpointController.text = 'https://flarum.imikufans.cn/';
  }

  Future<void> _saveEndpoint() async {
    final endpoint = _endpointController.text.trim();
    if (endpoint.isEmpty) {
      SnackbarUtils.showSnackbar('请输入端点URL');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cleanedUrl = endpoint.endsWith('/')
          ? endpoint.substring(0, endpoint.length - 1)
          : endpoint;

      final tempDio = Dio();
      tempDio.httpClientAdapter = Http2Adapter(
        ConnectionManager(idleTimeout: const Duration(seconds: 10)),
      );

      final response = await tempDio.get(
        '$cleanedUrl/api',
        options: Options(
          followRedirects: false,
          validateStatus: (status) => status != null,
          headers: {'Accept': 'application/json'},
        ),
      );

      if (response.statusCode != 200) {
        if (mounted) {
          SnackbarUtils.showSnackbar('端点响应异常，状态码：${response.statusCode}');
          setState(() => _isLoading = false);
        }
        return;
      }

      await _api.saveEndpoint(cleanedUrl);
      if (mounted) {
        await _showUserAgentDialog();
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showSnackbar('无法连接到端点，请检查URL');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showUserAgentDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('是否使用专用User Agent？'),
        content: const Text(
          '此User Agent已加入雷池WAF白名单，并使用了最新的Chrome 144内核。你需要切换吗？',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onNext();
            },
            child: const Text('不，谢谢'),
          ),
          FilledButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(
                Constants.userAgentTypeKey,
                Constants.userAgentTypeChrome,
              );
              if (context.mounted) {
                Navigator.of(context).pop();
                widget.onNext();
              }
            },
            child: const Text('切换'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '配置端点',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text('请输入您的 Flarum 社区 URL', textAlign: TextAlign.center),
          const SizedBox(height: 32),
          TextField(
            controller: _endpointController,
            decoration: InputDecoration(
              labelText: 'Flarum 端点 URL',
              hintText: 'https://example.com',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveEndpoint,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(),
                  )
                : const Text('连接并继续'),
          ),
        ],
      ),
    );
  }
}

// --- Appearance Step Widget ---
class _AppearanceStep extends StatefulWidget {
  final VoidCallback onNext;

  const _AppearanceStep({required this.onNext});

  @override
  State<_AppearanceStep> createState() => _AppearanceStepState();
}

class _AppearanceStepState extends State<_AppearanceStep> {
  final AppearanceService _appearanceService = AppearanceService();

  // Rx vars for UI updates
  final RxBool _isDarkMode = false.obs;
  final RxBool _useDynamicColor = true.obs;
  final RxString _accentColor = 'blue'.obs;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final mode = await _appearanceService.loadThemeMode();
    _isDarkMode.value = mode == ThemeMode.dark;
    _useDynamicColor.value = await _appearanceService.loadUseDynamicColor();
    _accentColor.value = await _appearanceService.loadAccentColor();
  }

  Future<void> _toggleDarkMode(bool value) async {
    final themeMode = value ? ThemeMode.dark : ThemeMode.light;
    await _appearanceService.saveThemeMode(themeMode);
    _isDarkMode.value = value;
    Get.changeThemeMode(themeMode);
  }

  Future<void> _toggleDynamicColor(bool value) async {
    await _appearanceService.saveUseDynamicColor(value);
    _useDynamicColor.value = value;
    // Notify user to restart for full effect, but for welcome page just save it
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('外观设置', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 32),
          Obx(
            () => SwitchListTile(
              title: const Text('深色模式'),
              value: _isDarkMode.value,
              onChanged: _toggleDarkMode,
            ),
          ),
          Obx(
            () => SwitchListTile(
              title: const Text('动态色彩 (Material 3)'),
              value: _useDynamicColor.value,
              onChanged: _toggleDynamicColor,
            ),
          ),
          const SizedBox(height: 48),
          FilledButton(onPressed: widget.onNext, child: const Text('下一步')),
        ],
      ),
    );
  }
}

// --- All Set Step Widget ---
class _AllSetStep extends StatefulWidget {
  @override
  State<_AllSetStep> createState() => _AllSetStepState();
}

class _AllSetStepState extends State<_AllSetStep> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FocusNode _focusNode = FocusNode();
  bool _showSwipeHint = false;
  bool _permissionsGranted = false;

  bool get _isDesktop => GetPlatform.isDesktop;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      // 请求存储和通知权限
      await [
        Permission.storage,
        Permission.notification,
        Permission.manageExternalStorage,
      ].request();

      // 无论结果如何，我们在欢迎页面都继续（或者可以根据需要更严格）
      // 这里我们标记为已授予，以便开始动画
      if (mounted) {
        setState(() {
          _permissionsGranted = true;
        });
        _playSound();
      }
    } else {
      // 非 Android 平台直接标记为已授予
      if (mounted) {
        setState(() {
          _permissionsGranted = true;
        });
        _playSound();
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _playSound() async {
    await _audioPlayer.play(AssetSource('sounds/AllSet.wav'));
  }

  Widget _buildStatusLine(String text, int delayMs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: TypewriterText(
        text: text,
        duration: const Duration(milliseconds: 450),
        delay: Duration(milliseconds: delayMs),
        style: TextStyle(
          fontFamily: 'MiSans',
          fontSize: 12,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _finishWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_welcome', true);
    Get.offAllNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final countdownStyle = Theme.of(context).textTheme.displayLarge?.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: 80,
      color: Theme.of(context).colorScheme.primary,
    );

    final finalTextStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.primary,
    );

    final subTextStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Scaffold(
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (event) {
          if (_showSwipeHint && _isDesktop && event is KeyDownEvent) {
            _finishWelcome();
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_showSwipeHint && _isDesktop) {
              _finishWelcome();
            }
          },
          onVerticalDragEnd: (details) {
            if (!_isDesktop) {
              final velocity = details.primaryVelocity ?? 0;
              if (_showSwipeHint && velocity < -500) {
                // Swipe Up detected (negative velocity is up)
                _finishWelcome();
              }
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. 替代 Lottie 的动态背景：流动的渐变
              const AnimatedGradientBackground(),

              if (_permissionsGranted) ...[
                // 1.1 背景变黑遮罩 (Fade to black)
                // 持续时间覆盖整个倒计时过程 (约3.5秒)
                Container(color: Colors.black)
                    .animate()
                    .fadeIn(duration: const Duration(milliseconds: 500))
                    .fadeOut(
                      delay: const Duration(milliseconds: 3500),
                      duration: const Duration(milliseconds: 500),
                    ),

                // 1.2 倒计时背景图 3
                ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.5),
                        BlendMode.darken,
                      ),
                      child: Image.asset(
                        'assets/images/Countdown-num3.png',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: const Duration(milliseconds: 500))
                    .fadeOut(
                      delay: const Duration(milliseconds: 1000),
                      duration: const Duration(milliseconds: 300),
                    ),

                // 1.3 倒计时背景图 2
                ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.5),
                        BlendMode.darken,
                      ),
                      child: Image.asset(
                        'assets/images/Countdown-num2.jpg',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                    .animate(delay: const Duration(milliseconds: 1000))
                    .fadeIn(duration: const Duration(milliseconds: 300))
                    .fadeOut(
                      delay: const Duration(milliseconds: 1000),
                      duration: const Duration(milliseconds: 300),
                    ),

                // 1.4 倒计时背景图 1
                ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.5),
                        BlendMode.darken,
                      ),
                      child: Image.asset(
                        'assets/images/Countdown-num1.png',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                    .animate(delay: const Duration(milliseconds: 2000))
                    .fadeIn(duration: const Duration(milliseconds: 300))
                    .fadeOut(
                      delay: const Duration(milliseconds: 1000),
                      duration: const Duration(milliseconds: 300),
                    ),

                // --- Status Typewriter Lines ---
                Positioned(
                  top: MediaQuery.of(context).padding.top + 40,
                  left: 32,
                  right: 32,
                  child:
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusLine("Checking permissions... OK.", 0),
                          _buildStatusLine(
                            "Checking API access... Successful.",
                            500,
                          ),
                          _buildStatusLine(
                            "Initializing log debugging function... OK.",
                            1000,
                          ),
                          _buildStatusLine(
                            "Initializing application... Completed.",
                            1500,
                          ),
                          _buildStatusLine("Final Audition...", 2000),
                          _buildStatusLine("All Set!", 2500),
                        ],
                      ).animate().fadeOut(
                        delay: const Duration(milliseconds: 3000),
                        duration: const Duration(milliseconds: 300),
                      ),
                ),
                // 2. 核心动画逻辑：倒计时 -> 设置完成
                // 数字 3
                Text("3", style: countdownStyle)
                    .animate()
                    .fadeIn(duration: const Duration(milliseconds: 300))
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      curve: Curves.easeOutBack,
                    )
                    .fadeOut(
                      delay: const Duration(milliseconds: 700),
                      duration: const Duration(milliseconds: 200),
                    ),

                // 数字 2
                Text("2", style: countdownStyle)
                    .animate(delay: const Duration(milliseconds: 1000)) // 1秒后开始
                    .fadeIn(duration: const Duration(milliseconds: 300))
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      curve: Curves.easeOutBack,
                    )
                    .fadeOut(
                      delay: const Duration(milliseconds: 700),
                      duration: const Duration(milliseconds: 200),
                    ),

                // 数字 1
                Text("1", style: countdownStyle)
                    .animate(delay: const Duration(milliseconds: 2000)) // 2秒后开始
                    .fadeIn(duration: const Duration(milliseconds: 300))
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      curve: Curves.easeOutBack,
                    )
                    .fadeOut(
                      delay: const Duration(milliseconds: 700),
                      duration: const Duration(milliseconds: 200),
                    ),

                // 3. 衔接点：3.35秒左右出现的“设置完成！”
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("配置完成！", style: finalTextStyle)
                        .animate(
                          delay: const Duration(milliseconds: 3350),
                          onPlay: (controller) => Future.delayed(
                            const Duration(milliseconds: 3500),
                            () {
                              if (mounted)
                                setState(() => _showSwipeHint = true);
                            },
                          ),
                        ) // 精确匹配你要求的 335 帧（3.35秒）
                        .fadeIn(duration: const Duration(milliseconds: 600))
                        .slideY(begin: 0.3, end: 0, curve: Curves.easeOutQuart)
                        .shimmer(
                          delay: const Duration(milliseconds: 4000),
                          duration: const Duration(milliseconds: 1500),
                        ), // 增加一个像 Framer Motion 的光泽效果

                    const SizedBox(height: 10),

                    Text("You're All Set!", style: subTextStyle)
                        .animate(delay: const Duration(milliseconds: 3600))
                        .fadeIn()
                        .moveY(begin: 10, end: 0),
                  ],
                ),

                if (_showSwipeHint)
                  Positioned(
                    bottom: 64,
                    left: 0,
                    right: 0,
                    child:
                        Column(
                              children: [
                                Text(
                                  _isDesktop ? '按任意键或单击鼠标进入应用' : '上滑进入应用',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                if (!_isDesktop)
                                  const Icon(Icons.keyboard_arrow_up, size: 32),
                              ],
                            )
                            .animate()
                            .fadeIn(duration: const Duration(milliseconds: 500))
                            .moveY(begin: 20, end: 0),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedGradientBackground extends StatelessWidget {
  const AnimatedGradientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(color: Theme.of(context).colorScheme.surface)
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .tint(
          color: Theme.of(context).colorScheme.primaryContainer.withAlpha(76),
          duration: const Duration(seconds: 3),
        );
  }
}

class TypewriterText extends StatefulWidget {
  final String text;
  final Duration duration;
  final Duration delay;
  final TextStyle? style;

  const TypewriterText({
    super.key,
    required this.text,
    required this.duration,
    this.delay = Duration.zero,
    this.style,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _characterCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _characterCount = StepTween(
      begin: 0,
      end: widget.text.length,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _characterCount,
      builder: (context, child) {
        final text = widget.text.substring(0, _characterCount.value);
        return Text(text, style: widget.style);
      },
    );
  }
}
