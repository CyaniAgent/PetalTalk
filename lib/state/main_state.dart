import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/snackbar_utils.dart';
import '../core/logger.dart';
import '../config/constants.dart';

// 动态徽章模式枚举
enum DynamicBadgeMode { hidden, point, number }

extension DynamicBadgeModeDesc on DynamicBadgeMode {
  String get description => ['隐藏', '红点', '数字'][index];
}

extension DynamicBadgeModeCode on DynamicBadgeMode {
  int get code => [0, 1, 2][index];
}

class UiMainController extends GetxController {
  final AppLogger _logger = AppLogger();
  RxList<Widget> pages = <Widget>[].obs;
  RxList<int> pagesIds = <int>[].obs;
  RxList<Map<String, dynamic>> navigationBars = <Map<String, dynamic>>[].obs;
  final StreamController<bool> bottomBarStream =
      StreamController<bool>.broadcast();
  DateTime? _lastPressedAt;
  late PageController pageController;
  RxInt selectedIndex = 0.obs;
  RxBool userLogin = false.obs;
  Rx<DynamicBadgeMode> dynamicBadgeType = DynamicBadgeMode.point.obs; // 默认红点模式
  RxBool enableGradientBg = true.obs;
  RxBool imgPreviewStatus = false.obs;

  @override
  void onInit() {
    super.onInit();
    _logger.info('UiMainController初始化');
    pageController = PageController(initialPage: selectedIndex.value);
    _logger.debug(
      '初始化设置: selectedIndex = ${selectedIndex.value}, dynamicBadgeType = ${dynamicBadgeType.value}, enableGradientBg = ${enableGradientBg.value}',
    );
  }

  @override
  void onReady() {
    super.onReady();
    _logger.info('UiMainController准备就绪');
  }

  /// 设置导航栏配置
  void setNavBarConfig(List<Map<String, dynamic>> navItems) {
    _logger.debug('设置导航栏配置: 项目数量 = ${navItems.length}');
    navigationBars.value = navItems;
    pagesIds.value = navigationBars.map<int>((e) => e['id']).toList();
    _logger.debug('导航栏配置更新完成: pagesIds = $pagesIds');

    // 只有在pages列表为空或者页面数量发生变化时，才重新创建页面列表
    // 否则，保持现有页面实例不变，避免状态丢失
    if (pages.isEmpty || pages.length != navItems.length) {
      _logger.debug(
        '重新创建页面列表: 旧数量 = ${pages.length}, 新数量 = ${navItems.length}',
      );
      pages.value = navigationBars.map<Widget>((e) => e['page']).toList();
      _logger.info('页面列表更新完成: 新页面数量 = ${pages.length}');
    } else {
      _logger.debug('保持现有页面实例不变');
    }
  }

  /// 处理返回按钮点击
  void onBackPressed(BuildContext context) {
    _logger.debug('处理返回按钮点击 - 当前页面索引: ${selectedIndex.value}');
    if (_lastPressedAt == null ||
        DateTime.now().difference(_lastPressedAt!) >
            Constants.doubleTapExitDuration) {
      // 两次点击时间间隔超过2秒，重新记录时间戳
      _lastPressedAt = DateTime.now();
      _logger.debug('记录第一次返回按钮点击时间: $_lastPressedAt');

      if (selectedIndex.value != 0) {
        _logger.debug('跳转到首页（索引0）');
        pageController.jumpToPage(0);
      }
      // 使用优化后的SnackbarUtils
      SnackbarUtils.showSnackbar(
        '再按一次退出',
        duration: Constants.doubleTapExitDuration,
      );
      _logger.info('显示退出提示');
      return; // 不退出应用
    }
    _logger.info('第二次返回按钮点击，退出应用');
    Navigator.of(context).pop(); // 退出应用
  }

  /// 设置选中索引
  void setSelectedIndex(int index) {
    _logger.debug('设置选中索引: 从 ${selectedIndex.value} 到 $index');
    selectedIndex.value = index;
    pageController.jumpToPage(index);
    _logger.info('页面切换完成: 索引 = $index');
  }

  /// 清除未读消息
  void clearUnread(int itemId) {
    _logger.debug('清除未读消息: itemId = $itemId');
    final int index = navigationBars.indexWhere((item) => item['id'] == itemId);
    if (index != -1) {
      // 直接更新特定索引的元素，避免整个列表刷新
      navigationBars[index] = {...navigationBars[index], 'count': 0};
      update(['navigation_bars']); // 只更新需要的部分
      _logger.info('未读消息清除成功: 导航项索引 = $index, itemId = $itemId');
    } else {
      _logger.warning('未找到对应的导航项: itemId = $itemId');
    }
  }

  /// 更新未读消息数
  void updateUnreadCount(int itemId, int count) {
    _logger.debug('更新未读消息数: itemId = $itemId, 新计数 = $count');
    final int index = navigationBars.indexWhere((item) => item['id'] == itemId);
    if (index != -1) {
      // 直接更新特定索引的元素，避免整个列表刷新
      navigationBars[index] = {...navigationBars[index], 'count': count};
      update(['navigation_bars']); // 只更新需要的部分
      _logger.info('未读消息数更新成功: 导航项索引 = $index, itemId = $itemId, 计数 = $count');
    } else {
      _logger.warning('未找到对应的导航项: itemId = $itemId');
    }
  }

  @override
  void onClose() {
    _logger.info('UiMainController关闭，释放资源');
    bottomBarStream.close();
    pageController.dispose();
    _logger.debug('资源释放完成');
    super.onClose();
  }
}
