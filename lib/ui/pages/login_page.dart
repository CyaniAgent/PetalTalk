import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:petal_talk/state/main_state.dart';

import '../../api/services/auth_service.dart';
import '../../utils/snackbar_utils.dart';

// 登录控制器，管理登录状态
class LoginController extends GetxController {
  final _authService = Get.find<AuthService>();

  // 使用GetX的响应式变量
  final isLoading = false.obs;
  final rememberMe = false.obs;

  // 表单控制器
  final formKey = GlobalKey<FormState>();
  final identificationController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void onClose() {
    identificationController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  // 处理登录
  Future<void> handleLogin() async {
    if (formKey.currentState!.validate()) {
      isLoading.value = true;

      final result = await _authService.login(
        identification: identificationController.text,
        password: passwordController.text,
        remember: rememberMe.value,
      );

      isLoading.value = false;

      if (result != null) {
        // 登录成功，重置侧边栏选中项为首页
        final mainController = Get.find<UiMainController>();
        mainController.setSelectedIndex(0);
        // 跳转到首页
        Get.offAllNamed('/home');
      } else {
        // 登录失败，显示错误信息
        SnackbarUtils.showMaterialSnackbar(Get.context!, '用户名或密码错误');
      }
    }
  }

  // 切换记住我状态
  void toggleRememberMe(bool? value) {
    rememberMe.value = value ?? false;
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final controller = Get.isRegistered<LoginController>()
        ? Get.find<LoginController>()
        : Get.put(LoginController());

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Get.back();
          },
        ),
        title: const Text('登录'),
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Text('欢迎回来', style: textTheme.headlineLarge),
                  const SizedBox(height: 8),
                  Text('请登录您的账户', style: textTheme.bodyLarge),
                  const SizedBox(height: 48),

                  // 登录表单
                  Form(
                    key: controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 用户名/邮箱
                        TextFormField(
                          controller: controller.identificationController,
                          decoration: InputDecoration(
                            labelText: '用户名或邮箱',
                            hintText: '请输入用户名或邮箱',
                            prefixIcon: const Icon(Icons.person_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入用户名或邮箱';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // 密码
                        TextFormField(
                          controller: controller.passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: '密码',
                            hintText: '请输入密码',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入密码';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // 记住我和忘记密码
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Obx(
                                  () => Checkbox(
                                    value: controller.rememberMe.value,
                                    onChanged: controller.toggleRememberMe,
                                  ),
                                ),
                                const Text('记住我'),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                // TODO: 忘记密码
                                SnackbarUtils.showDevelopmentInProgress(
                                  context,
                                );
                              },
                              child: const Text('忘记密码?'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // 登录按钮
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: controller.isLoading.value
                                ? null
                                : controller.handleLogin,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: textTheme.titleMedium,
                            ),
                            child: Obx(
                              () => controller.isLoading.value
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('登录'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 注册入口
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('还没有账户?'),
                        TextButton(
                          onPressed: () {
                            // TODO: 跳转到注册页面
                            SnackbarUtils.showDevelopmentInProgress(context);
                          },
                          child: const Text('立即注册'),
                        ),
                      ],
                    ),
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
