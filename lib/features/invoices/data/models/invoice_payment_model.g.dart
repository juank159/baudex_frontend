// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_payment_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetInvoicePaymentModelCollection on Isar {
  IsarCollection<InvoicePaymentModel> get invoicePaymentModels =>
      this.collection();
}

const InvoicePaymentModelSchema = CollectionSchema(
  name: r'InvoicePaymentModel',
  id: 2400607877091277887,
  properties: {
    r'amount': PropertySchema(
      id: 0,
      name: r'amount',
      type: IsarType.double,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'createdAtIndex': PropertySchema(
      id: 2,
      name: r'createdAtIndex',
      type: IsarType.dateTime,
    ),
    r'createdById': PropertySchema(
      id: 3,
      name: r'createdById',
      type: IsarType.string,
    ),
    r'id': PropertySchema(
      id: 4,
      name: r'id',
      type: IsarType.string,
    ),
    r'invoiceId': PropertySchema(
      id: 5,
      name: r'invoiceId',
      type: IsarType.string,
    ),
    r'invoiceIdIndex': PropertySchema(
      id: 6,
      name: r'invoiceIdIndex',
      type: IsarType.string,
    ),
    r'notes': PropertySchema(
      id: 7,
      name: r'notes',
      type: IsarType.string,
    ),
    r'organizationId': PropertySchema(
      id: 8,
      name: r'organizationId',
      type: IsarType.string,
    ),
    r'organizationIdIndex': PropertySchema(
      id: 9,
      name: r'organizationIdIndex',
      type: IsarType.string,
    ),
    r'paymentDate': PropertySchema(
      id: 10,
      name: r'paymentDate',
      type: IsarType.dateTime,
    ),
    r'paymentDateIndex': PropertySchema(
      id: 11,
      name: r'paymentDateIndex',
      type: IsarType.dateTime,
    ),
    r'paymentMethod': PropertySchema(
      id: 12,
      name: r'paymentMethod',
      type: IsarType.byte,
      enumMap: _InvoicePaymentModelpaymentMethodEnumValueMap,
    ),
    r'reference': PropertySchema(
      id: 13,
      name: r'reference',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 14,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _invoicePaymentModelEstimateSize,
  serialize: _invoicePaymentModelSerialize,
  deserialize: _invoicePaymentModelDeserialize,
  deserializeProp: _invoicePaymentModelDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'invoiceIdIndex': IndexSchema(
      id: 2817602778918146636,
      name: r'invoiceIdIndex',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'invoiceIdIndex',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'organizationIdIndex': IndexSchema(
      id: -7015055370042955203,
      name: r'organizationIdIndex',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'organizationIdIndex',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'paymentDateIndex': IndexSchema(
      id: -8461385532866071419,
      name: r'paymentDateIndex',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'paymentDateIndex',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'createdAtIndex': IndexSchema(
      id: -7100342901358937067,
      name: r'createdAtIndex',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'createdAtIndex',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _invoicePaymentModelGetId,
  getLinks: _invoicePaymentModelGetLinks,
  attach: _invoicePaymentModelAttach,
  version: '3.1.0+1',
);

int _invoicePaymentModelEstimateSize(
  InvoicePaymentModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.createdById.length * 3;
  bytesCount += 3 + object.id.length * 3;
  bytesCount += 3 + object.invoiceId.length * 3;
  bytesCount += 3 + object.invoiceIdIndex.length * 3;
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.organizationId.length * 3;
  bytesCount += 3 + object.organizationIdIndex.length * 3;
  {
    final value = object.reference;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _invoicePaymentModelSerialize(
  InvoicePaymentModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.amount);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeDateTime(offsets[2], object.createdAtIndex);
  writer.writeString(offsets[3], object.createdById);
  writer.writeString(offsets[4], object.id);
  writer.writeString(offsets[5], object.invoiceId);
  writer.writeString(offsets[6], object.invoiceIdIndex);
  writer.writeString(offsets[7], object.notes);
  writer.writeString(offsets[8], object.organizationId);
  writer.writeString(offsets[9], object.organizationIdIndex);
  writer.writeDateTime(offsets[10], object.paymentDate);
  writer.writeDateTime(offsets[11], object.paymentDateIndex);
  writer.writeByte(offsets[12], object.paymentMethod.index);
  writer.writeString(offsets[13], object.reference);
  writer.writeDateTime(offsets[14], object.updatedAt);
}

InvoicePaymentModel _invoicePaymentModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = InvoicePaymentModel();
  object.amount = reader.readDouble(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.createdById = reader.readString(offsets[3]);
  object.id = reader.readString(offsets[4]);
  object.invoiceId = reader.readString(offsets[5]);
  object.notes = reader.readStringOrNull(offsets[7]);
  object.organizationId = reader.readString(offsets[8]);
  object.paymentDate = reader.readDateTime(offsets[10]);
  object.paymentMethod = _InvoicePaymentModelpaymentMethodValueEnumMap[
          reader.readByteOrNull(offsets[12])] ??
      PaymentMethod.cash;
  object.reference = reader.readStringOrNull(offsets[13]);
  object.updatedAt = reader.readDateTime(offsets[14]);
  return object;
}

P _invoicePaymentModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readDateTime(offset)) as P;
    case 11:
      return (reader.readDateTime(offset)) as P;
    case 12:
      return (_InvoicePaymentModelpaymentMethodValueEnumMap[
              reader.readByteOrNull(offset)] ??
          PaymentMethod.cash) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _InvoicePaymentModelpaymentMethodEnumValueMap = {
  'cash': 0,
  'credit': 1,
  'creditCard': 2,
  'debitCard': 3,
  'bankTransfer': 4,
  'check': 5,
  'other': 6,
};
const _InvoicePaymentModelpaymentMethodValueEnumMap = {
  0: PaymentMethod.cash,
  1: PaymentMethod.credit,
  2: PaymentMethod.creditCard,
  3: PaymentMethod.debitCard,
  4: PaymentMethod.bankTransfer,
  5: PaymentMethod.check,
  6: PaymentMethod.other,
};

Id _invoicePaymentModelGetId(InvoicePaymentModel object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _invoicePaymentModelGetLinks(
    InvoicePaymentModel object) {
  return [];
}

void _invoicePaymentModelAttach(
    IsarCollection<dynamic> col, Id id, InvoicePaymentModel object) {}

extension InvoicePaymentModelQueryWhereSort
    on QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QWhere> {
  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterWhere>
      anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterWhere>
      anyPaymentDateIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'paymentDateIndex'),
      );
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterWhere>
      anyCreatedAtIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAtIndex'),
      );
    });
  }
}

extension InvoicePaymentModelQueryWhere
    on QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QWhereClause> {
  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterWhereClause>
      isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterWhereClause>
      isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterWhereClause>
      isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterWhereClause>
      invoiceIdIndexEqualTo(String invoiceIdIndex) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'invoiceIdIndex',
        value: [invoiceIdIndex],
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterWhereClause>
      invoiceIdIndexNotEqualTo(String invoiceIdIndex) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'invoiceIdIndex',
              lower: [],
              upper: [invoiceIdIndex],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'invoiceIdIndex',
              lower: [invoiceIdIndex],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'invoiceIdIndex',
              lower: [invoiceIdIndex],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'invoiceIdIndex',
              lower: [],
              upper: [invoiceIdIndex],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterWhereClause>
      organizationIdIndexEqualTo(String organizationIdIndex) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'organizationIdIndex',
        value: [organizationIdIndex],
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterWhereClause>
      organizationIdIndexNotEqualTo(String organizationIdIndex) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'organizationIdIndex',
              lower: [],
              upper: [organizationIdIndex],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'organizationIdIndex',
              lower: [organizationIdIndex],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'organizationIdIndex',
              lower: [organizationIdIndex],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'organizationIdIndex',
              lower: [],
              upper: [organizationIdIndex],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterWhereClause>
      paymentDateIndexEqualTo(DateTime paymentDateIndex) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'paymentDateIndex',
        value: [paymentDateIndex],
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterWhereClause>
      paymentDateIndexNotEqualTo(DateTime paymentDateIndex) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'paymentDateIndex',
              lower: [],
              upper: [paymentDateIndex],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'paymentDateIndex',
              lower: [paymentDateIndex],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'paymentDateIndex',
              lower: [paymentDateIndex],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'paymentDateIndex',
              lower: [],
              upper: [paymentDateIndex],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterWhereClause>
      paymentDateIndexGreaterThan(
    DateTime paymentDateIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'paymentDateIndex',
        lower: [paymentDateIndex],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterWhereClause>
      paymentDateIndexLessThan(
    DateTime paymentDateIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'paymentDateIndex',
        lower: [],
        upper: [paymentDateIndex],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterWhereClause>
      paymentDateIndexBetween(
    DateTime lowerPaymentDateIndex,
    DateTime upperPaymentDateIndex, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'paymentDateIndex',
        lower: [lowerPaymentDateIndex],
        includeLower: includeLower,
        upper: [upperPaymentDateIndex],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterWhereClause>
      createdAtIndexEqualTo(DateTime createdAtIndex) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'createdAtIndex',
        value: [createdAtIndex],
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterWhereClause>
      createdAtIndexNotEqualTo(DateTime createdAtIndex) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAtIndex',
              lower: [],
              upper: [createdAtIndex],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAtIndex',
              lower: [createdAtIndex],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAtIndex',
              lower: [createdAtIndex],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAtIndex',
              lower: [],
              upper: [createdAtIndex],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterWhereClause>
      createdAtIndexGreaterThan(
    DateTime createdAtIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAtIndex',
        lower: [createdAtIndex],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterWhereClause>
      createdAtIndexLessThan(
    DateTime createdAtIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAtIndex',
        lower: [],
        upper: [createdAtIndex],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterWhereClause>
      createdAtIndexBetween(
    DateTime lowerCreatedAtIndex,
    DateTime upperCreatedAtIndex, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAtIndex',
        lower: [lowerCreatedAtIndex],
        includeLower: includeLower,
        upper: [upperCreatedAtIndex],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension InvoicePaymentModelQueryFilter on QueryBuilder<InvoicePaymentModel,
    InvoicePaymentModel, QFilterCondition> {
  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      amountEqualTo(
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      amountGreaterThan(
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      amountLessThan(
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      amountBetween(
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      createdAtIndexEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAtIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      createdAtIndexGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAtIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      createdAtIndexLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAtIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      createdAtIndexBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAtIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      createdByIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'createdById',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      createdByIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'createdById',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      createdByIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdById',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      createdByIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'createdById',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      idMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      invoiceIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'invoiceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      invoiceIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'invoiceId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      invoiceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'invoiceId',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      invoiceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'invoiceId',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      invoiceIdIndexEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'invoiceIdIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      invoiceIdIndexGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'invoiceIdIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      invoiceIdIndexLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'invoiceIdIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      invoiceIdIndexBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'invoiceIdIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      invoiceIdIndexStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'invoiceIdIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      invoiceIdIndexEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'invoiceIdIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      invoiceIdIndexContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'invoiceIdIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      invoiceIdIndexMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'invoiceIdIndex',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      invoiceIdIndexIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'invoiceIdIndex',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      invoiceIdIndexIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'invoiceIdIndex',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      notesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      notesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      organizationIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'organizationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      organizationIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'organizationId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      organizationIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'organizationId',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      organizationIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'organizationId',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      organizationIdIndexEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'organizationIdIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      organizationIdIndexGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'organizationIdIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      organizationIdIndexLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'organizationIdIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      organizationIdIndexBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'organizationIdIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      organizationIdIndexStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'organizationIdIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      organizationIdIndexEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'organizationIdIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      organizationIdIndexContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'organizationIdIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      organizationIdIndexMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'organizationIdIndex',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      organizationIdIndexIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'organizationIdIndex',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      organizationIdIndexIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'organizationIdIndex',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      paymentDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentDate',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      paymentDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paymentDate',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      paymentDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paymentDate',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      paymentDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paymentDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      paymentDateIndexEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentDateIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      paymentDateIndexGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paymentDateIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      paymentDateIndexLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paymentDateIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      paymentDateIndexBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paymentDateIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      paymentMethodEqualTo(PaymentMethod value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentMethod',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      paymentMethodGreaterThan(
    PaymentMethod value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paymentMethod',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      paymentMethodLessThan(
    PaymentMethod value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paymentMethod',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      paymentMethodBetween(
    PaymentMethod lower,
    PaymentMethod upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paymentMethod',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      referenceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'reference',
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      referenceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'reference',
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      referenceEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      referenceGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      referenceLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      referenceBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reference',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      referenceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'reference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      referenceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'reference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      referenceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'reference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      referenceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'reference',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      referenceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reference',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      referenceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'reference',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterFilterCondition>
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

extension InvoicePaymentModelQueryObject on QueryBuilder<InvoicePaymentModel,
    InvoicePaymentModel, QFilterCondition> {}

extension InvoicePaymentModelQueryLinks on QueryBuilder<InvoicePaymentModel,
    InvoicePaymentModel, QFilterCondition> {}

extension InvoicePaymentModelQuerySortBy
    on QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QSortBy> {
  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortByCreatedAtIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtIndex', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortByCreatedAtIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtIndex', Sort.desc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortByCreatedById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdById', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortByCreatedByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdById', Sort.desc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortByInvoiceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceId', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortByInvoiceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceId', Sort.desc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortByInvoiceIdIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceIdIndex', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortByInvoiceIdIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceIdIndex', Sort.desc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortByOrganizationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationId', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortByOrganizationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationId', Sort.desc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortByOrganizationIdIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationIdIndex', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortByOrganizationIdIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationIdIndex', Sort.desc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortByPaymentDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentDate', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortByPaymentDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentDate', Sort.desc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortByPaymentDateIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentDateIndex', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortByPaymentDateIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentDateIndex', Sort.desc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortByPaymentMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortByPaymentMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.desc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortByReference() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reference', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortByReferenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reference', Sort.desc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension InvoicePaymentModelQuerySortThenBy
    on QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QSortThenBy> {
  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByCreatedAtIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtIndex', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByCreatedAtIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtIndex', Sort.desc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByCreatedById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdById', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByCreatedByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdById', Sort.desc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByInvoiceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceId', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByInvoiceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceId', Sort.desc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByInvoiceIdIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceIdIndex', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByInvoiceIdIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceIdIndex', Sort.desc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByOrganizationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationId', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByOrganizationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationId', Sort.desc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByOrganizationIdIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationIdIndex', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByOrganizationIdIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationIdIndex', Sort.desc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByPaymentDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentDate', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByPaymentDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentDate', Sort.desc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByPaymentDateIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentDateIndex', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByPaymentDateIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentDateIndex', Sort.desc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByPaymentMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByPaymentMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.desc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByReference() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reference', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByReferenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reference', Sort.desc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension InvoicePaymentModelQueryWhereDistinct
    on QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QDistinct> {
  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QDistinct>
      distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QDistinct>
      distinctByCreatedAtIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAtIndex');
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QDistinct>
      distinctByCreatedById({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdById', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QDistinct>
      distinctById({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QDistinct>
      distinctByInvoiceId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'invoiceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QDistinct>
      distinctByInvoiceIdIndex({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'invoiceIdIndex',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QDistinct>
      distinctByNotes({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QDistinct>
      distinctByOrganizationId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'organizationId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QDistinct>
      distinctByOrganizationIdIndex({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'organizationIdIndex',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QDistinct>
      distinctByPaymentDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paymentDate');
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QDistinct>
      distinctByPaymentDateIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paymentDateIndex');
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QDistinct>
      distinctByPaymentMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paymentMethod');
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QDistinct>
      distinctByReference({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reference', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension InvoicePaymentModelQueryProperty
    on QueryBuilder<InvoicePaymentModel, InvoicePaymentModel, QQueryProperty> {
  QueryBuilder<InvoicePaymentModel, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<InvoicePaymentModel, double, QQueryOperations> amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<InvoicePaymentModel, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<InvoicePaymentModel, DateTime, QQueryOperations>
      createdAtIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAtIndex');
    });
  }

  QueryBuilder<InvoicePaymentModel, String, QQueryOperations>
      createdByIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdById');
    });
  }

  QueryBuilder<InvoicePaymentModel, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<InvoicePaymentModel, String, QQueryOperations>
      invoiceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'invoiceId');
    });
  }

  QueryBuilder<InvoicePaymentModel, String, QQueryOperations>
      invoiceIdIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'invoiceIdIndex');
    });
  }

  QueryBuilder<InvoicePaymentModel, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<InvoicePaymentModel, String, QQueryOperations>
      organizationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'organizationId');
    });
  }

  QueryBuilder<InvoicePaymentModel, String, QQueryOperations>
      organizationIdIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'organizationIdIndex');
    });
  }

  QueryBuilder<InvoicePaymentModel, DateTime, QQueryOperations>
      paymentDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paymentDate');
    });
  }

  QueryBuilder<InvoicePaymentModel, DateTime, QQueryOperations>
      paymentDateIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paymentDateIndex');
    });
  }

  QueryBuilder<InvoicePaymentModel, PaymentMethod, QQueryOperations>
      paymentMethodProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paymentMethod');
    });
  }

  QueryBuilder<InvoicePaymentModel, String?, QQueryOperations>
      referenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reference');
    });
  }

  QueryBuilder<InvoicePaymentModel, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
