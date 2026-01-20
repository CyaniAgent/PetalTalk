/// 主题帖列表组件，显示论坛的主题帖列表
///
/// 该组件支持：
/// 1. 分页加载主题帖
/// 2. 下拉刷新功能
/// 3. 上拉加载更多
/// 4. 自动保持组件状态
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:m3e_collection/m3e_collection.dart';

import '../../api/services/discussion_service.dart';
import '../../api/models/discussion.dart';
import '../../utils/snackbar_utils.dart';
import '../../core/logger.dart';
import '../../state/main_state.dart';
import '../components/search/search_widget.dart' as search_widget;
import '../components/discussion/discussion_card.dart';
import '../components/common/ui_main_frame.dart';
import 'notification_page.dart';
import 'profile/my_account_page.dart';
import '../components/discussion/discussion_input.dart';

class DiscussionList extends StatefulWidget {
  const DiscussionList({super.key});

  @override
  State<DiscussionList> createState() => _DiscussionListState();
}

class _DiscussionListState extends State<DiscussionList>
    with AutomaticKeepAliveClientMixin<DiscussionList> {
  final DiscussionService _discussionService = Get.find<DiscussionService>();
  final AppLogger _logger = AppLogger();
  final List<Discussion> _discussions = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;
  late final search_widget.SearchLogicController _searchController;

  // 存储用户信息，key是userId，value是用户名
  final Map<String, String> _users = {};
  // 存储标签信息，key是tagId，value是标签名称
  final Map<String, String> _tags = {};

  @override
  void initState() {
    super.initState();
    _searchController = search_widget.SearchLogicController();
    _searchController.onSearch = _handleSearchRequest;
    _loadDiscussions(query: _searchController.state.query);
    
    // 监听首页按钮重复点击事件
    final mainController = Get.find<UiMainController>();
    mainController.homeReselected.listen((reselect) {
      if (reselect && _searchController.state.query.isNotEmpty) {
        _logger.info('首页按钮重复点击，关闭搜索并返回首页');
        _searchController.clearSearch();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  // 加载主题帖列表
  Future<void> _loadDiscussions({bool isRefresh = false, String? query}) async {
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
      query: query ?? _searchController.state.query,
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
    await _loadDiscussions(isRefresh: true, query: _searchController.state.query);
  }

  // 上拉加载更多
  Future<void> _handleLoadMore() async {
    await _loadDiscussions(query: _searchController.state.query);
  }

  // 处理搜索请求（SearchLogicController回调）
  Future<void> _handleSearchRequest(String query) async {
    if (mounted) {
      setState(() {
        _discussions.clear();
        _offset = 0;
        _hasMore = true;
        _isLoading = true;
      });
    }

    try {
      await _loadDiscussions(query: query);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      // 错误处理由SearchLogicController负责，这里只重新抛出异常
      rethrow;
    }
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
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: search_widget.SearchWidget(
            controller: _searchController,
            hintText: '搜索帖子...',
          ),
        ),
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
                // 显示创建主题帖弹窗
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => DiscussionInput(
                    showTitle: true,
                    onSubmit: (title, content) async {
                      if (title == null) return;
                      final result = await _discussionService.createDiscussion(
                        title: title,
                        content: content,
                      );
                      if (result != null) {
                        Navigator.pop(context);
                        SnackbarUtils.showSnackbar('发布成功');
                        _handleRefresh();
                      } else {
                        SnackbarUtils.showSnackbar('发布失败');
                      }
                    },
                  ),
                );
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
        'page': const MyAccountPage(),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return UiMainFrame(navItems: navItems, enableGradientBg: true);
  }
}
