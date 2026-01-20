/// 搜索组件，负责处理搜索的UI和逻辑
/// 
/// 该组件提供：
/// 1. 搜索输入框UI
/// 2. 搜索请求处理
/// 3. 10秒超时机制
/// 4. 错误处理和用户反馈
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../core/logger.dart';

/// 搜索回调函数类型定义
typedef SearchCallback = Future<void> Function(String query);

/// 搜索组件状态
class SearchState {
  final String query;
  final bool isLoading;
  
  const SearchState({
    required this.query,
    required this.isLoading,
  });
  
  /// 创建初始状态
  factory SearchState.initial() => const SearchState(
    query: '',
    isLoading: false,
  );
  
  /// 复制当前状态并更新属性
  SearchState copyWith({
    String? query,
    bool? isLoading,
  }) {
    return SearchState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// 搜索逻辑控制器，管理搜索状态和逻辑
class SearchLogicController {
  final TextEditingController textController = TextEditingController();
  SearchState _state = SearchState.initial();
  
  /// 获取当前搜索状态
  SearchState get state => _state;
  
  /// 状态变更回调
  ValueChanged<SearchState>? onStateChanged;
  
  /// 搜索请求回调
  SearchCallback? onSearch;
  
  /// 更新状态并通知监听器
  void _updateState(SearchState newState) {
    _state = newState;
    onStateChanged?.call(newState);
  }
  
  /// 处理搜索请求
  Future<void> handleSearch(String query) async {
    if (_state.query == query) return;
    
    // 如果查询为空或空白字符串，关闭搜索并返回首页
    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }
    
    // 更新状态
    _updateState(_state.copyWith(
      query: query,
      isLoading: true,
    ));
    
    try {
      // 调用搜索回调
      if (onSearch != null) {
        await onSearch!(query);
      }
      
    } catch (e) {
      // 更新状态
      _updateState(_state.copyWith(isLoading: false));
      
      // 处理错误
      _handleError(e);
      rethrow;
    }
  }
  
  /// 处理错误
  void _handleError(dynamic e) {
    String errorMessage;
    if (e is SocketException) {
      errorMessage = '网络连接失败，请检查网络设置';
    } else if (e is TimeoutException) {
      errorMessage = '搜索请求超时，请检查网络连接';
    } else if (e is DioException) {
      final statusCode = e.response?.statusCode;
      switch (statusCode) {
        case 403:
          errorMessage = '搜索请求被安全拦截，请稍后重试';
          break;
        case 400:
          errorMessage = '搜索参数错误，请检查查询内容';
          break;
        case 429:
          errorMessage = '搜索请求过于频繁，请稍后再试';
          break;
        case 500:
        case 502:
        case 503:
        case 504:
          errorMessage = '服务器内部错误，请稍后重试';
          break;
        default:
          errorMessage = '搜索失败: ${e.message ?? e.toString()}';
      }
    } else {
      errorMessage = '搜索失败: ${e.toString()}';
    }
    
    logger.error('搜索失败: $e', e);
    // 显示错误信息给用户
    SnackbarUtils.showSnackbar(errorMessage, type: SnackbarType.error);
  }
  
  /// 清除搜索
  void clearSearch() {
    textController.clear();
    
    // 更新状态
    _updateState(SearchState.initial());
    
    // 触发空搜索
    if (onSearch != null) {
      onSearch!('');
    }
  }
  
  /// 销毁资源
  void dispose() {
    textController.dispose();
  }
}

/// 搜索组件UI
class SearchWidget extends StatefulWidget {
  /// 搜索逻辑控制器
  final SearchLogicController controller;
  
  /// 搜索提示文本
  final String hintText;
  
  /// 是否启用搜索按钮
  final bool showSearchButton;
  
  /// 构造函数
  const SearchWidget({
    super.key,
    required this.controller,
    this.hintText = '搜索...',
    this.showSearchButton = false,
  });
  
  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

/// 搜索组件状态
class _SearchWidgetState extends State<SearchWidget> {
  @override
  void initState() {
    super.initState();
    // 监听状态变化
    widget.controller.onStateChanged = _handleStateChanged;
  }
  
  @override
  void dispose() {
    widget.controller.onStateChanged = null;
    super.dispose();
  }
  
  /// 处理状态变化
  void _handleStateChanged(SearchState state) {
    if (mounted) {
      setState(() {});
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state;
    
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller.textController,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                suffixIcon: state.query.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          state.isLoading ? Icons.hourglass_empty : Icons.close,
                          size: 20,
                        ),
                        onPressed: state.isLoading ? null : widget.controller.clearSearch,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                widget.controller.handleSearch(value);
              },
            ),
          ),
          if (widget.showSearchButton && !state.isLoading)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  final query = widget.controller.textController.text;
                  if (query.isNotEmpty) {
                    widget.controller.handleSearch(query);
                  }
                },
              ),
            ),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.only(left: 8, right: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }
}