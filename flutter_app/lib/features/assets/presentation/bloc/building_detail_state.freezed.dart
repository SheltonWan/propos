// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'building_detail_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BuildingDetailState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuildingDetailState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BuildingDetailState()';
}


}

/// @nodoc
class $BuildingDetailStateCopyWith<$Res>  {
$BuildingDetailStateCopyWith(BuildingDetailState _, $Res Function(BuildingDetailState) __);
}


/// Adds pattern-matching-related methods to [BuildingDetailState].
extension BuildingDetailStatePatterns on BuildingDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( BuildingDetailStateInitial value)?  initial,TResult Function( BuildingDetailStateLoading value)?  loading,TResult Function( BuildingDetailStateLoaded value)?  loaded,TResult Function( BuildingDetailStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case BuildingDetailStateInitial() when initial != null:
return initial(_that);case BuildingDetailStateLoading() when loading != null:
return loading(_that);case BuildingDetailStateLoaded() when loaded != null:
return loaded(_that);case BuildingDetailStateError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( BuildingDetailStateInitial value)  initial,required TResult Function( BuildingDetailStateLoading value)  loading,required TResult Function( BuildingDetailStateLoaded value)  loaded,required TResult Function( BuildingDetailStateError value)  error,}){
final _that = this;
switch (_that) {
case BuildingDetailStateInitial():
return initial(_that);case BuildingDetailStateLoading():
return loading(_that);case BuildingDetailStateLoaded():
return loaded(_that);case BuildingDetailStateError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( BuildingDetailStateInitial value)?  initial,TResult? Function( BuildingDetailStateLoading value)?  loading,TResult? Function( BuildingDetailStateLoaded value)?  loaded,TResult? Function( BuildingDetailStateError value)?  error,}){
final _that = this;
switch (_that) {
case BuildingDetailStateInitial() when initial != null:
return initial(_that);case BuildingDetailStateLoading() when loading != null:
return loading(_that);case BuildingDetailStateLoaded() when loaded != null:
return loaded(_that);case BuildingDetailStateError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( Building building,  List<Floor> floors)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case BuildingDetailStateInitial() when initial != null:
return initial();case BuildingDetailStateLoading() when loading != null:
return loading();case BuildingDetailStateLoaded() when loaded != null:
return loaded(_that.building,_that.floors);case BuildingDetailStateError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( Building building,  List<Floor> floors)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case BuildingDetailStateInitial():
return initial();case BuildingDetailStateLoading():
return loading();case BuildingDetailStateLoaded():
return loaded(_that.building,_that.floors);case BuildingDetailStateError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( Building building,  List<Floor> floors)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case BuildingDetailStateInitial() when initial != null:
return initial();case BuildingDetailStateLoading() when loading != null:
return loading();case BuildingDetailStateLoaded() when loaded != null:
return loaded(_that.building,_that.floors);case BuildingDetailStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class BuildingDetailStateInitial implements BuildingDetailState {
  const BuildingDetailStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuildingDetailStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BuildingDetailState.initial()';
}


}




/// @nodoc


class BuildingDetailStateLoading implements BuildingDetailState {
  const BuildingDetailStateLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuildingDetailStateLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BuildingDetailState.loading()';
}


}




/// @nodoc


class BuildingDetailStateLoaded implements BuildingDetailState {
  const BuildingDetailStateLoaded({required this.building, required final  List<Floor> floors}): _floors = floors;
  

 final  Building building;
 final  List<Floor> _floors;
 List<Floor> get floors {
  if (_floors is EqualUnmodifiableListView) return _floors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_floors);
}


/// Create a copy of BuildingDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuildingDetailStateLoadedCopyWith<BuildingDetailStateLoaded> get copyWith => _$BuildingDetailStateLoadedCopyWithImpl<BuildingDetailStateLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuildingDetailStateLoaded&&(identical(other.building, building) || other.building == building)&&const DeepCollectionEquality().equals(other._floors, _floors));
}


@override
int get hashCode => Object.hash(runtimeType,building,const DeepCollectionEquality().hash(_floors));

@override
String toString() {
  return 'BuildingDetailState.loaded(building: $building, floors: $floors)';
}


}

/// @nodoc
abstract mixin class $BuildingDetailStateLoadedCopyWith<$Res> implements $BuildingDetailStateCopyWith<$Res> {
  factory $BuildingDetailStateLoadedCopyWith(BuildingDetailStateLoaded value, $Res Function(BuildingDetailStateLoaded) _then) = _$BuildingDetailStateLoadedCopyWithImpl;
@useResult
$Res call({
 Building building, List<Floor> floors
});


$BuildingCopyWith<$Res> get building;

}
/// @nodoc
class _$BuildingDetailStateLoadedCopyWithImpl<$Res>
    implements $BuildingDetailStateLoadedCopyWith<$Res> {
  _$BuildingDetailStateLoadedCopyWithImpl(this._self, this._then);

  final BuildingDetailStateLoaded _self;
  final $Res Function(BuildingDetailStateLoaded) _then;

/// Create a copy of BuildingDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? building = null,Object? floors = null,}) {
  return _then(BuildingDetailStateLoaded(
building: null == building ? _self.building : building // ignore: cast_nullable_to_non_nullable
as Building,floors: null == floors ? _self._floors : floors // ignore: cast_nullable_to_non_nullable
as List<Floor>,
  ));
}

/// Create a copy of BuildingDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuildingCopyWith<$Res> get building {
  
  return $BuildingCopyWith<$Res>(_self.building, (value) {
    return _then(_self.copyWith(building: value));
  });
}
}

/// @nodoc


class BuildingDetailStateError implements BuildingDetailState {
  const BuildingDetailStateError(this.message);
  

 final  String message;

/// Create a copy of BuildingDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuildingDetailStateErrorCopyWith<BuildingDetailStateError> get copyWith => _$BuildingDetailStateErrorCopyWithImpl<BuildingDetailStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuildingDetailStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'BuildingDetailState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $BuildingDetailStateErrorCopyWith<$Res> implements $BuildingDetailStateCopyWith<$Res> {
  factory $BuildingDetailStateErrorCopyWith(BuildingDetailStateError value, $Res Function(BuildingDetailStateError) _then) = _$BuildingDetailStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$BuildingDetailStateErrorCopyWithImpl<$Res>
    implements $BuildingDetailStateErrorCopyWith<$Res> {
  _$BuildingDetailStateErrorCopyWithImpl(this._self, this._then);

  final BuildingDetailStateError _self;
  final $Res Function(BuildingDetailStateError) _then;

/// Create a copy of BuildingDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(BuildingDetailStateError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
