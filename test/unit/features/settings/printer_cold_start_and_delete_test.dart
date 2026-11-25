// Reproduce lo que reportó el cliente en Windows (1.0.7):
//  1. Tras apagar y prender, la factura dice "No hay impresora configurada"
//     aunque la impresora sigue guardada.
//  2. Eliminar una impresora deja cosas mal (cola, servidor, memoria).
//
// Todo corre con el controlador, el repositorio y la base local reales,
// sobre una base Isar temporal y preferencias de mentira. No toca la base
// del equipo, ni el llavero, ni el servidor.
import 'dart:async';
import 'dart:io';

import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/app/data/local/sync_service.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/thermal_printer_controller.dart';
import 'package:baudex_desktop/features/settings/data/datasources/printer_settings_remote_datasource.dart';
import 'package:baudex_desktop/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:baudex_desktop/features/settings/data/models/printer_settings_model.dart';
import 'package:baudex_desktop/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:baudex_desktop/features/settings/domain/entities/printer_settings.dart';
import 'package:baudex_desktop/features/settings/domain/usecases/get_app_settings_usecase.dart';
import 'package:baudex_desktop/features/settings/domain/usecases/get_invoice_settings_usecase.dart';
import 'package:baudex_desktop/features/settings/domain/usecases/get_printer_settings_usecase.dart';
import 'package:baudex_desktop/features/settings/domain/usecases/save_app_settings_usecase.dart';
import 'package:baudex_desktop/features/settings/domain/usecases/save_invoice_settings_usecase.dart';
import 'package:baudex_desktop/features/settings/domain/usecases/save_printer_settings_usecase.dart';
import 'package:baudex_desktop/features/settings/presentation/controllers/settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_sync_service.dart';
import '../../../helpers/isar_core.dart';

class _Remote extends Mock implements PrinterSettingsRemoteDataSource {}

class _Network extends Mock implements NetworkInfo {}

const _serverId = '3f2b8c1e-5a7d-4e9b-8c1a-2d3e4f5a6b7c';
const _serverId2 = '9a8b7c6d-1e2f-4a3b-9c8d-7e6f5a4b3c2d';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late Directory dir;
  late _Remote remote;
  late _Network network;
  late FakeSyncService queue;

  setUpAll(() async {
    await initIsarCore();
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('baudex_printer_test');
    isar = await Isar.open(IsarDatabase.schemas, directory: dir.path);
    IsarDatabase.debugSetDatabase(isar);
    remote = _Remote();
    network = _Network();
    when(() => network.isConnected).thenAnswer((_) async => true);
    when(() => network.markServerUnreachable()).thenReturn(null);
  });

  tearDown(() async {
    Get.reset();
    IsarDatabase.debugSetDatabase(null);
    await isar.close(deleteFromDisk: true);
    await dir.delete(recursive: true);
  });

  /// Los avisos del controlador (`Get.snackbar`) necesitan una pantalla
  /// montada; aquí no la hay y ese fallo no es lo que se prueba.
  Future<void> quiet(Future<void> Function() body) {
    final done = Completer<void>();
    runZonedGuarded(
      () async {
        await body();
        if (!done.isCompleted) done.complete();
      },
      (error, stack) {
        if (stack.toString().contains('snackbar')) return;
        if (!done.isCompleted) done.completeError(error, stack);
      },
    );
    return done.future;
  }

  /// La impresora tal como la devuelve el servidor al crearla.
  PrinterSettings fromServer(PrinterSettings sent, String id) =>
      sent.copyWith(id: id);

  /// La impresora tal como la arma el formulario de Configuración >
  /// Impresoras: "predeterminada" viene apagado si el cajero no lo toca.
  PrinterSettings formPrinter({
    String name = 'POS-80',
    bool isDefault = false,
  }) => PrinterSettings.usbPrinter(
    id: 'printer_offline_${DateTime.now().microsecondsSinceEpoch}',
    name: name,
    usbPath: name,
    isDefault: isDefault,
  );

  /// Monta lo mismo que `SettingsBinding`, con base local real.
  /// [withQueue] en false imita el arranque real: `InitialBinding` registra
  /// el controlador de configuración ANTES que la cola de sincronización.
  Future<SettingsController> startSettings({bool withQueue = true}) async {
    if (withQueue) {
      queue = FakeSyncService();
      Get.put<SyncService>(queue);
    }
    final repo = SettingsRepositoryImpl(
      localDataSource: SettingsLocalDataSourceImpl(),
      printerRemoteDataSource: remote,
      networkInfo: network,
    );
    final controller = Get.put<SettingsController>(
      SettingsController(
        getAppSettingsUseCase: GetAppSettingsUseCase(repo),
        saveAppSettingsUseCase: SaveAppSettingsUseCase(repo),
        getInvoiceSettingsUseCase: GetInvoiceSettingsUseCase(repo),
        saveInvoiceSettingsUseCase: SaveInvoiceSettingsUseCase(repo),
        getAllPrinterSettingsUseCase: GetAllPrinterSettingsUseCase(repo),
        getDefaultPrinterSettingsUseCase: GetDefaultPrinterSettingsUseCase(repo),
        savePrinterSettingsUseCase: SavePrinterSettingsUseCase(repo),
        deletePrinterSettingsUseCase: DeletePrinterSettingsUseCase(repo),
        setDefaultPrinterUseCase: SetDefaultPrinterUseCase(repo),
        testPrinterConnectionUseCase: TestPrinterConnectionUseCase(repo),
      ),
      permanent: true,
    );
    await controller.loadPrinterSettings();
    return controller;
  }

  /// Cerrar la app y volver a abrirla: se pierde la memoria, queda el disco
  /// (la base Isar y las preferencias).
  Future<SettingsController> restartApp({bool withQueue = true}) async {
    Get.reset();
    Get.testMode = true;
    return startSettings(withQueue: withQueue);
  }

  Future<List<PrinterSettingsModel>> stored() =>
      isar.printerSettingsModels.where().findAll();

  group('arranque en frío con una impresora guardada', () {
    test(
      'la única impresora (sin marcar "predeterminada") sirve para facturar '
      'después de cerrar y abrir la app, sin pasar por la pantalla',
      () async {
        when(() => remote.createPrinterSetting(any())).thenAnswer(
          (_) async => fromServer(formPrinter(), _serverId),
        );

        // Día 1: el cajero agrega la impresora y la deja como viene.
        final settings = await startSettings();
        await quiet(() => settings.savePrinterSettings(formPrinter()));
        expect((await stored()).single.usbPath, 'POS-80');

        // Día 2: prende el equipo, abre Baudex y factura.
        await restartApp();
        final printer = Get.put(ThermalPrinterController());
        final ready = await printer.ensurePrinterConfigLoaded();

        expect(
          ready,
          isTrue,
          reason: 'La impresora está en la base local pero la factura no la ve',
        );
        expect(printer.currentPrinterConfig?.usbPath, 'POS-80');
      },
    );

    test(
      'el mismo día funciona solo porque la página de prueba deja la '
      'impresora en memoria (esto explica por qué "ahí sí imprime")',
      () async {
        when(() => remote.createPrinterSetting(any())).thenAnswer(
          (_) async => fromServer(formPrinter(), _serverId),
        );
        final settings = await startSettings();
        await quiet(() => settings.savePrinterSettings(formPrinter()));
        final printer = Get.put(ThermalPrinterController());

        // Sin página de prueba: no hay impresora para la factura.
        expect(await printer.ensurePrinterConfigLoaded(), isFalse);

        // Lo que hace "Imprimir página de prueba" antes de imprimir.
        await printer.setTempPrinterConfig(settings.printerSettings.single);
        expect(await printer.ensurePrinterConfigLoaded(), isTrue);
      },
    );

    test(
      'las impresoras que baja la sincronización llegan a la memoria '
      '(equipo nuevo o base recién descargada), con el orden real de arranque',
      () async {
        // Igual que InitialBinding: primero configuración, después la cola.
        final settings = await startSettings(withQueue: false);
        queue = FakeSyncService();
        Get.put<SyncService>(queue);
        expect(settings.printerSettings, isEmpty);

        // La bajada guarda la impresora del servidor y termina.
        queue.syncStateObs.value = SyncState.syncing;
        await isar.writeTxn(
          () => isar.printerSettingsModels.put(
            PrinterSettingsModel.fromEntity(
              fromServer(formPrinter(isDefault: true), _serverId),
            ),
          ),
        );
        queue.syncStateObs.value = SyncState.idle;
        await Future<void>.delayed(const Duration(milliseconds: 1200));

        expect(
          settings.defaultPrinter?.usbPath,
          'POS-80',
          reason: 'El controlador nunca se entera de que terminó la bajada',
        );
      },
    );
  });

  group('eliminar una impresora', () {
    Future<SettingsController> withServerPrinter({
      bool isDefault = true,
    }) async {
      await isar.writeTxn(
        () => isar.printerSettingsModels.put(
          PrinterSettingsModel.fromEntity(
            fromServer(formPrinter(isDefault: isDefault), _serverId),
          ),
        ),
      );
      return startSettings();
    }

    test('con internet y el servidor acepta: se va de todos lados', () async {
      when(() => remote.deletePrinterSetting(any())).thenAnswer((_) async {});
      final settings = await withServerPrinter();

      await quiet(() => settings.deletePrinterSettings(_serverId));

      expect(await stored(), isEmpty);
      expect(settings.printerSettings, isEmpty);
      expect(queue.ops, isEmpty);
    });

    test(
      'la factura deja de usar la impresora eliminada',
      () async {
        when(() => remote.deletePrinterSetting(any())).thenAnswer((_) async {});
        final settings = await withServerPrinter();
        final printer = Get.put(ThermalPrinterController());
        expect(await printer.ensurePrinterConfigLoaded(), isTrue);

        await quiet(() => settings.deletePrinterSettings(_serverId));
        // Lo que hace la factura justo antes de imprimir.
        final ready = await printer.ensurePrinterConfigLoaded();

        expect(
          ready && printer.currentPrinterConfig?.id == _serverId,
          isFalse,
          reason: 'Sigue mandando tiquetes a una impresora que ya se eliminó',
        );
      },
    );

    test(
      'si queda otra impresora, pasa a ser la de las facturas',
      () async {
        when(() => remote.deletePrinterSetting(any())).thenAnswer((_) async {});
        await isar.writeTxn(
          () => isar.printerSettingsModels.put(
            PrinterSettingsModel.fromEntity(
              fromServer(formPrinter(name: 'Cocina'), _serverId2),
            ),
          ),
        );
        final settings = await withServerPrinter();
        expect(settings.defaultPrinter?.id, _serverId);

        await quiet(() => settings.deletePrinterSettings(_serverId));

        expect(
          settings.defaultPrinter?.id,
          _serverId2,
          reason: 'Queda una impresora guardada y ninguna para facturar',
        );
      },
    );

    test(
      'el servidor dice que ya no existe (404): se da por eliminada, sin '
      'dejar nada en cola ni marcar el servidor como caído',
      () async {
        when(() => remote.deletePrinterSetting(any())).thenThrow(
          const ServerException(
            'Recurso no encontrado: Impresora no encontrada',
            statusCode: 404,
          ),
        );
        final settings = await withServerPrinter();

        await quiet(() => settings.deletePrinterSettings(_serverId));

        expect(await stored(), isEmpty);
        expect(queue.ops, isEmpty, reason: 'Encola un borrado que ya está hecho');
        verifyNever(() => network.markServerUnreachable());
      },
    );

    test(
      'el servidor lo prohíbe (403, cajero sin permiso): la impresora se '
      'queda y no se trata como falta de internet',
      () async {
        when(() => remote.deletePrinterSetting(any())).thenThrow(
          const ServerException(
            'No tiene permisos para esta acción',
            statusCode: 403,
          ),
        );
        final settings = await withServerPrinter();

        await quiet(() => settings.deletePrinterSettings(_serverId));

        expect(
          (await stored()).length,
          1,
          reason: 'Se borró en este equipo algo que el servidor rechazó',
        );
        expect(queue.ops, isEmpty);
        verifyNever(() => network.markServerUnreachable());
      },
    );

    test('sin internet: se borra aquí y queda en cola para el servidor', () async {
      when(() => network.isConnected).thenAnswer((_) async => false);
      final settings = await withServerPrinter();

      await quiet(() => settings.deletePrinterSettings(_serverId));

      expect(await stored(), isEmpty);
      expect(queue.ops.single['op'], 'delete');
      expect(queue.ops.single['entityId'], _serverId);
      verifyNever(() => remote.deletePrinterSetting(any()));
    });

    test(
      'creada sin internet y eliminada antes de subir: no debe subir después',
      () async {
        when(() => network.isConnected).thenAnswer((_) async => false);
        final settings = await startSettings();
        await quiet(() => settings.savePrinterSettings(formPrinter()));
        final localId = settings.printerSettings.single.id;
        expect(queue.ops.single['op'], 'create');

        await quiet(() => settings.deletePrinterSettings(localId));

        expect(await stored(), isEmpty);
        final pendingCreates = queue.ops.where((o) => o['op'] == 'create');
        final cancelled = queue.ops.any(
          (o) => o['op'] == 'delete' && o['entityId'] == localId,
        );
        expect(
          pendingCreates.isEmpty || cancelled,
          isTrue,
          reason:
              'La creación sigue en cola: al volver el internet la impresora '
              'eliminada se crea en el servidor y reaparece',
        );
      },
    );

    test(
      'sin cola disponible y sin internet: no se borra aquí, porque la '
      'bajada la volvería a traer',
      () async {
        when(() => network.isConnected).thenAnswer((_) async => false);
        final settings = await withServerPrinter();
        queue.fail = true;

        await quiet(() => settings.deletePrinterSettings(_serverId));

        expect(
          (await stored()).length,
          1,
          reason: 'Se borró local sin encolar: el servidor la conserva',
        );
      },
    );
  });
}
