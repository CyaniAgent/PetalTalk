import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:m3e_collection/m3e_collection.dart';
import '../../../state/profile_controller.dart';
import '../../../state/main_state.dart';
import '../../../utils/snackbar_utils.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});

  @override
  State<MyAccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
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

        // 优先处理错误状态，如果已登录但加载失败
        if (_controller.error.value != null) {
          return _buildErrorView(context, _controller.error.value!);
        }

        final user = _controller.user.value;

        return RefreshIndicator(
          onRefresh: _controller.fetchProfile,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (user != null)
                _buildHeader(context, user)
              else
                _buildLoggedOutHeader(context),
              if (user != null) _buildStats(context, user),
              _buildActions(context, user),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildErrorView(BuildContext context, String errorMessage) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _controller.fetchProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedOutHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.surfaceContainerHighest.withAlpha(180),
                colorScheme.surface,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Icon(
                Icons.account_circle_outlined,
                size: 80,
                color: theme.colorScheme.primary.withAlpha(150),
              ),
              const SizedBox(height: 16),
              const Text(
                '登录以查看个人资料',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Get.toNamed('/login'),
                icon: const Icon(Icons.login, size: 18),
                label: const Text('立即登录'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primaryContainer.withAlpha(180),
                colorScheme.surface,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              CircleAvatar(
                radius: 45,
                backgroundColor: colorScheme.primaryContainer,
                backgroundImage: user.avatarUrl != null
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null
                    ? Text(
                        user.displayName[0].toUpperCase(),
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                user.displayName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '@${user.username}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              // roles / groups
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: _controller.groups.map<Widget>((group) {
                  final color = group['color'] != null
                      ? Color(
                          int.parse(group['color'].replaceFirst('#', '0xFF')),
                        )
                      : colorScheme.secondary;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withAlpha(120)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (group['icon'] != null) ...[
                          Icon(
                            _getIconData(group['icon']),
                            size: 12,
                            color: color,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          group['nameSingular'],
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context, user) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatColumn(
                    context,
                    '讨论',
                    user.discussionCount.toString(),
                  ),
                  VerticalDivider(color: theme.colorScheme.outlineVariant),
                  _buildStatColumn(context, '评论', user.commentCount.toString()),
                  VerticalDivider(color: theme.colorScheme.outlineVariant),
                  _buildStatColumn(
                    context,
                    '加入于',
                    _formatJoinDate(user.joinTime),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, user) {
    final theme = Theme.of(context);
    return SliverList(
      delegate: SliverChildListDelegate([
        const SizedBox(height: 16),
        _buildSectionHeader(context, '通用'),
        _buildActionTile(
          context,
          icon: Icons.settings_outlined,
          title: '设置',
          onTap: () => Get.toNamed('/settings'),
        ),
        _buildActionTile(
          context,
          icon: Icons.notifications_none_outlined,
          title: '通知设置',
          onTap: () => SnackbarUtils.showDevelopmentInProgress(),
        ),
        _buildActionTile(
          context,
          icon: Icons.bug_report_outlined,
          title: '调试日志',
          onTap: () => Get.toNamed('/logs'),
        ),
        const SizedBox(height: 16),
        _buildSectionHeader(context, '关于'),
        _buildActionTile(
          context,
          icon: Icons.info_outline,
          title: '关于 PetalTalk',
          onTap: () => Get.toNamed('/about'),
        ),
        if (user != null) ...[
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: OutlinedButton.icon(
              onPressed: () => _handleLogout(),
              icon: const Icon(Icons.logout),
              label: const Text('退出登录'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.errorContainer),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
        const SizedBox(height: 100),
      ]),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurface),
      title: Text(title),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.outlineVariant,
      ),
      onTap: onTap,
    );
  }

  String _formatJoinDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  IconData _getIconData(String? iconName) {
    if (iconName == null) return Icons.group_outlined;
    if (iconName.contains('star')) return Icons.star_outline;
    if (iconName.contains('wrench')) return Icons.admin_panel_settings_outlined;
    if (iconName.contains('user')) return Icons.person_outline;
    return Icons.label_outline;
  }

  void _handleLogout() {
    _controller.logout();
    SnackbarUtils.showSnackbar('已退出登录');
    final mainController = Get.find<UiMainController>();
    mainController.setSelectedIndex(0);
    Get.offAllNamed('/home');
  }
}
