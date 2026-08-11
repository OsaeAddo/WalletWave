// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'market_coin.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MarketCoin {

 String get id; String get symbol; String get name;@JsonKey(name: 'current_price') double get currentPrice;@JsonKey(name: 'price_change_percentage_24h') double? get priceChange24h;@JsonKey(name: 'image') String get imageUrl;
/// Create a copy of MarketCoin
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarketCoinCopyWith<MarketCoin> get copyWith => _$MarketCoinCopyWithImpl<MarketCoin>(this as MarketCoin, _$identity);

  /// Serializes this MarketCoin to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarketCoin&&(identical(other.id, id) || other.id == id)&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.name, name) || other.name == name)&&(identical(other.currentPrice, currentPrice) || other.currentPrice == currentPrice)&&(identical(other.priceChange24h, priceChange24h) || other.priceChange24h == priceChange24h)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,symbol,name,currentPrice,priceChange24h,imageUrl);

@override
String toString() {
  return 'MarketCoin(id: $id, symbol: $symbol, name: $name, currentPrice: $currentPrice, priceChange24h: $priceChange24h, imageUrl: $imageUrl)';
}


}

/// @nodoc
abstract mixin class $MarketCoinCopyWith<$Res>  {
  factory $MarketCoinCopyWith(MarketCoin value, $Res Function(MarketCoin) _then) = _$MarketCoinCopyWithImpl;
@useResult
$Res call({
 String id, String symbol, String name,@JsonKey(name: 'current_price') double currentPrice,@JsonKey(name: 'price_change_percentage_24h') double? priceChange24h,@JsonKey(name: 'image') String imageUrl
});




}
/// @nodoc
class _$MarketCoinCopyWithImpl<$Res>
    implements $MarketCoinCopyWith<$Res> {
  _$MarketCoinCopyWithImpl(this._self, this._then);

  final MarketCoin _self;
  final $Res Function(MarketCoin) _then;

/// Create a copy of MarketCoin
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? symbol = null,Object? name = null,Object? currentPrice = null,Object? priceChange24h = freezed,Object? imageUrl = null,}) {
  return _then(MarketCoin(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,currentPrice: null == currentPrice ? _self.currentPrice : currentPrice // ignore: cast_nullable_to_non_nullable
as double,priceChange24h: freezed == priceChange24h ? _self.priceChange24h : priceChange24h // ignore: cast_nullable_to_non_nullable
as double?,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MarketCoin].
extension MarketCoinPatterns on MarketCoin {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MarketCoin value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MarketCoin() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MarketCoin value)  $default,){
final _that = this;
switch (_that) {
case _MarketCoin():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MarketCoin value)?  $default,){
final _that = this;
switch (_that) {
case _MarketCoin() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String symbol,  String name, @JsonKey(name: 'current_price')  double currentPrice, @JsonKey(name: 'price_change_percentage_24h')  double? priceChange24h, @JsonKey(name: 'image')  String imageUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MarketCoin() when $default != null:
return $default(_that.id,_that.symbol,_that.name,_that.currentPrice,_that.priceChange24h,_that.imageUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String symbol,  String name, @JsonKey(name: 'current_price')  double currentPrice, @JsonKey(name: 'price_change_percentage_24h')  double? priceChange24h, @JsonKey(name: 'image')  String imageUrl)  $default,) {final _that = this;
switch (_that) {
case _MarketCoin():
return $default(_that.id,_that.symbol,_that.name,_that.currentPrice,_that.priceChange24h,_that.imageUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String symbol,  String name, @JsonKey(name: 'current_price')  double currentPrice, @JsonKey(name: 'price_change_percentage_24h')  double? priceChange24h, @JsonKey(name: 'image')  String imageUrl)?  $default,) {final _that = this;
switch (_that) {
case _MarketCoin() when $default != null:
return $default(_that.id,_that.symbol,_that.name,_that.currentPrice,_that.priceChange24h,_that.imageUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MarketCoin implements MarketCoin {
  const _MarketCoin({required this.id, required this.symbol, required this.name, @JsonKey(name: 'current_price') required this.currentPrice, @JsonKey(name: 'price_change_percentage_24h') this.priceChange24h, @JsonKey(name: 'image') required this.imageUrl});
  factory _MarketCoin.fromJson(Map<String, dynamic> json) => _$MarketCoinFromJson(json);

@override final  String id;
@override final  String symbol;
@override final  String name;
@override@JsonKey(name: 'current_price') final  double currentPrice;
@override@JsonKey(name: 'price_change_percentage_24h') final  double? priceChange24h;
@override@JsonKey(name: 'image') final  String imageUrl;

/// Create a copy of MarketCoin
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MarketCoinCopyWith<_MarketCoin> get copyWith => __$MarketCoinCopyWithImpl<_MarketCoin>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MarketCoinToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MarketCoin&&(identical(other.id, id) || other.id == id)&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.name, name) || other.name == name)&&(identical(other.currentPrice, currentPrice) || other.currentPrice == currentPrice)&&(identical(other.priceChange24h, priceChange24h) || other.priceChange24h == priceChange24h)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,symbol,name,currentPrice,priceChange24h,imageUrl);

@override
String toString() {
  return 'MarketCoin(id: $id, symbol: $symbol, name: $name, currentPrice: $currentPrice, priceChange24h: $priceChange24h, imageUrl: $imageUrl)';
}


}

/// @nodoc
abstract mixin class _$MarketCoinCopyWith<$Res> implements $MarketCoinCopyWith<$Res> {
  factory _$MarketCoinCopyWith(_MarketCoin value, $Res Function(_MarketCoin) _then) = __$MarketCoinCopyWithImpl;
@override @useResult
$Res call({
 String id, String symbol, String name,@JsonKey(name: 'current_price') double currentPrice,@JsonKey(name: 'price_change_percentage_24h') double? priceChange24h,@JsonKey(name: 'image') String imageUrl
});




}
/// @nodoc
class __$MarketCoinCopyWithImpl<$Res>
    implements _$MarketCoinCopyWith<$Res> {
  __$MarketCoinCopyWithImpl(this._self, this._then);

  final _MarketCoin _self;
  final $Res Function(_MarketCoin) _then;

/// Create a copy of MarketCoin
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? symbol = null,Object? name = null,Object? currentPrice = null,Object? priceChange24h = freezed,Object? imageUrl = null,}) {
  return _then(_MarketCoin(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,currentPrice: null == currentPrice ? _self.currentPrice : currentPrice // ignore: cast_nullable_to_non_nullable
as double,priceChange24h: freezed == priceChange24h ? _self.priceChange24h : priceChange24h // ignore: cast_nullable_to_non_nullable
as double?,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
