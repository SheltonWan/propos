// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'building.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Building {

 String get id; String get name; PropertyType get propertyType; int get totalFloors; int get basementFloors; double get gfa; double get nla; String? get address; int? get builtYear; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of Building
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuildingCopyWith<Building> get copyWith => _$BuildingCopyWithImpl<Building>(this as Building, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Building&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.propertyType, propertyType) || other.propertyType == propertyType)&&(identical(other.totalFloors, totalFloors) || other.totalFloors == totalFloors)&&(identical(other.basementFloors, basementFloors) || other.basementFloors == basementFloors)&&(identical(other.gfa, gfa) || other.gfa == gfa)&&(identical(other.nla, nla) || other.nla == nla)&&(identical(other.address, address) || other.address == address)&&(identical(other.builtYear, builtYear) || other.builtYear == builtYear)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,propertyType,totalFloors,basementFloors,gfa,nla,address,builtYear,createdAt,updatedAt);

@override
String toString() {
  return 'Building(id: $id, name: $name, propertyType: $propertyType, totalFloors: $totalFloors, basementFloors: $basementFloors, gfa: $gfa, nla: $nla, address: $address, builtYear: $builtYear, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $BuildingCopyWith<$Res>  {
  factory $BuildingCopyWith(Building value, $Res Function(Building) _then) = _$BuildingCopyWithImpl;
@useResult
$Res call({
 String id, String name, PropertyType propertyType, int totalFloors, int basementFloors, double gfa, double nla, String? address, int? builtYear, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$BuildingCopyWithImpl<$Res>
    implements $BuildingCopyWith<$Res> {
  _$BuildingCopyWithImpl(this._self, this._then);

  final Building _self;
  final $Res Function(Building) _then;

/// Create a copy of Building
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? propertyType = null,Object? totalFloors = null,Object? basementFloors = null,Object? gfa = null,Object? nla = null,Object? address = freezed,Object? builtYear = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,propertyType: null == propertyType ? _self.propertyType : propertyType // ignore: cast_nullable_to_non_nullable
as PropertyType,totalFloors: null == totalFloors ? _self.totalFloors : totalFloors // ignore: cast_nullable_to_non_nullable
as int,basementFloors: null == basementFloors ? _self.basementFloors : basementFloors // ignore: cast_nullable_to_non_nullable
as int,gfa: null == gfa ? _self.gfa : gfa // ignore: cast_nullable_to_non_nullable
as double,nla: null == nla ? _self.nla : nla // ignore: cast_nullable_to_non_nullable
as double,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,builtYear: freezed == builtYear ? _self.builtYear : builtYear // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Building].
extension BuildingPatterns on Building {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Building value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Building() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Building value)  $default,){
final _that = this;
switch (_that) {
case _Building():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Building value)?  $default,){
final _that = this;
switch (_that) {
case _Building() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  PropertyType propertyType,  int totalFloors,  int basementFloors,  double gfa,  double nla,  String? address,  int? builtYear,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Building() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  PropertyType propertyType,  int totalFloors,  int basementFloors,  double gfa,  double nla,  String? address,  int? builtYear,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Building():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  PropertyType propertyType,  int totalFloors,  int basementFloors,  double gfa,  double nla,  String? address,  int? builtYear,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Building() when $default != null:
return $default(_that.id,_that.name,_that.propertyType,_that.totalFloors,_that.basementFloors,_that.gfa,_that.nla,_that.address,_that.builtYear,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Building implements Building {
  const _Building({required this.id, required this.name, required this.propertyType, required this.totalFloors, this.basementFloors = 0, required this.gfa, required this.nla, this.address, this.builtYear, required this.createdAt, required this.updatedAt});
  

@override final  String id;
@override final  String name;
@override final  PropertyType propertyType;
@override final  int totalFloors;
@override@JsonKey() final  int basementFloors;
@override final  double gfa;
@override final  double nla;
@override final  String? address;
@override final  int? builtYear;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of Building
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuildingCopyWith<_Building> get copyWith => __$BuildingCopyWithImpl<_Building>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Building&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.propertyType, propertyType) || other.propertyType == propertyType)&&(identical(other.totalFloors, totalFloors) || other.totalFloors == totalFloors)&&(identical(other.basementFloors, basementFloors) || other.basementFloors == basementFloors)&&(identical(other.gfa, gfa) || other.gfa == gfa)&&(identical(other.nla, nla) || other.nla == nla)&&(identical(other.address, address) || other.address == address)&&(identical(other.builtYear, builtYear) || other.builtYear == builtYear)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,propertyType,totalFloors,basementFloors,gfa,nla,address,builtYear,createdAt,updatedAt);

@override
String toString() {
  return 'Building(id: $id, name: $name, propertyType: $propertyType, totalFloors: $totalFloors, basementFloors: $basementFloors, gfa: $gfa, nla: $nla, address: $address, builtYear: $builtYear, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$BuildingCopyWith<$Res> implements $BuildingCopyWith<$Res> {
  factory _$BuildingCopyWith(_Building value, $Res Function(_Building) _then) = __$BuildingCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, PropertyType propertyType, int totalFloors, int basementFloors, double gfa, double nla, String? address, int? builtYear, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$BuildingCopyWithImpl<$Res>
    implements _$BuildingCopyWith<$Res> {
  __$BuildingCopyWithImpl(this._self, this._then);

  final _Building _self;
  final $Res Function(_Building) _then;

/// Create a copy of Building
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? propertyType = null,Object? totalFloors = null,Object? basementFloors = null,Object? gfa = null,Object? nla = null,Object? address = freezed,Object? builtYear = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Building(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,propertyType: null == propertyType ? _self.propertyType : propertyType // ignore: cast_nullable_to_non_nullable
as PropertyType,totalFloors: null == totalFloors ? _self.totalFloors : totalFloors // ignore: cast_nullable_to_non_nullable
as int,basementFloors: null == basementFloors ? _self.basementFloors : basementFloors // ignore: cast_nullable_to_non_nullable
as int,gfa: null == gfa ? _self.gfa : gfa // ignore: cast_nullable_to_non_nullable
as double,nla: null == nla ? _self.nla : nla // ignore: cast_nullable_to_non_nullable
as double,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,builtYear: freezed == builtYear ? _self.builtYear : builtYear // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
