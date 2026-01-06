import 'package:flutter/material.dart';

class NotificationItem extends StatelessWidget {
  final String type;
  final String title;
  final String content;
  final String createdAt;
  final bool isRead;
  final VoidCallback onTap;
  final VoidCallback onMarkAsRead;

  const NotificationItem({
    super.key,
    required this.type,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.isRead,
    required this.onTap,
    required this.onMarkAsRead,
  });

  // 根据通知类型获取图标
  IconData _getNotificationIcon() {
    switch (type) {
      case 'discussionRenamed':
        return Icons.edit;
      case 'postMentioned':
        return Icons.alternate_email;
      case 'userMentioned':
        return Icons.alternate_email;
      case 'groupMentioned':
        return Icons.group;
      case 'postLiked':
        return Icons.favorite;
      case 'postReplied':
        return Icons.reply;
      case 'discussionLocked':
        return Icons.lock;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isRead ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 通知图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getNotificationIcon(),
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              // 通知内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    // 内容
                    Text(
                      content,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // 时间
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          createdAt,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        // 标记为已读按钮
                        if (!isRead)
                          TextButton(
                            onPressed: onMarkAsRead,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('标记为已读'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
