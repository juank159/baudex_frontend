// lib/features/settings/data/datasources/settings_local_datasource.dart
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/core/errors/failures.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/invoice_settings.dart';
import '../../domain/entities/printer_settings.dart';
import '../models/printer_settings_model.dart';

abstract class SettingsLocalDataSource {
  Future<Either<Failure, AppSettings>> getAppSettings();
  Future<Either<Failure, AppSettings>> saveAppSettings(AppSettings settings);
  Future<Either<Failure, InvoiceSettings>> getInvoiceSettings();
  Future<Either<Failure, InvoiceSettings>> saveInvoiceSettings(InvoiceSettings settings);
  Future<Either<Failure, List<PrinterSettings>>> getAllPrinterSettings();
  Future<Either<Failure, PrinterSettings?>> getDefaultPrinterSettings();
  Future<Either<Failure, PrinterSettings>> savePrinterSettings(PrinterSettings settings);
  Future<Either<Failure, void>> deletePrinterSettings(String settingsId);
  Future<Either<Failure, PrinterSettings>> setDefaultPrinter(String settingsId);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  static const String _appSettingsKey = 'app_settings';
  static const String _invoiceSettingsKey = 'invoice_settings';
  static const String _defaultPrinterKey = 'default_printer_id';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ==================== APP SETTINGS ====================

  @override
  Future<Either<Failure, AppSettings>> getAppSettings() async {
    try {
      final prefs = await _preferences;
      final json = prefs.getString(_appSettingsKey);

      if (json == null || json.isEmpty) {
        return Right(AppSettings.defaultSettings());
      }

      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return Right(_appSettingsFromJson(decoded));
    } catch (e) {
      return Right(AppSettings.defaultSettings());
    }
  }

  @override
  Future<Either<Failure, AppSettings>> saveAppSettings(AppSettings settings) async {
    try {
      final prefs = await _preferences;
      final json = jsonEncode(_appSettingsToJson(settings));
      await prefs.setString(_appSettingsKey, json);
      return Right(settings);
    } catch (e) {
      return Left(CacheFailure('Error guardando configuración: ${e.toString()}'));
    }
  }

  AppSettings _appSettingsFromJson(Map<String, dynamic> json) {
    return AppSettings(
      id: json['id'] ?? 'default',
      themeMode: _parseThemeMode(json['themeMode']),
      language: _parseLanguage(json['language']),
      enableNotifications: json['enableNotifications'] ?? true,
      enableSounds: json['enableSounds'] ?? true,
      autoBackup: json['autoBackup'] ?? false,
      backupIntervalHours: json['backupIntervalHours'] ?? 24,
      debugMode: json['debugMode'] ?? false,
      companyName: json['companyName'] ?? '',
      companyAddress: json['companyAddress'] ?? '',
      companyPhone: json['companyPhone'] ?? '',
      companyEmail: json['companyEmail'] ?? '',
      companyTaxId: json['companyTaxId'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> _appSettingsToJson(AppSettings settings) {
    return {
      'id': settings.id,
      'themeMode': settings.themeMode.name,
      'language': settings.language.name,
      'enableNotifications': settings.enableNotifications,
      'enableSounds': settings.enableSounds,
      'autoBackup': settings.autoBackup,
      'backupIntervalHours': settings.backupIntervalHours,
      'debugMode': settings.debugMode,
      'companyName': settings.companyName,
      'companyAddress': settings.companyAddress,
      'companyPhone': settings.companyPhone,
      'companyEmail': settings.companyEmail,
      'companyTaxId': settings.companyTaxId,
      'createdAt': settings.createdAt.toIso8601String(),
      'updatedAt': settings.updatedAt.toIso8601String(),
    };
  }

  ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  AppLanguage _parseLanguage(String? value) {
    switch (value) {
      case 'english':
        return AppLanguage.english;
      default:
        return AppLanguage.spanish;
    }
  }

  // ==================== INVOICE SETTINGS ====================

  @override
  Future<Either<Failure, InvoiceSettings>> getInvoiceSettings() async {
    try {
      final prefs = await _preferences;
      final json = prefs.getString(_invoiceSettingsKey);

      if (json == null || json.isEmpty) {
        return Right(InvoiceSettings.defaultSettings());
      }

      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return Right(_invoiceSettingsFromJson(decoded));
    } catch (e) {
      return Right(InvoiceSettings.defaultSettings());
    }
  }

  @override
  Future<Either<Failure, InvoiceSettings>> saveInvoiceSettings(
    InvoiceSettings settings,
  ) async {
    try {
      final prefs = await _preferences;
      final json = jsonEncode(_invoiceSettingsToJson(settings));
      await prefs.setString(_invoiceSettingsKey, json);
      return Right(settings);
    } catch (e) {
      return Left(CacheFailure('Error guardando configuración de facturas: ${e.toString()}'));
    }
  }

  InvoiceSettings _invoiceSettingsFromJson(Map<String, dynamic> json) {
    return InvoiceSettings(
      id: json['id'] ?? 'default',
      invoicePrefix: json['invoicePrefix'] ?? 'FACT-',
      initialInvoiceNumber: json['initialInvoiceNumber'] ?? 1,
      numberFormat: _parseInvoiceNumberFormat(json['numberFormat']),
      defaultTaxPercentage: (json['defaultTaxPercentage'] ?? 19.0).toDouble(),
      currencyFormat: _parseCurrencyFormat(json['currencyFormat']),
      dateFormat: _parseDateFormat(json['dateFormat']),
      language: _parseLanguageOption(json['language']),
      defaultTermsAndConditions: json['defaultTermsAndConditions'] ?? '',
      defaultNotes: json['defaultNotes'] ?? '',
      includeQrCode: json['includeQrCode'] ?? true,
      includeCompanyLogo: json['includeCompanyLogo'] ?? true,
      autoCalculateTax: json['autoCalculateTax'] ?? true,
      requireCustomerInfo: json['requireCustomerInfo'] ?? false,
      paymentTermsDays: json['paymentTermsDays'] ?? 30,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> _invoiceSettingsToJson(InvoiceSettings settings) {
    return {
      'id': settings.id,
      'invoicePrefix': settings.invoicePrefix,
      'initialInvoiceNumber': settings.initialInvoiceNumber,
      'numberFormat': settings.numberFormat.name,
      'defaultTaxPercentage': settings.defaultTaxPercentage,
      'currencyFormat': settings.currencyFormat.name,
      'dateFormat': settings.dateFormat.name,
      'language': settings.language.name,
      'defaultTermsAndConditions': settings.defaultTermsAndConditions,
      'defaultNotes': settings.defaultNotes,
      'includeQrCode': settings.includeQrCode,
      'includeCompanyLogo': settings.includeCompanyLogo,
      'autoCalculateTax': settings.autoCalculateTax,
      'requireCustomerInfo': settings.requireCustomerInfo,
      'paymentTermsDays': settings.paymentTermsDays,
      'createdAt': settings.createdAt.toIso8601String(),
      'updatedAt': settings.updatedAt.toIso8601String(),
    };
  }

  InvoiceNumberFormat _parseInvoiceNumberFormat(String? value) {
    switch (value) {
      case 'yearMonth':
        return InvoiceNumberFormat.yearMonth;
      case 'custom':
        return InvoiceNumberFormat.custom;
      default:
        return InvoiceNumberFormat.sequential;
    }
  }

  CurrencyFormat _parseCurrencyFormat(String? value) {
    switch (value) {
      case 'usd':
        return CurrencyFormat.usd;
      case 'eur':
        return CurrencyFormat.eur;
      default:
        return CurrencyFormat.cop;
    }
  }

  DateFormat _parseDateFormat(String? value) {
    switch (value) {
      case 'mmDDyyyy':
        return DateFormat.mmDDyyyy;
      case 'yyyyMMdd':
        return DateFormat.yyyyMMdd;
      default:
        return DateFormat.ddMMyyyy;
    }
  }

  LanguageOption _parseLanguageOption(String? value) {
    switch (value) {
      case 'english':
        return LanguageOption.english;
      default:
        return LanguageOption.spanish;
    }
  }

  // ==================== PRINTER SETTINGS (ISAR) ====================

  Isar get _isar => IsarDatabase.instance.database;

  @override
  Future<Either<Failure, List<PrinterSettings>>> getAllPrinterSettings() async {
    try {
      final isarPrinters = await _isar.printerSettingsModels
          .filter()
          .deletedAtIsNull()
          .sortByIsDefaultDesc()
          .thenByName()
          .findAll();

      final printers = isarPrinters.map((m) => m.toEntity()).toList();
      return Right(printers);
    } catch (e) {
      print('Error obteniendo impresoras de ISAR: $e');
      return Right(<PrinterSettings>[]);
    }
  }

  @override
  Future<Either<Failure, PrinterSettings?>> getDefaultPrinterSettings() async {
    try {
      // Default es device-local (SharedPreferences)
      final prefs = await _preferences;
      final defaultId = prefs.getString(_defaultPrinterKey);

      if (defaultId == null || defaultId.isEmpty) {
        // Si no hay default local, buscar la marcada como default en ISAR
        final defaultPrinter = await _isar.printerSettingsModels
            .filter()
            .isDefaultEqualTo(true)
            .deletedAtIsNull()
            .findFirst();
        return Right(defaultPrinter?.toEntity());
      }

      // Buscar la impresora por serverId
      final printer = await _isar.printerSettingsModels
          .filter()
          .serverIdEqualTo(defaultId)
          .deletedAtIsNull()
          .findFirst();

      if (printer != null) {
        return Right(printer.toEntity());
      }

      // Fallback: primera impresora disponible
      final firstPrinter = await _isar.printerSettingsModels
          .filter()
          .deletedAtIsNull()
          .findFirst();
      return Right(firstPrinter?.toEntity());
    } catch (e) {
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, PrinterSettings>> savePrinterSettings(
    PrinterSettings settings,
  ) async {
    try {
      await _isar.writeTxn(() async {
        // Buscar si ya existe
        final existing = await _isar.printerSettingsModels
            .filter()
            .serverIdEqualTo(settings.id)
            .findFirst();

        if (existing != null) {
          existing.updateFromEntity(settings);
          existing.markAsUnsynced();
          await _isar.printerSettingsModels.put(existing);
        } else {
          final newModel = PrinterSettingsModel.fromEntity(settings);
          newModel.isSynced = false;
          await _isar.printerSettingsModels.put(newModel);
        }
      });

      // Si es default, guardar referencia device-local
      if (settings.isDefault) {
        final prefs = await _preferences;
        await prefs.setString(_defaultPrinterKey, settings.id);
      }

      return Right(settings);
    } catch (e) {
      return Left(CacheFailure('Error guardando impresora en ISAR: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePrinterSettings(String settingsId) async {
    try {
      await _isar.writeTxn(() async {
        final printer = await _isar.printerSettingsModels
            .filter()
            .serverIdEqualTo(settingsId)
            .findFirst();

        if (printer != null) {
          await _isar.printerSettingsModels.delete(printer.id);
        }
      });

      // Si era default, limpiar referencia
      final prefs = await _preferences;
      final defaultId = prefs.getString(_defaultPrinterKey);
      if (defaultId == settingsId) {
        await prefs.remove(_defaultPrinterKey);
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error eliminando impresora de ISAR: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PrinterSettings>> setDefaultPrinter(String settingsId) async {
    try {
      // Guardar referencia device-local (NO sincronizado)
      final prefs = await _preferences;
      await prefs.setString(_defaultPrinterKey, settingsId);

      // Buscar la impresora para retornarla
      final printer = await _isar.printerSettingsModels
          .filter()
          .serverIdEqualTo(settingsId)
          .deletedAtIsNull()
          .findFirst();

      if (printer == null) {
        return Left(CacheFailure('Impresora no encontrada'));
      }

      return Right(printer.toEntity().copyWith(isDefault: true));
    } catch (e) {
      return Left(CacheFailure('Error estableciendo impresora por defecto: ${e.toString()}'));
    }
  }
}
