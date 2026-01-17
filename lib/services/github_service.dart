import 'package:dio/dio.dart';
import '../core/logger.dart';

/// GitHub开发者信息模型
class GitHubDeveloper {
  /// 登录用户名
  final String login;
  
  /// 开发者名称
  final String name;
  
  /// 开发者头像URL
  final String avatarUrl;
  
  /// 开发者个人资料URL
  final String htmlUrl;
  
  /// 开发者邮箱
  final String? email;
  
  /// 开发者位置
  final String? location;
  
  /// 开发者博客URL
  final String? blog;
  
  /// 开发者公司
  final String? company;
  
  /// 开发者公开仓库数量
  final int publicRepos;
  
  /// 开发者关注者数量
  final int followers;
  
  /// 开发者关注的人数
  final int following;

  const GitHubDeveloper({
    required this.login,
    required this.name,
    required this.avatarUrl,
    required this.htmlUrl,
    this.email,
    this.location,
    this.blog,
    this.company,
    required this.publicRepos,
    required this.followers,
    required this.following,
  });

  /// 从JSON创建GitHubDeveloper实例
  factory GitHubDeveloper.fromJson(Map<String, dynamic> json) {
    return GitHubDeveloper(
      login: json['login'],
      name: json['name'] ?? json['login'],
      avatarUrl: json['avatar_url'],
      htmlUrl: json['html_url'],
      email: json['email'],
      location: json['location'],
      blog: json['blog'],
      company: json['company'],
      publicRepos: json['public_repos'],
      followers: json['followers'],
      following: json['following'],
    );
  }
}

/// GitHub服务类，用于获取GitHub相关信息
class GitHubService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.github.com',
    headers: {
      'Accept': 'application/vnd.github.v3+json',
    },
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// 获取指定用户名的GitHub用户信息
  Future<GitHubDeveloper?> getUserInfo(String username) async {
    try {
      logger.info('GitHubService: 获取用户信息 - $username');
      final response = await _dio.get('/users/$username');
      return GitHubDeveloper.fromJson(response.data);
    } catch (e, stackTrace) {
      logger.error('GitHubService: 获取用户信息失败 - $username', e, stackTrace);
      return null;
    }
  }

  /// 批量获取GitHub用户信息
  Future<List<GitHubDeveloper?>> getUsersInfo(List<String> usernames) async {
    final futures = usernames.map(getUserInfo).toList();
    return Future.wait(futures);
  }
}