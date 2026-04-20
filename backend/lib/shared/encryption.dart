import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';

/// AES-256-CBC 加解密工具，用于证件号 / 手机号等敏感字段加密存储。
/// 密钥从环境变量 ENCRYPTION_KEY 注入（32 字节十六进制字符串，即 64 hex chars）。
///
/// 密文格式：base64( iv[16字节] || ciphertext )
/// 每次加密随机生成 IV，保证语义安全（相同明文产生不同密文）。
class EncryptionService {
  late final Encrypter _encrypter;

  EncryptionService(String encryptionKeyHex) {
    if (encryptionKeyHex.length < 32) {
      throw ArgumentError('ENCRYPTION_KEY 长度不足 32 字节');
    }
    // 取前 32 字节作为 AES-256 密钥
    final keyBytes = Uint8List.fromList(encryptionKeyHex.codeUnits.take(32).toList());
    _encrypter = Encrypter(AES(Key(keyBytes), mode: AESMode.cbc));
  }

  /// 加密明文字段，返回 base64 密文（写入 DB 前调用）。
  /// encrypted: AES-256-CBC，每次随机 IV，格式 base64(iv[16] || ciphertext)
  String encryptField(String plainText) {
    // 每次加密生成新的随机 IV，防止相同明文产生相同密文
    final iv = IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(plainText, iv: iv);
    // 将 IV 拼接在密文头部，一起 base64 编码
    final combined = Uint8List(16 + encrypted.bytes.length)
      ..setRange(0, 16, iv.bytes)
      ..setRange(16, 16 + encrypted.bytes.length, encrypted.bytes);
    return base64Encode(combined);
  }

  /// 解密密文，返回明文（API 响应前先脱敏，不对外直接暴露）。
  /// 支持格式：base64(iv[16] || ciphertext)
  String decryptField(String cipherTextBase64) {
    final combined = base64Decode(cipherTextBase64);
    if (combined.length <= 16) {
      throw ArgumentError('密文长度不足，数据可能已损坏');
    }
    // 前 16 字节为 IV，其余为密文
    final iv = IV(Uint8List.fromList(combined.sublist(0, 16)));
    final cipher = Encrypted(Uint8List.fromList(combined.sublist(16)));
    return _encrypter.decrypt(cipher, iv: iv);
  }

  /// 返回脱敏后4位展示值，e.g. "****1234"
  String maskField(String cipherTextBase64) {
    final plain = decryptField(cipherTextBase64);
    if (plain.length <= 4) return '****';
    return '****${plain.substring(plain.length - 4)}';
  }
}
