import 'package:get/get.dart';

class UiSettingController extends GetxController {
  RxBool userLogin = false.obs;
  late bool showLogoutButton;

  @override
  void onInit() {
    super.onInit();
    showLogoutButton = false; // 默认不显示退出登录按钮
  }

  /// 退出登录
  void loginOut() {
    // 这里可以添加退出登录的逻辑
    Get.snackbar('提示', '退出登录');
  }
}