import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

class PostContent extends StatelessWidget {
  final String contentHtml;

  const PostContent({Key? key, required this.contentHtml}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Html(
      data: contentHtml,
      onLinkTap: (url, attributes, element) async {
        if (url == null) return;

        // 判断是否为回复引用
        final isQuote = attributes['class']?.contains('QuoteLink') ?? false;

        if (isQuote) {
          // 回复引用，不打开外部链接
          print('Quote link tapped: $url');
          return;
        }

        // 外部链接，显示确认对话框
        final confirmed =
            await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('打开链接'),
                content: Text('是否要打开外部链接？\n$url'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('打开'),
                  ),
                ],
              ),
            ) ??
            false;

        if (confirmed) {
          // 打开链接
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
    );
  }
}
