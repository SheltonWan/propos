// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'asset_overview_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AssetOverviewState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssetOverviewState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AssetOverviewState()';
}


}

/// @nodoc
class $AssetOverviewStateCopyWith<$Res>  {
$AssetOverviewStateCopyWith(AssetOverviewState _, $Res Function(AssetOverviewState) __);
}


/// Adds pattern-matching-related methods to [AssetOverviewState].
extension AssetOverviewStatePatterns on AssetOverviewState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AssetOverviewStateInitial value)?  initial,TResult Function( AssetOverviewStateLoading value)?  loading,TResult Function( AssetOverviewStateLoaded value)?  loaded,TResult Function( AssetOverviewStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AssetOverviewStateInitial() when initial != null:
return initial(_that);case AssetOverviewStateLoading() when loading != null:
return loading(_that);case AssetOverviewStateLoaded() when loaded != null:
return loaded(_that);case AssetOverviewStateError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AssetOverviewStateInitial value)  initial,required TResult Function( AssetOverviewStateLoading value)  loading,required TResult Function( AssetOverviewStateLoaded value)  loaded,required TResult Function( AssetOverviewStateError value)  error,}){
final _that = this;
switch (_that) {
case AssetOverviewStateInitial():
return initial(_that);case AssetOverviewStateLoading():
return loading(_that);case AssetOverviewStateLoaded():
return loaded(_that);case AssetOverviewStateError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AssetOverviewStateInitial value)?  initial,TResult? Function( AssetOverviewStateLoading value)?  loading,TResult? Function( AssetOverviewStateLoaded value)?  loaded,TResult? Function( AssetOverviewStateError value)?  error,}){
final _that = this;
switch (_that) {
case AssetOverviewStateInitial() when initial != null:
return initial(_that);case AssetOverviewStateLoading() when loading != null:
return loading(_that);case AssetOverviewStateLoaded() when loaded != null:
return loaded(_that);case AssetOverviewStateError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( AssetOverview overview,  List<Building> buildings)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AssetOverviewStateInitial() when initial != null:
return initial();case AssetOverviewStateLoading() when loading != null:
return loading();case AssetOverviewStateLoaded() when loaded != null:
return loaded(_that.overview,_that.buildings);case AssetOverviewStateError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( AssetOverview overview,  List<Building> buildings)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case AssetOverviewStateInitial():
return initial();case AssetOverviewStateLoading():
return loading();case AssetOverviewStateLoaded():
return loaded(_that.overview,_that.buildings);case AssetOverviewStateError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( AssetOverview overview,  List<Building> buildings)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case AssetOverviewStateInitial() when initial != null:
return initial();case AssetOverviewStateLoading() when loading != null:
return loading();case AssetOverviewStateLoaded() when loaded != null:
return loaded(_that.overview,_that.buildings);case AssetOverviewStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class AssetOverviewStateInitial implements AssetOverviewState {
  const AssetOverviewStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssetOverviewStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AssetOverviewState.initial()';
}


}




/// @nodoc


class AssetOverviewStateLoading implements AssetOverviewState {
  const AssetOverviewStateLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssetOverviewStateLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AssetOverviewState.loading()';
}


}




/// @nodoc


class AssetOverviewStateLoaded implements AssetOverviewState {
  const AssetOverviewStateLoaded({required this.overview, required final  List<Building> buildings}): _buildings = buildings;
  

 final  AssetOverview overview;
 final  List<Building> _buildings;
 List<Building> get buildings {
  if (_buildings is EqualUnmodifiableListView) return _buildings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_buildings);
}


/// Create a copy of AssetOverviewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssetOverviewStateLoadedCopyWith<AssetOverviewStateLoaded> get copyWith => _$AssetOverviewStateLoadedCopyWithImpl<AssetOverviewStateLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssetOverviewStateLoaded&&(identical(other.overview, overview) || other.overview == overview)&&const DeepCollectionEquality().equals(other._buildings, _buildings));
}


@override
int get hashCode => Object.hash(runtimeType,overview,const DeepCollectionEquality().hash(_buildings));

@override
String toString() {
  return 'AssetOverviewState.loaded(overview: $overview, buildings: $buildings)';
}


}

/// @nodoc
abstract mixin class $AssetOverviewStateLoadedCopyWith<$Res> implements $AssetOverviewStateCopyWith<$Res> {
  factory $AssetOverviewStateLoadedCopyWith(AssetOverviewStateLoaded value, $Res Function(AssetOverviewStateLoaded) _then) = _$AssetOverviewStateLoadedCopyWithImpl;
@useResult
$Res call({
 AssetOverview overview, List<Building> buildings
});


$AssetOverviewCopyWith<$Res> get overview;

}
/// @nodoc
class _$AssetOverviewStateLoadedCopyWithImpl<$Res>
    implements $AssetOverviewStateLoadedCopyWith<$Res> {
  _$AssetOverviewStateLoadedCopyWithImpl(this._self, this._then);

  final AssetOverviewStateLoaded _self;
  final $Res Function(AssetOverviewStateLoaded) _then;

/// Create a copy of AssetOverviewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? overview = null,Object? buildings = null,}) {
  return _then(AssetOverviewStateLoaded(
overview: null == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as AssetOverview,buildings: null == buildings ? _self._buildings : buildings // ignore: cast_nullable_to_non_nullable
as List<Building>,
  ));
}

/// Create a copy of AssetOverviewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AssetOverviewCopyWith<$Res> get overview {
  
  return $AssetOverviewCopyWith<$Res>(_self.overview, (value) {
    return _then(_self.copyWith(overview: value));
  });
}
}

/// @nodoc


class AssetOverviewStateError implements AssetOverviewState {
  const AssetOverviewStateError(this.message);
  

 final  String message;

/// Create a copy of AssetOverviewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssetOverviewStateErrorCopyWith<AssetOverviewStateError> get copyWith => _$AssetOverviewStateErrorCopyWithImpl<AssetOverviewStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssetOverviewStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AssetOverviewState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $AssetOverviewStateErrorCopyWith<$Res> implements $AssetOverviewStateCopyWith<$Res> {
  factory $AssetOverviewStateErrorCopyWith(AssetOverviewStateError value, $Res Function(AssetOverviewStateError) _then) = _$AssetOverviewStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$AssetOverviewStateErrorCopyWithImpl<$Res>
    implements $AssetOverviewStateErrorCopyWith<$Res> {
  _$AssetOverviewStateErrorCopyWithImpl(this._self, this._then);

  final AssetOverviewStateError _self;
  final $Res Function(AssetOverviewStateError) _then;

/// Create a copy of AssetOverviewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(AssetOverviewStateError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
