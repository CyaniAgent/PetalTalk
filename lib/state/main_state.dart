import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// 动态徽章模式枚举
enum DynamicBadgeMode { hidden, point, number }

extension DynamicBadgeModeDesc on DynamicBadgeMode {
  String get description => ['隐藏', '红点', '数字'][index];
}

extension DynamicBadgeModeCode on DynamicBadgeMode {
  int get code => [0, 1, 2][index];
}

class UiMainController extends GetxController {
  RxList<Widget> pages = <Widget>[].obs;
  RxList<int> pagesIds = <int>[].obs;
  RxList<Map<String, dynamic>> navigationBars = <Map<String, dynamic>>[].obs;
  final StreamController<bool> bottomBarStream =
      StreamController<bool>.broadcast();
  DateTime? _lastPressedAt;
  late PageController pageController;
  RxInt selectedIndex = 0.obs;
  RxBool userLogin = false.obs;
  late Rx<DynamicBadgeMode> dynamicBadgeType = DynamicBadgeMode.number.obs;
  RxBool enableGradientBg = true.obs;
  RxBool imgPreviewStatus = false.obs;

  @override
  void onInit() {
    super.onInit();
    dynamicBadgeType.value = DynamicBadgeMode.values[1]; // 默认红点模式
    pageController = PageController(initialPage: selectedIndex.value);
  }

  /// 设置导航栏配置
  void setNavBarConfig(List<Map<String, dynamic>> navItems) {
    navigationBars.value = navItems;
    pagesIds.value = navigationBars.map<int>((e) => e['id']).toList();
    
    // 只有在pages列表为空或者页面数量发生变化时，才重新创建页面列表
    // 否则，保持现有页面实例不变，避免状态丢失
    if (pages.isEmpty || pages.length != navItems.length) {
      pages.value = navigationBars.map<Widget>((e) => e['page']).toList();
    }
  }

  /// 处理返回按钮点击
  void onBackPressed(BuildContext context) {
    if (_lastPressedAt == null ||
        DateTime.now().difference(_lastPressedAt!) >
            const Duration(seconds: 2)) {
      // 两次点击时间间隔超过2秒，重新记录时间戳
      _lastPressedAt = DateTime.now();
      if (selectedIndex.value != 0) {
        pageController.jumpToPage(0);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('再按一次退出'), duration: Duration(seconds: 2)),
      );
      return; // 不退出应用
    }
    Navigator.of(context).pop(); // 退出应用
  }

  /// 设置选中索引
  void setSelectedIndex(int index) {
    selectedIndex.value = index;
    pageController.jumpToPage(index);
  }

  /// 清除未读消息
  void clearUnread(int itemId) {
    final int index = navigationBars.indexWhere((item) => item['id'] == itemId);
    if (index != -1) {
      navigationBars[index]['count'] = 0;
      navigationBars.refresh();
    }
  }

  /// 更新未读消息数
  void updateUnreadCount(int itemId, int count) {
    final int index = navigationBars.indexWhere((item) => item['id'] == itemId);
    if (index != -1) {
      navigationBars[index]['count'] = count;
      navigationBars.refresh();
    }
  }

  @override
  void onClose() {
    bottomBarStream.close();
    pageController.dispose();
    super.onClose();
  }
}
