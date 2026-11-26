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

  /// Impresoras guardadas (sin las marcas de "eliminada aquí", que solo
  /// existen para que la bajada no las reviva).
  Future<List<PrinterSettingsModel>> stored() =>
      isar.printerSettingsModels.filter().deletedAtIsNull().findAll();

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
      'el mismo día sirve sin imprimir antes la página de prueba, y la '
      'primera impresora queda como predeterminada',
      () async {
        when(() => remote.createPrinterSetting(any())).thenAnswer(
          (inv) async => fromServer(
            formPrinter(
              isDefault:
                  (inv.positionalArguments.single as Map)['isDefault'] as bool,
            ),
            _serverId,
          ),
        );
        final settings = await startSettings();
        await quiet(() => settings.savePrinterSettings(formPrinter()));
        final printer = Get.put(ThermalPrinterController());

        expect(await printer.ensurePrinterConfigLoaded(), isTrue);
        expect(settings.defaultPrinter?.id, _serverId);
        expect(settings.printerSettings.single.isDefault, isTrue);
        final sent =
            verify(() => remote.createPrinterSetting(captureAny())).captured;
        expect((sent.single as Map)['isDefault'], isTrue);
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

  group('simulaciones de uso', () {
    Future<void> putServerPrinter(
      String id,
      String name, {
      bool isDefault = false,
    }) => isar.writeTxn(
      () => isar.printerSettingsModels.putByServerId(
        PrinterSettingsModel.fromEntity(
          fromServer(formPrinter(name: name, isDefault: isDefault), id),
        ),
      ),
    );

    test('ir a productos y volver: la factura sigue con su impresora', () async {
      await putServerPrinter(_serverId, 'POS-80');
      await startSettings();
      var printer = Get.put(ThermalPrinterController());
      expect(await printer.ensurePrinterConfigLoaded(), isTrue);

      // Salir de facturación destruye el controlador; al volver se crea otro.
      await Get.delete<ThermalPrinterController>(force: true);
      printer = Get.put(ThermalPrinterController());

      expect(await printer.ensurePrinterConfigLoaded(), isTrue);
      expect(printer.currentPrinterConfig?.id, _serverId);
    });

    test(
      'sin el controlador de Configuración en memoria, la factura lee la '
      'impresora de la base local',
      () async {
        await putServerPrinter(_serverId, 'POS-80');
        final printer = Get.put(ThermalPrinterController());

        expect(Get.isRegistered<SettingsController>(), isFalse);
        expect(await printer.ensurePrinterConfigLoaded(), isTrue);
        expect(printer.currentPrinterConfig?.usbPath, 'POS-80');
      },
    );

    test('sin internet al arrancar: no se consulta el servidor', () async {
      await putServerPrinter(_serverId, 'POS-80');
      when(() => network.isConnected).thenAnswer((_) async => false);

      await startSettings();
      final printer = Get.put(ThermalPrinterController());

      expect(await printer.ensurePrinterConfigLoaded(), isTrue);
      verifyNever(() => remote.getAllPrinterSettings());
      verifyZeroInteractions(remote);
    });

    test(
      'dos impresoras: la que se elige en este equipo se mantiene al '
      'cerrar y abrir',
      () async {
        await putServerPrinter(_serverId, 'Caja', isDefault: true);
        await putServerPrinter(_serverId2, 'Cocina');
        var settings = await startSettings();
        expect(settings.defaultPrinter?.id, _serverId);

        await quiet(() => settings.setDefaultPrinter(_serverId2));
        expect(settings.defaultPrinter?.id, _serverId2);

        settings = await restartApp();
        final printer = Get.put(ThermalPrinterController());
        expect(await printer.ensurePrinterConfigLoaded(), isTrue);
        expect(printer.currentPrinterConfig?.id, _serverId2);
        expect(
          settings.printerSettings.where((p) => p.isDefault).map((p) => p.id),
          [_serverId2],
        );
      },
    );

    test(
      'dos impresoras sin marcar ninguna: se factura con la primera por '
      'nombre, siempre la misma',
      () async {
        await putServerPrinter(_serverId, 'Cocina');
        await putServerPrinter(_serverId2, 'Caja');

        final first = (await startSettings()).defaultPrinter?.name;
        final again = (await restartApp()).defaultPrinter?.name;

        expect(first, 'Caja');
        expect(again, 'Caja');
      },
    );

    test(
      'dos impresoras: al eliminar la predeterminada la factura pasa a la '
      'otra, también tras reiniciar',
      () async {
        when(() => remote.deletePrinterSetting(any())).thenAnswer((_) async {});
        await putServerPrinter(_serverId, 'Caja', isDefault: true);
        await putServerPrinter(_serverId2, 'Cocina');
        final settings = await startSettings();
        final printer = Get.put(ThermalPrinterController());
        await printer.ensurePrinterConfigLoaded();
        expect(printer.currentPrinterConfig?.id, _serverId);

        await quiet(() => settings.deletePrinterSettings(_serverId));
        await printer.ensurePrinterConfigLoaded();
        expect(printer.currentPrinterConfig?.id, _serverId2);

        await restartApp();
        final reopened = Get.put(ThermalPrinterController());
        expect(await reopened.ensurePrinterConfigLoaded(), isTrue);
        expect(reopened.currentPrinterConfig?.id, _serverId2);
      },
    );

    test(
      'la impresora que otro equipo marcó como predeterminada no le quita '
      'la suya a este equipo',
      () async {
        await putServerPrinter(_serverId, 'POS de este equipo');
        final settings = await startSettings(withQueue: false);
        queue = FakeSyncService();
        Get.put<SyncService>(queue);
        await quiet(() => settings.setDefaultPrinter(_serverId));

        // Baja del servidor la USB de otro computador, marcada allá.
        queue.syncStateObs.value = SyncState.syncing;
        await putServerPrinter(_serverId2, 'USB de otro equipo', isDefault: true);
        queue.syncStateObs.value = SyncState.idle;
        await Future<void>.delayed(const Duration(milliseconds: 1200));

        expect(settings.printerSettings.length, 2);
        expect(settings.defaultPrinter?.id, _serverId);
      },
    );

    test('cerrar sesión y entrar al mismo negocio: sigue la impresora', () async {
      await putServerPrinter(_serverId, 'POS-80');
      final settings = await startSettings();
      final printer = Get.put(ThermalPrinterController());
      expect(await printer.ensurePrinterConfigLoaded(), isTrue);

      // Entrar de nuevo dispara una bajada que vuelve a traer lo mismo.
      queue.syncStateObs.value = SyncState.syncing;
      await putServerPrinter(_serverId, 'POS-80');
      queue.syncStateObs.value = SyncState.idle;
      await Future<void>.delayed(const Duration(milliseconds: 900));

      expect(settings.defaultPrinter?.id, _serverId);
      expect(await printer.ensurePrinterConfigLoaded(), isTrue);
      expect((await stored()).length, 1);
    });

    test(
      'entrar con otro negocio: la impresora del negocio anterior ya '
      'sincronizada se va y se factura con la del nuevo',
      () async {
        await putServerPrinter(_serverId, 'Del negocio A');
        final settings = await startSettings();
        final printer = Get.put(ThermalPrinterController());
        await printer.ensurePrinterConfigLoaded();
        expect(printer.currentPrinterConfig?.id, _serverId);

        // Lo que hace la bajada al detectar otro negocio
        // (full_sync_service: conserva solo las no sincronizadas) y
        // después descarga las del negocio nuevo.
        queue.syncStateObs.value = SyncState.syncing;
        await isar.writeTxn(() async {
          final unsynced =
              await isar.printerSettingsModels
                  .filter()
                  .isSyncedEqualTo(false)
                  .findAll();
          await isar.printerSettingsModels.clear();
          await isar.printerSettingsModels.putAll(unsynced);
        });
        await putServerPrinter(_serverId2, 'Del negocio B');
        queue.syncStateObs.value = SyncState.idle;
        await Future<void>.delayed(const Duration(milliseconds: 900));

        expect(settings.printerSettings.map((p) => p.name), ['Del negocio B']);
        expect(await printer.ensurePrinterConfigLoaded(), isTrue);
        expect(printer.currentPrinterConfig?.id, _serverId2);
      },
    );

    test(
      'cajero sin permiso agrega una impresora: queda en este equipo, sin '
      'cola, y sirve al reiniciar',
      () async {
        when(() => remote.createPrinterSetting(any())).thenThrow(
          const ServerException('Acceso denegado', statusCode: 403),
        );
        final settings = await startSettings();

        await quiet(() => settings.savePrinterSettings(formPrinter()));

        expect((await stored()).single.usbPath, 'POS-80');
        expect(queue.ops, isEmpty);
        verifyNever(() => network.markServerUnreachable());

        await restartApp();
        final printer = Get.put(ThermalPrinterController());
        expect(await printer.ensurePrinterConfigLoaded(), isTrue);
      },
    );

    test(
      'cajero sin permiso cambia una impresora del negocio: no se cambia',
      () async {
        when(() => remote.updatePrinterSetting(any(), any())).thenThrow(
          const ServerException('Acceso denegado', statusCode: 403),
        );
        await putServerPrinter(_serverId, 'POS-80');
        final settings = await startSettings();

        await quiet(
          () => settings.savePrinterSettings(
            settings.printerSettings.single.copyWith(name: 'Otro nombre'),
          ),
        );

        expect((await stored()).single.name, 'POS-80');
        expect(queue.ops, isEmpty);
      },
    );

    test('dos "Eliminar" seguidos: al servidor solo va uno', () async {
      when(() => remote.deletePrinterSetting(any())).thenAnswer(
        (_) => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await putServerPrinter(_serverId, 'POS-80');
      final settings = await startSettings();

      await quiet(
        () => Future.wait([
          settings.deletePrinterSettings(_serverId),
          settings.deletePrinterSettings(_serverId),
        ]),
      );

      verify(() => remote.deletePrinterSetting(_serverId)).called(1);
      expect(await stored(), isEmpty);
    });

    test(
      'sin red al eliminar (sin respuesta): se borra aquí, queda en cola y '
      'se marca el servidor como no disponible',
      () async {
        when(() => remote.deletePrinterSetting(any())).thenThrow(
          const ServerException('Error al eliminar impresora: sin conexión'),
        );
        await putServerPrinter(_serverId, 'POS-80');
        final settings = await startSettings();

        await quiet(() => settings.deletePrinterSettings(_serverId));

        expect(await stored(), isEmpty);
        expect(queue.ops.single['op'], 'delete');
        verify(() => network.markServerUnreachable()).called(1);
      },
    );

    test(
      'creada sin internet y guardada otra vez con internet: una sola '
      'impresora, sin creación pendiente',
      () async {
        when(() => network.isConnected).thenAnswer((_) async => false);
        final settings = await startSettings();
        await quiet(() => settings.savePrinterSettings(formPrinter()));
        final local = settings.printerSettings.single;
        expect(queue.ops.single['op'], 'create');

        when(() => network.isConnected).thenAnswer((_) async => true);
        when(() => remote.createPrinterSetting(any())).thenAnswer(
          (_) async => fromServer(local, _serverId),
        );
        await quiet(() => settings.savePrinterSettings(local));

        expect((await stored()).map((p) => p.serverId), [_serverId]);
        expect(queue.ops, isEmpty);
        expect(settings.defaultPrinter?.id, _serverId);
      },
    );
  });
}
