import 'package:flutter/material.dart';

/// 全局常量配置
class AppConstants {
  /// 应用名称
  static const String appName = 'PetalTalk';

  /// 默认主题色
  static const Color primaryColor = Colors.blue;

  /// 默认深色主题色
  static const Color darkPrimaryColor = Colors.blueAccent;

  /// 标题栏高度（仅桌面平台）
  static const double titleBarHeight = 30.0;

  /// 默认字体大小
  static const double defaultFontSize = 16.0;

  /// 最小字体大小
  static const double minFontSize = 12.0;

  /// 最大字体大小
  static const double maxFontSize = 24.0;

  /// 网格视图交叉轴数量
  static const int gridCrossAxisCount = 4;

  /// 网格间距
  static const double gridSpacing = 8.0;

  /// 强调色选择对话框宽度
  static const double accentColorDialogWidth = 200.0;

  /// 强调色选择对话框高度
  static const double accentColorDialogHeight = 250.0;
}

/// 存储键名常量
class StorageKeys {
  /// 主题模式
  static const String themeMode = 'theme_mode';

  /// 字体大小
  static const String fontSize = 'font_size';

  /// 深色主题偏好
  static const String darkTheme = 'dark_theme';

  /// 使用动态色彩
  static const String useDynamicColor = 'use_dynamic_color';

  /// 强调色
  static const String accentColor = 'accent_color';

  /// 紧凑布局
  static const String compactLayout = 'compact_layout';

  /// 显示头像
  static const String showAvatars = 'show_avatars';

  /// 端点配置
  static const String flarumEndpoint = 'flarum_endpoint';

  /// 登录令牌
  static const String flarumToken = 'flarum_token';

  /// 用户ID
  static const String flarumUserId = 'flarum_user_id';
}
