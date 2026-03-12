// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_inventory_batch_movement.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarInventoryBatchMovementCollection on Isar {
  IsarCollection<IsarInventoryBatchMovement> get isarInventoryBatchMovements =>
      this.collection();
}

const IsarInventoryBatchMovementSchema = CollectionSchema(
  name: r'IsarInventoryBatchMovement',
  id: 4259471417092819490,
  properties: {
    r'batchId': PropertySchema(
      id: 0,
      name: r'batchId',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'deletedAt': PropertySchema(
      id: 2,
      name: r'deletedAt',
      type: IsarType.dateTime,
    ),
    r'displayQuantity': PropertySchema(
      id: 3,
      name: r'displayQuantity',
      type: IsarType.string,
    ),
    r'hasReference': PropertySchema(
      id: 4,
      name: r'hasReference',
      type: IsarType.bool,
    ),
    r'isAdjustment': PropertySchema(
      id: 5,
      name: r'isAdjustment',
      type: IsarType.bool,
    ),
    r'isDeleted': PropertySchema(
      id: 6,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'isGain': PropertySchema(
      id: 7,
      name: r'isGain',
      type: IsarType.bool,
    ),
    r'isInbound': PropertySchema(
      id: 8,
      name: r'isInbound',
      type: IsarType.bool,
    ),
    r'isLoss': PropertySchema(
      id: 9,
      name: r'isLoss',
      type: IsarType.bool,
    ),
    r'isOutbound': PropertySchema(
      id: 10,
      name: r'isOutbound',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 11,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'lastModifiedAt': PropertySchema(
      id: 12,
      name: r'lastModifiedAt',
      type: IsarType.dateTime,
    ),
    r'lastModifiedBy': PropertySchema(
      id: 13,
      name: r'lastModifiedBy',
      type: IsarType.string,
    ),
    r'lastSyncAt': PropertySchema(
      id: 14,
      name: r'lastSyncAt',
      type: IsarType.dateTime,
    ),
    r'movementDate': PropertySchema(
      id: 15,
      name: r'movementDate',
      type: IsarType.dateTime,
    ),
    r'movementId': PropertySchema(
      id: 16,
      name: r'movementId',
      type: IsarType.string,
    ),
    r'movementType': PropertySchema(
      id: 17,
      name: r'movementType',
      type: IsarType.string,
    ),
    r'movementTypeDescription': PropertySchema(
      id: 18,
      name: r'movementTypeDescription',
      type: IsarType.string,
    ),
    r'needsSync': PropertySchema(
      id: 19,
      name: r'needsSync',
      type: IsarType.bool,
    ),
    r'notes': PropertySchema(
      id: 20,
      name: r'notes',
      type: IsarType.string,
    ),
    r'quantity': PropertySchema(
      id: 21,
      name: r'quantity',
      type: IsarType.long,
    ),
    r'referenceId': PropertySchema(
      id: 22,
      name: r'referenceId',
      type: IsarType.string,
    ),
    r'referenceType': PropertySchema(
      id: 23,
      name: r'referenceType',
      type: IsarType.string,
    ),
    r'serverId': PropertySchema(
      id: 24,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'stockImpact': PropertySchema(
      id: 25,
      name: r'stockImpact',
      type: IsarType.long,
    ),
    r'totalCost': PropertySchema(
      id: 26,
      name: r'totalCost',
      type: IsarType.double,
    ),
    r'unitCost': PropertySchema(
      id: 27,
      name: r'unitCost',
      type: IsarType.double,
    ),
    r'updatedAt': PropertySchema(
      id: 28,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'valueImpact': PropertySchema(
      id: 29,
      name: r'valueImpact',
      type: IsarType.double,
    ),
    r'version': PropertySchema(
      id: 30,
      name: r'version',
      type: IsarType.long,
    )
  },
  estimateSize: _isarInventoryBatchMovementEstimateSize,
  serialize: _isarInventoryBatchMovementSerialize,
  deserialize: _isarInventoryBatchMovementDeserialize,
  deserializeProp: _isarInventoryBatchMovementDeserializeProp,
  idName: r'id',
  indexes: {
    r'serverId': IndexSchema(
      id: -7950187970872907662,
      name: r'serverId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'serverId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'batchId': IndexSchema(
      id: -5468368523860846432,
      name: r'batchId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'batchId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'movementId': IndexSchema(
      id: 1547802813824549110,
      name: r'movementId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'movementId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarInventoryBatchMovementGetId,
  getLinks: _isarInventoryBatchMovementGetLinks,
  attach: _isarInventoryBatchMovementAttach,
  version: '3.1.0+1',
);

int _isarInventoryBatchMovementEstimateSize(
  IsarInventoryBatchMovement object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.batchId.length * 3;
  bytesCount += 3 + object.displayQuantity.length * 3;
  {
    final value = object.lastModifiedBy;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.movementId.length * 3;
  bytesCount += 3 + object.movementType.length * 3;
  bytesCount += 3 + object.movementTypeDescription.length * 3;
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.referenceId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.referenceType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.serverId.length * 3;
  return bytesCount;
}

void _isarInventoryBatchMovementSerialize(
  IsarInventoryBatchMovement object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.batchId);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeDateTime(offsets[2], object.deletedAt);
  writer.writeString(offsets[3], object.displayQuantity);
  writer.writeBool(offsets[4], object.hasReference);
  writer.writeBool(offsets[5], object.isAdjustment);
  writer.writeBool(offsets[6], object.isDeleted);
  writer.writeBool(offsets[7], object.isGain);
  writer.writeBool(offsets[8], object.isInbound);
  writer.writeBool(offsets[9], object.isLoss);
  writer.writeBool(offsets[10], object.isOutbound);
  writer.writeBool(offsets[11], object.isSynced);
  writer.writeDateTime(offsets[12], object.lastModifiedAt);
  writer.writeString(offsets[13], object.lastModifiedBy);
  writer.writeDateTime(offsets[14], object.lastSyncAt);
  writer.writeDateTime(offsets[15], object.movementDate);
  writer.writeString(offsets[16], object.movementId);
  writer.writeString(offsets[17], object.movementType);
  writer.writeString(offsets[18], object.movementTypeDescription);
  writer.writeBool(offsets[19], object.needsSync);
  writer.writeString(offsets[20], object.notes);
  writer.writeLong(offsets[21], object.quantity);
  writer.writeString(offsets[22], object.referenceId);
  writer.writeString(offsets[23], object.referenceType);
  writer.writeString(offsets[24], object.serverId);
  writer.writeLong(offsets[25], object.stockImpact);
  writer.writeDouble(offsets[26], object.totalCost);
  writer.writeDouble(offsets[27], object.unitCost);
  writer.writeDateTime(offsets[28], object.updatedAt);
  writer.writeDouble(offsets[29], object.valueImpact);
  writer.writeLong(offsets[30], object.version);
}

IsarInventoryBatchMovement _isarInventoryBatchMovementDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarInventoryBatchMovement();
  object.batchId = reader.readString(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.deletedAt = reader.readDateTimeOrNull(offsets[2]);
  object.id = id;
  object.isSynced = reader.readBool(offsets[11]);
  object.lastModifiedAt = reader.readDateTimeOrNull(offsets[12]);
  object.lastModifiedBy = reader.readStringOrNull(offsets[13]);
  object.lastSyncAt = reader.readDateTimeOrNull(offsets[14]);
  object.movementDate = reader.readDateTime(offsets[15]);
  object.movementId = reader.readString(offsets[16]);
  object.movementType = reader.readString(offsets[17]);
  object.notes = reader.readStringOrNull(offsets[20]);
  object.quantity = reader.readLong(offsets[21]);
  object.referenceId = reader.readStringOrNull(offsets[22]);
  object.referenceType = reader.readStringOrNull(offsets[23]);
  object.serverId = reader.readString(offsets[24]);
  object.totalCost = reader.readDouble(offsets[26]);
  object.unitCost = reader.readDouble(offsets[27]);
  object.updatedAt = reader.readDateTime(offsets[28]);
  object.version = reader.readLong(offsets[30]);
  return object;
}

P _isarInventoryBatchMovementDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readBool(offset)) as P;
    case 12:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 15:
      return (reader.readDateTime(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readString(offset)) as P;
    case 18:
      return (reader.readString(offset)) as P;
    case 19:
      return (reader.readBool(offset)) as P;
    case 20:
      return (reader.readStringOrNull(offset)) as P;
    case 21:
      return (reader.readLong(offset)) as P;
    case 22:
      return (reader.readStringOrNull(offset)) as P;
    case 23:
      return (reader.readStringOrNull(offset)) as P;
    case 24:
      return (reader.readString(offset)) as P;
    case 25:
      return (reader.readLong(offset)) as P;
    case 26:
      return (reader.readDouble(offset)) as P;
    case 27:
      return (reader.readDouble(offset)) as P;
    case 28:
      return (reader.readDateTime(offset)) as P;
    case 29:
      return (reader.readDouble(offset)) as P;
    case 30:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarInventoryBatchMovementGetId(IsarInventoryBatchMovement object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarInventoryBatchMovementGetLinks(
    IsarInventoryBatchMovement object) {
  return [];
}

void _isarInventoryBatchMovementAttach(
    IsarCollection<dynamic> col, Id id, IsarInventoryBatchMovement object) {
  object.id = id;
}

extension IsarInventoryBatchMovementByIndex
    on IsarCollection<IsarInventoryBatchMovement> {
  Future<IsarInventoryBatchMovement?> getByServerId(String serverId) {
    return getByIndex(r'serverId', [serverId]);
  }

  IsarInventoryBatchMovement? getByServerIdSync(String serverId) {
    return getByIndexSync(r'serverId', [serverId]);
  }

  Future<bool> deleteByServerId(String serverId) {
    return deleteByIndex(r'serverId', [serverId]);
  }

  bool deleteByServerIdSync(String serverId) {
    return deleteByIndexSync(r'serverId', [serverId]);
  }

  Future<List<IsarInventoryBatchMovement?>> getAllByServerId(
      List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'serverId', values);
  }

  List<IsarInventoryBatchMovement?> getAllByServerIdSync(
      List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'serverId', values);
  }

  Future<int> deleteAllByServerId(List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'serverId', values);
  }

  int deleteAllByServerIdSync(List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'serverId', values);
  }

  Future<Id> putByServerId(IsarInventoryBatchMovement object) {
    return putByIndex(r'serverId', object);
  }

  Id putByServerIdSync(IsarInventoryBatchMovement object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'serverId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByServerId(List<IsarInventoryBatchMovement> objects) {
    return putAllByIndex(r'serverId', objects);
  }

  List<Id> putAllByServerIdSync(List<IsarInventoryBatchMovement> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'serverId', objects, saveLinks: saveLinks);
  }
}

extension IsarInventoryBatchMovementQueryWhereSort on QueryBuilder<
    IsarInventoryBatchMovement, IsarInventoryBatchMovement, QWhere> {
  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarInventoryBatchMovementQueryWhere on QueryBuilder<
    IsarInventoryBatchMovement, IsarInventoryBatchMovement, QWhereClause> {
  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterWhereClause> serverIdEqualTo(String serverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'serverId',
        value: [serverId],
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterWhereClause> serverIdNotEqualTo(String serverId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [],
              upper: [serverId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [serverId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [serverId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [],
              upper: [serverId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterWhereClause> batchIdEqualTo(String batchId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'batchId',
        value: [batchId],
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterWhereClause> batchIdNotEqualTo(String batchId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'batchId',
              lower: [],
              upper: [batchId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'batchId',
              lower: [batchId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'batchId',
              lower: [batchId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'batchId',
              lower: [],
              upper: [batchId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterWhereClause> movementIdEqualTo(String movementId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'movementId',
        value: [movementId],
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterWhereClause> movementIdNotEqualTo(String movementId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'movementId',
              lower: [],
              upper: [movementId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'movementId',
              lower: [movementId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'movementId',
              lower: [movementId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'movementId',
              lower: [],
              upper: [movementId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarInventoryBatchMovementQueryFilter on QueryBuilder<
    IsarInventoryBatchMovement, IsarInventoryBatchMovement, QFilterCondition> {
  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> batchIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'batchId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> batchIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'batchId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> batchIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'batchId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> batchIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'batchId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> batchIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'batchId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> batchIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'batchId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
          QAfterFilterCondition>
      batchIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'batchId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
          QAfterFilterCondition>
      batchIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'batchId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> batchIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'batchId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> batchIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'batchId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
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

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
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

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
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

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> deletedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> deletedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> deletedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> deletedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> deletedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deletedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> displayQuantityEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'displayQuantity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> displayQuantityGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'displayQuantity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> displayQuantityLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'displayQuantity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> displayQuantityBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'displayQuantity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> displayQuantityStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'displayQuantity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> displayQuantityEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'displayQuantity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
          QAfterFilterCondition>
      displayQuantityContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'displayQuantity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
          QAfterFilterCondition>
      displayQuantityMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'displayQuantity',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> displayQuantityIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'displayQuantity',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> displayQuantityIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'displayQuantity',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> hasReferenceEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hasReference',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
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

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
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

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
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

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> isAdjustmentEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isAdjustment',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> isDeletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> isGainEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isGain',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> isInboundEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isInbound',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> isLossEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isLoss',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> isOutboundEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isOutbound',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> lastModifiedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastModifiedAt',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> lastModifiedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastModifiedAt',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> lastModifiedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastModifiedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> lastModifiedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastModifiedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> lastModifiedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastModifiedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> lastModifiedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastModifiedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> lastModifiedByIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastModifiedBy',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> lastModifiedByIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastModifiedBy',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> lastModifiedByEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastModifiedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> lastModifiedByGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastModifiedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> lastModifiedByLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastModifiedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> lastModifiedByBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastModifiedBy',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> lastModifiedByStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastModifiedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> lastModifiedByEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastModifiedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
          QAfterFilterCondition>
      lastModifiedByContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastModifiedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
          QAfterFilterCondition>
      lastModifiedByMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastModifiedBy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> lastModifiedByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastModifiedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> lastModifiedByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastModifiedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> lastSyncAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSyncAt',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> lastSyncAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSyncAt',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> lastSyncAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSyncAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> lastSyncAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSyncAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> lastSyncAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSyncAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> lastSyncAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSyncAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> movementDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'movementDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> movementDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'movementDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> movementDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'movementDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> movementDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'movementDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> movementIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'movementId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> movementIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'movementId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> movementIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'movementId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> movementIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'movementId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> movementIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'movementId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> movementIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'movementId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
          QAfterFilterCondition>
      movementIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'movementId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
          QAfterFilterCondition>
      movementIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'movementId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> movementIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'movementId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> movementIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'movementId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> movementTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'movementType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> movementTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'movementType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> movementTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'movementType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> movementTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'movementType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> movementTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'movementType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> movementTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'movementType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
          QAfterFilterCondition>
      movementTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'movementType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
          QAfterFilterCondition>
      movementTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'movementType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> movementTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'movementType',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> movementTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'movementType',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> movementTypeDescriptionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'movementTypeDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> movementTypeDescriptionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'movementTypeDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> movementTypeDescriptionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'movementTypeDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> movementTypeDescriptionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'movementTypeDescription',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> movementTypeDescriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'movementTypeDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> movementTypeDescriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'movementTypeDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
          QAfterFilterCondition>
      movementTypeDescriptionContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'movementTypeDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
          QAfterFilterCondition>
      movementTypeDescriptionMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'movementTypeDescription',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> movementTypeDescriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'movementTypeDescription',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> movementTypeDescriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'movementTypeDescription',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> needsSyncEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'needsSync',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
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

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
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

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
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

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
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

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
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

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
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

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
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

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
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

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> quantityEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'quantity',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
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

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
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

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
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

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> referenceIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'referenceId',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> referenceIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'referenceId',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> referenceIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'referenceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> referenceIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'referenceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> referenceIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'referenceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> referenceIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'referenceId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> referenceIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'referenceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> referenceIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'referenceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
          QAfterFilterCondition>
      referenceIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'referenceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
          QAfterFilterCondition>
      referenceIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'referenceId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> referenceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'referenceId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> referenceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'referenceId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> referenceTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'referenceType',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> referenceTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'referenceType',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> referenceTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'referenceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> referenceTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'referenceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> referenceTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'referenceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> referenceTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'referenceType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> referenceTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'referenceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> referenceTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'referenceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
          QAfterFilterCondition>
      referenceTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'referenceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
          QAfterFilterCondition>
      referenceTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'referenceType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> referenceTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'referenceType',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> referenceTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'referenceType',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> serverIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> serverIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> serverIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> serverIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'serverId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> serverIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> serverIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
          QAfterFilterCondition>
      serverIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
          QAfterFilterCondition>
      serverIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'serverId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> stockImpactEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stockImpact',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> stockImpactGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stockImpact',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> stockImpactLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stockImpact',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> stockImpactBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stockImpact',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> totalCostEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> totalCostGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> totalCostLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> totalCostBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalCost',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> unitCostEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unitCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> unitCostGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'unitCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> unitCostLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'unitCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> unitCostBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'unitCost',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
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

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
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

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
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

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> valueImpactEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'valueImpact',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> valueImpactGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'valueImpact',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> valueImpactLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'valueImpact',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> valueImpactBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'valueImpact',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> versionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> versionGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> versionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterFilterCondition> versionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'version',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IsarInventoryBatchMovementQueryObject on QueryBuilder<
    IsarInventoryBatchMovement, IsarInventoryBatchMovement, QFilterCondition> {}

extension IsarInventoryBatchMovementQueryLinks on QueryBuilder<
    IsarInventoryBatchMovement, IsarInventoryBatchMovement, QFilterCondition> {}

extension IsarInventoryBatchMovementQuerySortBy on QueryBuilder<
    IsarInventoryBatchMovement, IsarInventoryBatchMovement, QSortBy> {
  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByBatchId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchId', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByBatchIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchId', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByDisplayQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayQuantity', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByDisplayQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayQuantity', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByHasReference() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasReference', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByHasReferenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasReference', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByIsAdjustment() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAdjustment', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByIsAdjustmentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAdjustment', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByIsGain() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isGain', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByIsGainDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isGain', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByIsInbound() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isInbound', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByIsInboundDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isInbound', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByIsLoss() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLoss', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByIsLossDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLoss', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByIsOutbound() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOutbound', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByIsOutboundDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOutbound', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByLastModifiedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByLastModifiedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByLastModifiedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedBy', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByLastModifiedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedBy', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByLastSyncAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByMovementDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'movementDate', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByMovementDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'movementDate', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByMovementId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'movementId', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByMovementIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'movementId', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByMovementType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'movementType', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByMovementTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'movementType', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByMovementTypeDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'movementTypeDescription', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByMovementTypeDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'movementTypeDescription', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByNeedsSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByReferenceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceId', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByReferenceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceId', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByReferenceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceType', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByReferenceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceType', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByStockImpact() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockImpact', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByStockImpactDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockImpact', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByTotalCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCost', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByTotalCostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCost', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByUnitCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitCost', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByUnitCostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitCost', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByValueImpact() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueImpact', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByValueImpactDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueImpact', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> sortByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension IsarInventoryBatchMovementQuerySortThenBy on QueryBuilder<
    IsarInventoryBatchMovement, IsarInventoryBatchMovement, QSortThenBy> {
  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByBatchId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchId', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByBatchIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchId', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByDisplayQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayQuantity', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByDisplayQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayQuantity', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByHasReference() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasReference', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByHasReferenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasReference', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByIsAdjustment() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAdjustment', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByIsAdjustmentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAdjustment', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByIsGain() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isGain', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByIsGainDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isGain', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByIsInbound() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isInbound', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByIsInboundDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isInbound', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByIsLoss() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLoss', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByIsLossDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLoss', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByIsOutbound() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOutbound', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByIsOutboundDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOutbound', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByLastModifiedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByLastModifiedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByLastModifiedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedBy', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByLastModifiedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedBy', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByLastSyncAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByMovementDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'movementDate', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByMovementDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'movementDate', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByMovementId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'movementId', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByMovementIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'movementId', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByMovementType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'movementType', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByMovementTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'movementType', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByMovementTypeDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'movementTypeDescription', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByMovementTypeDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'movementTypeDescription', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByNeedsSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByReferenceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceId', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByReferenceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceId', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByReferenceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceType', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByReferenceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceType', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByStockImpact() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockImpact', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByStockImpactDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockImpact', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByTotalCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCost', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByTotalCostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCost', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByUnitCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitCost', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByUnitCostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitCost', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByValueImpact() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueImpact', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByValueImpactDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueImpact', Sort.desc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QAfterSortBy> thenByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension IsarInventoryBatchMovementQueryWhereDistinct on QueryBuilder<
    IsarInventoryBatchMovement, IsarInventoryBatchMovement, QDistinct> {
  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByBatchId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'batchId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedAt');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByDisplayQuantity({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'displayQuantity',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByHasReference() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasReference');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByIsAdjustment() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isAdjustment');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByIsGain() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isGain');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByIsInbound() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isInbound');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByIsLoss() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isLoss');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByIsOutbound() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isOutbound');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByLastModifiedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastModifiedAt');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByLastModifiedBy({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastModifiedBy',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncAt');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByMovementDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'movementDate');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByMovementId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'movementId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByMovementType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'movementType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
          QDistinct>
      distinctByMovementTypeDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'movementTypeDescription',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'needsSync');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByNotes({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'quantity');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByReferenceId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'referenceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByReferenceType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'referenceType',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByServerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByStockImpact() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stockImpact');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByTotalCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalCost');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByUnitCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unitCost');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByValueImpact() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'valueImpact');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, IsarInventoryBatchMovement,
      QDistinct> distinctByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'version');
    });
  }
}

extension IsarInventoryBatchMovementQueryProperty on QueryBuilder<
    IsarInventoryBatchMovement, IsarInventoryBatchMovement, QQueryProperty> {
  QueryBuilder<IsarInventoryBatchMovement, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, String, QQueryOperations>
      batchIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'batchId');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, DateTime?, QQueryOperations>
      deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedAt');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, String, QQueryOperations>
      displayQuantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'displayQuantity');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, bool, QQueryOperations>
      hasReferenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasReference');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, bool, QQueryOperations>
      isAdjustmentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isAdjustment');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, bool, QQueryOperations>
      isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, bool, QQueryOperations>
      isGainProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isGain');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, bool, QQueryOperations>
      isInboundProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isInbound');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, bool, QQueryOperations>
      isLossProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isLoss');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, bool, QQueryOperations>
      isOutboundProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isOutbound');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, bool, QQueryOperations>
      isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, DateTime?, QQueryOperations>
      lastModifiedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastModifiedAt');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, String?, QQueryOperations>
      lastModifiedByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastModifiedBy');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, DateTime?, QQueryOperations>
      lastSyncAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncAt');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, DateTime, QQueryOperations>
      movementDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'movementDate');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, String, QQueryOperations>
      movementIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'movementId');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, String, QQueryOperations>
      movementTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'movementType');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, String, QQueryOperations>
      movementTypeDescriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'movementTypeDescription');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, bool, QQueryOperations>
      needsSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'needsSync');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, String?, QQueryOperations>
      notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, int, QQueryOperations>
      quantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quantity');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, String?, QQueryOperations>
      referenceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'referenceId');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, String?, QQueryOperations>
      referenceTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'referenceType');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, String, QQueryOperations>
      serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, int, QQueryOperations>
      stockImpactProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stockImpact');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, double, QQueryOperations>
      totalCostProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalCost');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, double, QQueryOperations>
      unitCostProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unitCost');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, double, QQueryOperations>
      valueImpactProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'valueImpact');
    });
  }

  QueryBuilder<IsarInventoryBatchMovement, int, QQueryOperations>
      versionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'version');
    });
  }
}
