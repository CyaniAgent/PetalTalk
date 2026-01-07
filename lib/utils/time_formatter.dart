/// 时间格式化工具类，提供时间格式转换功能
library;

/// 时间格式化工具，用于将ISO时间格式转换为用户友好的本地时间格式
class TimeFormatter {
  /// 将ISO时间格式转换为用户本地时间格式
  ///
  /// 参数：
  /// - isoTime: ISO 8601格式的时间字符串（如'2023-01-01T12:00:00Z'）
  ///
  /// 返回值：
  /// - String: 格式化后的本地时间字符串
  ///   - 如果是今天：显示"小时:分钟"（如"14:30"）
  ///   - 如果是昨天：显示"昨天 小时:分钟"（如"昨天 14:30"）
  ///   - 如果是今年：显示"月-日 小时:分钟"（如"1-1 14:30"）
  ///   - 其他情况：显示"年-月-日 小时:分钟"（如"2023-1-1 14:30"）
  static String formatLocalTime(String isoTime) {
    try {
      final DateTime utcTime = DateTime.parse(isoTime);
      final DateTime localTime = utcTime.toLocal();

      // 获取当前时间
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(localTime);

      // 如果是今天发布的，显示时间（小时:分钟）
      if (localTime.day == now.day &&
          localTime.month == now.month &&
          localTime.year == now.year) {
        return localTime.formatTime();
      }

      // 如果是昨天发布的，显示"昨天 时间"
      if (difference.inDays == 1) {
        return "昨天 ${localTime.formatTime()}";
      }

      // 如果是今年发布的，显示"月-日 时间"
      if (localTime.year == now.year) {
        return "${localTime.month}-${localTime.day} ${localTime.formatTime()}";
      }

      // 其他情况，显示"年-月-日 时间"
      return "${localTime.year}-${localTime.month}-${localTime.day} ${localTime.formatTime()}";
    } catch (e) {
      return isoTime;
    }
  }
}

/// DateTime扩展，添加格式化时间的方法
extension DateTimeExtension on DateTime {
  /// 将DateTime转换为"小时:分钟"格式的字符串
  ///
  /// 返回值：
  /// - String: 格式化后的时间字符串（如"14:30"）
  String formatTime() {
    String hour = this.hour.toString().padLeft(2, '0');
    String minute = this.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }
}
