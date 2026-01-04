import 'package:flutter/widgets.dart';

/// 导航栏项模型
class NavBarItem {
  final int id;
  final Widget icon;
  final Widget selectIcon;
  final String label;
  int count;
  final Widget page;

  NavBarItem({
    required this.id,
    required this.icon,
    required this.selectIcon,
    required this.label,
    this.count = 0,
    required this.page,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'icon': icon,
      'selectIcon': selectIcon,
      'label': label,
      'count': count,
      'page': page,
    };
  }

  factory NavBarItem.fromMap(Map<String, dynamic> map) {
    return NavBarItem(
      id: map['id'] as int,
      icon: map['icon'] as Widget,
      selectIcon: map['selectIcon'] as Widget,
      label: map['label'] as String,
      count: map['count'] as int,
      page: map['page'] as Widget,
    );
  }
}