import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propos_app/core/api/api_exception.dart';
import 'package:propos_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:propos_app/features/auth/presentation/bloc/forgot_password_cubit.dart';
import 'package:propos_app/features/auth/presentation/bloc/forgot_password_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  // ForgotPasswordCubit 单元测试：验证两步 OTP 流程的状态流转
  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  // ── 初始状态 ──
  test('initial state is ForgotPasswordState.initial', () {
    final cubit = ForgotPasswordCubit(mockAuthRepository);
    expect(cubit.state, const ForgotPasswordState.initial());
    cubit.close();
  });

  group('ForgotPasswordCubit', () {
    // ── sendOtp ──
    // 第一步：请求向邮箱发送 OTP，防枚举设计：成功或邮箱不存在均进入 codeSent

    // 接口调用成功 → 进入 codeSent 并携带 email（供第二步使用）
    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'sendOtp emits [loading, codeSent] on success',
      build: () {
        when(() => mockAuthRepository.forgotPassword(email: any(named: 'email')))
            .thenAnswer((_) async {});
        return ForgotPasswordCubit(mockAuthRepository);
      },
      act: (cubit) => cubit.sendOtp(email: 'user@propos.com'),
      expect: () => [
        const ForgotPasswordState.loading(),
        const ForgotPasswordState.codeSent('user@propos.com'),
      ],
      verify: (_) {
        verify(() => mockAuthRepository.forgotPassword(email: 'user@propos.com'))
            .called(1);
      },
    );

    // 接口限流（429）→ 服务端 message 透传给 UI，email 不携带（停留在第一步）
    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'sendOtp emits [loading, error] with ApiException message on rate limit',
      build: () {
        when(() => mockAuthRepository.forgotPassword(email: any(named: 'email')))
            .thenThrow(const ApiException(
          code: 'RATE_LIMIT_EXCEEDED',
          message: '请求过于频繁，请稍后再试',
          statusCode: 429,
        ));
        return ForgotPasswordCubit(mockAuthRepository);
      },
      act: (cubit) => cubit.sendOtp(email: 'user@propos.com'),
      expect: () => [
        const ForgotPasswordState.loading(),
        const ForgotPasswordState.error('请求过于频繁，请稍后再试'),
      ],
    );

    // 非 ApiException（网络断连等）→ 使用固定兜底文案
    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'sendOtp emits [loading, error] with fallback message on unknown exception',
      build: () {
        when(() => mockAuthRepository.forgotPassword(email: any(named: 'email')))
            .thenThrow(Exception('network down'));
        return ForgotPasswordCubit(mockAuthRepository);
      },
      act: (cubit) => cubit.sendOtp(email: 'user@propos.com'),
      expect: () => [
        const ForgotPasswordState.loading(),
        const ForgotPasswordState.error('请求失败，请稍后再试'),
      ],
    );

    // ── resetPassword ──
    // 第二步：提交 OTP + 新密码完成重置

    // OTP 正确 → 调用 repository.resetPassword → 进入 success
    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'resetPassword emits [loading, success] on success',
      build: () {
        when(() => mockAuthRepository.resetPassword(
              email: any(named: 'email'),
              otp: any(named: 'otp'),
              newPassword: any(named: 'newPassword'),
            )).thenAnswer((_) async {});
        return ForgotPasswordCubit(mockAuthRepository);
      },
      seed: () => const ForgotPasswordState.codeSent('user@propos.com'),
      act: (cubit) => cubit.resetPassword(
        email: 'user@propos.com',
        otp: '123456',
        newPassword: 'NewPass@123',
      ),
      expect: () => [
        const ForgotPasswordState.loading(),
        const ForgotPasswordState.success(),
      ],
      verify: (_) {
        verify(() => mockAuthRepository.resetPassword(
              email: 'user@propos.com',
              otp: '123456',
              newPassword: 'NewPass@123',
            )).called(1);
      },
    );

    // OTP 错误或已过期 → 服务端 INVALID_OTP → error 状态携带 email，UI 停留在第二步
    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'resetPassword emits [loading, error(email)] when OTP is invalid',
      build: () {
        when(() => mockAuthRepository.resetPassword(
              email: any(named: 'email'),
              otp: any(named: 'otp'),
              newPassword: any(named: 'newPassword'),
            )).thenThrow(const ApiException(
          code: 'INVALID_OTP',
          message: '验证码错误或已过期',
          statusCode: 400,
        ));
        return ForgotPasswordCubit(mockAuthRepository);
      },
      seed: () => const ForgotPasswordState.codeSent('user@propos.com'),
      act: (cubit) => cubit.resetPassword(
        email: 'user@propos.com',
        otp: '000000',
        newPassword: 'NewPass@123',
      ),
      expect: () => [
        const ForgotPasswordState.loading(),
        // email 字段非 null，表示错误在第二步，UI 不退回步骤 1
        const ForgotPasswordState.error('验证码错误或已过期', email: 'user@propos.com'),
      ],
    );

    // 非 ApiException（如断网）→ 固定兜底文案，仍携带 email
    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'resetPassword emits [loading, error(email)] with fallback on unknown exception',
      build: () {
        when(() => mockAuthRepository.resetPassword(
              email: any(named: 'email'),
              otp: any(named: 'otp'),
              newPassword: any(named: 'newPassword'),
            )).thenThrow(Exception('network timeout'));
        return ForgotPasswordCubit(mockAuthRepository);
      },
      seed: () => const ForgotPasswordState.codeSent('user@propos.com'),
      act: (cubit) => cubit.resetPassword(
        email: 'user@propos.com',
        otp: '123456',
        newPassword: 'NewPass@123',
      ),
      expect: () => [
        const ForgotPasswordState.loading(),
        const ForgotPasswordState.error('操作失败，请稍后再试', email: 'user@propos.com'),
      ],
    );

    // PASSWORD_TOO_WEAK → 服务端 message 透传，UI 停留在第二步
    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'resetPassword emits [loading, error(email)] when password is too weak',
      build: () {
        when(() => mockAuthRepository.resetPassword(
              email: any(named: 'email'),
              otp: any(named: 'otp'),
              newPassword: any(named: 'newPassword'),
            )).thenThrow(const ApiException(
          code: 'PASSWORD_TOO_WEAK',
          message: '密码强度不足，需包含大写字母、数字和特殊字符',
          statusCode: 422,
        ));
        return ForgotPasswordCubit(mockAuthRepository);
      },
      seed: () => const ForgotPasswordState.codeSent('user@propos.com'),
      act: (cubit) => cubit.resetPassword(
        email: 'user@propos.com',
        otp: '654321',
        newPassword: 'weak',
      ),
      expect: () => [
        const ForgotPasswordState.loading(),
        const ForgotPasswordState.error(
          '密码强度不足，需包含大写字母、数字和特殊字符',
          email: 'user@propos.com',
        ),
      ],
    );
  });
}
