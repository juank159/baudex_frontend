// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'printer_settings_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPrinterSettingsModelCollection on Isar {
  IsarCollection<PrinterSettingsModel> get printerSettingsModels =>
      this.collection();
}

const PrinterSettingsModelSchema = CollectionSchema(
  name: r'PrinterSettingsModel',
  id: 5104961235230921518,
  properties: {
    r'autoCut': PropertySchema(
      id: 0,
      name: r'autoCut',
      type: IsarType.bool,
    ),
    r'cashDrawer': PropertySchema(
      id: 1,
      name: r'cashDrawer',
      type: IsarType.bool,
    ),
    r'connectionType': PropertySchema(
      id: 2,
      name: r'connectionType',
      type: IsarType.string,
      enumMap: _PrinterSettingsModelconnectionTypeEnumValueMap,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'ipAddress': PropertySchema(
      id: 4,
      name: r'ipAddress',
      type: IsarType.string,
    ),
    r'isActive': PropertySchema(
      id: 5,
      name: r'isActive',
      type: IsarType.bool,
    ),
    r'isDefault': PropertySchema(
      id: 6,
      name: r'isDefault',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(
      id: 7,
      name: r'name',
      type: IsarType.string,
    ),
    r'paperSize': PropertySchema(
      id: 8,
      name: r'paperSize',
      type: IsarType.string,
      enumMap: _PrinterSettingsModelpaperSizeEnumValueMap,
    ),
    r'port': PropertySchema(
      id: 9,
      name: r'port',
      type: IsarType.long,
    ),
    r'settingsId': PropertySchema(
      id: 10,
      name: r'settingsId',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 11,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'usbPath': PropertySchema(
      id: 12,
      name: r'usbPath',
      type: IsarType.string,
    )
  },
  estimateSize: _printerSettingsModelEstimateSize,
  serialize: _printerSettingsModelSerialize,
  deserialize: _printerSettingsModelDeserialize,
  deserializeProp: _printerSettingsModelDeserializeProp,
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
    ),
    r'isDefault': IndexSchema(
      id: -6569979013669400724,
      name: r'isDefault',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isDefault',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'isActive': IndexSchema(
      id: 8092228061260947457,
      name: r'isActive',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isActive',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _printerSettingsModelGetId,
  getLinks: _printerSettingsModelGetLinks,
  attach: _printerSettingsModelAttach,
  version: '3.1.0+1',
);

int _printerSettingsModelEstimateSize(
  PrinterSettingsModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.connectionType.name.length * 3;
  {
    final value = object.ipAddress;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.paperSize.name.length * 3;
  bytesCount += 3 + object.settingsId.length * 3;
  {
    final value = object.usbPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _printerSettingsModelSerialize(
  PrinterSettingsModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.autoCut);
  writer.writeBool(offsets[1], object.cashDrawer);
  writer.writeString(offsets[2], object.connectionType.name);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeString(offsets[4], object.ipAddress);
  writer.writeBool(offsets[5], object.isActive);
  writer.writeBool(offsets[6], object.isDefault);
  writer.writeString(offsets[7], object.name);
  writer.writeString(offsets[8], object.paperSize.name);
  writer.writeLong(offsets[9], object.port);
  writer.writeString(offsets[10], object.settingsId);
  writer.writeDateTime(offsets[11], object.updatedAt);
  writer.writeString(offsets[12], object.usbPath);
}

PrinterSettingsModel _printerSettingsModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PrinterSettingsModel();
  object.autoCut = reader.readBool(offsets[0]);
  object.cashDrawer = reader.readBool(offsets[1]);
  object.connectionType = _PrinterSettingsModelconnectionTypeValueEnumMap[
          reader.readStringOrNull(offsets[2])] ??
      PrinterConnectionType.usb;
  object.createdAt = reader.readDateTime(offsets[3]);
  object.id = id;
  object.ipAddress = reader.readStringOrNull(offsets[4]);
  object.isActive = reader.readBool(offsets[5]);
  object.isDefault = reader.readBool(offsets[6]);
  object.name = reader.readString(offsets[7]);
  object.paperSize = _PrinterSettingsModelpaperSizeValueEnumMap[
          reader.readStringOrNull(offsets[8])] ??
      PaperSize.mm58;
  object.port = reader.readLongOrNull(offsets[9]);
  object.settingsId = reader.readString(offsets[10]);
  object.updatedAt = reader.readDateTime(offsets[11]);
  object.usbPath = reader.readStringOrNull(offsets[12]);
  return object;
}

P _printerSettingsModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (_PrinterSettingsModelconnectionTypeValueEnumMap[
              reader.readStringOrNull(offset)] ??
          PrinterConnectionType.usb) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (_PrinterSettingsModelpaperSizeValueEnumMap[
              reader.readStringOrNull(offset)] ??
          PaperSize.mm58) as P;
    case 9:
      return (reader.readLongOrNull(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readDateTime(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _PrinterSettingsModelconnectionTypeEnumValueMap = {
  r'usb': r'usb',
  r'network': r'network',
};
const _PrinterSettingsModelconnectionTypeValueEnumMap = {
  r'usb': PrinterConnectionType.usb,
  r'network': PrinterConnectionType.network,
};
const _PrinterSettingsModelpaperSizeEnumValueMap = {
  r'mm58': r'mm58',
  r'mm80': r'mm80',
};
const _PrinterSettingsModelpaperSizeValueEnumMap = {
  r'mm58': PaperSize.mm58,
  r'mm80': PaperSize.mm80,
};

Id _printerSettingsModelGetId(PrinterSettingsModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _printerSettingsModelGetLinks(
    PrinterSettingsModel object) {
  return [];
}

void _printerSettingsModelAttach(
    IsarCollection<dynamic> col, Id id, PrinterSettingsModel object) {
  object.id = id;
}

extension PrinterSettingsModelByIndex on IsarCollection<PrinterSettingsModel> {
  Future<PrinterSettingsModel?> getBySettingsId(String settingsId) {
    return getByIndex(r'settingsId', [settingsId]);
  }

  PrinterSettingsModel? getBySettingsIdSync(String settingsId) {
    return getByIndexSync(r'settingsId', [settingsId]);
  }

  Future<bool> deleteBySettingsId(String settingsId) {
    return deleteByIndex(r'settingsId', [settingsId]);
  }

  bool deleteBySettingsIdSync(String settingsId) {
    return deleteByIndexSync(r'settingsId', [settingsId]);
  }

  Future<List<PrinterSettingsModel?>> getAllBySettingsId(
      List<String> settingsIdValues) {
    final values = settingsIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'settingsId', values);
  }

  List<PrinterSettingsModel?> getAllBySettingsIdSync(
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

  Future<Id> putBySettingsId(PrinterSettingsModel object) {
    return putByIndex(r'settingsId', object);
  }

  Id putBySettingsIdSync(PrinterSettingsModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'settingsId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySettingsId(List<PrinterSettingsModel> objects) {
    return putAllByIndex(r'settingsId', objects);
  }

  List<Id> putAllBySettingsIdSync(List<PrinterSettingsModel> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'settingsId', objects, saveLinks: saveLinks);
  }
}

extension PrinterSettingsModelQueryWhereSort
    on QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QWhere> {
  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterWhere>
      anyIsDefault() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isDefault'),
      );
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterWhere>
      anyIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isActive'),
      );
    });
  }
}

extension PrinterSettingsModelQueryWhere
    on QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QWhereClause> {
  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterWhereClause>
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

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterWhereClause>
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

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterWhereClause>
      settingsIdEqualTo(String settingsId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'settingsId',
        value: [settingsId],
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterWhereClause>
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

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterWhereClause>
      isDefaultEqualTo(bool isDefault) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isDefault',
        value: [isDefault],
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterWhereClause>
      isDefaultNotEqualTo(bool isDefault) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isDefault',
              lower: [],
              upper: [isDefault],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isDefault',
              lower: [isDefault],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isDefault',
              lower: [isDefault],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isDefault',
              lower: [],
              upper: [isDefault],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterWhereClause>
      isActiveEqualTo(bool isActive) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isActive',
        value: [isActive],
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterWhereClause>
      isActiveNotEqualTo(bool isActive) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isActive',
              lower: [],
              upper: [isActive],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isActive',
              lower: [isActive],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isActive',
              lower: [isActive],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isActive',
              lower: [],
              upper: [isActive],
              includeUpper: false,
            ));
      }
    });
  }
}

extension PrinterSettingsModelQueryFilter on QueryBuilder<PrinterSettingsModel,
    PrinterSettingsModel, QFilterCondition> {
  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> autoCutEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'autoCut',
        value: value,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> cashDrawerEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cashDrawer',
        value: value,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> connectionTypeEqualTo(
    PrinterConnectionType value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'connectionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> connectionTypeGreaterThan(
    PrinterConnectionType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'connectionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> connectionTypeLessThan(
    PrinterConnectionType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'connectionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> connectionTypeBetween(
    PrinterConnectionType lower,
    PrinterConnectionType upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'connectionType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> connectionTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'connectionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> connectionTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'connectionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
          QAfterFilterCondition>
      connectionTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'connectionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
          QAfterFilterCondition>
      connectionTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'connectionType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> connectionTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'connectionType',
        value: '',
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> connectionTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'connectionType',
        value: '',
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
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

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
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

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
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

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
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

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
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

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
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

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> ipAddressIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'ipAddress',
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> ipAddressIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'ipAddress',
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> ipAddressEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ipAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> ipAddressGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ipAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> ipAddressLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ipAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> ipAddressBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ipAddress',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> ipAddressStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ipAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> ipAddressEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ipAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
          QAfterFilterCondition>
      ipAddressContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ipAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
          QAfterFilterCondition>
      ipAddressMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ipAddress',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> ipAddressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ipAddress',
        value: '',
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> ipAddressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ipAddress',
        value: '',
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> isActiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isActive',
        value: value,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> isDefaultEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDefault',
        value: value,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> nameEqualTo(
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

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> nameGreaterThan(
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

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> nameLessThan(
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

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> nameBetween(
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

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> nameStartsWith(
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

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> nameEndsWith(
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

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
          QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
          QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> paperSizeEqualTo(
    PaperSize value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paperSize',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> paperSizeGreaterThan(
    PaperSize value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paperSize',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> paperSizeLessThan(
    PaperSize value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paperSize',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> paperSizeBetween(
    PaperSize lower,
    PaperSize upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paperSize',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> paperSizeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'paperSize',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> paperSizeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'paperSize',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
          QAfterFilterCondition>
      paperSizeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'paperSize',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
          QAfterFilterCondition>
      paperSizeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'paperSize',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> paperSizeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paperSize',
        value: '',
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> paperSizeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'paperSize',
        value: '',
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> portIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'port',
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> portIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'port',
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> portEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'port',
        value: value,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> portGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'port',
        value: value,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> portLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'port',
        value: value,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> portBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'port',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
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

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
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

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
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

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
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

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
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

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
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

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
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

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
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

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> settingsIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'settingsId',
        value: '',
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> settingsIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'settingsId',
        value: '',
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
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

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
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

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
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

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> usbPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'usbPath',
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> usbPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'usbPath',
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> usbPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'usbPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> usbPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'usbPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> usbPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'usbPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> usbPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'usbPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> usbPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'usbPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> usbPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'usbPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
          QAfterFilterCondition>
      usbPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'usbPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
          QAfterFilterCondition>
      usbPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'usbPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> usbPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'usbPath',
        value: '',
      ));
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel,
      QAfterFilterCondition> usbPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'usbPath',
        value: '',
      ));
    });
  }
}

extension PrinterSettingsModelQueryObject on QueryBuilder<PrinterSettingsModel,
    PrinterSettingsModel, QFilterCondition> {}

extension PrinterSettingsModelQueryLinks on QueryBuilder<PrinterSettingsModel,
    PrinterSettingsModel, QFilterCondition> {}

extension PrinterSettingsModelQuerySortBy
    on QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QSortBy> {
  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      sortByAutoCut() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoCut', Sort.asc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      sortByAutoCutDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoCut', Sort.desc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      sortByCashDrawer() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cashDrawer', Sort.asc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      sortByCashDrawerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cashDrawer', Sort.desc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      sortByConnectionType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'connectionType', Sort.asc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      sortByConnectionTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'connectionType', Sort.desc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      sortByIpAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ipAddress', Sort.asc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      sortByIpAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ipAddress', Sort.desc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      sortByIsDefault() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDefault', Sort.asc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      sortByIsDefaultDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDefault', Sort.desc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      sortByPaperSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paperSize', Sort.asc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      sortByPaperSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paperSize', Sort.desc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      sortByPort() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'port', Sort.asc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      sortByPortDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'port', Sort.desc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      sortBySettingsId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'settingsId', Sort.asc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      sortBySettingsIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'settingsId', Sort.desc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      sortByUsbPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usbPath', Sort.asc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      sortByUsbPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usbPath', Sort.desc);
    });
  }
}

extension PrinterSettingsModelQuerySortThenBy
    on QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QSortThenBy> {
  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      thenByAutoCut() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoCut', Sort.asc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      thenByAutoCutDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoCut', Sort.desc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      thenByCashDrawer() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cashDrawer', Sort.asc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      thenByCashDrawerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cashDrawer', Sort.desc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      thenByConnectionType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'connectionType', Sort.asc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      thenByConnectionTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'connectionType', Sort.desc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      thenByIpAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ipAddress', Sort.asc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      thenByIpAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ipAddress', Sort.desc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      thenByIsDefault() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDefault', Sort.asc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      thenByIsDefaultDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDefault', Sort.desc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      thenByPaperSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paperSize', Sort.asc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      thenByPaperSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paperSize', Sort.desc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      thenByPort() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'port', Sort.asc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      thenByPortDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'port', Sort.desc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      thenBySettingsId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'settingsId', Sort.asc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      thenBySettingsIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'settingsId', Sort.desc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      thenByUsbPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usbPath', Sort.asc);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QAfterSortBy>
      thenByUsbPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usbPath', Sort.desc);
    });
  }
}

extension PrinterSettingsModelQueryWhereDistinct
    on QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QDistinct> {
  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QDistinct>
      distinctByAutoCut() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoCut');
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QDistinct>
      distinctByCashDrawer() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cashDrawer');
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QDistinct>
      distinctByConnectionType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'connectionType',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QDistinct>
      distinctByIpAddress({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ipAddress', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QDistinct>
      distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActive');
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QDistinct>
      distinctByIsDefault() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDefault');
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QDistinct>
      distinctByName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QDistinct>
      distinctByPaperSize({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paperSize', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QDistinct>
      distinctByPort() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'port');
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QDistinct>
      distinctBySettingsId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'settingsId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterSettingsModel, QDistinct>
      distinctByUsbPath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'usbPath', caseSensitive: caseSensitive);
    });
  }
}

extension PrinterSettingsModelQueryProperty on QueryBuilder<
    PrinterSettingsModel, PrinterSettingsModel, QQueryProperty> {
  QueryBuilder<PrinterSettingsModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PrinterSettingsModel, bool, QQueryOperations> autoCutProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoCut');
    });
  }

  QueryBuilder<PrinterSettingsModel, bool, QQueryOperations>
      cashDrawerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cashDrawer');
    });
  }

  QueryBuilder<PrinterSettingsModel, PrinterConnectionType, QQueryOperations>
      connectionTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'connectionType');
    });
  }

  QueryBuilder<PrinterSettingsModel, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<PrinterSettingsModel, String?, QQueryOperations>
      ipAddressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ipAddress');
    });
  }

  QueryBuilder<PrinterSettingsModel, bool, QQueryOperations>
      isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActive');
    });
  }

  QueryBuilder<PrinterSettingsModel, bool, QQueryOperations>
      isDefaultProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDefault');
    });
  }

  QueryBuilder<PrinterSettingsModel, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<PrinterSettingsModel, PaperSize, QQueryOperations>
      paperSizeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paperSize');
    });
  }

  QueryBuilder<PrinterSettingsModel, int?, QQueryOperations> portProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'port');
    });
  }

  QueryBuilder<PrinterSettingsModel, String, QQueryOperations>
      settingsIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'settingsId');
    });
  }

  QueryBuilder<PrinterSettingsModel, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<PrinterSettingsModel, String?, QQueryOperations>
      usbPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'usbPath');
    });
  }
}
