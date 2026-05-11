// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_bank_account_movement.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarBankAccountMovementCollection on Isar {
  IsarCollection<IsarBankAccountMovement> get isarBankAccountMovements =>
      this.collection();
}

const IsarBankAccountMovementSchema = CollectionSchema(
  name: r'IsarBankAccountMovement',
  id: 1437438723749839590,
  properties: {
    r'amount': PropertySchema(
      id: 0,
      name: r'amount',
      type: IsarType.double,
    ),
    r'balanceAfter': PropertySchema(
      id: 1,
      name: r'balanceAfter',
      type: IsarType.double,
    ),
    r'bankAccountId': PropertySchema(
      id: 2,
      name: r'bankAccountId',
      type: IsarType.string,
    ),
    r'counterpartyAccountId': PropertySchema(
      id: 3,
      name: r'counterpartyAccountId',
      type: IsarType.string,
    ),
    r'counterpartyMovementId': PropertySchema(
      id: 4,
      name: r'counterpartyMovementId',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 5,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'createdById': PropertySchema(
      id: 6,
      name: r'createdById',
      type: IsarType.string,
    ),
    r'deletedAt': PropertySchema(
      id: 7,
      name: r'deletedAt',
      type: IsarType.dateTime,
    ),
    r'description': PropertySchema(
      id: 8,
      name: r'description',
      type: IsarType.string,
    ),
    r'isSynced': PropertySchema(
      id: 9,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'lastSyncAt': PropertySchema(
      id: 10,
      name: r'lastSyncAt',
      type: IsarType.dateTime,
    ),
    r'metadataJson': PropertySchema(
      id: 11,
      name: r'metadataJson',
      type: IsarType.string,
    ),
    r'movementDate': PropertySchema(
      id: 12,
      name: r'movementDate',
      type: IsarType.dateTime,
    ),
    r'organizationId': PropertySchema(
      id: 13,
      name: r'organizationId',
      type: IsarType.string,
    ),
    r'referenceId': PropertySchema(
      id: 14,
      name: r'referenceId',
      type: IsarType.string,
    ),
    r'referenceType': PropertySchema(
      id: 15,
      name: r'referenceType',
      type: IsarType.string,
    ),
    r'serverId': PropertySchema(
      id: 16,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 17,
      name: r'type',
      type: IsarType.string,
      enumMap: _IsarBankAccountMovementtypeEnumValueMap,
    ),
    r'updatedAt': PropertySchema(
      id: 18,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _isarBankAccountMovementEstimateSize,
  serialize: _isarBankAccountMovementSerialize,
  deserialize: _isarBankAccountMovementDeserialize,
  deserializeProp: _isarBankAccountMovementDeserializeProp,
  idName: r'id',
  indexes: {
    r'serverId': IndexSchema(
      id: -7950187970872907662,
      name: r'serverId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'serverId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'bankAccountId': IndexSchema(
      id: -7107590253631006507,
      name: r'bankAccountId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'bankAccountId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'movementDate': IndexSchema(
      id: -6300938769280071366,
      name: r'movementDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'movementDate',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'organizationId': IndexSchema(
      id: 6034903298354724267,
      name: r'organizationId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'organizationId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarBankAccountMovementGetId,
  getLinks: _isarBankAccountMovementGetLinks,
  attach: _isarBankAccountMovementAttach,
  version: '3.1.0+1',
);

int _isarBankAccountMovementEstimateSize(
  IsarBankAccountMovement object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.bankAccountId.length * 3;
  {
    final value = object.counterpartyAccountId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.counterpartyMovementId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.createdById;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.metadataJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.organizationId.length * 3;
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
  bytesCount += 3 + object.type.name.length * 3;
  return bytesCount;
}

void _isarBankAccountMovementSerialize(
  IsarBankAccountMovement object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.amount);
  writer.writeDouble(offsets[1], object.balanceAfter);
  writer.writeString(offsets[2], object.bankAccountId);
  writer.writeString(offsets[3], object.counterpartyAccountId);
  writer.writeString(offsets[4], object.counterpartyMovementId);
  writer.writeDateTime(offsets[5], object.createdAt);
  writer.writeString(offsets[6], object.createdById);
  writer.writeDateTime(offsets[7], object.deletedAt);
  writer.writeString(offsets[8], object.description);
  writer.writeBool(offsets[9], object.isSynced);
  writer.writeDateTime(offsets[10], object.lastSyncAt);
  writer.writeString(offsets[11], object.metadataJson);
  writer.writeDateTime(offsets[12], object.movementDate);
  writer.writeString(offsets[13], object.organizationId);
  writer.writeString(offsets[14], object.referenceId);
  writer.writeString(offsets[15], object.referenceType);
  writer.writeString(offsets[16], object.serverId);
  writer.writeString(offsets[17], object.type.name);
  writer.writeDateTime(offsets[18], object.updatedAt);
}

IsarBankAccountMovement _isarBankAccountMovementDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarBankAccountMovement();
  object.amount = reader.readDouble(offsets[0]);
  object.balanceAfter = reader.readDouble(offsets[1]);
  object.bankAccountId = reader.readString(offsets[2]);
  object.counterpartyAccountId = reader.readStringOrNull(offsets[3]);
  object.counterpartyMovementId = reader.readStringOrNull(offsets[4]);
  object.createdAt = reader.readDateTime(offsets[5]);
  object.createdById = reader.readStringOrNull(offsets[6]);
  object.deletedAt = reader.readDateTimeOrNull(offsets[7]);
  object.description = reader.readStringOrNull(offsets[8]);
  object.id = id;
  object.isSynced = reader.readBool(offsets[9]);
  object.lastSyncAt = reader.readDateTimeOrNull(offsets[10]);
  object.metadataJson = reader.readStringOrNull(offsets[11]);
  object.movementDate = reader.readDateTime(offsets[12]);
  object.organizationId = reader.readString(offsets[13]);
  object.referenceId = reader.readStringOrNull(offsets[14]);
  object.referenceType = reader.readStringOrNull(offsets[15]);
  object.serverId = reader.readString(offsets[16]);
  object.type = _IsarBankAccountMovementtypeValueEnumMap[
          reader.readStringOrNull(offsets[17])] ??
      IsarBankAccountMovementType.initialBalance;
  object.updatedAt = reader.readDateTime(offsets[18]);
  return object;
}

P _isarBankAccountMovementDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readDateTime(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (_IsarBankAccountMovementtypeValueEnumMap[
              reader.readStringOrNull(offset)] ??
          IsarBankAccountMovementType.initialBalance) as P;
    case 18:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _IsarBankAccountMovementtypeEnumValueMap = {
  r'initialBalance': r'initialBalance',
  r'deposit': r'deposit',
  r'withdrawal': r'withdrawal',
  r'invoicePayment': r'invoicePayment',
  r'creditPayment': r'creditPayment',
  r'expensePayment': r'expensePayment',
  r'transferOut': r'transferOut',
  r'transferIn': r'transferIn',
  r'adjustment': r'adjustment',
  r'refund': r'refund',
};
const _IsarBankAccountMovementtypeValueEnumMap = {
  r'initialBalance': IsarBankAccountMovementType.initialBalance,
  r'deposit': IsarBankAccountMovementType.deposit,
  r'withdrawal': IsarBankAccountMovementType.withdrawal,
  r'invoicePayment': IsarBankAccountMovementType.invoicePayment,
  r'creditPayment': IsarBankAccountMovementType.creditPayment,
  r'expensePayment': IsarBankAccountMovementType.expensePayment,
  r'transferOut': IsarBankAccountMovementType.transferOut,
  r'transferIn': IsarBankAccountMovementType.transferIn,
  r'adjustment': IsarBankAccountMovementType.adjustment,
  r'refund': IsarBankAccountMovementType.refund,
};

Id _isarBankAccountMovementGetId(IsarBankAccountMovement object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarBankAccountMovementGetLinks(
    IsarBankAccountMovement object) {
  return [];
}

void _isarBankAccountMovementAttach(
    IsarCollection<dynamic> col, Id id, IsarBankAccountMovement object) {
  object.id = id;
}

extension IsarBankAccountMovementByIndex
    on IsarCollection<IsarBankAccountMovement> {
  Future<IsarBankAccountMovement?> getByServerId(String serverId) {
    return getByIndex(r'serverId', [serverId]);
  }

  IsarBankAccountMovement? getByServerIdSync(String serverId) {
    return getByIndexSync(r'serverId', [serverId]);
  }

  Future<bool> deleteByServerId(String serverId) {
    return deleteByIndex(r'serverId', [serverId]);
  }

  bool deleteByServerIdSync(String serverId) {
    return deleteByIndexSync(r'serverId', [serverId]);
  }

  Future<List<IsarBankAccountMovement?>> getAllByServerId(
      List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'serverId', values);
  }

  List<IsarBankAccountMovement?> getAllByServerIdSync(
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

  Future<Id> putByServerId(IsarBankAccountMovement object) {
    return putByIndex(r'serverId', object);
  }

  Id putByServerIdSync(IsarBankAccountMovement object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'serverId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByServerId(List<IsarBankAccountMovement> objects) {
    return putAllByIndex(r'serverId', objects);
  }

  List<Id> putAllByServerIdSync(List<IsarBankAccountMovement> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'serverId', objects, saveLinks: saveLinks);
  }
}

extension IsarBankAccountMovementQueryWhereSort
    on QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QWhere> {
  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterWhere>
      anyMovementDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'movementDate'),
      );
    });
  }
}

extension IsarBankAccountMovementQueryWhere on QueryBuilder<
    IsarBankAccountMovement, IsarBankAccountMovement, QWhereClause> {
  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterWhereClause> serverIdEqualTo(String serverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'serverId',
        value: [serverId],
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterWhereClause> bankAccountIdEqualTo(String bankAccountId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'bankAccountId',
        value: [bankAccountId],
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterWhereClause> bankAccountIdNotEqualTo(String bankAccountId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'bankAccountId',
              lower: [],
              upper: [bankAccountId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'bankAccountId',
              lower: [bankAccountId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'bankAccountId',
              lower: [bankAccountId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'bankAccountId',
              lower: [],
              upper: [bankAccountId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterWhereClause> movementDateEqualTo(DateTime movementDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'movementDate',
        value: [movementDate],
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterWhereClause> movementDateNotEqualTo(DateTime movementDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'movementDate',
              lower: [],
              upper: [movementDate],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'movementDate',
              lower: [movementDate],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'movementDate',
              lower: [movementDate],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'movementDate',
              lower: [],
              upper: [movementDate],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterWhereClause> movementDateGreaterThan(
    DateTime movementDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'movementDate',
        lower: [movementDate],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterWhereClause> movementDateLessThan(
    DateTime movementDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'movementDate',
        lower: [],
        upper: [movementDate],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterWhereClause> movementDateBetween(
    DateTime lowerMovementDate,
    DateTime upperMovementDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'movementDate',
        lower: [lowerMovementDate],
        includeLower: includeLower,
        upper: [upperMovementDate],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterWhereClause> organizationIdEqualTo(String organizationId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'organizationId',
        value: [organizationId],
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterWhereClause> organizationIdNotEqualTo(String organizationId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'organizationId',
              lower: [],
              upper: [organizationId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'organizationId',
              lower: [organizationId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'organizationId',
              lower: [organizationId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'organizationId',
              lower: [],
              upper: [organizationId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarBankAccountMovementQueryFilter on QueryBuilder<
    IsarBankAccountMovement, IsarBankAccountMovement, QFilterCondition> {
  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> amountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> amountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> amountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> amountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> balanceAfterEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'balanceAfter',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> balanceAfterGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'balanceAfter',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> balanceAfterLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'balanceAfter',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> balanceAfterBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'balanceAfter',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> bankAccountIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bankAccountId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> bankAccountIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bankAccountId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> bankAccountIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bankAccountId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> bankAccountIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bankAccountId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> bankAccountIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'bankAccountId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> bankAccountIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'bankAccountId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
          QAfterFilterCondition>
      bankAccountIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'bankAccountId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
          QAfterFilterCondition>
      bankAccountIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'bankAccountId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> bankAccountIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bankAccountId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> bankAccountIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'bankAccountId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> counterpartyAccountIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'counterpartyAccountId',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> counterpartyAccountIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'counterpartyAccountId',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> counterpartyAccountIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'counterpartyAccountId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> counterpartyAccountIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'counterpartyAccountId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> counterpartyAccountIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'counterpartyAccountId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> counterpartyAccountIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'counterpartyAccountId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> counterpartyAccountIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'counterpartyAccountId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> counterpartyAccountIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'counterpartyAccountId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
          QAfterFilterCondition>
      counterpartyAccountIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'counterpartyAccountId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
          QAfterFilterCondition>
      counterpartyAccountIdMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'counterpartyAccountId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> counterpartyAccountIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'counterpartyAccountId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> counterpartyAccountIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'counterpartyAccountId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> counterpartyMovementIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'counterpartyMovementId',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> counterpartyMovementIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'counterpartyMovementId',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> counterpartyMovementIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'counterpartyMovementId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> counterpartyMovementIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'counterpartyMovementId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> counterpartyMovementIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'counterpartyMovementId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> counterpartyMovementIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'counterpartyMovementId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> counterpartyMovementIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'counterpartyMovementId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> counterpartyMovementIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'counterpartyMovementId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
          QAfterFilterCondition>
      counterpartyMovementIdContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'counterpartyMovementId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
          QAfterFilterCondition>
      counterpartyMovementIdMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'counterpartyMovementId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> counterpartyMovementIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'counterpartyMovementId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> counterpartyMovementIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'counterpartyMovementId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> createdByIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createdById',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> createdByIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createdById',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> createdByIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdById',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> createdByIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdById',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> createdByIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdById',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> createdByIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdById',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> createdByIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'createdById',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> createdByIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'createdById',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
          QAfterFilterCondition>
      createdByIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'createdById',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
          QAfterFilterCondition>
      createdByIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'createdById',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> createdByIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdById',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> createdByIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'createdById',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> deletedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> deletedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> descriptionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> descriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> descriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> descriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
          QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
          QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> lastSyncAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSyncAt',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> lastSyncAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSyncAt',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> lastSyncAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSyncAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> metadataJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'metadataJson',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> metadataJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'metadataJson',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> metadataJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'metadataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> metadataJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'metadataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> metadataJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'metadataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> metadataJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'metadataJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> metadataJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'metadataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> metadataJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'metadataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
          QAfterFilterCondition>
      metadataJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'metadataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
          QAfterFilterCondition>
      metadataJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'metadataJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> metadataJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'metadataJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> metadataJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'metadataJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> movementDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'movementDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> organizationIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'organizationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> organizationIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'organizationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> organizationIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'organizationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> organizationIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'organizationId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> organizationIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'organizationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> organizationIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'organizationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
          QAfterFilterCondition>
      organizationIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'organizationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
          QAfterFilterCondition>
      organizationIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'organizationId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> organizationIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'organizationId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> organizationIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'organizationId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> referenceIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'referenceId',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> referenceIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'referenceId',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> referenceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'referenceId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> referenceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'referenceId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> referenceTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'referenceType',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> referenceTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'referenceType',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> referenceTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'referenceType',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> referenceTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'referenceType',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> typeEqualTo(
    IsarBankAccountMovementType value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> typeGreaterThan(
    IsarBankAccountMovementType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> typeLessThan(
    IsarBankAccountMovementType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> typeBetween(
    IsarBankAccountMovementType lower,
    IsarBankAccountMovementType upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
          QAfterFilterCondition>
      typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
          QAfterFilterCondition>
      typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
      QAfterFilterCondition> updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement,
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

extension IsarBankAccountMovementQueryObject on QueryBuilder<
    IsarBankAccountMovement, IsarBankAccountMovement, QFilterCondition> {}

extension IsarBankAccountMovementQueryLinks on QueryBuilder<
    IsarBankAccountMovement, IsarBankAccountMovement, QFilterCondition> {}

extension IsarBankAccountMovementQuerySortBy
    on QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QSortBy> {
  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByBalanceAfter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceAfter', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByBalanceAfterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceAfter', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByBankAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bankAccountId', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByBankAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bankAccountId', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByCounterpartyAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'counterpartyAccountId', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByCounterpartyAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'counterpartyAccountId', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByCounterpartyMovementId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'counterpartyMovementId', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByCounterpartyMovementIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'counterpartyMovementId', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByCreatedById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdById', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByCreatedByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdById', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByLastSyncAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByMetadataJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataJson', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByMetadataJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataJson', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByMovementDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'movementDate', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByMovementDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'movementDate', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByOrganizationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationId', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByOrganizationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationId', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByReferenceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceId', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByReferenceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceId', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByReferenceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceType', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByReferenceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceType', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension IsarBankAccountMovementQuerySortThenBy on QueryBuilder<
    IsarBankAccountMovement, IsarBankAccountMovement, QSortThenBy> {
  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByBalanceAfter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceAfter', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByBalanceAfterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceAfter', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByBankAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bankAccountId', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByBankAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bankAccountId', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByCounterpartyAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'counterpartyAccountId', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByCounterpartyAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'counterpartyAccountId', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByCounterpartyMovementId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'counterpartyMovementId', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByCounterpartyMovementIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'counterpartyMovementId', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByCreatedById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdById', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByCreatedByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdById', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByLastSyncAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByMetadataJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataJson', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByMetadataJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataJson', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByMovementDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'movementDate', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByMovementDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'movementDate', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByOrganizationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationId', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByOrganizationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationId', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByReferenceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceId', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByReferenceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceId', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByReferenceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceType', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByReferenceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceType', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension IsarBankAccountMovementQueryWhereDistinct on QueryBuilder<
    IsarBankAccountMovement, IsarBankAccountMovement, QDistinct> {
  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QDistinct>
      distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QDistinct>
      distinctByBalanceAfter() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'balanceAfter');
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QDistinct>
      distinctByBankAccountId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bankAccountId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QDistinct>
      distinctByCounterpartyAccountId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'counterpartyAccountId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QDistinct>
      distinctByCounterpartyMovementId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'counterpartyMovementId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QDistinct>
      distinctByCreatedById({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdById', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QDistinct>
      distinctByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedAt');
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QDistinct>
      distinctByDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QDistinct>
      distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QDistinct>
      distinctByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncAt');
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QDistinct>
      distinctByMetadataJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'metadataJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QDistinct>
      distinctByMovementDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'movementDate');
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QDistinct>
      distinctByOrganizationId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'organizationId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QDistinct>
      distinctByReferenceId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'referenceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QDistinct>
      distinctByReferenceType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'referenceType',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QDistinct>
      distinctByServerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QDistinct>
      distinctByType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovement, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension IsarBankAccountMovementQueryProperty on QueryBuilder<
    IsarBankAccountMovement, IsarBankAccountMovement, QQueryProperty> {
  QueryBuilder<IsarBankAccountMovement, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarBankAccountMovement, double, QQueryOperations>
      amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<IsarBankAccountMovement, double, QQueryOperations>
      balanceAfterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'balanceAfter');
    });
  }

  QueryBuilder<IsarBankAccountMovement, String, QQueryOperations>
      bankAccountIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bankAccountId');
    });
  }

  QueryBuilder<IsarBankAccountMovement, String?, QQueryOperations>
      counterpartyAccountIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'counterpartyAccountId');
    });
  }

  QueryBuilder<IsarBankAccountMovement, String?, QQueryOperations>
      counterpartyMovementIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'counterpartyMovementId');
    });
  }

  QueryBuilder<IsarBankAccountMovement, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<IsarBankAccountMovement, String?, QQueryOperations>
      createdByIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdById');
    });
  }

  QueryBuilder<IsarBankAccountMovement, DateTime?, QQueryOperations>
      deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedAt');
    });
  }

  QueryBuilder<IsarBankAccountMovement, String?, QQueryOperations>
      descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<IsarBankAccountMovement, bool, QQueryOperations>
      isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<IsarBankAccountMovement, DateTime?, QQueryOperations>
      lastSyncAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncAt');
    });
  }

  QueryBuilder<IsarBankAccountMovement, String?, QQueryOperations>
      metadataJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'metadataJson');
    });
  }

  QueryBuilder<IsarBankAccountMovement, DateTime, QQueryOperations>
      movementDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'movementDate');
    });
  }

  QueryBuilder<IsarBankAccountMovement, String, QQueryOperations>
      organizationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'organizationId');
    });
  }

  QueryBuilder<IsarBankAccountMovement, String?, QQueryOperations>
      referenceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'referenceId');
    });
  }

  QueryBuilder<IsarBankAccountMovement, String?, QQueryOperations>
      referenceTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'referenceType');
    });
  }

  QueryBuilder<IsarBankAccountMovement, String, QQueryOperations>
      serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<IsarBankAccountMovement, IsarBankAccountMovementType,
      QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<IsarBankAccountMovement, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
