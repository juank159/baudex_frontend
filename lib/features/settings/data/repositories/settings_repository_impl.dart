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
      print('🌐 SettingsRepository: Probando conexión de red a ${settings.connectionInfo}');
      
      final ipAddress = settings.ipAddress;
      final port = settings.port ?? 9100;
      
      if (ipAddress == null || ipAddress.isEmpty) {
        return Left(ServerFailure('La dirección IP no puede estar vacía'));
      }
      
      // Validar formato básico de IP
      final ipPattern = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
      if (!ipPattern.hasMatch(ipAddress)) {
        return Left(ServerFailure('Formato de dirección IP inválido'));
      }
      
      // Simular prueba de conexión de red con delay realista
      await Future.delayed(const Duration(milliseconds: 2000));
      
      // En una implementación real, aquí harías:
      // 1. Socket.connect(ipAddress, port) con timeout
      // 2. Enviar comando ESC/POS de prueba
      // 3. Verificar respuesta o timeout
      
      print('✅ SettingsRepository: Conexión de red simulada exitosa');
      return const Right(true);
      
    } catch (e) {
      return Left(ServerFailure('Error al probar conexión de red: $e'));
    }
  }

  Future<Either<Failure, bool>> _testUsbPrinter(PrinterSettings settings) async {
    try {
      print('🔌 SettingsRepository: Probando conexión USB: ${settings.connectionInfo}');
      
      // Simular prueba de conexión USB con delay más realista
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // En una implementación real, aquí intentarías:
      // 1. Verificar que el puerto USB existe
      // 2. Intentar abrir el puerto
      // 3. Enviar un comando de prueba (como ESC/POS test)
      // 4. Verificar respuesta
      
      final usbPath = settings.usbPath?.toUpperCase() ?? '';
      
      // Validar formato básico de ruta USB
      if (usbPath.isEmpty) {
        return Left(ServerFailure('La ruta USB no puede estar vacía'));
      }
      
      // Verificar patrones comunes de rutas USB en Windows
      final validUsbPatterns = [
        RegExp(r'^USB\d+$'),           // USB001, USB002, etc.
        RegExp(r'^COM\d+$'),           // COM1, COM2, etc.
        RegExp(r'^LPT\d+$'),           // LPT1, LPT2, etc.
        RegExp(r'^\\\\\.\\\w+\d*$'),   // \\.\USB001, \\.\COM1, etc.
        RegExp(r'^[\w\s\-]+$'),        // Nombres de impresora con espacios y guiones
      ];
      
      final isValidFormat = validUsbPatterns.any((pattern) => pattern.hasMatch(usbPath));
      
      if (!isValidFormat) {
        return Left(ServerFailure('Formato de ruta USB inválido. Use: USB001, COM1, LPT1, etc.'));
      }
      
      // Por ahora simulamos éxito para rutas con formato válido
      print('✅ SettingsRepository: Conexión USB simulada exitosa');
      return const Right(true);
      
    } catch (e) {
      return Left(ServerFailure('Error al probar conexión USB: $e'));
    }
  }
}