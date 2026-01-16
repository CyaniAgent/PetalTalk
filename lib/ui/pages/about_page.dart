import 'package:flutter/material.dart';
import '../../services/github_service.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:url_launcher/url_launcher.dart';

/// 开发者角色信息
class DeveloperRole {
  final String name;
  final String role;

  const DeveloperRole({required this.name, required this.role});
}

/// 应用信息配置类
class AppInfo {
  /// 应用名称
  static const String appName = 'PetalTalk';

  /// 应用版本
  static const String appVersion = 'v0.0.11';

  /// 应用图标路径
  static const String appIcon = 'assets/icons/logo.png';

  /// 应用技术栈
  static const String techStack = 'Flutter';

  /// 应用开源协议
  static const String license = 'MIT License';

  /// 应用描述
  static const String description = '这是一个基于 Flutter 开发的 Flarum 客户端，支持多种平台。';

  /// 版权信息
  static const String copyright = '© 2026 CyaniAgent';

  /// 开发者GitHub用户名和角色映射
  static const List<DeveloperRole> developerRoles = [
    DeveloperRole(name: 'CyaniAgent', role: '组织'),
    DeveloperRole(name: 'SakuraCake', role: '贡献者'),
    DeveloperRole(name: 'YunaAyase', role: '贡献者'),
  ];
}

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final GitHubService _githubService = GitHubService();

  /// 是否正在加载开发者信息
  bool _isLoading = true;

  /// 开发者信息列表
  List<(GitHubDeveloper, String?)> _developers = [];

  @override
  void initState() {
    super.initState();
    _loadDeveloperInfo();
  }

  /// 加载开发者信息
  Future<void> _loadDeveloperInfo() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 获取所有开发者的GitHub信息
      final usernames = AppInfo.developerRoles
          .map((role) => role.name)
          .toList();
      final githubDevelopers = await _githubService.getUsersInfo(usernames);

      // 合并开发者信息和角色
      setState(() {
        _developers = githubDevelopers
            .asMap()
            .entries
            .where((entry) => entry.value != null)
            .map(
              (entry) => (entry.value!, AppInfo.developerRoles[entry.key].role),
            )
            .toList();
      });
    } catch (e) {
      // 如果加载失败，使用默认信息
      setState(() {
        _developers = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 应用图标
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage(AppInfo.appIcon),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 应用名称和版本
              Text(
                AppInfo.appName,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                AppInfo.appVersion,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              // 应用信息卡片
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // 技术栈
                      const ListTile(
                        leading: Icon(Icons.code),
                        title: Text('技术栈'),
                        subtitle: Text(AppInfo.techStack),
                      ),

                      // 开源协议
                      const ListTile(
                        leading: Icon(Icons.favorite),
                        title: Text('开源协议'),
                        subtitle: Text(AppInfo.license),
                      ),

                      // 应用描述
                      const ListTile(
                        leading: Icon(Icons.info),
                        title: Text('关于'),
                        subtitle: Text(AppInfo.description),
                      ),

                      const Divider(),

                      // 开发者列表标题
                      const ListTile(
                        leading: Icon(Icons.group),
                        title: Text('开发者'),
                      ),

                      // 开发者信息列表
                      if (_isLoading)
                        // 加载中状态
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: LoadingIndicatorM3E(),
                        )
                      else if (_developers.isNotEmpty)
                        // 加载成功，显示开发者列表
                        for (final (developer, role) in _developers)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(
                                  developer.avatarUrl,
                                ),
                                onBackgroundImageError: (_, _) =>
                                    Text(developer.name[0]),
                              ),
                              title: Text(developer.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (role != null) Text(role),
                                  Text('@${developer.login}'),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                // 使用url_launcher跳转到GitHub个人主页
                                final url = developer.htmlUrl;
                                if (url.isNotEmpty) {
                                  await launchUrl(
                                    Uri.parse(url),
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              },
                            ),
                          )
                      else
                        // 加载失败状态
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('加载开发者信息失败'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 版权信息
              Text(
                AppInfo.copyright,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
