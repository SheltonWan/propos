/// 敏感字段脱敏工具。
///
/// 所有日志输出前调用，确保证件号、手机号、Token、密码等
/// 敏感信息不进入任何日志通道。
/// 禁止在业务层直接实例化，统一由 [AppLogger] 内部调用。
abstract final class LoggingFilter {
  /// 脱敏 Authorization header 值，仅保留类型前缀。
  ///
  /// 示例：`Bearer eyJhbGciOiJIUzI1Ni...` → `Bearer eyJ[REDACTED]`
  static String maskToken(String? token) {
    if (token == null || token.isEmpty) return '';
    const prefix = 'Bearer ';
    if (token.startsWith(prefix)) {
      return '${prefix}eyJ[REDACTED]';
    }
    return '[REDACTED]';
  }

  /// 脱敏请求 headers Map，替换 Authorization 字段内容。
  static Map<String, dynamic> maskHeaders(Map<String, dynamic> headers) {
    final result = Map<String, dynamic>.from(headers);
    if (result.containsKey('Authorization')) {
      result['Authorization'] = maskToken(result['Authorization'] as String?);
    }
    return result;
  }

  /// 递归脱敏 Map 中的已知敏感字段。
  ///
  /// 覆盖：password、id_number、phone、mobile、cert_no、
  ///        id_card、bank_card、encryption_key。
  static Map<String, dynamic> maskSensitiveFields(Map<String, dynamic> data) {
    const sensitiveKeys = {
      'password',
      'id_number',
      'phone',
      'mobile',
      'cert_no',
      'id_card',
      'bank_card',
      'encryption_key',
    };
    return data.map((key, value) {
      if (sensitiveKeys.contains(key)) return MapEntry(key, '[REDACTED]');
      if (value is Map<String, dynamic>) {
        return MapEntry(key, maskSensitiveFields(value));
      }
      return MapEntry(key, value);
    });
  }
}
