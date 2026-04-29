// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'renovation_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RenovationSummaryModel {

 String get id;@JsonKey(name: 'unit_id') String get unitId;@JsonKey(name: 'unit_number') String get unitNumber;@JsonKey(name: 'renovation_type') String get renovationType;@JsonKey(name: 'started_at') String get startedAt;@JsonKey(name: 'completed_at') String? get completedAt; double? get cost; String? get contractor;@JsonKey(name: 'created_at') String get createdAt;
/// Create a copy of RenovationSummaryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RenovationSummaryModelCopyWith<RenovationSummaryModel> get copyWith => _$RenovationSummaryModelCopyWithImpl<RenovationSummaryModel>(this as RenovationSummaryModel, _$identity);

  /// Serializes this RenovationSummaryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RenovationSummaryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.unitNumber, unitNumber) || other.unitNumber == unitNumber)&&(identical(other.renovationType, renovationType) || other.renovationType == renovationType)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.cost, cost) || other.cost == cost)&&(identical(other.contractor, contractor) || other.contractor == contractor)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,unitId,unitNumber,renovationType,startedAt,completedAt,cost,contractor,createdAt);

@override
String toString() {
  return 'RenovationSummaryModel(id: $id, unitId: $unitId, unitNumber: $unitNumber, renovationType: $renovationType, startedAt: $startedAt, completedAt: $completedAt, cost: $cost, contractor: $contractor, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $RenovationSummaryModelCopyWith<$Res>  {
  factory $RenovationSummaryModelCopyWith(RenovationSummaryModel value, $Res Function(RenovationSummaryModel) _then) = _$RenovationSummaryModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'unit_id') String unitId,@JsonKey(name: 'unit_number') String unitNumber,@JsonKey(name: 'renovation_type') String renovationType,@JsonKey(name: 'started_at') String startedAt,@JsonKey(name: 'completed_at') String? completedAt, double? cost, String? contractor,@JsonKey(name: 'created_at') String createdAt
});




}
/// @nodoc
class _$RenovationSummaryModelCopyWithImpl<$Res>
    implements $RenovationSummaryModelCopyWith<$Res> {
  _$RenovationSummaryModelCopyWithImpl(this._self, this._then);

  final RenovationSummaryModel _self;
  final $Res Function(RenovationSummaryModel) _then;

/// Create a copy of RenovationSummaryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? unitId = null,Object? unitNumber = null,Object? renovationType = null,Object? startedAt = null,Object? completedAt = freezed,Object? cost = freezed,Object? contractor = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,unitId: null == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String,unitNumber: null == unitNumber ? _self.unitNumber : unitNumber // ignore: cast_nullable_to_non_nullable
as String,renovationType: null == renovationType ? _self.renovationType : renovationType // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as String,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as String?,cost: freezed == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as double?,contractor: freezed == contractor ? _self.contractor : contractor // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RenovationSummaryModel].
extension RenovationSummaryModelPatterns on RenovationSummaryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RenovationSummaryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RenovationSummaryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RenovationSummaryModel value)  $default,){
final _that = this;
switch (_that) {
case _RenovationSummaryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RenovationSummaryModel value)?  $default,){
final _that = this;
switch (_that) {
case _RenovationSummaryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'unit_id')  String unitId, @JsonKey(name: 'unit_number')  String unitNumber, @JsonKey(name: 'renovation_type')  String renovationType, @JsonKey(name: 'started_at')  String startedAt, @JsonKey(name: 'completed_at')  String? completedAt,  double? cost,  String? contractor, @JsonKey(name: 'created_at')  String createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RenovationSummaryModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'unit_id')  String unitId, @JsonKey(name: 'unit_number')  String unitNumber, @JsonKey(name: 'renovation_type')  String renovationType, @JsonKey(name: 'started_at')  String startedAt, @JsonKey(name: 'completed_at')  String? completedAt,  double? cost,  String? contractor, @JsonKey(name: 'created_at')  String createdAt)  $default,) {final _that = this;
switch (_that) {
case _RenovationSummaryModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'unit_id')  String unitId, @JsonKey(name: 'unit_number')  String unitNumber, @JsonKey(name: 'renovation_type')  String renovationType, @JsonKey(name: 'started_at')  String startedAt, @JsonKey(name: 'completed_at')  String? completedAt,  double? cost,  String? contractor, @JsonKey(name: 'created_at')  String createdAt)?  $default,) {final _that = this;
switch (_that) {
case _RenovationSummaryModel() when $default != null:
return $default(_that.id,_that.unitId,_that.unitNumber,_that.renovationType,_that.startedAt,_that.completedAt,_that.cost,_that.contractor,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RenovationSummaryModel implements RenovationSummaryModel {
  const _RenovationSummaryModel({required this.id, @JsonKey(name: 'unit_id') required this.unitId, @JsonKey(name: 'unit_number') required this.unitNumber, @JsonKey(name: 'renovation_type') required this.renovationType, @JsonKey(name: 'started_at') required this.startedAt, @JsonKey(name: 'completed_at') this.completedAt, this.cost, this.contractor, @JsonKey(name: 'created_at') required this.createdAt});
  factory _RenovationSummaryModel.fromJson(Map<String, dynamic> json) => _$RenovationSummaryModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'unit_id') final  String unitId;
@override@JsonKey(name: 'unit_number') final  String unitNumber;
@override@JsonKey(name: 'renovation_type') final  String renovationType;
@override@JsonKey(name: 'started_at') final  String startedAt;
@override@JsonKey(name: 'completed_at') final  String? completedAt;
@override final  double? cost;
@override final  String? contractor;
@override@JsonKey(name: 'created_at') final  String createdAt;

/// Create a copy of RenovationSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RenovationSummaryModelCopyWith<_RenovationSummaryModel> get copyWith => __$RenovationSummaryModelCopyWithImpl<_RenovationSummaryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RenovationSummaryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RenovationSummaryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.unitNumber, unitNumber) || other.unitNumber == unitNumber)&&(identical(other.renovationType, renovationType) || other.renovationType == renovationType)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.cost, cost) || other.cost == cost)&&(identical(other.contractor, contractor) || other.contractor == contractor)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,unitId,unitNumber,renovationType,startedAt,completedAt,cost,contractor,createdAt);

@override
String toString() {
  return 'RenovationSummaryModel(id: $id, unitId: $unitId, unitNumber: $unitNumber, renovationType: $renovationType, startedAt: $startedAt, completedAt: $completedAt, cost: $cost, contractor: $contractor, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$RenovationSummaryModelCopyWith<$Res> implements $RenovationSummaryModelCopyWith<$Res> {
  factory _$RenovationSummaryModelCopyWith(_RenovationSummaryModel value, $Res Function(_RenovationSummaryModel) _then) = __$RenovationSummaryModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'unit_id') String unitId,@JsonKey(name: 'unit_number') String unitNumber,@JsonKey(name: 'renovation_type') String renovationType,@JsonKey(name: 'started_at') String startedAt,@JsonKey(name: 'completed_at') String? completedAt, double? cost, String? contractor,@JsonKey(name: 'created_at') String createdAt
});




}
/// @nodoc
class __$RenovationSummaryModelCopyWithImpl<$Res>
    implements _$RenovationSummaryModelCopyWith<$Res> {
  __$RenovationSummaryModelCopyWithImpl(this._self, this._then);

  final _RenovationSummaryModel _self;
  final $Res Function(_RenovationSummaryModel) _then;

/// Create a copy of RenovationSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? unitId = null,Object? unitNumber = null,Object? renovationType = null,Object? startedAt = null,Object? completedAt = freezed,Object? cost = freezed,Object? contractor = freezed,Object? createdAt = null,}) {
  return _then(_RenovationSummaryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,unitId: null == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String,unitNumber: null == unitNumber ? _self.unitNumber : unitNumber // ignore: cast_nullable_to_non_nullable
as String,renovationType: null == renovationType ? _self.renovationType : renovationType // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as String,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as String?,cost: freezed == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as double?,contractor: freezed == contractor ? _self.contractor : contractor // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
