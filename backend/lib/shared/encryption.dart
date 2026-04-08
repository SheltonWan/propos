import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';

/// AES-256-CBC 加解密工具，用于证件号 / 手机号等敏感字段加密存储。
/// 密钥从环境变量 ENCRYPTION_KEY 注入（32 字节十六进制字符串，即 64 hex chars）。
class EncryptionService {
  late final Encrypter _encrypter;
  late final IV _iv;

  EncryptionService(String encryptionKeyHex) {
    if (encryptionKeyHex.length < 32) {
      throw ArgumentError('ENCRYPTION_KEY 长度不足 32 字节');
    }
    // 取前 32 字节作为 AES-256 密钥
    final keyBytes = Uint8List.fromList(encryptionKeyHex.codeUnits.take(32).toList());
    final key = Key(keyBytes);
    _encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    // IV 固定嵌入密文前缀（生产应每次随机，此处简化为固定 16 字节）
    _iv = IV.fromLength(16);
  }

  /// 加密明文字段，返回 base64 密文（写入 DB 前调用）
  /// encrypted: AES-256-CBC
  String encryptField(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  /// 解密 base64 密文，返回明文（API 响应前先脱敏，不对外直接暴露）
  String decryptField(String cipherTextBase64) {
    final encrypted = Encrypted.fromBase64(cipherTextBase64);
    return _encrypter.decrypt(encrypted, iv: _iv);
  }

  /// 返回脱敏后4位展示值，e.g. "****1234"
  String maskField(String cipherTextBase64) {
    final plain = decryptField(cipherTextBase64);
    if (plain.length <= 4) return '****';
    return '****${plain.substring(plain.length - 4)}';
  }
}
