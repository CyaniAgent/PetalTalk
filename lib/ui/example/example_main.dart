import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widgets/ui_main_frame.dart';
import '../widgets/setting_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'UI Components Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ExampleHomePage(),
      getPages: [
        GetPage(name: '/', page: () => const ExampleHomePage()),
        GetPage(name: '/setting', page: () => const ExampleSettingPage()),
      ],
    );
  }
}

class ExampleHomePage extends StatelessWidget {
  const ExampleHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 定义导航栏项
    final List<Map<String, dynamic>> navItems = [
      {
        'id': 0,
        'icon': const Icon(
          Icons.home_outlined,
          size: 21,
        ),
        'selectIcon': const Icon(
          Icons.home,
          size: 21,
        ),
        'label': "首页",
        'count': 0,
        'page': const HomeContent(),
      },
      {
        'id': 1,
        'icon': const Icon(
          Icons.trending_up,
          size: 21,
        ),
        'selectIcon': const Icon(
          Icons.trending_up_outlined,
          size: 21,
        ),
        'label': "排行榜",
        'count': 0,
        'page': const RankContent(),
      },
      {
        'id': 2,
        'icon': const Icon(
          Icons.motion_photos_on_outlined,
          size: 21,
        ),
        'selectIcon': const Icon(
          Icons.motion_photos_on,
          size: 21,
        ),
        'label': "动态",
        'count': 5, // 显示5条未读消息
        'page': const DynamicsContent(),
      },
      {
        'id': 3,
        'icon': const Icon(
          Icons.video_collection_outlined,
          size: 20,
        ),
        'selectIcon': const Icon(
          Icons.video_collection,
          size: 21,
        ),
        'label': "媒体库",
        'count': 0,
        'page': const MediaContent(),
      },
    ];

    return UiMainFrame(
      navItems: navItems,
      enableGradientBg: true,
    );
  }
}

// 首页内容
class HomeContent extends StatelessWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('首页内容'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Get.toNamed('/setting');
              },
              child: const Text('打开设置页面'),
            ),
          ],
        ),
      ),
    );
  }
}

// 排行榜内容
class RankContent extends StatelessWidget {
  const RankContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: const Text('排行榜内容'),
      ),
    );
  }
}

// 动态内容
class DynamicsContent extends StatelessWidget {
  const DynamicsContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: const Text('动态内容'),
      ),
    );
  }
}

// 媒体库内容
class MediaContent extends StatelessWidget {
  const MediaContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: const Text('媒体库内容'),
      ),
    );
  }
}

// 设置页面示例
class ExampleSettingPage extends StatelessWidget {
  const ExampleSettingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 定义设置项
    final List<Map<String, dynamic>> settingItems = [
      {
        'title': '隐私设置',
        'icon': Icons.privacy_tip_outlined,
        'content': const PrivacySettingContent(),
      },
      {
        'title': '推荐设置',
        'icon': Icons.recommend_outlined,
        'content': const RecommendSettingContent(),
      },
      {
        'title': '播放设置',
        'icon': Icons.play_arrow_outlined,
        'content': const PlaySettingContent(),
      },
      {
        'title': '外观设置',
        'icon': Icons.style_outlined,
        'content': const StyleSettingContent(),
      },
      {
        'title': '其他设置',
        'icon': Icons.more_horiz_outlined,
        'content': const ExtraSettingContent(),
      },
    ];

    return UiSettingPage(
      settingItems: settingItems,
      showLogoutButton: true,
      onLogout: () {
        Get.snackbar('提示', '退出登录成功');
        Get.back();
      },
      onAbout: () {
        Get.snackbar('关于', '这是一个UI组件示例');
      },
    );
  }
}

// 隐私设置内容
class PrivacySettingContent extends StatelessWidget {
  const PrivacySettingContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('隐私设置内容'),
    );
  }
}

// 推荐设置内容
class RecommendSettingContent extends StatelessWidget {
  const RecommendSettingContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('推荐设置内容'),
    );
  }
}

// 播放设置内容
class PlaySettingContent extends StatelessWidget {
  const PlaySettingContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('播放设置内容'),
    );
  }
}

// 外观设置内容
class StyleSettingContent extends StatelessWidget {
  const StyleSettingContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('外观设置内容'),
    );
  }
}

// 其他设置内容
class ExtraSettingContent extends StatelessWidget {
  const ExtraSettingContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('其他设置内容'),
    );
  }
}