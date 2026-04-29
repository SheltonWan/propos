// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'floor_map_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FloorMapState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FloorMapState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FloorMapState()';
}


}

/// @nodoc
class $FloorMapStateCopyWith<$Res>  {
$FloorMapStateCopyWith(FloorMapState _, $Res Function(FloorMapState) __);
}


/// Adds pattern-matching-related methods to [FloorMapState].
extension FloorMapStatePatterns on FloorMapState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( FloorMapStateInitial value)?  initial,TResult Function( FloorMapStateLoading value)?  loading,TResult Function( FloorMapStateLoaded value)?  loaded,TResult Function( FloorMapStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case FloorMapStateInitial() when initial != null:
return initial(_that);case FloorMapStateLoading() when loading != null:
return loading(_that);case FloorMapStateLoaded() when loaded != null:
return loaded(_that);case FloorMapStateError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( FloorMapStateInitial value)  initial,required TResult Function( FloorMapStateLoading value)  loading,required TResult Function( FloorMapStateLoaded value)  loaded,required TResult Function( FloorMapStateError value)  error,}){
final _that = this;
switch (_that) {
case FloorMapStateInitial():
return initial(_that);case FloorMapStateLoading():
return loading(_that);case FloorMapStateLoaded():
return loaded(_that);case FloorMapStateError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( FloorMapStateInitial value)?  initial,TResult? Function( FloorMapStateLoading value)?  loading,TResult? Function( FloorMapStateLoaded value)?  loaded,TResult? Function( FloorMapStateError value)?  error,}){
final _that = this;
switch (_that) {
case FloorMapStateInitial() when initial != null:
return initial(_that);case FloorMapStateLoading() when loading != null:
return loading(_that);case FloorMapStateLoaded() when loaded != null:
return loaded(_that);case FloorMapStateError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( Floor floor,  FloorHeatmap heatmap)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case FloorMapStateInitial() when initial != null:
return initial();case FloorMapStateLoading() when loading != null:
return loading();case FloorMapStateLoaded() when loaded != null:
return loaded(_that.floor,_that.heatmap);case FloorMapStateError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( Floor floor,  FloorHeatmap heatmap)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case FloorMapStateInitial():
return initial();case FloorMapStateLoading():
return loading();case FloorMapStateLoaded():
return loaded(_that.floor,_that.heatmap);case FloorMapStateError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( Floor floor,  FloorHeatmap heatmap)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case FloorMapStateInitial() when initial != null:
return initial();case FloorMapStateLoading() when loading != null:
return loading();case FloorMapStateLoaded() when loaded != null:
return loaded(_that.floor,_that.heatmap);case FloorMapStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class FloorMapStateInitial implements FloorMapState {
  const FloorMapStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FloorMapStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FloorMapState.initial()';
}


}




/// @nodoc


class FloorMapStateLoading implements FloorMapState {
  const FloorMapStateLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FloorMapStateLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FloorMapState.loading()';
}


}




/// @nodoc


class FloorMapStateLoaded implements FloorMapState {
  const FloorMapStateLoaded({required this.floor, required this.heatmap});
  

 final  Floor floor;
 final  FloorHeatmap heatmap;

/// Create a copy of FloorMapState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FloorMapStateLoadedCopyWith<FloorMapStateLoaded> get copyWith => _$FloorMapStateLoadedCopyWithImpl<FloorMapStateLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FloorMapStateLoaded&&const DeepCollectionEquality().equals(other.floor, floor)&&const DeepCollectionEquality().equals(other.heatmap, heatmap));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(floor),const DeepCollectionEquality().hash(heatmap));

@override
String toString() {
  return 'FloorMapState.loaded(floor: $floor, heatmap: $heatmap)';
}


}

/// @nodoc
abstract mixin class $FloorMapStateLoadedCopyWith<$Res> implements $FloorMapStateCopyWith<$Res> {
  factory $FloorMapStateLoadedCopyWith(FloorMapStateLoaded value, $Res Function(FloorMapStateLoaded) _then) = _$FloorMapStateLoadedCopyWithImpl;
@useResult
$Res call({
 Floor floor, FloorHeatmap heatmap
});




}
/// @nodoc
class _$FloorMapStateLoadedCopyWithImpl<$Res>
    implements $FloorMapStateLoadedCopyWith<$Res> {
  _$FloorMapStateLoadedCopyWithImpl(this._self, this._then);

  final FloorMapStateLoaded _self;
  final $Res Function(FloorMapStateLoaded) _then;

/// Create a copy of FloorMapState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? floor = freezed,Object? heatmap = freezed,}) {
  return _then(FloorMapStateLoaded(
floor: freezed == floor ? _self.floor : floor // ignore: cast_nullable_to_non_nullable
as Floor,heatmap: freezed == heatmap ? _self.heatmap : heatmap // ignore: cast_nullable_to_non_nullable
as FloorHeatmap,
  ));
}


}

/// @nodoc


class FloorMapStateError implements FloorMapState {
  const FloorMapStateError(this.message);
  

 final  String message;

/// Create a copy of FloorMapState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FloorMapStateErrorCopyWith<FloorMapStateError> get copyWith => _$FloorMapStateErrorCopyWithImpl<FloorMapStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FloorMapStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'FloorMapState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $FloorMapStateErrorCopyWith<$Res> implements $FloorMapStateCopyWith<$Res> {
  factory $FloorMapStateErrorCopyWith(FloorMapStateError value, $Res Function(FloorMapStateError) _then) = _$FloorMapStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$FloorMapStateErrorCopyWithImpl<$Res>
    implements $FloorMapStateErrorCopyWith<$Res> {
  _$FloorMapStateErrorCopyWithImpl(this._self, this._then);

  final FloorMapStateError _self;
  final $Res Function(FloorMapStateError) _then;

/// Create a copy of FloorMapState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(FloorMapStateError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
