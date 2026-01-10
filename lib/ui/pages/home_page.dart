/// 主题帖列表组件，显示论坛的主题帖列表
///
/// 该组件支持：
/// 1. 分页加载主题帖
/// 2. 下拉刷新功能
/// 3. 上拉加载更多
/// 4. 自动保持组件状态
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:m3e_collection/m3e_collection.dart';

import '../../api/services/discussion_service.dart';
import '../../api/models/discussion.dart';
import '../../api/services/auth_service.dart';
import '../../utils/snackbar_utils.dart';
import '../components/discussion/discussion_card.dart';
import '../components/common/ui_main_frame.dart';
import 'notification_page.dart';
import '../../state/main_state.dart';

class DiscussionList extends StatefulWidget {
  const DiscussionList({super.key});

  @override
  State<DiscussionList> createState() => _DiscussionListState();
}

class _DiscussionListState extends State<DiscussionList>
    with AutomaticKeepAliveClientMixin<DiscussionList> {
  final DiscussionService _discussionService = Get.find<DiscussionService>();
  final List<Discussion> _discussions = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;

  // 存储用户信息，key是userId，value是用户名
  final Map<String, String> _users = {};
  // 存储标签信息，key是tagId，value是标签名称
  final Map<String, String> _tags = {};

  @override
  void initState() {
    super.initState();
    _loadDiscussions();
  }

  @override
  bool get wantKeepAlive => true;

  // 加载主题帖列表
  Future<void> _loadDiscussions({bool isRefresh = false}) async {
    if (_isLoading || (!_hasMore && !isRefresh)) return;

    // 对于刷新操作，不显示额外的加载动画，只使用RefreshIndicator的动画
    if (!isRefresh) {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }
    }

    final result = await _discussionService.getDiscussions(
      offset: isRefresh ? 0 : _offset,
      limit: _limit,
    );

    // 检查组件是否仍然挂载
    if (!mounted) return;

    if (result != null) {
      // 处理included数据，获取用户和标签信息
      if (result.containsKey('included')) {
        final List<dynamic> included = result['included'];
        for (final item in included) {
          if (item['type'] == 'users') {
            final userId = item['id'];
            final username = item['attributes']['username'];
            _users[userId] = username;
          } else if (item['type'] == 'tags') {
            final tagId = item['id'];
            final tagName = item['attributes']['name'];
            _tags[tagId] = tagName;
          }
        }
      }

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
      // 不再显示错误提示，只在UI上显示错误状态
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
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('PetalTalk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // 搜索功能
              SnackbarUtils.showDevelopmentInProgress(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // 切换到底部导航栏的通知页面
              final uiController = Get.find<UiMainController>();
              uiController.setSelectedIndex(1);
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
                      id: discussion.id,
                      title: discussion.title,
                      author: _users[discussion.userId] ?? '未知用户',
                      createdAt: discussion.createdAt,
                      commentCount: discussion.commentCount,
                      isSticky: discussion.isSticky,
                      isLocked: discussion.isLocked,
                      tags: discussion.tagIds
                          .map((id) => _tags[id] ?? '标签 $id')
                          .toList(),
                      onTap: () => _gotoDiscussionDetail(discussion),
                    );
                  } else if (_hasMore) {
                    // 异步加载更多，避免在build过程中调用setState()
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _handleLoadMore();
                    });
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: LoadingIndicatorM3E()),
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
      floatingActionButton: Builder(
        builder: (context) {
          // 检测屏幕宽度，根据不同设备尺寸调整padding
          final screenWidth = MediaQuery.of(context).size.width;
          final isMobile = screenWidth < 768;

          return Padding(
            padding: EdgeInsets.only(bottom: isMobile ? 80.0 : 0.0),
            child: FloatingActionButton(
              onPressed: () {
                // 创建主题帖
                Get.toNamed('/create-discussion');
              },
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// 主页面，使用UiMainFrame整合导航
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<Map<String, dynamic>> navItems;

  @override
  void initState() {
    super.initState();
    // 初始化导航项配置，只在组件创建时执行一次
    // 这样页面实例只会创建一次，避免窗口大小变化时状态丢失
    navItems = [
      {
        'id': 0,
        'icon': const Icon(Icons.home_outlined),
        'selectIcon': const Icon(Icons.home),
        'label': '首页',
        'count': 0,
        'page': const DiscussionList(),
      },
      {
        'id': 1,
        'icon': const Icon(Icons.notifications_outlined),
        'selectIcon': const Icon(Icons.notifications),
        'label': '消息',
        'count': 0,
        'page': const NotificationList(),
      },
      {
        'id': 2,
        'icon': const Icon(Icons.person_outlined),
        'selectIcon': const Icon(Icons.person),
        'label': '我的',
        'count': 0,
        'page': const _ProfilePage(),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return UiMainFrame(navItems: navItems, enableGradientBg: true);
  }
}

// 个人中心页面，提取为独立组件
class _ProfilePage extends GetView {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Get.find<AuthService>();

    return Scaffold(
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
                    backgroundColor: Colors.blue,
                    // 这里应该显示用户头像
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '占位符',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('占位符@sorange.top'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // 退出登录
                      authService.logout();
                      SnackbarUtils.showMaterialSnackbar(context, '已退出登录');
                      // 刷新页面
                      final mainController = Get.find<UiMainController>();
                      mainController.setSelectedIndex(0);
                      Get.offAllNamed('/home');
                    },
                    child: const Text('退出登录'),
                  ),
                ],
              )
            else
              Column(
                children: [
                  const Icon(Icons.person_off, size: 80, color: Colors.grey),
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
    );
  }
}
