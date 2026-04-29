// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unit_detail_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UnitDetailState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnitDetailState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UnitDetailState()';
}


}

/// @nodoc
class $UnitDetailStateCopyWith<$Res>  {
$UnitDetailStateCopyWith(UnitDetailState _, $Res Function(UnitDetailState) __);
}


/// Adds pattern-matching-related methods to [UnitDetailState].
extension UnitDetailStatePatterns on UnitDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UnitDetailStateInitial value)?  initial,TResult Function( UnitDetailStateLoading value)?  loading,TResult Function( UnitDetailStateLoaded value)?  loaded,TResult Function( UnitDetailStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UnitDetailStateInitial() when initial != null:
return initial(_that);case UnitDetailStateLoading() when loading != null:
return loading(_that);case UnitDetailStateLoaded() when loaded != null:
return loaded(_that);case UnitDetailStateError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UnitDetailStateInitial value)  initial,required TResult Function( UnitDetailStateLoading value)  loading,required TResult Function( UnitDetailStateLoaded value)  loaded,required TResult Function( UnitDetailStateError value)  error,}){
final _that = this;
switch (_that) {
case UnitDetailStateInitial():
return initial(_that);case UnitDetailStateLoading():
return loading(_that);case UnitDetailStateLoaded():
return loaded(_that);case UnitDetailStateError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UnitDetailStateInitial value)?  initial,TResult? Function( UnitDetailStateLoading value)?  loading,TResult? Function( UnitDetailStateLoaded value)?  loaded,TResult? Function( UnitDetailStateError value)?  error,}){
final _that = this;
switch (_that) {
case UnitDetailStateInitial() when initial != null:
return initial(_that);case UnitDetailStateLoading() when loading != null:
return loading(_that);case UnitDetailStateLoaded() when loaded != null:
return loaded(_that);case UnitDetailStateError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( UnitDetail unit,  List<RenovationSummary> renovations)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UnitDetailStateInitial() when initial != null:
return initial();case UnitDetailStateLoading() when loading != null:
return loading();case UnitDetailStateLoaded() when loaded != null:
return loaded(_that.unit,_that.renovations);case UnitDetailStateError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( UnitDetail unit,  List<RenovationSummary> renovations)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case UnitDetailStateInitial():
return initial();case UnitDetailStateLoading():
return loading();case UnitDetailStateLoaded():
return loaded(_that.unit,_that.renovations);case UnitDetailStateError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( UnitDetail unit,  List<RenovationSummary> renovations)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case UnitDetailStateInitial() when initial != null:
return initial();case UnitDetailStateLoading() when loading != null:
return loading();case UnitDetailStateLoaded() when loaded != null:
return loaded(_that.unit,_that.renovations);case UnitDetailStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class UnitDetailStateInitial implements UnitDetailState {
  const UnitDetailStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnitDetailStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UnitDetailState.initial()';
}


}




/// @nodoc


class UnitDetailStateLoading implements UnitDetailState {
  const UnitDetailStateLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnitDetailStateLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UnitDetailState.loading()';
}


}




/// @nodoc


class UnitDetailStateLoaded implements UnitDetailState {
  const UnitDetailStateLoaded({required this.unit, required final  List<RenovationSummary> renovations}): _renovations = renovations;
  

 final  UnitDetail unit;
 final  List<RenovationSummary> _renovations;
 List<RenovationSummary> get renovations {
  if (_renovations is EqualUnmodifiableListView) return _renovations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_renovations);
}


/// Create a copy of UnitDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnitDetailStateLoadedCopyWith<UnitDetailStateLoaded> get copyWith => _$UnitDetailStateLoadedCopyWithImpl<UnitDetailStateLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnitDetailStateLoaded&&(identical(other.unit, unit) || other.unit == unit)&&const DeepCollectionEquality().equals(other._renovations, _renovations));
}


@override
int get hashCode => Object.hash(runtimeType,unit,const DeepCollectionEquality().hash(_renovations));

@override
String toString() {
  return 'UnitDetailState.loaded(unit: $unit, renovations: $renovations)';
}


}

/// @nodoc
abstract mixin class $UnitDetailStateLoadedCopyWith<$Res> implements $UnitDetailStateCopyWith<$Res> {
  factory $UnitDetailStateLoadedCopyWith(UnitDetailStateLoaded value, $Res Function(UnitDetailStateLoaded) _then) = _$UnitDetailStateLoadedCopyWithImpl;
@useResult
$Res call({
 UnitDetail unit, List<RenovationSummary> renovations
});


$UnitDetailCopyWith<$Res> get unit;

}
/// @nodoc
class _$UnitDetailStateLoadedCopyWithImpl<$Res>
    implements $UnitDetailStateLoadedCopyWith<$Res> {
  _$UnitDetailStateLoadedCopyWithImpl(this._self, this._then);

  final UnitDetailStateLoaded _self;
  final $Res Function(UnitDetailStateLoaded) _then;

/// Create a copy of UnitDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? unit = null,Object? renovations = null,}) {
  return _then(UnitDetailStateLoaded(
unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as UnitDetail,renovations: null == renovations ? _self._renovations : renovations // ignore: cast_nullable_to_non_nullable
as List<RenovationSummary>,
  ));
}

/// Create a copy of UnitDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UnitDetailCopyWith<$Res> get unit {
  
  return $UnitDetailCopyWith<$Res>(_self.unit, (value) {
    return _then(_self.copyWith(unit: value));
  });
}
}

/// @nodoc


class UnitDetailStateError implements UnitDetailState {
  const UnitDetailStateError(this.message);
  

 final  String message;

/// Create a copy of UnitDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnitDetailStateErrorCopyWith<UnitDetailStateError> get copyWith => _$UnitDetailStateErrorCopyWithImpl<UnitDetailStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnitDetailStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'UnitDetailState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $UnitDetailStateErrorCopyWith<$Res> implements $UnitDetailStateCopyWith<$Res> {
  factory $UnitDetailStateErrorCopyWith(UnitDetailStateError value, $Res Function(UnitDetailStateError) _then) = _$UnitDetailStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$UnitDetailStateErrorCopyWithImpl<$Res>
    implements $UnitDetailStateErrorCopyWith<$Res> {
  _$UnitDetailStateErrorCopyWithImpl(this._self, this._then);

  final UnitDetailStateError _self;
  final $Res Function(UnitDetailStateError) _then;

/// Create a copy of UnitDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(UnitDetailStateError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
