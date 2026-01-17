import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../api/services/discussion_service.dart';
import '../../utils/snackbar_utils.dart';
import '../../config/constants.dart';

class CreateDiscussionPage extends StatefulWidget {
  const CreateDiscussionPage({super.key});

  @override
  State<CreateDiscussionPage> createState() => _CreateDiscussionPageState();
}

class _CreateDiscussionPageState extends State<CreateDiscussionPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSubmitting = false;
  final DiscussionService _discussionService = Get.find<DiscussionService>();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // 插入文本
  void _insertText(String text) {
    final textEditingValue = _contentController.value;
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

    _contentController.value = textEditingValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );
  }

  // 插入格式文本
  void _insertFormat(String before, String after, [String? placeholder]) {
    final textEditingValue = _contentController.value;
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

    _contentController.value = textEditingValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );
  }

  // 处理发帖
  Future<void> _handleCreateDiscussion() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      final result = await _discussionService.createDiscussion(
        title: _titleController.text,
        content: _contentController.text,
      );

      setState(() {
        _isSubmitting = false;
      });

      if (result != null) {
        // 发帖成功，返回首页并刷新
        if (mounted) {
          SnackbarUtils.showSnackbar('发帖成功');
        }
        Get.offAllNamed('/home');
      } else {
        // 发帖失败
        if (mounted) {
          SnackbarUtils.showSnackbar('发帖失败');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发布主题'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _handleCreateDiscussion,
            child: Text(
              '发布',
              style: TextStyle(
                color: _isSubmitting
                    ? Colors.grey
                    : Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题输入框
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '标题',
                    hintText: '请输入主题标题',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入标题';
                    }
                    if (value.length < Constants.titleMinLength) {
                      return '标题至少需要${Constants.titleMinLength}个字符';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // 内容输入框
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: '内容',
                    hintText: '请输入主题内容',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 10,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入内容';
                    }
                    if (value.length < Constants.contentMinLength) {
                      return '内容至少需要${Constants.contentMinLength}个字符';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Markdown编辑按钮 - 第一行
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
                // Markdown编辑按钮 - 第二行
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
                // TODO: 标签选择功能待实现
                // const SizedBox(height: 16),
                // const Text('标签'),
                // const SizedBox(height: 8),
                // Wrap(
                //   spacing: 8,
                //   runSpacing: 8,
                //   children: [
                //     Chip(label: const Text('标签1'), onPressed: () {}),
                //     Chip(label: const Text('标签2'), onPressed: () {}),
                //     Chip(label: const Text('标签3'), onPressed: () {}),
                //   ],
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
