// lib/features/settings/data/datasources/settings_local_datasource.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../models/app_settings_model.dart';
import '../models/invoice_settings_model.dart';
import '../models/printer_settings_model.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/invoice_settings.dart';
import '../../domain/entities/printer_settings.dart';

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

// Implementación temporal usando valores por defecto
class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  @override
  Future<Either<Failure, AppSettings>> getAppSettings() async {
    return Right(AppSettings.defaultSettings());
  }

  @override
  Future<Either<Failure, AppSettings>> saveAppSettings(AppSettings settings) async {
    return Right(settings);
  }

  @override
  Future<Either<Failure, InvoiceSettings>> getInvoiceSettings() async {
    return Right(InvoiceSettings.defaultSettings());
  }

  @override
  Future<Either<Failure, InvoiceSettings>> saveInvoiceSettings(InvoiceSettings settings) async {
    return Right(settings);
  }

  @override
  Future<Either<Failure, List<PrinterSettings>>> getAllPrinterSettings() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, PrinterSettings?>> getDefaultPrinterSettings() async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, PrinterSettings>> savePrinterSettings(PrinterSettings settings) async {
    return Right(settings);
  }

  @override
  Future<Either<Failure, void>> deletePrinterSettings(String settingsId) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, PrinterSettings>> setDefaultPrinter(String settingsId) async {
    return Right(PrinterSettings.defaultSettings());
  }
}
