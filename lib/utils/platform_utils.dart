import 'dart:io';

/// 平台工具类，提供平台相关的检查和工具方法
class PlatformUtils {
  /// 检查是否为桌面平台
  static bool get isDesktop {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// 检查是否为移动平台
  static bool get isMobile {
    return Platform.isAndroid || Platform.isIOS;
  }

  /// 检查是否为Web平台
  static bool get isWeb {
    return false; // Flutter Web 目前不在支持范围内
  }

  /// 检查是否为Windows平台
  static bool get isWindows {
    return Platform.isWindows;
  }

  /// 检查是否为macOS平台
  static bool get isMacOS {
    return Platform.isMacOS;
  }

  /// 检查是否为Linux平台
  static bool get isLinux {
    return Platform.isLinux;
  }

  /// 检查是否为Android平台
  static bool get isAndroid {
    return Platform.isAndroid;
  }

  /// 检查是否为iOS平台
  static bool get isIOS {
    return Platform.isIOS;
  }
}