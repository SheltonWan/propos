// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UnitSummary {

 String get id; String get buildingId; String get buildingName; String get floorId; String? get floorName; String get unitNumber; PropertyType get propertyType; double? get grossArea; double? get netArea; UnitStatus get currentStatus; bool get isLeasable; DecorationStatus get decorationStatus; double? get marketRentReference; DateTime get createdAt;
/// Create a copy of UnitSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnitSummaryCopyWith<UnitSummary> get copyWith => _$UnitSummaryCopyWithImpl<UnitSummary>(this as UnitSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnitSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.buildingId, buildingId) || other.buildingId == buildingId)&&(identical(other.buildingName, buildingName) || other.buildingName == buildingName)&&(identical(other.floorId, floorId) || other.floorId == floorId)&&(identical(other.floorName, floorName) || other.floorName == floorName)&&(identical(other.unitNumber, unitNumber) || other.unitNumber == unitNumber)&&(identical(other.propertyType, propertyType) || other.propertyType == propertyType)&&(identical(other.grossArea, grossArea) || other.grossArea == grossArea)&&(identical(other.netArea, netArea) || other.netArea == netArea)&&(identical(other.currentStatus, currentStatus) || other.currentStatus == currentStatus)&&(identical(other.isLeasable, isLeasable) || other.isLeasable == isLeasable)&&(identical(other.decorationStatus, decorationStatus) || other.decorationStatus == decorationStatus)&&(identical(other.marketRentReference, marketRentReference) || other.marketRentReference == marketRentReference)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,buildingId,buildingName,floorId,floorName,unitNumber,propertyType,grossArea,netArea,currentStatus,isLeasable,decorationStatus,marketRentReference,createdAt);

@override
String toString() {
  return 'UnitSummary(id: $id, buildingId: $buildingId, buildingName: $buildingName, floorId: $floorId, floorName: $floorName, unitNumber: $unitNumber, propertyType: $propertyType, grossArea: $grossArea, netArea: $netArea, currentStatus: $currentStatus, isLeasable: $isLeasable, decorationStatus: $decorationStatus, marketRentReference: $marketRentReference, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $UnitSummaryCopyWith<$Res>  {
  factory $UnitSummaryCopyWith(UnitSummary value, $Res Function(UnitSummary) _then) = _$UnitSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String buildingId, String buildingName, String floorId, String? floorName, String unitNumber, PropertyType propertyType, double? grossArea, double? netArea, UnitStatus currentStatus, bool isLeasable, DecorationStatus decorationStatus, double? marketRentReference, DateTime createdAt
});




}
/// @nodoc
class _$UnitSummaryCopyWithImpl<$Res>
    implements $UnitSummaryCopyWith<$Res> {
  _$UnitSummaryCopyWithImpl(this._self, this._then);

  final UnitSummary _self;
  final $Res Function(UnitSummary) _then;

/// Create a copy of UnitSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? buildingId = null,Object? buildingName = null,Object? floorId = null,Object? floorName = freezed,Object? unitNumber = null,Object? propertyType = null,Object? grossArea = freezed,Object? netArea = freezed,Object? currentStatus = null,Object? isLeasable = null,Object? decorationStatus = null,Object? marketRentReference = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,buildingId: null == buildingId ? _self.buildingId : buildingId // ignore: cast_nullable_to_non_nullable
as String,buildingName: null == buildingName ? _self.buildingName : buildingName // ignore: cast_nullable_to_non_nullable
as String,floorId: null == floorId ? _self.floorId : floorId // ignore: cast_nullable_to_non_nullable
as String,floorName: freezed == floorName ? _self.floorName : floorName // ignore: cast_nullable_to_non_nullable
as String?,unitNumber: null == unitNumber ? _self.unitNumber : unitNumber // ignore: cast_nullable_to_non_nullable
as String,propertyType: null == propertyType ? _self.propertyType : propertyType // ignore: cast_nullable_to_non_nullable
as PropertyType,grossArea: freezed == grossArea ? _self.grossArea : grossArea // ignore: cast_nullable_to_non_nullable
as double?,netArea: freezed == netArea ? _self.netArea : netArea // ignore: cast_nullable_to_non_nullable
as double?,currentStatus: null == currentStatus ? _self.currentStatus : currentStatus // ignore: cast_nullable_to_non_nullable
as UnitStatus,isLeasable: null == isLeasable ? _self.isLeasable : isLeasable // ignore: cast_nullable_to_non_nullable
as bool,decorationStatus: null == decorationStatus ? _self.decorationStatus : decorationStatus // ignore: cast_nullable_to_non_nullable
as DecorationStatus,marketRentReference: freezed == marketRentReference ? _self.marketRentReference : marketRentReference // ignore: cast_nullable_to_non_nullable
as double?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [UnitSummary].
extension UnitSummaryPatterns on UnitSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UnitSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UnitSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UnitSummary value)  $default,){
final _that = this;
switch (_that) {
case _UnitSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UnitSummary value)?  $default,){
final _that = this;
switch (_that) {
case _UnitSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String buildingId,  String buildingName,  String floorId,  String? floorName,  String unitNumber,  PropertyType propertyType,  double? grossArea,  double? netArea,  UnitStatus currentStatus,  bool isLeasable,  DecorationStatus decorationStatus,  double? marketRentReference,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UnitSummary() when $default != null:
return $default(_that.id,_that.buildingId,_that.buildingName,_that.floorId,_that.floorName,_that.unitNumber,_that.propertyType,_that.grossArea,_that.netArea,_that.currentStatus,_that.isLeasable,_that.decorationStatus,_that.marketRentReference,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String buildingId,  String buildingName,  String floorId,  String? floorName,  String unitNumber,  PropertyType propertyType,  double? grossArea,  double? netArea,  UnitStatus currentStatus,  bool isLeasable,  DecorationStatus decorationStatus,  double? marketRentReference,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _UnitSummary():
return $default(_that.id,_that.buildingId,_that.buildingName,_that.floorId,_that.floorName,_that.unitNumber,_that.propertyType,_that.grossArea,_that.netArea,_that.currentStatus,_that.isLeasable,_that.decorationStatus,_that.marketRentReference,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String buildingId,  String buildingName,  String floorId,  String? floorName,  String unitNumber,  PropertyType propertyType,  double? grossArea,  double? netArea,  UnitStatus currentStatus,  bool isLeasable,  DecorationStatus decorationStatus,  double? marketRentReference,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _UnitSummary() when $default != null:
return $default(_that.id,_that.buildingId,_that.buildingName,_that.floorId,_that.floorName,_that.unitNumber,_that.propertyType,_that.grossArea,_that.netArea,_that.currentStatus,_that.isLeasable,_that.decorationStatus,_that.marketRentReference,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _UnitSummary implements UnitSummary {
  const _UnitSummary({required this.id, required this.buildingId, required this.buildingName, required this.floorId, this.floorName, required this.unitNumber, required this.propertyType, this.grossArea, this.netArea, required this.currentStatus, required this.isLeasable, required this.decorationStatus, this.marketRentReference, required this.createdAt});
  

@override final  String id;
@override final  String buildingId;
@override final  String buildingName;
@override final  String floorId;
@override final  String? floorName;
@override final  String unitNumber;
@override final  PropertyType propertyType;
@override final  double? grossArea;
@override final  double? netArea;
@override final  UnitStatus currentStatus;
@override final  bool isLeasable;
@override final  DecorationStatus decorationStatus;
@override final  double? marketRentReference;
@override final  DateTime createdAt;

/// Create a copy of UnitSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnitSummaryCopyWith<_UnitSummary> get copyWith => __$UnitSummaryCopyWithImpl<_UnitSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UnitSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.buildingId, buildingId) || other.buildingId == buildingId)&&(identical(other.buildingName, buildingName) || other.buildingName == buildingName)&&(identical(other.floorId, floorId) || other.floorId == floorId)&&(identical(other.floorName, floorName) || other.floorName == floorName)&&(identical(other.unitNumber, unitNumber) || other.unitNumber == unitNumber)&&(identical(other.propertyType, propertyType) || other.propertyType == propertyType)&&(identical(other.grossArea, grossArea) || other.grossArea == grossArea)&&(identical(other.netArea, netArea) || other.netArea == netArea)&&(identical(other.currentStatus, currentStatus) || other.currentStatus == currentStatus)&&(identical(other.isLeasable, isLeasable) || other.isLeasable == isLeasable)&&(identical(other.decorationStatus, decorationStatus) || other.decorationStatus == decorationStatus)&&(identical(other.marketRentReference, marketRentReference) || other.marketRentReference == marketRentReference)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,buildingId,buildingName,floorId,floorName,unitNumber,propertyType,grossArea,netArea,currentStatus,isLeasable,decorationStatus,marketRentReference,createdAt);

@override
String toString() {
  return 'UnitSummary(id: $id, buildingId: $buildingId, buildingName: $buildingName, floorId: $floorId, floorName: $floorName, unitNumber: $unitNumber, propertyType: $propertyType, grossArea: $grossArea, netArea: $netArea, currentStatus: $currentStatus, isLeasable: $isLeasable, decorationStatus: $decorationStatus, marketRentReference: $marketRentReference, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$UnitSummaryCopyWith<$Res> implements $UnitSummaryCopyWith<$Res> {
  factory _$UnitSummaryCopyWith(_UnitSummary value, $Res Function(_UnitSummary) _then) = __$UnitSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String buildingId, String buildingName, String floorId, String? floorName, String unitNumber, PropertyType propertyType, double? grossArea, double? netArea, UnitStatus currentStatus, bool isLeasable, DecorationStatus decorationStatus, double? marketRentReference, DateTime createdAt
});




}
/// @nodoc
class __$UnitSummaryCopyWithImpl<$Res>
    implements _$UnitSummaryCopyWith<$Res> {
  __$UnitSummaryCopyWithImpl(this._self, this._then);

  final _UnitSummary _self;
  final $Res Function(_UnitSummary) _then;

/// Create a copy of UnitSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? buildingId = null,Object? buildingName = null,Object? floorId = null,Object? floorName = freezed,Object? unitNumber = null,Object? propertyType = null,Object? grossArea = freezed,Object? netArea = freezed,Object? currentStatus = null,Object? isLeasable = null,Object? decorationStatus = null,Object? marketRentReference = freezed,Object? createdAt = null,}) {
  return _then(_UnitSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,buildingId: null == buildingId ? _self.buildingId : buildingId // ignore: cast_nullable_to_non_nullable
as String,buildingName: null == buildingName ? _self.buildingName : buildingName // ignore: cast_nullable_to_non_nullable
as String,floorId: null == floorId ? _self.floorId : floorId // ignore: cast_nullable_to_non_nullable
as String,floorName: freezed == floorName ? _self.floorName : floorName // ignore: cast_nullable_to_non_nullable
as String?,unitNumber: null == unitNumber ? _self.unitNumber : unitNumber // ignore: cast_nullable_to_non_nullable
as String,propertyType: null == propertyType ? _self.propertyType : propertyType // ignore: cast_nullable_to_non_nullable
as PropertyType,grossArea: freezed == grossArea ? _self.grossArea : grossArea // ignore: cast_nullable_to_non_nullable
as double?,netArea: freezed == netArea ? _self.netArea : netArea // ignore: cast_nullable_to_non_nullable
as double?,currentStatus: null == currentStatus ? _self.currentStatus : currentStatus // ignore: cast_nullable_to_non_nullable
as UnitStatus,isLeasable: null == isLeasable ? _self.isLeasable : isLeasable // ignore: cast_nullable_to_non_nullable
as bool,decorationStatus: null == decorationStatus ? _self.decorationStatus : decorationStatus // ignore: cast_nullable_to_non_nullable
as DecorationStatus,marketRentReference: freezed == marketRentReference ? _self.marketRentReference : marketRentReference // ignore: cast_nullable_to_non_nullable
as double?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$UnitDetail {

 String get id; String get buildingId; String get buildingName; String get floorId; String? get floorName; String get unitNumber; PropertyType get propertyType; double? get grossArea; double? get netArea; String? get orientation; double? get ceilingHeight; DecorationStatus get decorationStatus; UnitStatus get currentStatus; bool get isLeasable; Map<String, dynamic>? get extFields; String? get currentContractId; String? get qrCode; double? get marketRentReference; List<String> get predecessorUnitIds; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of UnitDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnitDetailCopyWith<UnitDetail> get copyWith => _$UnitDetailCopyWithImpl<UnitDetail>(this as UnitDetail, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnitDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.buildingId, buildingId) || other.buildingId == buildingId)&&(identical(other.buildingName, buildingName) || other.buildingName == buildingName)&&(identical(other.floorId, floorId) || other.floorId == floorId)&&(identical(other.floorName, floorName) || other.floorName == floorName)&&(identical(other.unitNumber, unitNumber) || other.unitNumber == unitNumber)&&(identical(other.propertyType, propertyType) || other.propertyType == propertyType)&&(identical(other.grossArea, grossArea) || other.grossArea == grossArea)&&(identical(other.netArea, netArea) || other.netArea == netArea)&&(identical(other.orientation, orientation) || other.orientation == orientation)&&(identical(other.ceilingHeight, ceilingHeight) || other.ceilingHeight == ceilingHeight)&&(identical(other.decorationStatus, decorationStatus) || other.decorationStatus == decorationStatus)&&(identical(other.currentStatus, currentStatus) || other.currentStatus == currentStatus)&&(identical(other.isLeasable, isLeasable) || other.isLeasable == isLeasable)&&const DeepCollectionEquality().equals(other.extFields, extFields)&&(identical(other.currentContractId, currentContractId) || other.currentContractId == currentContractId)&&(identical(other.qrCode, qrCode) || other.qrCode == qrCode)&&(identical(other.marketRentReference, marketRentReference) || other.marketRentReference == marketRentReference)&&const DeepCollectionEquality().equals(other.predecessorUnitIds, predecessorUnitIds)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,buildingId,buildingName,floorId,floorName,unitNumber,propertyType,grossArea,netArea,orientation,ceilingHeight,decorationStatus,currentStatus,isLeasable,const DeepCollectionEquality().hash(extFields),currentContractId,qrCode,marketRentReference,const DeepCollectionEquality().hash(predecessorUnitIds),createdAt,updatedAt]);

@override
String toString() {
  return 'UnitDetail(id: $id, buildingId: $buildingId, buildingName: $buildingName, floorId: $floorId, floorName: $floorName, unitNumber: $unitNumber, propertyType: $propertyType, grossArea: $grossArea, netArea: $netArea, orientation: $orientation, ceilingHeight: $ceilingHeight, decorationStatus: $decorationStatus, currentStatus: $currentStatus, isLeasable: $isLeasable, extFields: $extFields, currentContractId: $currentContractId, qrCode: $qrCode, marketRentReference: $marketRentReference, predecessorUnitIds: $predecessorUnitIds, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $UnitDetailCopyWith<$Res>  {
  factory $UnitDetailCopyWith(UnitDetail value, $Res Function(UnitDetail) _then) = _$UnitDetailCopyWithImpl;
@useResult
$Res call({
 String id, String buildingId, String buildingName, String floorId, String? floorName, String unitNumber, PropertyType propertyType, double? grossArea, double? netArea, String? orientation, double? ceilingHeight, DecorationStatus decorationStatus, UnitStatus currentStatus, bool isLeasable, Map<String, dynamic>? extFields, String? currentContractId, String? qrCode, double? marketRentReference, List<String> predecessorUnitIds, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$UnitDetailCopyWithImpl<$Res>
    implements $UnitDetailCopyWith<$Res> {
  _$UnitDetailCopyWithImpl(this._self, this._then);

  final UnitDetail _self;
  final $Res Function(UnitDetail) _then;

/// Create a copy of UnitDetail
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
as PropertyType,grossArea: freezed == grossArea ? _self.grossArea : grossArea // ignore: cast_nullable_to_non_nullable
as double?,netArea: freezed == netArea ? _self.netArea : netArea // ignore: cast_nullable_to_non_nullable
as double?,orientation: freezed == orientation ? _self.orientation : orientation // ignore: cast_nullable_to_non_nullable
as String?,ceilingHeight: freezed == ceilingHeight ? _self.ceilingHeight : ceilingHeight // ignore: cast_nullable_to_non_nullable
as double?,decorationStatus: null == decorationStatus ? _self.decorationStatus : decorationStatus // ignore: cast_nullable_to_non_nullable
as DecorationStatus,currentStatus: null == currentStatus ? _self.currentStatus : currentStatus // ignore: cast_nullable_to_non_nullable
as UnitStatus,isLeasable: null == isLeasable ? _self.isLeasable : isLeasable // ignore: cast_nullable_to_non_nullable
as bool,extFields: freezed == extFields ? _self.extFields : extFields // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,currentContractId: freezed == currentContractId ? _self.currentContractId : currentContractId // ignore: cast_nullable_to_non_nullable
as String?,qrCode: freezed == qrCode ? _self.qrCode : qrCode // ignore: cast_nullable_to_non_nullable
as String?,marketRentReference: freezed == marketRentReference ? _self.marketRentReference : marketRentReference // ignore: cast_nullable_to_non_nullable
as double?,predecessorUnitIds: null == predecessorUnitIds ? _self.predecessorUnitIds : predecessorUnitIds // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [UnitDetail].
extension UnitDetailPatterns on UnitDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UnitDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UnitDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UnitDetail value)  $default,){
final _that = this;
switch (_that) {
case _UnitDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UnitDetail value)?  $default,){
final _that = this;
switch (_that) {
case _UnitDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String buildingId,  String buildingName,  String floorId,  String? floorName,  String unitNumber,  PropertyType propertyType,  double? grossArea,  double? netArea,  String? orientation,  double? ceilingHeight,  DecorationStatus decorationStatus,  UnitStatus currentStatus,  bool isLeasable,  Map<String, dynamic>? extFields,  String? currentContractId,  String? qrCode,  double? marketRentReference,  List<String> predecessorUnitIds,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UnitDetail() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String buildingId,  String buildingName,  String floorId,  String? floorName,  String unitNumber,  PropertyType propertyType,  double? grossArea,  double? netArea,  String? orientation,  double? ceilingHeight,  DecorationStatus decorationStatus,  UnitStatus currentStatus,  bool isLeasable,  Map<String, dynamic>? extFields,  String? currentContractId,  String? qrCode,  double? marketRentReference,  List<String> predecessorUnitIds,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _UnitDetail():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String buildingId,  String buildingName,  String floorId,  String? floorName,  String unitNumber,  PropertyType propertyType,  double? grossArea,  double? netArea,  String? orientation,  double? ceilingHeight,  DecorationStatus decorationStatus,  UnitStatus currentStatus,  bool isLeasable,  Map<String, dynamic>? extFields,  String? currentContractId,  String? qrCode,  double? marketRentReference,  List<String> predecessorUnitIds,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _UnitDetail() when $default != null:
return $default(_that.id,_that.buildingId,_that.buildingName,_that.floorId,_that.floorName,_that.unitNumber,_that.propertyType,_that.grossArea,_that.netArea,_that.orientation,_that.ceilingHeight,_that.decorationStatus,_that.currentStatus,_that.isLeasable,_that.extFields,_that.currentContractId,_that.qrCode,_that.marketRentReference,_that.predecessorUnitIds,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _UnitDetail implements UnitDetail {
  const _UnitDetail({required this.id, required this.buildingId, required this.buildingName, required this.floorId, this.floorName, required this.unitNumber, required this.propertyType, this.grossArea, this.netArea, this.orientation, this.ceilingHeight, required this.decorationStatus, required this.currentStatus, required this.isLeasable, final  Map<String, dynamic>? extFields, this.currentContractId, this.qrCode, this.marketRentReference, final  List<String> predecessorUnitIds = const [], required this.createdAt, required this.updatedAt}): _extFields = extFields,_predecessorUnitIds = predecessorUnitIds;
  

@override final  String id;
@override final  String buildingId;
@override final  String buildingName;
@override final  String floorId;
@override final  String? floorName;
@override final  String unitNumber;
@override final  PropertyType propertyType;
@override final  double? grossArea;
@override final  double? netArea;
@override final  String? orientation;
@override final  double? ceilingHeight;
@override final  DecorationStatus decorationStatus;
@override final  UnitStatus currentStatus;
@override final  bool isLeasable;
 final  Map<String, dynamic>? _extFields;
@override Map<String, dynamic>? get extFields {
  final value = _extFields;
  if (value == null) return null;
  if (_extFields is EqualUnmodifiableMapView) return _extFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  String? currentContractId;
@override final  String? qrCode;
@override final  double? marketRentReference;
 final  List<String> _predecessorUnitIds;
@override@JsonKey() List<String> get predecessorUnitIds {
  if (_predecessorUnitIds is EqualUnmodifiableListView) return _predecessorUnitIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_predecessorUnitIds);
}

@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of UnitDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnitDetailCopyWith<_UnitDetail> get copyWith => __$UnitDetailCopyWithImpl<_UnitDetail>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UnitDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.buildingId, buildingId) || other.buildingId == buildingId)&&(identical(other.buildingName, buildingName) || other.buildingName == buildingName)&&(identical(other.floorId, floorId) || other.floorId == floorId)&&(identical(other.floorName, floorName) || other.floorName == floorName)&&(identical(other.unitNumber, unitNumber) || other.unitNumber == unitNumber)&&(identical(other.propertyType, propertyType) || other.propertyType == propertyType)&&(identical(other.grossArea, grossArea) || other.grossArea == grossArea)&&(identical(other.netArea, netArea) || other.netArea == netArea)&&(identical(other.orientation, orientation) || other.orientation == orientation)&&(identical(other.ceilingHeight, ceilingHeight) || other.ceilingHeight == ceilingHeight)&&(identical(other.decorationStatus, decorationStatus) || other.decorationStatus == decorationStatus)&&(identical(other.currentStatus, currentStatus) || other.currentStatus == currentStatus)&&(identical(other.isLeasable, isLeasable) || other.isLeasable == isLeasable)&&const DeepCollectionEquality().equals(other._extFields, _extFields)&&(identical(other.currentContractId, currentContractId) || other.currentContractId == currentContractId)&&(identical(other.qrCode, qrCode) || other.qrCode == qrCode)&&(identical(other.marketRentReference, marketRentReference) || other.marketRentReference == marketRentReference)&&const DeepCollectionEquality().equals(other._predecessorUnitIds, _predecessorUnitIds)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,buildingId,buildingName,floorId,floorName,unitNumber,propertyType,grossArea,netArea,orientation,ceilingHeight,decorationStatus,currentStatus,isLeasable,const DeepCollectionEquality().hash(_extFields),currentContractId,qrCode,marketRentReference,const DeepCollectionEquality().hash(_predecessorUnitIds),createdAt,updatedAt]);

@override
String toString() {
  return 'UnitDetail(id: $id, buildingId: $buildingId, buildingName: $buildingName, floorId: $floorId, floorName: $floorName, unitNumber: $unitNumber, propertyType: $propertyType, grossArea: $grossArea, netArea: $netArea, orientation: $orientation, ceilingHeight: $ceilingHeight, decorationStatus: $decorationStatus, currentStatus: $currentStatus, isLeasable: $isLeasable, extFields: $extFields, currentContractId: $currentContractId, qrCode: $qrCode, marketRentReference: $marketRentReference, predecessorUnitIds: $predecessorUnitIds, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$UnitDetailCopyWith<$Res> implements $UnitDetailCopyWith<$Res> {
  factory _$UnitDetailCopyWith(_UnitDetail value, $Res Function(_UnitDetail) _then) = __$UnitDetailCopyWithImpl;
@override @useResult
$Res call({
 String id, String buildingId, String buildingName, String floorId, String? floorName, String unitNumber, PropertyType propertyType, double? grossArea, double? netArea, String? orientation, double? ceilingHeight, DecorationStatus decorationStatus, UnitStatus currentStatus, bool isLeasable, Map<String, dynamic>? extFields, String? currentContractId, String? qrCode, double? marketRentReference, List<String> predecessorUnitIds, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$UnitDetailCopyWithImpl<$Res>
    implements _$UnitDetailCopyWith<$Res> {
  __$UnitDetailCopyWithImpl(this._self, this._then);

  final _UnitDetail _self;
  final $Res Function(_UnitDetail) _then;

/// Create a copy of UnitDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? buildingId = null,Object? buildingName = null,Object? floorId = null,Object? floorName = freezed,Object? unitNumber = null,Object? propertyType = null,Object? grossArea = freezed,Object? netArea = freezed,Object? orientation = freezed,Object? ceilingHeight = freezed,Object? decorationStatus = null,Object? currentStatus = null,Object? isLeasable = null,Object? extFields = freezed,Object? currentContractId = freezed,Object? qrCode = freezed,Object? marketRentReference = freezed,Object? predecessorUnitIds = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_UnitDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,buildingId: null == buildingId ? _self.buildingId : buildingId // ignore: cast_nullable_to_non_nullable
as String,buildingName: null == buildingName ? _self.buildingName : buildingName // ignore: cast_nullable_to_non_nullable
as String,floorId: null == floorId ? _self.floorId : floorId // ignore: cast_nullable_to_non_nullable
as String,floorName: freezed == floorName ? _self.floorName : floorName // ignore: cast_nullable_to_non_nullable
as String?,unitNumber: null == unitNumber ? _self.unitNumber : unitNumber // ignore: cast_nullable_to_non_nullable
as String,propertyType: null == propertyType ? _self.propertyType : propertyType // ignore: cast_nullable_to_non_nullable
as PropertyType,grossArea: freezed == grossArea ? _self.grossArea : grossArea // ignore: cast_nullable_to_non_nullable
as double?,netArea: freezed == netArea ? _self.netArea : netArea // ignore: cast_nullable_to_non_nullable
as double?,orientation: freezed == orientation ? _self.orientation : orientation // ignore: cast_nullable_to_non_nullable
as String?,ceilingHeight: freezed == ceilingHeight ? _self.ceilingHeight : ceilingHeight // ignore: cast_nullable_to_non_nullable
as double?,decorationStatus: null == decorationStatus ? _self.decorationStatus : decorationStatus // ignore: cast_nullable_to_non_nullable
as DecorationStatus,currentStatus: null == currentStatus ? _self.currentStatus : currentStatus // ignore: cast_nullable_to_non_nullable
as UnitStatus,isLeasable: null == isLeasable ? _self.isLeasable : isLeasable // ignore: cast_nullable_to_non_nullable
as bool,extFields: freezed == extFields ? _self._extFields : extFields // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,currentContractId: freezed == currentContractId ? _self.currentContractId : currentContractId // ignore: cast_nullable_to_non_nullable
as String?,qrCode: freezed == qrCode ? _self.qrCode : qrCode // ignore: cast_nullable_to_non_nullable
as String?,marketRentReference: freezed == marketRentReference ? _self.marketRentReference : marketRentReference // ignore: cast_nullable_to_non_nullable
as double?,predecessorUnitIds: null == predecessorUnitIds ? _self._predecessorUnitIds : predecessorUnitIds // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
