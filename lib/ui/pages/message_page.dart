import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../api/services/notification_service.dart';
import '../../api/models/notification.dart' as flarum_notification;
import '../widgets/notification_item.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({Key? key}) : super(key: key);

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final NotificationService _notificationService = NotificationService();
  final List<flarum_notification.Notification> _notifications = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // 加载通知列表
  Future<void> _loadNotifications({bool isRefresh = false}) async {
    if (_isLoading || (!_hasMore && !isRefresh)) return;

    setState(() {
      _isLoading = true;
      if (isRefresh) {
        _offset = 0;
        _notifications.clear();
        _hasMore = true;
      }
    });

    final result = await _notificationService.getNotifications(
      offset: _offset,
      limit: _limit,
    );

    setState(() {
      _isLoading = false;
    });

    if (result != null) {
      final List<flarum_notification.Notification> newNotifications =
          (result['data'] as List)
              .map(
                (notification) =>
                    flarum_notification.Notification.fromJson(notification),
              )
              .toList();

      setState(() {
        _notifications.addAll(newNotifications);
        _offset += newNotifications.length;
        _hasMore = newNotifications.length == _limit;
        // 计算未读通知数
        _unreadCount = _notifications
            .where((notification) => !notification.isRead)
            .length;
      });
    } else {
      Get.snackbar('加载失败', '获取通知列表失败', snackPosition: SnackPosition.BOTTOM);
    }
  }

  // 标记所有通知为已读
  Future<void> _markAllAsRead() async {
    final result = await _notificationService.markAllAsRead();

    if (result) {
      setState(() {
        for (var i = 0; i < _notifications.length; i++) {
          _notifications[i] = flarum_notification.Notification(
            id: _notifications[i].id,
            type: _notifications[i].type,
            isRead: true,
            createdAt: _notifications[i].createdAt,
            data: _notifications[i].data,
          );
        }
        _unreadCount = 0;
      });

      Get.snackbar('操作成功', '所有通知已标记为已读', snackPosition: SnackPosition.BOTTOM);
    } else {
      Get.snackbar('操作失败', '标记所有通知为已读失败', snackPosition: SnackPosition.BOTTOM);
    }
  }

  // 标记单个通知为已读
  Future<void> _markAsRead(String id) async {
    final result = await _notificationService.markAsRead(id);

    if (result) {
      setState(() {
        final index = _notifications.indexWhere(
          (notification) => notification.id == id,
        );
        if (index != -1) {
          _notifications[index] = flarum_notification.Notification(
            id: _notifications[index].id,
            type: _notifications[index].type,
            isRead: true,
            createdAt: _notifications[index].createdAt,
            data: _notifications[index].data,
          );
          _unreadCount--;
        }
      });
    } else {
      Get.snackbar('操作失败', '标记通知为已读失败', snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('消息通知'),
        actions: [
          if (_unreadCount > 0)
            TextButton(onPressed: _markAllAsRead, child: const Text('全部已读')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadNotifications(isRefresh: true),
        child: ListView.builder(
          itemCount: _notifications.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < _notifications.length) {
              final notification = _notifications[index];
              return NotificationItem(
                type: notification.type,
                title: '通知标题', // 这里应该根据通知类型生成标题
                content: '通知内容', // 这里应该根据通知类型生成内容
                createdAt: notification.createdAt,
                isRead: notification.isRead,
                onTap: () {
                  // 处理通知点击
                  print('Notification tapped: ${notification.id}');
                  if (!notification.isRead) {
                    _markAsRead(notification.id);
                  }
                },
                onMarkAsRead: () => _markAsRead(notification.id),
              );
            } else if (_hasMore) {
              // 加载更多
              _loadNotifications();
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            } else {
              // 没有更多数据
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('没有更多通知了')),
              );
            }
          },
        ),
      ),
    );
  }
}
