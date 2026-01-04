import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

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
              const CircleAvatar(
                radius: 64,
                backgroundColor: Colors.blue,
                child: Icon(
                  Icons.forum,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // 应用名称和版本
              Text(
                'Flarum 客户端',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text('v1.0.0', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 32),

              // 开发者信息
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const ListTile(
                        leading: Icon(Icons.person),
                        title: Text('开发者'),
                        subtitle: Text('SakuraCake'),
                      ),
                      const ListTile(
                        leading: Icon(Icons.code),
                        title: Text('技术栈'),
                        subtitle: Text('Flutter 3.38.5'),
                      ),
                      const ListTile(
                        leading: Icon(Icons.favorite),
                        title: Text('开源协议'),
                        subtitle: Text('MIT License'),
                      ),
                      const ListTile(
                        leading: Icon(Icons.info),
                        title: Text('关于'),
                        subtitle: Text('这是一个基于 Flutter 开发的 Flarum 客户端，支持多种平台。'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 版权信息
              const Text(
                '© 2026 Flarum 客户端',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
