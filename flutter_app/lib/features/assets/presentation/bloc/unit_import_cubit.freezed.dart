// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unit_import_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UnitImportState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnitImportState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UnitImportState()';
}


}

/// @nodoc
class $UnitImportStateCopyWith<$Res>  {
$UnitImportStateCopyWith(UnitImportState _, $Res Function(UnitImportState) __);
}


/// Adds pattern-matching-related methods to [UnitImportState].
extension UnitImportStatePatterns on UnitImportState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UnitImportStateInitial value)?  initial,TResult Function( UnitImportStateUploading value)?  uploading,TResult Function( UnitImportStateSuccess value)?  success,TResult Function( UnitImportStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UnitImportStateInitial() when initial != null:
return initial(_that);case UnitImportStateUploading() when uploading != null:
return uploading(_that);case UnitImportStateSuccess() when success != null:
return success(_that);case UnitImportStateError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UnitImportStateInitial value)  initial,required TResult Function( UnitImportStateUploading value)  uploading,required TResult Function( UnitImportStateSuccess value)  success,required TResult Function( UnitImportStateError value)  error,}){
final _that = this;
switch (_that) {
case UnitImportStateInitial():
return initial(_that);case UnitImportStateUploading():
return uploading(_that);case UnitImportStateSuccess():
return success(_that);case UnitImportStateError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UnitImportStateInitial value)?  initial,TResult? Function( UnitImportStateUploading value)?  uploading,TResult? Function( UnitImportStateSuccess value)?  success,TResult? Function( UnitImportStateError value)?  error,}){
final _that = this;
switch (_that) {
case UnitImportStateInitial() when initial != null:
return initial(_that);case UnitImportStateUploading() when uploading != null:
return uploading(_that);case UnitImportStateSuccess() when success != null:
return success(_that);case UnitImportStateError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  uploading,TResult Function( int successCount,  int failedCount,  List<String> errors)?  success,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UnitImportStateInitial() when initial != null:
return initial();case UnitImportStateUploading() when uploading != null:
return uploading();case UnitImportStateSuccess() when success != null:
return success(_that.successCount,_that.failedCount,_that.errors);case UnitImportStateError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  uploading,required TResult Function( int successCount,  int failedCount,  List<String> errors)  success,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case UnitImportStateInitial():
return initial();case UnitImportStateUploading():
return uploading();case UnitImportStateSuccess():
return success(_that.successCount,_that.failedCount,_that.errors);case UnitImportStateError():
return error(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  uploading,TResult? Function( int successCount,  int failedCount,  List<String> errors)?  success,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case UnitImportStateInitial() when initial != null:
return initial();case UnitImportStateUploading() when uploading != null:
return uploading();case UnitImportStateSuccess() when success != null:
return success(_that.successCount,_that.failedCount,_that.errors);case UnitImportStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class UnitImportStateInitial implements UnitImportState {
  const UnitImportStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnitImportStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UnitImportState.initial()';
}


}




/// @nodoc


class UnitImportStateUploading implements UnitImportState {
  const UnitImportStateUploading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnitImportStateUploading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UnitImportState.uploading()';
}


}




/// @nodoc


class UnitImportStateSuccess implements UnitImportState {
  const UnitImportStateSuccess({required this.successCount, required this.failedCount, required final  List<String> errors}): _errors = errors;
  

 final  int successCount;
 final  int failedCount;
 final  List<String> _errors;
 List<String> get errors {
  if (_errors is EqualUnmodifiableListView) return _errors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_errors);
}


/// Create a copy of UnitImportState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnitImportStateSuccessCopyWith<UnitImportStateSuccess> get copyWith => _$UnitImportStateSuccessCopyWithImpl<UnitImportStateSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnitImportStateSuccess&&(identical(other.successCount, successCount) || other.successCount == successCount)&&(identical(other.failedCount, failedCount) || other.failedCount == failedCount)&&const DeepCollectionEquality().equals(other._errors, _errors));
}


@override
int get hashCode => Object.hash(runtimeType,successCount,failedCount,const DeepCollectionEquality().hash(_errors));

@override
String toString() {
  return 'UnitImportState.success(successCount: $successCount, failedCount: $failedCount, errors: $errors)';
}


}

/// @nodoc
abstract mixin class $UnitImportStateSuccessCopyWith<$Res> implements $UnitImportStateCopyWith<$Res> {
  factory $UnitImportStateSuccessCopyWith(UnitImportStateSuccess value, $Res Function(UnitImportStateSuccess) _then) = _$UnitImportStateSuccessCopyWithImpl;
@useResult
$Res call({
 int successCount, int failedCount, List<String> errors
});




}
/// @nodoc
class _$UnitImportStateSuccessCopyWithImpl<$Res>
    implements $UnitImportStateSuccessCopyWith<$Res> {
  _$UnitImportStateSuccessCopyWithImpl(this._self, this._then);

  final UnitImportStateSuccess _self;
  final $Res Function(UnitImportStateSuccess) _then;

/// Create a copy of UnitImportState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? successCount = null,Object? failedCount = null,Object? errors = null,}) {
  return _then(UnitImportStateSuccess(
successCount: null == successCount ? _self.successCount : successCount // ignore: cast_nullable_to_non_nullable
as int,failedCount: null == failedCount ? _self.failedCount : failedCount // ignore: cast_nullable_to_non_nullable
as int,errors: null == errors ? _self._errors : errors // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc


class UnitImportStateError implements UnitImportState {
  const UnitImportStateError(this.message);
  

 final  String message;

/// Create a copy of UnitImportState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnitImportStateErrorCopyWith<UnitImportStateError> get copyWith => _$UnitImportStateErrorCopyWithImpl<UnitImportStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnitImportStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'UnitImportState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $UnitImportStateErrorCopyWith<$Res> implements $UnitImportStateCopyWith<$Res> {
  factory $UnitImportStateErrorCopyWith(UnitImportStateError value, $Res Function(UnitImportStateError) _then) = _$UnitImportStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$UnitImportStateErrorCopyWithImpl<$Res>
    implements $UnitImportStateErrorCopyWith<$Res> {
  _$UnitImportStateErrorCopyWithImpl(this._self, this._then);

  final UnitImportStateError _self;
  final $Res Function(UnitImportStateError) _then;

/// Create a copy of UnitImportState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(UnitImportStateError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
