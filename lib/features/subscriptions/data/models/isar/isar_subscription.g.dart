// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_subscription.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarSubscriptionCollection on Isar {
  IsarCollection<IsarSubscription> get isarSubscriptions => this.collection();
}

const IsarSubscriptionSchema = CollectionSchema(
  name: r'IsarSubscription',
  id: -1005276068565913477,
  properties: {
    r'autoRenew': PropertySchema(
      id: 0,
      name: r'autoRenew',
      type: IsarType.bool,
    ),
    r'billingCycle': PropertySchema(
      id: 1,
      name: r'billingCycle',
      type: IsarType.long,
    ),
    r'currency': PropertySchema(
      id: 2,
      name: r'currency',
      type: IsarType.string,
    ),
    r'daysUntilExpiration': PropertySchema(
      id: 3,
      name: r'daysUntilExpiration',
      type: IsarType.long,
    ),
    r'endDate': PropertySchema(
      id: 4,
      name: r'endDate',
      type: IsarType.dateTime,
    ),
    r'isActive': PropertySchema(
      id: 5,
      name: r'isActive',
      type: IsarType.bool,
    ),
    r'isExpired': PropertySchema(
      id: 6,
      name: r'isExpired',
      type: IsarType.bool,
    ),
    r'isInOfflineGracePeriod': PropertySchema(
      id: 7,
      name: r'isInOfflineGracePeriod',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 8,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'isTrial': PropertySchema(
      id: 9,
      name: r'isTrial',
      type: IsarType.bool,
    ),
    r'lastModifiedAt': PropertySchema(
      id: 10,
      name: r'lastModifiedAt',
      type: IsarType.dateTime,
    ),
    r'lastModifiedBy': PropertySchema(
      id: 11,
      name: r'lastModifiedBy',
      type: IsarType.string,
    ),
    r'lastSyncAt': PropertySchema(
      id: 12,
      name: r'lastSyncAt',
      type: IsarType.dateTime,
    ),
    r'limitsJson': PropertySchema(
      id: 13,
      name: r'limitsJson',
      type: IsarType.string,
    ),
    r'maxUsers': PropertySchema(
      id: 14,
      name: r'maxUsers',
      type: IsarType.long,
    ),
    r'needsSync': PropertySchema(
      id: 15,
      name: r'needsSync',
      type: IsarType.bool,
    ),
    r'nextBillingDate': PropertySchema(
      id: 16,
      name: r'nextBillingDate',
      type: IsarType.dateTime,
    ),
    r'offlineGraceEnd': PropertySchema(
      id: 17,
      name: r'offlineGraceEnd',
      type: IsarType.dateTime,
    ),
    r'organizationId': PropertySchema(
      id: 18,
      name: r'organizationId',
      type: IsarType.string,
    ),
    r'paymentMethod': PropertySchema(
      id: 19,
      name: r'paymentMethod',
      type: IsarType.string,
    ),
    r'plan': PropertySchema(
      id: 20,
      name: r'plan',
      type: IsarType.string,
      enumMap: _IsarSubscriptionplanEnumValueMap,
    ),
    r'planDisplayName': PropertySchema(
      id: 21,
      name: r'planDisplayName',
      type: IsarType.string,
    ),
    r'price': PropertySchema(
      id: 22,
      name: r'price',
      type: IsarType.double,
    ),
    r'remainingDays': PropertySchema(
      id: 23,
      name: r'remainingDays',
      type: IsarType.long,
    ),
    r'serverId': PropertySchema(
      id: 24,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'startDate': PropertySchema(
      id: 25,
      name: r'startDate',
      type: IsarType.dateTime,
    ),
    r'status': PropertySchema(
      id: 26,
      name: r'status',
      type: IsarType.string,
      enumMap: _IsarSubscriptionstatusEnumValueMap,
    ),
    r'subscriptionProgress': PropertySchema(
      id: 27,
      name: r'subscriptionProgress',
      type: IsarType.double,
    ),
    r'trialEndsAt': PropertySchema(
      id: 28,
      name: r'trialEndsAt',
      type: IsarType.dateTime,
    ),
    r'type': PropertySchema(
      id: 29,
      name: r'type',
      type: IsarType.string,
      enumMap: _IsarSubscriptiontypeEnumValueMap,
    ),
    r'version': PropertySchema(
      id: 30,
      name: r'version',
      type: IsarType.long,
    ),
    r'wasExpiredOffline': PropertySchema(
      id: 31,
      name: r'wasExpiredOffline',
      type: IsarType.bool,
    )
  },
  estimateSize: _isarSubscriptionEstimateSize,
  serialize: _isarSubscriptionSerialize,
  deserialize: _isarSubscriptionDeserialize,
  deserializeProp: _isarSubscriptionDeserializeProp,
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
  getId: _isarSubscriptionGetId,
  getLinks: _isarSubscriptionGetLinks,
  attach: _isarSubscriptionAttach,
  version: '3.1.0+1',
);

int _isarSubscriptionEstimateSize(
  IsarSubscription object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.currency;
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
  bytesCount += 3 + object.limitsJson.length * 3;
  bytesCount += 3 + object.organizationId.length * 3;
  {
    final value = object.paymentMethod;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.plan.name.length * 3;
  bytesCount += 3 + object.planDisplayName.length * 3;
  bytesCount += 3 + object.serverId.length * 3;
  bytesCount += 3 + object.status.name.length * 3;
  bytesCount += 3 + object.type.name.length * 3;
  return bytesCount;
}

void _isarSubscriptionSerialize(
  IsarSubscription object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.autoRenew);
  writer.writeLong(offsets[1], object.billingCycle);
  writer.writeString(offsets[2], object.currency);
  writer.writeLong(offsets[3], object.daysUntilExpiration);
  writer.writeDateTime(offsets[4], object.endDate);
  writer.writeBool(offsets[5], object.isActive);
  writer.writeBool(offsets[6], object.isExpired);
  writer.writeBool(offsets[7], object.isInOfflineGracePeriod);
  writer.writeBool(offsets[8], object.isSynced);
  writer.writeBool(offsets[9], object.isTrial);
  writer.writeDateTime(offsets[10], object.lastModifiedAt);
  writer.writeString(offsets[11], object.lastModifiedBy);
  writer.writeDateTime(offsets[12], object.lastSyncAt);
  writer.writeString(offsets[13], object.limitsJson);
  writer.writeLong(offsets[14], object.maxUsers);
  writer.writeBool(offsets[15], object.needsSync);
  writer.writeDateTime(offsets[16], object.nextBillingDate);
  writer.writeDateTime(offsets[17], object.offlineGraceEnd);
  writer.writeString(offsets[18], object.organizationId);
  writer.writeString(offsets[19], object.paymentMethod);
  writer.writeString(offsets[20], object.plan.name);
  writer.writeString(offsets[21], object.planDisplayName);
  writer.writeDouble(offsets[22], object.price);
  writer.writeLong(offsets[23], object.remainingDays);
  writer.writeString(offsets[24], object.serverId);
  writer.writeDateTime(offsets[25], object.startDate);
  writer.writeString(offsets[26], object.status.name);
  writer.writeDouble(offsets[27], object.subscriptionProgress);
  writer.writeDateTime(offsets[28], object.trialEndsAt);
  writer.writeString(offsets[29], object.type.name);
  writer.writeLong(offsets[30], object.version);
  writer.writeBool(offsets[31], object.wasExpiredOffline);
}

IsarSubscription _isarSubscriptionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarSubscription();
  object.autoRenew = reader.readBool(offsets[0]);
  object.billingCycle = reader.readLong(offsets[1]);
  object.currency = reader.readStringOrNull(offsets[2]);
  object.daysUntilExpiration = reader.readLong(offsets[3]);
  object.endDate = reader.readDateTime(offsets[4]);
  object.id = id;
  object.isActive = reader.readBool(offsets[5]);
  object.isExpired = reader.readBool(offsets[6]);
  object.isSynced = reader.readBool(offsets[8]);
  object.isTrial = reader.readBool(offsets[9]);
  object.lastModifiedAt = reader.readDateTimeOrNull(offsets[10]);
  object.lastModifiedBy = reader.readStringOrNull(offsets[11]);
  object.lastSyncAt = reader.readDateTimeOrNull(offsets[12]);
  object.limitsJson = reader.readString(offsets[13]);
  object.maxUsers = reader.readLong(offsets[14]);
  object.nextBillingDate = reader.readDateTimeOrNull(offsets[16]);
  object.offlineGraceEnd = reader.readDateTimeOrNull(offsets[17]);
  object.organizationId = reader.readString(offsets[18]);
  object.paymentMethod = reader.readStringOrNull(offsets[19]);
  object.plan =
      _IsarSubscriptionplanValueEnumMap[reader.readStringOrNull(offsets[20])] ??
          IsarSubscriptionPlan.trial;
  object.planDisplayName = reader.readString(offsets[21]);
  object.price = reader.readDoubleOrNull(offsets[22]);
  object.remainingDays = reader.readLong(offsets[23]);
  object.serverId = reader.readString(offsets[24]);
  object.startDate = reader.readDateTime(offsets[25]);
  object.status = _IsarSubscriptionstatusValueEnumMap[
          reader.readStringOrNull(offsets[26])] ??
      IsarSubscriptionStatus.active;
  object.subscriptionProgress = reader.readDouble(offsets[27]);
  object.trialEndsAt = reader.readDateTimeOrNull(offsets[28]);
  object.type =
      _IsarSubscriptiontypeValueEnumMap[reader.readStringOrNull(offsets[29])] ??
          IsarSubscriptionType.trial;
  object.version = reader.readLong(offsets[30]);
  object.wasExpiredOffline = reader.readBool(offsets[31]);
  return object;
}

P _isarSubscriptionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
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
      return (reader.readDateTimeOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readLong(offset)) as P;
    case 15:
      return (reader.readBool(offset)) as P;
    case 16:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 17:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 18:
      return (reader.readString(offset)) as P;
    case 19:
      return (reader.readStringOrNull(offset)) as P;
    case 20:
      return (_IsarSubscriptionplanValueEnumMap[
              reader.readStringOrNull(offset)] ??
          IsarSubscriptionPlan.trial) as P;
    case 21:
      return (reader.readString(offset)) as P;
    case 22:
      return (reader.readDoubleOrNull(offset)) as P;
    case 23:
      return (reader.readLong(offset)) as P;
    case 24:
      return (reader.readString(offset)) as P;
    case 25:
      return (reader.readDateTime(offset)) as P;
    case 26:
      return (_IsarSubscriptionstatusValueEnumMap[
              reader.readStringOrNull(offset)] ??
          IsarSubscriptionStatus.active) as P;
    case 27:
      return (reader.readDouble(offset)) as P;
    case 28:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 29:
      return (_IsarSubscriptiontypeValueEnumMap[
              reader.readStringOrNull(offset)] ??
          IsarSubscriptionType.trial) as P;
    case 30:
      return (reader.readLong(offset)) as P;
    case 31:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _IsarSubscriptionplanEnumValueMap = {
  r'trial': r'trial',
  r'basic': r'basic',
  r'premium': r'premium',
  r'enterprise': r'enterprise',
};
const _IsarSubscriptionplanValueEnumMap = {
  r'trial': IsarSubscriptionPlan.trial,
  r'basic': IsarSubscriptionPlan.basic,
  r'premium': IsarSubscriptionPlan.premium,
  r'enterprise': IsarSubscriptionPlan.enterprise,
};
const _IsarSubscriptionstatusEnumValueMap = {
  r'active': r'active',
  r'expired': r'expired',
  r'cancelled': r'cancelled',
  r'suspended': r'suspended',
  r'pending': r'pending',
};
const _IsarSubscriptionstatusValueEnumMap = {
  r'active': IsarSubscriptionStatus.active,
  r'expired': IsarSubscriptionStatus.expired,
  r'cancelled': IsarSubscriptionStatus.cancelled,
  r'suspended': IsarSubscriptionStatus.suspended,
  r'pending': IsarSubscriptionStatus.pending,
};
const _IsarSubscriptiontypeEnumValueMap = {
  r'trial': r'trial',
  r'monthly': r'monthly',
  r'annual': r'annual',
  r'lifetime': r'lifetime',
};
const _IsarSubscriptiontypeValueEnumMap = {
  r'trial': IsarSubscriptionType.trial,
  r'monthly': IsarSubscriptionType.monthly,
  r'annual': IsarSubscriptionType.annual,
  r'lifetime': IsarSubscriptionType.lifetime,
};

Id _isarSubscriptionGetId(IsarSubscription object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarSubscriptionGetLinks(IsarSubscription object) {
  return [];
}

void _isarSubscriptionAttach(
    IsarCollection<dynamic> col, Id id, IsarSubscription object) {
  object.id = id;
}

extension IsarSubscriptionByIndex on IsarCollection<IsarSubscription> {
  Future<IsarSubscription?> getByServerId(String serverId) {
    return getByIndex(r'serverId', [serverId]);
  }

  IsarSubscription? getByServerIdSync(String serverId) {
    return getByIndexSync(r'serverId', [serverId]);
  }

  Future<bool> deleteByServerId(String serverId) {
    return deleteByIndex(r'serverId', [serverId]);
  }

  bool deleteByServerIdSync(String serverId) {
    return deleteByIndexSync(r'serverId', [serverId]);
  }

  Future<List<IsarSubscription?>> getAllByServerId(
      List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'serverId', values);
  }

  List<IsarSubscription?> getAllByServerIdSync(List<String> serverIdValues) {
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

  Future<Id> putByServerId(IsarSubscription object) {
    return putByIndex(r'serverId', object);
  }

  Id putByServerIdSync(IsarSubscription object, {bool saveLinks = true}) {
    return putByIndexSync(r'serverId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByServerId(List<IsarSubscription> objects) {
    return putAllByIndex(r'serverId', objects);
  }

  List<Id> putAllByServerIdSync(List<IsarSubscription> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'serverId', objects, saveLinks: saveLinks);
  }
}

extension IsarSubscriptionQueryWhereSort
    on QueryBuilder<IsarSubscription, IsarSubscription, QWhere> {
  QueryBuilder<IsarSubscription, IsarSubscription, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarSubscriptionQueryWhere
    on QueryBuilder<IsarSubscription, IsarSubscription, QWhereClause> {
  QueryBuilder<IsarSubscription, IsarSubscription, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterWhereClause>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterWhereClause>
      serverIdEqualTo(String serverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'serverId',
        value: [serverId],
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterWhereClause>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterWhereClause>
      organizationIdEqualTo(String organizationId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'organizationId',
        value: [organizationId],
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterWhereClause>
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

extension IsarSubscriptionQueryFilter
    on QueryBuilder<IsarSubscription, IsarSubscription, QFilterCondition> {
  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      autoRenewEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'autoRenew',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      billingCycleEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'billingCycle',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      billingCycleGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'billingCycle',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      billingCycleLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'billingCycle',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      billingCycleBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'billingCycle',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      currencyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'currency',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      currencyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'currency',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      currencyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      currencyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      currencyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      currencyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currency',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      currencyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      currencyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      currencyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      currencyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'currency',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      currencyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currency',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      currencyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'currency',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      daysUntilExpirationEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'daysUntilExpiration',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      daysUntilExpirationGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'daysUntilExpiration',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      daysUntilExpirationLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'daysUntilExpiration',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      daysUntilExpirationBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'daysUntilExpiration',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      endDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      endDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      endDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      endDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      isActiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isActive',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      isExpiredEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isExpired',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      isInOfflineGracePeriodEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isInOfflineGracePeriod',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      isTrialEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isTrial',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      lastModifiedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastModifiedAt',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      lastModifiedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastModifiedAt',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      lastModifiedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastModifiedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      lastModifiedByIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastModifiedBy',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      lastModifiedByIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastModifiedBy',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      lastModifiedByContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastModifiedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      lastModifiedByMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastModifiedBy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      lastModifiedByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastModifiedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      lastModifiedByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastModifiedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      lastSyncAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSyncAt',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      lastSyncAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSyncAt',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      lastSyncAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSyncAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      limitsJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'limitsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      limitsJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'limitsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      limitsJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'limitsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      limitsJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'limitsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      limitsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'limitsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      limitsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'limitsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      limitsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'limitsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      limitsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'limitsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      limitsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'limitsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      limitsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'limitsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      maxUsersEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxUsers',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      maxUsersGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxUsers',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      maxUsersLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxUsers',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      maxUsersBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxUsers',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      needsSyncEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'needsSync',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      nextBillingDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'nextBillingDate',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      nextBillingDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'nextBillingDate',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      nextBillingDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nextBillingDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      nextBillingDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nextBillingDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      nextBillingDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nextBillingDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      nextBillingDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nextBillingDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      offlineGraceEndIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'offlineGraceEnd',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      offlineGraceEndIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'offlineGraceEnd',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      offlineGraceEndEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'offlineGraceEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      offlineGraceEndGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'offlineGraceEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      offlineGraceEndLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'offlineGraceEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      offlineGraceEndBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'offlineGraceEnd',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      organizationIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'organizationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      organizationIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'organizationId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      organizationIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'organizationId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      organizationIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'organizationId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      paymentMethodIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'paymentMethod',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      paymentMethodIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'paymentMethod',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      paymentMethodEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentMethod',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      paymentMethodGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paymentMethod',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      paymentMethodLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paymentMethod',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      paymentMethodBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paymentMethod',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      paymentMethodStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'paymentMethod',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      paymentMethodEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'paymentMethod',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      paymentMethodContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'paymentMethod',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      paymentMethodMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'paymentMethod',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      paymentMethodIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentMethod',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      paymentMethodIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'paymentMethod',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      planEqualTo(
    IsarSubscriptionPlan value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'plan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      planGreaterThan(
    IsarSubscriptionPlan value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'plan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      planLessThan(
    IsarSubscriptionPlan value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'plan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      planBetween(
    IsarSubscriptionPlan lower,
    IsarSubscriptionPlan upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'plan',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      planStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'plan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      planEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'plan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      planContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'plan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      planMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'plan',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      planIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'plan',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      planIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'plan',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      planDisplayNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'planDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      planDisplayNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'planDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      planDisplayNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'planDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      planDisplayNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'planDisplayName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      planDisplayNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'planDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      planDisplayNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'planDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      planDisplayNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'planDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      planDisplayNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'planDisplayName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      planDisplayNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'planDisplayName',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      planDisplayNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'planDisplayName',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      priceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'price',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      priceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'price',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      priceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      priceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      priceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      priceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'price',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      remainingDaysEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remainingDays',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      remainingDaysGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remainingDays',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      remainingDaysLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remainingDays',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      remainingDaysBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remainingDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      serverIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      serverIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'serverId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      startDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      startDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      startDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      startDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      statusEqualTo(
    IsarSubscriptionStatus value, {
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      statusGreaterThan(
    IsarSubscriptionStatus value, {
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      statusLessThan(
    IsarSubscriptionStatus value, {
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      statusBetween(
    IsarSubscriptionStatus lower,
    IsarSubscriptionStatus upper, {
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      statusStartsWith(
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      statusEndsWith(
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      subscriptionProgressEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subscriptionProgress',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      subscriptionProgressGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subscriptionProgress',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      subscriptionProgressLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subscriptionProgress',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      subscriptionProgressBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subscriptionProgress',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      trialEndsAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'trialEndsAt',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      trialEndsAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'trialEndsAt',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      trialEndsAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'trialEndsAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      trialEndsAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'trialEndsAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      trialEndsAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'trialEndsAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      trialEndsAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'trialEndsAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      typeEqualTo(
    IsarSubscriptionType value, {
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      typeGreaterThan(
    IsarSubscriptionType value, {
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      typeLessThan(
    IsarSubscriptionType value, {
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      typeBetween(
    IsarSubscriptionType lower,
    IsarSubscriptionType upper, {
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      typeStartsWith(
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      typeEndsWith(
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      versionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      wasExpiredOfflineEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'wasExpiredOffline',
        value: value,
      ));
    });
  }
}

extension IsarSubscriptionQueryObject
    on QueryBuilder<IsarSubscription, IsarSubscription, QFilterCondition> {}

extension IsarSubscriptionQueryLinks
    on QueryBuilder<IsarSubscription, IsarSubscription, QFilterCondition> {}

extension IsarSubscriptionQuerySortBy
    on QueryBuilder<IsarSubscription, IsarSubscription, QSortBy> {
  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByAutoRenew() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoRenew', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByAutoRenewDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoRenew', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByBillingCycle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'billingCycle', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByBillingCycleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'billingCycle', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByDaysUntilExpiration() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysUntilExpiration', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByDaysUntilExpirationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysUntilExpiration', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByIsExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByIsExpiredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByIsInOfflineGracePeriod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isInOfflineGracePeriod', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByIsInOfflineGracePeriodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isInOfflineGracePeriod', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByIsTrial() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTrial', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByIsTrialDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTrial', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByLastModifiedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByLastModifiedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByLastModifiedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedBy', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByLastModifiedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedBy', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByLastSyncAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByLimitsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'limitsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByLimitsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'limitsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByMaxUsers() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxUsers', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByMaxUsersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxUsers', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByNeedsSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByNextBillingDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextBillingDate', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByNextBillingDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextBillingDate', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByOfflineGraceEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offlineGraceEnd', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByOfflineGraceEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offlineGraceEnd', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByOrganizationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationId', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByOrganizationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationId', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByPaymentMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByPaymentMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy> sortByPlan() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plan', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByPlanDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plan', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByPlanDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planDisplayName', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByPlanDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planDisplayName', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy> sortByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByRemainingDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingDays', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByRemainingDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingDays', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortBySubscriptionProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionProgress', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortBySubscriptionProgressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionProgress', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByTrialEndsAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trialEndsAt', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByTrialEndsAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trialEndsAt', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByWasExpiredOffline() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wasExpiredOffline', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByWasExpiredOfflineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wasExpiredOffline', Sort.desc);
    });
  }
}

extension IsarSubscriptionQuerySortThenBy
    on QueryBuilder<IsarSubscription, IsarSubscription, QSortThenBy> {
  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByAutoRenew() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoRenew', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByAutoRenewDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoRenew', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByBillingCycle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'billingCycle', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByBillingCycleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'billingCycle', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByDaysUntilExpiration() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysUntilExpiration', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByDaysUntilExpirationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysUntilExpiration', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByIsExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByIsExpiredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByIsInOfflineGracePeriod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isInOfflineGracePeriod', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByIsInOfflineGracePeriodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isInOfflineGracePeriod', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByIsTrial() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTrial', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByIsTrialDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTrial', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByLastModifiedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByLastModifiedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByLastModifiedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedBy', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByLastModifiedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedBy', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByLastSyncAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByLimitsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'limitsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByLimitsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'limitsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByMaxUsers() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxUsers', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByMaxUsersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxUsers', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByNeedsSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByNextBillingDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextBillingDate', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByNextBillingDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextBillingDate', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByOfflineGraceEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offlineGraceEnd', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByOfflineGraceEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offlineGraceEnd', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByOrganizationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationId', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByOrganizationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationId', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByPaymentMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByPaymentMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy> thenByPlan() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plan', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByPlanDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plan', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByPlanDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planDisplayName', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByPlanDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'planDisplayName', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy> thenByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByRemainingDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingDays', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByRemainingDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingDays', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenBySubscriptionProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionProgress', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenBySubscriptionProgressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionProgress', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByTrialEndsAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trialEndsAt', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByTrialEndsAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trialEndsAt', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByWasExpiredOffline() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wasExpiredOffline', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByWasExpiredOfflineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wasExpiredOffline', Sort.desc);
    });
  }
}

extension IsarSubscriptionQueryWhereDistinct
    on QueryBuilder<IsarSubscription, IsarSubscription, QDistinct> {
  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByAutoRenew() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoRenew');
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByBillingCycle() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'billingCycle');
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByCurrency({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currency', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByDaysUntilExpiration() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'daysUntilExpiration');
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endDate');
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActive');
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByIsExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isExpired');
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByIsInOfflineGracePeriod() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isInOfflineGracePeriod');
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByIsTrial() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isTrial');
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByLastModifiedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastModifiedAt');
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByLastModifiedBy({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastModifiedBy',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncAt');
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByLimitsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'limitsJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByMaxUsers() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxUsers');
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'needsSync');
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByNextBillingDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nextBillingDate');
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByOfflineGraceEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'offlineGraceEnd');
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByOrganizationId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'organizationId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByPaymentMethod({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paymentMethod',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct> distinctByPlan(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'plan', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByPlanDisplayName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'planDisplayName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'price');
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByRemainingDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remainingDays');
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByServerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startDate');
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctBySubscriptionProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subscriptionProgress');
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByTrialEndsAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'trialEndsAt');
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct> distinctByType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'version');
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByWasExpiredOffline() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'wasExpiredOffline');
    });
  }
}

extension IsarSubscriptionQueryProperty
    on QueryBuilder<IsarSubscription, IsarSubscription, QQueryProperty> {
  QueryBuilder<IsarSubscription, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarSubscription, bool, QQueryOperations> autoRenewProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoRenew');
    });
  }

  QueryBuilder<IsarSubscription, int, QQueryOperations> billingCycleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'billingCycle');
    });
  }

  QueryBuilder<IsarSubscription, String?, QQueryOperations> currencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currency');
    });
  }

  QueryBuilder<IsarSubscription, int, QQueryOperations>
      daysUntilExpirationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'daysUntilExpiration');
    });
  }

  QueryBuilder<IsarSubscription, DateTime, QQueryOperations> endDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endDate');
    });
  }

  QueryBuilder<IsarSubscription, bool, QQueryOperations> isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActive');
    });
  }

  QueryBuilder<IsarSubscription, bool, QQueryOperations> isExpiredProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isExpired');
    });
  }

  QueryBuilder<IsarSubscription, bool, QQueryOperations>
      isInOfflineGracePeriodProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isInOfflineGracePeriod');
    });
  }

  QueryBuilder<IsarSubscription, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<IsarSubscription, bool, QQueryOperations> isTrialProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isTrial');
    });
  }

  QueryBuilder<IsarSubscription, DateTime?, QQueryOperations>
      lastModifiedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastModifiedAt');
    });
  }

  QueryBuilder<IsarSubscription, String?, QQueryOperations>
      lastModifiedByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastModifiedBy');
    });
  }

  QueryBuilder<IsarSubscription, DateTime?, QQueryOperations>
      lastSyncAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncAt');
    });
  }

  QueryBuilder<IsarSubscription, String, QQueryOperations>
      limitsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'limitsJson');
    });
  }

  QueryBuilder<IsarSubscription, int, QQueryOperations> maxUsersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxUsers');
    });
  }

  QueryBuilder<IsarSubscription, bool, QQueryOperations> needsSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'needsSync');
    });
  }

  QueryBuilder<IsarSubscription, DateTime?, QQueryOperations>
      nextBillingDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nextBillingDate');
    });
  }

  QueryBuilder<IsarSubscription, DateTime?, QQueryOperations>
      offlineGraceEndProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'offlineGraceEnd');
    });
  }

  QueryBuilder<IsarSubscription, String, QQueryOperations>
      organizationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'organizationId');
    });
  }

  QueryBuilder<IsarSubscription, String?, QQueryOperations>
      paymentMethodProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paymentMethod');
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscriptionPlan, QQueryOperations>
      planProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'plan');
    });
  }

  QueryBuilder<IsarSubscription, String, QQueryOperations>
      planDisplayNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'planDisplayName');
    });
  }

  QueryBuilder<IsarSubscription, double?, QQueryOperations> priceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'price');
    });
  }

  QueryBuilder<IsarSubscription, int, QQueryOperations>
      remainingDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remainingDays');
    });
  }

  QueryBuilder<IsarSubscription, String, QQueryOperations> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<IsarSubscription, DateTime, QQueryOperations>
      startDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startDate');
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscriptionStatus, QQueryOperations>
      statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<IsarSubscription, double, QQueryOperations>
      subscriptionProgressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subscriptionProgress');
    });
  }

  QueryBuilder<IsarSubscription, DateTime?, QQueryOperations>
      trialEndsAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'trialEndsAt');
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscriptionType, QQueryOperations>
      typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<IsarSubscription, int, QQueryOperations> versionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'version');
    });
  }

  QueryBuilder<IsarSubscription, bool, QQueryOperations>
      wasExpiredOfflineProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'wasExpiredOffline');
    });
  }
}
