// lib/features/settings/data/models/invoice_settings_model.dart
import 'package:isar/isar.dart';
import '../../domain/entities/invoice_settings.dart';

part 'invoice_settings_model.g.dart';

@collection
class InvoiceSettingsModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String settingsId;
  late String invoicePrefix;
  late int initialInvoiceNumber;
  @Enumerated(EnumType.name)
  late InvoiceNumberFormat numberFormat;
  late double defaultTaxPercentage;
  @Enumerated(EnumType.name)
  late CurrencyFormat currencyFormat;
  @Enumerated(EnumType.name)
  late DateFormat dateFormat;
  @Enumerated(EnumType.name)
  late LanguageOption language;
  late String defaultTermsAndConditions;
  late String defaultNotes;
  late bool includeQrCode;
  late bool includeCompanyLogo;
  late bool autoCalculateTax;
  late bool requireCustomerInfo;
  late int paymentTermsDays;
  late DateTime createdAt;
  late DateTime updatedAt;

  InvoiceSettingsModel();

  InvoiceSettingsModel.fromEntity(InvoiceSettings entity) {
    settingsId = entity.id;
    invoicePrefix = entity.invoicePrefix;
    initialInvoiceNumber = entity.initialInvoiceNumber;
    numberFormat = entity.numberFormat;
    defaultTaxPercentage = entity.defaultTaxPercentage;
    currencyFormat = entity.currencyFormat;
    dateFormat = entity.dateFormat;
    language = entity.language;
    defaultTermsAndConditions = entity.defaultTermsAndConditions;
    defaultNotes = entity.defaultNotes;
    includeQrCode = entity.includeQrCode;
    includeCompanyLogo = entity.includeCompanyLogo;
    autoCalculateTax = entity.autoCalculateTax;
    requireCustomerInfo = entity.requireCustomerInfo;
    paymentTermsDays = entity.paymentTermsDays;
    createdAt = entity.createdAt;
    updatedAt = entity.updatedAt;
  }

  InvoiceSettings toEntity() {
    return InvoiceSettings(
      id: settingsId,
      invoicePrefix: invoicePrefix,
      initialInvoiceNumber: initialInvoiceNumber,
      numberFormat: numberFormat,
      defaultTaxPercentage: defaultTaxPercentage,
      currencyFormat: currencyFormat,
      dateFormat: dateFormat,
      language: language,
      defaultTermsAndConditions: defaultTermsAndConditions,
      defaultNotes: defaultNotes,
      includeQrCode: includeQrCode,
      includeCompanyLogo: includeCompanyLogo,
      autoCalculateTax: autoCalculateTax,
      requireCustomerInfo: requireCustomerInfo,
      paymentTermsDays: paymentTermsDays,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  void updateFromEntity(InvoiceSettings entity) {
    settingsId = entity.id;
    invoicePrefix = entity.invoicePrefix;
    initialInvoiceNumber = entity.initialInvoiceNumber;
    numberFormat = entity.numberFormat;
    defaultTaxPercentage = entity.defaultTaxPercentage;
    currencyFormat = entity.currencyFormat;
    dateFormat = entity.dateFormat;
    language = entity.language;
    defaultTermsAndConditions = entity.defaultTermsAndConditions;
    defaultNotes = entity.defaultNotes;
    includeQrCode = entity.includeQrCode;
    includeCompanyLogo = entity.includeCompanyLogo;
    autoCalculateTax = entity.autoCalculateTax;
    requireCustomerInfo = entity.requireCustomerInfo;
    paymentTermsDays = entity.paymentTermsDays;
    updatedAt = DateTime.now();
  }
}