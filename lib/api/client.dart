/// 统一的Dio客户端封装
library;

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import '../core/logger.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  ApiClient._internal() {
    _initDio();
  }

  late Dio _dio;
  String? _token;
  String? _baseUrl = 'https://flarum.imikufans.cn';

  // 初始化Dio
  void _initDio() {
    logger.info('ApiClient: 初始化Dio客户端，baseUrl: $_baseUrl');

    // 基本请求头，无论是否使用浏览器请求头都会包含
    final basicHeaders = {
      'Accept': 'application/vnd.api+json',
      'Content-Type': 'application/vnd.api+json',
    };

    // 浏览器请求头，根据设置决定是否添加
    String userAgent =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
    if (Platform.isAndroid) {
      userAgent =
          'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';
    } else if (Platform.isIOS) {
      userAgent =
          'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1';
    }

    final browserHeaders = {
      'User-Agent': userAgent,
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
        onClientCreate: (uri, config) {
          // 移除onBadCertificate设置，使用默认值
        },
      ),
    );

    // 添加Cookie管理器
    final cookieJar = CookieJar();
    _dio.interceptors.add(CookieManager(cookieJar));

    // 添加请求日志拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          logger.debug('ApiClient: 发送请求 - ${options.method} ${options.uri}');
          if (options.data != null) {
            logger.debug('ApiClient: 请求数据 - ${options.data}');
          }
          if (_token != null) {
            options.headers['Authorization'] = 'Token $_token';
          }

          return handler.next(options);
        },

        onResponse: (response, handler) {
          logger.debug(
            'ApiClient: 收到响应 - ${response.statusCode} ${response.requestOptions.uri}',
          );
          return handler.next(response);
        },

        onError: (DioException e, handler) {
          logger.error(
            'ApiClient: 请求错误 - ${e.requestOptions.uri}',
            e,
            e.stackTrace,
          );
          return handler.next(e);
        },
      ),
    );

    logger.info('ApiClient: Dio客户端初始化完成');
  }

  // 设置基础URL
  void setBaseUrl(String url) {
    logger.info('ApiClient: 设置基础URL - $url');
    _baseUrl = url;
    _dio.options.baseUrl = url;
    _dio.options.headers['Referer'] = url;
    _dio.options.headers['Origin'] = url;
  }

  // 设置认证令牌
  void setToken(String token) {
    logger.info('ApiClient: 设置认证令牌');
    _token = token;
  }

  // 清除认证令牌
  void clearToken() {
    logger.info('ApiClient: 清除认证令牌');
    _token = null;
  }

  // 获取当前令牌
  String? get token => _token;

  // GET请求
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    logger.debug('ApiClient: 发起GET请求 - $path');
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
    logger.debug('ApiClient: 发起POST请求 - $path');
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
    logger.debug('ApiClient: 发起PUT请求 - $path');
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
    logger.debug('ApiClient: 发起DELETE请求 - $path');
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
    logger.debug('ApiClient: 发起PATCH请求 - $path');
    return await _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
