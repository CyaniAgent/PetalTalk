import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';

class ReplyInput extends StatefulWidget {
  final VoidCallback onSubmit;
  final ValueChanged<String> onContentChanged;
  final String initialContent;
  final bool isSubmitting;

  const ReplyInput({
    super.key,
    required this.onSubmit,
    required this.onContentChanged,
    this.initialContent = '',
    this.isSubmitting = false,
  });

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

  // 插入文本
  void _insertText(String text) {
    final textEditingValue = _controller.value;
    // 确保选择索引有效
    final int selectionStart = textEditingValue.selection.start >= 0
        ? textEditingValue.selection.start
        : 0;
    final int selectionEnd = textEditingValue.selection.end >= 0
        ? textEditingValue.selection.end
        : 0;

    final String newText = textEditingValue.text.replaceRange(
      selectionStart,
      selectionEnd,
      text,
    );

    final int newCursorPosition = selectionStart + text.length;

    _controller.value = textEditingValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );

    widget.onContentChanged(_controller.text);
  }

  // 插入格式文本
  void _insertFormat(String before, String after, [String? placeholder]) {
    final textEditingValue = _controller.value;
    // 确保选择索引有效
    final int selectionStart = textEditingValue.selection.start >= 0
        ? textEditingValue.selection.start
        : 0;
    final int selectionEnd = textEditingValue.selection.end >= 0
        ? textEditingValue.selection.end
        : 0;

    String selectedText = '';
    // 只有在索引有效的情况下才截取子字符串
    if (selectionStart >= 0 &&
        selectionEnd >= 0 &&
        selectionStart <= selectionEnd) {
      selectedText = textEditingValue.text.substring(
        selectionStart,
        selectionEnd,
      );
    }
    if (selectedText.isEmpty && placeholder != null) {
      selectedText = placeholder;
    }

    final String newText = textEditingValue.text.replaceRange(
      selectionStart,
      selectionEnd,
      '$before$selectedText$after',
    );

    int newCursorPosition;
    if ((textEditingValue.selection.start == textEditingValue.selection.end ||
            selectionStart == selectionEnd) &&
        placeholder != null) {
      // 如果没有选中文本且有占位符，则光标放在占位符中间
      newCursorPosition = selectionStart + before.length;
    } else {
      // 否则光标放在格式文本后面
      newCursorPosition = selectionStart + before.length + selectedText.length;
    }

    _controller.value = textEditingValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );

    widget.onContentChanged(_controller.text);
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
            ),
          ),
          const SizedBox(height: 12),
          // 操作按钮 - 第一行
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // 标题按钮
              PopupMenuButton(
                icon: const Icon(Icons.title),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text('一级标题'),
                    onTap: () => _insertText('# '),
                  ),
                  PopupMenuItem(
                    child: const Text('二级标题'),
                    onTap: () => _insertText('## '),
                  ),
                  PopupMenuItem(
                    child: const Text('三级标题'),
                    onTap: () => _insertText('### '),
                  ),
                  PopupMenuItem(
                    child: const Text('四级标题'),
                    onTap: () => _insertText('#### '),
                  ),
                  PopupMenuItem(
                    child: const Text('五级标题'),
                    onTap: () => _insertText('##### '),
                  ),
                  PopupMenuItem(
                    child: const Text('六级标题'),
                    onTap: () => _insertText('###### '),
                  ),
                ],
              ),
              // 粗体
              IconButton(
                icon: const Icon(Icons.format_bold),
                onPressed: () => _insertFormat('**', '**', '粗体文本'),
              ),
              // 斜体
              IconButton(
                icon: const Icon(Icons.format_italic),
                onPressed: () => _insertFormat('*', '*', '斜体文本'),
              ),
              // 行内代码
              IconButton(
                icon: const Icon(Icons.code),
                onPressed: () => _insertFormat('`', '`', '行内代码'),
              ),
              // 引用
              IconButton(
                icon: const Icon(Icons.format_quote),
                onPressed: () => _insertText('> '),
              ),
              // 无序列表
              IconButton(
                icon: const Icon(Icons.format_list_bulleted),
                onPressed: () => _insertText('* '),
              ),
              // 有序列表
              IconButton(
                icon: const Icon(Icons.format_list_numbered),
                onPressed: () => _insertText('1. '),
              ),
              // 删除线
              IconButton(
                icon: const Icon(Icons.strikethrough_s),
                onPressed: () => _insertFormat('~~', '~~', '删除文本'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 操作按钮 - 第二行
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // 链接
              IconButton(
                icon: const Icon(Icons.link),
                onPressed: () => _insertFormat('[]()', '', '链接文本'),
              ),
              // 图片
              IconButton(
                icon: const Icon(Icons.image),
                onPressed: () => _insertFormat('![图片]()', '', '图片URL'),
              ),
              // 代码块
              IconButton(
                icon: const Icon(Icons.code),
                onPressed: () => _insertFormat('```\n', '\n```', '代码块'),
              ),
              // 分割线
              IconButton(
                icon: const Icon(Icons.horizontal_rule),
                onPressed: () => _insertText('\n---\n'),
              ),
              // 上标
              IconButton(
                icon: const Icon(Icons.superscript),
                onPressed: () => _insertFormat('^', '^', '上标'),
              ),
              // 下标
              IconButton(
                icon: const Icon(Icons.subscript),
                onPressed: () => _insertFormat('~', '~', '下标'),
              ),
              // 黑幕
              IconButton(
                icon: const Icon(Icons.visibility_off),
                onPressed: () => _insertFormat('>!', '!<', '黑幕内容'),
              ),
              // 提及用户
              IconButton(
                icon: const Icon(Icons.person_add),
                onPressed: () => _insertFormat('@', '', '用户名'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 发送按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: widget.isSubmitting ? null : widget.onSubmit,
                icon: widget.isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: LoadingIndicatorM3E(),
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
