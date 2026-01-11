import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:m3e_collection/m3e_collection.dart';

import '../../api/services/notification_service.dart';
import '../../api/services/auth_service.dart';
import '../../api/models/notification.dart' as notification_model;
import '../../utils/time_formatter.dart';
import '../../utils/snackbar_utils.dart';
import '../../core/logger.dart';

// 通知列表组件
class NotificationList extends StatefulWidget {
  const NotificationList({super.key});

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList>
    with AutomaticKeepAliveClientMixin<NotificationList> {
  final NotificationService _notificationService =
      Get.find<NotificationService>();
  final AuthService _authService = Get.find<AuthService>();
  final List<notification_model.Notification> _notifications = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  int _retryCount = 0;
  static const int _maxRetryCount = 3;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // 加载通知列表
  Future<void> _loadNotifications({bool isRefresh = false}) async {
    // 如果用户未登录，不加载通知
    if (!_authService.isLoggedIn()) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasMore = false;
        });
      }
      logger.info('用户未登录，跳过通知列表加载');
      return;
    }

    // 如果已达到最大重试次数，停止加载
    if (_retryCount >= _maxRetryCount && !isRefresh) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasMore = false;
        });
      }
      logger.warning('已达到最大重试次数，停止加载通知列表');
      return;
    }

    if (_isLoading || (!_hasMore && !isRefresh)) return;

    setState(() {
      _isLoading = true;
    });

    logger.info('开始加载通知列表，偏移量: ${isRefresh ? 0 : _offset}');
    final notifications = await _notificationService.getNotifications(
      offset: isRefresh ? 0 : _offset,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (notifications != null) {
          logger.info('成功加载通知列表，数量: ${notifications.length}');
          // 重置重试计数
          _retryCount = 0;
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

          // 如果是刷新操作且没有通知，显示空状态提示
          if (isRefresh && notifications.isEmpty) {
            SnackbarUtils.showMaterialSnackbar(
              context,
              '暂无新通知',
              duration: const Duration(seconds: 1),
            );
          }
        } else {
          logger.warning('获取通知列表失败，重试次数: ${_retryCount + 1}');
          // 增加重试计数
          _retryCount++;
          if (isRefresh) {
            _hasMore = false;
          }

          // 显示错误提示
          if (mounted && _retryCount <= _maxRetryCount) {
            final errorMessage = _retryCount == 1
                ? '加载通知失败，正在重试...'
                : '加载通知失败，${_maxRetryCount - _retryCount}次重试机会';

            SnackbarUtils.showMaterialSnackbar(
              context,
              errorMessage,
              duration: const Duration(seconds: 2),
              isError: true,
            );
          } else if (mounted) {
            // 达到最大重试次数，显示错误提示
            SnackbarUtils.showMaterialSnackbar(
              context,
              '加载通知失败，请检查网络连接后重试',
              duration: const Duration(seconds: 3),
              isError: true,
            );
          }
        }
      });
    }
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
        return '$fromUsername 对您（的帖子）进行了 ${notification.contentType} 操作';
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
          slivers: [SliverSafeArea(sliver: _buildContent())],
        ),
      ),
    );
  }

  // 构建内容区域
  Widget _buildContent() {
    // 未登录状态
    if (!_authService.isLoggedIn()) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.login, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('您尚未登录', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              const Text('请登录后查看通知', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Get.toNamed('/login');
                },
                child: const Text('去登录'),
              ),
            ],
          ),
        ),
      );
    }

    // 达到最大重试次数，显示错误页面
    if (_retryCount >= _maxRetryCount && _notifications.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('获取通知失败', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              const Text('请检查网络连接后重试', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // 重置重试计数并刷新
                  setState(() {
                    _retryCount = 0;
                    _hasMore = true;
                  });
                  _handleRefresh();
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    // 加载状态：显示加载指示器
    if (_isLoading && _notifications.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LoadingIndicatorM3E(),
              const SizedBox(height: 16),
              const Text('正在加载通知...'),
            ],
          ),
        ),
      );
    }

    // 空状态：已登录、无错误、但没有通知
    if (_notifications.isEmpty && !_isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.notifications_none,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text('暂无通知', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              const Text('当有新通知时，会在这里显示', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  _handleRefresh();
                },
                child: const Text('刷新'),
              ),
            ],
          ),
        ),
      );
    }

    // 正常显示通知列表
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index < _notifications.length) {
          final notification = _notifications[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    notification.fromUser?['attributes']?['avatarUrl'] != null
                    ? NetworkImage(
                        notification.fromUser!['attributes']!['avatarUrl'],
                      )
                    : null,
                child: notification.fromUser?['attributes']?['avatarUrl'] == null
                    ? Text(
                        notification.fromUser?['attributes']?['username']?[0] ??
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
            ),
          );
        } else if (_hasMore) {
          // 异步加载更多
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _handleLoadMore();
            }
          });
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: LoadingIndicatorM3E()),
          );
        } else {
          // 没有更多数据
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                '没有更多通知了',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
          );
        }
      }, childCount: _notifications.length + (_hasMore ? 1 : 0)),
    );
  }
}
