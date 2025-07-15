// lib/features/settings/data/repositories/settings_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/invoice_settings.dart';
import '../../domain/entities/printer_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource _localDataSource;

  SettingsRepositoryImpl({
    required SettingsLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  // ==================== APP SETTINGS ====================

  @override
  Future<Either<Failure, AppSettings>> getAppSettings() async {
    try {
      print('🏛️ SettingsRepository: Obteniendo configuración de app...');
      return await _localDataSource.getAppSettings();
    } catch (e) {
      print('❌ SettingsRepository: Error al obtener configuración de app: $e');
      return Left(CacheFailure('Error al obtener configuración de aplicación'));
    }
  }

  @override
  Future<Either<Failure, AppSettings>> saveAppSettings(AppSettings settings) async {
    try {
      print('🏛️ SettingsRepository: Guardando configuración de app...');
      
      // Actualizar timestamp
      final updatedSettings = settings.copyWith(updatedAt: DateTime.now());
      
      return await _localDataSource.saveAppSettings(updatedSettings);
    } catch (e) {
      print('❌ SettingsRepository: Error al guardar configuración de app: $e');
      return Left(CacheFailure('Error al guardar configuración de aplicación'));
    }
  }

  // ==================== INVOICE SETTINGS ====================

  @override
  Future<Either<Failure, InvoiceSettings>> getInvoiceSettings() async {
    try {
      print('🏛️ SettingsRepository: Obteniendo configuración de facturas...');
      return await _localDataSource.getInvoiceSettings();
    } catch (e) {
      print('❌ SettingsRepository: Error al obtener configuración de facturas: $e');
      return Left(CacheFailure('Error al obtener configuración de facturas'));
    }
  }

  @override
  Future<Either<Failure, InvoiceSettings>> saveInvoiceSettings(InvoiceSettings settings) async {
    try {
      print('🏛️ SettingsRepository: Guardando configuración de facturas...');
      
      // Actualizar timestamp
      final updatedSettings = settings.copyWith(updatedAt: DateTime.now());
      
      return await _localDataSource.saveInvoiceSettings(updatedSettings);
    } catch (e) {
      print('❌ SettingsRepository: Error al guardar configuración de facturas: $e');
      return Left(CacheFailure('Error al guardar configuración de facturas'));
    }
  }

  // ==================== PRINTER SETTINGS ====================

  @override
  Future<Either<Failure, List<PrinterSettings>>> getAllPrinterSettings() async {
    try {
      print('🏛️ SettingsRepository: Obteniendo todas las impresoras...');
      return await _localDataSource.getAllPrinterSettings();
    } catch (e) {
      print('❌ SettingsRepository: Error al obtener impresoras: $e');
      return Left(CacheFailure('Error al obtener configuración de impresoras'));
    }
  }

  @override
  Future<Either<Failure, PrinterSettings?>> getDefaultPrinterSettings() async {
    try {
      print('🏛️ SettingsRepository: Obteniendo impresora por defecto...');
      return await _localDataSource.getDefaultPrinterSettings();
    } catch (e) {
      print('❌ SettingsRepository: Error al obtener impresora por defecto: $e');
      return Left(CacheFailure('Error al obtener impresora por defecto'));
    }
  }

  @override
  Future<Either<Failure, PrinterSettings>> savePrinterSettings(PrinterSettings settings) async {
    try {
      print('🏛️ SettingsRepository: Guardando configuración de impresora: ${settings.name}');
      
      // Actualizar timestamp
      final updatedSettings = settings.copyWith(updatedAt: DateTime.now());
      
      return await _localDataSource.savePrinterSettings(updatedSettings);
    } catch (e) {
      print('❌ SettingsRepository: Error al guardar configuración de impresora: $e');
      return Left(CacheFailure('Error al guardar configuración de impresora'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePrinterSettings(String settingsId) async {
    try {
      print('🏛️ SettingsRepository: Eliminando impresora: $settingsId');
      return await _localDataSource.deletePrinterSettings(settingsId);
    } catch (e) {
      print('❌ SettingsRepository: Error al eliminar impresora: $e');
      return Left(CacheFailure('Error al eliminar configuración de impresora'));
    }
  }

  @override
  Future<Either<Failure, PrinterSettings>> setDefaultPrinter(String settingsId) async {
    try {
      print('🏛️ SettingsRepository: Estableciendo impresora por defecto: $settingsId');
      return await _localDataSource.setDefaultPrinter(settingsId);
    } catch (e) {
      print('❌ SettingsRepository: Error al establecer impresora por defecto: $e');
      return Left(CacheFailure('Error al establecer impresora por defecto'));
    }
  }

  @override
  Future<Either<Failure, bool>> testPrinterConnection(PrinterSettings settings) async {
    try {
      print('🏛️ SettingsRepository: Probando conexión con impresora: ${settings.name}');
      
      // TODO: Implementar lógica de prueba de conexión según el tipo
      if (settings.isNetworkPrinter) {
        return await _testNetworkPrinter(settings);
      } else {
        return await _testUsbPrinter(settings);
      }
    } catch (e) {
      print('❌ SettingsRepository: Error al probar conexión de impresora: $e');
      return Left(ServerFailure('Error al probar conexión de impresora'));
    }
  }

  Future<Either<Failure, bool>> _testNetworkPrinter(PrinterSettings settings) async {
    try {
      // Implementar prueba de conexión de red
      // Por ahora retornamos éxito simulado
      await Future.delayed(const Duration(seconds: 1));
      
      // Aquí puedes implementar un ping o conexión socket real
      print('🌐 SettingsRepository: Probando conexión de red a ${settings.connectionInfo}');
      
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure('No se pudo conectar a la impresora de red'));
    }
  }

  Future<Either<Failure, bool>> _testUsbPrinter(PrinterSettings settings) async {
    try {
      // Implementar prueba de conexión USB
      // Por ahora retornamos éxito simulado
      await Future.delayed(const Duration(milliseconds: 500));
      
      print('🔌 SettingsRepository: Probando conexión USB: ${settings.connectionInfo}');
      
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure('No se pudo conectar a la impresora USB'));
    }
  }
}