/// Form validators used across the app.
abstract final class Validators {
  static String? required(String? value, [String fieldName = '此项']) {
    if (value == null || value.trim().isEmpty) return '$fieldName不能为空';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return '请输入邮箱';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return '请输入有效邮箱地址';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return '请输入手机号';
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value.trim())) {
      return '请输入有效手机号';
    }
    return null;
  }

  static String? minLength(String? value, int min, [String fieldName = '此项']) {
    if (value == null || value.length < min) return '$fieldName至少 $min 个字符';
    return null;
  }
}
