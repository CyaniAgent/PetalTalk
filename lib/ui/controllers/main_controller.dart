import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/dynamic_badge_mode.dart';

class UiMainController extends GetxController {
  List<Widget> pages = <Widget>[];
  List<int> pagesIds = <int>[];
  RxList<Map<String, dynamic>> navigationBars = <Map<String, dynamic>>[].obs;
  final StreamController<bool> bottomBarStream = StreamController<bool>.broadcast();
  DateTime? _lastPressedAt;
  late PageController pageController;
  int selectedIndex = 0;
  RxBool userLogin = false.obs;
  late Rx<DynamicBadgeMode> dynamicBadgeType = DynamicBadgeMode.number.obs;
  bool enableGradientBg = true;
  bool imgPreviewStatus = false;

  @override
  void onInit() {
    super.onInit();
    dynamicBadgeType.value = DynamicBadgeMode.values[1]; // 默认红点模式
    pageController = PageController(initialPage: selectedIndex);
  }

  /// 设置导航栏配置
  void setNavBarConfig(List<Map<String, dynamic>> navItems) {
    navigationBars.value = navItems;
    pages = navigationBars.map<Widget>((e) => e['page']).toList();
    pagesIds = navigationBars.map<int>((e) => e['id']).toList();
    update();
  }

  /// 处理返回按钮点击
  void onBackPressed(BuildContext context) {
    if (_lastPressedAt == null ||
        DateTime.now().difference(_lastPressedAt!) > const Duration(seconds: 2)) {
      // 两次点击时间间隔超过2秒，重新记录时间戳
      _lastPressedAt = DateTime.now();
      if (selectedIndex != 0) {
        pageController.jumpToPage(0);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('再按一次退出'),
          duration: Duration(seconds: 2),
        ),
      );
      return; // 不退出应用
    }
    Navigator.of(context).pop(); // 退出应用
  }

  /// 设置选中索引
  void setSelectedIndex(int index) {
    selectedIndex = index;
    pageController.jumpToPage(index);
    update();
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