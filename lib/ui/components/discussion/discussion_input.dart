import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import '../../../config/constants.dart';

class DiscussionInput extends StatefulWidget {
  final String? initialTitle;
  final String initialContent;
  final bool showTitle;
  final String titleHint;
  final String contentHint;
  final String submitLabel;
  final Function(String? title, String content) onSubmit;
  final bool isSubmitting;

  const DiscussionInput({
    super.key,
    this.initialTitle,
    this.initialContent = '',
    this.showTitle = false,
    this.titleHint = '请输入标题',
    this.contentHint = '写下你的内容...',
    this.submitLabel = '发送',
    required this.onSubmit,
    this.isSubmitting = false,
  });

  @override
  State<DiscussionInput> createState() => _DiscussionInputState();
}

class _DiscussionInputState extends State<DiscussionInput> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _insertText(String text) {
    final textEditingValue = _contentController.value;
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

    _contentController.value = textEditingValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: selectionStart + text.length),
    );
  }

  void _insertFormat(String before, String after, [String? placeholder]) {
    final textEditingValue = _contentController.value;
    final int selectionStart = textEditingValue.selection.start >= 0
        ? textEditingValue.selection.start
        : 0;
    final int selectionEnd = textEditingValue.selection.end >= 0
        ? textEditingValue.selection.end
        : 0;

    String selectedText = selectionStart <= selectionEnd
        ? textEditingValue.text.substring(selectionStart, selectionEnd)
        : '';

    if (selectedText.isEmpty && placeholder != null) {
      selectedText = placeholder;
    }

    final String newText = textEditingValue.text.replaceRange(
      selectionStart,
      selectionEnd,
      '$before$selectedText$after',
    );

    int newCursorPosition;
    if (selectionStart == selectionEnd && placeholder != null) {
      newCursorPosition = selectionStart + before.length;
    } else {
      newCursorPosition = selectionStart + before.length + selectedText.length;
    }

    _contentController.value = textEditingValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.showTitle ? '发布主题' : '写下你的回复',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (widget.showTitle) ...[
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: widget.titleHint,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return '请输入标题';
                    if (value.length < Constants.titleMinLength) {
                      return '标题至少需要${Constants.titleMinLength}个字符';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _contentController,
                maxLines: 8,
                minLines: 3,
                decoration: InputDecoration(
                  hintText: widget.contentHint,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return '请输入内容';
                  if (value.length < Constants.contentMinLength) {
                    return '内容至少需要${Constants.contentMinLength}个字符';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _formatButton(Icons.title, () => _insertText('# ')),
                    _formatButton(
                      Icons.format_bold,
                      () => _insertFormat('**', '**', '加粗'),
                    ),
                    _formatButton(
                      Icons.format_italic,
                      () => _insertFormat('*', '*', '斜体'),
                    ),
                    _formatButton(Icons.format_quote, () => _insertText('> ')),
                    _formatButton(
                      Icons.code,
                      () => _insertFormat('`', '`', '代码'),
                    ),
                    _formatButton(
                      Icons.link,
                      () => _insertFormat('[]()', '', '链接'),
                    ),
                    _formatButton(
                      Icons.image_outlined,
                      () => _insertFormat('![图片]()', '', 'URL'),
                    ),
                    _formatButton(
                      Icons.format_list_bulleted,
                      () => _insertText('* '),
                    ),
                    _formatButton(
                      Icons.format_list_numbered,
                      () => _insertText('1. '),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: widget.isSubmitting
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          widget.onSubmit(
                            widget.showTitle ? _titleController.text : null,
                            _contentController.text,
                          );
                        }
                      },
                icon: widget.isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: LoadingIndicatorM3E(),
                      )
                    : const Icon(Icons.send),
                label: Text(widget.submitLabel),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formatButton(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      visualDensity: VisualDensity.compact,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}
