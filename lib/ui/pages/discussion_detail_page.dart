import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/services/post_service.dart';
import '../../api/services/discussion_service.dart';
import '../../api/flarum_api.dart';
import '../../api/models/discussion.dart';
import '../../api/models/post.dart';
import '../../utils/time_formatter.dart';
import '../../utils/snackbar_utils.dart';
import '../../core/cache_service.dart';
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
    // 1. 先从缓存获取数据并显示
    final cacheService = Get.find<CacheService>();
    final cacheKey = 'cache_discussion_$id';
    final cachedDiscussion = await cacheService.getCache<Map<String, dynamic>>(
      cacheKey,
    );

    if (cachedDiscussion != null && mounted) {
      // 处理缓存数据，获取用户和标签信息
      if (cachedDiscussion.containsKey('included')) {
        final List<dynamic> included = cachedDiscussion['included'];
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
        _discussion = Discussion.fromJson(cachedDiscussion['data']);
        _isLoading = false;
      });
      // 加载缓存的帖子
      _loadPostsFromCache(id);
    } else {
      // 如果没有缓存，显示加载状态
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }
    }

    // 2. 后台请求最新数据
    final result = await _discussionService.getDiscussion(id);

    // 检查组件是否仍然挂载
    if (!mounted) return;

    if (result != null && result.containsKey('data')) {
      // 处理最新数据，获取用户和标签信息
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

      final newDiscussion = Discussion.fromJson(result['data']);
      bool isNewData =
          _discussion == null || _discussion!.id != newDiscussion.id;

      setState(() {
        _discussion = newDiscussion;
        _isLoading = false;
      });

      // 如果是新数据或没有缓存，加载帖子；否则只在后台更新
      if (isNewData) {
        _loadPosts();
      } else {
        _loadPostsInBackground();
      }
    } else {
      // 获取主题帖详情失败，如果没有缓存则返回上一页
      if (_discussion == null) {
        Get.back();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 从缓存加载帖子
  Future<void> _loadPostsFromCache(String discussionId) async {
    final cacheService = Get.find<CacheService>();
    final cacheKey = 'cache_posts_for_discussion_${discussionId}_0_20';
    final cachedPosts = await cacheService.getCache<Map<String, dynamic>>(
      cacheKey,
    );

    if (cachedPosts != null && mounted) {
      // 处理缓存的帖子数据
      if (cachedPosts.containsKey('included')) {
        final List<dynamic> included = cachedPosts['included'];
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

      final List<Post> posts = (cachedPosts['data'] as List)
          .map((post) => Post.fromJson(post))
          .toList();

      setState(() {
        _posts.addAll(posts);
      });
    }
  }

  // 后台加载帖子并更新
  Future<void> _loadPostsInBackground() async {
    if (_discussion == null) return;

    final result = await _postService.getPostsForDiscussion(_discussion!.id);

    if (result != null && mounted) {
      // 处理最新帖子数据
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

      final List<Post> newPosts = (result['data'] as List)
          .map((post) => Post.fromJson(post))
          .toList();

      // 只添加新帖子
      final existingPostIds = _posts.map((post) => post.id).toSet();
      final postsToAdd = newPosts
          .where((post) => !existingPostIds.contains(post.id))
          .toList();

      if (postsToAdd.isNotEmpty && mounted) {
        setState(() {
          _posts.addAll(postsToAdd);
        });
      }
    }
  }

  // 加载帖子列表
  Future<void> _loadPosts() async {
    if (_discussion == null) return;

    // 1. 检查是否已经从缓存加载了帖子
    if (_posts.isNotEmpty) {
      // 如果已经有缓存帖子，只在后台更新
      _loadPostsInBackground();
      return;
    }

    // 2. 如果没有缓存帖子，显示加载状态并获取最新数据
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
      // 不再显示错误提示，只在UI上显示错误状态
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
          // 关注按钮
          if (_discussion != null)
            IconButton(
              icon: Icon(
                _discussion!.subscription == 'follow'
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: _discussion!.subscription == 'follow'
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
              onPressed: () async {
                // 切换关注状态
                final newSubscription = _discussion!.subscription == 'follow'
                    ? null
                    : 'follow';

                final result = await _discussionService.followDiscussion(
                  id: _discussion!.id,
                  subscription: newSubscription ?? '',
                );

                if (result != null) {
                  setState(() {
                    _discussion = Discussion.fromJson(result['data']);
                  });
                }
              },
            ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'browser',
                child: Row(
                  children: const [
                    Icon(Icons.open_in_browser),
                    SizedBox(width: 8),
                    Text('浏览器打开'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: const [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('分享链接'),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (_discussion != null) {
                // 获取完整的讨论链接
                final flarumApi = Get.find<FlarumApi>();
                final baseUrl = flarumApi.baseUrl;

                // 确保baseUrl不为空
                if (baseUrl == null || baseUrl.isEmpty) {
                  SnackbarUtils.showMaterialSnackbar(
                    context,
                    '无法获取API端点，请先设置端点',
                  );
                  return;
                }

                final discussionUrl =
                    '$baseUrl/d/${_discussion!.id}-${_discussion!.slug}';

                if (value == 'browser') {
                  // 在浏览器中打开
                  try {
                    final uri = Uri.parse(discussionUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      SnackbarUtils.showMaterialSnackbar(context, '无法打开链接');
                    }
                  } catch (e) {
                    SnackbarUtils.showMaterialSnackbar(context, '无法打开链接');
                  }
                } else if (value == 'share') {
                  // 分享链接
                  try {
                    await launchUrl(
                      Uri.parse(
                        'mailto:?subject=${Uri.encodeComponent(_discussion!.title)}&body=${Uri.encodeComponent(discussionUrl)}',
                      ),
                      mode: LaunchMode.externalApplication,
                    );
                  } catch (e) {
                    SnackbarUtils.showMaterialSnackbar(context, '分享失败');
                  }
                }
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicatorM3E())
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
