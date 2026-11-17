// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'market_coin_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMarketCoinEntityCollection on Isar {
  IsarCollection<MarketCoinEntity> get marketCoinEntitys => this.collection();
}

const MarketCoinEntitySchema = CollectionSchema(
  name: r'MarketCoinEntity',
  id: -1136715034776446824,
  properties: {
    r'coinId': PropertySchema(
      id: 0,
      name: r'coinId',
      type: IsarType.string,
    ),
    r'currentPrice': PropertySchema(
      id: 1,
      name: r'currentPrice',
      type: IsarType.double,
    ),
    r'imageUrl': PropertySchema(
      id: 2,
      name: r'imageUrl',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 3,
      name: r'name',
      type: IsarType.string,
    ),
    r'priceChange24h': PropertySchema(
      id: 4,
      name: r'priceChange24h',
      type: IsarType.double,
    ),
    r'symbol': PropertySchema(
      id: 5,
      name: r'symbol',
      type: IsarType.string,
    )
  },
  estimateSize: _marketCoinEntityEstimateSize,
  serialize: _marketCoinEntitySerialize,
  deserialize: _marketCoinEntityDeserialize,
  deserializeProp: _marketCoinEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'coinId': IndexSchema(
      id: 7477993230051464014,
      name: r'coinId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'coinId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _marketCoinEntityGetId,
  getLinks: _marketCoinEntityGetLinks,
  attach: _marketCoinEntityAttach,
  version: '3.3.2',
);

int _marketCoinEntityEstimateSize(
  MarketCoinEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.coinId.length * 3;
  bytesCount += 3 + object.imageUrl.length * 3;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.symbol.length * 3;
  return bytesCount;
}

void _marketCoinEntitySerialize(
  MarketCoinEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.coinId);
  writer.writeDouble(offsets[1], object.currentPrice);
  writer.writeString(offsets[2], object.imageUrl);
  writer.writeString(offsets[3], object.name);
  writer.writeDouble(offsets[4], object.priceChange24h);
  writer.writeString(offsets[5], object.symbol);
}

MarketCoinEntity _marketCoinEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MarketCoinEntity();
  object.coinId = reader.readString(offsets[0]);
  object.currentPrice = reader.readDouble(offsets[1]);
  object.id = id;
  object.imageUrl = reader.readString(offsets[2]);
  object.name = reader.readString(offsets[3]);
  object.priceChange24h = reader.readDoubleOrNull(offsets[4]);
  object.symbol = reader.readString(offsets[5]);
  return object;
}

P _marketCoinEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDoubleOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _marketCoinEntityGetId(MarketCoinEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _marketCoinEntityGetLinks(MarketCoinEntity object) {
  return [];
}

void _marketCoinEntityAttach(
    IsarCollection<dynamic> col, Id id, MarketCoinEntity object) {
  object.id = id;
}

extension MarketCoinEntityByIndex on IsarCollection<MarketCoinEntity> {
  Future<MarketCoinEntity?> getByCoinId(String coinId) {
    return getByIndex(r'coinId', [coinId]);
  }

  MarketCoinEntity? getByCoinIdSync(String coinId) {
    return getByIndexSync(r'coinId', [coinId]);
  }

  Future<bool> deleteByCoinId(String coinId) {
    return deleteByIndex(r'coinId', [coinId]);
  }

  bool deleteByCoinIdSync(String coinId) {
    return deleteByIndexSync(r'coinId', [coinId]);
  }

  Future<List<MarketCoinEntity?>> getAllByCoinId(List<String> coinIdValues) {
    final values = coinIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'coinId', values);
  }

  List<MarketCoinEntity?> getAllByCoinIdSync(List<String> coinIdValues) {
    final values = coinIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'coinId', values);
  }

  Future<int> deleteAllByCoinId(List<String> coinIdValues) {
    final values = coinIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'coinId', values);
  }

  int deleteAllByCoinIdSync(List<String> coinIdValues) {
    final values = coinIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'coinId', values);
  }

  Future<Id> putByCoinId(MarketCoinEntity object) {
    return putByIndex(r'coinId', object);
  }

  Id putByCoinIdSync(MarketCoinEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'coinId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCoinId(List<MarketCoinEntity> objects) {
    return putAllByIndex(r'coinId', objects);
  }

  List<Id> putAllByCoinIdSync(List<MarketCoinEntity> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'coinId', objects, saveLinks: saveLinks);
  }
}

extension MarketCoinEntityQueryWhereSort
    on QueryBuilder<MarketCoinEntity, MarketCoinEntity, QWhere> {
  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension MarketCoinEntityQueryWhere
    on QueryBuilder<MarketCoinEntity, MarketCoinEntity, QWhereClause> {
  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterWhereClause>
      coinIdEqualTo(String coinId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'coinId',
        value: [coinId],
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterWhereClause>
      coinIdNotEqualTo(String coinId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'coinId',
              lower: [],
              upper: [coinId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'coinId',
              lower: [coinId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'coinId',
              lower: [coinId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'coinId',
              lower: [],
              upper: [coinId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension MarketCoinEntityQueryFilter
    on QueryBuilder<MarketCoinEntity, MarketCoinEntity, QFilterCondition> {
  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      coinIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'coinId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      coinIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'coinId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      coinIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'coinId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      coinIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'coinId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      coinIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'coinId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      coinIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'coinId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      coinIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'coinId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      coinIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'coinId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      coinIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'coinId',
        value: '',
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      coinIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'coinId',
        value: '',
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      currentPriceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      currentPriceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      currentPriceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      currentPriceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentPrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      imageUrlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      imageUrlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      imageUrlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      imageUrlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'imageUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      imageUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      imageUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      imageUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      imageUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'imageUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      imageUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imageUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      imageUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'imageUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      priceChange24hIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'priceChange24h',
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      priceChange24hIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'priceChange24h',
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      priceChange24hEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'priceChange24h',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      priceChange24hGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'priceChange24h',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      priceChange24hLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'priceChange24h',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      priceChange24hBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'priceChange24h',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      symbolEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'symbol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      symbolGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'symbol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      symbolLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'symbol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      symbolBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'symbol',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      symbolStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'symbol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      symbolEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'symbol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      symbolContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'symbol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      symbolMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'symbol',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      symbolIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'symbol',
        value: '',
      ));
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterFilterCondition>
      symbolIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'symbol',
        value: '',
      ));
    });
  }
}

extension MarketCoinEntityQueryObject
    on QueryBuilder<MarketCoinEntity, MarketCoinEntity, QFilterCondition> {}

extension MarketCoinEntityQueryLinks
    on QueryBuilder<MarketCoinEntity, MarketCoinEntity, QFilterCondition> {}

extension MarketCoinEntityQuerySortBy
    on QueryBuilder<MarketCoinEntity, MarketCoinEntity, QSortBy> {
  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterSortBy>
      sortByCoinId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coinId', Sort.asc);
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterSortBy>
      sortByCoinIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coinId', Sort.desc);
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterSortBy>
      sortByCurrentPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentPrice', Sort.asc);
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterSortBy>
      sortByCurrentPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentPrice', Sort.desc);
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterSortBy>
      sortByImageUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.asc);
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterSortBy>
      sortByImageUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.desc);
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterSortBy>
      sortByPriceChange24h() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priceChange24h', Sort.asc);
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterSortBy>
      sortByPriceChange24hDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priceChange24h', Sort.desc);
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterSortBy>
      sortBySymbol() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'symbol', Sort.asc);
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterSortBy>
      sortBySymbolDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'symbol', Sort.desc);
    });
  }
}

extension MarketCoinEntityQuerySortThenBy
    on QueryBuilder<MarketCoinEntity, MarketCoinEntity, QSortThenBy> {
  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterSortBy>
      thenByCoinId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coinId', Sort.asc);
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterSortBy>
      thenByCoinIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coinId', Sort.desc);
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterSortBy>
      thenByCurrentPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentPrice', Sort.asc);
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterSortBy>
      thenByCurrentPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentPrice', Sort.desc);
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterSortBy>
      thenByImageUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.asc);
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterSortBy>
      thenByImageUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.desc);
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterSortBy>
      thenByPriceChange24h() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priceChange24h', Sort.asc);
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterSortBy>
      thenByPriceChange24hDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priceChange24h', Sort.desc);
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterSortBy>
      thenBySymbol() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'symbol', Sort.asc);
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QAfterSortBy>
      thenBySymbolDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'symbol', Sort.desc);
    });
  }
}

extension MarketCoinEntityQueryWhereDistinct
    on QueryBuilder<MarketCoinEntity, MarketCoinEntity, QDistinct> {
  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QDistinct> distinctByCoinId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'coinId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QDistinct>
      distinctByCurrentPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentPrice');
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QDistinct>
      distinctByImageUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imageUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QDistinct>
      distinctByPriceChange24h() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'priceChange24h');
    });
  }

  QueryBuilder<MarketCoinEntity, MarketCoinEntity, QDistinct> distinctBySymbol(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'symbol', caseSensitive: caseSensitive);
    });
  }
}

extension MarketCoinEntityQueryProperty
    on QueryBuilder<MarketCoinEntity, MarketCoinEntity, QQueryProperty> {
  QueryBuilder<MarketCoinEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<MarketCoinEntity, String, QQueryOperations> coinIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'coinId');
    });
  }

  QueryBuilder<MarketCoinEntity, double, QQueryOperations>
      currentPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentPrice');
    });
  }

  QueryBuilder<MarketCoinEntity, String, QQueryOperations> imageUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imageUrl');
    });
  }

  QueryBuilder<MarketCoinEntity, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<MarketCoinEntity, double?, QQueryOperations>
      priceChange24hProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'priceChange24h');
    });
  }

  QueryBuilder<MarketCoinEntity, String, QQueryOperations> symbolProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'symbol');
    });
  }
}
