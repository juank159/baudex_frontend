// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_purchase_order_item.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarPurchaseOrderItemCollection on Isar {
  IsarCollection<IsarPurchaseOrderItem> get isarPurchaseOrderItems =>
      this.collection();
}

const IsarPurchaseOrderItemSchema = CollectionSchema(
  name: r'IsarPurchaseOrderItem',
  id: 870382677725089335,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'damagedQuantity': PropertySchema(
      id: 1,
      name: r'damagedQuantity',
      type: IsarType.long,
    ),
    r'discountAmount': PropertySchema(
      id: 2,
      name: r'discountAmount',
      type: IsarType.double,
    ),
    r'discountPercentage': PropertySchema(
      id: 3,
      name: r'discountPercentage',
      type: IsarType.double,
    ),
    r'itemId': PropertySchema(
      id: 4,
      name: r'itemId',
      type: IsarType.string,
    ),
    r'missingQuantity': PropertySchema(
      id: 5,
      name: r'missingQuantity',
      type: IsarType.long,
    ),
    r'notes': PropertySchema(
      id: 6,
      name: r'notes',
      type: IsarType.string,
    ),
    r'productCode': PropertySchema(
      id: 7,
      name: r'productCode',
      type: IsarType.string,
    ),
    r'productDescription': PropertySchema(
      id: 8,
      name: r'productDescription',
      type: IsarType.string,
    ),
    r'productId': PropertySchema(
      id: 9,
      name: r'productId',
      type: IsarType.string,
    ),
    r'productName': PropertySchema(
      id: 10,
      name: r'productName',
      type: IsarType.string,
    ),
    r'purchaseOrderServerId': PropertySchema(
      id: 11,
      name: r'purchaseOrderServerId',
      type: IsarType.string,
    ),
    r'quantity': PropertySchema(
      id: 12,
      name: r'quantity',
      type: IsarType.long,
    ),
    r'receivedQuantity': PropertySchema(
      id: 13,
      name: r'receivedQuantity',
      type: IsarType.long,
    ),
    r'subtotal': PropertySchema(
      id: 14,
      name: r'subtotal',
      type: IsarType.double,
    ),
    r'taxAmount': PropertySchema(
      id: 15,
      name: r'taxAmount',
      type: IsarType.double,
    ),
    r'taxPercentage': PropertySchema(
      id: 16,
      name: r'taxPercentage',
      type: IsarType.double,
    ),
    r'totalAmount': PropertySchema(
      id: 17,
      name: r'totalAmount',
      type: IsarType.double,
    ),
    r'unit': PropertySchema(
      id: 18,
      name: r'unit',
      type: IsarType.string,
    ),
    r'unitPrice': PropertySchema(
      id: 19,
      name: r'unitPrice',
      type: IsarType.double,
    ),
    r'updatedAt': PropertySchema(
      id: 20,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _isarPurchaseOrderItemEstimateSize,
  serialize: _isarPurchaseOrderItemSerialize,
  deserialize: _isarPurchaseOrderItemDeserialize,
  deserializeProp: _isarPurchaseOrderItemDeserializeProp,
  idName: r'id',
  indexes: {
    r'itemId': IndexSchema(
      id: -5342806140158601489,
      name: r'itemId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'itemId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'purchaseOrderServerId': IndexSchema(
      id: -925600879677323051,
      name: r'purchaseOrderServerId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'purchaseOrderServerId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarPurchaseOrderItemGetId,
  getLinks: _isarPurchaseOrderItemGetLinks,
  attach: _isarPurchaseOrderItemAttach,
  version: '3.1.0+1',
);

int _isarPurchaseOrderItemEstimateSize(
  IsarPurchaseOrderItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.itemId.length * 3;
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.productCode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.productDescription;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.productId.length * 3;
  bytesCount += 3 + object.productName.length * 3;
  {
    final value = object.purchaseOrderServerId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.unit.length * 3;
  return bytesCount;
}

void _isarPurchaseOrderItemSerialize(
  IsarPurchaseOrderItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeLong(offsets[1], object.damagedQuantity);
  writer.writeDouble(offsets[2], object.discountAmount);
  writer.writeDouble(offsets[3], object.discountPercentage);
  writer.writeString(offsets[4], object.itemId);
  writer.writeLong(offsets[5], object.missingQuantity);
  writer.writeString(offsets[6], object.notes);
  writer.writeString(offsets[7], object.productCode);
  writer.writeString(offsets[8], object.productDescription);
  writer.writeString(offsets[9], object.productId);
  writer.writeString(offsets[10], object.productName);
  writer.writeString(offsets[11], object.purchaseOrderServerId);
  writer.writeLong(offsets[12], object.quantity);
  writer.writeLong(offsets[13], object.receivedQuantity);
  writer.writeDouble(offsets[14], object.subtotal);
  writer.writeDouble(offsets[15], object.taxAmount);
  writer.writeDouble(offsets[16], object.taxPercentage);
  writer.writeDouble(offsets[17], object.totalAmount);
  writer.writeString(offsets[18], object.unit);
  writer.writeDouble(offsets[19], object.unitPrice);
  writer.writeDateTime(offsets[20], object.updatedAt);
}

IsarPurchaseOrderItem _isarPurchaseOrderItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarPurchaseOrderItem();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.damagedQuantity = reader.readLongOrNull(offsets[1]);
  object.discountAmount = reader.readDouble(offsets[2]);
  object.discountPercentage = reader.readDouble(offsets[3]);
  object.id = id;
  object.itemId = reader.readString(offsets[4]);
  object.missingQuantity = reader.readLongOrNull(offsets[5]);
  object.notes = reader.readStringOrNull(offsets[6]);
  object.productCode = reader.readStringOrNull(offsets[7]);
  object.productDescription = reader.readStringOrNull(offsets[8]);
  object.productId = reader.readString(offsets[9]);
  object.productName = reader.readString(offsets[10]);
  object.purchaseOrderServerId = reader.readStringOrNull(offsets[11]);
  object.quantity = reader.readLong(offsets[12]);
  object.receivedQuantity = reader.readLongOrNull(offsets[13]);
  object.subtotal = reader.readDouble(offsets[14]);
  object.taxAmount = reader.readDouble(offsets[15]);
  object.taxPercentage = reader.readDouble(offsets[16]);
  object.totalAmount = reader.readDouble(offsets[17]);
  object.unit = reader.readString(offsets[18]);
  object.unitPrice = reader.readDouble(offsets[19]);
  object.updatedAt = reader.readDateTime(offsets[20]);
  return object;
}

P _isarPurchaseOrderItemDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readLong(offset)) as P;
    case 13:
      return (reader.readLongOrNull(offset)) as P;
    case 14:
      return (reader.readDouble(offset)) as P;
    case 15:
      return (reader.readDouble(offset)) as P;
    case 16:
      return (reader.readDouble(offset)) as P;
    case 17:
      return (reader.readDouble(offset)) as P;
    case 18:
      return (reader.readString(offset)) as P;
    case 19:
      return (reader.readDouble(offset)) as P;
    case 20:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarPurchaseOrderItemGetId(IsarPurchaseOrderItem object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarPurchaseOrderItemGetLinks(
    IsarPurchaseOrderItem object) {
  return [];
}

void _isarPurchaseOrderItemAttach(
    IsarCollection<dynamic> col, Id id, IsarPurchaseOrderItem object) {
  object.id = id;
}

extension IsarPurchaseOrderItemByIndex
    on IsarCollection<IsarPurchaseOrderItem> {
  Future<IsarPurchaseOrderItem?> getByItemId(String itemId) {
    return getByIndex(r'itemId', [itemId]);
  }

  IsarPurchaseOrderItem? getByItemIdSync(String itemId) {
    return getByIndexSync(r'itemId', [itemId]);
  }

  Future<bool> deleteByItemId(String itemId) {
    return deleteByIndex(r'itemId', [itemId]);
  }

  bool deleteByItemIdSync(String itemId) {
    return deleteByIndexSync(r'itemId', [itemId]);
  }

  Future<List<IsarPurchaseOrderItem?>> getAllByItemId(
      List<String> itemIdValues) {
    final values = itemIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'itemId', values);
  }

  List<IsarPurchaseOrderItem?> getAllByItemIdSync(List<String> itemIdValues) {
    final values = itemIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'itemId', values);
  }

  Future<int> deleteAllByItemId(List<String> itemIdValues) {
    final values = itemIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'itemId', values);
  }

  int deleteAllByItemIdSync(List<String> itemIdValues) {
    final values = itemIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'itemId', values);
  }

  Future<Id> putByItemId(IsarPurchaseOrderItem object) {
    return putByIndex(r'itemId', object);
  }

  Id putByItemIdSync(IsarPurchaseOrderItem object, {bool saveLinks = true}) {
    return putByIndexSync(r'itemId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByItemId(List<IsarPurchaseOrderItem> objects) {
    return putAllByIndex(r'itemId', objects);
  }

  List<Id> putAllByItemIdSync(List<IsarPurchaseOrderItem> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'itemId', objects, saveLinks: saveLinks);
  }
}

extension IsarPurchaseOrderItemQueryWhereSort
    on QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QWhere> {
  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarPurchaseOrderItemQueryWhere on QueryBuilder<IsarPurchaseOrderItem,
    IsarPurchaseOrderItem, QWhereClause> {
  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterWhereClause>
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

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterWhereClause>
      idBetween(
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

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterWhereClause>
      itemIdEqualTo(String itemId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'itemId',
        value: [itemId],
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterWhereClause>
      itemIdNotEqualTo(String itemId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'itemId',
              lower: [],
              upper: [itemId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'itemId',
              lower: [itemId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'itemId',
              lower: [itemId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'itemId',
              lower: [],
              upper: [itemId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterWhereClause>
      purchaseOrderServerIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'purchaseOrderServerId',
        value: [null],
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterWhereClause>
      purchaseOrderServerIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'purchaseOrderServerId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterWhereClause>
      purchaseOrderServerIdEqualTo(String? purchaseOrderServerId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'purchaseOrderServerId',
        value: [purchaseOrderServerId],
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterWhereClause>
      purchaseOrderServerIdNotEqualTo(String? purchaseOrderServerId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'purchaseOrderServerId',
              lower: [],
              upper: [purchaseOrderServerId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'purchaseOrderServerId',
              lower: [purchaseOrderServerId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'purchaseOrderServerId',
              lower: [purchaseOrderServerId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'purchaseOrderServerId',
              lower: [],
              upper: [purchaseOrderServerId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarPurchaseOrderItemQueryFilter on QueryBuilder<
    IsarPurchaseOrderItem, IsarPurchaseOrderItem, QFilterCondition> {
  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> damagedQuantityIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'damagedQuantity',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> damagedQuantityIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'damagedQuantity',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> damagedQuantityEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'damagedQuantity',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> damagedQuantityGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'damagedQuantity',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> damagedQuantityLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'damagedQuantity',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> damagedQuantityBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'damagedQuantity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> discountAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'discountAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> discountAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'discountAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> discountAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'discountAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> discountAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'discountAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> discountPercentageEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'discountPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> discountPercentageGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'discountPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> discountPercentageLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'discountPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> discountPercentageBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'discountPercentage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> idLessThan(
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

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> idBetween(
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

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> itemIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'itemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> itemIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'itemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> itemIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'itemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> itemIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'itemId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> itemIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'itemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> itemIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'itemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
          QAfterFilterCondition>
      itemIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'itemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
          QAfterFilterCondition>
      itemIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'itemId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> itemIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'itemId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> itemIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'itemId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> missingQuantityIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'missingQuantity',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> missingQuantityIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'missingQuantity',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> missingQuantityEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'missingQuantity',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> missingQuantityGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'missingQuantity',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> missingQuantityLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'missingQuantity',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> missingQuantityBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'missingQuantity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> notesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> notesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> notesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> notesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> notesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> notesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
          QAfterFilterCondition>
      notesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
          QAfterFilterCondition>
      notesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'productCode',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'productCode',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productCodeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productCodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'productCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productCodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'productCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productCodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'productCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'productCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'productCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
          QAfterFilterCondition>
      productCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'productCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
          QAfterFilterCondition>
      productCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'productCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productCode',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'productCode',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productDescriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'productDescription',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productDescriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'productDescription',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productDescriptionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productDescriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'productDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productDescriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'productDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productDescriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'productDescription',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productDescriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'productDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productDescriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'productDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
          QAfterFilterCondition>
      productDescriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'productDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
          QAfterFilterCondition>
      productDescriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'productDescription',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productDescriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productDescription',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productDescriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'productDescription',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'productId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'productId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'productId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'productId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'productId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
          QAfterFilterCondition>
      productIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'productId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
          QAfterFilterCondition>
      productIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'productId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'productId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'productName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
          QAfterFilterCondition>
      productNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
          QAfterFilterCondition>
      productNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'productName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productName',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> productNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'productName',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> purchaseOrderServerIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'purchaseOrderServerId',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> purchaseOrderServerIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'purchaseOrderServerId',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> purchaseOrderServerIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'purchaseOrderServerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> purchaseOrderServerIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'purchaseOrderServerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> purchaseOrderServerIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'purchaseOrderServerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> purchaseOrderServerIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'purchaseOrderServerId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> purchaseOrderServerIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'purchaseOrderServerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> purchaseOrderServerIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'purchaseOrderServerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
          QAfterFilterCondition>
      purchaseOrderServerIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'purchaseOrderServerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
          QAfterFilterCondition>
      purchaseOrderServerIdMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'purchaseOrderServerId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> purchaseOrderServerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'purchaseOrderServerId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> purchaseOrderServerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'purchaseOrderServerId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> quantityEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'quantity',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> quantityGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'quantity',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> quantityLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'quantity',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> quantityBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'quantity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> receivedQuantityIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'receivedQuantity',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> receivedQuantityIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'receivedQuantity',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> receivedQuantityEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'receivedQuantity',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> receivedQuantityGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'receivedQuantity',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> receivedQuantityLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'receivedQuantity',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> receivedQuantityBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'receivedQuantity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> subtotalEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subtotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> subtotalGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subtotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> subtotalLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subtotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> subtotalBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subtotal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> taxAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'taxAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> taxAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'taxAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> taxAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'taxAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> taxAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'taxAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> taxPercentageEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'taxPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> taxPercentageGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'taxPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> taxPercentageLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'taxPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> taxPercentageBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'taxPercentage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> totalAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> totalAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> totalAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> totalAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> unitEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> unitGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'unit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> unitLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'unit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> unitBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'unit',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> unitStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'unit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> unitEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'unit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
          QAfterFilterCondition>
      unitContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'unit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
          QAfterFilterCondition>
      unitMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'unit',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> unitIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unit',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> unitIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'unit',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> unitPriceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unitPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> unitPriceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'unitPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> unitPriceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'unitPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> unitPriceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'unitPrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem,
      QAfterFilterCondition> updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IsarPurchaseOrderItemQueryObject on QueryBuilder<
    IsarPurchaseOrderItem, IsarPurchaseOrderItem, QFilterCondition> {}

extension IsarPurchaseOrderItemQueryLinks on QueryBuilder<IsarPurchaseOrderItem,
    IsarPurchaseOrderItem, QFilterCondition> {}

extension IsarPurchaseOrderItemQuerySortBy
    on QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QSortBy> {
  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByDamagedQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'damagedQuantity', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByDamagedQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'damagedQuantity', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByDiscountAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByDiscountAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByDiscountPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountPercentage', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByDiscountPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountPercentage', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemId', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemId', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByMissingQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'missingQuantity', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByMissingQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'missingQuantity', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByProductCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productCode', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByProductCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productCode', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByProductDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productDescription', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByProductDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productDescription', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByProductIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByProductName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByProductNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByPurchaseOrderServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseOrderServerId', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByPurchaseOrderServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseOrderServerId', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByReceivedQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receivedQuantity', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByReceivedQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receivedQuantity', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortBySubtotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortBySubtotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByTaxAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxAmount', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByTaxAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxAmount', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByTaxPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxPercentage', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByTaxPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxPercentage', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByTotalAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unit', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unit', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByUnitPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitPrice', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByUnitPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitPrice', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension IsarPurchaseOrderItemQuerySortThenBy
    on QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QSortThenBy> {
  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByDamagedQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'damagedQuantity', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByDamagedQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'damagedQuantity', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByDiscountAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByDiscountAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByDiscountPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountPercentage', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByDiscountPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountPercentage', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemId', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemId', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByMissingQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'missingQuantity', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByMissingQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'missingQuantity', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByProductCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productCode', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByProductCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productCode', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByProductDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productDescription', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByProductDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productDescription', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByProductIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByProductName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByProductNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByPurchaseOrderServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseOrderServerId', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByPurchaseOrderServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseOrderServerId', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByReceivedQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receivedQuantity', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByReceivedQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receivedQuantity', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenBySubtotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenBySubtotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByTaxAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxAmount', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByTaxAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxAmount', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByTaxPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxPercentage', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByTaxPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxPercentage', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByTotalAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unit', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unit', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByUnitPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitPrice', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByUnitPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitPrice', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension IsarPurchaseOrderItemQueryWhereDistinct
    on QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QDistinct> {
  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QDistinct>
      distinctByDamagedQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'damagedQuantity');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QDistinct>
      distinctByDiscountAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'discountAmount');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QDistinct>
      distinctByDiscountPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'discountPercentage');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QDistinct>
      distinctByItemId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'itemId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QDistinct>
      distinctByMissingQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'missingQuantity');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QDistinct>
      distinctByNotes({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QDistinct>
      distinctByProductCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productCode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QDistinct>
      distinctByProductDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productDescription',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QDistinct>
      distinctByProductId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QDistinct>
      distinctByProductName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QDistinct>
      distinctByPurchaseOrderServerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'purchaseOrderServerId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QDistinct>
      distinctByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'quantity');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QDistinct>
      distinctByReceivedQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'receivedQuantity');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QDistinct>
      distinctBySubtotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subtotal');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QDistinct>
      distinctByTaxAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'taxAmount');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QDistinct>
      distinctByTaxPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'taxPercentage');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QDistinct>
      distinctByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalAmount');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QDistinct>
      distinctByUnit({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unit', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QDistinct>
      distinctByUnitPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unitPrice');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, IsarPurchaseOrderItem, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension IsarPurchaseOrderItemQueryProperty on QueryBuilder<
    IsarPurchaseOrderItem, IsarPurchaseOrderItem, QQueryProperty> {
  QueryBuilder<IsarPurchaseOrderItem, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, int?, QQueryOperations>
      damagedQuantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'damagedQuantity');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, double, QQueryOperations>
      discountAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'discountAmount');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, double, QQueryOperations>
      discountPercentageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'discountPercentage');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, String, QQueryOperations>
      itemIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'itemId');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, int?, QQueryOperations>
      missingQuantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'missingQuantity');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, String?, QQueryOperations>
      notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, String?, QQueryOperations>
      productCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productCode');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, String?, QQueryOperations>
      productDescriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productDescription');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, String, QQueryOperations>
      productIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productId');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, String, QQueryOperations>
      productNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productName');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, String?, QQueryOperations>
      purchaseOrderServerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'purchaseOrderServerId');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, int, QQueryOperations>
      quantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quantity');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, int?, QQueryOperations>
      receivedQuantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'receivedQuantity');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, double, QQueryOperations>
      subtotalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subtotal');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, double, QQueryOperations>
      taxAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'taxAmount');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, double, QQueryOperations>
      taxPercentageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'taxPercentage');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, double, QQueryOperations>
      totalAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalAmount');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, String, QQueryOperations> unitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unit');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, double, QQueryOperations>
      unitPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unitPrice');
    });
  }

  QueryBuilder<IsarPurchaseOrderItem, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
