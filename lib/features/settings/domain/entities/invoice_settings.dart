// lib/features/settings/domain/entities/invoice_settings.dart
import 'package:equatable/equatable.dart';

enum InvoiceNumberFormat { sequential, yearMonth, custom }

enum CurrencyFormat { cop, usd, eur }

enum DateFormat { ddMMyyyy, mmDDyyyy, yyyyMMdd }

enum LanguageOption { spanish, english }

class InvoiceSettings extends Equatable {
  final String id;
  final String invoicePrefix;
  final int initialInvoiceNumber;
  final InvoiceNumberFormat numberFormat;
  final double defaultTaxPercentage;
  final CurrencyFormat currencyFormat;
  final DateFormat dateFormat;
  final LanguageOption language;
  final String defaultTermsAndConditions;
  final String defaultNotes;
  final bool includeQrCode;
  final bool includeCompanyLogo;
  final bool autoCalculateTax;
  final bool requireCustomerInfo;
  final int paymentTermsDays;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InvoiceSettings({
    required this.id,
    this.invoicePrefix = 'FACT-',
    this.initialInvoiceNumber = 1,
    this.numberFormat = InvoiceNumberFormat.sequential,
    this.defaultTaxPercentage = 19.0,
    this.currencyFormat = CurrencyFormat.cop,
    this.dateFormat = DateFormat.ddMMyyyy,
    this.language = LanguageOption.spanish,
    this.defaultTermsAndConditions = '',
    this.defaultNotes = '',
    this.includeQrCode = true,
    this.includeCompanyLogo = true,
    this.autoCalculateTax = true,
    this.requireCustomerInfo = false,
    this.paymentTermsDays = 30,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        invoicePrefix,
        initialInvoiceNumber,
        numberFormat,
        defaultTaxPercentage,
        currencyFormat,
        dateFormat,
        language,
        defaultTermsAndConditions,
        defaultNotes,
        includeQrCode,
        includeCompanyLogo,
        autoCalculateTax,
        requireCustomerInfo,
        paymentTermsDays,
        createdAt,
        updatedAt,
      ];

  InvoiceSettings copyWith({
    String? id,
    String? invoicePrefix,
    int? initialInvoiceNumber,
    InvoiceNumberFormat? numberFormat,
    double? defaultTaxPercentage,
    CurrencyFormat? currencyFormat,
    DateFormat? dateFormat,
    LanguageOption? language,
    String? defaultTermsAndConditions,
    String? defaultNotes,
    bool? includeQrCode,
    bool? includeCompanyLogo,
    bool? autoCalculateTax,
    bool? requireCustomerInfo,
    int? paymentTermsDays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvoiceSettings(
      id: id ?? this.id,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      initialInvoiceNumber: initialInvoiceNumber ?? this.initialInvoiceNumber,
      numberFormat: numberFormat ?? this.numberFormat,
      defaultTaxPercentage: defaultTaxPercentage ?? this.defaultTaxPercentage,
      currencyFormat: currencyFormat ?? this.currencyFormat,
      dateFormat: dateFormat ?? this.dateFormat,
      language: language ?? this.language,
      defaultTermsAndConditions: defaultTermsAndConditions ?? this.defaultTermsAndConditions,
      defaultNotes: defaultNotes ?? this.defaultNotes,
      includeQrCode: includeQrCode ?? this.includeQrCode,
      includeCompanyLogo: includeCompanyLogo ?? this.includeCompanyLogo,
      autoCalculateTax: autoCalculateTax ?? this.autoCalculateTax,
      requireCustomerInfo: requireCustomerInfo ?? this.requireCustomerInfo,
      paymentTermsDays: paymentTermsDays ?? this.paymentTermsDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get currencySymbol {
    switch (currencyFormat) {
      case CurrencyFormat.cop:
        return '\$';
      case CurrencyFormat.usd:
        return 'USD \$';
      case CurrencyFormat.eur:
        return '€';
    }
  }

  String get dateFormatPattern {
    switch (dateFormat) {
      case DateFormat.ddMMyyyy:
        return 'dd/MM/yyyy';
      case DateFormat.mmDDyyyy:
        return 'MM/dd/yyyy';
      case DateFormat.yyyyMMdd:
        return 'yyyy-MM-dd';
    }
  }

  String get languageCode {
    switch (language) {
      case LanguageOption.spanish:
        return 'es';
      case LanguageOption.english:
        return 'en';
    }
  }

  String generateInvoiceNumber(int currentNumber) {
    switch (numberFormat) {
      case InvoiceNumberFormat.sequential:
        return '$invoicePrefix$currentNumber';
      case InvoiceNumberFormat.yearMonth:
        final now = DateTime.now();
        final yearMonth = '${now.year}${now.month.toString().padLeft(2, '0')}';
        return '$invoicePrefix$yearMonth-$currentNumber';
      case InvoiceNumberFormat.custom:
        return '$invoicePrefix$currentNumber';
    }
  }

  factory InvoiceSettings.defaultSettings() {
    final now = DateTime.now();
    return InvoiceSettings(
      id: 'default',
      createdAt: now,
      updatedAt: now,
    );
  }
}