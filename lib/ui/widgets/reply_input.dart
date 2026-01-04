import 'package:flutter/material.dart';

class ReplyInput extends StatefulWidget {
  final VoidCallback onSubmit;
  final ValueChanged<String> onContentChanged;
  final String initialContent;
  final bool isSubmitting;

  const ReplyInput({
    Key? key,
    required this.onSubmit,
    required this.onContentChanged,
    this.initialContent = '',
    this.isSubmitting = false,
  }) : super(key: key);

  @override
  State<ReplyInput> createState() => _ReplyInputState();
}

class _ReplyInputState extends State<ReplyInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 输入框
          TextField(
            controller: _controller,
            onChanged: widget.onContentChanged,
            maxLines: 4,
            minLines: 1,
            decoration: InputDecoration(
              hintText: '写下你的回复...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(12),
              suffixIcon: IconButton(
                icon: const Icon(Icons.emoji_emotions),
                onPressed: () {
                  // 表情选择
                  print('Emoji button tapped');
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 操作按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 左侧按钮组
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image),
                    onPressed: () {
                      // 图片上传
                      print('Image upload button tapped');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.link),
                    onPressed: () {
                      // 插入链接
                      print('Insert link button tapped');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.code),
                    onPressed: () {
                      // 插入代码
                      print('Insert code button tapped');
                    },
                  ),
                ],
              ),
              // 发送按钮
              ElevatedButton.icon(
                onPressed: widget.isSubmitting ? null : widget.onSubmit,
                icon: widget.isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: const Text('发送'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
