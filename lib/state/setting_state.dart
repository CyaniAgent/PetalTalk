import 'package:get/get.dart';
import '/utils/snackbar_utils.dart';
import '/core/logger.dart';

class UiSettingController extends GetxController {
  final AppLogger _logger = AppLogger();
  RxBool userLogin = false.obs;
  late bool showLogoutButton;

  @override
  void onInit() {
    super.onInit();
    _logger.info('UiSettingController初始化');
    showLogoutButton = false; // 默认不显示退出登录按钮
    _logger.debug('初始化设置: showLogoutButton = $showLogoutButton');
  }

  @override
  void onReady() {
    super.onReady();
    _logger.info('UiSettingController准备就绪');
  }

  @override
  void onClose() {
    _logger.info('UiSettingController关闭');
    super.onClose();
  }

  /// 退出登录
  void loginOut() {
    _logger.info('开始退出登录流程');
    try {
      // 这里可以添加退出登录的逻辑
      _logger.debug('退出登录逻辑执行中');
      SnackbarUtils.showSnackbar('退出登录成功');
      _logger.info('退出登录成功');
    } catch (e, stackTrace) {
      _logger.error('退出登录失败', e, stackTrace);
      SnackbarUtils.showSnackbar('退出登录失败', type: SnackbarType.error);
    }
  }
}
