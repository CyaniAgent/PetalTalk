import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';

class FlarumApi {
  static final FlarumApi _instance = FlarumApi._internal();
  factory FlarumApi() => _instance;

  FlarumApi._internal() {
    _initDio();
  }

  late Dio _dio;
  String? _token;
  String? _baseUrl = 'https://flarum.imikufans.cn';

  // 为特定端点生成唯一的存储键
  String _getEndpointKey(String endpoint, String key) {
    // 使用端点的哈希值作为唯一标识，确保不同端点的数据隔离
    final endpointHash = endpoint.hashCode.toString();
    return '${Constants.endpointDataPrefix}$endpointHash\_$key';
  }

  // 初始化Dio
  void _initDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl!,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/vnd.api+json',
          'Content-Type': 'application/vnd.api+json',
        },
      ),
    );

    // 添加HTTP/2适配器
    _dio.httpClientAdapter = Http2Adapter(
      ConnectionManager(
        idleTimeout: const Duration(seconds: 10),
        onClientCreate: (uri, config) {
          // 移除onBadCertificate设置，使用默认值
        },
      ),
    );

    // 添加Cookie管理器
    final cookieJar = CookieJar();
    _dio.interceptors.add(CookieManager(cookieJar));

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
  }

  // 设置基础URL
  void setBaseUrl(String url) {
    _baseUrl = url;
    _dio.options.baseUrl = url;
  }

  // 设置认证令牌
  void setToken(String token) {
    _token = token;
  }

  // 清除认证令牌
  void clearToken() {
    _token = null;
  }

  // 获取当前令牌
  String? get token => _token;

  // 获取当前基础URL
  String? get baseUrl => _baseUrl;

  // 保存端点到本地存储
  Future<void> saveEndpoint(String url) async {
    final prefs = await SharedPreferences.getInstance();

    // 获取当前端点列表
    final endpoints = await getEndpoints();

    // 如果端点不存在，则添加到列表
    if (!endpoints.contains(url)) {
      endpoints.add(url);
      await prefs.setStringList(Constants.endpointsKey, endpoints);
    }

    // 设置为当前端点
    await prefs.setString(Constants.currentEndpointKey, url);
    setBaseUrl(url);
  }

  // 从本地存储加载端点
  Future<void> loadEndpoint() async {
    final prefs = await SharedPreferences.getInstance();
    final currentEndpoint = prefs.getString(Constants.currentEndpointKey);
    if (currentEndpoint != null) {
      setBaseUrl(currentEndpoint);
      // 加载当前端点的认证令牌
      await loadToken(currentEndpoint);
    } else {
      // 如果没有当前端点，则使用默认端点
      setBaseUrl(_baseUrl!);
    }
  }

  // 获取所有保存的端点
  Future<List<String>> getEndpoints() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(Constants.endpointsKey) ?? [];
  }

  // 切换到指定端点
  Future<void> switchEndpoint(String url) async {
    final prefs = await SharedPreferences.getInstance();

    // 保存当前端点的令牌
    if (_baseUrl != null && _token != null) {
      await saveToken(_baseUrl!, _token!);
    }

    // 设置为当前端点
    await prefs.setString(Constants.currentEndpointKey, url);
    setBaseUrl(url);

    // 加载新端点的令牌
    await loadToken(url);
  }

  // 删除指定端点
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

  // 保存认证令牌到指定端点
  Future<void> saveToken(String endpoint, String token) async {
    final prefs = await SharedPreferences.getInstance();
    final tokenKey = _getEndpointKey(endpoint, Constants.tokenKey);
    await prefs.setString(tokenKey, token);
  }

  // 从指定端点加载认证令牌
  Future<void> loadToken(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    final tokenKey = _getEndpointKey(endpoint, Constants.tokenKey);
    final token = prefs.getString(tokenKey);
    _token = token;
  }

  // 清除指定端点的认证令牌
  Future<void> clearTokenForEndpoint(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    final tokenKey = _getEndpointKey(endpoint, Constants.tokenKey);
    await prefs.remove(tokenKey);
    if (_baseUrl == endpoint) {
      clearToken();
    }
  }

  // 清除指定端点的所有数据
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

  // 清除所有端点数据
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

  // GET请求
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

  // POST请求
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

  // PUT请求
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

  // DELETE请求
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

  // PATCH请求
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
