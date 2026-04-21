import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/user.dart';

part 'auth_state.freezed.dart';

/// Auth state — sealed union with 4 variants.
@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthStateInitial;
  const factory AuthState.loading() = AuthStateLoading;
  const factory AuthState.authenticated(CurrentUser user) = AuthStateAuthenticated;
  const factory AuthState.error(String message) = AuthStateError;
}
