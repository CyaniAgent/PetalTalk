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
