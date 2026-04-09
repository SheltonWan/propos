import 'package:test/test.dart';
import 'package:propos_backend/config/app_config.dart';

void main() {
  test('缺少 DATABASE_URL 时抛出 StateError', () {
    expect(
      () => AppConfig.load(get: (_) => null),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('DATABASE_URL'),
        ),
      ),
    );
  });

  test('JWT_SECRET 不足 32 字节时抛出 StateError', () {
    expect(
      () => AppConfig.load(get: (key) => switch (key) {
            'DATABASE_URL' => 'postgres://u:p@localhost/db',
            'JWT_SECRET' => 'tooshort',
            _ => null,
          }),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('JWT_SECRET'),
        ),
      ),
    );
  });
}
