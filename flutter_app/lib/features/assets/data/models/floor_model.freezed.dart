// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'floor_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FloorModel {

 String get id;@JsonKey(name: 'building_id') String get buildingId;@JsonKey(name: 'building_name') String get buildingName;@JsonKey(name: 'floor_number') int get floorNumber;@JsonKey(name: 'floor_name') String? get floorName;@JsonKey(name: 'svg_path') String? get svgPath;@JsonKey(name: 'png_path') String? get pngPath; double? get nla;@JsonKey(name: 'created_at') String get createdAt;@JsonKey(name: 'updated_at') String get updatedAt;
/// Create a copy of FloorModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FloorModelCopyWith<FloorModel> get copyWith => _$FloorModelCopyWithImpl<FloorModel>(this as FloorModel, _$identity);

  /// Serializes this FloorModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FloorModel&&(identical(other.id, id) || other.id == id)&&(identical(other.buildingId, buildingId) || other.buildingId == buildingId)&&(identical(other.buildingName, buildingName) || other.buildingName == buildingName)&&(identical(other.floorNumber, floorNumber) || other.floorNumber == floorNumber)&&(identical(other.floorName, floorName) || other.floorName == floorName)&&(identical(other.svgPath, svgPath) || other.svgPath == svgPath)&&(identical(other.pngPath, pngPath) || other.pngPath == pngPath)&&(identical(other.nla, nla) || other.nla == nla)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,buildingId,buildingName,floorNumber,floorName,svgPath,pngPath,nla,createdAt,updatedAt);

@override
String toString() {
  return 'FloorModel(id: $id, buildingId: $buildingId, buildingName: $buildingName, floorNumber: $floorNumber, floorName: $floorName, svgPath: $svgPath, pngPath: $pngPath, nla: $nla, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $FloorModelCopyWith<$Res>  {
  factory $FloorModelCopyWith(FloorModel value, $Res Function(FloorModel) _then) = _$FloorModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'building_id') String buildingId,@JsonKey(name: 'building_name') String buildingName,@JsonKey(name: 'floor_number') int floorNumber,@JsonKey(name: 'floor_name') String? floorName,@JsonKey(name: 'svg_path') String? svgPath,@JsonKey(name: 'png_path') String? pngPath, double? nla,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'updated_at') String updatedAt
});




}
/// @nodoc
class _$FloorModelCopyWithImpl<$Res>
    implements $FloorModelCopyWith<$Res> {
  _$FloorModelCopyWithImpl(this._self, this._then);

  final FloorModel _self;
  final $Res Function(FloorModel) _then;

/// Create a copy of FloorModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? buildingId = null,Object? buildingName = null,Object? floorNumber = null,Object? floorName = freezed,Object? svgPath = freezed,Object? pngPath = freezed,Object? nla = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,buildingId: null == buildingId ? _self.buildingId : buildingId // ignore: cast_nullable_to_non_nullable
as String,buildingName: null == buildingName ? _self.buildingName : buildingName // ignore: cast_nullable_to_non_nullable
as String,floorNumber: null == floorNumber ? _self.floorNumber : floorNumber // ignore: cast_nullable_to_non_nullable
as int,floorName: freezed == floorName ? _self.floorName : floorName // ignore: cast_nullable_to_non_nullable
as String?,svgPath: freezed == svgPath ? _self.svgPath : svgPath // ignore: cast_nullable_to_non_nullable
as String?,pngPath: freezed == pngPath ? _self.pngPath : pngPath // ignore: cast_nullable_to_non_nullable
as String?,nla: freezed == nla ? _self.nla : nla // ignore: cast_nullable_to_non_nullable
as double?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FloorModel].
extension FloorModelPatterns on FloorModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FloorModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FloorModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FloorModel value)  $default,){
final _that = this;
switch (_that) {
case _FloorModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FloorModel value)?  $default,){
final _that = this;
switch (_that) {
case _FloorModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'building_id')  String buildingId, @JsonKey(name: 'building_name')  String buildingName, @JsonKey(name: 'floor_number')  int floorNumber, @JsonKey(name: 'floor_name')  String? floorName, @JsonKey(name: 'svg_path')  String? svgPath, @JsonKey(name: 'png_path')  String? pngPath,  double? nla, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FloorModel() when $default != null:
return $default(_that.id,_that.buildingId,_that.buildingName,_that.floorNumber,_that.floorName,_that.svgPath,_that.pngPath,_that.nla,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'building_id')  String buildingId, @JsonKey(name: 'building_name')  String buildingName, @JsonKey(name: 'floor_number')  int floorNumber, @JsonKey(name: 'floor_name')  String? floorName, @JsonKey(name: 'svg_path')  String? svgPath, @JsonKey(name: 'png_path')  String? pngPath,  double? nla, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt)  $default,) {final _that = this;
switch (_that) {
case _FloorModel():
return $default(_that.id,_that.buildingId,_that.buildingName,_that.floorNumber,_that.floorName,_that.svgPath,_that.pngPath,_that.nla,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'building_id')  String buildingId, @JsonKey(name: 'building_name')  String buildingName, @JsonKey(name: 'floor_number')  int floorNumber, @JsonKey(name: 'floor_name')  String? floorName, @JsonKey(name: 'svg_path')  String? svgPath, @JsonKey(name: 'png_path')  String? pngPath,  double? nla, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _FloorModel() when $default != null:
return $default(_that.id,_that.buildingId,_that.buildingName,_that.floorNumber,_that.floorName,_that.svgPath,_that.pngPath,_that.nla,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FloorModel implements FloorModel {
  const _FloorModel({required this.id, @JsonKey(name: 'building_id') required this.buildingId, @JsonKey(name: 'building_name') required this.buildingName, @JsonKey(name: 'floor_number') required this.floorNumber, @JsonKey(name: 'floor_name') this.floorName, @JsonKey(name: 'svg_path') this.svgPath, @JsonKey(name: 'png_path') this.pngPath, this.nla, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt});
  factory _FloorModel.fromJson(Map<String, dynamic> json) => _$FloorModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'building_id') final  String buildingId;
@override@JsonKey(name: 'building_name') final  String buildingName;
@override@JsonKey(name: 'floor_number') final  int floorNumber;
@override@JsonKey(name: 'floor_name') final  String? floorName;
@override@JsonKey(name: 'svg_path') final  String? svgPath;
@override@JsonKey(name: 'png_path') final  String? pngPath;
@override final  double? nla;
@override@JsonKey(name: 'created_at') final  String createdAt;
@override@JsonKey(name: 'updated_at') final  String updatedAt;

/// Create a copy of FloorModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FloorModelCopyWith<_FloorModel> get copyWith => __$FloorModelCopyWithImpl<_FloorModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FloorModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FloorModel&&(identical(other.id, id) || other.id == id)&&(identical(other.buildingId, buildingId) || other.buildingId == buildingId)&&(identical(other.buildingName, buildingName) || other.buildingName == buildingName)&&(identical(other.floorNumber, floorNumber) || other.floorNumber == floorNumber)&&(identical(other.floorName, floorName) || other.floorName == floorName)&&(identical(other.svgPath, svgPath) || other.svgPath == svgPath)&&(identical(other.pngPath, pngPath) || other.pngPath == pngPath)&&(identical(other.nla, nla) || other.nla == nla)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,buildingId,buildingName,floorNumber,floorName,svgPath,pngPath,nla,createdAt,updatedAt);

@override
String toString() {
  return 'FloorModel(id: $id, buildingId: $buildingId, buildingName: $buildingName, floorNumber: $floorNumber, floorName: $floorName, svgPath: $svgPath, pngPath: $pngPath, nla: $nla, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$FloorModelCopyWith<$Res> implements $FloorModelCopyWith<$Res> {
  factory _$FloorModelCopyWith(_FloorModel value, $Res Function(_FloorModel) _then) = __$FloorModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'building_id') String buildingId,@JsonKey(name: 'building_name') String buildingName,@JsonKey(name: 'floor_number') int floorNumber,@JsonKey(name: 'floor_name') String? floorName,@JsonKey(name: 'svg_path') String? svgPath,@JsonKey(name: 'png_path') String? pngPath, double? nla,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'updated_at') String updatedAt
});




}
/// @nodoc
class __$FloorModelCopyWithImpl<$Res>
    implements _$FloorModelCopyWith<$Res> {
  __$FloorModelCopyWithImpl(this._self, this._then);

  final _FloorModel _self;
  final $Res Function(_FloorModel) _then;

/// Create a copy of FloorModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? buildingId = null,Object? buildingName = null,Object? floorNumber = null,Object? floorName = freezed,Object? svgPath = freezed,Object? pngPath = freezed,Object? nla = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_FloorModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,buildingId: null == buildingId ? _self.buildingId : buildingId // ignore: cast_nullable_to_non_nullable
as String,buildingName: null == buildingName ? _self.buildingName : buildingName // ignore: cast_nullable_to_non_nullable
as String,floorNumber: null == floorNumber ? _self.floorNumber : floorNumber // ignore: cast_nullable_to_non_nullable
as int,floorName: freezed == floorName ? _self.floorName : floorName // ignore: cast_nullable_to_non_nullable
as String?,svgPath: freezed == svgPath ? _self.svgPath : svgPath // ignore: cast_nullable_to_non_nullable
as String?,pngPath: freezed == pngPath ? _self.pngPath : pngPath // ignore: cast_nullable_to_non_nullable
as String?,nla: freezed == nla ? _self.nla : nla // ignore: cast_nullable_to_non_nullable
as double?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
