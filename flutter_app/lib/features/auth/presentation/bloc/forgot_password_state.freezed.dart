// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'forgot_password_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ForgotPasswordState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForgotPasswordState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ForgotPasswordState()';
}


}

/// @nodoc
class $ForgotPasswordStateCopyWith<$Res>  {
$ForgotPasswordStateCopyWith(ForgotPasswordState _, $Res Function(ForgotPasswordState) __);
}


/// Adds pattern-matching-related methods to [ForgotPasswordState].
extension ForgotPasswordStatePatterns on ForgotPasswordState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ForgotPasswordStateInitial value)?  initial,TResult Function( ForgotPasswordStateLoading value)?  loading,TResult Function( ForgotPasswordStateCodeSent value)?  codeSent,TResult Function( ForgotPasswordStateSuccess value)?  success,TResult Function( ForgotPasswordStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ForgotPasswordStateInitial() when initial != null:
return initial(_that);case ForgotPasswordStateLoading() when loading != null:
return loading(_that);case ForgotPasswordStateCodeSent() when codeSent != null:
return codeSent(_that);case ForgotPasswordStateSuccess() when success != null:
return success(_that);case ForgotPasswordStateError() when error != null:
return error(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ForgotPasswordStateInitial value)  initial,required TResult Function( ForgotPasswordStateLoading value)  loading,required TResult Function( ForgotPasswordStateCodeSent value)  codeSent,required TResult Function( ForgotPasswordStateSuccess value)  success,required TResult Function( ForgotPasswordStateError value)  error,}){
final _that = this;
switch (_that) {
case ForgotPasswordStateInitial():
return initial(_that);case ForgotPasswordStateLoading():
return loading(_that);case ForgotPasswordStateCodeSent():
return codeSent(_that);case ForgotPasswordStateSuccess():
return success(_that);case ForgotPasswordStateError():
return error(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ForgotPasswordStateInitial value)?  initial,TResult? Function( ForgotPasswordStateLoading value)?  loading,TResult? Function( ForgotPasswordStateCodeSent value)?  codeSent,TResult? Function( ForgotPasswordStateSuccess value)?  success,TResult? Function( ForgotPasswordStateError value)?  error,}){
final _that = this;
switch (_that) {
case ForgotPasswordStateInitial() when initial != null:
return initial(_that);case ForgotPasswordStateLoading() when loading != null:
return loading(_that);case ForgotPasswordStateCodeSent() when codeSent != null:
return codeSent(_that);case ForgotPasswordStateSuccess() when success != null:
return success(_that);case ForgotPasswordStateError() when error != null:
return error(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( String email)?  codeSent,TResult Function()?  success,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ForgotPasswordStateInitial() when initial != null:
return initial();case ForgotPasswordStateLoading() when loading != null:
return loading();case ForgotPasswordStateCodeSent() when codeSent != null:
return codeSent(_that.email);case ForgotPasswordStateSuccess() when success != null:
return success();case ForgotPasswordStateError() when error != null:
return error(_that.message);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( String email)  codeSent,required TResult Function()  success,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case ForgotPasswordStateInitial():
return initial();case ForgotPasswordStateLoading():
return loading();case ForgotPasswordStateCodeSent():
return codeSent(_that.email);case ForgotPasswordStateSuccess():
return success();case ForgotPasswordStateError():
return error(_that.message);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( String email)?  codeSent,TResult? Function()?  success,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case ForgotPasswordStateInitial() when initial != null:
return initial();case ForgotPasswordStateLoading() when loading != null:
return loading();case ForgotPasswordStateCodeSent() when codeSent != null:
return codeSent(_that.email);case ForgotPasswordStateSuccess() when success != null:
return success();case ForgotPasswordStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class ForgotPasswordStateInitial implements ForgotPasswordState {
  const ForgotPasswordStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForgotPasswordStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ForgotPasswordState.initial()';
}


}




/// @nodoc


class ForgotPasswordStateLoading implements ForgotPasswordState {
  const ForgotPasswordStateLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForgotPasswordStateLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ForgotPasswordState.loading()';
}


}




/// @nodoc


class ForgotPasswordStateCodeSent implements ForgotPasswordState {
  const ForgotPasswordStateCodeSent(this.email);
  

 final  String email;

/// Create a copy of ForgotPasswordState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ForgotPasswordStateCodeSentCopyWith<ForgotPasswordStateCodeSent> get copyWith => _$ForgotPasswordStateCodeSentCopyWithImpl<ForgotPasswordStateCodeSent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForgotPasswordStateCodeSent&&(identical(other.email, email) || other.email == email));
}


@override
int get hashCode => Object.hash(runtimeType,email);

@override
String toString() {
  return 'ForgotPasswordState.codeSent(email: $email)';
}


}

/// @nodoc
abstract mixin class $ForgotPasswordStateCodeSentCopyWith<$Res> implements $ForgotPasswordStateCopyWith<$Res> {
  factory $ForgotPasswordStateCodeSentCopyWith(ForgotPasswordStateCodeSent value, $Res Function(ForgotPasswordStateCodeSent) _then) = _$ForgotPasswordStateCodeSentCopyWithImpl;
@useResult
$Res call({
 String email
});




}
/// @nodoc
class _$ForgotPasswordStateCodeSentCopyWithImpl<$Res>
    implements $ForgotPasswordStateCodeSentCopyWith<$Res> {
  _$ForgotPasswordStateCodeSentCopyWithImpl(this._self, this._then);

  final ForgotPasswordStateCodeSent _self;
  final $Res Function(ForgotPasswordStateCodeSent) _then;

/// Create a copy of ForgotPasswordState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? email = null,}) {
  return _then(ForgotPasswordStateCodeSent(
null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ForgotPasswordStateSuccess implements ForgotPasswordState {
  const ForgotPasswordStateSuccess();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForgotPasswordStateSuccess);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ForgotPasswordState.success()';
}


}




/// @nodoc


class ForgotPasswordStateError implements ForgotPasswordState {
  const ForgotPasswordStateError(this.message);
  

 final  String message;

/// Create a copy of ForgotPasswordState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ForgotPasswordStateErrorCopyWith<ForgotPasswordStateError> get copyWith => _$ForgotPasswordStateErrorCopyWithImpl<ForgotPasswordStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForgotPasswordStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ForgotPasswordState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $ForgotPasswordStateErrorCopyWith<$Res> implements $ForgotPasswordStateCopyWith<$Res> {
  factory $ForgotPasswordStateErrorCopyWith(ForgotPasswordStateError value, $Res Function(ForgotPasswordStateError) _then) = _$ForgotPasswordStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ForgotPasswordStateErrorCopyWithImpl<$Res>
    implements $ForgotPasswordStateErrorCopyWith<$Res> {
  _$ForgotPasswordStateErrorCopyWithImpl(this._self, this._then);

  final ForgotPasswordStateError _self;
  final $Res Function(ForgotPasswordStateError) _then;

/// Create a copy of ForgotPasswordState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ForgotPasswordStateError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
