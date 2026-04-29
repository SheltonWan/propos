// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unit_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UnitDetailModel {

 String get id;@JsonKey(name: 'building_id') String get buildingId;@JsonKey(name: 'building_name') String get buildingName;@JsonKey(name: 'floor_id') String get floorId;@JsonKey(name: 'floor_name') String? get floorName;@JsonKey(name: 'unit_number') String get unitNumber;@JsonKey(name: 'property_type') String get propertyType;@JsonKey(name: 'gross_area') double? get grossArea;@JsonKey(name: 'net_area') double? get netArea; String? get orientation;@JsonKey(name: 'ceiling_height') double? get ceilingHeight;@JsonKey(name: 'decoration_status') String get decorationStatus;@JsonKey(name: 'current_status') String get currentStatus;@JsonKey(name: 'is_leasable') bool get isLeasable;@JsonKey(name: 'ext_fields') Map<String, dynamic>? get extFields;@JsonKey(name: 'current_contract_id') String? get currentContractId;@JsonKey(name: 'qr_code') String? get qrCode;@JsonKey(name: 'market_rent_reference') double? get marketRentReference;@JsonKey(name: 'predecessor_unit_ids', defaultValue: <String>[]) List<String> get predecessorUnitIds;@JsonKey(name: 'created_at') String get createdAt;@JsonKey(name: 'updated_at') String get updatedAt;
/// Create a copy of UnitDetailModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnitDetailModelCopyWith<UnitDetailModel> get copyWith => _$UnitDetailModelCopyWithImpl<UnitDetailModel>(this as UnitDetailModel, _$identity);

  /// Serializes this UnitDetailModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnitDetailModel&&(identical(other.id, id) || other.id == id)&&(identical(other.buildingId, buildingId) || other.buildingId == buildingId)&&(identical(other.buildingName, buildingName) || other.buildingName == buildingName)&&(identical(other.floorId, floorId) || other.floorId == floorId)&&(identical(other.floorName, floorName) || other.floorName == floorName)&&(identical(other.unitNumber, unitNumber) || other.unitNumber == unitNumber)&&(identical(other.propertyType, propertyType) || other.propertyType == propertyType)&&(identical(other.grossArea, grossArea) || other.grossArea == grossArea)&&(identical(other.netArea, netArea) || other.netArea == netArea)&&(identical(other.orientation, orientation) || other.orientation == orientation)&&(identical(other.ceilingHeight, ceilingHeight) || other.ceilingHeight == ceilingHeight)&&(identical(other.decorationStatus, decorationStatus) || other.decorationStatus == decorationStatus)&&(identical(other.currentStatus, currentStatus) || other.currentStatus == currentStatus)&&(identical(other.isLeasable, isLeasable) || other.isLeasable == isLeasable)&&const DeepCollectionEquality().equals(other.extFields, extFields)&&(identical(other.currentContractId, currentContractId) || other.currentContractId == currentContractId)&&(identical(other.qrCode, qrCode) || other.qrCode == qrCode)&&(identical(other.marketRentReference, marketRentReference) || other.marketRentReference == marketRentReference)&&const DeepCollectionEquality().equals(other.predecessorUnitIds, predecessorUnitIds)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,buildingId,buildingName,floorId,floorName,unitNumber,propertyType,grossArea,netArea,orientation,ceilingHeight,decorationStatus,currentStatus,isLeasable,const DeepCollectionEquality().hash(extFields),currentContractId,qrCode,marketRentReference,const DeepCollectionEquality().hash(predecessorUnitIds),createdAt,updatedAt]);

@override
String toString() {
  return 'UnitDetailModel(id: $id, buildingId: $buildingId, buildingName: $buildingName, floorId: $floorId, floorName: $floorName, unitNumber: $unitNumber, propertyType: $propertyType, grossArea: $grossArea, netArea: $netArea, orientation: $orientation, ceilingHeight: $ceilingHeight, decorationStatus: $decorationStatus, currentStatus: $currentStatus, isLeasable: $isLeasable, extFields: $extFields, currentContractId: $currentContractId, qrCode: $qrCode, marketRentReference: $marketRentReference, predecessorUnitIds: $predecessorUnitIds, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $UnitDetailModelCopyWith<$Res>  {
  factory $UnitDetailModelCopyWith(UnitDetailModel value, $Res Function(UnitDetailModel) _then) = _$UnitDetailModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'building_id') String buildingId,@JsonKey(name: 'building_name') String buildingName,@JsonKey(name: 'floor_id') String floorId,@JsonKey(name: 'floor_name') String? floorName,@JsonKey(name: 'unit_number') String unitNumber,@JsonKey(name: 'property_type') String propertyType,@JsonKey(name: 'gross_area') double? grossArea,@JsonKey(name: 'net_area') double? netArea, String? orientation,@JsonKey(name: 'ceiling_height') double? ceilingHeight,@JsonKey(name: 'decoration_status') String decorationStatus,@JsonKey(name: 'current_status') String currentStatus,@JsonKey(name: 'is_leasable') bool isLeasable,@JsonKey(name: 'ext_fields') Map<String, dynamic>? extFields,@JsonKey(name: 'current_contract_id') String? currentContractId,@JsonKey(name: 'qr_code') String? qrCode,@JsonKey(name: 'market_rent_reference') double? marketRentReference,@JsonKey(name: 'predecessor_unit_ids', defaultValue: <String>[]) List<String> predecessorUnitIds,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'updated_at') String updatedAt
});




}
/// @nodoc
class _$UnitDetailModelCopyWithImpl<$Res>
    implements $UnitDetailModelCopyWith<$Res> {
  _$UnitDetailModelCopyWithImpl(this._self, this._then);

  final UnitDetailModel _self;
  final $Res Function(UnitDetailModel) _then;

/// Create a copy of UnitDetailModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? buildingId = null,Object? buildingName = null,Object? floorId = null,Object? floorName = freezed,Object? unitNumber = null,Object? propertyType = null,Object? grossArea = freezed,Object? netArea = freezed,Object? orientation = freezed,Object? ceilingHeight = freezed,Object? decorationStatus = null,Object? currentStatus = null,Object? isLeasable = null,Object? extFields = freezed,Object? currentContractId = freezed,Object? qrCode = freezed,Object? marketRentReference = freezed,Object? predecessorUnitIds = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,buildingId: null == buildingId ? _self.buildingId : buildingId // ignore: cast_nullable_to_non_nullable
as String,buildingName: null == buildingName ? _self.buildingName : buildingName // ignore: cast_nullable_to_non_nullable
as String,floorId: null == floorId ? _self.floorId : floorId // ignore: cast_nullable_to_non_nullable
as String,floorName: freezed == floorName ? _self.floorName : floorName // ignore: cast_nullable_to_non_nullable
as String?,unitNumber: null == unitNumber ? _self.unitNumber : unitNumber // ignore: cast_nullable_to_non_nullable
as String,propertyType: null == propertyType ? _self.propertyType : propertyType // ignore: cast_nullable_to_non_nullable
as String,grossArea: freezed == grossArea ? _self.grossArea : grossArea // ignore: cast_nullable_to_non_nullable
as double?,netArea: freezed == netArea ? _self.netArea : netArea // ignore: cast_nullable_to_non_nullable
as double?,orientation: freezed == orientation ? _self.orientation : orientation // ignore: cast_nullable_to_non_nullable
as String?,ceilingHeight: freezed == ceilingHeight ? _self.ceilingHeight : ceilingHeight // ignore: cast_nullable_to_non_nullable
as double?,decorationStatus: null == decorationStatus ? _self.decorationStatus : decorationStatus // ignore: cast_nullable_to_non_nullable
as String,currentStatus: null == currentStatus ? _self.currentStatus : currentStatus // ignore: cast_nullable_to_non_nullable
as String,isLeasable: null == isLeasable ? _self.isLeasable : isLeasable // ignore: cast_nullable_to_non_nullable
as bool,extFields: freezed == extFields ? _self.extFields : extFields // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,currentContractId: freezed == currentContractId ? _self.currentContractId : currentContractId // ignore: cast_nullable_to_non_nullable
as String?,qrCode: freezed == qrCode ? _self.qrCode : qrCode // ignore: cast_nullable_to_non_nullable
as String?,marketRentReference: freezed == marketRentReference ? _self.marketRentReference : marketRentReference // ignore: cast_nullable_to_non_nullable
as double?,predecessorUnitIds: null == predecessorUnitIds ? _self.predecessorUnitIds : predecessorUnitIds // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UnitDetailModel].
extension UnitDetailModelPatterns on UnitDetailModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UnitDetailModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UnitDetailModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UnitDetailModel value)  $default,){
final _that = this;
switch (_that) {
case _UnitDetailModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UnitDetailModel value)?  $default,){
final _that = this;
switch (_that) {
case _UnitDetailModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'building_id')  String buildingId, @JsonKey(name: 'building_name')  String buildingName, @JsonKey(name: 'floor_id')  String floorId, @JsonKey(name: 'floor_name')  String? floorName, @JsonKey(name: 'unit_number')  String unitNumber, @JsonKey(name: 'property_type')  String propertyType, @JsonKey(name: 'gross_area')  double? grossArea, @JsonKey(name: 'net_area')  double? netArea,  String? orientation, @JsonKey(name: 'ceiling_height')  double? ceilingHeight, @JsonKey(name: 'decoration_status')  String decorationStatus, @JsonKey(name: 'current_status')  String currentStatus, @JsonKey(name: 'is_leasable')  bool isLeasable, @JsonKey(name: 'ext_fields')  Map<String, dynamic>? extFields, @JsonKey(name: 'current_contract_id')  String? currentContractId, @JsonKey(name: 'qr_code')  String? qrCode, @JsonKey(name: 'market_rent_reference')  double? marketRentReference, @JsonKey(name: 'predecessor_unit_ids', defaultValue: <String>[])  List<String> predecessorUnitIds, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UnitDetailModel() when $default != null:
return $default(_that.id,_that.buildingId,_that.buildingName,_that.floorId,_that.floorName,_that.unitNumber,_that.propertyType,_that.grossArea,_that.netArea,_that.orientation,_that.ceilingHeight,_that.decorationStatus,_that.currentStatus,_that.isLeasable,_that.extFields,_that.currentContractId,_that.qrCode,_that.marketRentReference,_that.predecessorUnitIds,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'building_id')  String buildingId, @JsonKey(name: 'building_name')  String buildingName, @JsonKey(name: 'floor_id')  String floorId, @JsonKey(name: 'floor_name')  String? floorName, @JsonKey(name: 'unit_number')  String unitNumber, @JsonKey(name: 'property_type')  String propertyType, @JsonKey(name: 'gross_area')  double? grossArea, @JsonKey(name: 'net_area')  double? netArea,  String? orientation, @JsonKey(name: 'ceiling_height')  double? ceilingHeight, @JsonKey(name: 'decoration_status')  String decorationStatus, @JsonKey(name: 'current_status')  String currentStatus, @JsonKey(name: 'is_leasable')  bool isLeasable, @JsonKey(name: 'ext_fields')  Map<String, dynamic>? extFields, @JsonKey(name: 'current_contract_id')  String? currentContractId, @JsonKey(name: 'qr_code')  String? qrCode, @JsonKey(name: 'market_rent_reference')  double? marketRentReference, @JsonKey(name: 'predecessor_unit_ids', defaultValue: <String>[])  List<String> predecessorUnitIds, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt)  $default,) {final _that = this;
switch (_that) {
case _UnitDetailModel():
return $default(_that.id,_that.buildingId,_that.buildingName,_that.floorId,_that.floorName,_that.unitNumber,_that.propertyType,_that.grossArea,_that.netArea,_that.orientation,_that.ceilingHeight,_that.decorationStatus,_that.currentStatus,_that.isLeasable,_that.extFields,_that.currentContractId,_that.qrCode,_that.marketRentReference,_that.predecessorUnitIds,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'building_id')  String buildingId, @JsonKey(name: 'building_name')  String buildingName, @JsonKey(name: 'floor_id')  String floorId, @JsonKey(name: 'floor_name')  String? floorName, @JsonKey(name: 'unit_number')  String unitNumber, @JsonKey(name: 'property_type')  String propertyType, @JsonKey(name: 'gross_area')  double? grossArea, @JsonKey(name: 'net_area')  double? netArea,  String? orientation, @JsonKey(name: 'ceiling_height')  double? ceilingHeight, @JsonKey(name: 'decoration_status')  String decorationStatus, @JsonKey(name: 'current_status')  String currentStatus, @JsonKey(name: 'is_leasable')  bool isLeasable, @JsonKey(name: 'ext_fields')  Map<String, dynamic>? extFields, @JsonKey(name: 'current_contract_id')  String? currentContractId, @JsonKey(name: 'qr_code')  String? qrCode, @JsonKey(name: 'market_rent_reference')  double? marketRentReference, @JsonKey(name: 'predecessor_unit_ids', defaultValue: <String>[])  List<String> predecessorUnitIds, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _UnitDetailModel() when $default != null:
return $default(_that.id,_that.buildingId,_that.buildingName,_that.floorId,_that.floorName,_that.unitNumber,_that.propertyType,_that.grossArea,_that.netArea,_that.orientation,_that.ceilingHeight,_that.decorationStatus,_that.currentStatus,_that.isLeasable,_that.extFields,_that.currentContractId,_that.qrCode,_that.marketRentReference,_that.predecessorUnitIds,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UnitDetailModel implements UnitDetailModel {
  const _UnitDetailModel({required this.id, @JsonKey(name: 'building_id') required this.buildingId, @JsonKey(name: 'building_name') required this.buildingName, @JsonKey(name: 'floor_id') required this.floorId, @JsonKey(name: 'floor_name') this.floorName, @JsonKey(name: 'unit_number') required this.unitNumber, @JsonKey(name: 'property_type') required this.propertyType, @JsonKey(name: 'gross_area') this.grossArea, @JsonKey(name: 'net_area') this.netArea, this.orientation, @JsonKey(name: 'ceiling_height') this.ceilingHeight, @JsonKey(name: 'decoration_status') required this.decorationStatus, @JsonKey(name: 'current_status') required this.currentStatus, @JsonKey(name: 'is_leasable') required this.isLeasable, @JsonKey(name: 'ext_fields') final  Map<String, dynamic>? extFields, @JsonKey(name: 'current_contract_id') this.currentContractId, @JsonKey(name: 'qr_code') this.qrCode, @JsonKey(name: 'market_rent_reference') this.marketRentReference, @JsonKey(name: 'predecessor_unit_ids', defaultValue: <String>[]) final  List<String> predecessorUnitIds = const <String>[], @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt}): _extFields = extFields,_predecessorUnitIds = predecessorUnitIds;
  factory _UnitDetailModel.fromJson(Map<String, dynamic> json) => _$UnitDetailModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'building_id') final  String buildingId;
@override@JsonKey(name: 'building_name') final  String buildingName;
@override@JsonKey(name: 'floor_id') final  String floorId;
@override@JsonKey(name: 'floor_name') final  String? floorName;
@override@JsonKey(name: 'unit_number') final  String unitNumber;
@override@JsonKey(name: 'property_type') final  String propertyType;
@override@JsonKey(name: 'gross_area') final  double? grossArea;
@override@JsonKey(name: 'net_area') final  double? netArea;
@override final  String? orientation;
@override@JsonKey(name: 'ceiling_height') final  double? ceilingHeight;
@override@JsonKey(name: 'decoration_status') final  String decorationStatus;
@override@JsonKey(name: 'current_status') final  String currentStatus;
@override@JsonKey(name: 'is_leasable') final  bool isLeasable;
 final  Map<String, dynamic>? _extFields;
@override@JsonKey(name: 'ext_fields') Map<String, dynamic>? get extFields {
  final value = _extFields;
  if (value == null) return null;
  if (_extFields is EqualUnmodifiableMapView) return _extFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(name: 'current_contract_id') final  String? currentContractId;
@override@JsonKey(name: 'qr_code') final  String? qrCode;
@override@JsonKey(name: 'market_rent_reference') final  double? marketRentReference;
 final  List<String> _predecessorUnitIds;
@override@JsonKey(name: 'predecessor_unit_ids', defaultValue: <String>[]) List<String> get predecessorUnitIds {
  if (_predecessorUnitIds is EqualUnmodifiableListView) return _predecessorUnitIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_predecessorUnitIds);
}

@override@JsonKey(name: 'created_at') final  String createdAt;
@override@JsonKey(name: 'updated_at') final  String updatedAt;

/// Create a copy of UnitDetailModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnitDetailModelCopyWith<_UnitDetailModel> get copyWith => __$UnitDetailModelCopyWithImpl<_UnitDetailModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UnitDetailModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UnitDetailModel&&(identical(other.id, id) || other.id == id)&&(identical(other.buildingId, buildingId) || other.buildingId == buildingId)&&(identical(other.buildingName, buildingName) || other.buildingName == buildingName)&&(identical(other.floorId, floorId) || other.floorId == floorId)&&(identical(other.floorName, floorName) || other.floorName == floorName)&&(identical(other.unitNumber, unitNumber) || other.unitNumber == unitNumber)&&(identical(other.propertyType, propertyType) || other.propertyType == propertyType)&&(identical(other.grossArea, grossArea) || other.grossArea == grossArea)&&(identical(other.netArea, netArea) || other.netArea == netArea)&&(identical(other.orientation, orientation) || other.orientation == orientation)&&(identical(other.ceilingHeight, ceilingHeight) || other.ceilingHeight == ceilingHeight)&&(identical(other.decorationStatus, decorationStatus) || other.decorationStatus == decorationStatus)&&(identical(other.currentStatus, currentStatus) || other.currentStatus == currentStatus)&&(identical(other.isLeasable, isLeasable) || other.isLeasable == isLeasable)&&const DeepCollectionEquality().equals(other._extFields, _extFields)&&(identical(other.currentContractId, currentContractId) || other.currentContractId == currentContractId)&&(identical(other.qrCode, qrCode) || other.qrCode == qrCode)&&(identical(other.marketRentReference, marketRentReference) || other.marketRentReference == marketRentReference)&&const DeepCollectionEquality().equals(other._predecessorUnitIds, _predecessorUnitIds)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,buildingId,buildingName,floorId,floorName,unitNumber,propertyType,grossArea,netArea,orientation,ceilingHeight,decorationStatus,currentStatus,isLeasable,const DeepCollectionEquality().hash(_extFields),currentContractId,qrCode,marketRentReference,const DeepCollectionEquality().hash(_predecessorUnitIds),createdAt,updatedAt]);

@override
String toString() {
  return 'UnitDetailModel(id: $id, buildingId: $buildingId, buildingName: $buildingName, floorId: $floorId, floorName: $floorName, unitNumber: $unitNumber, propertyType: $propertyType, grossArea: $grossArea, netArea: $netArea, orientation: $orientation, ceilingHeight: $ceilingHeight, decorationStatus: $decorationStatus, currentStatus: $currentStatus, isLeasable: $isLeasable, extFields: $extFields, currentContractId: $currentContractId, qrCode: $qrCode, marketRentReference: $marketRentReference, predecessorUnitIds: $predecessorUnitIds, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$UnitDetailModelCopyWith<$Res> implements $UnitDetailModelCopyWith<$Res> {
  factory _$UnitDetailModelCopyWith(_UnitDetailModel value, $Res Function(_UnitDetailModel) _then) = __$UnitDetailModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'building_id') String buildingId,@JsonKey(name: 'building_name') String buildingName,@JsonKey(name: 'floor_id') String floorId,@JsonKey(name: 'floor_name') String? floorName,@JsonKey(name: 'unit_number') String unitNumber,@JsonKey(name: 'property_type') String propertyType,@JsonKey(name: 'gross_area') double? grossArea,@JsonKey(name: 'net_area') double? netArea, String? orientation,@JsonKey(name: 'ceiling_height') double? ceilingHeight,@JsonKey(name: 'decoration_status') String decorationStatus,@JsonKey(name: 'current_status') String currentStatus,@JsonKey(name: 'is_leasable') bool isLeasable,@JsonKey(name: 'ext_fields') Map<String, dynamic>? extFields,@JsonKey(name: 'current_contract_id') String? currentContractId,@JsonKey(name: 'qr_code') String? qrCode,@JsonKey(name: 'market_rent_reference') double? marketRentReference,@JsonKey(name: 'predecessor_unit_ids', defaultValue: <String>[]) List<String> predecessorUnitIds,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'updated_at') String updatedAt
});




}
/// @nodoc
class __$UnitDetailModelCopyWithImpl<$Res>
    implements _$UnitDetailModelCopyWith<$Res> {
  __$UnitDetailModelCopyWithImpl(this._self, this._then);

  final _UnitDetailModel _self;
  final $Res Function(_UnitDetailModel) _then;

/// Create a copy of UnitDetailModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? buildingId = null,Object? buildingName = null,Object? floorId = null,Object? floorName = freezed,Object? unitNumber = null,Object? propertyType = null,Object? grossArea = freezed,Object? netArea = freezed,Object? orientation = freezed,Object? ceilingHeight = freezed,Object? decorationStatus = null,Object? currentStatus = null,Object? isLeasable = null,Object? extFields = freezed,Object? currentContractId = freezed,Object? qrCode = freezed,Object? marketRentReference = freezed,Object? predecessorUnitIds = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_UnitDetailModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,buildingId: null == buildingId ? _self.buildingId : buildingId // ignore: cast_nullable_to_non_nullable
as String,buildingName: null == buildingName ? _self.buildingName : buildingName // ignore: cast_nullable_to_non_nullable
as String,floorId: null == floorId ? _self.floorId : floorId // ignore: cast_nullable_to_non_nullable
as String,floorName: freezed == floorName ? _self.floorName : floorName // ignore: cast_nullable_to_non_nullable
as String?,unitNumber: null == unitNumber ? _self.unitNumber : unitNumber // ignore: cast_nullable_to_non_nullable
as String,propertyType: null == propertyType ? _self.propertyType : propertyType // ignore: cast_nullable_to_non_nullable
as String,grossArea: freezed == grossArea ? _self.grossArea : grossArea // ignore: cast_nullable_to_non_nullable
as double?,netArea: freezed == netArea ? _self.netArea : netArea // ignore: cast_nullable_to_non_nullable
as double?,orientation: freezed == orientation ? _self.orientation : orientation // ignore: cast_nullable_to_non_nullable
as String?,ceilingHeight: freezed == ceilingHeight ? _self.ceilingHeight : ceilingHeight // ignore: cast_nullable_to_non_nullable
as double?,decorationStatus: null == decorationStatus ? _self.decorationStatus : decorationStatus // ignore: cast_nullable_to_non_nullable
as String,currentStatus: null == currentStatus ? _self.currentStatus : currentStatus // ignore: cast_nullable_to_non_nullable
as String,isLeasable: null == isLeasable ? _self.isLeasable : isLeasable // ignore: cast_nullable_to_non_nullable
as bool,extFields: freezed == extFields ? _self._extFields : extFields // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,currentContractId: freezed == currentContractId ? _self.currentContractId : currentContractId // ignore: cast_nullable_to_non_nullable
as String?,qrCode: freezed == qrCode ? _self.qrCode : qrCode // ignore: cast_nullable_to_non_nullable
as String?,marketRentReference: freezed == marketRentReference ? _self.marketRentReference : marketRentReference // ignore: cast_nullable_to_non_nullable
as double?,predecessorUnitIds: null == predecessorUnitIds ? _self._predecessorUnitIds : predecessorUnitIds // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
