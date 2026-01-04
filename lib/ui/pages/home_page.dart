import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/services/discussion_service.dart';
import '../../api/models/discussion.dart';
import '../../api/services/auth_service.dart';
import '../widgets/discussion_card.dart';
import '../widgets/ui_main_frame.dart';

// 主题帖列表组件
class DiscussionList extends StatefulWidget {
  const DiscussionList({Key? key}) : super(key: key);

  @override
  State<DiscussionList> createState() => _DiscussionListState();
}

class _DiscussionListState extends State<DiscussionList> {
  final DiscussionService _discussionService = DiscussionService();
  final List<Discussion> _discussions = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadDiscussions();
  }

  // 加载主题帖列表
  Future<void> _loadDiscussions({bool isRefresh = false}) async {
    if (_isLoading || (!_hasMore && !isRefresh)) return;

    // 对于刷新操作，不显示额外的加载动画，只使用RefreshIndicator的动画
    if (!isRefresh) {
      setState(() {
        _isLoading = true;
      });
    }

    final result = await _discussionService.getDiscussions(
      offset: isRefresh ? 0 : _offset,
      limit: _limit,
    );

    if (result != null) {
      final List<Discussion> newDiscussions = (result['data'] as List)
          .map((discussion) => Discussion.fromJson(discussion))
          .toList();

      setState(() {
        _isLoading = false;
        if (isRefresh) {
          // 刷新时，等待数据加载完成后再清空列表并更新，避免UI闪烁
          _discussions.clear();
          _discussions.addAll(newDiscussions);
          _offset = newDiscussions.length;
          _hasMore = newDiscussions.length == _limit;
        } else {
          _discussions.addAll(newDiscussions);
          _offset += newDiscussions.length;
          _hasMore = newDiscussions.length == _limit;
        }
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar('加载失败', '获取主题帖列表失败', snackPosition: SnackPosition.BOTTOM);
    }
  }

  // 下拉刷新
  Future<void> _handleRefresh() async {
    await _loadDiscussions(isRefresh: true);
  }

  // 上拉加载更多
  Future<void> _handleLoadMore() async {
    await _loadDiscussions();
  }

  // 跳转到主题帖详情页
  void _gotoDiscussionDetail(Discussion discussion) {
    Get.toNamed('/discussion/${discussion.id}', arguments: discussion);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flarum 社区'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // 搜索功能
              Get.snackbar('提示', '功能开发中', snackPosition: SnackPosition.BOTTOM);
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // 跳转到消息页
              Get.snackbar('提示', '功能开发中', snackPosition: SnackPosition.BOTTOM);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // 跳转到设置页
              Get.toNamed('/settings');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          slivers: [
            SliverSafeArea(
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index < _discussions.length) {
                    final discussion = _discussions[index];
                    return DiscussionCard(
                      title: discussion.title,
                      author: '作者', // 这里需要从included数据中获取作者信息
                      createdAt: discussion.createdAt,
                      commentCount: discussion.commentCount,
                      viewCount: 0, // 这里需要从API响应中获取浏览数
                      isSticky: discussion.isSticky,
                      isLocked: discussion.isLocked,
                      tags: discussion.tagIds
                          .map((id) => '标签 $id')
                          .toList(), // 这里需要从included数据中获取标签名称
                      onTap: () => _gotoDiscussionDetail(discussion),
                    );
                  } else if (_hasMore) {
                    // 异步加载更多，避免在build过程中调用setState()
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
                      child: Center(child: Text('没有更多数据了')),
                    );
                  }
                }, childCount: _discussions.length + (_hasMore ? 1 : 0)),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 创建主题帖
          Get.snackbar('提示', '功能开发中', snackPosition: SnackPosition.BOTTOM);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// 主页面，使用UiMainFrame整合导航
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    // 导航项配置
    final List<Map<String, dynamic>> navItems = [
      {
        'id': 0,
        'icon': const Icon(Icons.home_outlined),
        'selectIcon': const Icon(Icons.home),
        'label': '首页',
        'count': 0,
        'page': const DiscussionList(),
      },
      // TODO: 消息通知功能待实现
      /*{
        'id': 1,
        'icon': const Icon(Icons.notifications_outlined),
        'selectIcon': const Icon(Icons.notifications),
        'label': '消息',
        'count': 0,
        'page': Scaffold(
          appBar: AppBar(title: const Text('消息通知')),
          body: const Center(child: Text('消息列表')),
        ),
      },*/
      {
        'id': 2,
        'icon': const Icon(Icons.person_outlined),
        'selectIcon': const Icon(Icons.person),
        'label': '我的',
        'count': 0,
        'page': Scaffold(
          appBar: AppBar(title: const Text('个人中心')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (authService.isLoggedIn())
                  Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey,
                        // 这里应该显示用户头像
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '用户名',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('用户邮箱@example.com'),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          // 退出登录
                          authService.logout();
                          Get.snackbar(
                            '提示',
                            '已退出登录',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          // 刷新页面
                          Get.offAllNamed('/home');
                        },
                        child: const Text('退出登录'),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      const Icon(
                        Icons.person_off,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text('您尚未登录', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          // 跳转到登录页面
                          Get.toNamed('/login');
                        },
                        child: const Text('登录'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      },
    ];

    return UiMainFrame(navItems: navItems, enableGradientBg: true);
  }
}
