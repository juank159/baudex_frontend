// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_settings_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetInvoiceSettingsModelCollection on Isar {
  IsarCollection<InvoiceSettingsModel> get invoiceSettingsModels =>
      this.collection();
}

const InvoiceSettingsModelSchema = CollectionSchema(
  name: r'InvoiceSettingsModel',
  id: -7414693431986390444,
  properties: {
    r'autoCalculateTax': PropertySchema(
      id: 0,
      name: r'autoCalculateTax',
      type: IsarType.bool,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'currencyFormat': PropertySchema(
      id: 2,
      name: r'currencyFormat',
      type: IsarType.string,
      enumMap: _InvoiceSettingsModelcurrencyFormatEnumValueMap,
    ),
    r'dateFormat': PropertySchema(
      id: 3,
      name: r'dateFormat',
      type: IsarType.string,
      enumMap: _InvoiceSettingsModeldateFormatEnumValueMap,
    ),
    r'defaultNotes': PropertySchema(
      id: 4,
      name: r'defaultNotes',
      type: IsarType.string,
    ),
    r'defaultTaxPercentage': PropertySchema(
      id: 5,
      name: r'defaultTaxPercentage',
      type: IsarType.double,
    ),
    r'defaultTermsAndConditions': PropertySchema(
      id: 6,
      name: r'defaultTermsAndConditions',
      type: IsarType.string,
    ),
    r'includeCompanyLogo': PropertySchema(
      id: 7,
      name: r'includeCompanyLogo',
      type: IsarType.bool,
    ),
    r'includeQrCode': PropertySchema(
      id: 8,
      name: r'includeQrCode',
      type: IsarType.bool,
    ),
    r'initialInvoiceNumber': PropertySchema(
      id: 9,
      name: r'initialInvoiceNumber',
      type: IsarType.long,
    ),
    r'invoicePrefix': PropertySchema(
      id: 10,
      name: r'invoicePrefix',
      type: IsarType.string,
    ),
    r'language': PropertySchema(
      id: 11,
      name: r'language',
      type: IsarType.string,
      enumMap: _InvoiceSettingsModellanguageEnumValueMap,
    ),
    r'numberFormat': PropertySchema(
      id: 12,
      name: r'numberFormat',
      type: IsarType.string,
      enumMap: _InvoiceSettingsModelnumberFormatEnumValueMap,
    ),
    r'paymentTermsDays': PropertySchema(
      id: 13,
      name: r'paymentTermsDays',
      type: IsarType.long,
    ),
    r'requireCustomerInfo': PropertySchema(
      id: 14,
      name: r'requireCustomerInfo',
      type: IsarType.bool,
    ),
    r'settingsId': PropertySchema(
      id: 15,
      name: r'settingsId',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 16,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _invoiceSettingsModelEstimateSize,
  serialize: _invoiceSettingsModelSerialize,
  deserialize: _invoiceSettingsModelDeserialize,
  deserializeProp: _invoiceSettingsModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'settingsId': IndexSchema(
      id: -4428449816366672166,
      name: r'settingsId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'settingsId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _invoiceSettingsModelGetId,
  getLinks: _invoiceSettingsModelGetLinks,
  attach: _invoiceSettingsModelAttach,
  version: '3.1.0+1',
);

int _invoiceSettingsModelEstimateSize(
  InvoiceSettingsModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.currencyFormat.name.length * 3;
  bytesCount += 3 + object.dateFormat.name.length * 3;
  bytesCount += 3 + object.defaultNotes.length * 3;
  bytesCount += 3 + object.defaultTermsAndConditions.length * 3;
  bytesCount += 3 + object.invoicePrefix.length * 3;
  bytesCount += 3 + object.language.name.length * 3;
  bytesCount += 3 + object.numberFormat.name.length * 3;
  bytesCount += 3 + object.settingsId.length * 3;
  return bytesCount;
}

void _invoiceSettingsModelSerialize(
  InvoiceSettingsModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.autoCalculateTax);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.currencyFormat.name);
  writer.writeString(offsets[3], object.dateFormat.name);
  writer.writeString(offsets[4], object.defaultNotes);
  writer.writeDouble(offsets[5], object.defaultTaxPercentage);
  writer.writeString(offsets[6], object.defaultTermsAndConditions);
  writer.writeBool(offsets[7], object.includeCompanyLogo);
  writer.writeBool(offsets[8], object.includeQrCode);
  writer.writeLong(offsets[9], object.initialInvoiceNumber);
  writer.writeString(offsets[10], object.invoicePrefix);
  writer.writeString(offsets[11], object.language.name);
  writer.writeString(offsets[12], object.numberFormat.name);
  writer.writeLong(offsets[13], object.paymentTermsDays);
  writer.writeBool(offsets[14], object.requireCustomerInfo);
  writer.writeString(offsets[15], object.settingsId);
  writer.writeDateTime(offsets[16], object.updatedAt);
}

InvoiceSettingsModel _invoiceSettingsModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = InvoiceSettingsModel();
  object.autoCalculateTax = reader.readBool(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.currencyFormat = _InvoiceSettingsModelcurrencyFormatValueEnumMap[
          reader.readStringOrNull(offsets[2])] ??
      CurrencyFormat.cop;
  object.dateFormat = _InvoiceSettingsModeldateFormatValueEnumMap[
          reader.readStringOrNull(offsets[3])] ??
      DateFormat.ddMMyyyy;
  object.defaultNotes = reader.readString(offsets[4]);
  object.defaultTaxPercentage = reader.readDouble(offsets[5]);
  object.defaultTermsAndConditions = reader.readString(offsets[6]);
  object.id = id;
  object.includeCompanyLogo = reader.readBool(offsets[7]);
  object.includeQrCode = reader.readBool(offsets[8]);
  object.initialInvoiceNumber = reader.readLong(offsets[9]);
  object.invoicePrefix = reader.readString(offsets[10]);
  object.language = _InvoiceSettingsModellanguageValueEnumMap[
          reader.readStringOrNull(offsets[11])] ??
      LanguageOption.spanish;
  object.numberFormat = _InvoiceSettingsModelnumberFormatValueEnumMap[
          reader.readStringOrNull(offsets[12])] ??
      InvoiceNumberFormat.sequential;
  object.paymentTermsDays = reader.readLong(offsets[13]);
  object.requireCustomerInfo = reader.readBool(offsets[14]);
  object.settingsId = reader.readString(offsets[15]);
  object.updatedAt = reader.readDateTime(offsets[16]);
  return object;
}

P _invoiceSettingsModelDeserializeProp<P>(
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
      return (_InvoiceSettingsModelcurrencyFormatValueEnumMap[
              reader.readStringOrNull(offset)] ??
          CurrencyFormat.cop) as P;
    case 3:
      return (_InvoiceSettingsModeldateFormatValueEnumMap[
              reader.readStringOrNull(offset)] ??
          DateFormat.ddMMyyyy) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (_InvoiceSettingsModellanguageValueEnumMap[
              reader.readStringOrNull(offset)] ??
          LanguageOption.spanish) as P;
    case 12:
      return (_InvoiceSettingsModelnumberFormatValueEnumMap[
              reader.readStringOrNull(offset)] ??
          InvoiceNumberFormat.sequential) as P;
    case 13:
      return (reader.readLong(offset)) as P;
    case 14:
      return (reader.readBool(offset)) as P;
    case 15:
      return (reader.readString(offset)) as P;
    case 16:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _InvoiceSettingsModelcurrencyFormatEnumValueMap = {
  r'cop': r'cop',
  r'usd': r'usd',
  r'eur': r'eur',
};
const _InvoiceSettingsModelcurrencyFormatValueEnumMap = {
  r'cop': CurrencyFormat.cop,
  r'usd': CurrencyFormat.usd,
  r'eur': CurrencyFormat.eur,
};
const _InvoiceSettingsModeldateFormatEnumValueMap = {
  r'ddMMyyyy': r'ddMMyyyy',
  r'mmDDyyyy': r'mmDDyyyy',
  r'yyyyMMdd': r'yyyyMMdd',
};
const _InvoiceSettingsModeldateFormatValueEnumMap = {
  r'ddMMyyyy': DateFormat.ddMMyyyy,
  r'mmDDyyyy': DateFormat.mmDDyyyy,
  r'yyyyMMdd': DateFormat.yyyyMMdd,
};
const _InvoiceSettingsModellanguageEnumValueMap = {
  r'spanish': r'spanish',
  r'english': r'english',
};
const _InvoiceSettingsModellanguageValueEnumMap = {
  r'spanish': LanguageOption.spanish,
  r'english': LanguageOption.english,
};
const _InvoiceSettingsModelnumberFormatEnumValueMap = {
  r'sequential': r'sequential',
  r'yearMonth': r'yearMonth',
  r'custom': r'custom',
};
const _InvoiceSettingsModelnumberFormatValueEnumMap = {
  r'sequential': InvoiceNumberFormat.sequential,
  r'yearMonth': InvoiceNumberFormat.yearMonth,
  r'custom': InvoiceNumberFormat.custom,
};

Id _invoiceSettingsModelGetId(InvoiceSettingsModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _invoiceSettingsModelGetLinks(
    InvoiceSettingsModel object) {
  return [];
}

void _invoiceSettingsModelAttach(
    IsarCollection<dynamic> col, Id id, InvoiceSettingsModel object) {
  object.id = id;
}

extension InvoiceSettingsModelByIndex on IsarCollection<InvoiceSettingsModel> {
  Future<InvoiceSettingsModel?> getBySettingsId(String settingsId) {
    return getByIndex(r'settingsId', [settingsId]);
  }

  InvoiceSettingsModel? getBySettingsIdSync(String settingsId) {
    return getByIndexSync(r'settingsId', [settingsId]);
  }

  Future<bool> deleteBySettingsId(String settingsId) {
    return deleteByIndex(r'settingsId', [settingsId]);
  }

  bool deleteBySettingsIdSync(String settingsId) {
    return deleteByIndexSync(r'settingsId', [settingsId]);
  }

  Future<List<InvoiceSettingsModel?>> getAllBySettingsId(
      List<String> settingsIdValues) {
    final values = settingsIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'settingsId', values);
  }

  List<InvoiceSettingsModel?> getAllBySettingsIdSync(
      List<String> settingsIdValues) {
    final values = settingsIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'settingsId', values);
  }

  Future<int> deleteAllBySettingsId(List<String> settingsIdValues) {
    final values = settingsIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'settingsId', values);
  }

  int deleteAllBySettingsIdSync(List<String> settingsIdValues) {
    final values = settingsIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'settingsId', values);
  }

  Future<Id> putBySettingsId(InvoiceSettingsModel object) {
    return putByIndex(r'settingsId', object);
  }

  Id putBySettingsIdSync(InvoiceSettingsModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'settingsId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySettingsId(List<InvoiceSettingsModel> objects) {
    return putAllByIndex(r'settingsId', objects);
  }

  List<Id> putAllBySettingsIdSync(List<InvoiceSettingsModel> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'settingsId', objects, saveLinks: saveLinks);
  }
}

extension InvoiceSettingsModelQueryWhereSort
    on QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QWhere> {
  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension InvoiceSettingsModelQueryWhere
    on QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QWhereClause> {
  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterWhereClause>
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

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterWhereClause>
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

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterWhereClause>
      settingsIdEqualTo(String settingsId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'settingsId',
        value: [settingsId],
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterWhereClause>
      settingsIdNotEqualTo(String settingsId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'settingsId',
              lower: [],
              upper: [settingsId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'settingsId',
              lower: [settingsId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'settingsId',
              lower: [settingsId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'settingsId',
              lower: [],
              upper: [settingsId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension InvoiceSettingsModelQueryFilter on QueryBuilder<InvoiceSettingsModel,
    InvoiceSettingsModel, QFilterCondition> {
  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> autoCalculateTaxEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'autoCalculateTax',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
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

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
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

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
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

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> currencyFormatEqualTo(
    CurrencyFormat value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currencyFormat',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> currencyFormatGreaterThan(
    CurrencyFormat value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currencyFormat',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> currencyFormatLessThan(
    CurrencyFormat value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currencyFormat',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> currencyFormatBetween(
    CurrencyFormat lower,
    CurrencyFormat upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currencyFormat',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> currencyFormatStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'currencyFormat',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> currencyFormatEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'currencyFormat',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
          QAfterFilterCondition>
      currencyFormatContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'currencyFormat',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
          QAfterFilterCondition>
      currencyFormatMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'currencyFormat',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> currencyFormatIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currencyFormat',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> currencyFormatIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'currencyFormat',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> dateFormatEqualTo(
    DateFormat value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateFormat',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> dateFormatGreaterThan(
    DateFormat value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dateFormat',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> dateFormatLessThan(
    DateFormat value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dateFormat',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> dateFormatBetween(
    DateFormat lower,
    DateFormat upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dateFormat',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> dateFormatStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dateFormat',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> dateFormatEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dateFormat',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
          QAfterFilterCondition>
      dateFormatContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dateFormat',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
          QAfterFilterCondition>
      dateFormatMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dateFormat',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> dateFormatIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateFormat',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> dateFormatIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dateFormat',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> defaultNotesEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'defaultNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> defaultNotesGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'defaultNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> defaultNotesLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'defaultNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> defaultNotesBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'defaultNotes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> defaultNotesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'defaultNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> defaultNotesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'defaultNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
          QAfterFilterCondition>
      defaultNotesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'defaultNotes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
          QAfterFilterCondition>
      defaultNotesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'defaultNotes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> defaultNotesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'defaultNotes',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> defaultNotesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'defaultNotes',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> defaultTaxPercentageEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'defaultTaxPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> defaultTaxPercentageGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'defaultTaxPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> defaultTaxPercentageLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'defaultTaxPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> defaultTaxPercentageBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'defaultTaxPercentage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> defaultTermsAndConditionsEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'defaultTermsAndConditions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> defaultTermsAndConditionsGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'defaultTermsAndConditions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> defaultTermsAndConditionsLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'defaultTermsAndConditions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> defaultTermsAndConditionsBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'defaultTermsAndConditions',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> defaultTermsAndConditionsStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'defaultTermsAndConditions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> defaultTermsAndConditionsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'defaultTermsAndConditions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
          QAfterFilterCondition>
      defaultTermsAndConditionsContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'defaultTermsAndConditions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
          QAfterFilterCondition>
      defaultTermsAndConditionsMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'defaultTermsAndConditions',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> defaultTermsAndConditionsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'defaultTermsAndConditions',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> defaultTermsAndConditionsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'defaultTermsAndConditions',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
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

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
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

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
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

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> includeCompanyLogoEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'includeCompanyLogo',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> includeQrCodeEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'includeQrCode',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> initialInvoiceNumberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'initialInvoiceNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> initialInvoiceNumberGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'initialInvoiceNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> initialInvoiceNumberLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'initialInvoiceNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> initialInvoiceNumberBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'initialInvoiceNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> invoicePrefixEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'invoicePrefix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> invoicePrefixGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'invoicePrefix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> invoicePrefixLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'invoicePrefix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> invoicePrefixBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'invoicePrefix',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> invoicePrefixStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'invoicePrefix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> invoicePrefixEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'invoicePrefix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
          QAfterFilterCondition>
      invoicePrefixContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'invoicePrefix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
          QAfterFilterCondition>
      invoicePrefixMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'invoicePrefix',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> invoicePrefixIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'invoicePrefix',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> invoicePrefixIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'invoicePrefix',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> languageEqualTo(
    LanguageOption value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'language',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> languageGreaterThan(
    LanguageOption value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'language',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> languageLessThan(
    LanguageOption value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'language',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> languageBetween(
    LanguageOption lower,
    LanguageOption upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'language',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> languageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'language',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> languageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'language',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
          QAfterFilterCondition>
      languageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'language',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
          QAfterFilterCondition>
      languageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'language',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> languageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'language',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> languageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'language',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> numberFormatEqualTo(
    InvoiceNumberFormat value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'numberFormat',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> numberFormatGreaterThan(
    InvoiceNumberFormat value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'numberFormat',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> numberFormatLessThan(
    InvoiceNumberFormat value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'numberFormat',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> numberFormatBetween(
    InvoiceNumberFormat lower,
    InvoiceNumberFormat upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'numberFormat',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> numberFormatStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'numberFormat',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> numberFormatEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'numberFormat',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
          QAfterFilterCondition>
      numberFormatContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'numberFormat',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
          QAfterFilterCondition>
      numberFormatMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'numberFormat',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> numberFormatIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'numberFormat',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> numberFormatIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'numberFormat',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> paymentTermsDaysEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentTermsDays',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> paymentTermsDaysGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paymentTermsDays',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> paymentTermsDaysLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paymentTermsDays',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> paymentTermsDaysBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paymentTermsDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> requireCustomerInfoEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'requireCustomerInfo',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> settingsIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'settingsId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> settingsIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'settingsId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> settingsIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'settingsId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> settingsIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'settingsId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> settingsIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'settingsId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> settingsIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'settingsId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
          QAfterFilterCondition>
      settingsIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'settingsId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
          QAfterFilterCondition>
      settingsIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'settingsId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> settingsIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'settingsId',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> settingsIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'settingsId',
        value: '',
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
      QAfterFilterCondition> updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
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

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
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

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel,
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

extension InvoiceSettingsModelQueryObject on QueryBuilder<InvoiceSettingsModel,
    InvoiceSettingsModel, QFilterCondition> {}

extension InvoiceSettingsModelQueryLinks on QueryBuilder<InvoiceSettingsModel,
    InvoiceSettingsModel, QFilterCondition> {}

extension InvoiceSettingsModelQuerySortBy
    on QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QSortBy> {
  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByAutoCalculateTax() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoCalculateTax', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByAutoCalculateTaxDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoCalculateTax', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByCurrencyFormat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currencyFormat', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByCurrencyFormatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currencyFormat', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByDateFormat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateFormat', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByDateFormatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateFormat', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByDefaultNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultNotes', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByDefaultNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultNotes', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByDefaultTaxPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultTaxPercentage', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByDefaultTaxPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultTaxPercentage', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByDefaultTermsAndConditions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultTermsAndConditions', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByDefaultTermsAndConditionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultTermsAndConditions', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByIncludeCompanyLogo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'includeCompanyLogo', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByIncludeCompanyLogoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'includeCompanyLogo', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByIncludeQrCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'includeQrCode', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByIncludeQrCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'includeQrCode', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByInitialInvoiceNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'initialInvoiceNumber', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByInitialInvoiceNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'initialInvoiceNumber', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByInvoicePrefix() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoicePrefix', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByInvoicePrefixDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoicePrefix', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByLanguage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'language', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByLanguageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'language', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByNumberFormat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numberFormat', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByNumberFormatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numberFormat', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByPaymentTermsDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentTermsDays', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByPaymentTermsDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentTermsDays', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByRequireCustomerInfo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requireCustomerInfo', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByRequireCustomerInfoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requireCustomerInfo', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortBySettingsId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'settingsId', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortBySettingsIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'settingsId', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension InvoiceSettingsModelQuerySortThenBy
    on QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QSortThenBy> {
  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByAutoCalculateTax() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoCalculateTax', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByAutoCalculateTaxDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoCalculateTax', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByCurrencyFormat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currencyFormat', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByCurrencyFormatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currencyFormat', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByDateFormat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateFormat', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByDateFormatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateFormat', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByDefaultNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultNotes', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByDefaultNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultNotes', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByDefaultTaxPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultTaxPercentage', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByDefaultTaxPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultTaxPercentage', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByDefaultTermsAndConditions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultTermsAndConditions', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByDefaultTermsAndConditionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultTermsAndConditions', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByIncludeCompanyLogo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'includeCompanyLogo', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByIncludeCompanyLogoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'includeCompanyLogo', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByIncludeQrCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'includeQrCode', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByIncludeQrCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'includeQrCode', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByInitialInvoiceNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'initialInvoiceNumber', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByInitialInvoiceNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'initialInvoiceNumber', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByInvoicePrefix() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoicePrefix', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByInvoicePrefixDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoicePrefix', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByLanguage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'language', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByLanguageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'language', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByNumberFormat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numberFormat', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByNumberFormatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numberFormat', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByPaymentTermsDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentTermsDays', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByPaymentTermsDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentTermsDays', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByRequireCustomerInfo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requireCustomerInfo', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByRequireCustomerInfoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requireCustomerInfo', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenBySettingsId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'settingsId', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenBySettingsIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'settingsId', Sort.desc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension InvoiceSettingsModelQueryWhereDistinct
    on QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QDistinct> {
  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QDistinct>
      distinctByAutoCalculateTax() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoCalculateTax');
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QDistinct>
      distinctByCurrencyFormat({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currencyFormat',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QDistinct>
      distinctByDateFormat({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateFormat', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QDistinct>
      distinctByDefaultNotes({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'defaultNotes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QDistinct>
      distinctByDefaultTaxPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'defaultTaxPercentage');
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QDistinct>
      distinctByDefaultTermsAndConditions({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'defaultTermsAndConditions',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QDistinct>
      distinctByIncludeCompanyLogo() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'includeCompanyLogo');
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QDistinct>
      distinctByIncludeQrCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'includeQrCode');
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QDistinct>
      distinctByInitialInvoiceNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'initialInvoiceNumber');
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QDistinct>
      distinctByInvoicePrefix({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'invoicePrefix',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QDistinct>
      distinctByLanguage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'language', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QDistinct>
      distinctByNumberFormat({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'numberFormat', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QDistinct>
      distinctByPaymentTermsDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paymentTermsDays');
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QDistinct>
      distinctByRequireCustomerInfo() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'requireCustomerInfo');
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QDistinct>
      distinctBySettingsId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'settingsId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceSettingsModel, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension InvoiceSettingsModelQueryProperty on QueryBuilder<
    InvoiceSettingsModel, InvoiceSettingsModel, QQueryProperty> {
  QueryBuilder<InvoiceSettingsModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<InvoiceSettingsModel, bool, QQueryOperations>
      autoCalculateTaxProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoCalculateTax');
    });
  }

  QueryBuilder<InvoiceSettingsModel, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<InvoiceSettingsModel, CurrencyFormat, QQueryOperations>
      currencyFormatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currencyFormat');
    });
  }

  QueryBuilder<InvoiceSettingsModel, DateFormat, QQueryOperations>
      dateFormatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateFormat');
    });
  }

  QueryBuilder<InvoiceSettingsModel, String, QQueryOperations>
      defaultNotesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'defaultNotes');
    });
  }

  QueryBuilder<InvoiceSettingsModel, double, QQueryOperations>
      defaultTaxPercentageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'defaultTaxPercentage');
    });
  }

  QueryBuilder<InvoiceSettingsModel, String, QQueryOperations>
      defaultTermsAndConditionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'defaultTermsAndConditions');
    });
  }

  QueryBuilder<InvoiceSettingsModel, bool, QQueryOperations>
      includeCompanyLogoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'includeCompanyLogo');
    });
  }

  QueryBuilder<InvoiceSettingsModel, bool, QQueryOperations>
      includeQrCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'includeQrCode');
    });
  }

  QueryBuilder<InvoiceSettingsModel, int, QQueryOperations>
      initialInvoiceNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'initialInvoiceNumber');
    });
  }

  QueryBuilder<InvoiceSettingsModel, String, QQueryOperations>
      invoicePrefixProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'invoicePrefix');
    });
  }

  QueryBuilder<InvoiceSettingsModel, LanguageOption, QQueryOperations>
      languageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'language');
    });
  }

  QueryBuilder<InvoiceSettingsModel, InvoiceNumberFormat, QQueryOperations>
      numberFormatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'numberFormat');
    });
  }

  QueryBuilder<InvoiceSettingsModel, int, QQueryOperations>
      paymentTermsDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paymentTermsDays');
    });
  }

  QueryBuilder<InvoiceSettingsModel, bool, QQueryOperations>
      requireCustomerInfoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'requireCustomerInfo');
    });
  }

  QueryBuilder<InvoiceSettingsModel, String, QQueryOperations>
      settingsIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'settingsId');
    });
  }

  QueryBuilder<InvoiceSettingsModel, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
