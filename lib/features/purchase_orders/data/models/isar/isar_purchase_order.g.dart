// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_purchase_order.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarPurchaseOrderCollection on Isar {
  IsarCollection<IsarPurchaseOrder> get isarPurchaseOrders => this.collection();
}

const IsarPurchaseOrderSchema = CollectionSchema(
  name: r'IsarPurchaseOrder',
  id: 7786784340440015519,
  properties: {
    r'approvedAt': PropertySchema(
      id: 0,
      name: r'approvedAt',
      type: IsarType.dateTime,
    ),
    r'approvedBy': PropertySchema(
      id: 1,
      name: r'approvedBy',
      type: IsarType.string,
    ),
    r'attachmentsJson': PropertySchema(
      id: 2,
      name: r'attachmentsJson',
      type: IsarType.string,
    ),
    r'contactEmail': PropertySchema(
      id: 3,
      name: r'contactEmail',
      type: IsarType.string,
    ),
    r'contactPerson': PropertySchema(
      id: 4,
      name: r'contactPerson',
      type: IsarType.string,
    ),
    r'contactPhone': PropertySchema(
      id: 5,
      name: r'contactPhone',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 6,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'createdBy': PropertySchema(
      id: 7,
      name: r'createdBy',
      type: IsarType.string,
    ),
    r'currency': PropertySchema(
      id: 8,
      name: r'currency',
      type: IsarType.string,
    ),
    r'deletedAt': PropertySchema(
      id: 9,
      name: r'deletedAt',
      type: IsarType.dateTime,
    ),
    r'deliveredDate': PropertySchema(
      id: 10,
      name: r'deliveredDate',
      type: IsarType.dateTime,
    ),
    r'deliveryAddress': PropertySchema(
      id: 11,
      name: r'deliveryAddress',
      type: IsarType.string,
    ),
    r'discountAmount': PropertySchema(
      id: 12,
      name: r'discountAmount',
      type: IsarType.double,
    ),
    r'exchangeRate': PropertySchema(
      id: 13,
      name: r'exchangeRate',
      type: IsarType.double,
    ),
    r'expectedDeliveryDate': PropertySchema(
      id: 14,
      name: r'expectedDeliveryDate',
      type: IsarType.dateTime,
    ),
    r'internalNotes': PropertySchema(
      id: 15,
      name: r'internalNotes',
      type: IsarType.string,
    ),
    r'isApproved': PropertySchema(
      id: 16,
      name: r'isApproved',
      type: IsarType.bool,
    ),
    r'isCancelled': PropertySchema(
      id: 17,
      name: r'isCancelled',
      type: IsarType.bool,
    ),
    r'isDeleted': PropertySchema(
      id: 18,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'isDraft': PropertySchema(
      id: 19,
      name: r'isDraft',
      type: IsarType.bool,
    ),
    r'isPending': PropertySchema(
      id: 20,
      name: r'isPending',
      type: IsarType.bool,
    ),
    r'isReceived': PropertySchema(
      id: 21,
      name: r'isReceived',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 22,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'lastModifiedAt': PropertySchema(
      id: 23,
      name: r'lastModifiedAt',
      type: IsarType.dateTime,
    ),
    r'lastModifiedBy': PropertySchema(
      id: 24,
      name: r'lastModifiedBy',
      type: IsarType.string,
    ),
    r'lastSyncAt': PropertySchema(
      id: 25,
      name: r'lastSyncAt',
      type: IsarType.dateTime,
    ),
    r'needsSync': PropertySchema(
      id: 26,
      name: r'needsSync',
      type: IsarType.bool,
    ),
    r'notes': PropertySchema(
      id: 27,
      name: r'notes',
      type: IsarType.string,
    ),
    r'orderDate': PropertySchema(
      id: 28,
      name: r'orderDate',
      type: IsarType.dateTime,
    ),
    r'orderNumber': PropertySchema(
      id: 29,
      name: r'orderNumber',
      type: IsarType.string,
    ),
    r'priority': PropertySchema(
      id: 30,
      name: r'priority',
      type: IsarType.string,
      enumMap: _IsarPurchaseOrderpriorityEnumValueMap,
    ),
    r'purchaseCurrency': PropertySchema(
      id: 31,
      name: r'purchaseCurrency',
      type: IsarType.string,
    ),
    r'purchaseCurrencyAmount': PropertySchema(
      id: 32,
      name: r'purchaseCurrencyAmount',
      type: IsarType.double,
    ),
    r'serverId': PropertySchema(
      id: 33,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 34,
      name: r'status',
      type: IsarType.string,
      enumMap: _IsarPurchaseOrderstatusEnumValueMap,
    ),
    r'subtotal': PropertySchema(
      id: 35,
      name: r'subtotal',
      type: IsarType.double,
    ),
    r'supplierId': PropertySchema(
      id: 36,
      name: r'supplierId',
      type: IsarType.string,
    ),
    r'supplierName': PropertySchema(
      id: 37,
      name: r'supplierName',
      type: IsarType.string,
    ),
    r'taxAmount': PropertySchema(
      id: 38,
      name: r'taxAmount',
      type: IsarType.double,
    ),
    r'totalAmount': PropertySchema(
      id: 39,
      name: r'totalAmount',
      type: IsarType.double,
    ),
    r'updatedAt': PropertySchema(
      id: 40,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'version': PropertySchema(
      id: 41,
      name: r'version',
      type: IsarType.long,
    )
  },
  estimateSize: _isarPurchaseOrderEstimateSize,
  serialize: _isarPurchaseOrderSerialize,
  deserialize: _isarPurchaseOrderDeserialize,
  deserializeProp: _isarPurchaseOrderDeserializeProp,
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
    r'orderNumber': IndexSchema(
      id: 7506692016205733885,
      name: r'orderNumber',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'orderNumber',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'supplierId': IndexSchema(
      id: -7509772217447508349,
      name: r'supplierId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'supplierId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'orderDate': IndexSchema(
      id: 3422021493395204714,
      name: r'orderDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'orderDate',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {
    r'items': LinkSchema(
      id: -5167609322953303649,
      name: r'items',
      target: r'IsarPurchaseOrderItem',
      single: false,
    )
  },
  embeddedSchemas: {},
  getId: _isarPurchaseOrderGetId,
  getLinks: _isarPurchaseOrderGetLinks,
  attach: _isarPurchaseOrderAttach,
  version: '3.1.0+1',
);

int _isarPurchaseOrderEstimateSize(
  IsarPurchaseOrder object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.approvedBy;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.attachmentsJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.contactEmail;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.contactPerson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.contactPhone;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.createdBy;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.currency;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.deliveryAddress;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.internalNotes;
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
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.orderNumber;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.priority.name.length * 3;
  {
    final value = object.purchaseCurrency;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.serverId.length * 3;
  bytesCount += 3 + object.status.name.length * 3;
  {
    final value = object.supplierId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.supplierName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _isarPurchaseOrderSerialize(
  IsarPurchaseOrder object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.approvedAt);
  writer.writeString(offsets[1], object.approvedBy);
  writer.writeString(offsets[2], object.attachmentsJson);
  writer.writeString(offsets[3], object.contactEmail);
  writer.writeString(offsets[4], object.contactPerson);
  writer.writeString(offsets[5], object.contactPhone);
  writer.writeDateTime(offsets[6], object.createdAt);
  writer.writeString(offsets[7], object.createdBy);
  writer.writeString(offsets[8], object.currency);
  writer.writeDateTime(offsets[9], object.deletedAt);
  writer.writeDateTime(offsets[10], object.deliveredDate);
  writer.writeString(offsets[11], object.deliveryAddress);
  writer.writeDouble(offsets[12], object.discountAmount);
  writer.writeDouble(offsets[13], object.exchangeRate);
  writer.writeDateTime(offsets[14], object.expectedDeliveryDate);
  writer.writeString(offsets[15], object.internalNotes);
  writer.writeBool(offsets[16], object.isApproved);
  writer.writeBool(offsets[17], object.isCancelled);
  writer.writeBool(offsets[18], object.isDeleted);
  writer.writeBool(offsets[19], object.isDraft);
  writer.writeBool(offsets[20], object.isPending);
  writer.writeBool(offsets[21], object.isReceived);
  writer.writeBool(offsets[22], object.isSynced);
  writer.writeDateTime(offsets[23], object.lastModifiedAt);
  writer.writeString(offsets[24], object.lastModifiedBy);
  writer.writeDateTime(offsets[25], object.lastSyncAt);
  writer.writeBool(offsets[26], object.needsSync);
  writer.writeString(offsets[27], object.notes);
  writer.writeDateTime(offsets[28], object.orderDate);
  writer.writeString(offsets[29], object.orderNumber);
  writer.writeString(offsets[30], object.priority.name);
  writer.writeString(offsets[31], object.purchaseCurrency);
  writer.writeDouble(offsets[32], object.purchaseCurrencyAmount);
  writer.writeString(offsets[33], object.serverId);
  writer.writeString(offsets[34], object.status.name);
  writer.writeDouble(offsets[35], object.subtotal);
  writer.writeString(offsets[36], object.supplierId);
  writer.writeString(offsets[37], object.supplierName);
  writer.writeDouble(offsets[38], object.taxAmount);
  writer.writeDouble(offsets[39], object.totalAmount);
  writer.writeDateTime(offsets[40], object.updatedAt);
  writer.writeLong(offsets[41], object.version);
}

IsarPurchaseOrder _isarPurchaseOrderDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarPurchaseOrder();
  object.approvedAt = reader.readDateTimeOrNull(offsets[0]);
  object.approvedBy = reader.readStringOrNull(offsets[1]);
  object.attachmentsJson = reader.readStringOrNull(offsets[2]);
  object.contactEmail = reader.readStringOrNull(offsets[3]);
  object.contactPerson = reader.readStringOrNull(offsets[4]);
  object.contactPhone = reader.readStringOrNull(offsets[5]);
  object.createdAt = reader.readDateTime(offsets[6]);
  object.createdBy = reader.readStringOrNull(offsets[7]);
  object.currency = reader.readStringOrNull(offsets[8]);
  object.deletedAt = reader.readDateTimeOrNull(offsets[9]);
  object.deliveredDate = reader.readDateTimeOrNull(offsets[10]);
  object.deliveryAddress = reader.readStringOrNull(offsets[11]);
  object.discountAmount = reader.readDouble(offsets[12]);
  object.exchangeRate = reader.readDoubleOrNull(offsets[13]);
  object.expectedDeliveryDate = reader.readDateTimeOrNull(offsets[14]);
  object.id = id;
  object.internalNotes = reader.readStringOrNull(offsets[15]);
  object.isSynced = reader.readBool(offsets[22]);
  object.lastModifiedAt = reader.readDateTimeOrNull(offsets[23]);
  object.lastModifiedBy = reader.readStringOrNull(offsets[24]);
  object.lastSyncAt = reader.readDateTimeOrNull(offsets[25]);
  object.notes = reader.readStringOrNull(offsets[27]);
  object.orderDate = reader.readDateTimeOrNull(offsets[28]);
  object.orderNumber = reader.readStringOrNull(offsets[29]);
  object.priority = _IsarPurchaseOrderpriorityValueEnumMap[
          reader.readStringOrNull(offsets[30])] ??
      IsarPurchaseOrderPriority.low;
  object.purchaseCurrency = reader.readStringOrNull(offsets[31]);
  object.purchaseCurrencyAmount = reader.readDoubleOrNull(offsets[32]);
  object.serverId = reader.readString(offsets[33]);
  object.status = _IsarPurchaseOrderstatusValueEnumMap[
          reader.readStringOrNull(offsets[34])] ??
      IsarPurchaseOrderStatus.draft;
  object.subtotal = reader.readDouble(offsets[35]);
  object.supplierId = reader.readStringOrNull(offsets[36]);
  object.supplierName = reader.readStringOrNull(offsets[37]);
  object.taxAmount = reader.readDouble(offsets[38]);
  object.totalAmount = reader.readDouble(offsets[39]);
  object.updatedAt = reader.readDateTime(offsets[40]);
  object.version = reader.readLong(offsets[41]);
  return object;
}

P _isarPurchaseOrderDeserializeProp<P>(
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
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 10:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readDouble(offset)) as P;
    case 13:
      return (reader.readDoubleOrNull(offset)) as P;
    case 14:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readBool(offset)) as P;
    case 17:
      return (reader.readBool(offset)) as P;
    case 18:
      return (reader.readBool(offset)) as P;
    case 19:
      return (reader.readBool(offset)) as P;
    case 20:
      return (reader.readBool(offset)) as P;
    case 21:
      return (reader.readBool(offset)) as P;
    case 22:
      return (reader.readBool(offset)) as P;
    case 23:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 24:
      return (reader.readStringOrNull(offset)) as P;
    case 25:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 26:
      return (reader.readBool(offset)) as P;
    case 27:
      return (reader.readStringOrNull(offset)) as P;
    case 28:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 29:
      return (reader.readStringOrNull(offset)) as P;
    case 30:
      return (_IsarPurchaseOrderpriorityValueEnumMap[
              reader.readStringOrNull(offset)] ??
          IsarPurchaseOrderPriority.low) as P;
    case 31:
      return (reader.readStringOrNull(offset)) as P;
    case 32:
      return (reader.readDoubleOrNull(offset)) as P;
    case 33:
      return (reader.readString(offset)) as P;
    case 34:
      return (_IsarPurchaseOrderstatusValueEnumMap[
              reader.readStringOrNull(offset)] ??
          IsarPurchaseOrderStatus.draft) as P;
    case 35:
      return (reader.readDouble(offset)) as P;
    case 36:
      return (reader.readStringOrNull(offset)) as P;
    case 37:
      return (reader.readStringOrNull(offset)) as P;
    case 38:
      return (reader.readDouble(offset)) as P;
    case 39:
      return (reader.readDouble(offset)) as P;
    case 40:
      return (reader.readDateTime(offset)) as P;
    case 41:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _IsarPurchaseOrderpriorityEnumValueMap = {
  r'low': r'low',
  r'medium': r'medium',
  r'high': r'high',
  r'urgent': r'urgent',
};
const _IsarPurchaseOrderpriorityValueEnumMap = {
  r'low': IsarPurchaseOrderPriority.low,
  r'medium': IsarPurchaseOrderPriority.medium,
  r'high': IsarPurchaseOrderPriority.high,
  r'urgent': IsarPurchaseOrderPriority.urgent,
};
const _IsarPurchaseOrderstatusEnumValueMap = {
  r'draft': r'draft',
  r'pending': r'pending',
  r'approved': r'approved',
  r'rejected': r'rejected',
  r'sent': r'sent',
  r'partiallyReceived': r'partiallyReceived',
  r'received': r'received',
  r'cancelled': r'cancelled',
};
const _IsarPurchaseOrderstatusValueEnumMap = {
  r'draft': IsarPurchaseOrderStatus.draft,
  r'pending': IsarPurchaseOrderStatus.pending,
  r'approved': IsarPurchaseOrderStatus.approved,
  r'rejected': IsarPurchaseOrderStatus.rejected,
  r'sent': IsarPurchaseOrderStatus.sent,
  r'partiallyReceived': IsarPurchaseOrderStatus.partiallyReceived,
  r'received': IsarPurchaseOrderStatus.received,
  r'cancelled': IsarPurchaseOrderStatus.cancelled,
};

Id _isarPurchaseOrderGetId(IsarPurchaseOrder object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarPurchaseOrderGetLinks(
    IsarPurchaseOrder object) {
  return [object.items];
}

void _isarPurchaseOrderAttach(
    IsarCollection<dynamic> col, Id id, IsarPurchaseOrder object) {
  object.id = id;
  object.items
      .attach(col, col.isar.collection<IsarPurchaseOrderItem>(), r'items', id);
}

extension IsarPurchaseOrderByIndex on IsarCollection<IsarPurchaseOrder> {
  Future<IsarPurchaseOrder?> getByServerId(String serverId) {
    return getByIndex(r'serverId', [serverId]);
  }

  IsarPurchaseOrder? getByServerIdSync(String serverId) {
    return getByIndexSync(r'serverId', [serverId]);
  }

  Future<bool> deleteByServerId(String serverId) {
    return deleteByIndex(r'serverId', [serverId]);
  }

  bool deleteByServerIdSync(String serverId) {
    return deleteByIndexSync(r'serverId', [serverId]);
  }

  Future<List<IsarPurchaseOrder?>> getAllByServerId(
      List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'serverId', values);
  }

  List<IsarPurchaseOrder?> getAllByServerIdSync(List<String> serverIdValues) {
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

  Future<Id> putByServerId(IsarPurchaseOrder object) {
    return putByIndex(r'serverId', object);
  }

  Id putByServerIdSync(IsarPurchaseOrder object, {bool saveLinks = true}) {
    return putByIndexSync(r'serverId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByServerId(List<IsarPurchaseOrder> objects) {
    return putAllByIndex(r'serverId', objects);
  }

  List<Id> putAllByServerIdSync(List<IsarPurchaseOrder> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'serverId', objects, saveLinks: saveLinks);
  }
}

extension IsarPurchaseOrderQueryWhereSort
    on QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QWhere> {
  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterWhere>
      anyOrderDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'orderDate'),
      );
    });
  }
}

extension IsarPurchaseOrderQueryWhere
    on QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QWhereClause> {
  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterWhereClause>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterWhereClause>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterWhereClause>
      serverIdEqualTo(String serverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'serverId',
        value: [serverId],
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterWhereClause>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterWhereClause>
      orderNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'orderNumber',
        value: [null],
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterWhereClause>
      orderNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'orderNumber',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterWhereClause>
      orderNumberEqualTo(String? orderNumber) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'orderNumber',
        value: [orderNumber],
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterWhereClause>
      orderNumberNotEqualTo(String? orderNumber) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'orderNumber',
              lower: [],
              upper: [orderNumber],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'orderNumber',
              lower: [orderNumber],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'orderNumber',
              lower: [orderNumber],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'orderNumber',
              lower: [],
              upper: [orderNumber],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterWhereClause>
      supplierIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'supplierId',
        value: [null],
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterWhereClause>
      supplierIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'supplierId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterWhereClause>
      supplierIdEqualTo(String? supplierId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'supplierId',
        value: [supplierId],
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterWhereClause>
      supplierIdNotEqualTo(String? supplierId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'supplierId',
              lower: [],
              upper: [supplierId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'supplierId',
              lower: [supplierId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'supplierId',
              lower: [supplierId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'supplierId',
              lower: [],
              upper: [supplierId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterWhereClause>
      orderDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'orderDate',
        value: [null],
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterWhereClause>
      orderDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'orderDate',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterWhereClause>
      orderDateEqualTo(DateTime? orderDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'orderDate',
        value: [orderDate],
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterWhereClause>
      orderDateNotEqualTo(DateTime? orderDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'orderDate',
              lower: [],
              upper: [orderDate],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'orderDate',
              lower: [orderDate],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'orderDate',
              lower: [orderDate],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'orderDate',
              lower: [],
              upper: [orderDate],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterWhereClause>
      orderDateGreaterThan(
    DateTime? orderDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'orderDate',
        lower: [orderDate],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterWhereClause>
      orderDateLessThan(
    DateTime? orderDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'orderDate',
        lower: [],
        upper: [orderDate],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterWhereClause>
      orderDateBetween(
    DateTime? lowerOrderDate,
    DateTime? upperOrderDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'orderDate',
        lower: [lowerOrderDate],
        includeLower: includeLower,
        upper: [upperOrderDate],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IsarPurchaseOrderQueryFilter
    on QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QFilterCondition> {
  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      approvedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'approvedAt',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      approvedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'approvedAt',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      approvedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'approvedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      approvedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'approvedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      approvedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'approvedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      approvedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'approvedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      approvedByIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'approvedBy',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      approvedByIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'approvedBy',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      approvedByEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'approvedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      approvedByGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'approvedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      approvedByLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'approvedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      approvedByBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'approvedBy',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      approvedByStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'approvedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      approvedByEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'approvedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      approvedByContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'approvedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      approvedByMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'approvedBy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      approvedByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'approvedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      approvedByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'approvedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      attachmentsJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'attachmentsJson',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      attachmentsJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'attachmentsJson',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      attachmentsJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'attachmentsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      attachmentsJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'attachmentsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      attachmentsJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'attachmentsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      attachmentsJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'attachmentsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      attachmentsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'attachmentsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      attachmentsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'attachmentsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      attachmentsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'attachmentsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      attachmentsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'attachmentsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      attachmentsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'attachmentsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      attachmentsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'attachmentsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactEmailIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'contactEmail',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactEmailIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'contactEmail',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactEmailEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contactEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactEmailGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'contactEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactEmailLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'contactEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactEmailBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'contactEmail',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactEmailStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'contactEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactEmailEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'contactEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactEmailContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'contactEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactEmailMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'contactEmail',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactEmailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contactEmail',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactEmailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'contactEmail',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactPersonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'contactPerson',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactPersonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'contactPerson',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactPersonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contactPerson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactPersonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'contactPerson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactPersonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'contactPerson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactPersonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'contactPerson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactPersonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'contactPerson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactPersonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'contactPerson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactPersonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'contactPerson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactPersonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'contactPerson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactPersonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contactPerson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactPersonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'contactPerson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactPhoneIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'contactPhone',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactPhoneIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'contactPhone',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactPhoneEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contactPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactPhoneGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'contactPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactPhoneLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'contactPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactPhoneBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'contactPhone',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactPhoneStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'contactPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactPhoneEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'contactPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactPhoneContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'contactPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactPhoneMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'contactPhone',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactPhoneIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contactPhone',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      contactPhoneIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'contactPhone',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      createdByIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createdBy',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      createdByIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createdBy',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      createdByEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      createdByGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      createdByLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      createdByBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdBy',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      createdByStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      createdByEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      createdByContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      createdByMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'createdBy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      createdByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdBy',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      createdByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'createdBy',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      currencyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'currency',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      currencyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'currency',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      currencyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      currencyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'currency',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      currencyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currency',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      currencyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'currency',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      deletedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      deletedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      deliveredDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deliveredDate',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      deliveredDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deliveredDate',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      deliveredDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deliveredDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      deliveredDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deliveredDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      deliveredDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deliveredDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      deliveredDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deliveredDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      deliveryAddressIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deliveryAddress',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      deliveryAddressIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deliveryAddress',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      deliveryAddressEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deliveryAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      deliveryAddressGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deliveryAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      deliveryAddressLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deliveryAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      deliveryAddressBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deliveryAddress',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      deliveryAddressStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'deliveryAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      deliveryAddressEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'deliveryAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      deliveryAddressContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'deliveryAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      deliveryAddressMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'deliveryAddress',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      deliveryAddressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deliveryAddress',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      deliveryAddressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'deliveryAddress',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      discountAmountEqualTo(
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      discountAmountGreaterThan(
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      discountAmountLessThan(
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      discountAmountBetween(
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      exchangeRateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'exchangeRate',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      exchangeRateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'exchangeRate',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      exchangeRateEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exchangeRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      exchangeRateGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'exchangeRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      exchangeRateLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'exchangeRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      exchangeRateBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'exchangeRate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      expectedDeliveryDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'expectedDeliveryDate',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      expectedDeliveryDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'expectedDeliveryDate',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      expectedDeliveryDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'expectedDeliveryDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      expectedDeliveryDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'expectedDeliveryDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      expectedDeliveryDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'expectedDeliveryDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      expectedDeliveryDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'expectedDeliveryDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      internalNotesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'internalNotes',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      internalNotesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'internalNotes',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      internalNotesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'internalNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      internalNotesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'internalNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      internalNotesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'internalNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      internalNotesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'internalNotes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      internalNotesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'internalNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      internalNotesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'internalNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      internalNotesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'internalNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      internalNotesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'internalNotes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      internalNotesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'internalNotes',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      internalNotesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'internalNotes',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      isApprovedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isApproved',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      isCancelledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isCancelled',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      isDeletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      isDraftEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDraft',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      isPendingEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isPending',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      isReceivedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isReceived',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      lastModifiedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastModifiedAt',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      lastModifiedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastModifiedAt',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      lastModifiedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastModifiedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      lastModifiedByIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastModifiedBy',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      lastModifiedByIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastModifiedBy',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      lastModifiedByContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastModifiedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      lastModifiedByMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastModifiedBy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      lastModifiedByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastModifiedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      lastModifiedByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastModifiedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      lastSyncAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSyncAt',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      lastSyncAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSyncAt',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      lastSyncAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSyncAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      needsSyncEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'needsSync',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      notesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      notesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      orderDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'orderDate',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      orderDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'orderDate',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      orderDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orderDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      orderDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'orderDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      orderDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'orderDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      orderDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'orderDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      orderNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'orderNumber',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      orderNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'orderNumber',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      orderNumberEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orderNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      orderNumberGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'orderNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      orderNumberLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'orderNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      orderNumberBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'orderNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      orderNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'orderNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      orderNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'orderNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      orderNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'orderNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      orderNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'orderNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      orderNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orderNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      orderNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'orderNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      priorityEqualTo(
    IsarPurchaseOrderPriority value, {
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      priorityGreaterThan(
    IsarPurchaseOrderPriority value, {
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      priorityLessThan(
    IsarPurchaseOrderPriority value, {
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      priorityBetween(
    IsarPurchaseOrderPriority lower,
    IsarPurchaseOrderPriority upper, {
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      priorityContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'priority',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      priorityMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'priority',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      priorityIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'priority',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      priorityIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'priority',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      purchaseCurrencyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'purchaseCurrency',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      purchaseCurrencyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'purchaseCurrency',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      purchaseCurrencyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'purchaseCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      purchaseCurrencyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'purchaseCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      purchaseCurrencyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'purchaseCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      purchaseCurrencyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'purchaseCurrency',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      purchaseCurrencyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'purchaseCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      purchaseCurrencyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'purchaseCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      purchaseCurrencyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'purchaseCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      purchaseCurrencyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'purchaseCurrency',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      purchaseCurrencyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'purchaseCurrency',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      purchaseCurrencyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'purchaseCurrency',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      purchaseCurrencyAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'purchaseCurrencyAmount',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      purchaseCurrencyAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'purchaseCurrencyAmount',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      purchaseCurrencyAmountEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'purchaseCurrencyAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      purchaseCurrencyAmountGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'purchaseCurrencyAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      purchaseCurrencyAmountLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'purchaseCurrencyAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      purchaseCurrencyAmountBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'purchaseCurrencyAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      serverIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      serverIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'serverId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      statusEqualTo(
    IsarPurchaseOrderStatus value, {
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      statusGreaterThan(
    IsarPurchaseOrderStatus value, {
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      statusLessThan(
    IsarPurchaseOrderStatus value, {
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      statusBetween(
    IsarPurchaseOrderStatus lower,
    IsarPurchaseOrderStatus upper, {
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      supplierIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'supplierId',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      supplierIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'supplierId',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      supplierIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'supplierId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      supplierIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'supplierId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      supplierIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'supplierId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      supplierIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'supplierId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      supplierIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'supplierId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      supplierIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'supplierId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      supplierIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'supplierId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      supplierIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'supplierId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      supplierIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'supplierId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      supplierIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'supplierId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      supplierNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'supplierName',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      supplierNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'supplierName',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      supplierNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'supplierName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      supplierNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'supplierName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      supplierNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'supplierName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      supplierNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'supplierName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      supplierNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'supplierName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      supplierNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'supplierName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      supplierNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'supplierName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      supplierNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'supplierName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      supplierNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'supplierName',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      supplierNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'supplierName',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      totalAmountEqualTo(
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      totalAmountGreaterThan(
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      totalAmountLessThan(
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      totalAmountBetween(
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      versionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
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

extension IsarPurchaseOrderQueryObject
    on QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QFilterCondition> {}

extension IsarPurchaseOrderQueryLinks
    on QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QFilterCondition> {
  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      items(FilterQuery<IsarPurchaseOrderItem> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'items');
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      itemsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'items', length, true, length, true);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      itemsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'items', 0, true, 0, true);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      itemsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'items', 0, false, 999999, true);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      itemsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'items', 0, true, length, include);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      itemsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'items', length, include, 999999, true);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterFilterCondition>
      itemsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'items', lower, includeLower, upper, includeUpper);
    });
  }
}

extension IsarPurchaseOrderQuerySortBy
    on QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QSortBy> {
  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByApprovedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'approvedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByApprovedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'approvedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByApprovedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'approvedBy', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByApprovedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'approvedBy', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByAttachmentsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attachmentsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByAttachmentsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attachmentsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByContactEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactEmail', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByContactEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactEmail', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByContactPerson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactPerson', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByContactPersonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactPerson', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByContactPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactPhone', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByContactPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactPhone', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByCreatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByCreatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByDeliveredDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveredDate', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByDeliveredDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveredDate', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByDeliveryAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveryAddress', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByDeliveryAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveryAddress', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByDiscountAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByDiscountAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByExchangeRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchangeRate', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByExchangeRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchangeRate', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByExpectedDeliveryDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedDeliveryDate', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByExpectedDeliveryDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedDeliveryDate', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByInternalNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'internalNotes', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByInternalNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'internalNotes', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByIsApproved() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isApproved', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByIsApprovedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isApproved', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByIsCancelled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCancelled', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByIsCancelledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCancelled', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByIsDraft() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDraft', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByIsDraftDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDraft', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByIsPending() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPending', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByIsPendingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPending', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByIsReceived() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isReceived', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByIsReceivedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isReceived', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByLastModifiedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByLastModifiedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByLastModifiedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedBy', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByLastModifiedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedBy', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByLastSyncAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByNeedsSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByOrderDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderDate', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByOrderDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderDate', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByOrderNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderNumber', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByOrderNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderNumber', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByPriority() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByPriorityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByPurchaseCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseCurrency', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByPurchaseCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseCurrency', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByPurchaseCurrencyAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseCurrencyAmount', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByPurchaseCurrencyAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseCurrencyAmount', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortBySubtotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortBySubtotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortBySupplierId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierId', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortBySupplierIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierId', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortBySupplierName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierName', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortBySupplierNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierName', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByTaxAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxAmount', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByTaxAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxAmount', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByTotalAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      sortByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension IsarPurchaseOrderQuerySortThenBy
    on QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QSortThenBy> {
  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByApprovedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'approvedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByApprovedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'approvedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByApprovedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'approvedBy', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByApprovedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'approvedBy', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByAttachmentsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attachmentsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByAttachmentsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attachmentsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByContactEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactEmail', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByContactEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactEmail', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByContactPerson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactPerson', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByContactPersonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactPerson', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByContactPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactPhone', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByContactPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactPhone', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByCreatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByCreatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByDeliveredDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveredDate', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByDeliveredDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveredDate', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByDeliveryAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveryAddress', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByDeliveryAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveryAddress', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByDiscountAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByDiscountAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByExchangeRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchangeRate', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByExchangeRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchangeRate', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByExpectedDeliveryDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedDeliveryDate', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByExpectedDeliveryDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedDeliveryDate', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByInternalNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'internalNotes', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByInternalNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'internalNotes', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByIsApproved() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isApproved', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByIsApprovedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isApproved', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByIsCancelled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCancelled', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByIsCancelledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCancelled', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByIsDraft() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDraft', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByIsDraftDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDraft', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByIsPending() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPending', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByIsPendingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPending', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByIsReceived() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isReceived', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByIsReceivedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isReceived', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByLastModifiedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByLastModifiedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByLastModifiedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedBy', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByLastModifiedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedBy', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByLastSyncAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByNeedsSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByOrderDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderDate', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByOrderDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderDate', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByOrderNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderNumber', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByOrderNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderNumber', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByPriority() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByPriorityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByPurchaseCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseCurrency', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByPurchaseCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseCurrency', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByPurchaseCurrencyAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseCurrencyAmount', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByPurchaseCurrencyAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseCurrencyAmount', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenBySubtotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenBySubtotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenBySupplierId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierId', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenBySupplierIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierId', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenBySupplierName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierName', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenBySupplierNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierName', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByTaxAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxAmount', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByTaxAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxAmount', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByTotalAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QAfterSortBy>
      thenByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension IsarPurchaseOrderQueryWhereDistinct
    on QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct> {
  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByApprovedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'approvedAt');
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByApprovedBy({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'approvedBy', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByAttachmentsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'attachmentsJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByContactEmail({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contactEmail', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByContactPerson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contactPerson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByContactPhone({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contactPhone', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByCreatedBy({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdBy', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByCurrency({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currency', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedAt');
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByDeliveredDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deliveredDate');
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByDeliveryAddress({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deliveryAddress',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByDiscountAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'discountAmount');
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByExchangeRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'exchangeRate');
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByExpectedDeliveryDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expectedDeliveryDate');
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByInternalNotes({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'internalNotes',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByIsApproved() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isApproved');
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByIsCancelled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isCancelled');
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByIsDraft() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDraft');
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByIsPending() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPending');
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByIsReceived() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isReceived');
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByLastModifiedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastModifiedAt');
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByLastModifiedBy({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastModifiedBy',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncAt');
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'needsSync');
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct> distinctByNotes(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByOrderDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orderDate');
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByOrderNumber({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orderNumber', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByPriority({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'priority', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByPurchaseCurrency({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'purchaseCurrency',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByPurchaseCurrencyAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'purchaseCurrencyAmount');
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByServerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctBySubtotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subtotal');
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctBySupplierId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'supplierId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctBySupplierName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'supplierName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByTaxAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'taxAmount');
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalAmount');
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QDistinct>
      distinctByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'version');
    });
  }
}

extension IsarPurchaseOrderQueryProperty
    on QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrder, QQueryProperty> {
  QueryBuilder<IsarPurchaseOrder, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarPurchaseOrder, DateTime?, QQueryOperations>
      approvedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'approvedAt');
    });
  }

  QueryBuilder<IsarPurchaseOrder, String?, QQueryOperations>
      approvedByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'approvedBy');
    });
  }

  QueryBuilder<IsarPurchaseOrder, String?, QQueryOperations>
      attachmentsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'attachmentsJson');
    });
  }

  QueryBuilder<IsarPurchaseOrder, String?, QQueryOperations>
      contactEmailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contactEmail');
    });
  }

  QueryBuilder<IsarPurchaseOrder, String?, QQueryOperations>
      contactPersonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contactPerson');
    });
  }

  QueryBuilder<IsarPurchaseOrder, String?, QQueryOperations>
      contactPhoneProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contactPhone');
    });
  }

  QueryBuilder<IsarPurchaseOrder, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<IsarPurchaseOrder, String?, QQueryOperations>
      createdByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdBy');
    });
  }

  QueryBuilder<IsarPurchaseOrder, String?, QQueryOperations>
      currencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currency');
    });
  }

  QueryBuilder<IsarPurchaseOrder, DateTime?, QQueryOperations>
      deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedAt');
    });
  }

  QueryBuilder<IsarPurchaseOrder, DateTime?, QQueryOperations>
      deliveredDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deliveredDate');
    });
  }

  QueryBuilder<IsarPurchaseOrder, String?, QQueryOperations>
      deliveryAddressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deliveryAddress');
    });
  }

  QueryBuilder<IsarPurchaseOrder, double, QQueryOperations>
      discountAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'discountAmount');
    });
  }

  QueryBuilder<IsarPurchaseOrder, double?, QQueryOperations>
      exchangeRateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'exchangeRate');
    });
  }

  QueryBuilder<IsarPurchaseOrder, DateTime?, QQueryOperations>
      expectedDeliveryDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expectedDeliveryDate');
    });
  }

  QueryBuilder<IsarPurchaseOrder, String?, QQueryOperations>
      internalNotesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'internalNotes');
    });
  }

  QueryBuilder<IsarPurchaseOrder, bool, QQueryOperations> isApprovedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isApproved');
    });
  }

  QueryBuilder<IsarPurchaseOrder, bool, QQueryOperations>
      isCancelledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isCancelled');
    });
  }

  QueryBuilder<IsarPurchaseOrder, bool, QQueryOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<IsarPurchaseOrder, bool, QQueryOperations> isDraftProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDraft');
    });
  }

  QueryBuilder<IsarPurchaseOrder, bool, QQueryOperations> isPendingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPending');
    });
  }

  QueryBuilder<IsarPurchaseOrder, bool, QQueryOperations> isReceivedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isReceived');
    });
  }

  QueryBuilder<IsarPurchaseOrder, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<IsarPurchaseOrder, DateTime?, QQueryOperations>
      lastModifiedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastModifiedAt');
    });
  }

  QueryBuilder<IsarPurchaseOrder, String?, QQueryOperations>
      lastModifiedByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastModifiedBy');
    });
  }

  QueryBuilder<IsarPurchaseOrder, DateTime?, QQueryOperations>
      lastSyncAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncAt');
    });
  }

  QueryBuilder<IsarPurchaseOrder, bool, QQueryOperations> needsSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'needsSync');
    });
  }

  QueryBuilder<IsarPurchaseOrder, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<IsarPurchaseOrder, DateTime?, QQueryOperations>
      orderDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orderDate');
    });
  }

  QueryBuilder<IsarPurchaseOrder, String?, QQueryOperations>
      orderNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orderNumber');
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrderPriority, QQueryOperations>
      priorityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'priority');
    });
  }

  QueryBuilder<IsarPurchaseOrder, String?, QQueryOperations>
      purchaseCurrencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'purchaseCurrency');
    });
  }

  QueryBuilder<IsarPurchaseOrder, double?, QQueryOperations>
      purchaseCurrencyAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'purchaseCurrencyAmount');
    });
  }

  QueryBuilder<IsarPurchaseOrder, String, QQueryOperations> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<IsarPurchaseOrder, IsarPurchaseOrderStatus, QQueryOperations>
      statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<IsarPurchaseOrder, double, QQueryOperations> subtotalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subtotal');
    });
  }

  QueryBuilder<IsarPurchaseOrder, String?, QQueryOperations>
      supplierIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'supplierId');
    });
  }

  QueryBuilder<IsarPurchaseOrder, String?, QQueryOperations>
      supplierNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'supplierName');
    });
  }

  QueryBuilder<IsarPurchaseOrder, double, QQueryOperations>
      taxAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'taxAmount');
    });
  }

  QueryBuilder<IsarPurchaseOrder, double, QQueryOperations>
      totalAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalAmount');
    });
  }

  QueryBuilder<IsarPurchaseOrder, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<IsarPurchaseOrder, int, QQueryOperations> versionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'version');
    });
  }
}
