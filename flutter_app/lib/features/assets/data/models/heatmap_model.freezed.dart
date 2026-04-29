// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'heatmap_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HeatmapUnitModel {

@JsonKey(name: 'unit_id') String get unitId;@JsonKey(name: 'unit_number') String get unitNumber;@JsonKey(name: 'current_status') String get currentStatus;@JsonKey(name: 'property_type') String get propertyType;@JsonKey(name: 'tenant_name') String? get tenantName;@JsonKey(name: 'contract_end_date') String? get contractEndDate;
/// Create a copy of HeatmapUnitModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HeatmapUnitModelCopyWith<HeatmapUnitModel> get copyWith => _$HeatmapUnitModelCopyWithImpl<HeatmapUnitModel>(this as HeatmapUnitModel, _$identity);

  /// Serializes this HeatmapUnitModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HeatmapUnitModel&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.unitNumber, unitNumber) || other.unitNumber == unitNumber)&&(identical(other.currentStatus, currentStatus) || other.currentStatus == currentStatus)&&(identical(other.propertyType, propertyType) || other.propertyType == propertyType)&&(identical(other.tenantName, tenantName) || other.tenantName == tenantName)&&(identical(other.contractEndDate, contractEndDate) || other.contractEndDate == contractEndDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,unitId,unitNumber,currentStatus,propertyType,tenantName,contractEndDate);

@override
String toString() {
  return 'HeatmapUnitModel(unitId: $unitId, unitNumber: $unitNumber, currentStatus: $currentStatus, propertyType: $propertyType, tenantName: $tenantName, contractEndDate: $contractEndDate)';
}


}

/// @nodoc
abstract mixin class $HeatmapUnitModelCopyWith<$Res>  {
  factory $HeatmapUnitModelCopyWith(HeatmapUnitModel value, $Res Function(HeatmapUnitModel) _then) = _$HeatmapUnitModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'unit_id') String unitId,@JsonKey(name: 'unit_number') String unitNumber,@JsonKey(name: 'current_status') String currentStatus,@JsonKey(name: 'property_type') String propertyType,@JsonKey(name: 'tenant_name') String? tenantName,@JsonKey(name: 'contract_end_date') String? contractEndDate
});




}
/// @nodoc
class _$HeatmapUnitModelCopyWithImpl<$Res>
    implements $HeatmapUnitModelCopyWith<$Res> {
  _$HeatmapUnitModelCopyWithImpl(this._self, this._then);

  final HeatmapUnitModel _self;
  final $Res Function(HeatmapUnitModel) _then;

/// Create a copy of HeatmapUnitModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? unitId = null,Object? unitNumber = null,Object? currentStatus = null,Object? propertyType = null,Object? tenantName = freezed,Object? contractEndDate = freezed,}) {
  return _then(_self.copyWith(
unitId: null == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String,unitNumber: null == unitNumber ? _self.unitNumber : unitNumber // ignore: cast_nullable_to_non_nullable
as String,currentStatus: null == currentStatus ? _self.currentStatus : currentStatus // ignore: cast_nullable_to_non_nullable
as String,propertyType: null == propertyType ? _self.propertyType : propertyType // ignore: cast_nullable_to_non_nullable
as String,tenantName: freezed == tenantName ? _self.tenantName : tenantName // ignore: cast_nullable_to_non_nullable
as String?,contractEndDate: freezed == contractEndDate ? _self.contractEndDate : contractEndDate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [HeatmapUnitModel].
extension HeatmapUnitModelPatterns on HeatmapUnitModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HeatmapUnitModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HeatmapUnitModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HeatmapUnitModel value)  $default,){
final _that = this;
switch (_that) {
case _HeatmapUnitModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HeatmapUnitModel value)?  $default,){
final _that = this;
switch (_that) {
case _HeatmapUnitModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'unit_id')  String unitId, @JsonKey(name: 'unit_number')  String unitNumber, @JsonKey(name: 'current_status')  String currentStatus, @JsonKey(name: 'property_type')  String propertyType, @JsonKey(name: 'tenant_name')  String? tenantName, @JsonKey(name: 'contract_end_date')  String? contractEndDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HeatmapUnitModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'unit_id')  String unitId, @JsonKey(name: 'unit_number')  String unitNumber, @JsonKey(name: 'current_status')  String currentStatus, @JsonKey(name: 'property_type')  String propertyType, @JsonKey(name: 'tenant_name')  String? tenantName, @JsonKey(name: 'contract_end_date')  String? contractEndDate)  $default,) {final _that = this;
switch (_that) {
case _HeatmapUnitModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'unit_id')  String unitId, @JsonKey(name: 'unit_number')  String unitNumber, @JsonKey(name: 'current_status')  String currentStatus, @JsonKey(name: 'property_type')  String propertyType, @JsonKey(name: 'tenant_name')  String? tenantName, @JsonKey(name: 'contract_end_date')  String? contractEndDate)?  $default,) {final _that = this;
switch (_that) {
case _HeatmapUnitModel() when $default != null:
return $default(_that.unitId,_that.unitNumber,_that.currentStatus,_that.propertyType,_that.tenantName,_that.contractEndDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HeatmapUnitModel implements HeatmapUnitModel {
  const _HeatmapUnitModel({@JsonKey(name: 'unit_id') required this.unitId, @JsonKey(name: 'unit_number') required this.unitNumber, @JsonKey(name: 'current_status') required this.currentStatus, @JsonKey(name: 'property_type') required this.propertyType, @JsonKey(name: 'tenant_name') this.tenantName, @JsonKey(name: 'contract_end_date') this.contractEndDate});
  factory _HeatmapUnitModel.fromJson(Map<String, dynamic> json) => _$HeatmapUnitModelFromJson(json);

@override@JsonKey(name: 'unit_id') final  String unitId;
@override@JsonKey(name: 'unit_number') final  String unitNumber;
@override@JsonKey(name: 'current_status') final  String currentStatus;
@override@JsonKey(name: 'property_type') final  String propertyType;
@override@JsonKey(name: 'tenant_name') final  String? tenantName;
@override@JsonKey(name: 'contract_end_date') final  String? contractEndDate;

/// Create a copy of HeatmapUnitModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HeatmapUnitModelCopyWith<_HeatmapUnitModel> get copyWith => __$HeatmapUnitModelCopyWithImpl<_HeatmapUnitModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HeatmapUnitModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HeatmapUnitModel&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.unitNumber, unitNumber) || other.unitNumber == unitNumber)&&(identical(other.currentStatus, currentStatus) || other.currentStatus == currentStatus)&&(identical(other.propertyType, propertyType) || other.propertyType == propertyType)&&(identical(other.tenantName, tenantName) || other.tenantName == tenantName)&&(identical(other.contractEndDate, contractEndDate) || other.contractEndDate == contractEndDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,unitId,unitNumber,currentStatus,propertyType,tenantName,contractEndDate);

@override
String toString() {
  return 'HeatmapUnitModel(unitId: $unitId, unitNumber: $unitNumber, currentStatus: $currentStatus, propertyType: $propertyType, tenantName: $tenantName, contractEndDate: $contractEndDate)';
}


}

/// @nodoc
abstract mixin class _$HeatmapUnitModelCopyWith<$Res> implements $HeatmapUnitModelCopyWith<$Res> {
  factory _$HeatmapUnitModelCopyWith(_HeatmapUnitModel value, $Res Function(_HeatmapUnitModel) _then) = __$HeatmapUnitModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'unit_id') String unitId,@JsonKey(name: 'unit_number') String unitNumber,@JsonKey(name: 'current_status') String currentStatus,@JsonKey(name: 'property_type') String propertyType,@JsonKey(name: 'tenant_name') String? tenantName,@JsonKey(name: 'contract_end_date') String? contractEndDate
});




}
/// @nodoc
class __$HeatmapUnitModelCopyWithImpl<$Res>
    implements _$HeatmapUnitModelCopyWith<$Res> {
  __$HeatmapUnitModelCopyWithImpl(this._self, this._then);

  final _HeatmapUnitModel _self;
  final $Res Function(_HeatmapUnitModel) _then;

/// Create a copy of HeatmapUnitModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? unitId = null,Object? unitNumber = null,Object? currentStatus = null,Object? propertyType = null,Object? tenantName = freezed,Object? contractEndDate = freezed,}) {
  return _then(_HeatmapUnitModel(
unitId: null == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String,unitNumber: null == unitNumber ? _self.unitNumber : unitNumber // ignore: cast_nullable_to_non_nullable
as String,currentStatus: null == currentStatus ? _self.currentStatus : currentStatus // ignore: cast_nullable_to_non_nullable
as String,propertyType: null == propertyType ? _self.propertyType : propertyType // ignore: cast_nullable_to_non_nullable
as String,tenantName: freezed == tenantName ? _self.tenantName : tenantName // ignore: cast_nullable_to_non_nullable
as String?,contractEndDate: freezed == contractEndDate ? _self.contractEndDate : contractEndDate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$FloorHeatmapModel {

@JsonKey(name: 'floor_id') String get floorId;@JsonKey(name: 'svg_path') String? get svgPath; List<HeatmapUnitModel> get units;
/// Create a copy of FloorHeatmapModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FloorHeatmapModelCopyWith<FloorHeatmapModel> get copyWith => _$FloorHeatmapModelCopyWithImpl<FloorHeatmapModel>(this as FloorHeatmapModel, _$identity);

  /// Serializes this FloorHeatmapModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FloorHeatmapModel&&(identical(other.floorId, floorId) || other.floorId == floorId)&&(identical(other.svgPath, svgPath) || other.svgPath == svgPath)&&const DeepCollectionEquality().equals(other.units, units));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,floorId,svgPath,const DeepCollectionEquality().hash(units));

@override
String toString() {
  return 'FloorHeatmapModel(floorId: $floorId, svgPath: $svgPath, units: $units)';
}


}

/// @nodoc
abstract mixin class $FloorHeatmapModelCopyWith<$Res>  {
  factory $FloorHeatmapModelCopyWith(FloorHeatmapModel value, $Res Function(FloorHeatmapModel) _then) = _$FloorHeatmapModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'floor_id') String floorId,@JsonKey(name: 'svg_path') String? svgPath, List<HeatmapUnitModel> units
});




}
/// @nodoc
class _$FloorHeatmapModelCopyWithImpl<$Res>
    implements $FloorHeatmapModelCopyWith<$Res> {
  _$FloorHeatmapModelCopyWithImpl(this._self, this._then);

  final FloorHeatmapModel _self;
  final $Res Function(FloorHeatmapModel) _then;

/// Create a copy of FloorHeatmapModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? floorId = null,Object? svgPath = freezed,Object? units = null,}) {
  return _then(_self.copyWith(
floorId: null == floorId ? _self.floorId : floorId // ignore: cast_nullable_to_non_nullable
as String,svgPath: freezed == svgPath ? _self.svgPath : svgPath // ignore: cast_nullable_to_non_nullable
as String?,units: null == units ? _self.units : units // ignore: cast_nullable_to_non_nullable
as List<HeatmapUnitModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [FloorHeatmapModel].
extension FloorHeatmapModelPatterns on FloorHeatmapModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FloorHeatmapModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FloorHeatmapModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FloorHeatmapModel value)  $default,){
final _that = this;
switch (_that) {
case _FloorHeatmapModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FloorHeatmapModel value)?  $default,){
final _that = this;
switch (_that) {
case _FloorHeatmapModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'floor_id')  String floorId, @JsonKey(name: 'svg_path')  String? svgPath,  List<HeatmapUnitModel> units)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FloorHeatmapModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'floor_id')  String floorId, @JsonKey(name: 'svg_path')  String? svgPath,  List<HeatmapUnitModel> units)  $default,) {final _that = this;
switch (_that) {
case _FloorHeatmapModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'floor_id')  String floorId, @JsonKey(name: 'svg_path')  String? svgPath,  List<HeatmapUnitModel> units)?  $default,) {final _that = this;
switch (_that) {
case _FloorHeatmapModel() when $default != null:
return $default(_that.floorId,_that.svgPath,_that.units);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FloorHeatmapModel implements FloorHeatmapModel {
  const _FloorHeatmapModel({@JsonKey(name: 'floor_id') required this.floorId, @JsonKey(name: 'svg_path') this.svgPath, required final  List<HeatmapUnitModel> units}): _units = units;
  factory _FloorHeatmapModel.fromJson(Map<String, dynamic> json) => _$FloorHeatmapModelFromJson(json);

@override@JsonKey(name: 'floor_id') final  String floorId;
@override@JsonKey(name: 'svg_path') final  String? svgPath;
 final  List<HeatmapUnitModel> _units;
@override List<HeatmapUnitModel> get units {
  if (_units is EqualUnmodifiableListView) return _units;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_units);
}


/// Create a copy of FloorHeatmapModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FloorHeatmapModelCopyWith<_FloorHeatmapModel> get copyWith => __$FloorHeatmapModelCopyWithImpl<_FloorHeatmapModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FloorHeatmapModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FloorHeatmapModel&&(identical(other.floorId, floorId) || other.floorId == floorId)&&(identical(other.svgPath, svgPath) || other.svgPath == svgPath)&&const DeepCollectionEquality().equals(other._units, _units));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,floorId,svgPath,const DeepCollectionEquality().hash(_units));

@override
String toString() {
  return 'FloorHeatmapModel(floorId: $floorId, svgPath: $svgPath, units: $units)';
}


}

/// @nodoc
abstract mixin class _$FloorHeatmapModelCopyWith<$Res> implements $FloorHeatmapModelCopyWith<$Res> {
  factory _$FloorHeatmapModelCopyWith(_FloorHeatmapModel value, $Res Function(_FloorHeatmapModel) _then) = __$FloorHeatmapModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'floor_id') String floorId,@JsonKey(name: 'svg_path') String? svgPath, List<HeatmapUnitModel> units
});




}
/// @nodoc
class __$FloorHeatmapModelCopyWithImpl<$Res>
    implements _$FloorHeatmapModelCopyWith<$Res> {
  __$FloorHeatmapModelCopyWithImpl(this._self, this._then);

  final _FloorHeatmapModel _self;
  final $Res Function(_FloorHeatmapModel) _then;

/// Create a copy of FloorHeatmapModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? floorId = null,Object? svgPath = freezed,Object? units = null,}) {
  return _then(_FloorHeatmapModel(
floorId: null == floorId ? _self.floorId : floorId // ignore: cast_nullable_to_non_nullable
as String,svgPath: freezed == svgPath ? _self.svgPath : svgPath // ignore: cast_nullable_to_non_nullable
as String?,units: null == units ? _self._units : units // ignore: cast_nullable_to_non_nullable
as List<HeatmapUnitModel>,
  ));
}


}

// dart format on
