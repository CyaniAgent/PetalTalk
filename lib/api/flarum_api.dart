/// Flarum API 客户端，负责与 Flarum 后端进行通信
///
/// 该类提供了：
/// 1. 基于 Dio 的 HTTP 客户端封装
/// 2. 多端点管理功能
/// 3. 认证令牌管理
/// 4. 统一的请求方法（GET, POST, PUT, DELETE, PATCH）
///
/// 使用单例模式，确保在应用中只有一个 API 客户端实例
library;

import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import '../utils/verification_window.dart';
import '../core/logger.dart';

/// Flarum API 客户端类，封装了与 Flarum 后端通信的所有功能
class FlarumApi {
  /// 单例实例，确保全局唯一
  static final FlarumApi _instance = FlarumApi._internal();

  /// 工厂构造函数，返回单例实例
  factory FlarumApi() => _instance;

  /// 内部构造函数，初始化Dio客户端
  FlarumApi._internal() {
    _initDio();
  }

  /// Dio HTTP客户端实例
  late Dio _dio;

  /// Cookie管理器
  late CookieJar _cookieJar;

  /// 当前认证令牌
  String? _token;

  /// 当前API基础URL
  String? _baseUrl = 'https://flarum.imikufans.cn';

  /// 为特定端点生成唯一的存储键
  ///
  /// 参数：
  /// - endpoint: 端点URL
  /// - key: 原始存储键
  ///
  /// 返回值：
  /// - String: 带有端点标识的唯一存储键
  String _getEndpointKey(String endpoint, String key) {
    // 使用端点的哈希值作为唯一标识，确保不同端点的数据隔离
    final endpointHash = endpoint.hashCode.toString();
    return '${Constants.endpointDataPrefix}$endpointHash$key';
  }

  /// 初始化Dio HTTP客户端
  ///
  /// 配置内容包括：
  /// 1. 基本选项（基础URL、超时时间、请求头）
  /// 2. HTTP/2适配器
  /// 3. Cookie管理器
  /// 4. 认证拦截器
  void _initDio() {
    logger.info('FlarumApi: 初始化Dio客户端，baseUrl: $_baseUrl');

    // 基本请求头，无论是否使用浏览器请求头都会包含
    final basicHeaders = {
      'Accept': 'application/vnd.api+json',
      'Content-Type': 'application/vnd.api+json',
    };

    // 浏览器请求头，根据设置决定是否添加
    final browserHeaders = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
      'Referer': _baseUrl,
      'Origin': _baseUrl,
    };

    // 合并请求头
    final headers = {...basicHeaders, ...browserHeaders};

    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl!,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: headers,
      ),
    );

    // 添加HTTP/2适配器
    _dio.httpClientAdapter = Http2Adapter(
      ConnectionManager(
        idleTimeout: const Duration(seconds: 10),
        onClientCreate: (uri, config) {},
      ),
    );

    // 添加Cookie管理器
    _cookieJar = CookieJar();
    _dio.interceptors.add(CookieManager(_cookieJar));

    // 添加请求日志拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          logger.debug('FlarumApi: 发送请求 - ${options.method} ${options.uri}');
          if (options.data != null) {
            logger.debug('FlarumApi: 请求数据 - ${options.data}');
          }
          if (_token != null) {
            options.headers['Authorization'] = 'Token $_token';
          }

          // 根据设置调整请求头
          final prefs = await SharedPreferences.getInstance();
          final useBrowserHeaders =
              prefs.getBool(Constants.useBrowserHeadersKey) ??
              Constants.defaultUseBrowserHeaders;

          if (!useBrowserHeaders) {
            // 如果不使用浏览器请求头，只保留基本请求头
            options.headers = {
              'Accept': 'application/vnd.api+json',
              'Content-Type': 'application/vnd.api+json',
              if (_token != null) 'Authorization': 'Token $_token',
            };
          }

          return handler.next(options);
        },

        onResponse: (response, handler) {
          logger.debug(
            'FlarumApi: 收到响应 - ${response.statusCode} ${response.requestOptions.uri}',
          );
          return handler.next(response);
        },
      ),
    );

    // 添加认证拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Token $_token';
          }
          return handler.next(options);
        },
      ),
    );

    // 添加错误拦截器（处理WAF验证）
    // 使用 QueuedInterceptorsWrapper 确保请求按顺序处理，避免并发请求同时触发验证
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onError: (DioException e, ErrorInterceptorHandler handler) async {
          // 检查是否为WAF拦截（通常403或405，或者特定内容）
          // 阿里云ESA/LeiChi有时返回403，有时返回405
          if (e.response?.statusCode == 403 || e.response?.statusCode == 405) {
            logger.debug('FlarumApi: 检测到WAF拦截，尝试触发验证');
            // 尝试触发验证
            final requestOptions = e.requestOptions;
            final url = '${requestOptions.baseUrl}${requestOptions.path}';

            try {
              // 显示验证窗口
              final cookieValue = await VerificationWindow.show(url);

              if (cookieValue != null) {
                logger.debug('FlarumApi: WAF验证成功，添加Cookie');

                // 验证成功，添加Cookie到CookieJar
                final uri = Uri.parse(_baseUrl!);
                final cookie = Cookie('acw_sc__v2', cookieValue)
                  ..domain = uri.host
                  ..path = '/'
                  ..httpOnly = true;

                await _cookieJar.saveFromResponse(uri, [cookie]);

                // 重试请求
                logger.debug('FlarumApi: WAF验证成功，重试请求');
                final response = await _dio.fetch(requestOptions);
                return handler.resolve(response);
              } else {
                logger.warning('FlarumApi: WAF验证失败或取消');
              }
            } catch (err) {
              logger.error('FlarumApi: WAF验证过程中发生错误', err);
              // 验证失败或取消
            }
          }
          return handler.next(e);
        },
      ),
    );

    logger.info('FlarumApi: Dio客户端初始化完成');
  }

  /// 设置API基础URL
  ///
  /// 参数：
  /// - url: 新的基础URL
  void setBaseUrl(String url) {
    logger.info('FlarumApi: 设置基础URL - $url');
    _baseUrl = url;
    _dio.options.baseUrl = url;
    _dio.options.headers['Referer'] = url;
    _dio.options.headers['Origin'] = url;
  }

  /// 设置认证令牌
  ///
  /// 参数：
  /// - token: 新的认证令牌
  void setToken(String token) {
    logger.info('FlarumApi: 设置认证令牌');
    _token = token;
  }

  /// 清除当前认证令牌
  void clearToken() {
    logger.info('FlarumApi: 清除认证令牌');
    _token = null;
  }

  /// 获取当前认证令牌
  String? get token => _token;

  /// 获取当前API基础URL
  String? get baseUrl => _baseUrl;

  /// 保存端点到本地存储
  ///
  /// 参数：
  /// - url: 要保存的端点URL
  ///
  /// 该方法会：
  /// 1. 将端点添加到端点列表（如果不存在）
  /// 2. 将该端点设置为当前端点
  /// 3. 更新Dio客户端的基础URL
  Future<void> saveEndpoint(String url) async {
    logger.info('FlarumApi: 保存端点 - $url');
    final prefs = await SharedPreferences.getInstance();

    // 获取当前端点列表
    final endpoints = await getEndpoints();

    // 如果端点不存在，则添加到列表
    if (!endpoints.contains(url)) {
      logger.debug('FlarumApi: 端点不存在，添加到列表');
      endpoints.add(url);
      await prefs.setStringList(Constants.endpointsKey, endpoints);
    }

    // 设置为当前端点
    await prefs.setString(Constants.currentEndpointKey, url);
    setBaseUrl(url);
    logger.info('FlarumApi: 端点保存完成 - $url');
  }

  /// 从本地存储加载端点配置
  ///
  /// 该方法会：
  /// 1. 读取当前端点配置
  /// 2. 如果存在当前端点，使用该端点并加载对应的认证令牌
  /// 3. 如果不存在，使用默认端点
  Future<void> loadEndpoint() async {
    logger.info('FlarumApi: 加载端点配置');
    final prefs = await SharedPreferences.getInstance();
    final currentEndpoint = prefs.getString(Constants.currentEndpointKey);
    if (currentEndpoint != null) {
      logger.info('FlarumApi: 加载当前端点 - $currentEndpoint');
      setBaseUrl(currentEndpoint);
      // 加载当前端点的认证令牌
      await loadToken(currentEndpoint);
    } else {
      // 如果没有当前端点，则使用默认端点
      logger.info('FlarumApi: 没有当前端点，使用默认端点 - $_baseUrl');
      setBaseUrl(_baseUrl!);
    }
    logger.info('FlarumApi: 端点配置加载完成');
  }

  /// 获取所有保存的端点列表
  ///
  /// 返回值：
  /// - `Future<List<String>>`: 包含所有保存端点URL的列表
  Future<List<String>> getEndpoints() async {
    logger.debug('FlarumApi: 获取所有保存的端点');
    final prefs = await SharedPreferences.getInstance();
    final endpoints = prefs.getStringList(Constants.endpointsKey) ?? [];
    logger.debug('FlarumApi: 找到 ${endpoints.length} 个端点');
    return endpoints;
  }

  /// 切换到指定端点
  ///
  /// 参数：
  /// - url: 要切换到的端点URL
  ///
  /// 该方法会：
  /// 1. 保存当前端点的认证令牌
  /// 2. 切换到新端点
  /// 3. 加载新端点的认证令牌
  Future<void> switchEndpoint(String url) async {
    logger.info('FlarumApi: 切换到端点 - $url');
    final prefs = await SharedPreferences.getInstance();

    // 保存当前端点的令牌
    if (_baseUrl != null && _token != null) {
      logger.debug('FlarumApi: 保存当前端点的令牌 - $_baseUrl');
      await saveToken(_baseUrl!, _token!);
    }

    // 设置为当前端点
    await prefs.setString(Constants.currentEndpointKey, url);
    setBaseUrl(url);

    // 加载新端点的令牌
    logger.debug('FlarumApi: 加载新端点的令牌 - $url');
    await loadToken(url);
    logger.info('FlarumApi: 端点切换完成 - $url');
  }

  /// 删除指定端点
  ///
  /// 参数：
  /// - url: 要删除的端点URL
  ///
  /// 该方法会：
  /// 1. 从端点列表中移除指定端点
  /// 2. 如果删除的是当前端点，切换到其他端点或默认端点
  /// 3. 清除该端点的所有数据
  Future<void> deleteEndpoint(String url) async {
    final prefs = await SharedPreferences.getInstance();

    // 获取当前端点列表
    final endpoints = await getEndpoints();

    // 从列表中移除端点
    endpoints.remove(url);
    await prefs.setStringList(Constants.endpointsKey, endpoints);

    // 如果删除的是当前端点，则切换到其他端点或默认端点
    final currentEndpoint = prefs.getString(Constants.currentEndpointKey);
    if (currentEndpoint == url) {
      if (endpoints.isNotEmpty) {
        // 切换到第一个端点
        await switchEndpoint(endpoints.first);
      } else {
        // 没有其他端点，清除当前端点
        await prefs.remove(Constants.currentEndpointKey);
        setBaseUrl(_baseUrl!);
        clearToken();
      }
    }

    // 删除端点的所有数据
    await clearEndpointData(url);
  }

  /// 保存认证令牌到指定端点
  ///
  /// 参数：
  /// - endpoint: 端点URL
  /// - token: 要保存的认证令牌
  Future<void> saveToken(String endpoint, String token) async {
    final prefs = await SharedPreferences.getInstance();
    final tokenKey = _getEndpointKey(endpoint, Constants.tokenKey);
    await prefs.setString(tokenKey, token);
  }

  /// 从指定端点加载认证令牌
  ///
  /// 参数：
  /// - endpoint: 端点URL
  Future<void> loadToken(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    final tokenKey = _getEndpointKey(endpoint, Constants.tokenKey);
    final token = prefs.getString(tokenKey);
    _token = token;
  }

  /// 清除指定端点的认证令牌
  ///
  /// 参数：
  /// - endpoint: 端点URL
  Future<void> clearTokenForEndpoint(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    final tokenKey = _getEndpointKey(endpoint, Constants.tokenKey);
    await prefs.remove(tokenKey);
    if (_baseUrl == endpoint) {
      clearToken();
    }
  }

  /// 清除指定端点的所有数据
  ///
  /// 参数：
  /// - endpoint: 端点URL
  Future<void> clearEndpointData(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();

    // 获取所有与该端点相关的键
    final keys = prefs.getKeys().where((key) {
      final endpointHash = endpoint.hashCode.toString();
      return key.startsWith('${Constants.endpointDataPrefix}$endpointHash');
    }).toList();

    // 删除所有相关键
    for (final key in keys) {
      await prefs.remove(key);
    }

    // 如果是当前端点，清除内存中的令牌
    if (_baseUrl == endpoint) {
      clearToken();
    }
  }

  /// 清除所有端点数据
  ///
  /// 该方法会清除所有端点的配置和认证令牌
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();

    // 获取所有与端点相关的键
    final keys = prefs.getKeys().where((key) {
      return key.startsWith(Constants.endpointDataPrefix) ||
          key == Constants.endpointsKey ||
          key == Constants.currentEndpointKey;
    }).toList();

    // 删除所有相关键
    for (final key in keys) {
      await prefs.remove(key);
    }

    // 重置状态
    clearToken();
    setBaseUrl(_baseUrl!);
  }

  /// 发送GET请求
  ///
  /// 参数：
  /// - path: 请求路径（相对于baseUrl）
  /// - queryParameters: 查询参数
  /// - options: 请求选项
  ///
  /// 返回值：
  /// - `Future<Response>`: 包含响应数据的Response对象
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// 发送POST请求
  ///
  /// 参数：
  /// - path: 请求路径（相对于baseUrl）
  /// - data: 请求体数据
  /// - queryParameters: 查询参数
  /// - options: 请求选项
  ///
  /// 返回值：
  /// - `Future<Response>`: 包含响应数据的Response对象
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// 发送PUT请求
  ///
  /// 参数：
  /// - path: 请求路径（相对于baseUrl）
  /// - data: 请求体数据
  /// - queryParameters: 查询参数
  /// - options: 请求选项
  ///
  /// 返回值：
  /// - `Future<Response>`: 包含响应数据的Response对象
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// 发送DELETE请求
  ///
  /// 参数：
  /// - path: 请求路径（相对于baseUrl）
  /// - queryParameters: 查询参数
  /// - options: 请求选项
  ///
  /// 返回值：
  /// - `Future<Response>`: 包含响应数据的Response对象
  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// 发送PATCH请求
  ///
  /// 参数：
  /// - path: 请求路径（相对于baseUrl）
  /// - data: 请求体数据
  /// - queryParameters: 查询参数
  /// - options: 请求选项
  ///
  /// 返回值：
  /// - `Future<Response>`: 包含响应数据的Response对象
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
