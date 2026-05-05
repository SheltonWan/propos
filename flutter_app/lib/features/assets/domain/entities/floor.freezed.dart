// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'floor.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Floor {

 String get id; String get buildingId; String get buildingName; int get floorNumber; String? get floorName;/// 楼层业态（001 新增）：office / retail / apartment；
/// 混合体楼栋需逐层指定，非混合体楼栋自动继承楼栋业态；
/// null 代表「待定」
 String? get propertyType; String? get svgPath; String? get pngPath; double? get nla; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of Floor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FloorCopyWith<Floor> get copyWith => _$FloorCopyWithImpl<Floor>(this as Floor, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Floor&&(identical(other.id, id) || other.id == id)&&(identical(other.buildingId, buildingId) || other.buildingId == buildingId)&&(identical(other.buildingName, buildingName) || other.buildingName == buildingName)&&(identical(other.floorNumber, floorNumber) || other.floorNumber == floorNumber)&&(identical(other.floorName, floorName) || other.floorName == floorName)&&(identical(other.propertyType, propertyType) || other.propertyType == propertyType)&&(identical(other.svgPath, svgPath) || other.svgPath == svgPath)&&(identical(other.pngPath, pngPath) || other.pngPath == pngPath)&&(identical(other.nla, nla) || other.nla == nla)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,buildingId,buildingName,floorNumber,floorName,propertyType,svgPath,pngPath,nla,createdAt,updatedAt);

@override
String toString() {
  return 'Floor(id: $id, buildingId: $buildingId, buildingName: $buildingName, floorNumber: $floorNumber, floorName: $floorName, propertyType: $propertyType, svgPath: $svgPath, pngPath: $pngPath, nla: $nla, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $FloorCopyWith<$Res>  {
  factory $FloorCopyWith(Floor value, $Res Function(Floor) _then) = _$FloorCopyWithImpl;
@useResult
$Res call({
 String id, String buildingId, String buildingName, int floorNumber, String? floorName, String? propertyType, String? svgPath, String? pngPath, double? nla, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$FloorCopyWithImpl<$Res>
    implements $FloorCopyWith<$Res> {
  _$FloorCopyWithImpl(this._self, this._then);

  final Floor _self;
  final $Res Function(Floor) _then;

/// Create a copy of Floor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? buildingId = null,Object? buildingName = null,Object? floorNumber = null,Object? floorName = freezed,Object? propertyType = freezed,Object? svgPath = freezed,Object? pngPath = freezed,Object? nla = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,buildingId: null == buildingId ? _self.buildingId : buildingId // ignore: cast_nullable_to_non_nullable
as String,buildingName: null == buildingName ? _self.buildingName : buildingName // ignore: cast_nullable_to_non_nullable
as String,floorNumber: null == floorNumber ? _self.floorNumber : floorNumber // ignore: cast_nullable_to_non_nullable
as int,floorName: freezed == floorName ? _self.floorName : floorName // ignore: cast_nullable_to_non_nullable
as String?,propertyType: freezed == propertyType ? _self.propertyType : propertyType // ignore: cast_nullable_to_non_nullable
as String?,svgPath: freezed == svgPath ? _self.svgPath : svgPath // ignore: cast_nullable_to_non_nullable
as String?,pngPath: freezed == pngPath ? _self.pngPath : pngPath // ignore: cast_nullable_to_non_nullable
as String?,nla: freezed == nla ? _self.nla : nla // ignore: cast_nullable_to_non_nullable
as double?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Floor].
extension FloorPatterns on Floor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Floor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Floor() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Floor value)  $default,){
final _that = this;
switch (_that) {
case _Floor():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Floor value)?  $default,){
final _that = this;
switch (_that) {
case _Floor() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String buildingId,  String buildingName,  int floorNumber,  String? floorName,  String? propertyType,  String? svgPath,  String? pngPath,  double? nla,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Floor() when $default != null:
return $default(_that.id,_that.buildingId,_that.buildingName,_that.floorNumber,_that.floorName,_that.propertyType,_that.svgPath,_that.pngPath,_that.nla,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String buildingId,  String buildingName,  int floorNumber,  String? floorName,  String? propertyType,  String? svgPath,  String? pngPath,  double? nla,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Floor():
return $default(_that.id,_that.buildingId,_that.buildingName,_that.floorNumber,_that.floorName,_that.propertyType,_that.svgPath,_that.pngPath,_that.nla,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String buildingId,  String buildingName,  int floorNumber,  String? floorName,  String? propertyType,  String? svgPath,  String? pngPath,  double? nla,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Floor() when $default != null:
return $default(_that.id,_that.buildingId,_that.buildingName,_that.floorNumber,_that.floorName,_that.propertyType,_that.svgPath,_that.pngPath,_that.nla,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Floor extends Floor {
  const _Floor({required this.id, required this.buildingId, required this.buildingName, required this.floorNumber, this.floorName, this.propertyType, this.svgPath, this.pngPath, this.nla, required this.createdAt, required this.updatedAt}): super._();
  

@override final  String id;
@override final  String buildingId;
@override final  String buildingName;
@override final  int floorNumber;
@override final  String? floorName;
/// 楼层业态（001 新增）：office / retail / apartment；
/// 混合体楼栋需逐层指定，非混合体楼栋自动继承楼栋业态；
/// null 代表「待定」
@override final  String? propertyType;
@override final  String? svgPath;
@override final  String? pngPath;
@override final  double? nla;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of Floor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FloorCopyWith<_Floor> get copyWith => __$FloorCopyWithImpl<_Floor>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Floor&&(identical(other.id, id) || other.id == id)&&(identical(other.buildingId, buildingId) || other.buildingId == buildingId)&&(identical(other.buildingName, buildingName) || other.buildingName == buildingName)&&(identical(other.floorNumber, floorNumber) || other.floorNumber == floorNumber)&&(identical(other.floorName, floorName) || other.floorName == floorName)&&(identical(other.propertyType, propertyType) || other.propertyType == propertyType)&&(identical(other.svgPath, svgPath) || other.svgPath == svgPath)&&(identical(other.pngPath, pngPath) || other.pngPath == pngPath)&&(identical(other.nla, nla) || other.nla == nla)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,buildingId,buildingName,floorNumber,floorName,propertyType,svgPath,pngPath,nla,createdAt,updatedAt);

@override
String toString() {
  return 'Floor(id: $id, buildingId: $buildingId, buildingName: $buildingName, floorNumber: $floorNumber, floorName: $floorName, propertyType: $propertyType, svgPath: $svgPath, pngPath: $pngPath, nla: $nla, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$FloorCopyWith<$Res> implements $FloorCopyWith<$Res> {
  factory _$FloorCopyWith(_Floor value, $Res Function(_Floor) _then) = __$FloorCopyWithImpl;
@override @useResult
$Res call({
 String id, String buildingId, String buildingName, int floorNumber, String? floorName, String? propertyType, String? svgPath, String? pngPath, double? nla, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$FloorCopyWithImpl<$Res>
    implements _$FloorCopyWith<$Res> {
  __$FloorCopyWithImpl(this._self, this._then);

  final _Floor _self;
  final $Res Function(_Floor) _then;

/// Create a copy of Floor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? buildingId = null,Object? buildingName = null,Object? floorNumber = null,Object? floorName = freezed,Object? propertyType = freezed,Object? svgPath = freezed,Object? pngPath = freezed,Object? nla = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Floor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,buildingId: null == buildingId ? _self.buildingId : buildingId // ignore: cast_nullable_to_non_nullable
as String,buildingName: null == buildingName ? _self.buildingName : buildingName // ignore: cast_nullable_to_non_nullable
as String,floorNumber: null == floorNumber ? _self.floorNumber : floorNumber // ignore: cast_nullable_to_non_nullable
as int,floorName: freezed == floorName ? _self.floorName : floorName // ignore: cast_nullable_to_non_nullable
as String?,propertyType: freezed == propertyType ? _self.propertyType : propertyType // ignore: cast_nullable_to_non_nullable
as String?,svgPath: freezed == svgPath ? _self.svgPath : svgPath // ignore: cast_nullable_to_non_nullable
as String?,pngPath: freezed == pngPath ? _self.pngPath : pngPath // ignore: cast_nullable_to_non_nullable
as String?,nla: freezed == nla ? _self.nla : nla // ignore: cast_nullable_to_non_nullable
as double?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
