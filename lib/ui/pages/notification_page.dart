import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/services/notification_service.dart';
import '../../api/models/notification.dart' as notification_model;
import '../../utils/snackbar_utils.dart';
import '../../utils/time_formatter.dart';

// 通知列表组件
class NotificationList extends StatefulWidget {
  const NotificationList({Key? key}) : super(key: key);

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList>
    with AutomaticKeepAliveClientMixin<NotificationList> {
  final NotificationService _notificationService = NotificationService();
  final List<notification_model.Notification> _notifications = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;

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
    });

    final notifications = await _notificationService.getNotifications(
      offset: isRefresh ? 0 : _offset,
    );

    setState(() {
      _isLoading = false;
      if (notifications != null) {
        if (isRefresh) {
          _notifications.clear();
          _notifications.addAll(notifications);
          _offset = notifications.length;
          _hasMore = notifications.isNotEmpty;
        } else {
          _notifications.addAll(notifications);
          _offset += notifications.length;
          _hasMore = notifications.isNotEmpty;
        }
      } else {
        if (isRefresh) {
          _hasMore = false;
        }
        Get.snackbar('加载失败', '获取通知列表失败', snackPosition: SnackPosition.BOTTOM);
      }
    });
  }

  // 下拉刷新
  Future<void> _handleRefresh() async {
    await _loadNotifications(isRefresh: true);
  }

  // 上拉加载更多
  Future<void> _handleLoadMore() async {
    await _loadNotifications();
  }

  // 格式化通知内容
  String _formatNotificationContent(
    notification_model.Notification notification,
  ) {
    final fromUsername =
        notification.fromUser?['attributes']?['displayName'] ?? '未知用户';
    final subjectTitle =
        notification.subject?['attributes']?['title'] ?? '未知主题';

    switch (notification.contentType) {
      case 'newPost':
        final postNumber = notification.content['postNumber'];
        return '$fromUsername 在 "$subjectTitle" 中发布了第 $postNumber 楼';
      default:
        return '$fromUsername 对您进行了 $notification.contentType 操作';
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: const Text('通知')),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          slivers: [
            SliverSafeArea(
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index < _notifications.length) {
                    final notification = _notifications[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            notification
                                    .fromUser?['attributes']?['avatarUrl'] !=
                                null
                            ? NetworkImage(
                                notification
                                    .fromUser!['attributes']!['avatarUrl'],
                              )
                            : null,
                        child:
                            notification
                                    .fromUser?['attributes']?['avatarUrl'] ==
                                null
                            ? Text(
                                notification
                                        .fromUser?['attributes']?['username']?[0] ??
                                    '?',
                              )
                            : null,
                      ),
                      title: Text(_formatNotificationContent(notification)),
                      subtitle: Text(
                        TimeFormatter.formatLocalTime(notification.createdAt),
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      trailing: notification.isRead
                          ? null
                          : Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red,
                              ),
                            ),
                      onTap: () {
                        // 跳转到相关主题帖
                        if (notification.subjectType == 'discussions') {
                          Get.toNamed('/discussion/${notification.subjectId}');
                        }
                      },
                    );
                  } else if (_hasMore) {
                    // 异步加载更多
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _handleLoadMore();
                    });
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
                }, childCount: _notifications.length + (_hasMore ? 1 : 0)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
