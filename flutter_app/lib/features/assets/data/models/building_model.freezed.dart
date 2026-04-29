// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'building_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuildingModel {

 String get id; String get name;@JsonKey(name: 'property_type') String get propertyType;@JsonKey(name: 'total_floors') int get totalFloors;@JsonKey(name: 'basement_floors') int get basementFloors; double get gfa; double get nla; String? get address;@JsonKey(name: 'built_year') int? get builtYear;@JsonKey(name: 'created_at') String get createdAt;@JsonKey(name: 'updated_at') String get updatedAt;
/// Create a copy of BuildingModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuildingModelCopyWith<BuildingModel> get copyWith => _$BuildingModelCopyWithImpl<BuildingModel>(this as BuildingModel, _$identity);

  /// Serializes this BuildingModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuildingModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.propertyType, propertyType) || other.propertyType == propertyType)&&(identical(other.totalFloors, totalFloors) || other.totalFloors == totalFloors)&&(identical(other.basementFloors, basementFloors) || other.basementFloors == basementFloors)&&(identical(other.gfa, gfa) || other.gfa == gfa)&&(identical(other.nla, nla) || other.nla == nla)&&(identical(other.address, address) || other.address == address)&&(identical(other.builtYear, builtYear) || other.builtYear == builtYear)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,propertyType,totalFloors,basementFloors,gfa,nla,address,builtYear,createdAt,updatedAt);

@override
String toString() {
  return 'BuildingModel(id: $id, name: $name, propertyType: $propertyType, totalFloors: $totalFloors, basementFloors: $basementFloors, gfa: $gfa, nla: $nla, address: $address, builtYear: $builtYear, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $BuildingModelCopyWith<$Res>  {
  factory $BuildingModelCopyWith(BuildingModel value, $Res Function(BuildingModel) _then) = _$BuildingModelCopyWithImpl;
@useResult
$Res call({
 String id, String name,@JsonKey(name: 'property_type') String propertyType,@JsonKey(name: 'total_floors') int totalFloors,@JsonKey(name: 'basement_floors') int basementFloors, double gfa, double nla, String? address,@JsonKey(name: 'built_year') int? builtYear,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'updated_at') String updatedAt
});




}
/// @nodoc
class _$BuildingModelCopyWithImpl<$Res>
    implements $BuildingModelCopyWith<$Res> {
  _$BuildingModelCopyWithImpl(this._self, this._then);

  final BuildingModel _self;
  final $Res Function(BuildingModel) _then;

/// Create a copy of BuildingModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? propertyType = null,Object? totalFloors = null,Object? basementFloors = null,Object? gfa = null,Object? nla = null,Object? address = freezed,Object? builtYear = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,propertyType: null == propertyType ? _self.propertyType : propertyType // ignore: cast_nullable_to_non_nullable
as String,totalFloors: null == totalFloors ? _self.totalFloors : totalFloors // ignore: cast_nullable_to_non_nullable
as int,basementFloors: null == basementFloors ? _self.basementFloors : basementFloors // ignore: cast_nullable_to_non_nullable
as int,gfa: null == gfa ? _self.gfa : gfa // ignore: cast_nullable_to_non_nullable
as double,nla: null == nla ? _self.nla : nla // ignore: cast_nullable_to_non_nullable
as double,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,builtYear: freezed == builtYear ? _self.builtYear : builtYear // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BuildingModel].
extension BuildingModelPatterns on BuildingModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuildingModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuildingModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuildingModel value)  $default,){
final _that = this;
switch (_that) {
case _BuildingModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuildingModel value)?  $default,){
final _that = this;
switch (_that) {
case _BuildingModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'property_type')  String propertyType, @JsonKey(name: 'total_floors')  int totalFloors, @JsonKey(name: 'basement_floors')  int basementFloors,  double gfa,  double nla,  String? address, @JsonKey(name: 'built_year')  int? builtYear, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuildingModel() when $default != null:
return $default(_that.id,_that.name,_that.propertyType,_that.totalFloors,_that.basementFloors,_that.gfa,_that.nla,_that.address,_that.builtYear,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'property_type')  String propertyType, @JsonKey(name: 'total_floors')  int totalFloors, @JsonKey(name: 'basement_floors')  int basementFloors,  double gfa,  double nla,  String? address, @JsonKey(name: 'built_year')  int? builtYear, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt)  $default,) {final _that = this;
switch (_that) {
case _BuildingModel():
return $default(_that.id,_that.name,_that.propertyType,_that.totalFloors,_that.basementFloors,_that.gfa,_that.nla,_that.address,_that.builtYear,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name, @JsonKey(name: 'property_type')  String propertyType, @JsonKey(name: 'total_floors')  int totalFloors, @JsonKey(name: 'basement_floors')  int basementFloors,  double gfa,  double nla,  String? address, @JsonKey(name: 'built_year')  int? builtYear, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _BuildingModel() when $default != null:
return $default(_that.id,_that.name,_that.propertyType,_that.totalFloors,_that.basementFloors,_that.gfa,_that.nla,_that.address,_that.builtYear,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuildingModel implements BuildingModel {
  const _BuildingModel({required this.id, required this.name, @JsonKey(name: 'property_type') required this.propertyType, @JsonKey(name: 'total_floors') required this.totalFloors, @JsonKey(name: 'basement_floors') this.basementFloors = 0, required this.gfa, required this.nla, this.address, @JsonKey(name: 'built_year') this.builtYear, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt});
  factory _BuildingModel.fromJson(Map<String, dynamic> json) => _$BuildingModelFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey(name: 'property_type') final  String propertyType;
@override@JsonKey(name: 'total_floors') final  int totalFloors;
@override@JsonKey(name: 'basement_floors') final  int basementFloors;
@override final  double gfa;
@override final  double nla;
@override final  String? address;
@override@JsonKey(name: 'built_year') final  int? builtYear;
@override@JsonKey(name: 'created_at') final  String createdAt;
@override@JsonKey(name: 'updated_at') final  String updatedAt;

/// Create a copy of BuildingModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuildingModelCopyWith<_BuildingModel> get copyWith => __$BuildingModelCopyWithImpl<_BuildingModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuildingModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuildingModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.propertyType, propertyType) || other.propertyType == propertyType)&&(identical(other.totalFloors, totalFloors) || other.totalFloors == totalFloors)&&(identical(other.basementFloors, basementFloors) || other.basementFloors == basementFloors)&&(identical(other.gfa, gfa) || other.gfa == gfa)&&(identical(other.nla, nla) || other.nla == nla)&&(identical(other.address, address) || other.address == address)&&(identical(other.builtYear, builtYear) || other.builtYear == builtYear)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,propertyType,totalFloors,basementFloors,gfa,nla,address,builtYear,createdAt,updatedAt);

@override
String toString() {
  return 'BuildingModel(id: $id, name: $name, propertyType: $propertyType, totalFloors: $totalFloors, basementFloors: $basementFloors, gfa: $gfa, nla: $nla, address: $address, builtYear: $builtYear, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$BuildingModelCopyWith<$Res> implements $BuildingModelCopyWith<$Res> {
  factory _$BuildingModelCopyWith(_BuildingModel value, $Res Function(_BuildingModel) _then) = __$BuildingModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@JsonKey(name: 'property_type') String propertyType,@JsonKey(name: 'total_floors') int totalFloors,@JsonKey(name: 'basement_floors') int basementFloors, double gfa, double nla, String? address,@JsonKey(name: 'built_year') int? builtYear,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'updated_at') String updatedAt
});




}
/// @nodoc
class __$BuildingModelCopyWithImpl<$Res>
    implements _$BuildingModelCopyWith<$Res> {
  __$BuildingModelCopyWithImpl(this._self, this._then);

  final _BuildingModel _self;
  final $Res Function(_BuildingModel) _then;

/// Create a copy of BuildingModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? propertyType = null,Object? totalFloors = null,Object? basementFloors = null,Object? gfa = null,Object? nla = null,Object? address = freezed,Object? builtYear = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_BuildingModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,propertyType: null == propertyType ? _self.propertyType : propertyType // ignore: cast_nullable_to_non_nullable
as String,totalFloors: null == totalFloors ? _self.totalFloors : totalFloors // ignore: cast_nullable_to_non_nullable
as int,basementFloors: null == basementFloors ? _self.basementFloors : basementFloors // ignore: cast_nullable_to_non_nullable
as int,gfa: null == gfa ? _self.gfa : gfa // ignore: cast_nullable_to_non_nullable
as double,nla: null == nla ? _self.nla : nla // ignore: cast_nullable_to_non_nullable
as double,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,builtYear: freezed == builtYear ? _self.builtYear : builtYear // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
