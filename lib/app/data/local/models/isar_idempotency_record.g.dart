// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_idempotency_record.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarIdempotencyRecordCollection on Isar {
  IsarCollection<IsarIdempotencyRecord> get isarIdempotencyRecords =>
      this.collection();
}

const IsarIdempotencyRecordSchema = CollectionSchema(
  name: r'IsarIdempotencyRecord',
  id: -3181065228050904149,
  properties: {
    r'canRetry': PropertySchema(
      id: 0,
      name: r'canRetry',
      type: IsarType.bool,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'entityId': PropertySchema(
      id: 2,
      name: r'entityId',
      type: IsarType.string,
    ),
    r'entityType': PropertySchema(
      id: 3,
      name: r'entityType',
      type: IsarType.string,
    ),
    r'errorMessage': PropertySchema(
      id: 4,
      name: r'errorMessage',
      type: IsarType.string,
    ),
    r'expiresAt': PropertySchema(
      id: 5,
      name: r'expiresAt',
      type: IsarType.dateTime,
    ),
    r'hashCode': PropertySchema(
      id: 6,
      name: r'hashCode',
      type: IsarType.long,
    ),
    r'idempotencyKey': PropertySchema(
      id: 7,
      name: r'idempotencyKey',
      type: IsarType.string,
    ),
    r'isCompleted': PropertySchema(
      id: 8,
      name: r'isCompleted',
      type: IsarType.bool,
    ),
    r'isExpired': PropertySchema(
      id: 9,
      name: r'isExpired',
      type: IsarType.bool,
    ),
    r'isFailed': PropertySchema(
      id: 10,
      name: r'isFailed',
      type: IsarType.bool,
    ),
    r'isPending': PropertySchema(
      id: 11,
      name: r'isPending',
      type: IsarType.bool,
    ),
    r'isProcessing': PropertySchema(
      id: 12,
      name: r'isProcessing',
      type: IsarType.bool,
    ),
    r'lastRetryAt': PropertySchema(
      id: 13,
      name: r'lastRetryAt',
      type: IsarType.dateTime,
    ),
    r'operationType': PropertySchema(
      id: 14,
      name: r'operationType',
      type: IsarType.string,
    ),
    r'processedAt': PropertySchema(
      id: 15,
      name: r'processedAt',
      type: IsarType.dateTime,
    ),
    r'responseData': PropertySchema(
      id: 16,
      name: r'responseData',
      type: IsarType.string,
    ),
    r'retryCount': PropertySchema(
      id: 17,
      name: r'retryCount',
      type: IsarType.long,
    ),
    r'status': PropertySchema(
      id: 18,
      name: r'status',
      type: IsarType.string,
      enumMap: _IsarIdempotencyRecordstatusEnumValueMap,
    ),
    r'updatedAt': PropertySchema(
      id: 19,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _isarIdempotencyRecordEstimateSize,
  serialize: _isarIdempotencyRecordSerialize,
  deserialize: _isarIdempotencyRecordDeserialize,
  deserializeProp: _isarIdempotencyRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'idempotencyKey': IndexSchema(
      id: 6522471565226449816,
      name: r'idempotencyKey',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'idempotencyKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'operationType': IndexSchema(
      id: 7940488376024458150,
      name: r'operationType',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'operationType',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'entityType': IndexSchema(
      id: -5109706325448941117,
      name: r'entityType',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'entityType',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'entityId': IndexSchema(
      id: 745355021660786263,
      name: r'entityId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'entityId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'status': IndexSchema(
      id: -107785170620420283,
      name: r'status',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'status',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarIdempotencyRecordGetId,
  getLinks: _isarIdempotencyRecordGetLinks,
  attach: _isarIdempotencyRecordAttach,
  version: '3.1.0+1',
);

int _isarIdempotencyRecordEstimateSize(
  IsarIdempotencyRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.entityId.length * 3;
  bytesCount += 3 + object.entityType.length * 3;
  {
    final value = object.errorMessage;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.idempotencyKey.length * 3;
  bytesCount += 3 + object.operationType.length * 3;
  {
    final value = object.responseData;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.status.name.length * 3;
  return bytesCount;
}

void _isarIdempotencyRecordSerialize(
  IsarIdempotencyRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.canRetry);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.entityId);
  writer.writeString(offsets[3], object.entityType);
  writer.writeString(offsets[4], object.errorMessage);
  writer.writeDateTime(offsets[5], object.expiresAt);
  writer.writeLong(offsets[6], object.hashCode);
  writer.writeString(offsets[7], object.idempotencyKey);
  writer.writeBool(offsets[8], object.isCompleted);
  writer.writeBool(offsets[9], object.isExpired);
  writer.writeBool(offsets[10], object.isFailed);
  writer.writeBool(offsets[11], object.isPending);
  writer.writeBool(offsets[12], object.isProcessing);
  writer.writeDateTime(offsets[13], object.lastRetryAt);
  writer.writeString(offsets[14], object.operationType);
  writer.writeDateTime(offsets[15], object.processedAt);
  writer.writeString(offsets[16], object.responseData);
  writer.writeLong(offsets[17], object.retryCount);
  writer.writeString(offsets[18], object.status.name);
  writer.writeDateTime(offsets[19], object.updatedAt);
}

IsarIdempotencyRecord _isarIdempotencyRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarIdempotencyRecord();
  object.createdAt = reader.readDateTime(offsets[1]);
  object.entityId = reader.readString(offsets[2]);
  object.entityType = reader.readString(offsets[3]);
  object.errorMessage = reader.readStringOrNull(offsets[4]);
  object.expiresAt = reader.readDateTimeOrNull(offsets[5]);
  object.id = id;
  object.idempotencyKey = reader.readString(offsets[7]);
  object.lastRetryAt = reader.readDateTimeOrNull(offsets[13]);
  object.operationType = reader.readString(offsets[14]);
  object.processedAt = reader.readDateTimeOrNull(offsets[15]);
  object.responseData = reader.readStringOrNull(offsets[16]);
  object.retryCount = reader.readLong(offsets[17]);
  object.status = _IsarIdempotencyRecordstatusValueEnumMap[
          reader.readStringOrNull(offsets[18])] ??
      IdempotencyStatus.pending;
  object.updatedAt = reader.readDateTime(offsets[19]);
  return object;
}

P _isarIdempotencyRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readBool(offset)) as P;
    case 12:
      return (reader.readBool(offset)) as P;
    case 13:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (reader.readLong(offset)) as P;
    case 18:
      return (_IsarIdempotencyRecordstatusValueEnumMap[
              reader.readStringOrNull(offset)] ??
          IdempotencyStatus.pending) as P;
    case 19:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _IsarIdempotencyRecordstatusEnumValueMap = {
  r'pending': r'pending',
  r'processing': r'processing',
  r'completed': r'completed',
  r'failed': r'failed',
};
const _IsarIdempotencyRecordstatusValueEnumMap = {
  r'pending': IdempotencyStatus.pending,
  r'processing': IdempotencyStatus.processing,
  r'completed': IdempotencyStatus.completed,
  r'failed': IdempotencyStatus.failed,
};

Id _isarIdempotencyRecordGetId(IsarIdempotencyRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarIdempotencyRecordGetLinks(
    IsarIdempotencyRecord object) {
  return [];
}

void _isarIdempotencyRecordAttach(
    IsarCollection<dynamic> col, Id id, IsarIdempotencyRecord object) {
  object.id = id;
}

extension IsarIdempotencyRecordByIndex
    on IsarCollection<IsarIdempotencyRecord> {
  Future<IsarIdempotencyRecord?> getByIdempotencyKey(String idempotencyKey) {
    return getByIndex(r'idempotencyKey', [idempotencyKey]);
  }

  IsarIdempotencyRecord? getByIdempotencyKeySync(String idempotencyKey) {
    return getByIndexSync(r'idempotencyKey', [idempotencyKey]);
  }

  Future<bool> deleteByIdempotencyKey(String idempotencyKey) {
    return deleteByIndex(r'idempotencyKey', [idempotencyKey]);
  }

  bool deleteByIdempotencyKeySync(String idempotencyKey) {
    return deleteByIndexSync(r'idempotencyKey', [idempotencyKey]);
  }

  Future<List<IsarIdempotencyRecord?>> getAllByIdempotencyKey(
      List<String> idempotencyKeyValues) {
    final values = idempotencyKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'idempotencyKey', values);
  }

  List<IsarIdempotencyRecord?> getAllByIdempotencyKeySync(
      List<String> idempotencyKeyValues) {
    final values = idempotencyKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'idempotencyKey', values);
  }

  Future<int> deleteAllByIdempotencyKey(List<String> idempotencyKeyValues) {
    final values = idempotencyKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'idempotencyKey', values);
  }

  int deleteAllByIdempotencyKeySync(List<String> idempotencyKeyValues) {
    final values = idempotencyKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'idempotencyKey', values);
  }

  Future<Id> putByIdempotencyKey(IsarIdempotencyRecord object) {
    return putByIndex(r'idempotencyKey', object);
  }

  Id putByIdempotencyKeySync(IsarIdempotencyRecord object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'idempotencyKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByIdempotencyKey(List<IsarIdempotencyRecord> objects) {
    return putAllByIndex(r'idempotencyKey', objects);
  }

  List<Id> putAllByIdempotencyKeySync(List<IsarIdempotencyRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'idempotencyKey', objects, saveLinks: saveLinks);
  }
}

extension IsarIdempotencyRecordQueryWhereSort
    on QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QWhere> {
  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarIdempotencyRecordQueryWhere on QueryBuilder<IsarIdempotencyRecord,
    IsarIdempotencyRecord, QWhereClause> {
  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterWhereClause>
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

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterWhereClause>
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

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterWhereClause>
      idempotencyKeyEqualTo(String idempotencyKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'idempotencyKey',
        value: [idempotencyKey],
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterWhereClause>
      idempotencyKeyNotEqualTo(String idempotencyKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'idempotencyKey',
              lower: [],
              upper: [idempotencyKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'idempotencyKey',
              lower: [idempotencyKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'idempotencyKey',
              lower: [idempotencyKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'idempotencyKey',
              lower: [],
              upper: [idempotencyKey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterWhereClause>
      operationTypeEqualTo(String operationType) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'operationType',
        value: [operationType],
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterWhereClause>
      operationTypeNotEqualTo(String operationType) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'operationType',
              lower: [],
              upper: [operationType],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'operationType',
              lower: [operationType],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'operationType',
              lower: [operationType],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'operationType',
              lower: [],
              upper: [operationType],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterWhereClause>
      entityTypeEqualTo(String entityType) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'entityType',
        value: [entityType],
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterWhereClause>
      entityTypeNotEqualTo(String entityType) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'entityType',
              lower: [],
              upper: [entityType],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'entityType',
              lower: [entityType],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'entityType',
              lower: [entityType],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'entityType',
              lower: [],
              upper: [entityType],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterWhereClause>
      entityIdEqualTo(String entityId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'entityId',
        value: [entityId],
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterWhereClause>
      entityIdNotEqualTo(String entityId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'entityId',
              lower: [],
              upper: [entityId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'entityId',
              lower: [entityId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'entityId',
              lower: [entityId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'entityId',
              lower: [],
              upper: [entityId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterWhereClause>
      statusEqualTo(IdempotencyStatus status) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'status',
        value: [status],
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterWhereClause>
      statusNotEqualTo(IdempotencyStatus status) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [],
              upper: [status],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [status],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [status],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [],
              upper: [status],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarIdempotencyRecordQueryFilter on QueryBuilder<
    IsarIdempotencyRecord, IsarIdempotencyRecord, QFilterCondition> {
  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> canRetryEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'canRetry',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
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

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
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

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
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

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> entityIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'entityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> entityIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'entityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> entityIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'entityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> entityIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'entityId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> entityIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'entityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> entityIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'entityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
          QAfterFilterCondition>
      entityIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'entityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
          QAfterFilterCondition>
      entityIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'entityId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> entityIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'entityId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> entityIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'entityId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> entityTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'entityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> entityTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'entityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> entityTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'entityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> entityTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'entityType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> entityTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'entityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> entityTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'entityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
          QAfterFilterCondition>
      entityTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'entityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
          QAfterFilterCondition>
      entityTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'entityType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> entityTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'entityType',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> entityTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'entityType',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> errorMessageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'errorMessage',
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> errorMessageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'errorMessage',
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> errorMessageEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> errorMessageGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> errorMessageLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> errorMessageBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'errorMessage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> errorMessageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> errorMessageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
          QAfterFilterCondition>
      errorMessageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
          QAfterFilterCondition>
      errorMessageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'errorMessage',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> errorMessageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'errorMessage',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> errorMessageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'errorMessage',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> expiresAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'expiresAt',
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> expiresAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'expiresAt',
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> expiresAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'expiresAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> expiresAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'expiresAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> expiresAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'expiresAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> expiresAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'expiresAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> hashCodeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> hashCodeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> hashCodeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> hashCodeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hashCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
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

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
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

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
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

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> idempotencyKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idempotencyKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> idempotencyKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'idempotencyKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> idempotencyKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'idempotencyKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> idempotencyKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'idempotencyKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> idempotencyKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'idempotencyKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> idempotencyKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'idempotencyKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
          QAfterFilterCondition>
      idempotencyKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'idempotencyKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
          QAfterFilterCondition>
      idempotencyKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'idempotencyKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> idempotencyKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idempotencyKey',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> idempotencyKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'idempotencyKey',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> isCompletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isCompleted',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> isExpiredEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isExpired',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> isFailedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isFailed',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> isPendingEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isPending',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> isProcessingEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isProcessing',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> lastRetryAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastRetryAt',
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> lastRetryAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastRetryAt',
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> lastRetryAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastRetryAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> lastRetryAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastRetryAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> lastRetryAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastRetryAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> lastRetryAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastRetryAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> operationTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'operationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> operationTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'operationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> operationTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'operationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> operationTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'operationType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> operationTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'operationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> operationTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'operationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
          QAfterFilterCondition>
      operationTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'operationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
          QAfterFilterCondition>
      operationTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'operationType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> operationTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'operationType',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> operationTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'operationType',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> processedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'processedAt',
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> processedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'processedAt',
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> processedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'processedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> processedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'processedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> processedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'processedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> processedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'processedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> responseDataIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'responseData',
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> responseDataIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'responseData',
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> responseDataEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'responseData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> responseDataGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'responseData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> responseDataLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'responseData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> responseDataBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'responseData',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> responseDataStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'responseData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> responseDataEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'responseData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
          QAfterFilterCondition>
      responseDataContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'responseData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
          QAfterFilterCondition>
      responseDataMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'responseData',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> responseDataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'responseData',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> responseDataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'responseData',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> retryCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'retryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> retryCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'retryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> retryCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'retryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> retryCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'retryCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> statusEqualTo(
    IdempotencyStatus value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> statusGreaterThan(
    IdempotencyStatus value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> statusLessThan(
    IdempotencyStatus value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> statusBetween(
    IdempotencyStatus lower,
    IdempotencyStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
          QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
          QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
      QAfterFilterCondition> updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
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

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
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

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord,
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

extension IsarIdempotencyRecordQueryObject on QueryBuilder<
    IsarIdempotencyRecord, IsarIdempotencyRecord, QFilterCondition> {}

extension IsarIdempotencyRecordQueryLinks on QueryBuilder<IsarIdempotencyRecord,
    IsarIdempotencyRecord, QFilterCondition> {}

extension IsarIdempotencyRecordQuerySortBy
    on QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QSortBy> {
  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByCanRetry() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canRetry', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByCanRetryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canRetry', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByEntityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByEntityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByEntityType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityType', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByEntityTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityType', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByErrorMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByErrorMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByExpiresAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByExpiresAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByHashCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByIdempotencyKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idempotencyKey', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByIdempotencyKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idempotencyKey', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByIsCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByIsExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByIsExpiredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByIsFailed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFailed', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByIsFailedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFailed', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByIsPending() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPending', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByIsPendingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPending', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByIsProcessing() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isProcessing', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByIsProcessingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isProcessing', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByLastRetryAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastRetryAt', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByLastRetryAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastRetryAt', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByOperationType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'operationType', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByOperationTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'operationType', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByProcessedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'processedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByProcessedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'processedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByResponseData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'responseData', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByResponseDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'responseData', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByRetryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension IsarIdempotencyRecordQuerySortThenBy
    on QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QSortThenBy> {
  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByCanRetry() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canRetry', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByCanRetryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canRetry', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByEntityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByEntityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByEntityType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityType', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByEntityTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityType', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByErrorMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByErrorMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByExpiresAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByExpiresAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByHashCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByIdempotencyKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idempotencyKey', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByIdempotencyKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idempotencyKey', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByIsCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByIsExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByIsExpiredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByIsFailed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFailed', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByIsFailedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFailed', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByIsPending() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPending', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByIsPendingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPending', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByIsProcessing() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isProcessing', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByIsProcessingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isProcessing', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByLastRetryAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastRetryAt', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByLastRetryAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastRetryAt', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByOperationType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'operationType', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByOperationTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'operationType', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByProcessedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'processedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByProcessedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'processedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByResponseData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'responseData', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByResponseDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'responseData', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByRetryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension IsarIdempotencyRecordQueryWhereDistinct
    on QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QDistinct> {
  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QDistinct>
      distinctByCanRetry() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'canRetry');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QDistinct>
      distinctByEntityId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entityId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QDistinct>
      distinctByEntityType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entityType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QDistinct>
      distinctByErrorMessage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'errorMessage', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QDistinct>
      distinctByExpiresAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expiresAt');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QDistinct>
      distinctByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hashCode');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QDistinct>
      distinctByIdempotencyKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'idempotencyKey',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QDistinct>
      distinctByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isCompleted');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QDistinct>
      distinctByIsExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isExpired');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QDistinct>
      distinctByIsFailed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFailed');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QDistinct>
      distinctByIsPending() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPending');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QDistinct>
      distinctByIsProcessing() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isProcessing');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QDistinct>
      distinctByLastRetryAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastRetryAt');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QDistinct>
      distinctByOperationType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'operationType',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QDistinct>
      distinctByProcessedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'processedAt');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QDistinct>
      distinctByResponseData({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'responseData', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QDistinct>
      distinctByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'retryCount');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QDistinct>
      distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IsarIdempotencyRecord, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension IsarIdempotencyRecordQueryProperty on QueryBuilder<
    IsarIdempotencyRecord, IsarIdempotencyRecord, QQueryProperty> {
  QueryBuilder<IsarIdempotencyRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, bool, QQueryOperations>
      canRetryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'canRetry');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, String, QQueryOperations>
      entityIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entityId');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, String, QQueryOperations>
      entityTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entityType');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, String?, QQueryOperations>
      errorMessageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'errorMessage');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, DateTime?, QQueryOperations>
      expiresAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expiresAt');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, int, QQueryOperations>
      hashCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hashCode');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, String, QQueryOperations>
      idempotencyKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'idempotencyKey');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, bool, QQueryOperations>
      isCompletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isCompleted');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, bool, QQueryOperations>
      isExpiredProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isExpired');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, bool, QQueryOperations>
      isFailedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFailed');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, bool, QQueryOperations>
      isPendingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPending');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, bool, QQueryOperations>
      isProcessingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isProcessing');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, DateTime?, QQueryOperations>
      lastRetryAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastRetryAt');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, String, QQueryOperations>
      operationTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'operationType');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, DateTime?, QQueryOperations>
      processedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'processedAt');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, String?, QQueryOperations>
      responseDataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'responseData');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, int, QQueryOperations>
      retryCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'retryCount');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, IdempotencyStatus, QQueryOperations>
      statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<IsarIdempotencyRecord, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
