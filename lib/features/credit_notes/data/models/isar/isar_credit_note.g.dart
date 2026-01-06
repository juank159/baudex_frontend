// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_credit_note.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarCreditNoteCollection on Isar {
  IsarCollection<IsarCreditNote> get isarCreditNotes => this.collection();
}

const IsarCreditNoteSchema = CollectionSchema(
  name: r'IsarCreditNote',
  id: 9074850303045278172,
  properties: {
    r'appliedAt': PropertySchema(
      id: 0,
      name: r'appliedAt',
      type: IsarType.dateTime,
    ),
    r'appliedById': PropertySchema(
      id: 1,
      name: r'appliedById',
      type: IsarType.string,
    ),
    r'canBeEdited': PropertySchema(
      id: 2,
      name: r'canBeEdited',
      type: IsarType.bool,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'createdById': PropertySchema(
      id: 4,
      name: r'createdById',
      type: IsarType.string,
    ),
    r'customerId': PropertySchema(
      id: 5,
      name: r'customerId',
      type: IsarType.string,
    ),
    r'date': PropertySchema(
      id: 6,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'deletedAt': PropertySchema(
      id: 7,
      name: r'deletedAt',
      type: IsarType.dateTime,
    ),
    r'inventoryRestored': PropertySchema(
      id: 8,
      name: r'inventoryRestored',
      type: IsarType.bool,
    ),
    r'inventoryRestoredAt': PropertySchema(
      id: 9,
      name: r'inventoryRestoredAt',
      type: IsarType.dateTime,
    ),
    r'invoiceId': PropertySchema(
      id: 10,
      name: r'invoiceId',
      type: IsarType.string,
    ),
    r'isCancelled': PropertySchema(
      id: 11,
      name: r'isCancelled',
      type: IsarType.bool,
    ),
    r'isConfirmed': PropertySchema(
      id: 12,
      name: r'isConfirmed',
      type: IsarType.bool,
    ),
    r'isDeleted': PropertySchema(
      id: 13,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'isDraft': PropertySchema(
      id: 14,
      name: r'isDraft',
      type: IsarType.bool,
    ),
    r'isFullCredit': PropertySchema(
      id: 15,
      name: r'isFullCredit',
      type: IsarType.bool,
    ),
    r'isPartialCredit': PropertySchema(
      id: 16,
      name: r'isPartialCredit',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 17,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'itemsJson': PropertySchema(
      id: 18,
      name: r'itemsJson',
      type: IsarType.string,
    ),
    r'lastModifiedAt': PropertySchema(
      id: 19,
      name: r'lastModifiedAt',
      type: IsarType.dateTime,
    ),
    r'lastModifiedBy': PropertySchema(
      id: 20,
      name: r'lastModifiedBy',
      type: IsarType.string,
    ),
    r'lastSyncAt': PropertySchema(
      id: 21,
      name: r'lastSyncAt',
      type: IsarType.dateTime,
    ),
    r'metadataJson': PropertySchema(
      id: 22,
      name: r'metadataJson',
      type: IsarType.string,
    ),
    r'needsSync': PropertySchema(
      id: 23,
      name: r'needsSync',
      type: IsarType.bool,
    ),
    r'notes': PropertySchema(
      id: 24,
      name: r'notes',
      type: IsarType.string,
    ),
    r'number': PropertySchema(
      id: 25,
      name: r'number',
      type: IsarType.string,
    ),
    r'reason': PropertySchema(
      id: 26,
      name: r'reason',
      type: IsarType.string,
      enumMap: _IsarCreditNotereasonEnumValueMap,
    ),
    r'reasonDescription': PropertySchema(
      id: 27,
      name: r'reasonDescription',
      type: IsarType.string,
    ),
    r'restoreInventory': PropertySchema(
      id: 28,
      name: r'restoreInventory',
      type: IsarType.bool,
    ),
    r'serverId': PropertySchema(
      id: 29,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 30,
      name: r'status',
      type: IsarType.string,
      enumMap: _IsarCreditNotestatusEnumValueMap,
    ),
    r'subtotal': PropertySchema(
      id: 31,
      name: r'subtotal',
      type: IsarType.double,
    ),
    r'taxAmount': PropertySchema(
      id: 32,
      name: r'taxAmount',
      type: IsarType.double,
    ),
    r'taxPercentage': PropertySchema(
      id: 33,
      name: r'taxPercentage',
      type: IsarType.double,
    ),
    r'terms': PropertySchema(
      id: 34,
      name: r'terms',
      type: IsarType.string,
    ),
    r'total': PropertySchema(
      id: 35,
      name: r'total',
      type: IsarType.double,
    ),
    r'type': PropertySchema(
      id: 36,
      name: r'type',
      type: IsarType.string,
      enumMap: _IsarCreditNotetypeEnumValueMap,
    ),
    r'updatedAt': PropertySchema(
      id: 37,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'version': PropertySchema(
      id: 38,
      name: r'version',
      type: IsarType.long,
    )
  },
  estimateSize: _isarCreditNoteEstimateSize,
  serialize: _isarCreditNoteSerialize,
  deserialize: _isarCreditNoteDeserialize,
  deserializeProp: _isarCreditNoteDeserializeProp,
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
    r'number': IndexSchema(
      id: 5012388430481709372,
      name: r'number',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'number',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'date': IndexSchema(
      id: -7552997827385218417,
      name: r'date',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'date',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'type': IndexSchema(
      id: 5117122708147080838,
      name: r'type',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'type',
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
    ),
    r'invoiceId': IndexSchema(
      id: 7861523084118270123,
      name: r'invoiceId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'invoiceId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'customerId': IndexSchema(
      id: 1498639901530368639,
      name: r'customerId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'customerId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarCreditNoteGetId,
  getLinks: _isarCreditNoteGetLinks,
  attach: _isarCreditNoteAttach,
  version: '3.1.0+1',
);

int _isarCreditNoteEstimateSize(
  IsarCreditNote object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.appliedById;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.createdById.length * 3;
  bytesCount += 3 + object.customerId.length * 3;
  bytesCount += 3 + object.invoiceId.length * 3;
  {
    final value = object.itemsJson;
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
  {
    final value = object.metadataJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.number.length * 3;
  bytesCount += 3 + object.reason.name.length * 3;
  {
    final value = object.reasonDescription;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.serverId.length * 3;
  bytesCount += 3 + object.status.name.length * 3;
  {
    final value = object.terms;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.type.name.length * 3;
  return bytesCount;
}

void _isarCreditNoteSerialize(
  IsarCreditNote object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.appliedAt);
  writer.writeString(offsets[1], object.appliedById);
  writer.writeBool(offsets[2], object.canBeEdited);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeString(offsets[4], object.createdById);
  writer.writeString(offsets[5], object.customerId);
  writer.writeDateTime(offsets[6], object.date);
  writer.writeDateTime(offsets[7], object.deletedAt);
  writer.writeBool(offsets[8], object.inventoryRestored);
  writer.writeDateTime(offsets[9], object.inventoryRestoredAt);
  writer.writeString(offsets[10], object.invoiceId);
  writer.writeBool(offsets[11], object.isCancelled);
  writer.writeBool(offsets[12], object.isConfirmed);
  writer.writeBool(offsets[13], object.isDeleted);
  writer.writeBool(offsets[14], object.isDraft);
  writer.writeBool(offsets[15], object.isFullCredit);
  writer.writeBool(offsets[16], object.isPartialCredit);
  writer.writeBool(offsets[17], object.isSynced);
  writer.writeString(offsets[18], object.itemsJson);
  writer.writeDateTime(offsets[19], object.lastModifiedAt);
  writer.writeString(offsets[20], object.lastModifiedBy);
  writer.writeDateTime(offsets[21], object.lastSyncAt);
  writer.writeString(offsets[22], object.metadataJson);
  writer.writeBool(offsets[23], object.needsSync);
  writer.writeString(offsets[24], object.notes);
  writer.writeString(offsets[25], object.number);
  writer.writeString(offsets[26], object.reason.name);
  writer.writeString(offsets[27], object.reasonDescription);
  writer.writeBool(offsets[28], object.restoreInventory);
  writer.writeString(offsets[29], object.serverId);
  writer.writeString(offsets[30], object.status.name);
  writer.writeDouble(offsets[31], object.subtotal);
  writer.writeDouble(offsets[32], object.taxAmount);
  writer.writeDouble(offsets[33], object.taxPercentage);
  writer.writeString(offsets[34], object.terms);
  writer.writeDouble(offsets[35], object.total);
  writer.writeString(offsets[36], object.type.name);
  writer.writeDateTime(offsets[37], object.updatedAt);
  writer.writeLong(offsets[38], object.version);
}

IsarCreditNote _isarCreditNoteDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarCreditNote();
  object.appliedAt = reader.readDateTimeOrNull(offsets[0]);
  object.appliedById = reader.readStringOrNull(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[3]);
  object.createdById = reader.readString(offsets[4]);
  object.customerId = reader.readString(offsets[5]);
  object.date = reader.readDateTime(offsets[6]);
  object.deletedAt = reader.readDateTimeOrNull(offsets[7]);
  object.id = id;
  object.inventoryRestored = reader.readBool(offsets[8]);
  object.inventoryRestoredAt = reader.readDateTimeOrNull(offsets[9]);
  object.invoiceId = reader.readString(offsets[10]);
  object.isSynced = reader.readBool(offsets[17]);
  object.itemsJson = reader.readStringOrNull(offsets[18]);
  object.lastModifiedAt = reader.readDateTimeOrNull(offsets[19]);
  object.lastModifiedBy = reader.readStringOrNull(offsets[20]);
  object.lastSyncAt = reader.readDateTimeOrNull(offsets[21]);
  object.metadataJson = reader.readStringOrNull(offsets[22]);
  object.notes = reader.readStringOrNull(offsets[24]);
  object.number = reader.readString(offsets[25]);
  object.reason =
      _IsarCreditNotereasonValueEnumMap[reader.readStringOrNull(offsets[26])] ??
          IsarCreditNoteReason.returnedGoods;
  object.reasonDescription = reader.readStringOrNull(offsets[27]);
  object.restoreInventory = reader.readBool(offsets[28]);
  object.serverId = reader.readString(offsets[29]);
  object.status =
      _IsarCreditNotestatusValueEnumMap[reader.readStringOrNull(offsets[30])] ??
          IsarCreditNoteStatus.draft;
  object.subtotal = reader.readDouble(offsets[31]);
  object.taxAmount = reader.readDouble(offsets[32]);
  object.taxPercentage = reader.readDouble(offsets[33]);
  object.terms = reader.readStringOrNull(offsets[34]);
  object.total = reader.readDouble(offsets[35]);
  object.type =
      _IsarCreditNotetypeValueEnumMap[reader.readStringOrNull(offsets[36])] ??
          IsarCreditNoteType.full;
  object.updatedAt = reader.readDateTime(offsets[37]);
  object.version = reader.readLong(offsets[38]);
  return object;
}

P _isarCreditNoteDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
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
      return (reader.readBool(offset)) as P;
    case 17:
      return (reader.readBool(offset)) as P;
    case 18:
      return (reader.readStringOrNull(offset)) as P;
    case 19:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 20:
      return (reader.readStringOrNull(offset)) as P;
    case 21:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 22:
      return (reader.readStringOrNull(offset)) as P;
    case 23:
      return (reader.readBool(offset)) as P;
    case 24:
      return (reader.readStringOrNull(offset)) as P;
    case 25:
      return (reader.readString(offset)) as P;
    case 26:
      return (_IsarCreditNotereasonValueEnumMap[
              reader.readStringOrNull(offset)] ??
          IsarCreditNoteReason.returnedGoods) as P;
    case 27:
      return (reader.readStringOrNull(offset)) as P;
    case 28:
      return (reader.readBool(offset)) as P;
    case 29:
      return (reader.readString(offset)) as P;
    case 30:
      return (_IsarCreditNotestatusValueEnumMap[
              reader.readStringOrNull(offset)] ??
          IsarCreditNoteStatus.draft) as P;
    case 31:
      return (reader.readDouble(offset)) as P;
    case 32:
      return (reader.readDouble(offset)) as P;
    case 33:
      return (reader.readDouble(offset)) as P;
    case 34:
      return (reader.readStringOrNull(offset)) as P;
    case 35:
      return (reader.readDouble(offset)) as P;
    case 36:
      return (_IsarCreditNotetypeValueEnumMap[
              reader.readStringOrNull(offset)] ??
          IsarCreditNoteType.full) as P;
    case 37:
      return (reader.readDateTime(offset)) as P;
    case 38:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _IsarCreditNotereasonEnumValueMap = {
  r'returnedGoods': r'returnedGoods',
  r'damagedGoods': r'damagedGoods',
  r'billingError': r'billingError',
  r'priceAdjustment': r'priceAdjustment',
  r'orderCancellation': r'orderCancellation',
  r'customerDissatisfaction': r'customerDissatisfaction',
  r'inventoryAdjustment': r'inventoryAdjustment',
  r'discountGranted': r'discountGranted',
  r'other': r'other',
};
const _IsarCreditNotereasonValueEnumMap = {
  r'returnedGoods': IsarCreditNoteReason.returnedGoods,
  r'damagedGoods': IsarCreditNoteReason.damagedGoods,
  r'billingError': IsarCreditNoteReason.billingError,
  r'priceAdjustment': IsarCreditNoteReason.priceAdjustment,
  r'orderCancellation': IsarCreditNoteReason.orderCancellation,
  r'customerDissatisfaction': IsarCreditNoteReason.customerDissatisfaction,
  r'inventoryAdjustment': IsarCreditNoteReason.inventoryAdjustment,
  r'discountGranted': IsarCreditNoteReason.discountGranted,
  r'other': IsarCreditNoteReason.other,
};
const _IsarCreditNotestatusEnumValueMap = {
  r'draft': r'draft',
  r'confirmed': r'confirmed',
  r'cancelled': r'cancelled',
};
const _IsarCreditNotestatusValueEnumMap = {
  r'draft': IsarCreditNoteStatus.draft,
  r'confirmed': IsarCreditNoteStatus.confirmed,
  r'cancelled': IsarCreditNoteStatus.cancelled,
};
const _IsarCreditNotetypeEnumValueMap = {
  r'full': r'full',
  r'partial': r'partial',
};
const _IsarCreditNotetypeValueEnumMap = {
  r'full': IsarCreditNoteType.full,
  r'partial': IsarCreditNoteType.partial,
};

Id _isarCreditNoteGetId(IsarCreditNote object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarCreditNoteGetLinks(IsarCreditNote object) {
  return [];
}

void _isarCreditNoteAttach(
    IsarCollection<dynamic> col, Id id, IsarCreditNote object) {
  object.id = id;
}

extension IsarCreditNoteByIndex on IsarCollection<IsarCreditNote> {
  Future<IsarCreditNote?> getByServerId(String serverId) {
    return getByIndex(r'serverId', [serverId]);
  }

  IsarCreditNote? getByServerIdSync(String serverId) {
    return getByIndexSync(r'serverId', [serverId]);
  }

  Future<bool> deleteByServerId(String serverId) {
    return deleteByIndex(r'serverId', [serverId]);
  }

  bool deleteByServerIdSync(String serverId) {
    return deleteByIndexSync(r'serverId', [serverId]);
  }

  Future<List<IsarCreditNote?>> getAllByServerId(List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'serverId', values);
  }

  List<IsarCreditNote?> getAllByServerIdSync(List<String> serverIdValues) {
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

  Future<Id> putByServerId(IsarCreditNote object) {
    return putByIndex(r'serverId', object);
  }

  Id putByServerIdSync(IsarCreditNote object, {bool saveLinks = true}) {
    return putByIndexSync(r'serverId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByServerId(List<IsarCreditNote> objects) {
    return putAllByIndex(r'serverId', objects);
  }

  List<Id> putAllByServerIdSync(List<IsarCreditNote> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'serverId', objects, saveLinks: saveLinks);
  }

  Future<IsarCreditNote?> getByNumber(String number) {
    return getByIndex(r'number', [number]);
  }

  IsarCreditNote? getByNumberSync(String number) {
    return getByIndexSync(r'number', [number]);
  }

  Future<bool> deleteByNumber(String number) {
    return deleteByIndex(r'number', [number]);
  }

  bool deleteByNumberSync(String number) {
    return deleteByIndexSync(r'number', [number]);
  }

  Future<List<IsarCreditNote?>> getAllByNumber(List<String> numberValues) {
    final values = numberValues.map((e) => [e]).toList();
    return getAllByIndex(r'number', values);
  }

  List<IsarCreditNote?> getAllByNumberSync(List<String> numberValues) {
    final values = numberValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'number', values);
  }

  Future<int> deleteAllByNumber(List<String> numberValues) {
    final values = numberValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'number', values);
  }

  int deleteAllByNumberSync(List<String> numberValues) {
    final values = numberValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'number', values);
  }

  Future<Id> putByNumber(IsarCreditNote object) {
    return putByIndex(r'number', object);
  }

  Id putByNumberSync(IsarCreditNote object, {bool saveLinks = true}) {
    return putByIndexSync(r'number', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByNumber(List<IsarCreditNote> objects) {
    return putAllByIndex(r'number', objects);
  }

  List<Id> putAllByNumberSync(List<IsarCreditNote> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'number', objects, saveLinks: saveLinks);
  }
}

extension IsarCreditNoteQueryWhereSort
    on QueryBuilder<IsarCreditNote, IsarCreditNote, QWhere> {
  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterWhere> anyDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'date'),
      );
    });
  }
}

extension IsarCreditNoteQueryWhere
    on QueryBuilder<IsarCreditNote, IsarCreditNote, QWhereClause> {
  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterWhereClause>
      serverIdEqualTo(String serverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'serverId',
        value: [serverId],
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterWhereClause>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterWhereClause> numberEqualTo(
      String number) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'number',
        value: [number],
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterWhereClause>
      numberNotEqualTo(String number) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'number',
              lower: [],
              upper: [number],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'number',
              lower: [number],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'number',
              lower: [number],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'number',
              lower: [],
              upper: [number],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterWhereClause> dateEqualTo(
      DateTime date) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'date',
        value: [date],
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterWhereClause>
      dateNotEqualTo(DateTime date) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterWhereClause>
      dateGreaterThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [date],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterWhereClause> dateLessThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [],
        upper: [date],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterWhereClause> dateBetween(
    DateTime lowerDate,
    DateTime upperDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [lowerDate],
        includeLower: includeLower,
        upper: [upperDate],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterWhereClause> typeEqualTo(
      IsarCreditNoteType type) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'type',
        value: [type],
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterWhereClause>
      typeNotEqualTo(IsarCreditNoteType type) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [],
              upper: [type],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [type],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [type],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [],
              upper: [type],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterWhereClause> statusEqualTo(
      IsarCreditNoteStatus status) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'status',
        value: [status],
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterWhereClause>
      statusNotEqualTo(IsarCreditNoteStatus status) {
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterWhereClause>
      invoiceIdEqualTo(String invoiceId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'invoiceId',
        value: [invoiceId],
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterWhereClause>
      invoiceIdNotEqualTo(String invoiceId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'invoiceId',
              lower: [],
              upper: [invoiceId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'invoiceId',
              lower: [invoiceId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'invoiceId',
              lower: [invoiceId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'invoiceId',
              lower: [],
              upper: [invoiceId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterWhereClause>
      customerIdEqualTo(String customerId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'customerId',
        value: [customerId],
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterWhereClause>
      customerIdNotEqualTo(String customerId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'customerId',
              lower: [],
              upper: [customerId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'customerId',
              lower: [customerId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'customerId',
              lower: [customerId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'customerId',
              lower: [],
              upper: [customerId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarCreditNoteQueryFilter
    on QueryBuilder<IsarCreditNote, IsarCreditNote, QFilterCondition> {
  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      appliedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'appliedAt',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      appliedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'appliedAt',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      appliedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'appliedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      appliedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'appliedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      appliedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'appliedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      appliedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'appliedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      appliedByIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'appliedById',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      appliedByIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'appliedById',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      appliedByIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'appliedById',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      appliedByIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'appliedById',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      appliedByIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'appliedById',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      appliedByIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'appliedById',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      appliedByIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'appliedById',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      appliedByIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'appliedById',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      appliedByIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'appliedById',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      appliedByIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'appliedById',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      appliedByIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'appliedById',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      appliedByIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'appliedById',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      canBeEditedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'canBeEdited',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      createdByIdEqualTo(
    String value, {
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      createdByIdGreaterThan(
    String value, {
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      createdByIdLessThan(
    String value, {
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      createdByIdBetween(
    String lower,
    String upper, {
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      createdByIdStartsWith(
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      createdByIdEndsWith(
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      createdByIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'createdById',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      createdByIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'createdById',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      createdByIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdById',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      createdByIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'createdById',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      customerIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      customerIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'customerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      customerIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'customerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      customerIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'customerId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      customerIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'customerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      customerIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'customerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      customerIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'customerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      customerIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'customerId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      customerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customerId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      customerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'customerId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      dateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      deletedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      deletedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition> idBetween(
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      inventoryRestoredEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'inventoryRestored',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      inventoryRestoredAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'inventoryRestoredAt',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      inventoryRestoredAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'inventoryRestoredAt',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      inventoryRestoredAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'inventoryRestoredAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      inventoryRestoredAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'inventoryRestoredAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      inventoryRestoredAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'inventoryRestoredAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      inventoryRestoredAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'inventoryRestoredAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      invoiceIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'invoiceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      invoiceIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'invoiceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      invoiceIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'invoiceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      invoiceIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'invoiceId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      invoiceIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'invoiceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      invoiceIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'invoiceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      invoiceIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'invoiceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      invoiceIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'invoiceId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      invoiceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'invoiceId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      invoiceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'invoiceId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      isCancelledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isCancelled',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      isConfirmedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isConfirmed',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      isDeletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      isDraftEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDraft',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      isFullCreditEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isFullCredit',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      isPartialCreditEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isPartialCredit',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      itemsJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'itemsJson',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      itemsJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'itemsJson',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      itemsJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'itemsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      itemsJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'itemsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      itemsJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'itemsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      itemsJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'itemsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      itemsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'itemsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      itemsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'itemsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      itemsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'itemsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      itemsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'itemsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      itemsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'itemsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      itemsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'itemsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      lastModifiedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastModifiedAt',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      lastModifiedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastModifiedAt',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      lastModifiedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastModifiedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      lastModifiedByIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastModifiedBy',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      lastModifiedByIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastModifiedBy',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      lastModifiedByContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastModifiedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      lastModifiedByMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastModifiedBy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      lastModifiedByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastModifiedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      lastModifiedByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastModifiedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      lastSyncAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSyncAt',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      lastSyncAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSyncAt',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      lastSyncAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSyncAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      metadataJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'metadataJson',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      metadataJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'metadataJson',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      metadataJsonEqualTo(
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      metadataJsonGreaterThan(
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      metadataJsonLessThan(
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      metadataJsonBetween(
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      metadataJsonStartsWith(
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      metadataJsonEndsWith(
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      metadataJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'metadataJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      metadataJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'metadataJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      metadataJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'metadataJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      metadataJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'metadataJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      needsSyncEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'needsSync',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      notesEqualTo(
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      notesGreaterThan(
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      notesLessThan(
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      notesBetween(
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      notesStartsWith(
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      notesEndsWith(
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      notesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      notesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      numberEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'number',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      numberGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'number',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      numberLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'number',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      numberBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'number',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      numberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'number',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      numberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'number',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      numberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'number',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      numberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'number',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      numberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'number',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      numberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'number',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      reasonEqualTo(
    IsarCreditNoteReason value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      reasonGreaterThan(
    IsarCreditNoteReason value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      reasonLessThan(
    IsarCreditNoteReason value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      reasonBetween(
    IsarCreditNoteReason lower,
    IsarCreditNoteReason upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reason',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      reasonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'reason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      reasonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'reason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      reasonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'reason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      reasonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'reason',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      reasonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reason',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      reasonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'reason',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      reasonDescriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'reasonDescription',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      reasonDescriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'reasonDescription',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      reasonDescriptionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reasonDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      reasonDescriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reasonDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      reasonDescriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reasonDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      reasonDescriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reasonDescription',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      reasonDescriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'reasonDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      reasonDescriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'reasonDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      reasonDescriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'reasonDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      reasonDescriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'reasonDescription',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      reasonDescriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reasonDescription',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      reasonDescriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'reasonDescription',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      restoreInventoryEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'restoreInventory',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      serverIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      serverIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'serverId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      statusEqualTo(
    IsarCreditNoteStatus value, {
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      statusGreaterThan(
    IsarCreditNoteStatus value, {
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      statusLessThan(
    IsarCreditNoteStatus value, {
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      statusBetween(
    IsarCreditNoteStatus lower,
    IsarCreditNoteStatus upper, {
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      subtotalEqualTo(
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      subtotalGreaterThan(
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      subtotalLessThan(
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      subtotalBetween(
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      taxAmountEqualTo(
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      taxAmountGreaterThan(
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      taxAmountLessThan(
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      taxAmountBetween(
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      taxPercentageEqualTo(
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      taxPercentageGreaterThan(
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      taxPercentageLessThan(
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      taxPercentageBetween(
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      termsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'terms',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      termsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'terms',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      termsEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'terms',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      termsGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'terms',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      termsLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'terms',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      termsBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'terms',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      termsStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'terms',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      termsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'terms',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      termsContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'terms',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      termsMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'terms',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      termsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'terms',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      termsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'terms',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      totalEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'total',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      totalGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'total',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      totalLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'total',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      totalBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'total',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      typeEqualTo(
    IsarCreditNoteType value, {
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      typeGreaterThan(
    IsarCreditNoteType value, {
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      typeLessThan(
    IsarCreditNoteType value, {
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      typeBetween(
    IsarCreditNoteType lower,
    IsarCreditNoteType upper, {
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
      versionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterFilterCondition>
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

extension IsarCreditNoteQueryObject
    on QueryBuilder<IsarCreditNote, IsarCreditNote, QFilterCondition> {}

extension IsarCreditNoteQueryLinks
    on QueryBuilder<IsarCreditNote, IsarCreditNote, QFilterCondition> {}

extension IsarCreditNoteQuerySortBy
    on QueryBuilder<IsarCreditNote, IsarCreditNote, QSortBy> {
  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> sortByAppliedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appliedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByAppliedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appliedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByAppliedById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appliedById', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByAppliedByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appliedById', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByCanBeEdited() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canBeEdited', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByCanBeEditedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canBeEdited', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByCreatedById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdById', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByCreatedByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdById', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByCustomerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerId', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByCustomerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerId', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> sortByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByInventoryRestored() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inventoryRestored', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByInventoryRestoredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inventoryRestored', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByInventoryRestoredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inventoryRestoredAt', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByInventoryRestoredAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inventoryRestoredAt', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> sortByInvoiceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceId', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByInvoiceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceId', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByIsCancelled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCancelled', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByIsCancelledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCancelled', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByIsConfirmed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isConfirmed', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByIsConfirmedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isConfirmed', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> sortByIsDraft() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDraft', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByIsDraftDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDraft', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByIsFullCredit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFullCredit', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByIsFullCreditDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFullCredit', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByIsPartialCredit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPartialCredit', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByIsPartialCreditDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPartialCredit', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> sortByItemsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByItemsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByLastModifiedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByLastModifiedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByLastModifiedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedBy', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByLastModifiedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedBy', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByLastSyncAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByMetadataJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataJson', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByMetadataJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataJson', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> sortByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByNeedsSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> sortByNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'number', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'number', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> sortByReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reason', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reason', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByReasonDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reasonDescription', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByReasonDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reasonDescription', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByRestoreInventory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restoreInventory', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByRestoreInventoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restoreInventory', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> sortBySubtotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortBySubtotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> sortByTaxAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxAmount', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByTaxAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxAmount', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByTaxPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxPercentage', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByTaxPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxPercentage', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> sortByTerms() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'terms', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> sortByTermsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'terms', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> sortByTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> sortByTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> sortByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      sortByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension IsarCreditNoteQuerySortThenBy
    on QueryBuilder<IsarCreditNote, IsarCreditNote, QSortThenBy> {
  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> thenByAppliedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appliedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByAppliedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appliedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByAppliedById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appliedById', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByAppliedByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appliedById', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByCanBeEdited() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canBeEdited', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByCanBeEditedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canBeEdited', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByCreatedById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdById', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByCreatedByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdById', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByCustomerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerId', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByCustomerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerId', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> thenByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByInventoryRestored() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inventoryRestored', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByInventoryRestoredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inventoryRestored', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByInventoryRestoredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inventoryRestoredAt', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByInventoryRestoredAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inventoryRestoredAt', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> thenByInvoiceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceId', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByInvoiceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceId', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByIsCancelled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCancelled', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByIsCancelledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCancelled', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByIsConfirmed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isConfirmed', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByIsConfirmedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isConfirmed', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> thenByIsDraft() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDraft', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByIsDraftDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDraft', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByIsFullCredit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFullCredit', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByIsFullCreditDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFullCredit', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByIsPartialCredit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPartialCredit', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByIsPartialCreditDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPartialCredit', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> thenByItemsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByItemsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByLastModifiedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByLastModifiedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByLastModifiedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedBy', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByLastModifiedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedBy', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByLastSyncAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByMetadataJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataJson', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByMetadataJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataJson', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> thenByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByNeedsSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> thenByNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'number', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'number', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> thenByReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reason', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reason', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByReasonDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reasonDescription', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByReasonDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reasonDescription', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByRestoreInventory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restoreInventory', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByRestoreInventoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restoreInventory', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> thenBySubtotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenBySubtotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> thenByTaxAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxAmount', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByTaxAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxAmount', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByTaxPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxPercentage', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByTaxPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxPercentage', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> thenByTerms() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'terms', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> thenByTermsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'terms', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> thenByTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> thenByTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy> thenByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QAfterSortBy>
      thenByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension IsarCreditNoteQueryWhereDistinct
    on QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct> {
  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct>
      distinctByAppliedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'appliedAt');
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct> distinctByAppliedById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'appliedById', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct>
      distinctByCanBeEdited() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'canBeEdited');
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct> distinctByCreatedById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdById', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct> distinctByCustomerId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct>
      distinctByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedAt');
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct>
      distinctByInventoryRestored() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'inventoryRestored');
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct>
      distinctByInventoryRestoredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'inventoryRestoredAt');
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct> distinctByInvoiceId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'invoiceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct>
      distinctByIsCancelled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isCancelled');
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct>
      distinctByIsConfirmed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isConfirmed');
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct>
      distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct> distinctByIsDraft() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDraft');
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct>
      distinctByIsFullCredit() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFullCredit');
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct>
      distinctByIsPartialCredit() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPartialCredit');
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct> distinctByItemsJson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'itemsJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct>
      distinctByLastModifiedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastModifiedAt');
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct>
      distinctByLastModifiedBy({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastModifiedBy',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct>
      distinctByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncAt');
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct>
      distinctByMetadataJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'metadataJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct>
      distinctByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'needsSync');
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct> distinctByNotes(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct> distinctByNumber(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'number', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct> distinctByReason(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reason', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct>
      distinctByReasonDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reasonDescription',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct>
      distinctByRestoreInventory() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'restoreInventory');
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct> distinctByServerId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct> distinctBySubtotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subtotal');
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct>
      distinctByTaxAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'taxAmount');
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct>
      distinctByTaxPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'taxPercentage');
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct> distinctByTerms(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'terms', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct> distinctByTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'total');
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct> distinctByType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNote, QDistinct> distinctByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'version');
    });
  }
}

extension IsarCreditNoteQueryProperty
    on QueryBuilder<IsarCreditNote, IsarCreditNote, QQueryProperty> {
  QueryBuilder<IsarCreditNote, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarCreditNote, DateTime?, QQueryOperations>
      appliedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'appliedAt');
    });
  }

  QueryBuilder<IsarCreditNote, String?, QQueryOperations>
      appliedByIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'appliedById');
    });
  }

  QueryBuilder<IsarCreditNote, bool, QQueryOperations> canBeEditedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'canBeEdited');
    });
  }

  QueryBuilder<IsarCreditNote, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<IsarCreditNote, String, QQueryOperations> createdByIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdById');
    });
  }

  QueryBuilder<IsarCreditNote, String, QQueryOperations> customerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customerId');
    });
  }

  QueryBuilder<IsarCreditNote, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<IsarCreditNote, DateTime?, QQueryOperations>
      deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedAt');
    });
  }

  QueryBuilder<IsarCreditNote, bool, QQueryOperations>
      inventoryRestoredProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'inventoryRestored');
    });
  }

  QueryBuilder<IsarCreditNote, DateTime?, QQueryOperations>
      inventoryRestoredAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'inventoryRestoredAt');
    });
  }

  QueryBuilder<IsarCreditNote, String, QQueryOperations> invoiceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'invoiceId');
    });
  }

  QueryBuilder<IsarCreditNote, bool, QQueryOperations> isCancelledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isCancelled');
    });
  }

  QueryBuilder<IsarCreditNote, bool, QQueryOperations> isConfirmedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isConfirmed');
    });
  }

  QueryBuilder<IsarCreditNote, bool, QQueryOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<IsarCreditNote, bool, QQueryOperations> isDraftProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDraft');
    });
  }

  QueryBuilder<IsarCreditNote, bool, QQueryOperations> isFullCreditProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFullCredit');
    });
  }

  QueryBuilder<IsarCreditNote, bool, QQueryOperations>
      isPartialCreditProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPartialCredit');
    });
  }

  QueryBuilder<IsarCreditNote, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<IsarCreditNote, String?, QQueryOperations> itemsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'itemsJson');
    });
  }

  QueryBuilder<IsarCreditNote, DateTime?, QQueryOperations>
      lastModifiedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastModifiedAt');
    });
  }

  QueryBuilder<IsarCreditNote, String?, QQueryOperations>
      lastModifiedByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastModifiedBy');
    });
  }

  QueryBuilder<IsarCreditNote, DateTime?, QQueryOperations>
      lastSyncAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncAt');
    });
  }

  QueryBuilder<IsarCreditNote, String?, QQueryOperations>
      metadataJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'metadataJson');
    });
  }

  QueryBuilder<IsarCreditNote, bool, QQueryOperations> needsSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'needsSync');
    });
  }

  QueryBuilder<IsarCreditNote, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<IsarCreditNote, String, QQueryOperations> numberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'number');
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNoteReason, QQueryOperations>
      reasonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reason');
    });
  }

  QueryBuilder<IsarCreditNote, String?, QQueryOperations>
      reasonDescriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reasonDescription');
    });
  }

  QueryBuilder<IsarCreditNote, bool, QQueryOperations>
      restoreInventoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'restoreInventory');
    });
  }

  QueryBuilder<IsarCreditNote, String, QQueryOperations> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNoteStatus, QQueryOperations>
      statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<IsarCreditNote, double, QQueryOperations> subtotalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subtotal');
    });
  }

  QueryBuilder<IsarCreditNote, double, QQueryOperations> taxAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'taxAmount');
    });
  }

  QueryBuilder<IsarCreditNote, double, QQueryOperations>
      taxPercentageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'taxPercentage');
    });
  }

  QueryBuilder<IsarCreditNote, String?, QQueryOperations> termsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'terms');
    });
  }

  QueryBuilder<IsarCreditNote, double, QQueryOperations> totalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'total');
    });
  }

  QueryBuilder<IsarCreditNote, IsarCreditNoteType, QQueryOperations>
      typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<IsarCreditNote, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<IsarCreditNote, int, QQueryOperations> versionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'version');
    });
  }
}
