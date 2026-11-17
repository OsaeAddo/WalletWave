// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wallet_balance.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WalletBalance {
  String get address;
  double get nativeBalanceEther;
  String get symbol;

  /// Create a copy of WalletBalance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WalletBalanceCopyWith<WalletBalance> get copyWith =>
      _$WalletBalanceCopyWithImpl<WalletBalance>(
          this as WalletBalance, _$identity);

  /// Serializes this WalletBalance to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WalletBalance &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.nativeBalanceEther, nativeBalanceEther) ||
                other.nativeBalanceEther == nativeBalanceEther) &&
            (identical(other.symbol, symbol) || other.symbol == symbol));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, address, nativeBalanceEther, symbol);

  @override
  String toString() {
    return 'WalletBalance(address: $address, nativeBalanceEther: $nativeBalanceEther, symbol: $symbol)';
  }
}

/// @nodoc
abstract mixin class $WalletBalanceCopyWith<$Res> {
  factory $WalletBalanceCopyWith(
          WalletBalance value, $Res Function(WalletBalance) _then) =
      _$WalletBalanceCopyWithImpl;
  @useResult
  $Res call({String address, double nativeBalanceEther, String symbol});
}

/// @nodoc
class _$WalletBalanceCopyWithImpl<$Res>
    implements $WalletBalanceCopyWith<$Res> {
  _$WalletBalanceCopyWithImpl(this._self, this._then);

  final WalletBalance _self;
  final $Res Function(WalletBalance) _then;

  /// Create a copy of WalletBalance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? address = null,
    Object? nativeBalanceEther = null,
    Object? symbol = null,
  }) {
    return _then(_self.copyWith(
      address: null == address
          ? _self.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      nativeBalanceEther: null == nativeBalanceEther
          ? _self.nativeBalanceEther
          : nativeBalanceEther // ignore: cast_nullable_to_non_nullable
              as double,
      symbol: null == symbol
          ? _self.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [WalletBalance].
extension WalletBalancePatterns on WalletBalance {
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

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_WalletBalance value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WalletBalance() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_WalletBalance value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WalletBalance():
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_WalletBalance value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WalletBalance() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(String address, double nativeBalanceEther, String symbol)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WalletBalance() when $default != null:
        return $default(_that.address, _that.nativeBalanceEther, _that.symbol);
      case _:
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

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(String address, double nativeBalanceEther, String symbol)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WalletBalance():
        return $default(_that.address, _that.nativeBalanceEther, _that.symbol);
      case _:
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(String address, double nativeBalanceEther, String symbol)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WalletBalance() when $default != null:
        return $default(_that.address, _that.nativeBalanceEther, _that.symbol);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _WalletBalance implements WalletBalance {
  const _WalletBalance(
      {required this.address,
      required this.nativeBalanceEther,
      required this.symbol});
  factory _WalletBalance.fromJson(Map<String, dynamic> json) =>
      _$WalletBalanceFromJson(json);

  @override
  final String address;
  @override
  final double nativeBalanceEther;
  @override
  final String symbol;

  /// Create a copy of WalletBalance
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WalletBalanceCopyWith<_WalletBalance> get copyWith =>
      __$WalletBalanceCopyWithImpl<_WalletBalance>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$WalletBalanceToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WalletBalance &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.nativeBalanceEther, nativeBalanceEther) ||
                other.nativeBalanceEther == nativeBalanceEther) &&
            (identical(other.symbol, symbol) || other.symbol == symbol));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, address, nativeBalanceEther, symbol);

  @override
  String toString() {
    return 'WalletBalance(address: $address, nativeBalanceEther: $nativeBalanceEther, symbol: $symbol)';
  }
}

/// @nodoc
abstract mixin class _$WalletBalanceCopyWith<$Res>
    implements $WalletBalanceCopyWith<$Res> {
  factory _$WalletBalanceCopyWith(
          _WalletBalance value, $Res Function(_WalletBalance) _then) =
      __$WalletBalanceCopyWithImpl;
  @override
  @useResult
  $Res call({String address, double nativeBalanceEther, String symbol});
}

/// @nodoc
class __$WalletBalanceCopyWithImpl<$Res>
    implements _$WalletBalanceCopyWith<$Res> {
  __$WalletBalanceCopyWithImpl(this._self, this._then);

  final _WalletBalance _self;
  final $Res Function(_WalletBalance) _then;

  /// Create a copy of WalletBalance
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? address = null,
    Object? nativeBalanceEther = null,
    Object? symbol = null,
  }) {
    return _then(_WalletBalance(
      address: null == address
          ? _self.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      nativeBalanceEther: null == nativeBalanceEther
          ? _self.nativeBalanceEther
          : nativeBalanceEther // ignore: cast_nullable_to_non_nullable
              as double,
      symbol: null == symbol
          ? _self.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
