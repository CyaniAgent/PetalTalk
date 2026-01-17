import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:m3e_collection/m3e_collection.dart';
import '../../state/profile_controller.dart';
import '../../state/main_state.dart';
import '../../utils/snackbar_utils.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileController _controller = Get.isRegistered<ProfileController>() 
      ? Get.find<ProfileController>() 
      : Get.put(ProfileController());

  @override
  void initState() {
    super.initState();
    // 初始化时刷新用户数据
    _controller.fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(child: LoadingIndicatorM3E());
        }

        final user = _controller.user.value;
        if (user == null) {
          return _buildNotLoggedIn();
        }

        return CustomScrollView(
          slivers: [_buildHeader(context, user), _buildBody(context, user)],
        );
      }),
    );
  }

  Widget _buildNotLoggedIn() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('您尚未登录', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Get.toNamed('/login'),
            child: const Text('登录'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // 背景渐变
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.tertiaryContainer,
                  ],
                ),
              ),
            ),
            // 用户信息居中
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Hero(
                  tag: 'avatar_${user.id}',
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: colorScheme.surface,
                    backgroundImage: user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? Text(
                            user.displayName[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.displayName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  '@${user.username}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                // 组勋章
                Wrap(
                  spacing: 4,
                  children: _controller.groups.map((group) {
                    final color = group['color'] != null
                        ? Color(
                            int.parse(group['color'].replaceFirst('#', '0xFF')),
                          )
                        : colorScheme.secondary;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: color.a * 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: color.withValues(alpha: color.a * 0.5),
                        ),
                      ),
                      child: Text(
                        group['nameSingular'],
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, user) {
    final theme = Theme.of(context);

    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 统计数据
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('讨论', user.discussionCount.toString(), theme),
                  _buildStatItem('评论', user.commentCount.toString(), theme),
                  _buildStatItem('加入', _formatDate(user.joinTime), theme),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildSectionTitle('账户设置', theme),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('系统设置'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Get.toNamed('/settings'),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('关于 PetalTalk'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Get.toNamed('/about'),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton.icon(
                  onPressed: () => _handleLogout(),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    '退出登录',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(height: 100), // 为底部导航留出空间
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildStatItem(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  void _handleLogout() {
    _controller.logout();
    SnackbarUtils.showSnackbar('已退出登录');
    final mainController = Get.find<UiMainController>();
    mainController.setSelectedIndex(0);
    // 强制刷新主页状态
    Get.offAllNamed('/home');
  }
}
