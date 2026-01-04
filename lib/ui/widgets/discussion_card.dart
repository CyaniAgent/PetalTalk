import 'package:flutter/material.dart';
import '../../utils/time_formatter.dart';

class DiscussionCard extends StatelessWidget {
  final String title;
  final String author;
  final String createdAt;
  final int commentCount;
  final int viewCount;
  final bool isSticky;
  final bool isLocked;
  final List<String> tags;
  final VoidCallback onTap;

  const DiscussionCard({
    Key? key,
    required this.title,
    required this.author,
    required this.createdAt,
    required this.commentCount,
    required this.viewCount,
    required this.isSticky,
    required this.isLocked,
    required this.tags,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                      child: Icon(
                        Icons.lock,
                        size: 14,
                        color: Colors.grey,
                      ),
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
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tags[index],
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
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
                      Text(
                        author,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.circle,
                        size: 4,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        TimeFormatter.formatLocalTime(createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  // 评论和浏览数
                  Row(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.comment,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            commentCount.toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.remove_red_eye,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            viewCount.toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
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
