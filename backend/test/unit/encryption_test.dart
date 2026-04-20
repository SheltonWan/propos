import 'package:test/test.dart';
import 'package:propos_backend/shared/encryption.dart';

void main() {
  // 32 字节测试密钥（仅用于测试，不使用于生产）
  const testKey = 'abcdefghijklmnopqrstuvwxyz012345';
  late EncryptionService svc;

  setUp(() {
    svc = EncryptionService(testKey);
  });

  group('encryptField / decryptField', () {
    test('加密后可正确解密', () {
      const plain = '110101199003071234';
      final cipher = svc.encryptField(plain);
      expect(svc.decryptField(cipher), equals(plain));
    });

    test('相同明文每次产生不同密文（随机 IV）', () {
      const plain = '13800138000';
      final c1 = svc.encryptField(plain);
      final c2 = svc.encryptField(plain);
      // 随机 IV 保证语义安全
      expect(c1, isNot(equals(c2)));
    });

    test('不同密文均可正确解密到相同明文', () {
      const plain = '13800138000';
      final c1 = svc.encryptField(plain);
      final c2 = svc.encryptField(plain);
      expect(svc.decryptField(c1), equals(plain));
      expect(svc.decryptField(c2), equals(plain));
    });

    test('密文长度不足时 decryptField 抛出 ArgumentError', () {
      // base64('short') 解码后 < 16 字节
      expect(
        () => svc.decryptField('c2hvcnQ='),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('maskField', () {
    test('返回后4位脱敏格式', () {
      const plain = '110101199003071234';
      final cipher = svc.encryptField(plain);
      expect(svc.maskField(cipher), equals('****1234'));
    });

    test('明文不足4位时全部掩码', () {
      const plain = 'abc';
      final cipher = svc.encryptField(plain);
      expect(svc.maskField(cipher), equals('****'));
    });
  });

  group('构造函数校验', () {
    test('密钥长度不足时抛出 ArgumentError', () {
      expect(
        () => EncryptionService('tooshort'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
