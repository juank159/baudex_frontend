// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_organization.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarOrganizationCollection on Isar {
  IsarCollection<IsarOrganization> get isarOrganizations => this.collection();
}

const IsarOrganizationSchema = CollectionSchema(
  name: r'IsarOrganization',
  id: -1987124129506101121,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'currency': PropertySchema(
      id: 1,
      name: r'currency',
      type: IsarType.string,
    ),
    r'daysUntilExpiration': PropertySchema(
      id: 2,
      name: r'daysUntilExpiration',
      type: IsarType.long,
    ),
    r'daysUntilExpirationCached': PropertySchema(
      id: 3,
      name: r'daysUntilExpirationCached',
      type: IsarType.long,
    ),
    r'defaultProfitMarginPercentage': PropertySchema(
      id: 4,
      name: r'defaultProfitMarginPercentage',
      type: IsarType.double,
    ),
    r'deletedAt': PropertySchema(
      id: 5,
      name: r'deletedAt',
      type: IsarType.dateTime,
    ),
    r'domain': PropertySchema(
      id: 6,
      name: r'domain',
      type: IsarType.string,
    ),
    r'hasValidSubscription': PropertySchema(
      id: 7,
      name: r'hasValidSubscription',
      type: IsarType.bool,
    ),
    r'isActive': PropertySchema(
      id: 8,
      name: r'isActive',
      type: IsarType.bool,
    ),
    r'isActivePlan': PropertySchema(
      id: 9,
      name: r'isActivePlan',
      type: IsarType.bool,
    ),
    r'isDeleted': PropertySchema(
      id: 10,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'isExpired': PropertySchema(
      id: 11,
      name: r'isExpired',
      type: IsarType.bool,
    ),
    r'isSubscriptionActive': PropertySchema(
      id: 12,
      name: r'isSubscriptionActive',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 13,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'isTrialActive': PropertySchema(
      id: 14,
      name: r'isTrialActive',
      type: IsarType.bool,
    ),
    r'isTrialExpired': PropertySchema(
      id: 15,
      name: r'isTrialExpired',
      type: IsarType.bool,
    ),
    r'lastModifiedAt': PropertySchema(
      id: 16,
      name: r'lastModifiedAt',
      type: IsarType.dateTime,
    ),
    r'lastModifiedBy': PropertySchema(
      id: 17,
      name: r'lastModifiedBy',
      type: IsarType.string,
    ),
    r'lastSyncAt': PropertySchema(
      id: 18,
      name: r'lastSyncAt',
      type: IsarType.dateTime,
    ),
    r'locale': PropertySchema(
      id: 19,
      name: r'locale',
      type: IsarType.string,
    ),
    r'logo': PropertySchema(
      id: 20,
      name: r'logo',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 21,
      name: r'name',
      type: IsarType.string,
    ),
    r'needsSync': PropertySchema(
      id: 22,
      name: r'needsSync',
      type: IsarType.bool,
    ),
    r'serverId': PropertySchema(
      id: 23,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'settingsJson': PropertySchema(
      id: 24,
      name: r'settingsJson',
      type: IsarType.string,
    ),
    r'slug': PropertySchema(
      id: 25,
      name: r'slug',
      type: IsarType.string,
    ),
    r'subscriptionEndDate': PropertySchema(
      id: 26,
      name: r'subscriptionEndDate',
      type: IsarType.dateTime,
    ),
    r'subscriptionPlan': PropertySchema(
      id: 27,
      name: r'subscriptionPlan',
      type: IsarType.string,
      enumMap: _IsarOrganizationsubscriptionPlanEnumValueMap,
    ),
    r'subscriptionStartDate': PropertySchema(
      id: 28,
      name: r'subscriptionStartDate',
      type: IsarType.dateTime,
    ),
    r'subscriptionStatus': PropertySchema(
      id: 29,
      name: r'subscriptionStatus',
      type: IsarType.string,
      enumMap: _IsarOrganizationsubscriptionStatusEnumValueMap,
    ),
    r'timezone': PropertySchema(
      id: 30,
      name: r'timezone',
      type: IsarType.string,
    ),
    r'trialEndDate': PropertySchema(
      id: 31,
      name: r'trialEndDate',
      type: IsarType.dateTime,
    ),
    r'trialStartDate': PropertySchema(
      id: 32,
      name: r'trialStartDate',
      type: IsarType.dateTime,
    ),
    r'updatedAt': PropertySchema(
      id: 33,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'version': PropertySchema(
      id: 34,
      name: r'version',
      type: IsarType.long,
    )
  },
  estimateSize: _isarOrganizationEstimateSize,
  serialize: _isarOrganizationSerialize,
  deserialize: _isarOrganizationDeserialize,
  deserializeProp: _isarOrganizationDeserializeProp,
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
    r'name': IndexSchema(
      id: 879695947855722453,
      name: r'name',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'name',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'slug': IndexSchema(
      id: 6169444064746062836,
      name: r'slug',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'slug',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarOrganizationGetId,
  getLinks: _isarOrganizationGetLinks,
  attach: _isarOrganizationAttach,
  version: '3.1.0+1',
);

int _isarOrganizationEstimateSize(
  IsarOrganization object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.currency.length * 3;
  {
    final value = object.domain;
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
  bytesCount += 3 + object.locale.length * 3;
  {
    final value = object.logo;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.serverId.length * 3;
  {
    final value = object.settingsJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.slug.length * 3;
  bytesCount += 3 + object.subscriptionPlan.name.length * 3;
  bytesCount += 3 + object.subscriptionStatus.name.length * 3;
  bytesCount += 3 + object.timezone.length * 3;
  return bytesCount;
}

void _isarOrganizationSerialize(
  IsarOrganization object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.currency);
  writer.writeLong(offsets[2], object.daysUntilExpiration);
  writer.writeLong(offsets[3], object.daysUntilExpirationCached);
  writer.writeDouble(offsets[4], object.defaultProfitMarginPercentage);
  writer.writeDateTime(offsets[5], object.deletedAt);
  writer.writeString(offsets[6], object.domain);
  writer.writeBool(offsets[7], object.hasValidSubscription);
  writer.writeBool(offsets[8], object.isActive);
  writer.writeBool(offsets[9], object.isActivePlan);
  writer.writeBool(offsets[10], object.isDeleted);
  writer.writeBool(offsets[11], object.isExpired);
  writer.writeBool(offsets[12], object.isSubscriptionActive);
  writer.writeBool(offsets[13], object.isSynced);
  writer.writeBool(offsets[14], object.isTrialActive);
  writer.writeBool(offsets[15], object.isTrialExpired);
  writer.writeDateTime(offsets[16], object.lastModifiedAt);
  writer.writeString(offsets[17], object.lastModifiedBy);
  writer.writeDateTime(offsets[18], object.lastSyncAt);
  writer.writeString(offsets[19], object.locale);
  writer.writeString(offsets[20], object.logo);
  writer.writeString(offsets[21], object.name);
  writer.writeBool(offsets[22], object.needsSync);
  writer.writeString(offsets[23], object.serverId);
  writer.writeString(offsets[24], object.settingsJson);
  writer.writeString(offsets[25], object.slug);
  writer.writeDateTime(offsets[26], object.subscriptionEndDate);
  writer.writeString(offsets[27], object.subscriptionPlan.name);
  writer.writeDateTime(offsets[28], object.subscriptionStartDate);
  writer.writeString(offsets[29], object.subscriptionStatus.name);
  writer.writeString(offsets[30], object.timezone);
  writer.writeDateTime(offsets[31], object.trialEndDate);
  writer.writeDateTime(offsets[32], object.trialStartDate);
  writer.writeDateTime(offsets[33], object.updatedAt);
  writer.writeLong(offsets[34], object.version);
}

IsarOrganization _isarOrganizationDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarOrganization();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.currency = reader.readString(offsets[1]);
  object.daysUntilExpirationCached = reader.readLongOrNull(offsets[3]);
  object.defaultProfitMarginPercentage = reader.readDoubleOrNull(offsets[4]);
  object.deletedAt = reader.readDateTimeOrNull(offsets[5]);
  object.domain = reader.readStringOrNull(offsets[6]);
  object.hasValidSubscription = reader.readBoolOrNull(offsets[7]);
  object.id = id;
  object.isActive = reader.readBool(offsets[8]);
  object.isActivePlan = reader.readBoolOrNull(offsets[9]);
  object.isSynced = reader.readBool(offsets[13]);
  object.isTrialExpired = reader.readBoolOrNull(offsets[15]);
  object.lastModifiedAt = reader.readDateTimeOrNull(offsets[16]);
  object.lastModifiedBy = reader.readStringOrNull(offsets[17]);
  object.lastSyncAt = reader.readDateTimeOrNull(offsets[18]);
  object.locale = reader.readString(offsets[19]);
  object.logo = reader.readStringOrNull(offsets[20]);
  object.name = reader.readString(offsets[21]);
  object.serverId = reader.readString(offsets[23]);
  object.settingsJson = reader.readStringOrNull(offsets[24]);
  object.slug = reader.readString(offsets[25]);
  object.subscriptionEndDate = reader.readDateTimeOrNull(offsets[26]);
  object.subscriptionPlan = _IsarOrganizationsubscriptionPlanValueEnumMap[
          reader.readStringOrNull(offsets[27])] ??
      IsarSubscriptionPlan.trial;
  object.subscriptionStartDate = reader.readDateTimeOrNull(offsets[28]);
  object.subscriptionStatus = _IsarOrganizationsubscriptionStatusValueEnumMap[
          reader.readStringOrNull(offsets[29])] ??
      IsarSubscriptionStatus.active;
  object.timezone = reader.readString(offsets[30]);
  object.trialEndDate = reader.readDateTimeOrNull(offsets[31]);
  object.trialStartDate = reader.readDateTimeOrNull(offsets[32]);
  object.updatedAt = reader.readDateTime(offsets[33]);
  object.version = reader.readLong(offsets[34]);
  return object;
}

P _isarOrganizationDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readDoubleOrNull(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readBoolOrNull(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readBoolOrNull(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readBool(offset)) as P;
    case 12:
      return (reader.readBool(offset)) as P;
    case 13:
      return (reader.readBool(offset)) as P;
    case 14:
      return (reader.readBool(offset)) as P;
    case 15:
      return (reader.readBoolOrNull(offset)) as P;
    case 16:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 17:
      return (reader.readStringOrNull(offset)) as P;
    case 18:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 19:
      return (reader.readString(offset)) as P;
    case 20:
      return (reader.readStringOrNull(offset)) as P;
    case 21:
      return (reader.readString(offset)) as P;
    case 22:
      return (reader.readBool(offset)) as P;
    case 23:
      return (reader.readString(offset)) as P;
    case 24:
      return (reader.readStringOrNull(offset)) as P;
    case 25:
      return (reader.readString(offset)) as P;
    case 26:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 27:
      return (_IsarOrganizationsubscriptionPlanValueEnumMap[
              reader.readStringOrNull(offset)] ??
          IsarSubscriptionPlan.trial) as P;
    case 28:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 29:
      return (_IsarOrganizationsubscriptionStatusValueEnumMap[
              reader.readStringOrNull(offset)] ??
          IsarSubscriptionStatus.active) as P;
    case 30:
      return (reader.readString(offset)) as P;
    case 31:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 32:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 33:
      return (reader.readDateTime(offset)) as P;
    case 34:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _IsarOrganizationsubscriptionPlanEnumValueMap = {
  r'trial': r'trial',
  r'basic': r'basic',
  r'premium': r'premium',
  r'enterprise': r'enterprise',
};
const _IsarOrganizationsubscriptionPlanValueEnumMap = {
  r'trial': IsarSubscriptionPlan.trial,
  r'basic': IsarSubscriptionPlan.basic,
  r'premium': IsarSubscriptionPlan.premium,
  r'enterprise': IsarSubscriptionPlan.enterprise,
};
const _IsarOrganizationsubscriptionStatusEnumValueMap = {
  r'active': r'active',
  r'expired': r'expired',
  r'cancelled': r'cancelled',
  r'suspended': r'suspended',
};
const _IsarOrganizationsubscriptionStatusValueEnumMap = {
  r'active': IsarSubscriptionStatus.active,
  r'expired': IsarSubscriptionStatus.expired,
  r'cancelled': IsarSubscriptionStatus.cancelled,
  r'suspended': IsarSubscriptionStatus.suspended,
};

Id _isarOrganizationGetId(IsarOrganization object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarOrganizationGetLinks(IsarOrganization object) {
  return [];
}

void _isarOrganizationAttach(
    IsarCollection<dynamic> col, Id id, IsarOrganization object) {
  object.id = id;
}

extension IsarOrganizationByIndex on IsarCollection<IsarOrganization> {
  Future<IsarOrganization?> getByServerId(String serverId) {
    return getByIndex(r'serverId', [serverId]);
  }

  IsarOrganization? getByServerIdSync(String serverId) {
    return getByIndexSync(r'serverId', [serverId]);
  }

  Future<bool> deleteByServerId(String serverId) {
    return deleteByIndex(r'serverId', [serverId]);
  }

  bool deleteByServerIdSync(String serverId) {
    return deleteByIndexSync(r'serverId', [serverId]);
  }

  Future<List<IsarOrganization?>> getAllByServerId(
      List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'serverId', values);
  }

  List<IsarOrganization?> getAllByServerIdSync(List<String> serverIdValues) {
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

  Future<Id> putByServerId(IsarOrganization object) {
    return putByIndex(r'serverId', object);
  }

  Id putByServerIdSync(IsarOrganization object, {bool saveLinks = true}) {
    return putByIndexSync(r'serverId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByServerId(List<IsarOrganization> objects) {
    return putAllByIndex(r'serverId', objects);
  }

  List<Id> putAllByServerIdSync(List<IsarOrganization> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'serverId', objects, saveLinks: saveLinks);
  }

  Future<IsarOrganization?> getBySlug(String slug) {
    return getByIndex(r'slug', [slug]);
  }

  IsarOrganization? getBySlugSync(String slug) {
    return getByIndexSync(r'slug', [slug]);
  }

  Future<bool> deleteBySlug(String slug) {
    return deleteByIndex(r'slug', [slug]);
  }

  bool deleteBySlugSync(String slug) {
    return deleteByIndexSync(r'slug', [slug]);
  }

  Future<List<IsarOrganization?>> getAllBySlug(List<String> slugValues) {
    final values = slugValues.map((e) => [e]).toList();
    return getAllByIndex(r'slug', values);
  }

  List<IsarOrganization?> getAllBySlugSync(List<String> slugValues) {
    final values = slugValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'slug', values);
  }

  Future<int> deleteAllBySlug(List<String> slugValues) {
    final values = slugValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'slug', values);
  }

  int deleteAllBySlugSync(List<String> slugValues) {
    final values = slugValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'slug', values);
  }

  Future<Id> putBySlug(IsarOrganization object) {
    return putByIndex(r'slug', object);
  }

  Id putBySlugSync(IsarOrganization object, {bool saveLinks = true}) {
    return putByIndexSync(r'slug', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySlug(List<IsarOrganization> objects) {
    return putAllByIndex(r'slug', objects);
  }

  List<Id> putAllBySlugSync(List<IsarOrganization> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'slug', objects, saveLinks: saveLinks);
  }
}

extension IsarOrganizationQueryWhereSort
    on QueryBuilder<IsarOrganization, IsarOrganization, QWhere> {
  QueryBuilder<IsarOrganization, IsarOrganization, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarOrganizationQueryWhere
    on QueryBuilder<IsarOrganization, IsarOrganization, QWhereClause> {
  QueryBuilder<IsarOrganization, IsarOrganization, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterWhereClause>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterWhereClause>
      serverIdEqualTo(String serverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'serverId',
        value: [serverId],
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterWhereClause>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterWhereClause>
      nameEqualTo(String name) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'name',
        value: [name],
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterWhereClause>
      nameNotEqualTo(String name) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [],
              upper: [name],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [name],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [name],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [],
              upper: [name],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterWhereClause>
      slugEqualTo(String slug) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'slug',
        value: [slug],
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterWhereClause>
      slugNotEqualTo(String slug) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'slug',
              lower: [],
              upper: [slug],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'slug',
              lower: [slug],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'slug',
              lower: [slug],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'slug',
              lower: [],
              upper: [slug],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarOrganizationQueryFilter
    on QueryBuilder<IsarOrganization, IsarOrganization, QFilterCondition> {
  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      currencyEqualTo(
    String value, {
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      currencyGreaterThan(
    String value, {
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      currencyLessThan(
    String value, {
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      currencyBetween(
    String lower,
    String upper, {
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      currencyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      currencyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'currency',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      currencyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currency',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      currencyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'currency',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      daysUntilExpirationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'daysUntilExpiration',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      daysUntilExpirationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'daysUntilExpiration',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      daysUntilExpirationEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'daysUntilExpiration',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      daysUntilExpirationGreaterThan(
    int? value, {
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      daysUntilExpirationLessThan(
    int? value, {
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      daysUntilExpirationBetween(
    int? lower,
    int? upper, {
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      daysUntilExpirationCachedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'daysUntilExpirationCached',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      daysUntilExpirationCachedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'daysUntilExpirationCached',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      daysUntilExpirationCachedEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'daysUntilExpirationCached',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      daysUntilExpirationCachedGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'daysUntilExpirationCached',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      daysUntilExpirationCachedLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'daysUntilExpirationCached',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      daysUntilExpirationCachedBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'daysUntilExpirationCached',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      defaultProfitMarginPercentageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'defaultProfitMarginPercentage',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      defaultProfitMarginPercentageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'defaultProfitMarginPercentage',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      defaultProfitMarginPercentageEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'defaultProfitMarginPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      defaultProfitMarginPercentageGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'defaultProfitMarginPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      defaultProfitMarginPercentageLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'defaultProfitMarginPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      defaultProfitMarginPercentageBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'defaultProfitMarginPercentage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      deletedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      deletedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      deletedAtGreaterThan(
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      deletedAtLessThan(
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      deletedAtBetween(
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      domainIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'domain',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      domainIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'domain',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      domainEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'domain',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      domainGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'domain',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      domainLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'domain',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      domainBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'domain',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      domainStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'domain',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      domainEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'domain',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      domainContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'domain',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      domainMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'domain',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      domainIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'domain',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      domainIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'domain',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      hasValidSubscriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'hasValidSubscription',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      hasValidSubscriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'hasValidSubscription',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      hasValidSubscriptionEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hasValidSubscription',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      isActiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isActive',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      isActivePlanIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isActivePlan',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      isActivePlanIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isActivePlan',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      isActivePlanEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isActivePlan',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      isDeletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      isExpiredEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isExpired',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      isSubscriptionActiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSubscriptionActive',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      isTrialActiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isTrialActive',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      isTrialExpiredIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isTrialExpired',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      isTrialExpiredIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isTrialExpired',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      isTrialExpiredEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isTrialExpired',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      lastModifiedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastModifiedAt',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      lastModifiedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastModifiedAt',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      lastModifiedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastModifiedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      lastModifiedByIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastModifiedBy',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      lastModifiedByIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastModifiedBy',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      lastModifiedByContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastModifiedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      lastModifiedByMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastModifiedBy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      lastModifiedByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastModifiedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      lastModifiedByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastModifiedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      lastSyncAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSyncAt',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      lastSyncAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSyncAt',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      lastSyncAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSyncAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      localeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'locale',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      localeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'locale',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      localeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'locale',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      localeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'locale',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      localeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'locale',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      localeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'locale',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      localeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'locale',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      localeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'locale',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      localeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'locale',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      localeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'locale',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      logoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'logo',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      logoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'logo',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      logoEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'logo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      logoGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'logo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      logoLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'logo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      logoBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'logo',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      logoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'logo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      logoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'logo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      logoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'logo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      logoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'logo',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      logoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'logo',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      logoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'logo',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      needsSyncEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'needsSync',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      serverIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      serverIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'serverId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      settingsJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'settingsJson',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      settingsJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'settingsJson',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      settingsJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'settingsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      settingsJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'settingsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      settingsJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'settingsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      settingsJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'settingsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      settingsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'settingsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      settingsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'settingsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      settingsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'settingsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      settingsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'settingsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      settingsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'settingsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      settingsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'settingsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      slugEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'slug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      slugGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'slug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      slugLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'slug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      slugBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'slug',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      slugStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'slug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      slugEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'slug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      slugContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'slug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      slugMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'slug',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      slugIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'slug',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      slugIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'slug',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionEndDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'subscriptionEndDate',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionEndDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'subscriptionEndDate',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionEndDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subscriptionEndDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionEndDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subscriptionEndDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionEndDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subscriptionEndDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionEndDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subscriptionEndDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionPlanEqualTo(
    IsarSubscriptionPlan value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subscriptionPlan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionPlanGreaterThan(
    IsarSubscriptionPlan value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subscriptionPlan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionPlanLessThan(
    IsarSubscriptionPlan value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subscriptionPlan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionPlanBetween(
    IsarSubscriptionPlan lower,
    IsarSubscriptionPlan upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subscriptionPlan',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionPlanStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'subscriptionPlan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionPlanEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'subscriptionPlan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionPlanContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'subscriptionPlan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionPlanMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'subscriptionPlan',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionPlanIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subscriptionPlan',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionPlanIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'subscriptionPlan',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionStartDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'subscriptionStartDate',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionStartDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'subscriptionStartDate',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionStartDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subscriptionStartDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionStartDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subscriptionStartDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionStartDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subscriptionStartDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionStartDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subscriptionStartDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionStatusEqualTo(
    IsarSubscriptionStatus value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subscriptionStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionStatusGreaterThan(
    IsarSubscriptionStatus value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subscriptionStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionStatusLessThan(
    IsarSubscriptionStatus value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subscriptionStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionStatusBetween(
    IsarSubscriptionStatus lower,
    IsarSubscriptionStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subscriptionStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionStatusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'subscriptionStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionStatusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'subscriptionStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionStatusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'subscriptionStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionStatusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'subscriptionStatus',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionStatusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subscriptionStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      subscriptionStatusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'subscriptionStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      timezoneEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timezone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      timezoneGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timezone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      timezoneLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timezone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      timezoneBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timezone',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      timezoneStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'timezone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      timezoneEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'timezone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      timezoneContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'timezone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      timezoneMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'timezone',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      timezoneIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timezone',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      timezoneIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'timezone',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      trialEndDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'trialEndDate',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      trialEndDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'trialEndDate',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      trialEndDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'trialEndDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      trialEndDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'trialEndDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      trialEndDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'trialEndDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      trialEndDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'trialEndDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      trialStartDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'trialStartDate',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      trialStartDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'trialStartDate',
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      trialStartDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'trialStartDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      trialStartDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'trialStartDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      trialStartDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'trialStartDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      trialStartDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'trialStartDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
      versionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterFilterCondition>
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

extension IsarOrganizationQueryObject
    on QueryBuilder<IsarOrganization, IsarOrganization, QFilterCondition> {}

extension IsarOrganizationQueryLinks
    on QueryBuilder<IsarOrganization, IsarOrganization, QFilterCondition> {}

extension IsarOrganizationQuerySortBy
    on QueryBuilder<IsarOrganization, IsarOrganization, QSortBy> {
  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByDaysUntilExpiration() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysUntilExpiration', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByDaysUntilExpirationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysUntilExpiration', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByDaysUntilExpirationCached() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysUntilExpirationCached', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByDaysUntilExpirationCachedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysUntilExpirationCached', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByDefaultProfitMarginPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultProfitMarginPercentage', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByDefaultProfitMarginPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultProfitMarginPercentage', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByDomain() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'domain', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByDomainDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'domain', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByHasValidSubscription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasValidSubscription', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByHasValidSubscriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasValidSubscription', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByIsActivePlan() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActivePlan', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByIsActivePlanDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActivePlan', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByIsExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByIsExpiredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByIsSubscriptionActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSubscriptionActive', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByIsSubscriptionActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSubscriptionActive', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByIsTrialActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTrialActive', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByIsTrialActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTrialActive', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByIsTrialExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTrialExpired', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByIsTrialExpiredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTrialExpired', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByLastModifiedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByLastModifiedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByLastModifiedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedBy', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByLastModifiedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedBy', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByLastSyncAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByLocale() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locale', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByLocaleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locale', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy> sortByLogo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logo', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByLogoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logo', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByNeedsSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortBySettingsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'settingsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortBySettingsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'settingsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy> sortBySlug() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slug', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortBySlugDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slug', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortBySubscriptionEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionEndDate', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortBySubscriptionEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionEndDate', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortBySubscriptionPlan() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionPlan', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortBySubscriptionPlanDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionPlan', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortBySubscriptionStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionStartDate', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortBySubscriptionStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionStartDate', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortBySubscriptionStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionStatus', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortBySubscriptionStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionStatus', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByTimezone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timezone', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByTimezoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timezone', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByTrialEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trialEndDate', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByTrialEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trialEndDate', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByTrialStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trialStartDate', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByTrialStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trialStartDate', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      sortByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension IsarOrganizationQuerySortThenBy
    on QueryBuilder<IsarOrganization, IsarOrganization, QSortThenBy> {
  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByDaysUntilExpiration() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysUntilExpiration', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByDaysUntilExpirationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysUntilExpiration', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByDaysUntilExpirationCached() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysUntilExpirationCached', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByDaysUntilExpirationCachedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysUntilExpirationCached', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByDefaultProfitMarginPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultProfitMarginPercentage', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByDefaultProfitMarginPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultProfitMarginPercentage', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByDomain() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'domain', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByDomainDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'domain', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByHasValidSubscription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasValidSubscription', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByHasValidSubscriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasValidSubscription', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByIsActivePlan() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActivePlan', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByIsActivePlanDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActivePlan', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByIsExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByIsExpiredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByIsSubscriptionActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSubscriptionActive', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByIsSubscriptionActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSubscriptionActive', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByIsTrialActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTrialActive', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByIsTrialActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTrialActive', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByIsTrialExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTrialExpired', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByIsTrialExpiredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTrialExpired', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByLastModifiedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByLastModifiedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByLastModifiedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedBy', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByLastModifiedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedBy', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByLastSyncAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByLocale() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locale', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByLocaleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locale', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy> thenByLogo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logo', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByLogoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logo', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByNeedsSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenBySettingsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'settingsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenBySettingsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'settingsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy> thenBySlug() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slug', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenBySlugDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slug', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenBySubscriptionEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionEndDate', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenBySubscriptionEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionEndDate', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenBySubscriptionPlan() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionPlan', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenBySubscriptionPlanDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionPlan', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenBySubscriptionStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionStartDate', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenBySubscriptionStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionStartDate', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenBySubscriptionStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionStatus', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenBySubscriptionStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionStatus', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByTimezone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timezone', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByTimezoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timezone', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByTrialEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trialEndDate', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByTrialEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trialEndDate', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByTrialStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trialStartDate', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByTrialStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trialStartDate', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QAfterSortBy>
      thenByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension IsarOrganizationQueryWhereDistinct
    on QueryBuilder<IsarOrganization, IsarOrganization, QDistinct> {
  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctByCurrency({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currency', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctByDaysUntilExpiration() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'daysUntilExpiration');
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctByDaysUntilExpirationCached() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'daysUntilExpirationCached');
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctByDefaultProfitMarginPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'defaultProfitMarginPercentage');
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedAt');
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct> distinctByDomain(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'domain', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctByHasValidSubscription() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasValidSubscription');
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActive');
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctByIsActivePlan() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActivePlan');
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctByIsExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isExpired');
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctByIsSubscriptionActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSubscriptionActive');
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctByIsTrialActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isTrialActive');
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctByIsTrialExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isTrialExpired');
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctByLastModifiedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastModifiedAt');
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctByLastModifiedBy({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastModifiedBy',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncAt');
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct> distinctByLocale(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'locale', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct> distinctByLogo(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'logo', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'needsSync');
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctByServerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctBySettingsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'settingsJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct> distinctBySlug(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'slug', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctBySubscriptionEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subscriptionEndDate');
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctBySubscriptionPlan({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subscriptionPlan',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctBySubscriptionStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subscriptionStartDate');
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctBySubscriptionStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subscriptionStatus',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctByTimezone({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timezone', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctByTrialEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'trialEndDate');
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctByTrialStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'trialStartDate');
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<IsarOrganization, IsarOrganization, QDistinct>
      distinctByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'version');
    });
  }
}

extension IsarOrganizationQueryProperty
    on QueryBuilder<IsarOrganization, IsarOrganization, QQueryProperty> {
  QueryBuilder<IsarOrganization, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarOrganization, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<IsarOrganization, String, QQueryOperations> currencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currency');
    });
  }

  QueryBuilder<IsarOrganization, int?, QQueryOperations>
      daysUntilExpirationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'daysUntilExpiration');
    });
  }

  QueryBuilder<IsarOrganization, int?, QQueryOperations>
      daysUntilExpirationCachedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'daysUntilExpirationCached');
    });
  }

  QueryBuilder<IsarOrganization, double?, QQueryOperations>
      defaultProfitMarginPercentageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'defaultProfitMarginPercentage');
    });
  }

  QueryBuilder<IsarOrganization, DateTime?, QQueryOperations>
      deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedAt');
    });
  }

  QueryBuilder<IsarOrganization, String?, QQueryOperations> domainProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'domain');
    });
  }

  QueryBuilder<IsarOrganization, bool?, QQueryOperations>
      hasValidSubscriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasValidSubscription');
    });
  }

  QueryBuilder<IsarOrganization, bool, QQueryOperations> isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActive');
    });
  }

  QueryBuilder<IsarOrganization, bool?, QQueryOperations>
      isActivePlanProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActivePlan');
    });
  }

  QueryBuilder<IsarOrganization, bool, QQueryOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<IsarOrganization, bool, QQueryOperations> isExpiredProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isExpired');
    });
  }

  QueryBuilder<IsarOrganization, bool, QQueryOperations>
      isSubscriptionActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSubscriptionActive');
    });
  }

  QueryBuilder<IsarOrganization, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<IsarOrganization, bool, QQueryOperations>
      isTrialActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isTrialActive');
    });
  }

  QueryBuilder<IsarOrganization, bool?, QQueryOperations>
      isTrialExpiredProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isTrialExpired');
    });
  }

  QueryBuilder<IsarOrganization, DateTime?, QQueryOperations>
      lastModifiedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastModifiedAt');
    });
  }

  QueryBuilder<IsarOrganization, String?, QQueryOperations>
      lastModifiedByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastModifiedBy');
    });
  }

  QueryBuilder<IsarOrganization, DateTime?, QQueryOperations>
      lastSyncAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncAt');
    });
  }

  QueryBuilder<IsarOrganization, String, QQueryOperations> localeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'locale');
    });
  }

  QueryBuilder<IsarOrganization, String?, QQueryOperations> logoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'logo');
    });
  }

  QueryBuilder<IsarOrganization, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<IsarOrganization, bool, QQueryOperations> needsSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'needsSync');
    });
  }

  QueryBuilder<IsarOrganization, String, QQueryOperations> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<IsarOrganization, String?, QQueryOperations>
      settingsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'settingsJson');
    });
  }

  QueryBuilder<IsarOrganization, String, QQueryOperations> slugProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'slug');
    });
  }

  QueryBuilder<IsarOrganization, DateTime?, QQueryOperations>
      subscriptionEndDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subscriptionEndDate');
    });
  }

  QueryBuilder<IsarOrganization, IsarSubscriptionPlan, QQueryOperations>
      subscriptionPlanProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subscriptionPlan');
    });
  }

  QueryBuilder<IsarOrganization, DateTime?, QQueryOperations>
      subscriptionStartDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subscriptionStartDate');
    });
  }

  QueryBuilder<IsarOrganization, IsarSubscriptionStatus, QQueryOperations>
      subscriptionStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subscriptionStatus');
    });
  }

  QueryBuilder<IsarOrganization, String, QQueryOperations> timezoneProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timezone');
    });
  }

  QueryBuilder<IsarOrganization, DateTime?, QQueryOperations>
      trialEndDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'trialEndDate');
    });
  }

  QueryBuilder<IsarOrganization, DateTime?, QQueryOperations>
      trialStartDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'trialStartDate');
    });
  }

  QueryBuilder<IsarOrganization, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<IsarOrganization, int, QQueryOperations> versionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'version');
    });
  }
}
