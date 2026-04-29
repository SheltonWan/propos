// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'heatmap.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HeatmapUnit {

 String get unitId; String get unitNumber; UnitStatus get currentStatus; PropertyType get propertyType; String? get tenantName; DateTime? get contractEndDate;
/// Create a copy of HeatmapUnit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HeatmapUnitCopyWith<HeatmapUnit> get copyWith => _$HeatmapUnitCopyWithImpl<HeatmapUnit>(this as HeatmapUnit, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HeatmapUnit&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.unitNumber, unitNumber) || other.unitNumber == unitNumber)&&(identical(other.currentStatus, currentStatus) || other.currentStatus == currentStatus)&&(identical(other.propertyType, propertyType) || other.propertyType == propertyType)&&(identical(other.tenantName, tenantName) || other.tenantName == tenantName)&&(identical(other.contractEndDate, contractEndDate) || other.contractEndDate == contractEndDate));
}


@override
int get hashCode => Object.hash(runtimeType,unitId,unitNumber,currentStatus,propertyType,tenantName,contractEndDate);

@override
String toString() {
  return 'HeatmapUnit(unitId: $unitId, unitNumber: $unitNumber, currentStatus: $currentStatus, propertyType: $propertyType, tenantName: $tenantName, contractEndDate: $contractEndDate)';
}


}

/// @nodoc
abstract mixin class $HeatmapUnitCopyWith<$Res>  {
  factory $HeatmapUnitCopyWith(HeatmapUnit value, $Res Function(HeatmapUnit) _then) = _$HeatmapUnitCopyWithImpl;
@useResult
$Res call({
 String unitId, String unitNumber, UnitStatus currentStatus, PropertyType propertyType, String? tenantName, DateTime? contractEndDate
});




}
/// @nodoc
class _$HeatmapUnitCopyWithImpl<$Res>
    implements $HeatmapUnitCopyWith<$Res> {
  _$HeatmapUnitCopyWithImpl(this._self, this._then);

  final HeatmapUnit _self;
  final $Res Function(HeatmapUnit) _then;

/// Create a copy of HeatmapUnit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? unitId = null,Object? unitNumber = null,Object? currentStatus = null,Object? propertyType = null,Object? tenantName = freezed,Object? contractEndDate = freezed,}) {
  return _then(_self.copyWith(
unitId: null == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String,unitNumber: null == unitNumber ? _self.unitNumber : unitNumber // ignore: cast_nullable_to_non_nullable
as String,currentStatus: null == currentStatus ? _self.currentStatus : currentStatus // ignore: cast_nullable_to_non_nullable
as UnitStatus,propertyType: null == propertyType ? _self.propertyType : propertyType // ignore: cast_nullable_to_non_nullable
as PropertyType,tenantName: freezed == tenantName ? _self.tenantName : tenantName // ignore: cast_nullable_to_non_nullable
as String?,contractEndDate: freezed == contractEndDate ? _self.contractEndDate : contractEndDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [HeatmapUnit].
extension HeatmapUnitPatterns on HeatmapUnit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HeatmapUnit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HeatmapUnit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HeatmapUnit value)  $default,){
final _that = this;
switch (_that) {
case _HeatmapUnit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HeatmapUnit value)?  $default,){
final _that = this;
switch (_that) {
case _HeatmapUnit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String unitId,  String unitNumber,  UnitStatus currentStatus,  PropertyType propertyType,  String? tenantName,  DateTime? contractEndDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HeatmapUnit() when $default != null:
return $default(_that.unitId,_that.unitNumber,_that.currentStatus,_that.propertyType,_that.tenantName,_that.contractEndDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String unitId,  String unitNumber,  UnitStatus currentStatus,  PropertyType propertyType,  String? tenantName,  DateTime? contractEndDate)  $default,) {final _that = this;
switch (_that) {
case _HeatmapUnit():
return $default(_that.unitId,_that.unitNumber,_that.currentStatus,_that.propertyType,_that.tenantName,_that.contractEndDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String unitId,  String unitNumber,  UnitStatus currentStatus,  PropertyType propertyType,  String? tenantName,  DateTime? contractEndDate)?  $default,) {final _that = this;
switch (_that) {
case _HeatmapUnit() when $default != null:
return $default(_that.unitId,_that.unitNumber,_that.currentStatus,_that.propertyType,_that.tenantName,_that.contractEndDate);case _:
  return null;

}
}

}

/// @nodoc


class _HeatmapUnit implements HeatmapUnit {
  const _HeatmapUnit({required this.unitId, required this.unitNumber, required this.currentStatus, required this.propertyType, this.tenantName, this.contractEndDate});
  

@override final  String unitId;
@override final  String unitNumber;
@override final  UnitStatus currentStatus;
@override final  PropertyType propertyType;
@override final  String? tenantName;
@override final  DateTime? contractEndDate;

/// Create a copy of HeatmapUnit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HeatmapUnitCopyWith<_HeatmapUnit> get copyWith => __$HeatmapUnitCopyWithImpl<_HeatmapUnit>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HeatmapUnit&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.unitNumber, unitNumber) || other.unitNumber == unitNumber)&&(identical(other.currentStatus, currentStatus) || other.currentStatus == currentStatus)&&(identical(other.propertyType, propertyType) || other.propertyType == propertyType)&&(identical(other.tenantName, tenantName) || other.tenantName == tenantName)&&(identical(other.contractEndDate, contractEndDate) || other.contractEndDate == contractEndDate));
}


@override
int get hashCode => Object.hash(runtimeType,unitId,unitNumber,currentStatus,propertyType,tenantName,contractEndDate);

@override
String toString() {
  return 'HeatmapUnit(unitId: $unitId, unitNumber: $unitNumber, currentStatus: $currentStatus, propertyType: $propertyType, tenantName: $tenantName, contractEndDate: $contractEndDate)';
}


}

/// @nodoc
abstract mixin class _$HeatmapUnitCopyWith<$Res> implements $HeatmapUnitCopyWith<$Res> {
  factory _$HeatmapUnitCopyWith(_HeatmapUnit value, $Res Function(_HeatmapUnit) _then) = __$HeatmapUnitCopyWithImpl;
@override @useResult
$Res call({
 String unitId, String unitNumber, UnitStatus currentStatus, PropertyType propertyType, String? tenantName, DateTime? contractEndDate
});




}
/// @nodoc
class __$HeatmapUnitCopyWithImpl<$Res>
    implements _$HeatmapUnitCopyWith<$Res> {
  __$HeatmapUnitCopyWithImpl(this._self, this._then);

  final _HeatmapUnit _self;
  final $Res Function(_HeatmapUnit) _then;

/// Create a copy of HeatmapUnit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? unitId = null,Object? unitNumber = null,Object? currentStatus = null,Object? propertyType = null,Object? tenantName = freezed,Object? contractEndDate = freezed,}) {
  return _then(_HeatmapUnit(
unitId: null == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String,unitNumber: null == unitNumber ? _self.unitNumber : unitNumber // ignore: cast_nullable_to_non_nullable
as String,currentStatus: null == currentStatus ? _self.currentStatus : currentStatus // ignore: cast_nullable_to_non_nullable
as UnitStatus,propertyType: null == propertyType ? _self.propertyType : propertyType // ignore: cast_nullable_to_non_nullable
as PropertyType,tenantName: freezed == tenantName ? _self.tenantName : tenantName // ignore: cast_nullable_to_non_nullable
as String?,contractEndDate: freezed == contractEndDate ? _self.contractEndDate : contractEndDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$FloorHeatmap {

 String get floorId; String? get svgPath; List<HeatmapUnit> get units;
/// Create a copy of FloorHeatmap
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FloorHeatmapCopyWith<FloorHeatmap> get copyWith => _$FloorHeatmapCopyWithImpl<FloorHeatmap>(this as FloorHeatmap, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FloorHeatmap&&(identical(other.floorId, floorId) || other.floorId == floorId)&&(identical(other.svgPath, svgPath) || other.svgPath == svgPath)&&const DeepCollectionEquality().equals(other.units, units));
}


@override
int get hashCode => Object.hash(runtimeType,floorId,svgPath,const DeepCollectionEquality().hash(units));

@override
String toString() {
  return 'FloorHeatmap(floorId: $floorId, svgPath: $svgPath, units: $units)';
}


}

/// @nodoc
abstract mixin class $FloorHeatmapCopyWith<$Res>  {
  factory $FloorHeatmapCopyWith(FloorHeatmap value, $Res Function(FloorHeatmap) _then) = _$FloorHeatmapCopyWithImpl;
@useResult
$Res call({
 String floorId, String? svgPath, List<HeatmapUnit> units
});




}
/// @nodoc
class _$FloorHeatmapCopyWithImpl<$Res>
    implements $FloorHeatmapCopyWith<$Res> {
  _$FloorHeatmapCopyWithImpl(this._self, this._then);

  final FloorHeatmap _self;
  final $Res Function(FloorHeatmap) _then;

/// Create a copy of FloorHeatmap
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? floorId = null,Object? svgPath = freezed,Object? units = null,}) {
  return _then(_self.copyWith(
floorId: null == floorId ? _self.floorId : floorId // ignore: cast_nullable_to_non_nullable
as String,svgPath: freezed == svgPath ? _self.svgPath : svgPath // ignore: cast_nullable_to_non_nullable
as String?,units: null == units ? _self.units : units // ignore: cast_nullable_to_non_nullable
as List<HeatmapUnit>,
  ));
}

}


/// Adds pattern-matching-related methods to [FloorHeatmap].
extension FloorHeatmapPatterns on FloorHeatmap {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FloorHeatmap value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FloorHeatmap() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FloorHeatmap value)  $default,){
final _that = this;
switch (_that) {
case _FloorHeatmap():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FloorHeatmap value)?  $default,){
final _that = this;
switch (_that) {
case _FloorHeatmap() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String floorId,  String? svgPath,  List<HeatmapUnit> units)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FloorHeatmap() when $default != null:
return $default(_that.floorId,_that.svgPath,_that.units);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String floorId,  String? svgPath,  List<HeatmapUnit> units)  $default,) {final _that = this;
switch (_that) {
case _FloorHeatmap():
return $default(_that.floorId,_that.svgPath,_that.units);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String floorId,  String? svgPath,  List<HeatmapUnit> units)?  $default,) {final _that = this;
switch (_that) {
case _FloorHeatmap() when $default != null:
return $default(_that.floorId,_that.svgPath,_that.units);case _:
  return null;

}
}

}

/// @nodoc


class _FloorHeatmap implements FloorHeatmap {
  const _FloorHeatmap({required this.floorId, this.svgPath, required final  List<HeatmapUnit> units}): _units = units;
  

@override final  String floorId;
@override final  String? svgPath;
 final  List<HeatmapUnit> _units;
@override List<HeatmapUnit> get units {
  if (_units is EqualUnmodifiableListView) return _units;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_units);
}


/// Create a copy of FloorHeatmap
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FloorHeatmapCopyWith<_FloorHeatmap> get copyWith => __$FloorHeatmapCopyWithImpl<_FloorHeatmap>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FloorHeatmap&&(identical(other.floorId, floorId) || other.floorId == floorId)&&(identical(other.svgPath, svgPath) || other.svgPath == svgPath)&&const DeepCollectionEquality().equals(other._units, _units));
}


@override
int get hashCode => Object.hash(runtimeType,floorId,svgPath,const DeepCollectionEquality().hash(_units));

@override
String toString() {
  return 'FloorHeatmap(floorId: $floorId, svgPath: $svgPath, units: $units)';
}


}

/// @nodoc
abstract mixin class _$FloorHeatmapCopyWith<$Res> implements $FloorHeatmapCopyWith<$Res> {
  factory _$FloorHeatmapCopyWith(_FloorHeatmap value, $Res Function(_FloorHeatmap) _then) = __$FloorHeatmapCopyWithImpl;
@override @useResult
$Res call({
 String floorId, String? svgPath, List<HeatmapUnit> units
});




}
/// @nodoc
class __$FloorHeatmapCopyWithImpl<$Res>
    implements _$FloorHeatmapCopyWith<$Res> {
  __$FloorHeatmapCopyWithImpl(this._self, this._then);

  final _FloorHeatmap _self;
  final $Res Function(_FloorHeatmap) _then;

/// Create a copy of FloorHeatmap
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? floorId = null,Object? svgPath = freezed,Object? units = null,}) {
  return _then(_FloorHeatmap(
floorId: null == floorId ? _self.floorId : floorId // ignore: cast_nullable_to_non_nullable
as String,svgPath: freezed == svgPath ? _self.svgPath : svgPath // ignore: cast_nullable_to_non_nullable
as String?,units: null == units ? _self._units : units // ignore: cast_nullable_to_non_nullable
as List<HeatmapUnit>,
  ));
}


}

// dart format on
