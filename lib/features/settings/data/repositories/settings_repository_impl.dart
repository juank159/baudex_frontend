// lib/features/settings/data/repositories/settings_repository_impl.dart
import 'dart:async';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/printing/system_printer_discovery.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/invoice_settings.dart';
import '../../domain/entities/printer_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/rules/printer_rules.dart';
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
      var updatedSettings = settings.copyWith(updatedAt: DateTime.now());

      // Un id del servidor es un UUID; cualquier otro (vacío,
      // printer_offline_*) es una impresora que el servidor aún no tiene.
      final isCreate = !isServerPrinterId(settings.id);

      // La primera impresora de este equipo queda para facturar, aunque
      // el cajero no marque "predeterminada".
      if (!updatedSettings.isDefault && await _isOnlyPrinter(settings.id)) {
        updatedSettings = updatedSettings.copyWith(isDefault: true);
      }

      final bool isOnline = _networkInfo != null && await _networkInfo.isConnected;

      if (isOnline && _printerRemoteDataSource != null) {
        // ONLINE: Enviar al servidor primero
        try {
          final serverData = _settingsToServerJson(updatedSettings);
          PrinterSettings savedPrinter;

          if (isCreate) {
            savedPrinter = await _printerRemoteDataSource.createPrinterSetting(serverData);
          } else {
            savedPrinter = await _printerRemoteDataSource.updatePrinterSetting(
              settings.id,
              serverData,
            );
          }
          // La marca de predeterminada es de este equipo.
          savedPrinter = savedPrinter.copyWith(isDefault: updatedSettings.isDefault);

          final localResult = await _localDataSource.savePrinterSettings(savedPrinter);
          if (isCreate && settings.id.isNotEmpty) {
            // Era una impresora creada sin internet: ya subió con otro id.
            await _cancelPendingOperations(settings.id);
            await _localDataSource.deletePrinterSettings(settings.id);
            if (savedPrinter.isDefault) {
              await _localDataSource.setDefaultPrinter(savedPrinter.id);
            }
          }
          return localResult;
        } on ServerException catch (e) {
          final code = e.statusCode;
          if (isPrinterPermissionDenied(code)) {
            if (!isCreate) {
              return const Left(
                ServerFailure(
                  'No tienes permiso para cambiar esta impresora. '
                  'Pídele a un administrador que lo haga.',
                ),
              );
            }
            // El servidor no deja a este usuario guardar impresoras del
            // negocio: queda solo en este equipo, sin cola (el servidor
            // la rechazaría siempre).
            return await _saveOnThisDeviceOnly(updatedSettings);
          }
          if (code != null && code >= 400 && code < 500 &&
              code != 401 && code != 404 && code != 408 && code != 429) {
            if (isCreate) {
              // El servidor no la aceptó, pero la impresora es de este
              // equipo: se guarda aquí (como siempre se pudo) y sin cola,
              // porque el servidor la rechazaría cada vez.
              return await _saveOnThisDeviceOnly(updatedSettings);
            }
            final reason = cleanServerMessage(e.message);
            return Left(
              ServerFailure(
                reason.isEmpty
                    ? 'El servidor no aceptó los cambios de la impresora.'
                    : 'El servidor no aceptó los cambios: $reason',
              ),
            );
          }
          // Sin respuesta o error del servidor: guardar aquí y encolar.
          if (code == null || code >= 500) {
            _networkInfo.markServerUnreachable();
          }
          return await _saveOfflineAndEnqueue(updatedSettings, isCreate);
        } catch (e) {
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
      // Nunca subió al servidor: se cancela lo que tuviera en cola (si no,
      // al volver el internet se crearía y reaparecería) y se borra aquí.
      if (!isServerPrinterId(settingsId)) {
        await _cancelPendingOperations(settingsId);
        return await _localDataSource.deletePrinterSettings(settingsId);
      }

      final bool isOnline = _networkInfo != null && await _networkInfo.isConnected;
      var mustEnqueue = !isOnline || _printerRemoteDataSource == null;

      if (!mustEnqueue) {
        try {
          await _printerRemoteDataSource.deletePrinterSetting(settingsId);
        } on ServerException catch (e) {
          switch (classifyPrinterDeleteFailure(e.statusCode)) {
            case PrinterDeleteOutcome.alreadyGone:
              break; // El servidor ya no la tiene: hecho.
            case PrinterDeleteOutcome.rejected:
              // El servidor dijo que no: la impresora se queda.
              return Left(
                ServerFailure(
                  printerDeleteRejectionMessage(e.statusCode, e.message),
                  code: e.statusCode,
                ),
              );
            case PrinterDeleteOutcome.retryLater:
              if (e.statusCode == null || e.statusCode! >= 500) {
                _networkInfo.markServerUnreachable();
              }
              mustEnqueue = true;
          }
        }
      }

      if (mustEnqueue) {
        final queued = await _enqueueOperation(
          settingsId,
          SyncOperationType.delete,
          {},
        );
        if (!queued) {
          // Sin cola no se borra aquí: la próxima descarga la volvería a
          // traer y el servidor nunca se enteraría.
          return const Left(
            CacheFailure(
              'No se pudo eliminar la impresora en este momento. '
              'Inténtalo de nuevo cuando haya conexión.',
            ),
          );
        }
      }

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

  /// Encolar operación en sync queue. Devuelve false si no quedó en cola.
  Future<bool> _enqueueOperation(
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
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Quita de la cola lo pendiente de una impresora que aún no subió.
  Future<void> _cancelPendingOperations(String entityId) async {
    try {
      await Get.find<SyncService>().deleteSyncOperationsByEntityId(entityId);
    } catch (_) {}
  }

  /// No hay otra impresora guardada en este equipo aparte de [settingsId].
  Future<bool> _isOnlyPrinter(String settingsId) async {
    final all = await _localDataSource.getAllPrinterSettings();
    return all.fold(
      (_) => false,
      (printers) => printers.every((p) => p.id == settingsId),
    );
  }

  /// Guarda la impresora solo en este equipo, sin cola.
  Future<Either<Failure, PrinterSettings>> _saveOnThisDeviceOnly(
    PrinterSettings settings,
  ) async {
    var printer = settings;
    if (!printer.id.startsWith('printer_offline_')) {
      printer = printer.copyWith(
        id: 'printer_offline_${DateTime.now().millisecondsSinceEpoch}',
      );
    }
    await _cancelPendingOperations(printer.id);
    return _localDataSource.savePrinterSettings(printer);
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

      // Test real: intentar conexión TCP al puerto de la impresora
      try {
        final socket = await Socket.connect(
          ipAddress,
          port,
          timeout: const Duration(seconds: 5),
        );
        await socket.close();
        return const Right(true);
      } on SocketException catch (e) {
        return Left(ServerFailure(
          'No se pudo conectar a $ipAddress:$port - ${e.message}',
        ));
      } on TimeoutException {
        return Left(ServerFailure(
          'Timeout: La impresora en $ipAddress:$port no responde',
        ));
      }
    } catch (e) {
      return Left(ServerFailure('Error al probar conexión de red: $e'));
    }
  }

  Future<Either<Failure, bool>> _testUsbPrinter(PrinterSettings settings) async {
    try {
      final usbPath = settings.usbPath ?? '';
      if (usbPath.isEmpty) {
        return Left(ServerFailure('El nombre de impresora USB no puede estar vacío'));
      }

      // Test real: verificar que la impresora existe en el sistema
      if (Platform.isMacOS || Platform.isLinux) {
        final result = await Process.run('lpstat', ['-p', usbPath]);
        if (result.exitCode == 0) {
          final output = result.stdout.toString();
          if (output.contains('idle') || output.contains('enabled') || output.contains(usbPath)) {
            return const Right(true);
          }
          return Left(ServerFailure(
            'Impresora "$usbPath" encontrada pero no disponible: $output',
          ));
        } else {
          return Left(ServerFailure(
            'Impresora "$usbPath" no encontrada en el sistema',
          ));
        }
      } else if (Platform.isWindows) {
        final found = await discoverPrinters(defaultPrinterSources());
        if (containsPrinter(found.printers, usbPath)) {
          return const Right(true);
        }
        return Left(ServerFailure(
          'No encontramos la impresora "$usbPath" en este equipo. Revisa '
          'que esté instalada y que el nombre sea el mismo.',
        ));
      }

      return Left(ServerFailure('Plataforma no soportada para test USB'));
    } catch (e) {
      return Left(ServerFailure('Error al probar conexión USB: $e'));
    }
  }
}
