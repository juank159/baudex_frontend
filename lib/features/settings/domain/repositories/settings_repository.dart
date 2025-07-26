// lib/features/settings/domain/repositories/settings_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/app_settings.dart';
import '../entities/invoice_settings.dart';
import '../entities/printer_settings.dart';

abstract class SettingsRepository {
  // App Settings
  Future<Either<Failure, AppSettings>> getAppSettings();
  Future<Either<Failure, AppSettings>> saveAppSettings(AppSettings settings);

  // Invoice Settings
  Future<Either<Failure, InvoiceSettings>> getInvoiceSettings();
  Future<Either<Failure, InvoiceSettings>> saveInvoiceSettings(InvoiceSettings settings);

  // Printer Settings
  Future<Either<Failure, List<PrinterSettings>>> getAllPrinterSettings();
  Future<Either<Failure, PrinterSettings?>> getDefaultPrinterSettings();
  Future<Either<Failure, PrinterSettings>> savePrinterSettings(PrinterSettings settings);
  Future<Either<Failure, void>> deletePrinterSettings(String settingsId);
  Future<Either<Failure, PrinterSettings>> setDefaultPrinter(String settingsId);
  Future<Either<Failure, bool>> testPrinterConnection(PrinterSettings settings);
}