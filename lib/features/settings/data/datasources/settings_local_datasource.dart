// lib/features/settings/data/datasources/settings_local_datasource.dart
import 'package:dartz/dartz.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/database/isar_service.dart';
import '../../../../app/core/errors/failures.dart';
import '../models/app_settings_model.dart';
import '../models/invoice_settings_model.dart';
import '../models/printer_settings_model.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/invoice_settings.dart';
import '../../domain/entities/printer_settings.dart';

abstract class SettingsLocalDataSource {
  // App Settings
  Future<Either<Failure, AppSettings>> getAppSettings();
  Future<Either<Failure, AppSettings>> saveAppSettings(AppSettings settings);

  // Invoice Settings
  Future<Either<Failure, InvoiceSettings>> getInvoiceSettings();
  Future<Either<Failure, InvoiceSettings>> saveInvoiceSettings(
    InvoiceSettings settings,
  );

  // Printer Settings
  Future<Either<Failure, List<PrinterSettings>>> getAllPrinterSettings();
  Future<Either<Failure, PrinterSettings?>> getDefaultPrinterSettings();
  Future<Either<Failure, PrinterSettings>> savePrinterSettings(
    PrinterSettings settings,
  );
  Future<Either<Failure, void>> deletePrinterSettings(String settingsId);
  Future<Either<Failure, PrinterSettings>> setDefaultPrinter(String settingsId);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final IsarService _isarService;

  SettingsLocalDataSourceImpl({required IsarService isarService})
    : _isarService = isarService;

  // ==================== APP SETTINGS ====================

  @override
  Future<Either<Failure, AppSettings>> getAppSettings() async {
    try {
      print('📱 SettingsLocalDataSource: Obteniendo configuración de app...');

      final isar = await _isarService.database;
      final model = await isar.appSettingsModels.getBySettingsId('default');

      if (model != null) {
        print('✅ SettingsLocalDataSource: Configuración de app encontrada');
        return Right(model.toEntity());
      } else {
        print(
          '⚠️ SettingsLocalDataSource: No se encontró configuración, creando por defecto',
        );
        final defaultSettings = AppSettings.defaultSettings();
        return await saveAppSettings(defaultSettings);
      }
    } catch (e) {
      print(
        '❌ SettingsLocalDataSource: Error al obtener configuración de app: $e',
      );
      return Left(
        CacheFailure('Error al obtener configuración de aplicación: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, AppSettings>> saveAppSettings(
    AppSettings settings,
  ) async {
    try {
      print('💾 SettingsLocalDataSource: Guardando configuración de app...');

      final isar = await _isarService.database;

      await isar.writeTxn(() async {
        // Buscar configuración existente
        final existingModel = await isar.appSettingsModels.getBySettingsId(
          settings.id,
        );

        if (existingModel != null) {
          // Actualizar existente
          existingModel.updateFromEntity(settings);
          await isar.appSettingsModels.put(existingModel);
        } else {
          // Crear nueva
          final newModel = AppSettingsModel.fromEntity(settings);
          await isar.appSettingsModels.put(newModel);
        }
      });

      print(
        '✅ SettingsLocalDataSource: Configuración de app guardada exitosamente',
      );
      return Right(settings);
    } catch (e) {
      print(
        '❌ SettingsLocalDataSource: Error al guardar configuración de app: $e',
      );
      return Left(
        CacheFailure('Error al guardar configuración de aplicación: $e'),
      );
    }
  }

  // ==================== INVOICE SETTINGS ====================

  @override
  Future<Either<Failure, InvoiceSettings>> getInvoiceSettings() async {
    try {
      print(
        '🧾 SettingsLocalDataSource: Obteniendo configuración de facturas...',
      );

      final isar = await _isarService.database;
      final model = await isar.invoiceSettingsModels.getBySettingsId('default');

      if (model != null) {
        print(
          '✅ SettingsLocalDataSource: Configuración de facturas encontrada',
        );
        return Right(model.toEntity());
      } else {
        print(
          '⚠️ SettingsLocalDataSource: No se encontró configuración, creando por defecto',
        );
        final defaultSettings = InvoiceSettings.defaultSettings();
        return await saveInvoiceSettings(defaultSettings);
      }
    } catch (e) {
      print(
        '❌ SettingsLocalDataSource: Error al obtener configuración de facturas: $e',
      );
      return Left(
        CacheFailure('Error al obtener configuración de facturas: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, InvoiceSettings>> saveInvoiceSettings(
    InvoiceSettings settings,
  ) async {
    try {
      print(
        '💾 SettingsLocalDataSource: Guardando configuración de facturas...',
      );

      final isar = await _isarService.database;

      await isar.writeTxn(() async {
        // Buscar configuración existente
        final existingModel = await isar.invoiceSettingsModels.getBySettingsId(
          settings.id,
        );

        if (existingModel != null) {
          // Actualizar existente
          existingModel.updateFromEntity(settings);
          await isar.invoiceSettingsModels.put(existingModel);
        } else {
          // Crear nueva
          final newModel = InvoiceSettingsModel.fromEntity(settings);
          await isar.invoiceSettingsModels.put(newModel);
        }
      });

      print(
        '✅ SettingsLocalDataSource: Configuración de facturas guardada exitosamente',
      );
      return Right(settings);
    } catch (e) {
      print(
        '❌ SettingsLocalDataSource: Error al guardar configuración de facturas: $e',
      );
      return Left(
        CacheFailure('Error al guardar configuración de facturas: $e'),
      );
    }
  }

  // ==================== PRINTER SETTINGS ====================

  @override
  Future<Either<Failure, List<PrinterSettings>>> getAllPrinterSettings() async {
    try {
      print('🖨️ SettingsLocalDataSource: Obteniendo todas las impresoras...');

      final isar = await _isarService.database;
      final models =
          await isar.printerSettingsModels
              .filter()
              .isActiveEqualTo(true)
              .findAll();

      final printers = models.map((model) => model.toEntity()).toList();

      print(
        '✅ SettingsLocalDataSource: ${printers.length} impresoras encontradas',
      );
      return Right(printers);
    } catch (e) {
      print('❌ SettingsLocalDataSource: Error al obtener impresoras: $e');
      return Left(
        CacheFailure('Error al obtener configuración de impresoras: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, PrinterSettings?>> getDefaultPrinterSettings() async {
    try {
      print('🖨️ SettingsLocalDataSource: Obteniendo impresora por defecto...');

      final isar = await _isarService.database;
      final model =
          await isar.printerSettingsModels
              .filter()
              .isActiveEqualTo(true)
              .and()
              .isDefaultEqualTo(true)
              .findFirst();

      if (model != null) {
        print(
          '✅ SettingsLocalDataSource: Impresora por defecto encontrada: ${model.name}',
        );
        return Right(model.toEntity());
      } else {
        print(
          '⚠️ SettingsLocalDataSource: No se encontró impresora por defecto',
        );
        return const Right(null);
      }
    } catch (e) {
      print(
        '❌ SettingsLocalDataSource: Error al obtener impresora por defecto: $e',
      );
      return Left(CacheFailure('Error al obtener impresora por defecto: $e'));
    }
  }

  @override
  Future<Either<Failure, PrinterSettings>> savePrinterSettings(
    PrinterSettings settings,
  ) async {
    try {
      print(
        '💾 SettingsLocalDataSource: Guardando configuración de impresora: ${settings.name}',
      );

      final isar = await _isarService.database;

      await isar.writeTxn(() async {
        // Si esta impresora se marca como default, quitar default de otras
        if (settings.isDefault) {
          final existingDefaults =
              await isar.printerSettingsModels
                  .filter()
                  .isActiveEqualTo(true)
                  .and()
                  .isDefaultEqualTo(true)
                  .findAll();

          for (final existing in existingDefaults) {
            existing.isDefault = false;
            await isar.printerSettingsModels.put(existing);
          }
        }

        // Buscar configuración existente por settingsId
        final existingModel = await isar.printerSettingsModels.getBySettingsId(
          settings.id,
        );

        if (existingModel != null) {
          // Actualizar existente
          existingModel.updateFromEntity(settings);
          await isar.printerSettingsModels.put(existingModel);
        } else {
          // Crear nueva
          final newModel = PrinterSettingsModel.fromEntity(settings);
          await isar.printerSettingsModels.put(newModel);
        }
      });

      print(
        '✅ SettingsLocalDataSource: Configuración de impresora guardada exitosamente',
      );
      return Right(settings);
    } catch (e) {
      print(
        '❌ SettingsLocalDataSource: Error al guardar configuración de impresora: $e',
      );
      return Left(
        CacheFailure('Error al guardar configuración de impresora: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deletePrinterSettings(String settingsId) async {
    try {
      print('🗑️ SettingsLocalDataSource: Eliminando impresora: $settingsId');

      final isar = await _isarService.database;

      await isar.writeTxn(() async {
        final model = await isar.printerSettingsModels.getBySettingsId(
          settingsId,
        );

        if (model != null) {
          // Marcar como inactiva en lugar de eliminar
          model.isActive = false;
          model.isDefault = false;
          await isar.printerSettingsModels.put(model);
        }
      });

      print('✅ SettingsLocalDataSource: Impresora eliminada exitosamente');
      return const Right(null);
    } catch (e) {
      print('❌ SettingsLocalDataSource: Error al eliminar impresora: $e');
      return Left(
        CacheFailure('Error al eliminar configuración de impresora: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, PrinterSettings>> setDefaultPrinter(
    String settingsId,
  ) async {
    try {
      print(
        '⭐ SettingsLocalDataSource: Estableciendo impresora por defecto: $settingsId',
      );

      final isar = await _isarService.database;
      PrinterSettings? updatedPrinter;

      await isar.writeTxn(() async {
        // Quitar default de todas las impresoras
        final allPrinters =
            await isar.printerSettingsModels
                .filter()
                .isActiveEqualTo(true)
                .findAll();

        for (final printer in allPrinters) {
          printer.isDefault = printer.settingsId == settingsId;
          if (printer.settingsId == settingsId) {
            updatedPrinter = printer.toEntity();
          }
          await isar.printerSettingsModels.put(printer);
        }
      });

      if (updatedPrinter != null) {
        print(
          '✅ SettingsLocalDataSource: Impresora por defecto establecida exitosamente',
        );
        return Right(updatedPrinter!);
      } else {
        return Left(CacheFailure('No se encontró la impresora especificada'));
      }
    } catch (e) {
      print(
        '❌ SettingsLocalDataSource: Error al establecer impresora por defecto: $e',
      );
      return Left(
        CacheFailure('Error al establecer impresora por defecto: $e'),
      );
    }
  }
}
