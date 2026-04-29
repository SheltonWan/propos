// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'asset_overview_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PropertyTypeStatsModel {

@JsonKey(name: 'property_type') String get propertyType;@JsonKey(name: 'total_units') int get totalUnits;@JsonKey(name: 'leased_units') int get leasedUnits;@JsonKey(name: 'vacant_units') int get vacantUnits;@JsonKey(name: 'expiring_soon_units') int get expiringSoonUnits;@JsonKey(name: 'occupancy_rate') double get occupancyRate;@JsonKey(name: 'total_nla') double get totalNla;@JsonKey(name: 'leased_nla') double get leasedNla;
/// Create a copy of PropertyTypeStatsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PropertyTypeStatsModelCopyWith<PropertyTypeStatsModel> get copyWith => _$PropertyTypeStatsModelCopyWithImpl<PropertyTypeStatsModel>(this as PropertyTypeStatsModel, _$identity);

  /// Serializes this PropertyTypeStatsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PropertyTypeStatsModel&&(identical(other.propertyType, propertyType) || other.propertyType == propertyType)&&(identical(other.totalUnits, totalUnits) || other.totalUnits == totalUnits)&&(identical(other.leasedUnits, leasedUnits) || other.leasedUnits == leasedUnits)&&(identical(other.vacantUnits, vacantUnits) || other.vacantUnits == vacantUnits)&&(identical(other.expiringSoonUnits, expiringSoonUnits) || other.expiringSoonUnits == expiringSoonUnits)&&(identical(other.occupancyRate, occupancyRate) || other.occupancyRate == occupancyRate)&&(identical(other.totalNla, totalNla) || other.totalNla == totalNla)&&(identical(other.leasedNla, leasedNla) || other.leasedNla == leasedNla));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,propertyType,totalUnits,leasedUnits,vacantUnits,expiringSoonUnits,occupancyRate,totalNla,leasedNla);

@override
String toString() {
  return 'PropertyTypeStatsModel(propertyType: $propertyType, totalUnits: $totalUnits, leasedUnits: $leasedUnits, vacantUnits: $vacantUnits, expiringSoonUnits: $expiringSoonUnits, occupancyRate: $occupancyRate, totalNla: $totalNla, leasedNla: $leasedNla)';
}


}

/// @nodoc
abstract mixin class $PropertyTypeStatsModelCopyWith<$Res>  {
  factory $PropertyTypeStatsModelCopyWith(PropertyTypeStatsModel value, $Res Function(PropertyTypeStatsModel) _then) = _$PropertyTypeStatsModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'property_type') String propertyType,@JsonKey(name: 'total_units') int totalUnits,@JsonKey(name: 'leased_units') int leasedUnits,@JsonKey(name: 'vacant_units') int vacantUnits,@JsonKey(name: 'expiring_soon_units') int expiringSoonUnits,@JsonKey(name: 'occupancy_rate') double occupancyRate,@JsonKey(name: 'total_nla') double totalNla,@JsonKey(name: 'leased_nla') double leasedNla
});




}
/// @nodoc
class _$PropertyTypeStatsModelCopyWithImpl<$Res>
    implements $PropertyTypeStatsModelCopyWith<$Res> {
  _$PropertyTypeStatsModelCopyWithImpl(this._self, this._then);

  final PropertyTypeStatsModel _self;
  final $Res Function(PropertyTypeStatsModel) _then;

/// Create a copy of PropertyTypeStatsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? propertyType = null,Object? totalUnits = null,Object? leasedUnits = null,Object? vacantUnits = null,Object? expiringSoonUnits = null,Object? occupancyRate = null,Object? totalNla = null,Object? leasedNla = null,}) {
  return _then(_self.copyWith(
propertyType: null == propertyType ? _self.propertyType : propertyType // ignore: cast_nullable_to_non_nullable
as String,totalUnits: null == totalUnits ? _self.totalUnits : totalUnits // ignore: cast_nullable_to_non_nullable
as int,leasedUnits: null == leasedUnits ? _self.leasedUnits : leasedUnits // ignore: cast_nullable_to_non_nullable
as int,vacantUnits: null == vacantUnits ? _self.vacantUnits : vacantUnits // ignore: cast_nullable_to_non_nullable
as int,expiringSoonUnits: null == expiringSoonUnits ? _self.expiringSoonUnits : expiringSoonUnits // ignore: cast_nullable_to_non_nullable
as int,occupancyRate: null == occupancyRate ? _self.occupancyRate : occupancyRate // ignore: cast_nullable_to_non_nullable
as double,totalNla: null == totalNla ? _self.totalNla : totalNla // ignore: cast_nullable_to_non_nullable
as double,leasedNla: null == leasedNla ? _self.leasedNla : leasedNla // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [PropertyTypeStatsModel].
extension PropertyTypeStatsModelPatterns on PropertyTypeStatsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PropertyTypeStatsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PropertyTypeStatsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PropertyTypeStatsModel value)  $default,){
final _that = this;
switch (_that) {
case _PropertyTypeStatsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PropertyTypeStatsModel value)?  $default,){
final _that = this;
switch (_that) {
case _PropertyTypeStatsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'property_type')  String propertyType, @JsonKey(name: 'total_units')  int totalUnits, @JsonKey(name: 'leased_units')  int leasedUnits, @JsonKey(name: 'vacant_units')  int vacantUnits, @JsonKey(name: 'expiring_soon_units')  int expiringSoonUnits, @JsonKey(name: 'occupancy_rate')  double occupancyRate, @JsonKey(name: 'total_nla')  double totalNla, @JsonKey(name: 'leased_nla')  double leasedNla)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PropertyTypeStatsModel() when $default != null:
return $default(_that.propertyType,_that.totalUnits,_that.leasedUnits,_that.vacantUnits,_that.expiringSoonUnits,_that.occupancyRate,_that.totalNla,_that.leasedNla);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'property_type')  String propertyType, @JsonKey(name: 'total_units')  int totalUnits, @JsonKey(name: 'leased_units')  int leasedUnits, @JsonKey(name: 'vacant_units')  int vacantUnits, @JsonKey(name: 'expiring_soon_units')  int expiringSoonUnits, @JsonKey(name: 'occupancy_rate')  double occupancyRate, @JsonKey(name: 'total_nla')  double totalNla, @JsonKey(name: 'leased_nla')  double leasedNla)  $default,) {final _that = this;
switch (_that) {
case _PropertyTypeStatsModel():
return $default(_that.propertyType,_that.totalUnits,_that.leasedUnits,_that.vacantUnits,_that.expiringSoonUnits,_that.occupancyRate,_that.totalNla,_that.leasedNla);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'property_type')  String propertyType, @JsonKey(name: 'total_units')  int totalUnits, @JsonKey(name: 'leased_units')  int leasedUnits, @JsonKey(name: 'vacant_units')  int vacantUnits, @JsonKey(name: 'expiring_soon_units')  int expiringSoonUnits, @JsonKey(name: 'occupancy_rate')  double occupancyRate, @JsonKey(name: 'total_nla')  double totalNla, @JsonKey(name: 'leased_nla')  double leasedNla)?  $default,) {final _that = this;
switch (_that) {
case _PropertyTypeStatsModel() when $default != null:
return $default(_that.propertyType,_that.totalUnits,_that.leasedUnits,_that.vacantUnits,_that.expiringSoonUnits,_that.occupancyRate,_that.totalNla,_that.leasedNla);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PropertyTypeStatsModel implements PropertyTypeStatsModel {
  const _PropertyTypeStatsModel({@JsonKey(name: 'property_type') required this.propertyType, @JsonKey(name: 'total_units') required this.totalUnits, @JsonKey(name: 'leased_units') required this.leasedUnits, @JsonKey(name: 'vacant_units') required this.vacantUnits, @JsonKey(name: 'expiring_soon_units') required this.expiringSoonUnits, @JsonKey(name: 'occupancy_rate') required this.occupancyRate, @JsonKey(name: 'total_nla') required this.totalNla, @JsonKey(name: 'leased_nla') required this.leasedNla});
  factory _PropertyTypeStatsModel.fromJson(Map<String, dynamic> json) => _$PropertyTypeStatsModelFromJson(json);

@override@JsonKey(name: 'property_type') final  String propertyType;
@override@JsonKey(name: 'total_units') final  int totalUnits;
@override@JsonKey(name: 'leased_units') final  int leasedUnits;
@override@JsonKey(name: 'vacant_units') final  int vacantUnits;
@override@JsonKey(name: 'expiring_soon_units') final  int expiringSoonUnits;
@override@JsonKey(name: 'occupancy_rate') final  double occupancyRate;
@override@JsonKey(name: 'total_nla') final  double totalNla;
@override@JsonKey(name: 'leased_nla') final  double leasedNla;

/// Create a copy of PropertyTypeStatsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PropertyTypeStatsModelCopyWith<_PropertyTypeStatsModel> get copyWith => __$PropertyTypeStatsModelCopyWithImpl<_PropertyTypeStatsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PropertyTypeStatsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PropertyTypeStatsModel&&(identical(other.propertyType, propertyType) || other.propertyType == propertyType)&&(identical(other.totalUnits, totalUnits) || other.totalUnits == totalUnits)&&(identical(other.leasedUnits, leasedUnits) || other.leasedUnits == leasedUnits)&&(identical(other.vacantUnits, vacantUnits) || other.vacantUnits == vacantUnits)&&(identical(other.expiringSoonUnits, expiringSoonUnits) || other.expiringSoonUnits == expiringSoonUnits)&&(identical(other.occupancyRate, occupancyRate) || other.occupancyRate == occupancyRate)&&(identical(other.totalNla, totalNla) || other.totalNla == totalNla)&&(identical(other.leasedNla, leasedNla) || other.leasedNla == leasedNla));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,propertyType,totalUnits,leasedUnits,vacantUnits,expiringSoonUnits,occupancyRate,totalNla,leasedNla);

@override
String toString() {
  return 'PropertyTypeStatsModel(propertyType: $propertyType, totalUnits: $totalUnits, leasedUnits: $leasedUnits, vacantUnits: $vacantUnits, expiringSoonUnits: $expiringSoonUnits, occupancyRate: $occupancyRate, totalNla: $totalNla, leasedNla: $leasedNla)';
}


}

/// @nodoc
abstract mixin class _$PropertyTypeStatsModelCopyWith<$Res> implements $PropertyTypeStatsModelCopyWith<$Res> {
  factory _$PropertyTypeStatsModelCopyWith(_PropertyTypeStatsModel value, $Res Function(_PropertyTypeStatsModel) _then) = __$PropertyTypeStatsModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'property_type') String propertyType,@JsonKey(name: 'total_units') int totalUnits,@JsonKey(name: 'leased_units') int leasedUnits,@JsonKey(name: 'vacant_units') int vacantUnits,@JsonKey(name: 'expiring_soon_units') int expiringSoonUnits,@JsonKey(name: 'occupancy_rate') double occupancyRate,@JsonKey(name: 'total_nla') double totalNla,@JsonKey(name: 'leased_nla') double leasedNla
});




}
/// @nodoc
class __$PropertyTypeStatsModelCopyWithImpl<$Res>
    implements _$PropertyTypeStatsModelCopyWith<$Res> {
  __$PropertyTypeStatsModelCopyWithImpl(this._self, this._then);

  final _PropertyTypeStatsModel _self;
  final $Res Function(_PropertyTypeStatsModel) _then;

/// Create a copy of PropertyTypeStatsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? propertyType = null,Object? totalUnits = null,Object? leasedUnits = null,Object? vacantUnits = null,Object? expiringSoonUnits = null,Object? occupancyRate = null,Object? totalNla = null,Object? leasedNla = null,}) {
  return _then(_PropertyTypeStatsModel(
propertyType: null == propertyType ? _self.propertyType : propertyType // ignore: cast_nullable_to_non_nullable
as String,totalUnits: null == totalUnits ? _self.totalUnits : totalUnits // ignore: cast_nullable_to_non_nullable
as int,leasedUnits: null == leasedUnits ? _self.leasedUnits : leasedUnits // ignore: cast_nullable_to_non_nullable
as int,vacantUnits: null == vacantUnits ? _self.vacantUnits : vacantUnits // ignore: cast_nullable_to_non_nullable
as int,expiringSoonUnits: null == expiringSoonUnits ? _self.expiringSoonUnits : expiringSoonUnits // ignore: cast_nullable_to_non_nullable
as int,occupancyRate: null == occupancyRate ? _self.occupancyRate : occupancyRate // ignore: cast_nullable_to_non_nullable
as double,totalNla: null == totalNla ? _self.totalNla : totalNla // ignore: cast_nullable_to_non_nullable
as double,leasedNla: null == leasedNla ? _self.leasedNla : leasedNla // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$AssetOverviewModel {

@JsonKey(name: 'total_units') int get totalUnits;@JsonKey(name: 'total_leasable_units') int get totalLeasableUnits;@JsonKey(name: 'total_occupancy_rate') double get totalOccupancyRate;@JsonKey(name: 'wale_income_weighted') double get waleIncomeWeighted;@JsonKey(name: 'wale_area_weighted') double get waleAreaWeighted;@JsonKey(name: 'by_property_type') List<PropertyTypeStatsModel> get byPropertyType;
/// Create a copy of AssetOverviewModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssetOverviewModelCopyWith<AssetOverviewModel> get copyWith => _$AssetOverviewModelCopyWithImpl<AssetOverviewModel>(this as AssetOverviewModel, _$identity);

  /// Serializes this AssetOverviewModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssetOverviewModel&&(identical(other.totalUnits, totalUnits) || other.totalUnits == totalUnits)&&(identical(other.totalLeasableUnits, totalLeasableUnits) || other.totalLeasableUnits == totalLeasableUnits)&&(identical(other.totalOccupancyRate, totalOccupancyRate) || other.totalOccupancyRate == totalOccupancyRate)&&(identical(other.waleIncomeWeighted, waleIncomeWeighted) || other.waleIncomeWeighted == waleIncomeWeighted)&&(identical(other.waleAreaWeighted, waleAreaWeighted) || other.waleAreaWeighted == waleAreaWeighted)&&const DeepCollectionEquality().equals(other.byPropertyType, byPropertyType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalUnits,totalLeasableUnits,totalOccupancyRate,waleIncomeWeighted,waleAreaWeighted,const DeepCollectionEquality().hash(byPropertyType));

@override
String toString() {
  return 'AssetOverviewModel(totalUnits: $totalUnits, totalLeasableUnits: $totalLeasableUnits, totalOccupancyRate: $totalOccupancyRate, waleIncomeWeighted: $waleIncomeWeighted, waleAreaWeighted: $waleAreaWeighted, byPropertyType: $byPropertyType)';
}


}

/// @nodoc
abstract mixin class $AssetOverviewModelCopyWith<$Res>  {
  factory $AssetOverviewModelCopyWith(AssetOverviewModel value, $Res Function(AssetOverviewModel) _then) = _$AssetOverviewModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'total_units') int totalUnits,@JsonKey(name: 'total_leasable_units') int totalLeasableUnits,@JsonKey(name: 'total_occupancy_rate') double totalOccupancyRate,@JsonKey(name: 'wale_income_weighted') double waleIncomeWeighted,@JsonKey(name: 'wale_area_weighted') double waleAreaWeighted,@JsonKey(name: 'by_property_type') List<PropertyTypeStatsModel> byPropertyType
});




}
/// @nodoc
class _$AssetOverviewModelCopyWithImpl<$Res>
    implements $AssetOverviewModelCopyWith<$Res> {
  _$AssetOverviewModelCopyWithImpl(this._self, this._then);

  final AssetOverviewModel _self;
  final $Res Function(AssetOverviewModel) _then;

/// Create a copy of AssetOverviewModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalUnits = null,Object? totalLeasableUnits = null,Object? totalOccupancyRate = null,Object? waleIncomeWeighted = null,Object? waleAreaWeighted = null,Object? byPropertyType = null,}) {
  return _then(_self.copyWith(
totalUnits: null == totalUnits ? _self.totalUnits : totalUnits // ignore: cast_nullable_to_non_nullable
as int,totalLeasableUnits: null == totalLeasableUnits ? _self.totalLeasableUnits : totalLeasableUnits // ignore: cast_nullable_to_non_nullable
as int,totalOccupancyRate: null == totalOccupancyRate ? _self.totalOccupancyRate : totalOccupancyRate // ignore: cast_nullable_to_non_nullable
as double,waleIncomeWeighted: null == waleIncomeWeighted ? _self.waleIncomeWeighted : waleIncomeWeighted // ignore: cast_nullable_to_non_nullable
as double,waleAreaWeighted: null == waleAreaWeighted ? _self.waleAreaWeighted : waleAreaWeighted // ignore: cast_nullable_to_non_nullable
as double,byPropertyType: null == byPropertyType ? _self.byPropertyType : byPropertyType // ignore: cast_nullable_to_non_nullable
as List<PropertyTypeStatsModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [AssetOverviewModel].
extension AssetOverviewModelPatterns on AssetOverviewModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssetOverviewModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssetOverviewModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssetOverviewModel value)  $default,){
final _that = this;
switch (_that) {
case _AssetOverviewModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssetOverviewModel value)?  $default,){
final _that = this;
switch (_that) {
case _AssetOverviewModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'total_units')  int totalUnits, @JsonKey(name: 'total_leasable_units')  int totalLeasableUnits, @JsonKey(name: 'total_occupancy_rate')  double totalOccupancyRate, @JsonKey(name: 'wale_income_weighted')  double waleIncomeWeighted, @JsonKey(name: 'wale_area_weighted')  double waleAreaWeighted, @JsonKey(name: 'by_property_type')  List<PropertyTypeStatsModel> byPropertyType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssetOverviewModel() when $default != null:
return $default(_that.totalUnits,_that.totalLeasableUnits,_that.totalOccupancyRate,_that.waleIncomeWeighted,_that.waleAreaWeighted,_that.byPropertyType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'total_units')  int totalUnits, @JsonKey(name: 'total_leasable_units')  int totalLeasableUnits, @JsonKey(name: 'total_occupancy_rate')  double totalOccupancyRate, @JsonKey(name: 'wale_income_weighted')  double waleIncomeWeighted, @JsonKey(name: 'wale_area_weighted')  double waleAreaWeighted, @JsonKey(name: 'by_property_type')  List<PropertyTypeStatsModel> byPropertyType)  $default,) {final _that = this;
switch (_that) {
case _AssetOverviewModel():
return $default(_that.totalUnits,_that.totalLeasableUnits,_that.totalOccupancyRate,_that.waleIncomeWeighted,_that.waleAreaWeighted,_that.byPropertyType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'total_units')  int totalUnits, @JsonKey(name: 'total_leasable_units')  int totalLeasableUnits, @JsonKey(name: 'total_occupancy_rate')  double totalOccupancyRate, @JsonKey(name: 'wale_income_weighted')  double waleIncomeWeighted, @JsonKey(name: 'wale_area_weighted')  double waleAreaWeighted, @JsonKey(name: 'by_property_type')  List<PropertyTypeStatsModel> byPropertyType)?  $default,) {final _that = this;
switch (_that) {
case _AssetOverviewModel() when $default != null:
return $default(_that.totalUnits,_that.totalLeasableUnits,_that.totalOccupancyRate,_that.waleIncomeWeighted,_that.waleAreaWeighted,_that.byPropertyType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssetOverviewModel implements AssetOverviewModel {
  const _AssetOverviewModel({@JsonKey(name: 'total_units') required this.totalUnits, @JsonKey(name: 'total_leasable_units') required this.totalLeasableUnits, @JsonKey(name: 'total_occupancy_rate') required this.totalOccupancyRate, @JsonKey(name: 'wale_income_weighted') required this.waleIncomeWeighted, @JsonKey(name: 'wale_area_weighted') required this.waleAreaWeighted, @JsonKey(name: 'by_property_type') required final  List<PropertyTypeStatsModel> byPropertyType}): _byPropertyType = byPropertyType;
  factory _AssetOverviewModel.fromJson(Map<String, dynamic> json) => _$AssetOverviewModelFromJson(json);

@override@JsonKey(name: 'total_units') final  int totalUnits;
@override@JsonKey(name: 'total_leasable_units') final  int totalLeasableUnits;
@override@JsonKey(name: 'total_occupancy_rate') final  double totalOccupancyRate;
@override@JsonKey(name: 'wale_income_weighted') final  double waleIncomeWeighted;
@override@JsonKey(name: 'wale_area_weighted') final  double waleAreaWeighted;
 final  List<PropertyTypeStatsModel> _byPropertyType;
@override@JsonKey(name: 'by_property_type') List<PropertyTypeStatsModel> get byPropertyType {
  if (_byPropertyType is EqualUnmodifiableListView) return _byPropertyType;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_byPropertyType);
}


/// Create a copy of AssetOverviewModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssetOverviewModelCopyWith<_AssetOverviewModel> get copyWith => __$AssetOverviewModelCopyWithImpl<_AssetOverviewModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssetOverviewModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssetOverviewModel&&(identical(other.totalUnits, totalUnits) || other.totalUnits == totalUnits)&&(identical(other.totalLeasableUnits, totalLeasableUnits) || other.totalLeasableUnits == totalLeasableUnits)&&(identical(other.totalOccupancyRate, totalOccupancyRate) || other.totalOccupancyRate == totalOccupancyRate)&&(identical(other.waleIncomeWeighted, waleIncomeWeighted) || other.waleIncomeWeighted == waleIncomeWeighted)&&(identical(other.waleAreaWeighted, waleAreaWeighted) || other.waleAreaWeighted == waleAreaWeighted)&&const DeepCollectionEquality().equals(other._byPropertyType, _byPropertyType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalUnits,totalLeasableUnits,totalOccupancyRate,waleIncomeWeighted,waleAreaWeighted,const DeepCollectionEquality().hash(_byPropertyType));

@override
String toString() {
  return 'AssetOverviewModel(totalUnits: $totalUnits, totalLeasableUnits: $totalLeasableUnits, totalOccupancyRate: $totalOccupancyRate, waleIncomeWeighted: $waleIncomeWeighted, waleAreaWeighted: $waleAreaWeighted, byPropertyType: $byPropertyType)';
}


}

/// @nodoc
abstract mixin class _$AssetOverviewModelCopyWith<$Res> implements $AssetOverviewModelCopyWith<$Res> {
  factory _$AssetOverviewModelCopyWith(_AssetOverviewModel value, $Res Function(_AssetOverviewModel) _then) = __$AssetOverviewModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'total_units') int totalUnits,@JsonKey(name: 'total_leasable_units') int totalLeasableUnits,@JsonKey(name: 'total_occupancy_rate') double totalOccupancyRate,@JsonKey(name: 'wale_income_weighted') double waleIncomeWeighted,@JsonKey(name: 'wale_area_weighted') double waleAreaWeighted,@JsonKey(name: 'by_property_type') List<PropertyTypeStatsModel> byPropertyType
});




}
/// @nodoc
class __$AssetOverviewModelCopyWithImpl<$Res>
    implements _$AssetOverviewModelCopyWith<$Res> {
  __$AssetOverviewModelCopyWithImpl(this._self, this._then);

  final _AssetOverviewModel _self;
  final $Res Function(_AssetOverviewModel) _then;

/// Create a copy of AssetOverviewModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalUnits = null,Object? totalLeasableUnits = null,Object? totalOccupancyRate = null,Object? waleIncomeWeighted = null,Object? waleAreaWeighted = null,Object? byPropertyType = null,}) {
  return _then(_AssetOverviewModel(
totalUnits: null == totalUnits ? _self.totalUnits : totalUnits // ignore: cast_nullable_to_non_nullable
as int,totalLeasableUnits: null == totalLeasableUnits ? _self.totalLeasableUnits : totalLeasableUnits // ignore: cast_nullable_to_non_nullable
as int,totalOccupancyRate: null == totalOccupancyRate ? _self.totalOccupancyRate : totalOccupancyRate // ignore: cast_nullable_to_non_nullable
as double,waleIncomeWeighted: null == waleIncomeWeighted ? _self.waleIncomeWeighted : waleIncomeWeighted // ignore: cast_nullable_to_non_nullable
as double,waleAreaWeighted: null == waleAreaWeighted ? _self.waleAreaWeighted : waleAreaWeighted // ignore: cast_nullable_to_non_nullable
as double,byPropertyType: null == byPropertyType ? _self._byPropertyType : byPropertyType // ignore: cast_nullable_to_non_nullable
as List<PropertyTypeStatsModel>,
  ));
}


}

// dart format on
