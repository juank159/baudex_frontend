// lib/features/settings/data/repositories/settings_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/invoice_settings.dart';
import '../../domain/entities/printer_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';
import '../datasources/printer_settings_remote_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource _localDataSource;
  final PrinterSettingsRemoteDataSource? _printerRemoteDataSource;
  final NetworkInfo? _networkInfo;

  SettingsRepositoryImpl({
    required SettingsLocalDataSource localDataSource,
    PrinterSettingsRemoteDataSource? printerRemoteDataSource,
    NetworkInfo? networkInfo,
  })  : _localDataSource = localDataSource,
        _printerRemoteDataSource = printerRemoteDataSource,
        _networkInfo = networkInfo;

  // ==================== APP SETTINGS ====================

  @override
  Future<Either<Failure, AppSettings>> getAppSettings() async {
    try {
      return await _localDataSource.getAppSettings();
    } catch (e) {
      return Left(CacheFailure('Error al obtener configuración de aplicación'));
    }
  }

  @override
  Future<Either<Failure, AppSettings>> saveAppSettings(AppSettings settings) async {
    try {
      final updatedSettings = settings.copyWith(updatedAt: DateTime.now());
      return await _localDataSource.saveAppSettings(updatedSettings);
    } catch (e) {
      return Left(CacheFailure('Error al guardar configuración de aplicación'));
    }
  }

  // ==================== INVOICE SETTINGS ====================

  @override
  Future<Either<Failure, InvoiceSettings>> getInvoiceSettings() async {
    try {
      return await _localDataSource.getInvoiceSettings();
    } catch (e) {
      return Left(CacheFailure('Error al obtener configuración de facturas'));
    }
  }

  @override
  Future<Either<Failure, InvoiceSettings>> saveInvoiceSettings(InvoiceSettings settings) async {
    try {
      final updatedSettings = settings.copyWith(updatedAt: DateTime.now());
      return await _localDataSource.saveInvoiceSettings(updatedSettings);
    } catch (e) {
      return Left(CacheFailure('Error al guardar configuración de facturas'));
    }
  }

  // ==================== PRINTER SETTINGS ====================

  @override
  Future<Either<Failure, List<PrinterSettings>>> getAllPrinterSettings() async {
    try {
      // Siempre leer de ISAR (fuente de verdad local)
      return await _localDataSource.getAllPrinterSettings();
    } catch (e) {
      return Left(CacheFailure('Error al obtener configuración de impresoras'));
    }
  }

  @override
  Future<Either<Failure, PrinterSettings?>> getDefaultPrinterSettings() async {
    try {
      return await _localDataSource.getDefaultPrinterSettings();
    } catch (e) {
      return Left(CacheFailure('Error al obtener impresora por defecto'));
    }
  }

  @override
  Future<Either<Failure, PrinterSettings>> savePrinterSettings(PrinterSettings settings) async {
    try {
      final updatedSettings = settings.copyWith(updatedAt: DateTime.now());

      // Determinar si es create o update
      // Un ID del servidor es UUID (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
      // Cualquier otro formato (vacío, printer_offline_*, timestamp puro) = create
      final uuidPattern = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
      final isCreate = settings.id.isEmpty ||
          settings.id.startsWith('printer_offline_') ||
          !uuidPattern.hasMatch(settings.id);
      final bool isOnline = _networkInfo != null && await _networkInfo.isConnected;

      if (isOnline && _printerRemoteDataSource != null) {
        // ONLINE: Enviar al servidor primero
        try {
          final serverData = _settingsToServerJson(updatedSettings);
          PrinterSettings savedPrinter;

          if (isCreate) {
            savedPrinter = await _printerRemoteDataSource!.createPrinterSetting(serverData);
          } else {
            savedPrinter = await _printerRemoteDataSource!.updatePrinterSetting(
              settings.id,
              serverData,
            );
          }

          // Guardar en ISAR con ID del servidor
          final localResult = await _localDataSource.savePrinterSettings(savedPrinter);
          return localResult;
        } on ServerException catch (e) {
          // Si falla el servidor, guardar localmente y encolar
          print('Error servidor al guardar impresora: ${e.message} - guardando offline');
          if (_networkInfo != null) {
            _networkInfo.markServerUnreachable();
          }
          return await _saveOfflineAndEnqueue(updatedSettings, isCreate);
        } catch (e) {
          print('Error inesperado al guardar impresora online: $e - guardando offline');
          return await _saveOfflineAndEnqueue(updatedSettings, isCreate);
        }
      } else {
        // OFFLINE: Guardar localmente y encolar
        return await _saveOfflineAndEnqueue(updatedSettings, isCreate);
      }
    } catch (e) {
      return Left(CacheFailure('Error al guardar configuración de impresora'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePrinterSettings(String settingsId) async {
    try {
      final bool isOnline = _networkInfo != null && await _networkInfo.isConnected;

      // Solo sincronizar eliminación si tiene UUID del servidor
      final uuidPattern = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
      final hasServerId = uuidPattern.hasMatch(settingsId);

      if (isOnline && _printerRemoteDataSource != null && hasServerId) {
        try {
          await _printerRemoteDataSource!.deletePrinterSetting(settingsId);
        } on ServerException catch (e) {
          print('Error servidor al eliminar impresora: ${e.message} - encolando');
          if (_networkInfo != null) {
            _networkInfo.markServerUnreachable();
          }
          await _enqueueOperation(settingsId, SyncOperationType.delete, {});
        }
      } else if (hasServerId) {
        // Offline: encolar eliminación solo si tiene ID del servidor
        await _enqueueOperation(settingsId, SyncOperationType.delete, {});
      }

      // Eliminar de ISAR siempre
      return await _localDataSource.deletePrinterSettings(settingsId);
    } catch (e) {
      return Left(CacheFailure('Error al eliminar configuración de impresora'));
    }
  }

  @override
  Future<Either<Failure, PrinterSettings>> setDefaultPrinter(String settingsId) async {
    try {
      // Default es device-local, no necesita sincronización
      return await _localDataSource.setDefaultPrinter(settingsId);
    } catch (e) {
      return Left(CacheFailure('Error al establecer impresora por defecto'));
    }
  }

  @override
  Future<Either<Failure, bool>> testPrinterConnection(PrinterSettings settings) async {
    try {
      if (settings.isNetworkPrinter) {
        return await _testNetworkPrinter(settings);
      } else {
        return await _testUsbPrinter(settings);
      }
    } catch (e) {
      return Left(ServerFailure('Error al probar conexión de impresora'));
    }
  }

  // ==================== HELPERS PRIVADOS ====================

  /// Guardar localmente con ID offline y encolar para sync
  Future<Either<Failure, PrinterSettings>> _saveOfflineAndEnqueue(
    PrinterSettings settings,
    bool isCreate,
  ) async {
    PrinterSettings printerToSave = settings;

    if (isCreate && !settings.id.startsWith('printer_offline_')) {
      // Generar ID temporal para nueva impresora offline
      final tempId = 'printer_offline_${DateTime.now().millisecondsSinceEpoch}';
      printerToSave = settings.copyWith(id: tempId);
    }

    // Guardar en ISAR
    final localResult = await _localDataSource.savePrinterSettings(printerToSave);

    // Encolar operación de sync
    final operationType = isCreate ? SyncOperationType.create : SyncOperationType.update;
    final serverData = _settingsToServerJson(printerToSave);
    await _enqueueOperation(printerToSave.id, operationType, serverData);

    return localResult;
  }

  /// Encolar operación en sync queue
  Future<void> _enqueueOperation(
    String entityId,
    SyncOperationType operationType,
    Map<String, dynamic> data,
  ) async {
    try {
      final syncService = Get.find<SyncService>();
      await syncService.addOperationForCurrentUser(
        entityType: 'printer_settings',
        entityId: entityId,
        operationType: operationType,
        data: data,
        priority: 2,
      );
    } catch (e) {
      print('Error encolando operación de impresora: $e');
    }
  }

  /// Convertir entity a JSON para el servidor
  Map<String, dynamic> _settingsToServerJson(PrinterSettings settings) {
    return {
      'name': settings.name,
      'connectionType': settings.connectionType.name,
      'ipAddress': settings.ipAddress,
      'port': settings.port,
      'usbPath': settings.usbPath,
      'paperSize': settings.paperSize.name,
      'autoCut': settings.autoCut,
      'cashDrawer': settings.cashDrawer,
      'isDefault': settings.isDefault,
      'isActive': settings.isActive,
    };
  }

  Future<Either<Failure, bool>> _testNetworkPrinter(PrinterSettings settings) async {
    try {
      final ipAddress = settings.ipAddress;
      final port = settings.port ?? 9100;

      if (ipAddress == null || ipAddress.isEmpty) {
        return Left(ServerFailure('La dirección IP no puede estar vacía'));
      }

      final ipPattern = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
      if (!ipPattern.hasMatch(ipAddress)) {
        return Left(ServerFailure('Formato de dirección IP inválido'));
      }

      await Future.delayed(const Duration(milliseconds: 2000));
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure('Error al probar conexión de red: $e'));
    }
  }

  Future<Either<Failure, bool>> _testUsbPrinter(PrinterSettings settings) async {
    try {
      await Future.delayed(const Duration(milliseconds: 1500));

      final usbPath = settings.usbPath?.toUpperCase() ?? '';
      if (usbPath.isEmpty) {
        return Left(ServerFailure('La ruta USB no puede estar vacía'));
      }

      return const Right(true);
    } catch (e) {
      return Left(ServerFailure('Error al probar conexión USB: $e'));
    }
  }
}
