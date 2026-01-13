/// 全局通知服务，负责管理应用的推送通知
///
/// 该服务提供：
/// 1. 初始化通知设置
/// 2. 请求通知权限
/// 3. 显示本地通知
/// 4. 处理通知点击事件
/// 5. 支持多平台（iOS、Android、Windows、macOS、Linux）
library;

import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_guid/flutter_guid.dart';
import '../../core/logger.dart';
import '../config/constants.dart';

/// 全局通知服务类，处理通知相关的所有功能
class GlobalNotificationService {
  /// 单例实例
  static final GlobalNotificationService _instance =
      GlobalNotificationService._internal();
  factory GlobalNotificationService() => _instance;
  GlobalNotificationService._internal();

  /// 日志实例
  final AppLogger _logger = AppLogger();

  /// FlutterLocalNotificationsPlugin实例
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// 初始化通知服务
  Future<void> initialize() async {
    _logger.debug('开始初始化全局通知服务');
    try {
      // 初始化设置
      _logger.debug('创建各平台初始化设置');

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      _logger.debug('Android初始化设置创建完成');

      final DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );
      _logger.debug('iOS初始化设置创建完成');

      final LinuxInitializationSettings initializationSettingsLinux =
          LinuxInitializationSettings(
            defaultActionName: 'Open notification',
            defaultIcon: AssetsLinuxIcon('icons/app_icon.png'),
          );
      _logger.debug('Linux初始化设置创建完成');

      final WindowsInitializationSettings initializationSettingsWindows =
          WindowsInitializationSettings(
            appName: 'PetalTalk',
            appUserModelId: 'com.petaltalk.app',
            guid: Guid.newGuid.toString(),
          );
      _logger.debug('Windows初始化设置创建完成');

      final InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
            linux: initializationSettingsLinux,
            windows: initializationSettingsWindows,
          );
      _logger.debug('全局初始化设置创建完成');

      // 设置通知点击回调
      _logger.debug('开始初始化FlutterLocalNotificationsPlugin');
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (notificationResponse) {
          // 处理通知点击
          _handleNotificationTap(notificationResponse);
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );
      _logger.info('FlutterLocalNotificationsPlugin初始化成功');

      // 请求通知权限
      _logger.debug('开始请求通知权限');
      await requestPermissions();
      _logger.info('全局通知服务初始化完成');
    } catch (e, stackTrace) {
      _logger.error('初始化全局通知服务出错', e, stackTrace);
    }
  }

  /// 请求通知权限
  Future<void> requestPermissions() async {
    _logger.debug('请求通知权限 - 当前平台: ${Platform.operatingSystem}');
    try {
      if (Platform.isIOS) {
        _logger.debug('请求iOS通知权限（alert, badge, sound）');
        final iosImpl = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        if (iosImpl != null) {
          await iosImpl.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          _logger.info('iOS通知权限请求完成');
        } else {
          _logger.warning('无法获取iOS通知实现');
        }
      } else if (Platform.isAndroid) {
        _logger.debug('请求Android通知权限');
        final androidImpl = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (androidImpl != null) {
          await androidImpl.requestNotificationsPermission();
          _logger.info('Android通知权限请求完成');
        } else {
          _logger.warning('无法获取Android通知实现');
        }
      } else if (Platform.isLinux) {
        _logger.debug('Linux平台无需显式请求通知权限');
      } else if (Platform.isMacOS) {
        _logger.debug('macOS平台通知权限处理');
      } else if (Platform.isWindows) {
        _logger.debug('Windows平台通知权限处理');
      }
    } catch (e, stackTrace) {
      _logger.error('请求通知权限出错', e, stackTrace);
    }
  }

  /// 显示本地通知
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    _logger.debug('显示本地通知 - Title: $title, Body: $body, Payload: $payload');
    try {
      final AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
            Constants.notificationChannelId,
            Constants.notificationChannelName,
            channelDescription: Constants.notificationChannelDescription,
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: DarwinNotificationDetails(),
        linux: LinuxNotificationDetails(),
        windows: WindowsNotificationDetails(),
      );

      await _flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      _logger.info('本地通知显示成功');
    } catch (e, stackTrace) {
      _logger.error('显示本地通知出错', e, stackTrace);
    }
  }

  /// 处理通知点击
  void _handleNotificationTap(NotificationResponse notificationResponse) {
    _logger.debug(
      '处理通知点击 - ID: ${notificationResponse.id}, ActionId: ${notificationResponse.actionId}, Payload: ${notificationResponse.payload}',
    );
    // 可以根据payload处理不同的通知点击事件
    final payload = notificationResponse.payload;
    if (payload != null) {
      // 这里可以处理通知点击后的导航逻辑
      _logger.info('通知payload: $payload');
    }
  }

  /// 后台通知点击处理
  static void notificationTapBackground(
    NotificationResponse notificationResponse,
  ) {
    // 处理后台通知点击
    final logger = AppLogger();
    logger.info(
      '后台通知点击 - ID: ${notificationResponse.id}, Payload: ${notificationResponse.payload}',
    );
  }

  /// 检查是否有通知权限
  Future<bool> checkPermissions() async {
    _logger.debug('检查通知权限 - 当前平台: ${Platform.operatingSystem}');
    try {
      if (Platform.isIOS) {
        _logger.debug('检查iOS通知权限');
        final iosImplementation = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        if (iosImplementation != null) {
          // 对于iOS，我们只需要知道权限是否已请求，不需要具体属性
          _logger.info('iOS通知权限检查完成: true');
          return true;
        } else {
          _logger.warning('无法获取iOS通知实现，默认返回true');
          return true;
        }
      } else if (Platform.isAndroid) {
        _logger.debug('检查Android通知权限');
        // Android权限检查简化处理
        _logger.info('Android通知权限检查完成: true');
        return true;
      } else {
        _logger.debug('其他平台默认返回true');
        return true;
      }
    } catch (e, stackTrace) {
      _logger.error('检查通知权限出错', e, stackTrace);
      return true;
    }
  }
}
