// 全局常量
class Constants {
  // 端点相关
  static const String endpointsKey = 'flarum_endpoints';
  static const String currentEndpointKey = 'flarum_current_endpoint';

  // 端点特定数据的前缀
  static const String endpointDataPrefix = 'flarum_endpoint_';

  // 认证相关
  static const String tokenKey = 'token';
  static const String userIdKey = 'user_id';
  static const String usernameKey = 'username';

  // 主题相关
  static const String themeModeKey = 'theme_mode';
  static const String useDynamicColorKey = 'use_dynamic_color';
  static const String accentColorKey = 'accent_color';
  static const String fontSizeKey = 'font_size';
  static const String compactLayoutKey = 'compact_layout';
  static const String showAvatarsKey = 'show_avatars';

  // 通知相关存储键
  static const String enableNotificationsKey = 'enable_notifications';
  static const String enableMessageNotificationsKey =
      'enable_message_notifications';
  static const String enableMentionNotificationsKey =
      'enable_mention_notifications';
  static const String enableReplyNotificationsKey =
      'enable_reply_notifications';
  static const String enableSystemNotificationsKey =
      'enable_system_notifications';

  // 布局相关
  static const double narrowScreenThreshold = 600;
  static const double wideScreenThreshold = 768;
  static const Duration doubleTapExitDuration = Duration(seconds: 2);

  // 验证相关
  static const int titleMinLength = 3;
  static const int contentMinLength = 5;

  // 通知渠道相关
  static const String notificationChannelId = 'channel_id';
  static const String notificationChannelName = 'channel_name';
  static const String notificationChannelDescription = 'channel_description';

  // 默认值
  static const String defaultThemeMode = 'system';
  static const bool defaultEnableNotifications = true;
  static const bool defaultUseDynamicColor = true;
  static const String defaultAccentColor = 'blue';

  // 布局偏好
  static const String layoutPreferenceKey = 'layout_preference';

  // 日志相关
  static const String logLevelKey = 'log_level';
  static const String maxLogSizeKey = 'max_log_size';
  static const String enableLogExportKey = 'enable_log_export';
  static const String defaultLogLevel = 'error';
  static const int defaultMaxLogSize = 10; // MB
  static const bool defaultEnableLogExport = true;
}
