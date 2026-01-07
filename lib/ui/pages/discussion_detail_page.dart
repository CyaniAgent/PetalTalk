import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/services/post_service.dart';
import '../../api/services/discussion_service.dart';
import '../../api/models/discussion.dart';
import '../../api/models/post.dart';
import '../../utils/time_formatter.dart';
import '../../utils/snackbar_utils.dart';
import '../components/discussion/post_content.dart';
import '../components/discussion/reply_input.dart';

class DiscussionDetailPage extends StatefulWidget {
  const DiscussionDetailPage({super.key});

  @override
  State<DiscussionDetailPage> createState() => _DiscussionDetailPageState();
}

class _DiscussionDetailPageState extends State<DiscussionDetailPage> {
  final PostService _postService = Get.find<PostService>();
  final DiscussionService _discussionService = Get.find<DiscussionService>();
  Discussion? _discussion;
  final List<Post> _posts = [];
  bool _isLoading = false;
  bool _isSubmittingReply = false;
  String _replyContent = '';
  // 存储用户信息，key是userId，value是用户名
  final Map<String, String> _users = {};
  // 存储用户头像，key是userId，value是头像URL
  final Map<String, String> _userAvatars = {};
  // 存储标签信息，key是tagId，value是标签名称
  final Map<String, String> _tags = {};

  @override
  void initState() {
    super.initState();
    // 获取传递过来的主题帖数据
    final arguments = Get.arguments;
    if (arguments != null && arguments is Discussion) {
      _discussion = arguments;
      // 直接从ID获取主题帖详情，确保获取完整的标签信息
      final id = _discussion!.id;
      _loadDiscussionDetail(id);
    } else {
      // 如果没有传递主题帖数据，尝试从ID获取
      final id = Get.parameters['id'];
      if (id != null) {
        _loadDiscussionDetail(id);
      } else {
        // 没有ID，返回首页
        Get.back();
      }
    }
  }

  // 加载主题帖详情
  Future<void> _loadDiscussionDetail(String id) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final result = await _discussionService.getDiscussion(id);

    // 检查组件是否仍然挂载
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result != null && result.containsKey('data')) {
      // 处理included数据，获取用户和标签信息
      if (result.containsKey('included')) {
        final List<dynamic> included = result['included'];
        for (final item in included) {
          if (item['type'] == 'users') {
            final userId = item['id'];
            final username = item['attributes']['username'];
            final avatarUrl = item['attributes']['avatarUrl'];
            _users[userId] = username;
            if (avatarUrl != null) {
              _userAvatars[userId] = avatarUrl;
            }
          } else if (item['type'] == 'tags') {
            final tagId = item['id'];
            final tagName = item['attributes']['name'];
            _tags[tagId] = tagName;
          }
        }
      }
      setState(() {
        _discussion = Discussion.fromJson(result['data']);
      });
      _loadPosts();
    } else {
      SnackbarUtils.showMaterialSnackbar(context, '获取主题帖详情失败');
      Get.back();
    }
  }

  // 加载帖子列表
  Future<void> _loadPosts() async {
    if (_discussion == null) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final result = await _postService.getPostsForDiscussion(_discussion!.id);

    // 检查组件是否仍然挂载
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result != null) {
      // 处理included数据，只获取用户信息，标签信息已经在_loadDiscussionDetail中获取
      if (result.containsKey('included')) {
        final List<dynamic> included = result['included'];
        for (final item in included) {
          if (item['type'] == 'users') {
            final userId = item['id'];
            final username = item['attributes']['username'];
            final avatarUrl = item['attributes']['avatarUrl'];
            _users[userId] = username;
            if (avatarUrl != null) {
              _userAvatars[userId] = avatarUrl;
            }
          }
        }
      }

      // 解析帖子数据
      final List<Post> newPosts = (result['data'] as List)
          .map((post) => Post.fromJson(post))
          .toList();

      setState(() {
        _posts.addAll(newPosts);
      });
    } else {
      SnackbarUtils.showMaterialSnackbar(context, '获取帖子列表失败');
    }
  }

  // 显示底部回复输入框
  void _showReplyBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '写下你的回复',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Get.back();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 回复输入框
              ReplyInput(
                onSubmit: () {
                  // 提交回复后关闭弹窗
                  Get.back();
                  _handleReply();
                },
                onContentChanged: (content) {
                  setState(() {
                    _replyContent = content;
                  });
                },
                initialContent: _replyContent,
                isSubmitting: _isSubmittingReply,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 处理回复
  Future<void> _handleReply() async {
    if (_replyContent.isEmpty || _discussion == null) return;

    if (mounted) {
      setState(() {
        _isSubmittingReply = true;
      });
    }

    final result = await _postService.replyToDiscussion(
      discussionId: _discussion!.id,
      content: _replyContent,
    );

    // 检查组件是否仍然挂载
    if (!mounted) return;

    setState(() {
      _isSubmittingReply = false;
    });

    if (result != null) {
      // 回复成功，添加到帖子列表
      final post = Post.fromJson(result['data']);
      setState(() {
        _posts.add(post);
        _replyContent = '';
      });

      // 更新主题帖的评论数
      setState(() {
        _discussion = Discussion(
          id: _discussion!.id,
          title: _discussion!.title,
          slug: _discussion!.slug,
          commentCount: _discussion!.commentCount + 1,
          participantCount: _discussion!.participantCount,
          createdAt: _discussion!.createdAt,
          lastPostedAt: DateTime.now().toIso8601String(),
          lastPostNumber: _discussion!.lastPostNumber + 1,
          canReply: _discussion!.canReply,
          canRename: _discussion!.canRename,
          canDelete: _discussion!.canDelete,
          canHide: _discussion!.canHide,
          isHidden: _discussion!.isHidden,
          isLocked: _discussion!.isLocked,
          isSticky: _discussion!.isSticky,
          subscription: _discussion!.subscription,
          userId: _discussion!.userId,
          lastPostedUserId: 'current_user_id', // 这里应该是当前用户ID
          tagIds: _discussion!.tagIds,
          firstPostId: _discussion!.firstPostId,
        );
      });

      SnackbarUtils.showMaterialSnackbar(context, '你的回复已发布');
    } else {
      SnackbarUtils.showMaterialSnackbar(context, '发布回复失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _discussion != null
            ? Hero(
                tag: 'discussion-title-${_discussion!.id}',
                child: Text(
                  _discussion!.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : Text('加载中...', maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // 更多操作
              SnackbarUtils.showDevelopmentInProgress(context);
            },
          ),
        ],
      ),
      body: _isLoading && _discussion == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 帖子列表
                Expanded(
                  child: ListView.builder(
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      final post = _posts[index];
                      final isFirstPost = index == 0;

                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: isFirstPost ? 16 : 4,
                        ),
                        elevation: isFirstPost ? 2 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 作者信息
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: isFirstPost ? 24 : 20,
                                    backgroundColor: Colors.blue,
                                    backgroundImage:
                                        _userAvatars[post.userId] != null
                                        ? NetworkImage(
                                            _userAvatars[post.userId]!,
                                          )
                                        : null,
                                    child: _userAvatars[post.userId] == null
                                        ? Text(
                                            (_users[post.userId] ?? '未知用户')[0],
                                            style: TextStyle(
                                              fontSize: isFirstPost ? 16 : 14,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _users[post.userId] ??
                                            '未知用户', // 显示实际的作者名称
                                        style: isFirstPost
                                            ? Theme.of(
                                                context,
                                              ).textTheme.titleSmall
                                            : Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                      ),
                                      Text(
                                        TimeFormatter.formatLocalTime(
                                          post.createdAt,
                                        ),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // 标签显示
                              if (isFirstPost &&
                                  _discussion?.tagIds.isNotEmpty == true)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: (_discussion?.tagIds ?? []).map((
                                    tagId,
                                  ) {
                                    final tagName = _tags[tagId] ?? '标签 $tagId';
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        tagName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              const SizedBox(height: 16),
                              // 帖子内容
                              PostContent(contentHtml: post.contentHtml),
                              const SizedBox(height: 16),
                              // 操作按钮
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.thumb_up),
                                    iconSize: isFirstPost ? 20 : 18,
                                    onPressed: () {
                                      // 点赞
                                      SnackbarUtils.showDevelopmentInProgress(
                                        context,
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    icon: const Icon(Icons.reply),
                                    iconSize: isFirstPost ? 20 : 18,
                                    onPressed: () {
                                      // 回复
                                      _showReplyBottomSheet();
                                    },
                                  ),
                                  if (isFirstPost) const SizedBox(width: 16),
                                  if (isFirstPost)
                                    IconButton(
                                      icon: const Icon(Icons.share),
                                      iconSize: 20,
                                      onPressed: () {
                                        // 分享
                                        SnackbarUtils.showDevelopmentInProgress(
                                          context,
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      // 回帖按钮，点击后从页面下方弹出发送框
      floatingActionButton:
          _discussion != null && _discussion!.canReply && !_discussion!.isLocked
          ? FloatingActionButton(
              onPressed: _showReplyBottomSheet,
              tooltip: '回复',
              child: const Icon(Icons.comment),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
