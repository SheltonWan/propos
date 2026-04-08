import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// 平台能力检测工具
class PlatformUtils {
  PlatformUtils._();

  static bool get isWeb => kIsWeb;
  static bool get isMobile =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);
  static bool get isDesktop =>
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// 是否支持相机扫码（移动端）
  static bool get supportsCameraScanner => isMobile;

  /// 是否支持推送通知（移动端）
  static bool get supportsPushNotifications => isMobile;
}
