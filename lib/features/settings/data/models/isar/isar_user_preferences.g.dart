// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_user_preferences.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarUserPreferencesCollection on Isar {
  IsarCollection<IsarUserPreferences> get isarUserPreferences =>
      this.collection();
}

const IsarUserPreferencesSchema = CollectionSchema(
  name: r'IsarUserPreferences',
  id: 8399112685032142306,
  properties: {
    r'additionalSettingsJson': PropertySchema(
      id: 0,
      name: r'additionalSettingsJson',
      type: IsarType.string,
    ),
    r'allowOverselling': PropertySchema(
      id: 1,
      name: r'allowOverselling',
      type: IsarType.bool,
    ),
    r'autoDeductInventory': PropertySchema(
      id: 2,
      name: r'autoDeductInventory',
      type: IsarType.bool,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'defaultWarehouseId': PropertySchema(
      id: 4,
      name: r'defaultWarehouseId',
      type: IsarType.string,
    ),
    r'enableExpiryNotifications': PropertySchema(
      id: 5,
      name: r'enableExpiryNotifications',
      type: IsarType.bool,
    ),
    r'enableLowStockNotifications': PropertySchema(
      id: 6,
      name: r'enableLowStockNotifications',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 7,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'lastModifiedAt': PropertySchema(
      id: 8,
      name: r'lastModifiedAt',
      type: IsarType.dateTime,
    ),
    r'lastModifiedBy': PropertySchema(
      id: 9,
      name: r'lastModifiedBy',
      type: IsarType.string,
    ),
    r'lastSyncAt': PropertySchema(
      id: 10,
      name: r'lastSyncAt',
      type: IsarType.dateTime,
    ),
    r'needsSync': PropertySchema(
      id: 11,
      name: r'needsSync',
      type: IsarType.bool,
    ),
    r'organizationId': PropertySchema(
      id: 12,
      name: r'organizationId',
      type: IsarType.string,
    ),
    r'serverId': PropertySchema(
      id: 13,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'showConfirmationDialogs': PropertySchema(
      id: 14,
      name: r'showConfirmationDialogs',
      type: IsarType.bool,
    ),
    r'showStockWarnings': PropertySchema(
      id: 15,
      name: r'showStockWarnings',
      type: IsarType.bool,
    ),
    r'updatedAt': PropertySchema(
      id: 16,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'useCompactMode': PropertySchema(
      id: 17,
      name: r'useCompactMode',
      type: IsarType.bool,
    ),
    r'useFifoCosting': PropertySchema(
      id: 18,
      name: r'useFifoCosting',
      type: IsarType.bool,
    ),
    r'userId': PropertySchema(
      id: 19,
      name: r'userId',
      type: IsarType.string,
    ),
    r'validateStockBeforeInvoice': PropertySchema(
      id: 20,
      name: r'validateStockBeforeInvoice',
      type: IsarType.bool,
    ),
    r'version': PropertySchema(
      id: 21,
      name: r'version',
      type: IsarType.long,
    )
  },
  estimateSize: _isarUserPreferencesEstimateSize,
  serialize: _isarUserPreferencesSerialize,
  deserialize: _isarUserPreferencesDeserialize,
  deserializeProp: _isarUserPreferencesDeserializeProp,
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
    r'userId': IndexSchema(
      id: -2005826577402374815,
      name: r'userId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'userId',
          type: IndexType.hash,
          caseSensitive: true,
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
  getId: _isarUserPreferencesGetId,
  getLinks: _isarUserPreferencesGetLinks,
  attach: _isarUserPreferencesAttach,
  version: '3.1.0+1',
);

int _isarUserPreferencesEstimateSize(
  IsarUserPreferences object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.additionalSettingsJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.defaultWarehouseId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.lastModifiedBy;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.organizationId.length * 3;
  bytesCount += 3 + object.serverId.length * 3;
  bytesCount += 3 + object.userId.length * 3;
  return bytesCount;
}

void _isarUserPreferencesSerialize(
  IsarUserPreferences object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.additionalSettingsJson);
  writer.writeBool(offsets[1], object.allowOverselling);
  writer.writeBool(offsets[2], object.autoDeductInventory);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeString(offsets[4], object.defaultWarehouseId);
  writer.writeBool(offsets[5], object.enableExpiryNotifications);
  writer.writeBool(offsets[6], object.enableLowStockNotifications);
  writer.writeBool(offsets[7], object.isSynced);
  writer.writeDateTime(offsets[8], object.lastModifiedAt);
  writer.writeString(offsets[9], object.lastModifiedBy);
  writer.writeDateTime(offsets[10], object.lastSyncAt);
  writer.writeBool(offsets[11], object.needsSync);
  writer.writeString(offsets[12], object.organizationId);
  writer.writeString(offsets[13], object.serverId);
  writer.writeBool(offsets[14], object.showConfirmationDialogs);
  writer.writeBool(offsets[15], object.showStockWarnings);
  writer.writeDateTime(offsets[16], object.updatedAt);
  writer.writeBool(offsets[17], object.useCompactMode);
  writer.writeBool(offsets[18], object.useFifoCosting);
  writer.writeString(offsets[19], object.userId);
  writer.writeBool(offsets[20], object.validateStockBeforeInvoice);
  writer.writeLong(offsets[21], object.version);
}

IsarUserPreferences _isarUserPreferencesDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarUserPreferences();
  object.additionalSettingsJson = reader.readStringOrNull(offsets[0]);
  object.allowOverselling = reader.readBool(offsets[1]);
  object.autoDeductInventory = reader.readBool(offsets[2]);
  object.createdAt = reader.readDateTime(offsets[3]);
  object.defaultWarehouseId = reader.readStringOrNull(offsets[4]);
  object.enableExpiryNotifications = reader.readBool(offsets[5]);
  object.enableLowStockNotifications = reader.readBool(offsets[6]);
  object.id = id;
  object.isSynced = reader.readBool(offsets[7]);
  object.lastModifiedAt = reader.readDateTimeOrNull(offsets[8]);
  object.lastModifiedBy = reader.readStringOrNull(offsets[9]);
  object.lastSyncAt = reader.readDateTimeOrNull(offsets[10]);
  object.organizationId = reader.readString(offsets[12]);
  object.serverId = reader.readString(offsets[13]);
  object.showConfirmationDialogs = reader.readBool(offsets[14]);
  object.showStockWarnings = reader.readBool(offsets[15]);
  object.updatedAt = reader.readDateTime(offsets[16]);
  object.useCompactMode = reader.readBool(offsets[17]);
  object.useFifoCosting = reader.readBool(offsets[18]);
  object.userId = reader.readString(offsets[19]);
  object.validateStockBeforeInvoice = reader.readBool(offsets[20]);
  object.version = reader.readLong(offsets[21]);
  return object;
}

P _isarUserPreferencesDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 11:
      return (reader.readBool(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readBool(offset)) as P;
    case 15:
      return (reader.readBool(offset)) as P;
    case 16:
      return (reader.readDateTime(offset)) as P;
    case 17:
      return (reader.readBool(offset)) as P;
    case 18:
      return (reader.readBool(offset)) as P;
    case 19:
      return (reader.readString(offset)) as P;
    case 20:
      return (reader.readBool(offset)) as P;
    case 21:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarUserPreferencesGetId(IsarUserPreferences object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarUserPreferencesGetLinks(
    IsarUserPreferences object) {
  return [];
}

void _isarUserPreferencesAttach(
    IsarCollection<dynamic> col, Id id, IsarUserPreferences object) {
  object.id = id;
}

extension IsarUserPreferencesByIndex on IsarCollection<IsarUserPreferences> {
  Future<IsarUserPreferences?> getByServerId(String serverId) {
    return getByIndex(r'serverId', [serverId]);
  }

  IsarUserPreferences? getByServerIdSync(String serverId) {
    return getByIndexSync(r'serverId', [serverId]);
  }

  Future<bool> deleteByServerId(String serverId) {
    return deleteByIndex(r'serverId', [serverId]);
  }

  bool deleteByServerIdSync(String serverId) {
    return deleteByIndexSync(r'serverId', [serverId]);
  }

  Future<List<IsarUserPreferences?>> getAllByServerId(
      List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'serverId', values);
  }

  List<IsarUserPreferences?> getAllByServerIdSync(List<String> serverIdValues) {
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

  Future<Id> putByServerId(IsarUserPreferences object) {
    return putByIndex(r'serverId', object);
  }

  Id putByServerIdSync(IsarUserPreferences object, {bool saveLinks = true}) {
    return putByIndexSync(r'serverId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByServerId(List<IsarUserPreferences> objects) {
    return putAllByIndex(r'serverId', objects);
  }

  List<Id> putAllByServerIdSync(List<IsarUserPreferences> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'serverId', objects, saveLinks: saveLinks);
  }
}

extension IsarUserPreferencesQueryWhereSort
    on QueryBuilder<IsarUserPreferences, IsarUserPreferences, QWhere> {
  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarUserPreferencesQueryWhere
    on QueryBuilder<IsarUserPreferences, IsarUserPreferences, QWhereClause> {
  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterWhereClause>
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterWhereClause>
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterWhereClause>
      serverIdEqualTo(String serverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'serverId',
        value: [serverId],
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterWhereClause>
      serverIdNotEqualTo(String serverId) {
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterWhereClause>
      userIdEqualTo(String userId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userId',
        value: [userId],
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterWhereClause>
      userIdNotEqualTo(String userId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [],
              upper: [userId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [userId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [userId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [],
              upper: [userId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterWhereClause>
      organizationIdEqualTo(String organizationId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'organizationId',
        value: [organizationId],
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterWhereClause>
      organizationIdNotEqualTo(String organizationId) {
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

extension IsarUserPreferencesQueryFilter on QueryBuilder<IsarUserPreferences,
    IsarUserPreferences, QFilterCondition> {
  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      additionalSettingsJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'additionalSettingsJson',
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      additionalSettingsJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'additionalSettingsJson',
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      additionalSettingsJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'additionalSettingsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      additionalSettingsJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'additionalSettingsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      additionalSettingsJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'additionalSettingsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      additionalSettingsJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'additionalSettingsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      additionalSettingsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'additionalSettingsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      additionalSettingsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'additionalSettingsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      additionalSettingsJsonContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'additionalSettingsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      additionalSettingsJsonMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'additionalSettingsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      additionalSettingsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'additionalSettingsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      additionalSettingsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'additionalSettingsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      allowOversellingEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'allowOverselling',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      autoDeductInventoryEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'autoDeductInventory',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      createdAtGreaterThan(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      createdAtLessThan(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      createdAtBetween(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      defaultWarehouseIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'defaultWarehouseId',
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      defaultWarehouseIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'defaultWarehouseId',
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      defaultWarehouseIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'defaultWarehouseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      defaultWarehouseIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'defaultWarehouseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      defaultWarehouseIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'defaultWarehouseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      defaultWarehouseIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'defaultWarehouseId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      defaultWarehouseIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'defaultWarehouseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      defaultWarehouseIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'defaultWarehouseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      defaultWarehouseIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'defaultWarehouseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      defaultWarehouseIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'defaultWarehouseId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      defaultWarehouseIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'defaultWarehouseId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      defaultWarehouseIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'defaultWarehouseId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      enableExpiryNotificationsEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'enableExpiryNotifications',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      enableLowStockNotificationsEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'enableLowStockNotifications',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      lastModifiedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastModifiedAt',
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      lastModifiedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastModifiedAt',
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      lastModifiedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastModifiedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      lastModifiedAtGreaterThan(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      lastModifiedAtLessThan(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      lastModifiedAtBetween(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      lastModifiedByIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastModifiedBy',
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      lastModifiedByIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastModifiedBy',
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      lastModifiedByEqualTo(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      lastModifiedByGreaterThan(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      lastModifiedByLessThan(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      lastModifiedByBetween(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      lastModifiedByStartsWith(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      lastModifiedByEndsWith(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      lastModifiedByContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastModifiedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      lastModifiedByMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastModifiedBy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      lastModifiedByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastModifiedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      lastModifiedByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastModifiedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      lastSyncAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSyncAt',
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      lastSyncAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSyncAt',
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      lastSyncAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSyncAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      lastSyncAtGreaterThan(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      lastSyncAtLessThan(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      lastSyncAtBetween(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      needsSyncEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'needsSync',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      organizationIdEqualTo(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      organizationIdGreaterThan(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      organizationIdLessThan(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      organizationIdBetween(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      organizationIdStartsWith(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      organizationIdEndsWith(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      organizationIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'organizationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      organizationIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'organizationId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      organizationIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'organizationId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      organizationIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'organizationId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      serverIdEqualTo(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      serverIdGreaterThan(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      serverIdLessThan(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      serverIdBetween(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      serverIdStartsWith(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      serverIdEndsWith(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      serverIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      serverIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'serverId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      showConfirmationDialogsEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'showConfirmationDialogs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      showStockWarningsEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'showStockWarnings',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      updatedAtGreaterThan(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      updatedAtLessThan(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      updatedAtBetween(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      useCompactModeEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'useCompactMode',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      useFifoCostingEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'useFifoCosting',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      userIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      userIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      userIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      userIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      userIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      userIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      userIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      userIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      validateStockBeforeInvoiceEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'validateStockBeforeInvoice',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      versionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      versionGreaterThan(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      versionLessThan(
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

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterFilterCondition>
      versionBetween(
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

extension IsarUserPreferencesQueryObject on QueryBuilder<IsarUserPreferences,
    IsarUserPreferences, QFilterCondition> {}

extension IsarUserPreferencesQueryLinks on QueryBuilder<IsarUserPreferences,
    IsarUserPreferences, QFilterCondition> {}

extension IsarUserPreferencesQuerySortBy
    on QueryBuilder<IsarUserPreferences, IsarUserPreferences, QSortBy> {
  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByAdditionalSettingsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'additionalSettingsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByAdditionalSettingsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'additionalSettingsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByAllowOverselling() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowOverselling', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByAllowOversellingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowOverselling', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByAutoDeductInventory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoDeductInventory', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByAutoDeductInventoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoDeductInventory', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByDefaultWarehouseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultWarehouseId', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByDefaultWarehouseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultWarehouseId', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByEnableExpiryNotifications() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enableExpiryNotifications', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByEnableExpiryNotificationsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enableExpiryNotifications', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByEnableLowStockNotifications() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enableLowStockNotifications', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByEnableLowStockNotificationsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enableLowStockNotifications', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByLastModifiedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByLastModifiedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByLastModifiedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedBy', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByLastModifiedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedBy', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByLastSyncAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByNeedsSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByOrganizationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationId', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByOrganizationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationId', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByShowConfirmationDialogs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showConfirmationDialogs', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByShowConfirmationDialogsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showConfirmationDialogs', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByShowStockWarnings() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showStockWarnings', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByShowStockWarningsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showStockWarnings', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByUseCompactMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useCompactMode', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByUseCompactModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useCompactMode', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByUseFifoCosting() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useFifoCosting', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByUseFifoCostingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useFifoCosting', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByValidateStockBeforeInvoice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'validateStockBeforeInvoice', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByValidateStockBeforeInvoiceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'validateStockBeforeInvoice', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      sortByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension IsarUserPreferencesQuerySortThenBy
    on QueryBuilder<IsarUserPreferences, IsarUserPreferences, QSortThenBy> {
  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByAdditionalSettingsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'additionalSettingsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByAdditionalSettingsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'additionalSettingsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByAllowOverselling() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowOverselling', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByAllowOversellingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowOverselling', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByAutoDeductInventory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoDeductInventory', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByAutoDeductInventoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoDeductInventory', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByDefaultWarehouseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultWarehouseId', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByDefaultWarehouseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultWarehouseId', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByEnableExpiryNotifications() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enableExpiryNotifications', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByEnableExpiryNotificationsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enableExpiryNotifications', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByEnableLowStockNotifications() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enableLowStockNotifications', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByEnableLowStockNotificationsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enableLowStockNotifications', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByLastModifiedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByLastModifiedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByLastModifiedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedBy', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByLastModifiedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedBy', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByLastSyncAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByNeedsSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByOrganizationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationId', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByOrganizationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationId', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByShowConfirmationDialogs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showConfirmationDialogs', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByShowConfirmationDialogsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showConfirmationDialogs', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByShowStockWarnings() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showStockWarnings', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByShowStockWarningsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showStockWarnings', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByUseCompactMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useCompactMode', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByUseCompactModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useCompactMode', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByUseFifoCosting() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useFifoCosting', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByUseFifoCostingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useFifoCosting', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByValidateStockBeforeInvoice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'validateStockBeforeInvoice', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByValidateStockBeforeInvoiceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'validateStockBeforeInvoice', Sort.desc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QAfterSortBy>
      thenByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension IsarUserPreferencesQueryWhereDistinct
    on QueryBuilder<IsarUserPreferences, IsarUserPreferences, QDistinct> {
  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QDistinct>
      distinctByAdditionalSettingsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'additionalSettingsJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QDistinct>
      distinctByAllowOverselling() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'allowOverselling');
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QDistinct>
      distinctByAutoDeductInventory() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoDeductInventory');
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QDistinct>
      distinctByDefaultWarehouseId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'defaultWarehouseId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QDistinct>
      distinctByEnableExpiryNotifications() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'enableExpiryNotifications');
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QDistinct>
      distinctByEnableLowStockNotifications() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'enableLowStockNotifications');
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QDistinct>
      distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QDistinct>
      distinctByLastModifiedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastModifiedAt');
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QDistinct>
      distinctByLastModifiedBy({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastModifiedBy',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QDistinct>
      distinctByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncAt');
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QDistinct>
      distinctByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'needsSync');
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QDistinct>
      distinctByOrganizationId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'organizationId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QDistinct>
      distinctByServerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QDistinct>
      distinctByShowConfirmationDialogs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'showConfirmationDialogs');
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QDistinct>
      distinctByShowStockWarnings() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'showStockWarnings');
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QDistinct>
      distinctByUseCompactMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'useCompactMode');
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QDistinct>
      distinctByUseFifoCosting() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'useFifoCosting');
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QDistinct>
      distinctByUserId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QDistinct>
      distinctByValidateStockBeforeInvoice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'validateStockBeforeInvoice');
    });
  }

  QueryBuilder<IsarUserPreferences, IsarUserPreferences, QDistinct>
      distinctByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'version');
    });
  }
}

extension IsarUserPreferencesQueryProperty
    on QueryBuilder<IsarUserPreferences, IsarUserPreferences, QQueryProperty> {
  QueryBuilder<IsarUserPreferences, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarUserPreferences, String?, QQueryOperations>
      additionalSettingsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'additionalSettingsJson');
    });
  }

  QueryBuilder<IsarUserPreferences, bool, QQueryOperations>
      allowOversellingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'allowOverselling');
    });
  }

  QueryBuilder<IsarUserPreferences, bool, QQueryOperations>
      autoDeductInventoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoDeductInventory');
    });
  }

  QueryBuilder<IsarUserPreferences, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<IsarUserPreferences, String?, QQueryOperations>
      defaultWarehouseIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'defaultWarehouseId');
    });
  }

  QueryBuilder<IsarUserPreferences, bool, QQueryOperations>
      enableExpiryNotificationsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'enableExpiryNotifications');
    });
  }

  QueryBuilder<IsarUserPreferences, bool, QQueryOperations>
      enableLowStockNotificationsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'enableLowStockNotifications');
    });
  }

  QueryBuilder<IsarUserPreferences, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<IsarUserPreferences, DateTime?, QQueryOperations>
      lastModifiedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastModifiedAt');
    });
  }

  QueryBuilder<IsarUserPreferences, String?, QQueryOperations>
      lastModifiedByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastModifiedBy');
    });
  }

  QueryBuilder<IsarUserPreferences, DateTime?, QQueryOperations>
      lastSyncAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncAt');
    });
  }

  QueryBuilder<IsarUserPreferences, bool, QQueryOperations>
      needsSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'needsSync');
    });
  }

  QueryBuilder<IsarUserPreferences, String, QQueryOperations>
      organizationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'organizationId');
    });
  }

  QueryBuilder<IsarUserPreferences, String, QQueryOperations>
      serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<IsarUserPreferences, bool, QQueryOperations>
      showConfirmationDialogsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'showConfirmationDialogs');
    });
  }

  QueryBuilder<IsarUserPreferences, bool, QQueryOperations>
      showStockWarningsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'showStockWarnings');
    });
  }

  QueryBuilder<IsarUserPreferences, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<IsarUserPreferences, bool, QQueryOperations>
      useCompactModeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'useCompactMode');
    });
  }

  QueryBuilder<IsarUserPreferences, bool, QQueryOperations>
      useFifoCostingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'useFifoCosting');
    });
  }

  QueryBuilder<IsarUserPreferences, String, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }

  QueryBuilder<IsarUserPreferences, bool, QQueryOperations>
      validateStockBeforeInvoiceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'validateStockBeforeInvoice');
    });
  }

  QueryBuilder<IsarUserPreferences, int, QQueryOperations> versionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'version');
    });
  }
}
