// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_notification.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarNotificationCollection on Isar {
  IsarCollection<IsarNotification> get isarNotifications => this.collection();
}

const IsarNotificationSchema = CollectionSchema(
  name: r'IsarNotification',
  id: -5669466738626994633,
  properties: {
    r'actionDataJson': PropertySchema(
      id: 0,
      name: r'actionDataJson',
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
    r'formattedTime': PropertySchema(
      id: 3,
      name: r'formattedTime',
      type: IsarType.string,
    ),
    r'hasActionData': PropertySchema(
      id: 4,
      name: r'hasActionData',
      type: IsarType.bool,
    ),
    r'hasRelatedEntity': PropertySchema(
      id: 5,
      name: r'hasRelatedEntity',
      type: IsarType.bool,
    ),
    r'hashCode': PropertySchema(
      id: 6,
      name: r'hashCode',
      type: IsarType.long,
    ),
    r'isDeleted': PropertySchema(
      id: 7,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'isHighPriority': PropertySchema(
      id: 8,
      name: r'isHighPriority',
      type: IsarType.bool,
    ),
    r'isRead': PropertySchema(
      id: 9,
      name: r'isRead',
      type: IsarType.bool,
    ),
    r'isRecent': PropertySchema(
      id: 10,
      name: r'isRecent',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 11,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'isThisWeek': PropertySchema(
      id: 12,
      name: r'isThisWeek',
      type: IsarType.bool,
    ),
    r'isToday': PropertySchema(
      id: 13,
      name: r'isToday',
      type: IsarType.bool,
    ),
    r'isUnread': PropertySchema(
      id: 14,
      name: r'isUnread',
      type: IsarType.bool,
    ),
    r'isUrgent': PropertySchema(
      id: 15,
      name: r'isUrgent',
      type: IsarType.bool,
    ),
    r'lastSyncAt': PropertySchema(
      id: 16,
      name: r'lastSyncAt',
      type: IsarType.dateTime,
    ),
    r'message': PropertySchema(
      id: 17,
      name: r'message',
      type: IsarType.string,
    ),
    r'needsSync': PropertySchema(
      id: 18,
      name: r'needsSync',
      type: IsarType.bool,
    ),
    r'priority': PropertySchema(
      id: 19,
      name: r'priority',
      type: IsarType.string,
      enumMap: _IsarNotificationpriorityEnumValueMap,
    ),
    r'priorityDisplayName': PropertySchema(
      id: 20,
      name: r'priorityDisplayName',
      type: IsarType.string,
    ),
    r'relatedId': PropertySchema(
      id: 21,
      name: r'relatedId',
      type: IsarType.string,
    ),
    r'serverId': PropertySchema(
      id: 22,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'timeAgo': PropertySchema(
      id: 23,
      name: r'timeAgo',
      type: IsarType.string,
    ),
    r'timestamp': PropertySchema(
      id: 24,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
    r'title': PropertySchema(
      id: 25,
      name: r'title',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 26,
      name: r'type',
      type: IsarType.string,
      enumMap: _IsarNotificationtypeEnumValueMap,
    ),
    r'typeDisplayName': PropertySchema(
      id: 27,
      name: r'typeDisplayName',
      type: IsarType.string,
    ),
    r'typeIconName': PropertySchema(
      id: 28,
      name: r'typeIconName',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 29,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _isarNotificationEstimateSize,
  serialize: _isarNotificationSerialize,
  deserialize: _isarNotificationDeserialize,
  deserializeProp: _isarNotificationDeserializeProp,
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
    r'title': IndexSchema(
      id: -7636685945352118059,
      name: r'title',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'title',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'timestamp': IndexSchema(
      id: 1852253767416892198,
      name: r'timestamp',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'timestamp',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'isRead': IndexSchema(
      id: -944277114070112791,
      name: r'isRead',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isRead',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'relatedId': IndexSchema(
      id: 6518603770726519018,
      name: r'relatedId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'relatedId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarNotificationGetId,
  getLinks: _isarNotificationGetLinks,
  attach: _isarNotificationAttach,
  version: '3.1.0+1',
);

int _isarNotificationEstimateSize(
  IsarNotification object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.actionDataJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.formattedTime.length * 3;
  bytesCount += 3 + object.message.length * 3;
  bytesCount += 3 + object.priority.name.length * 3;
  bytesCount += 3 + object.priorityDisplayName.length * 3;
  {
    final value = object.relatedId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.serverId.length * 3;
  bytesCount += 3 + object.timeAgo.length * 3;
  bytesCount += 3 + object.title.length * 3;
  bytesCount += 3 + object.type.name.length * 3;
  bytesCount += 3 + object.typeDisplayName.length * 3;
  bytesCount += 3 + object.typeIconName.length * 3;
  return bytesCount;
}

void _isarNotificationSerialize(
  IsarNotification object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.actionDataJson);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeDateTime(offsets[2], object.deletedAt);
  writer.writeString(offsets[3], object.formattedTime);
  writer.writeBool(offsets[4], object.hasActionData);
  writer.writeBool(offsets[5], object.hasRelatedEntity);
  writer.writeLong(offsets[6], object.hashCode);
  writer.writeBool(offsets[7], object.isDeleted);
  writer.writeBool(offsets[8], object.isHighPriority);
  writer.writeBool(offsets[9], object.isRead);
  writer.writeBool(offsets[10], object.isRecent);
  writer.writeBool(offsets[11], object.isSynced);
  writer.writeBool(offsets[12], object.isThisWeek);
  writer.writeBool(offsets[13], object.isToday);
  writer.writeBool(offsets[14], object.isUnread);
  writer.writeBool(offsets[15], object.isUrgent);
  writer.writeDateTime(offsets[16], object.lastSyncAt);
  writer.writeString(offsets[17], object.message);
  writer.writeBool(offsets[18], object.needsSync);
  writer.writeString(offsets[19], object.priority.name);
  writer.writeString(offsets[20], object.priorityDisplayName);
  writer.writeString(offsets[21], object.relatedId);
  writer.writeString(offsets[22], object.serverId);
  writer.writeString(offsets[23], object.timeAgo);
  writer.writeDateTime(offsets[24], object.timestamp);
  writer.writeString(offsets[25], object.title);
  writer.writeString(offsets[26], object.type.name);
  writer.writeString(offsets[27], object.typeDisplayName);
  writer.writeString(offsets[28], object.typeIconName);
  writer.writeDateTime(offsets[29], object.updatedAt);
}

IsarNotification _isarNotificationDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarNotification();
  object.actionDataJson = reader.readStringOrNull(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.deletedAt = reader.readDateTimeOrNull(offsets[2]);
  object.id = id;
  object.isRead = reader.readBool(offsets[9]);
  object.isSynced = reader.readBool(offsets[11]);
  object.lastSyncAt = reader.readDateTimeOrNull(offsets[16]);
  object.message = reader.readString(offsets[17]);
  object.priority = _IsarNotificationpriorityValueEnumMap[
          reader.readStringOrNull(offsets[19])] ??
      IsarNotificationPriority.low;
  object.relatedId = reader.readStringOrNull(offsets[21]);
  object.serverId = reader.readString(offsets[22]);
  object.timestamp = reader.readDateTime(offsets[24]);
  object.title = reader.readString(offsets[25]);
  object.type =
      _IsarNotificationtypeValueEnumMap[reader.readStringOrNull(offsets[26])] ??
          IsarNotificationType.system;
  object.updatedAt = reader.readDateTime(offsets[29]);
  return object;
}

P _isarNotificationDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
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
      return (reader.readLong(offset)) as P;
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
      return (reader.readBool(offset)) as P;
    case 13:
      return (reader.readBool(offset)) as P;
    case 14:
      return (reader.readBool(offset)) as P;
    case 15:
      return (reader.readBool(offset)) as P;
    case 16:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 17:
      return (reader.readString(offset)) as P;
    case 18:
      return (reader.readBool(offset)) as P;
    case 19:
      return (_IsarNotificationpriorityValueEnumMap[
              reader.readStringOrNull(offset)] ??
          IsarNotificationPriority.low) as P;
    case 20:
      return (reader.readString(offset)) as P;
    case 21:
      return (reader.readStringOrNull(offset)) as P;
    case 22:
      return (reader.readString(offset)) as P;
    case 23:
      return (reader.readString(offset)) as P;
    case 24:
      return (reader.readDateTime(offset)) as P;
    case 25:
      return (reader.readString(offset)) as P;
    case 26:
      return (_IsarNotificationtypeValueEnumMap[
              reader.readStringOrNull(offset)] ??
          IsarNotificationType.system) as P;
    case 27:
      return (reader.readString(offset)) as P;
    case 28:
      return (reader.readString(offset)) as P;
    case 29:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _IsarNotificationpriorityEnumValueMap = {
  r'low': r'low',
  r'medium': r'medium',
  r'high': r'high',
  r'urgent': r'urgent',
};
const _IsarNotificationpriorityValueEnumMap = {
  r'low': IsarNotificationPriority.low,
  r'medium': IsarNotificationPriority.medium,
  r'high': IsarNotificationPriority.high,
  r'urgent': IsarNotificationPriority.urgent,
};
const _IsarNotificationtypeEnumValueMap = {
  r'system': r'system',
  r'payment': r'payment',
  r'invoice': r'invoice',
  r'lowStock': r'lowStock',
  r'expense': r'expense',
  r'sale': r'sale',
  r'user': r'user',
  r'reminder': r'reminder',
};
const _IsarNotificationtypeValueEnumMap = {
  r'system': IsarNotificationType.system,
  r'payment': IsarNotificationType.payment,
  r'invoice': IsarNotificationType.invoice,
  r'lowStock': IsarNotificationType.lowStock,
  r'expense': IsarNotificationType.expense,
  r'sale': IsarNotificationType.sale,
  r'user': IsarNotificationType.user,
  r'reminder': IsarNotificationType.reminder,
};

Id _isarNotificationGetId(IsarNotification object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarNotificationGetLinks(IsarNotification object) {
  return [];
}

void _isarNotificationAttach(
    IsarCollection<dynamic> col, Id id, IsarNotification object) {
  object.id = id;
}

extension IsarNotificationByIndex on IsarCollection<IsarNotification> {
  Future<IsarNotification?> getByServerId(String serverId) {
    return getByIndex(r'serverId', [serverId]);
  }

  IsarNotification? getByServerIdSync(String serverId) {
    return getByIndexSync(r'serverId', [serverId]);
  }

  Future<bool> deleteByServerId(String serverId) {
    return deleteByIndex(r'serverId', [serverId]);
  }

  bool deleteByServerIdSync(String serverId) {
    return deleteByIndexSync(r'serverId', [serverId]);
  }

  Future<List<IsarNotification?>> getAllByServerId(
      List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'serverId', values);
  }

  List<IsarNotification?> getAllByServerIdSync(List<String> serverIdValues) {
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

  Future<Id> putByServerId(IsarNotification object) {
    return putByIndex(r'serverId', object);
  }

  Id putByServerIdSync(IsarNotification object, {bool saveLinks = true}) {
    return putByIndexSync(r'serverId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByServerId(List<IsarNotification> objects) {
    return putAllByIndex(r'serverId', objects);
  }

  List<Id> putAllByServerIdSync(List<IsarNotification> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'serverId', objects, saveLinks: saveLinks);
  }
}

extension IsarNotificationQueryWhereSort
    on QueryBuilder<IsarNotification, IsarNotification, QWhere> {
  QueryBuilder<IsarNotification, IsarNotification, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterWhere> anyTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'timestamp'),
      );
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterWhere> anyIsRead() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isRead'),
      );
    });
  }
}

extension IsarNotificationQueryWhere
    on QueryBuilder<IsarNotification, IsarNotification, QWhereClause> {
  QueryBuilder<IsarNotification, IsarNotification, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterWhereClause>
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterWhereClause>
      serverIdEqualTo(String serverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'serverId',
        value: [serverId],
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterWhereClause>
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterWhereClause>
      titleEqualTo(String title) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'title',
        value: [title],
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterWhereClause>
      titleNotEqualTo(String title) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [],
              upper: [title],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [title],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [title],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [],
              upper: [title],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterWhereClause>
      timestampEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'timestamp',
        value: [timestamp],
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterWhereClause>
      timestampNotEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterWhereClause>
      timestampGreaterThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [timestamp],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterWhereClause>
      timestampLessThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [],
        upper: [timestamp],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterWhereClause>
      timestampBetween(
    DateTime lowerTimestamp,
    DateTime upperTimestamp, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [lowerTimestamp],
        includeLower: includeLower,
        upper: [upperTimestamp],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterWhereClause>
      isReadEqualTo(bool isRead) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isRead',
        value: [isRead],
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterWhereClause>
      isReadNotEqualTo(bool isRead) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isRead',
              lower: [],
              upper: [isRead],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isRead',
              lower: [isRead],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isRead',
              lower: [isRead],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isRead',
              lower: [],
              upper: [isRead],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterWhereClause>
      relatedIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'relatedId',
        value: [null],
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterWhereClause>
      relatedIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'relatedId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterWhereClause>
      relatedIdEqualTo(String? relatedId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'relatedId',
        value: [relatedId],
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterWhereClause>
      relatedIdNotEqualTo(String? relatedId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'relatedId',
              lower: [],
              upper: [relatedId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'relatedId',
              lower: [relatedId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'relatedId',
              lower: [relatedId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'relatedId',
              lower: [],
              upper: [relatedId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarNotificationQueryFilter
    on QueryBuilder<IsarNotification, IsarNotification, QFilterCondition> {
  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      actionDataJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'actionDataJson',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      actionDataJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'actionDataJson',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      actionDataJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'actionDataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      actionDataJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'actionDataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      actionDataJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'actionDataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      actionDataJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'actionDataJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      actionDataJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'actionDataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      actionDataJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'actionDataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      actionDataJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'actionDataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      actionDataJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'actionDataJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      actionDataJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'actionDataJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      actionDataJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'actionDataJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      deletedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      deletedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      formattedTimeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'formattedTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      formattedTimeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'formattedTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      formattedTimeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'formattedTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      formattedTimeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'formattedTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      formattedTimeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'formattedTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      formattedTimeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'formattedTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      formattedTimeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'formattedTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      formattedTimeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'formattedTime',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      formattedTimeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'formattedTime',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      formattedTimeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'formattedTime',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      hasActionDataEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hasActionData',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      hasRelatedEntityEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hasRelatedEntity',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      hashCodeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      hashCodeGreaterThan(
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      hashCodeLessThan(
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      hashCodeBetween(
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      isDeletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      isHighPriorityEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isHighPriority',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      isReadEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isRead',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      isRecentEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isRecent',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      isThisWeekEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isThisWeek',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      isTodayEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isToday',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      isUnreadEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isUnread',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      isUrgentEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isUrgent',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      lastSyncAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSyncAt',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      lastSyncAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSyncAt',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      lastSyncAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSyncAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      messageEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      messageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      messageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      messageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'message',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      messageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      messageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      messageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      messageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'message',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      messageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'message',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      messageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'message',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      needsSyncEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'needsSync',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      priorityEqualTo(
    IsarNotificationPriority value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'priority',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      priorityGreaterThan(
    IsarNotificationPriority value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'priority',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      priorityLessThan(
    IsarNotificationPriority value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'priority',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      priorityBetween(
    IsarNotificationPriority lower,
    IsarNotificationPriority upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'priority',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      priorityStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'priority',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      priorityEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'priority',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      priorityContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'priority',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      priorityMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'priority',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      priorityIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'priority',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      priorityIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'priority',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      priorityDisplayNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'priorityDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      priorityDisplayNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'priorityDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      priorityDisplayNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'priorityDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      priorityDisplayNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'priorityDisplayName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      priorityDisplayNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'priorityDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      priorityDisplayNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'priorityDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      priorityDisplayNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'priorityDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      priorityDisplayNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'priorityDisplayName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      priorityDisplayNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'priorityDisplayName',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      priorityDisplayNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'priorityDisplayName',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      relatedIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'relatedId',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      relatedIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'relatedId',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      relatedIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'relatedId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      relatedIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'relatedId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      relatedIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'relatedId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      relatedIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'relatedId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      relatedIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'relatedId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      relatedIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'relatedId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      relatedIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'relatedId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      relatedIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'relatedId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      relatedIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'relatedId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      relatedIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'relatedId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      serverIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      serverIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'serverId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      timeAgoEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timeAgo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      timeAgoGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timeAgo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      timeAgoLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timeAgo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      timeAgoBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timeAgo',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      timeAgoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'timeAgo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      timeAgoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'timeAgo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      timeAgoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'timeAgo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      timeAgoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'timeAgo',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      timeAgoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timeAgo',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      timeAgoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'timeAgo',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      typeEqualTo(
    IsarNotificationType value, {
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      typeGreaterThan(
    IsarNotificationType value, {
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      typeLessThan(
    IsarNotificationType value, {
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      typeBetween(
    IsarNotificationType lower,
    IsarNotificationType upper, {
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      typeDisplayNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'typeDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      typeDisplayNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'typeDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      typeDisplayNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'typeDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      typeDisplayNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'typeDisplayName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      typeDisplayNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'typeDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      typeDisplayNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'typeDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      typeDisplayNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'typeDisplayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      typeDisplayNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'typeDisplayName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      typeDisplayNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'typeDisplayName',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      typeDisplayNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'typeDisplayName',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      typeIconNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'typeIconName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      typeIconNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'typeIconName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      typeIconNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'typeIconName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      typeIconNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'typeIconName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      typeIconNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'typeIconName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      typeIconNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'typeIconName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      typeIconNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'typeIconName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      typeIconNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'typeIconName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      typeIconNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'typeIconName',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      typeIconNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'typeIconName',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
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

  QueryBuilder<IsarNotification, IsarNotification, QAfterFilterCondition>
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
}

extension IsarNotificationQueryObject
    on QueryBuilder<IsarNotification, IsarNotification, QFilterCondition> {}

extension IsarNotificationQueryLinks
    on QueryBuilder<IsarNotification, IsarNotification, QFilterCondition> {}

extension IsarNotificationQuerySortBy
    on QueryBuilder<IsarNotification, IsarNotification, QSortBy> {
  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByActionDataJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionDataJson', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByActionDataJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionDataJson', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByFormattedTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedTime', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByFormattedTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedTime', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByHasActionData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasActionData', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByHasActionDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasActionData', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByHasRelatedEntity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasRelatedEntity', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByHasRelatedEntityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasRelatedEntity', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByHashCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByIsHighPriority() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHighPriority', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByIsHighPriorityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHighPriority', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByIsRead() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRead', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByIsReadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRead', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByIsRecent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRecent', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByIsRecentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRecent', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByIsThisWeek() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isThisWeek', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByIsThisWeekDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isThisWeek', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByIsToday() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isToday', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByIsTodayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isToday', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByIsUnread() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUnread', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByIsUnreadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUnread', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByIsUrgent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUrgent', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByIsUrgentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUrgent', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByLastSyncAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByNeedsSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByPriority() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByPriorityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByPriorityDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priorityDisplayName', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByPriorityDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priorityDisplayName', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByRelatedId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relatedId', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByRelatedIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relatedId', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByTimeAgo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeAgo', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByTimeAgoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeAgo', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByTypeDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeDisplayName', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByTypeDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeDisplayName', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByTypeIconName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeIconName', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByTypeIconNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeIconName', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension IsarNotificationQuerySortThenBy
    on QueryBuilder<IsarNotification, IsarNotification, QSortThenBy> {
  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByActionDataJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionDataJson', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByActionDataJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionDataJson', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByFormattedTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedTime', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByFormattedTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedTime', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByHasActionData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasActionData', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByHasActionDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasActionData', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByHasRelatedEntity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasRelatedEntity', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByHasRelatedEntityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasRelatedEntity', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByHashCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByIsHighPriority() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHighPriority', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByIsHighPriorityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHighPriority', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByIsRead() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRead', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByIsReadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRead', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByIsRecent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRecent', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByIsRecentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRecent', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByIsThisWeek() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isThisWeek', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByIsThisWeekDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isThisWeek', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByIsToday() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isToday', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByIsTodayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isToday', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByIsUnread() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUnread', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByIsUnreadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUnread', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByIsUrgent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUrgent', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByIsUrgentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUrgent', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByLastSyncAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByNeedsSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByPriority() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByPriorityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByPriorityDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priorityDisplayName', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByPriorityDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priorityDisplayName', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByRelatedId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relatedId', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByRelatedIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relatedId', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByTimeAgo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeAgo', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByTimeAgoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeAgo', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByTypeDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeDisplayName', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByTypeDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeDisplayName', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByTypeIconName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeIconName', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByTypeIconNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeIconName', Sort.desc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension IsarNotificationQueryWhereDistinct
    on QueryBuilder<IsarNotification, IsarNotification, QDistinct> {
  QueryBuilder<IsarNotification, IsarNotification, QDistinct>
      distinctByActionDataJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'actionDataJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QDistinct>
      distinctByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedAt');
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QDistinct>
      distinctByFormattedTime({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'formattedTime',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QDistinct>
      distinctByHasActionData() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasActionData');
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QDistinct>
      distinctByHasRelatedEntity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasRelatedEntity');
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QDistinct>
      distinctByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hashCode');
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QDistinct>
      distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QDistinct>
      distinctByIsHighPriority() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isHighPriority');
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QDistinct>
      distinctByIsRead() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isRead');
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QDistinct>
      distinctByIsRecent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isRecent');
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QDistinct>
      distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QDistinct>
      distinctByIsThisWeek() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isThisWeek');
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QDistinct>
      distinctByIsToday() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isToday');
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QDistinct>
      distinctByIsUnread() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isUnread');
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QDistinct>
      distinctByIsUrgent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isUrgent');
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QDistinct>
      distinctByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncAt');
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QDistinct> distinctByMessage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'message', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QDistinct>
      distinctByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'needsSync');
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QDistinct>
      distinctByPriority({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'priority', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QDistinct>
      distinctByPriorityDisplayName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'priorityDisplayName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QDistinct>
      distinctByRelatedId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'relatedId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QDistinct>
      distinctByServerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QDistinct> distinctByTimeAgo(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timeAgo', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QDistinct>
      distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QDistinct> distinctByType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QDistinct>
      distinctByTypeDisplayName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'typeDisplayName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QDistinct>
      distinctByTypeIconName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'typeIconName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarNotification, IsarNotification, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension IsarNotificationQueryProperty
    on QueryBuilder<IsarNotification, IsarNotification, QQueryProperty> {
  QueryBuilder<IsarNotification, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarNotification, String?, QQueryOperations>
      actionDataJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'actionDataJson');
    });
  }

  QueryBuilder<IsarNotification, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<IsarNotification, DateTime?, QQueryOperations>
      deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedAt');
    });
  }

  QueryBuilder<IsarNotification, String, QQueryOperations>
      formattedTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'formattedTime');
    });
  }

  QueryBuilder<IsarNotification, bool, QQueryOperations>
      hasActionDataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasActionData');
    });
  }

  QueryBuilder<IsarNotification, bool, QQueryOperations>
      hasRelatedEntityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasRelatedEntity');
    });
  }

  QueryBuilder<IsarNotification, int, QQueryOperations> hashCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hashCode');
    });
  }

  QueryBuilder<IsarNotification, bool, QQueryOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<IsarNotification, bool, QQueryOperations>
      isHighPriorityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isHighPriority');
    });
  }

  QueryBuilder<IsarNotification, bool, QQueryOperations> isReadProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isRead');
    });
  }

  QueryBuilder<IsarNotification, bool, QQueryOperations> isRecentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isRecent');
    });
  }

  QueryBuilder<IsarNotification, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<IsarNotification, bool, QQueryOperations> isThisWeekProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isThisWeek');
    });
  }

  QueryBuilder<IsarNotification, bool, QQueryOperations> isTodayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isToday');
    });
  }

  QueryBuilder<IsarNotification, bool, QQueryOperations> isUnreadProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isUnread');
    });
  }

  QueryBuilder<IsarNotification, bool, QQueryOperations> isUrgentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isUrgent');
    });
  }

  QueryBuilder<IsarNotification, DateTime?, QQueryOperations>
      lastSyncAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncAt');
    });
  }

  QueryBuilder<IsarNotification, String, QQueryOperations> messageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'message');
    });
  }

  QueryBuilder<IsarNotification, bool, QQueryOperations> needsSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'needsSync');
    });
  }

  QueryBuilder<IsarNotification, IsarNotificationPriority, QQueryOperations>
      priorityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'priority');
    });
  }

  QueryBuilder<IsarNotification, String, QQueryOperations>
      priorityDisplayNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'priorityDisplayName');
    });
  }

  QueryBuilder<IsarNotification, String?, QQueryOperations>
      relatedIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'relatedId');
    });
  }

  QueryBuilder<IsarNotification, String, QQueryOperations> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<IsarNotification, String, QQueryOperations> timeAgoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timeAgo');
    });
  }

  QueryBuilder<IsarNotification, DateTime, QQueryOperations>
      timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }

  QueryBuilder<IsarNotification, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<IsarNotification, IsarNotificationType, QQueryOperations>
      typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<IsarNotification, String, QQueryOperations>
      typeDisplayNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'typeDisplayName');
    });
  }

  QueryBuilder<IsarNotification, String, QQueryOperations>
      typeIconNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'typeIconName');
    });
  }

  QueryBuilder<IsarNotification, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
