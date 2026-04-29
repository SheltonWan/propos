// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'asset_overview.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PropertyTypeStats {

 PropertyType get propertyType; int get totalUnits; int get leasedUnits; int get vacantUnits; int get expiringSoonUnits; double get occupancyRate; double get totalNla; double get leasedNla;
/// Create a copy of PropertyTypeStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PropertyTypeStatsCopyWith<PropertyTypeStats> get copyWith => _$PropertyTypeStatsCopyWithImpl<PropertyTypeStats>(this as PropertyTypeStats, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PropertyTypeStats&&(identical(other.propertyType, propertyType) || other.propertyType == propertyType)&&(identical(other.totalUnits, totalUnits) || other.totalUnits == totalUnits)&&(identical(other.leasedUnits, leasedUnits) || other.leasedUnits == leasedUnits)&&(identical(other.vacantUnits, vacantUnits) || other.vacantUnits == vacantUnits)&&(identical(other.expiringSoonUnits, expiringSoonUnits) || other.expiringSoonUnits == expiringSoonUnits)&&(identical(other.occupancyRate, occupancyRate) || other.occupancyRate == occupancyRate)&&(identical(other.totalNla, totalNla) || other.totalNla == totalNla)&&(identical(other.leasedNla, leasedNla) || other.leasedNla == leasedNla));
}


@override
int get hashCode => Object.hash(runtimeType,propertyType,totalUnits,leasedUnits,vacantUnits,expiringSoonUnits,occupancyRate,totalNla,leasedNla);

@override
String toString() {
  return 'PropertyTypeStats(propertyType: $propertyType, totalUnits: $totalUnits, leasedUnits: $leasedUnits, vacantUnits: $vacantUnits, expiringSoonUnits: $expiringSoonUnits, occupancyRate: $occupancyRate, totalNla: $totalNla, leasedNla: $leasedNla)';
}


}

/// @nodoc
abstract mixin class $PropertyTypeStatsCopyWith<$Res>  {
  factory $PropertyTypeStatsCopyWith(PropertyTypeStats value, $Res Function(PropertyTypeStats) _then) = _$PropertyTypeStatsCopyWithImpl;
@useResult
$Res call({
 PropertyType propertyType, int totalUnits, int leasedUnits, int vacantUnits, int expiringSoonUnits, double occupancyRate, double totalNla, double leasedNla
});




}
/// @nodoc
class _$PropertyTypeStatsCopyWithImpl<$Res>
    implements $PropertyTypeStatsCopyWith<$Res> {
  _$PropertyTypeStatsCopyWithImpl(this._self, this._then);

  final PropertyTypeStats _self;
  final $Res Function(PropertyTypeStats) _then;

/// Create a copy of PropertyTypeStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? propertyType = null,Object? totalUnits = null,Object? leasedUnits = null,Object? vacantUnits = null,Object? expiringSoonUnits = null,Object? occupancyRate = null,Object? totalNla = null,Object? leasedNla = null,}) {
  return _then(_self.copyWith(
propertyType: null == propertyType ? _self.propertyType : propertyType // ignore: cast_nullable_to_non_nullable
as PropertyType,totalUnits: null == totalUnits ? _self.totalUnits : totalUnits // ignore: cast_nullable_to_non_nullable
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


/// Adds pattern-matching-related methods to [PropertyTypeStats].
extension PropertyTypeStatsPatterns on PropertyTypeStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PropertyTypeStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PropertyTypeStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PropertyTypeStats value)  $default,){
final _that = this;
switch (_that) {
case _PropertyTypeStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PropertyTypeStats value)?  $default,){
final _that = this;
switch (_that) {
case _PropertyTypeStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PropertyType propertyType,  int totalUnits,  int leasedUnits,  int vacantUnits,  int expiringSoonUnits,  double occupancyRate,  double totalNla,  double leasedNla)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PropertyTypeStats() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PropertyType propertyType,  int totalUnits,  int leasedUnits,  int vacantUnits,  int expiringSoonUnits,  double occupancyRate,  double totalNla,  double leasedNla)  $default,) {final _that = this;
switch (_that) {
case _PropertyTypeStats():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PropertyType propertyType,  int totalUnits,  int leasedUnits,  int vacantUnits,  int expiringSoonUnits,  double occupancyRate,  double totalNla,  double leasedNla)?  $default,) {final _that = this;
switch (_that) {
case _PropertyTypeStats() when $default != null:
return $default(_that.propertyType,_that.totalUnits,_that.leasedUnits,_that.vacantUnits,_that.expiringSoonUnits,_that.occupancyRate,_that.totalNla,_that.leasedNla);case _:
  return null;

}
}

}

/// @nodoc


class _PropertyTypeStats implements PropertyTypeStats {
  const _PropertyTypeStats({required this.propertyType, required this.totalUnits, required this.leasedUnits, required this.vacantUnits, required this.expiringSoonUnits, required this.occupancyRate, required this.totalNla, required this.leasedNla});
  

@override final  PropertyType propertyType;
@override final  int totalUnits;
@override final  int leasedUnits;
@override final  int vacantUnits;
@override final  int expiringSoonUnits;
@override final  double occupancyRate;
@override final  double totalNla;
@override final  double leasedNla;

/// Create a copy of PropertyTypeStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PropertyTypeStatsCopyWith<_PropertyTypeStats> get copyWith => __$PropertyTypeStatsCopyWithImpl<_PropertyTypeStats>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PropertyTypeStats&&(identical(other.propertyType, propertyType) || other.propertyType == propertyType)&&(identical(other.totalUnits, totalUnits) || other.totalUnits == totalUnits)&&(identical(other.leasedUnits, leasedUnits) || other.leasedUnits == leasedUnits)&&(identical(other.vacantUnits, vacantUnits) || other.vacantUnits == vacantUnits)&&(identical(other.expiringSoonUnits, expiringSoonUnits) || other.expiringSoonUnits == expiringSoonUnits)&&(identical(other.occupancyRate, occupancyRate) || other.occupancyRate == occupancyRate)&&(identical(other.totalNla, totalNla) || other.totalNla == totalNla)&&(identical(other.leasedNla, leasedNla) || other.leasedNla == leasedNla));
}


@override
int get hashCode => Object.hash(runtimeType,propertyType,totalUnits,leasedUnits,vacantUnits,expiringSoonUnits,occupancyRate,totalNla,leasedNla);

@override
String toString() {
  return 'PropertyTypeStats(propertyType: $propertyType, totalUnits: $totalUnits, leasedUnits: $leasedUnits, vacantUnits: $vacantUnits, expiringSoonUnits: $expiringSoonUnits, occupancyRate: $occupancyRate, totalNla: $totalNla, leasedNla: $leasedNla)';
}


}

/// @nodoc
abstract mixin class _$PropertyTypeStatsCopyWith<$Res> implements $PropertyTypeStatsCopyWith<$Res> {
  factory _$PropertyTypeStatsCopyWith(_PropertyTypeStats value, $Res Function(_PropertyTypeStats) _then) = __$PropertyTypeStatsCopyWithImpl;
@override @useResult
$Res call({
 PropertyType propertyType, int totalUnits, int leasedUnits, int vacantUnits, int expiringSoonUnits, double occupancyRate, double totalNla, double leasedNla
});




}
/// @nodoc
class __$PropertyTypeStatsCopyWithImpl<$Res>
    implements _$PropertyTypeStatsCopyWith<$Res> {
  __$PropertyTypeStatsCopyWithImpl(this._self, this._then);

  final _PropertyTypeStats _self;
  final $Res Function(_PropertyTypeStats) _then;

/// Create a copy of PropertyTypeStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? propertyType = null,Object? totalUnits = null,Object? leasedUnits = null,Object? vacantUnits = null,Object? expiringSoonUnits = null,Object? occupancyRate = null,Object? totalNla = null,Object? leasedNla = null,}) {
  return _then(_PropertyTypeStats(
propertyType: null == propertyType ? _self.propertyType : propertyType // ignore: cast_nullable_to_non_nullable
as PropertyType,totalUnits: null == totalUnits ? _self.totalUnits : totalUnits // ignore: cast_nullable_to_non_nullable
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
mixin _$AssetOverview {

 int get totalUnits; int get totalLeasableUnits; double get totalOccupancyRate; double get waleIncomeWeighted; double get waleAreaWeighted; List<PropertyTypeStats> get byPropertyType;
/// Create a copy of AssetOverview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssetOverviewCopyWith<AssetOverview> get copyWith => _$AssetOverviewCopyWithImpl<AssetOverview>(this as AssetOverview, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssetOverview&&(identical(other.totalUnits, totalUnits) || other.totalUnits == totalUnits)&&(identical(other.totalLeasableUnits, totalLeasableUnits) || other.totalLeasableUnits == totalLeasableUnits)&&(identical(other.totalOccupancyRate, totalOccupancyRate) || other.totalOccupancyRate == totalOccupancyRate)&&(identical(other.waleIncomeWeighted, waleIncomeWeighted) || other.waleIncomeWeighted == waleIncomeWeighted)&&(identical(other.waleAreaWeighted, waleAreaWeighted) || other.waleAreaWeighted == waleAreaWeighted)&&const DeepCollectionEquality().equals(other.byPropertyType, byPropertyType));
}


@override
int get hashCode => Object.hash(runtimeType,totalUnits,totalLeasableUnits,totalOccupancyRate,waleIncomeWeighted,waleAreaWeighted,const DeepCollectionEquality().hash(byPropertyType));

@override
String toString() {
  return 'AssetOverview(totalUnits: $totalUnits, totalLeasableUnits: $totalLeasableUnits, totalOccupancyRate: $totalOccupancyRate, waleIncomeWeighted: $waleIncomeWeighted, waleAreaWeighted: $waleAreaWeighted, byPropertyType: $byPropertyType)';
}


}

/// @nodoc
abstract mixin class $AssetOverviewCopyWith<$Res>  {
  factory $AssetOverviewCopyWith(AssetOverview value, $Res Function(AssetOverview) _then) = _$AssetOverviewCopyWithImpl;
@useResult
$Res call({
 int totalUnits, int totalLeasableUnits, double totalOccupancyRate, double waleIncomeWeighted, double waleAreaWeighted, List<PropertyTypeStats> byPropertyType
});




}
/// @nodoc
class _$AssetOverviewCopyWithImpl<$Res>
    implements $AssetOverviewCopyWith<$Res> {
  _$AssetOverviewCopyWithImpl(this._self, this._then);

  final AssetOverview _self;
  final $Res Function(AssetOverview) _then;

/// Create a copy of AssetOverview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalUnits = null,Object? totalLeasableUnits = null,Object? totalOccupancyRate = null,Object? waleIncomeWeighted = null,Object? waleAreaWeighted = null,Object? byPropertyType = null,}) {
  return _then(_self.copyWith(
totalUnits: null == totalUnits ? _self.totalUnits : totalUnits // ignore: cast_nullable_to_non_nullable
as int,totalLeasableUnits: null == totalLeasableUnits ? _self.totalLeasableUnits : totalLeasableUnits // ignore: cast_nullable_to_non_nullable
as int,totalOccupancyRate: null == totalOccupancyRate ? _self.totalOccupancyRate : totalOccupancyRate // ignore: cast_nullable_to_non_nullable
as double,waleIncomeWeighted: null == waleIncomeWeighted ? _self.waleIncomeWeighted : waleIncomeWeighted // ignore: cast_nullable_to_non_nullable
as double,waleAreaWeighted: null == waleAreaWeighted ? _self.waleAreaWeighted : waleAreaWeighted // ignore: cast_nullable_to_non_nullable
as double,byPropertyType: null == byPropertyType ? _self.byPropertyType : byPropertyType // ignore: cast_nullable_to_non_nullable
as List<PropertyTypeStats>,
  ));
}

}


/// Adds pattern-matching-related methods to [AssetOverview].
extension AssetOverviewPatterns on AssetOverview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssetOverview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssetOverview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssetOverview value)  $default,){
final _that = this;
switch (_that) {
case _AssetOverview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssetOverview value)?  $default,){
final _that = this;
switch (_that) {
case _AssetOverview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int totalUnits,  int totalLeasableUnits,  double totalOccupancyRate,  double waleIncomeWeighted,  double waleAreaWeighted,  List<PropertyTypeStats> byPropertyType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssetOverview() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int totalUnits,  int totalLeasableUnits,  double totalOccupancyRate,  double waleIncomeWeighted,  double waleAreaWeighted,  List<PropertyTypeStats> byPropertyType)  $default,) {final _that = this;
switch (_that) {
case _AssetOverview():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int totalUnits,  int totalLeasableUnits,  double totalOccupancyRate,  double waleIncomeWeighted,  double waleAreaWeighted,  List<PropertyTypeStats> byPropertyType)?  $default,) {final _that = this;
switch (_that) {
case _AssetOverview() when $default != null:
return $default(_that.totalUnits,_that.totalLeasableUnits,_that.totalOccupancyRate,_that.waleIncomeWeighted,_that.waleAreaWeighted,_that.byPropertyType);case _:
  return null;

}
}

}

/// @nodoc


class _AssetOverview implements AssetOverview {
  const _AssetOverview({required this.totalUnits, required this.totalLeasableUnits, required this.totalOccupancyRate, required this.waleIncomeWeighted, required this.waleAreaWeighted, required final  List<PropertyTypeStats> byPropertyType}): _byPropertyType = byPropertyType;
  

@override final  int totalUnits;
@override final  int totalLeasableUnits;
@override final  double totalOccupancyRate;
@override final  double waleIncomeWeighted;
@override final  double waleAreaWeighted;
 final  List<PropertyTypeStats> _byPropertyType;
@override List<PropertyTypeStats> get byPropertyType {
  if (_byPropertyType is EqualUnmodifiableListView) return _byPropertyType;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_byPropertyType);
}


/// Create a copy of AssetOverview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssetOverviewCopyWith<_AssetOverview> get copyWith => __$AssetOverviewCopyWithImpl<_AssetOverview>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssetOverview&&(identical(other.totalUnits, totalUnits) || other.totalUnits == totalUnits)&&(identical(other.totalLeasableUnits, totalLeasableUnits) || other.totalLeasableUnits == totalLeasableUnits)&&(identical(other.totalOccupancyRate, totalOccupancyRate) || other.totalOccupancyRate == totalOccupancyRate)&&(identical(other.waleIncomeWeighted, waleIncomeWeighted) || other.waleIncomeWeighted == waleIncomeWeighted)&&(identical(other.waleAreaWeighted, waleAreaWeighted) || other.waleAreaWeighted == waleAreaWeighted)&&const DeepCollectionEquality().equals(other._byPropertyType, _byPropertyType));
}


@override
int get hashCode => Object.hash(runtimeType,totalUnits,totalLeasableUnits,totalOccupancyRate,waleIncomeWeighted,waleAreaWeighted,const DeepCollectionEquality().hash(_byPropertyType));

@override
String toString() {
  return 'AssetOverview(totalUnits: $totalUnits, totalLeasableUnits: $totalLeasableUnits, totalOccupancyRate: $totalOccupancyRate, waleIncomeWeighted: $waleIncomeWeighted, waleAreaWeighted: $waleAreaWeighted, byPropertyType: $byPropertyType)';
}


}

/// @nodoc
abstract mixin class _$AssetOverviewCopyWith<$Res> implements $AssetOverviewCopyWith<$Res> {
  factory _$AssetOverviewCopyWith(_AssetOverview value, $Res Function(_AssetOverview) _then) = __$AssetOverviewCopyWithImpl;
@override @useResult
$Res call({
 int totalUnits, int totalLeasableUnits, double totalOccupancyRate, double waleIncomeWeighted, double waleAreaWeighted, List<PropertyTypeStats> byPropertyType
});




}
/// @nodoc
class __$AssetOverviewCopyWithImpl<$Res>
    implements _$AssetOverviewCopyWith<$Res> {
  __$AssetOverviewCopyWithImpl(this._self, this._then);

  final _AssetOverview _self;
  final $Res Function(_AssetOverview) _then;

/// Create a copy of AssetOverview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalUnits = null,Object? totalLeasableUnits = null,Object? totalOccupancyRate = null,Object? waleIncomeWeighted = null,Object? waleAreaWeighted = null,Object? byPropertyType = null,}) {
  return _then(_AssetOverview(
totalUnits: null == totalUnits ? _self.totalUnits : totalUnits // ignore: cast_nullable_to_non_nullable
as int,totalLeasableUnits: null == totalLeasableUnits ? _self.totalLeasableUnits : totalLeasableUnits // ignore: cast_nullable_to_non_nullable
as int,totalOccupancyRate: null == totalOccupancyRate ? _self.totalOccupancyRate : totalOccupancyRate // ignore: cast_nullable_to_non_nullable
as double,waleIncomeWeighted: null == waleIncomeWeighted ? _self.waleIncomeWeighted : waleIncomeWeighted // ignore: cast_nullable_to_non_nullable
as double,waleAreaWeighted: null == waleAreaWeighted ? _self.waleAreaWeighted : waleAreaWeighted // ignore: cast_nullable_to_non_nullable
as double,byPropertyType: null == byPropertyType ? _self._byPropertyType : byPropertyType // ignore: cast_nullable_to_non_nullable
as List<PropertyTypeStats>,
  ));
}


}

// dart format on
