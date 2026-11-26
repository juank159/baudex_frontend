// lib/features/settings/data/datasources/settings_local_datasource.dart
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/storage/shared_prefs_repair.dart';
import '../../../../app/data/local/isar_database.dart';
import '../printer_diagnostics.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/invoice_settings.dart';
import '../../domain/entities/printer_settings.dart';
import '../../domain/rules/printer_rules.dart';
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

  SettingsLocalDataSourceImpl({Future<bool> Function()? repairPreferences})
    : _repairPreferences = repairPreferences ?? repairDevicePreferencesFile;

  /// Aparta el archivo de preferencias si está dañado (ver
  /// `shared_prefs_repair.dart`). Reemplazable en pruebas.
  final Future<bool> Function() _repairPreferences;

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
  //
  // La base local (Isar) es la verdad. Las preferencias del equipo solo
  // guardan "cuál elegí aquí" y son opcionales: en Windows ese archivo se
  // puede dañar (apagón mientras se escribe) y entonces cada lectura lanza
  // un error. Nada de impresoras puede fallar por eso: si las preferencias
  // no responden, manda la marca `isDefault` que queda en la base.

  Isar get _isar => IsarDatabase.instance.database;

  bool _repairTried = false;

  /// La impresora elegida en este equipo, o null si no hay o no se pudo leer.
  Future<String?> _deviceChoice() async {
    try {
      return (await _preferences).getString(_defaultPrinterKey);
    } catch (e, st) {
      if (await _tryRepairPreferences(e, st)) {
        try {
          return (await _preferences).getString(_defaultPrinterKey);
        } catch (_) {}
      }
      return null;
    }
  }

  /// Recuerda (o borra, con null) la elección de este equipo. Si las
  /// preferencias no responden no pasa nada: la marca queda en la base.
  Future<void> _rememberDeviceChoice(String? settingsId) async {
    Future<void> write() async {
      final prefs = await _preferences;
      if (settingsId == null) {
        await prefs.remove(_defaultPrinterKey);
      } else {
        await prefs.setString(_defaultPrinterKey, settingsId);
      }
    }

    try {
      await write();
    } catch (e, st) {
      if (await _tryRepairPreferences(e, st)) {
        try {
          await write();
        } catch (_) {}
      }
    }
  }

  /// Una sola vez por ejecución: deja constancia del fallo e intenta
  /// apartar el archivo dañado. Devuelve true si vale la pena reintentar.
  Future<bool> _tryRepairPreferences(Object error, StackTrace stack) async {
    if (_repairTried) return false;
    _repairTried = true;
    reportPrinterProblem('preferencias del equipo', error, stack);
    try {
      _prefs = null;
      return await _repairPreferences();
    } catch (_) {
      return false;
    }
  }

  /// Impresoras guardadas en este equipo y cuál usa para facturar.
  /// "Predeterminada" se calcula aquí (regla [pickBillingPrinter]): es una
  /// elección de este equipo, no la marca que viene del servidor.
  Future<({List<PrinterSettings> printers, PrinterSettings? billing})>
  _readPrinters() async {
    final isarPrinters =
        await _isar.printerSettingsModels.filter().deletedAtIsNull().findAll();
    final raw = isarPrinters.map((m) => m.toEntity()).toList();

    final chosen = pickBillingPrinter(
      raw,
      deviceChoiceId: await _deviceChoice(),
    );

    final printers =
        raw.map((p) => p.copyWith(isDefault: p.id == chosen?.id)).toList()
          ..sort((a, b) {
            if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
    return (
      printers: printers,
      billing: chosen?.copyWith(isDefault: true),
    );
  }

  @override
  Future<Either<Failure, List<PrinterSettings>>> getAllPrinterSettings() async {
    try {
      return Right((await _readPrinters()).printers);
    } catch (e, st) {
      reportPrinterProblem('cargar impresoras', e, st);
      return Left(
        CacheFailure('No se pudieron leer las impresoras: ${printerProblemDetail(e)}'),
      );
    }
  }

  @override
  Future<Either<Failure, PrinterSettings?>> getDefaultPrinterSettings() async {
    try {
      return Right((await _readPrinters()).billing);
    } catch (e, st) {
      reportPrinterProblem('cargar impresora predeterminada', e, st);
      return Left(
        CacheFailure('No se pudo leer la impresora: ${printerProblemDetail(e)}'),
      );
    }
  }

  /// Deja la marca de predeterminada solo en [settingsId]. No cambia
  /// `isSynced`: la marca es de este equipo. Tolerante a fallos: marcar no
  /// puede tumbar un guardado.
  Future<void> _markOnlyDefault(String settingsId) async {
    try {
      await _isar.writeTxn(() async {
        final all = await _isar.printerSettingsModels.where().findAll();
        final changed = <PrinterSettingsModel>[];
        for (final printer in all) {
          final shouldBe =
              printer.serverId == settingsId && printer.deletedAt == null;
          if (printer.isDefault != shouldBe) {
            printer.isDefault = shouldBe;
            changed.add(printer);
          }
        }
        if (changed.isNotEmpty) {
          await _isar.printerSettingsModels.putAll(changed);
        }
      });
    } catch (e, st) {
      reportPrinterProblem('marcar impresora predeterminada', e, st);
    }
  }

  @override
  Future<Either<Failure, PrinterSettings>> savePrinterSettings(
    PrinterSettings settings,
  ) async {
    // 1. Lo único que puede hacer fallar el guardado: escribir la fila.
    try {
      await _isar.writeTxn(() async {
        final existing = await _isar.printerSettingsModels
            .filter()
            .serverIdEqualTo(settings.id)
            .findFirst();

        if (existing != null) {
          existing.updateFromEntity(settings);
          // Si estaba borrada (restos de versiones anteriores), revive.
          existing.deletedAt = null;
          existing.markAsUnsynced();
          await _isar.printerSettingsModels.put(existing);
        } else {
          final newModel = PrinterSettingsModel.fromEntity(settings);
          newModel.isSynced = false;
          await _isar.printerSettingsModels.put(newModel);
        }
      });
    } catch (e, st) {
      reportPrinterProblem('guardar impresora', e, st);
      return Left(
        CacheFailure(
          'No se pudo guardar la impresora en este equipo: '
          '${printerProblemDetail(e)}',
        ),
      );
    }

    // 2. Predeterminada: aparte y sin poder tumbar lo ya guardado.
    if (settings.isDefault) {
      await _markOnlyDefault(settings.id);
      await _rememberDeviceChoice(settings.id);
    }

    return Right(settings);
  }

  @override
  Future<Either<Failure, void>> deletePrinterSettings(String settingsId) async {
    try {
      await _isar.writeTxn(() async {
        final rows = await _isar.printerSettingsModels
            .filter()
            .serverIdEqualTo(settingsId)
            .findAll();
        for (final row in rows) {
          if (isServerPrinterId(row.serverId)) {
            // El servidor la conoce: queda una marca de "eliminada aquí"
            // para que la próxima bajada no la vuelva a traer mientras el
            // servidor termina de enterarse (ver [mergeServerPrinters]).
            row
              ..deletedAt = DateTime.now()
              ..isDefault = false;
            await _isar.printerSettingsModels.put(row);
          } else {
            await _isar.printerSettingsModels.delete(row.id);
          }
        }
      });
    } catch (e, st) {
      reportPrinterProblem('eliminar impresora', e, st);
      return Left(
        CacheFailure(
          'No se pudo eliminar la impresora de este equipo: '
          '${printerProblemDetail(e)}',
        ),
      );
    }

    // Si era la elegida en este equipo, olvidarla (sin poder fallar).
    if (await _deviceChoice() == settingsId) {
      await _rememberDeviceChoice(null);
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, PrinterSettings>> setDefaultPrinter(String settingsId) async {
    try {
      final printer = await _isar.printerSettingsModels
          .filter()
          .serverIdEqualTo(settingsId)
          .deletedAtIsNull()
          .findFirst();

      if (printer == null) {
        return Left(CacheFailure('Impresora no encontrada'));
      }

      await _markOnlyDefault(settingsId);
      await _rememberDeviceChoice(settingsId);

      return Right(printer.toEntity().copyWith(isDefault: true));
    } catch (e, st) {
      reportPrinterProblem('elegir impresora predeterminada', e, st);
      return Left(
        CacheFailure(
          'No se pudo elegir la impresora: ${printerProblemDetail(e)}',
        ),
      );
    }
  }

  /// Cuánto se respeta una fila local reciente que el servidor aún no
  /// lista (recién creada, o la lista se pidió antes de crearla).
  static const Duration _recentGrace = Duration(minutes: 3);

  /// Deja la base local como el servidor después de una bajada, sin
  /// deshacer lo que se hizo en este equipo:
  ///  - una impresora eliminada aquí no revive aunque el servidor aún la
  ///    liste (bajada que se cruzó con el borrado, o borrado en cola);
  ///  - una fila con id del servidor que el servidor ya no tiene se quita
  ///    (eliminada en otro equipo, o restos);
  ///  - las creadas sin internet (`printer_offline_*`) no se tocan;
  ///  - la marca de predeterminada de este equipo se conserva.
  /// Devuelve cuántas quedaron visibles del servidor. Nunca lanza.
  Future<int> mergeServerPrinters(
    List<PrinterSettings> serverPrinters, {
    DateTime? now,
  }) async {
    try {
      final moment = now ?? DateTime.now();
      var visible = 0;
      await _isar.writeTxn(() async {
        final local = await _isar.printerSettingsModels.where().findAll();
        final byId = {for (final row in local) row.serverId: row};
        final onServer = <String>{};

        for (final printer in serverPrinters) {
          if (!isServerPrinterId(printer.id)) continue;
          onServer.add(printer.id);
          final existing = byId[printer.id];
          if (existing != null && existing.deletedAt != null) {
            continue; // eliminada aquí: no revive
          }
          if (existing == null) {
            await _isar.printerSettingsModels.put(
              PrinterSettingsModel.fromEntity(printer),
            );
          } else {
            final keepDefault = existing.isDefault;
            existing.updateFromEntity(printer);
            existing
              ..isDefault = keepDefault
              ..markAsSynced();
            await _isar.printerSettingsModels.put(existing);
          }
          visible++;
        }

        // Una respuesta vacía no basta para quitar las de este equipo (un
        // tropiezo del servidor dejaría la caja sin impresora): si de
        // verdad sobran, se eliminan a mano y el servidor responde "ya no
        // existe".
        if (onServer.isEmpty) {
          // Lo único que sí se limpia: marcas viejas de "eliminada aquí".
          for (final row in local) {
            final deletedAt = row.deletedAt;
            if (deletedAt != null &&
                moment.difference(deletedAt) > const Duration(minutes: 10)) {
              await _isar.printerSettingsModels.delete(row.id);
            }
          }
          return;
        }

        for (final row in local) {
          if (!isServerPrinterId(row.serverId)) continue;
          if (onServer.contains(row.serverId)) continue;
          // El servidor ya no la tiene.
          if (row.deletedAt != null) {
            await _isar.printerSettingsModels.delete(row.id); // marca cumplida
            continue;
          }
          final touched = row.updatedAt.isAfter(row.createdAt)
              ? row.updatedAt
              : row.createdAt;
          final last = row.lastSyncAt ?? touched;
          final newest = last.isAfter(touched) ? last : touched;
          if (moment.difference(newest) < _recentGrace) continue;
          await _isar.printerSettingsModels.delete(row.id);
        }
      });
      return visible;
    } catch (e, st) {
      reportPrinterProblem('aplicar impresoras del servidor', e, st);
      return 0;
    }
  }
}
