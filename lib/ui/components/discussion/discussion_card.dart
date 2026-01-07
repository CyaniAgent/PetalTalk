/// 主题帖卡片组件，用于显示单个主题帖的基本信息
/// 
/// 该组件显示：
/// 1. 主题帖标题
/// 2. 作者信息和发布时间
/// 3. 评论数量
/// 4. 标签
/// 5. 置顶和锁定状态标记
library;

import 'package:flutter/material.dart';
import '../../../utils/time_formatter.dart';

/// 主题帖卡片组件
class DiscussionCard extends StatelessWidget {
  /// 主题帖ID
  final String id;
  
  /// 主题帖标题
  final String title;
  
  /// 作者用户名
  final String author;
  
  /// 创建时间（ISO格式）
  final String createdAt;
  
  /// 评论总数
  final int commentCount;
  
  /// 是否置顶
  final bool isSticky;
  
  /// 是否锁定
  final bool isLocked;
  
  /// 标签列表
  final List<String> tags;
  
  /// 点击事件回调
  final VoidCallback onTap;

  const DiscussionCard({
    super.key,
    required this.id,
    required this.title,
    required this.author,
    required this.createdAt,
    required this.commentCount,
    required this.isSticky,
    required this.isLocked,
    required this.tags,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 主题帖标题
              Row(
                children: [
                  Expanded(
                    child: Hero(
                      tag: 'discussion-title-$id',
                      child: Text(
                        title,
                        style: textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (isSticky)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.push_pin,
                        size: 14,
                        color: Colors.orange,
                      ),
                    ),
                  if (isLocked)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.lock, size: 14, color: Colors.grey),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // 标签
              if (tags.isNotEmpty)
                SizedBox(
                  height: 24,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: tags.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tags[index],
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              // 底部信息
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 作者和时间
                  Row(
                    children: [
                      Text(author, style: textTheme.bodySmall),
                      const SizedBox(width: 8),
                      const Icon(Icons.circle, size: 4, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        TimeFormatter.formatLocalTime(createdAt),
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                  // 评论数
                  Row(
                    children: [
                      const Icon(Icons.comment, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        (commentCount > 0 ? commentCount - 1 : 0).toString(),
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
