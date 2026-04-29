// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'renovation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RenovationSummary {

 String get id; String get unitId; String get unitNumber; String get renovationType; DateTime get startedAt; DateTime? get completedAt; double? get cost; String? get contractor; DateTime get createdAt;
/// Create a copy of RenovationSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RenovationSummaryCopyWith<RenovationSummary> get copyWith => _$RenovationSummaryCopyWithImpl<RenovationSummary>(this as RenovationSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RenovationSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.unitNumber, unitNumber) || other.unitNumber == unitNumber)&&(identical(other.renovationType, renovationType) || other.renovationType == renovationType)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.cost, cost) || other.cost == cost)&&(identical(other.contractor, contractor) || other.contractor == contractor)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,unitId,unitNumber,renovationType,startedAt,completedAt,cost,contractor,createdAt);

@override
String toString() {
  return 'RenovationSummary(id: $id, unitId: $unitId, unitNumber: $unitNumber, renovationType: $renovationType, startedAt: $startedAt, completedAt: $completedAt, cost: $cost, contractor: $contractor, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $RenovationSummaryCopyWith<$Res>  {
  factory $RenovationSummaryCopyWith(RenovationSummary value, $Res Function(RenovationSummary) _then) = _$RenovationSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String unitId, String unitNumber, String renovationType, DateTime startedAt, DateTime? completedAt, double? cost, String? contractor, DateTime createdAt
});




}
/// @nodoc
class _$RenovationSummaryCopyWithImpl<$Res>
    implements $RenovationSummaryCopyWith<$Res> {
  _$RenovationSummaryCopyWithImpl(this._self, this._then);

  final RenovationSummary _self;
  final $Res Function(RenovationSummary) _then;

/// Create a copy of RenovationSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? unitId = null,Object? unitNumber = null,Object? renovationType = null,Object? startedAt = null,Object? completedAt = freezed,Object? cost = freezed,Object? contractor = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,unitId: null == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String,unitNumber: null == unitNumber ? _self.unitNumber : unitNumber // ignore: cast_nullable_to_non_nullable
as String,renovationType: null == renovationType ? _self.renovationType : renovationType // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,cost: freezed == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as double?,contractor: freezed == contractor ? _self.contractor : contractor // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [RenovationSummary].
extension RenovationSummaryPatterns on RenovationSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RenovationSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RenovationSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RenovationSummary value)  $default,){
final _that = this;
switch (_that) {
case _RenovationSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RenovationSummary value)?  $default,){
final _that = this;
switch (_that) {
case _RenovationSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String unitId,  String unitNumber,  String renovationType,  DateTime startedAt,  DateTime? completedAt,  double? cost,  String? contractor,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RenovationSummary() when $default != null:
return $default(_that.id,_that.unitId,_that.unitNumber,_that.renovationType,_that.startedAt,_that.completedAt,_that.cost,_that.contractor,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String unitId,  String unitNumber,  String renovationType,  DateTime startedAt,  DateTime? completedAt,  double? cost,  String? contractor,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _RenovationSummary():
return $default(_that.id,_that.unitId,_that.unitNumber,_that.renovationType,_that.startedAt,_that.completedAt,_that.cost,_that.contractor,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String unitId,  String unitNumber,  String renovationType,  DateTime startedAt,  DateTime? completedAt,  double? cost,  String? contractor,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _RenovationSummary() when $default != null:
return $default(_that.id,_that.unitId,_that.unitNumber,_that.renovationType,_that.startedAt,_that.completedAt,_that.cost,_that.contractor,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _RenovationSummary implements RenovationSummary {
  const _RenovationSummary({required this.id, required this.unitId, required this.unitNumber, required this.renovationType, required this.startedAt, this.completedAt, this.cost, this.contractor, required this.createdAt});
  

@override final  String id;
@override final  String unitId;
@override final  String unitNumber;
@override final  String renovationType;
@override final  DateTime startedAt;
@override final  DateTime? completedAt;
@override final  double? cost;
@override final  String? contractor;
@override final  DateTime createdAt;

/// Create a copy of RenovationSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RenovationSummaryCopyWith<_RenovationSummary> get copyWith => __$RenovationSummaryCopyWithImpl<_RenovationSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RenovationSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.unitNumber, unitNumber) || other.unitNumber == unitNumber)&&(identical(other.renovationType, renovationType) || other.renovationType == renovationType)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.cost, cost) || other.cost == cost)&&(identical(other.contractor, contractor) || other.contractor == contractor)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,unitId,unitNumber,renovationType,startedAt,completedAt,cost,contractor,createdAt);

@override
String toString() {
  return 'RenovationSummary(id: $id, unitId: $unitId, unitNumber: $unitNumber, renovationType: $renovationType, startedAt: $startedAt, completedAt: $completedAt, cost: $cost, contractor: $contractor, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$RenovationSummaryCopyWith<$Res> implements $RenovationSummaryCopyWith<$Res> {
  factory _$RenovationSummaryCopyWith(_RenovationSummary value, $Res Function(_RenovationSummary) _then) = __$RenovationSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String unitId, String unitNumber, String renovationType, DateTime startedAt, DateTime? completedAt, double? cost, String? contractor, DateTime createdAt
});




}
/// @nodoc
class __$RenovationSummaryCopyWithImpl<$Res>
    implements _$RenovationSummaryCopyWith<$Res> {
  __$RenovationSummaryCopyWithImpl(this._self, this._then);

  final _RenovationSummary _self;
  final $Res Function(_RenovationSummary) _then;

/// Create a copy of RenovationSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? unitId = null,Object? unitNumber = null,Object? renovationType = null,Object? startedAt = null,Object? completedAt = freezed,Object? cost = freezed,Object? contractor = freezed,Object? createdAt = null,}) {
  return _then(_RenovationSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,unitId: null == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String,unitNumber: null == unitNumber ? _self.unitNumber : unitNumber // ignore: cast_nullable_to_non_nullable
as String,renovationType: null == renovationType ? _self.renovationType : renovationType // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,cost: freezed == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as double?,contractor: freezed == contractor ? _self.contractor : contractor // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
