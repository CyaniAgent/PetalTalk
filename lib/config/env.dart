/// 环境类型枚举
enum Environment {
  /// 开发环境
  development,

  /// 测试环境
  staging,

  /// 生产环境
  production,
}

/// 环境配置
class EnvironmentConfig {
  /// 当前环境
  static const Environment current = Environment.development;

  /// 基础URL
  static String get baseUrl {
    switch (current) {
      case Environment.development:
        return 'https://flarum.imikufans.cn';
      case Environment.staging:
        return 'https://staging.flarum.imikufans.cn';
      case Environment.production:
        return 'https://flarum.imikufans.cn';
    }
  }

  /// 是否为开发环境
  static bool get isDevelopment => current == Environment.development;

  /// 是否为测试环境
  static bool get isStaging => current == Environment.staging;

  /// 是否为生产环境
  static bool get isProduction => current == Environment.production;
}
