// La pantalla REAL de Configuración > Impresoras, de punta a punta:
// abrir, llenar el formulario, Agregar, y que la impresora aparezca.
// También editar, eliminar (una vez y doble toque) y predeterminada.
//
// Controlador, repositorio y base local son los reales (Isar temporal).
// El servidor es de mentira pero valida como el real
// (backend/src/printer-settings: DTO con lista blanca, roles ADMIN/MANAGER).
import 'dart:io';

import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/app/data/local/sync_service.dart';
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
import 'package:baudex_desktop/features/settings/presentation/screens/printer_configuration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_sync_service.dart';
import '../../helpers/isar_core.dart';

class _Network extends Mock implements NetworkInfo {}

/// Servidor de mentira: valida como `CreatePrinterSettingsDto` con
/// `whitelist + forbidNonWhitelisted` y exige rol ADMIN o MANAGER.
class _Server implements PrinterSettingsRemoteDataSource {
  final rows = <String, PrinterSettings>{};
  String role = 'admin';
  bool down = false;
  int creates = 0, deletes = 0;
  int _next = 1;

  static const _fields = {
    'name', 'connectionType', 'ipAddress', 'port', 'usbPath',
    'paperSize', 'autoCut', 'cashDrawer', 'isDefault',
  };

  void _guard({bool write = true}) {
    if (down) throw const ServerException('Error de conexión al servidor');
    if (write && role != 'admin' && role != 'manager') {
      throw const ServerException('Forbidden resource', statusCode: 403);
    }
  }

  void _validate(Map<String, dynamic> d, {required bool partial}) {
    final errors = <String>[];
    for (final k in d.keys) {
      if (!_fields.contains(k)) errors.add('property $k should not exist');
    }
    bool has(String k) => d[k] != null;
    if (!partial || has('name')) {
      final n = d['name'];
      if (n is! String) {
        errors.add('name must be a string');
      } else if (n.length > 100) {
        errors.add('name must be shorter than or equal to 100 characters');
      }
    }
    if (!partial || has('connectionType')) {
      if (!const ['network', 'usb'].contains(d['connectionType'])) {
        errors.add('connectionType must be one of: network, usb');
      }
    }
    if (!partial || has('paperSize')) {
      if (!const ['mm58', 'mm80'].contains(d['paperSize'])) {
        errors.add('paperSize must be one of: mm58, mm80');
      }
    }
    if (has('ipAddress') && d['ipAddress'] is! String) {
      errors.add('ipAddress must be a string');
    }
    if (has('usbPath') && d['usbPath'] is! String) {
      errors.add('usbPath must be a string');
    }
    if (has('port')) {
      final p = d['port'];
      if (p is! int || p < 1 || p > 65535) errors.add('port must be 1-65535');
    }
    for (final k in ['autoCut', 'cashDrawer', 'isDefault']) {
      if (has(k) && d[k] is! bool) errors.add('$k must be a boolean value');
    }
    if (errors.isNotEmpty) {
      throw ServerException(
        'Solicitud incorrecta: ${errors.join(', ')}',
        statusCode: 400,
      );
    }
  }

  PrinterSettings _apply(PrinterSettings? old, String id, Map<String, dynamic> d) {
    final now = DateTime.now();
    return PrinterSettings(
      id: id,
      name: d['name'] ?? old!.name,
      connectionType: (d['connectionType'] ?? old?.connectionType.name) == 'usb'
          ? PrinterConnectionType.usb
          : PrinterConnectionType.network,
      ipAddress: d.containsKey('ipAddress') ? d['ipAddress'] : old?.ipAddress,
      port: d.containsKey('port') ? d['port'] : old?.port,
      usbPath: d.containsKey('usbPath') ? d['usbPath'] : old?.usbPath,
      paperSize: (d['paperSize'] ?? old?.paperSize.name) == 'mm58'
          ? PaperSize.mm58
          : PaperSize.mm80,
      autoCut: d['autoCut'] ?? old?.autoCut ?? true,
      cashDrawer: d['cashDrawer'] ?? old?.cashDrawer ?? false,
      isDefault: d['isDefault'] ?? old?.isDefault ?? false,
      createdAt: old?.createdAt ?? now,
      updatedAt: now,
    );
  }

  @override
  Future<PrinterSettings> createPrinterSetting(Map<String, dynamic> data) async {
    _guard();
    _validate(data, partial: false);
    creates++;
    final id =
        '00000000-0000-4000-8000-${(_next++).toString().padLeft(12, '0')}';
    return rows[id] = _apply(null, id, data);
  }

  @override
  Future<PrinterSettings> updatePrinterSetting(String id, Map<String, dynamic> data) async {
    _guard();
    _validate(data, partial: true);
    final old = rows[id];
    if (old == null) {
      throw const ServerException(
        'Recurso no encontrado: Impresora no encontrada',
        statusCode: 404,
      );
    }
    return rows[id] = _apply(old, id, data);
  }

  @override
  Future<void> deletePrinterSetting(String id) async {
    _guard();
    deletes++;
    if (rows.remove(id) == null) {
      throw const ServerException(
        'Recurso no encontrado: Impresora no encontrada',
        statusCode: 404,
      );
    }
  }

  @override
  Future<List<PrinterSettings>> getAllPrinterSettings() async {
    _guard(write: false);
    return rows.values.toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Isar isar;
  late Directory dir;
  late _Server server;
  late _Network network;
  late FakeSyncService queue;

  setUpAll(initIsarCore);

  Future<void> boot(WidgetTester tester, {Size size = const Size(1400, 1000)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // Con la fuente de pruebas (letras cuadradas) los botones se desbordan;
    // eso no pasa con la fuente real y no es lo que se prueba aquí.
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(() async {
      dir = await Directory.systemTemp.createTemp('baudex_printer_screen');
      isar = await Isar.open(IsarDatabase.schemas, directory: dir.path);
    });
    IsarDatabase.debugSetDatabase(isar);
    server = _Server();
    network = _Network();
    when(() => network.isConnected).thenAnswer((_) async => true);
    when(() => network.markServerUnreachable()).thenReturn(null);
    queue = FakeSyncService();
    Get.put<SyncService>(queue);
    final repo = SettingsRepositoryImpl(
      localDataSource: SettingsLocalDataSourceImpl(),
      printerRemoteDataSource: server,
      networkInfo: network,
    );
    Get.put<SettingsController>(
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
    addTearDown(() async {
      Get.reset();
      IsarDatabase.debugSetDatabase(null);
      await tester.runAsync(() async {
        await isar.close(deleteFromDisk: true);
        await dir.delete(recursive: true);
      });
    });
  }

  /// Deja correr el trabajo real (Isar) y repinta.
  Future<void> settle(WidgetTester tester, {int rounds = 30}) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 15)),
      );
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  Future<void> openScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(home: PrinterConfigurationScreen()),
    );
    await settle(tester);
  }

  Future<void> fillAndAdd(
    WidgetTester tester, {
    required String name,
    String? usb,
    String? ip,
  }) async {
    await tester.enterText(
      find.byType(TextFormField).at(0),
      name,
    );
    if (usb != null) {
      await tester.tap(find.text('USB').first);
      await settle(tester, rounds: 3);
      await tester.enterText(find.byType(TextFormField).at(1), usb);
    } else {
      await tester.enterText(find.byType(TextFormField).at(1), ip!);
    }
    await tester.pump();
    final add = find.text('Agregar');
    await tester.ensureVisible(add);
    await tester.pump();
    await tester.tap(add);
    await settle(tester);
  }

  Future<List<PrinterSettingsModel>> stored(WidgetTester tester) async =>
      (await tester.runAsync(() => isar.printerSettingsModels.where().findAll()))!;

  SettingsController ctrl() => Get.find<SettingsController>();

  /// Prueba de pantalla: al final deja que los avisos terminen de cerrarse.
  void screenTest(String description, Future<void> Function(WidgetTester) body) {
    testWidgets(description, (tester) async {
      await body(tester);
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
    });
  }

  screenTest('admin con internet, lista vacía, USB de Windows: se agrega', (tester) async {
    await boot(tester);
    await openScreen(tester);

    await fillAndAdd(tester, name: 'Caja', usb: 'POS-80 Térmica (copia 1)');

    expect(tester.takeException(), isNull);
    expect(server.creates, 1, reason: 'Debe llegar un POST al servidor');
    expect(server.rows.length, 1);
    expect((await stored(tester)).single.usbPath, 'POS-80 Térmica (copia 1)');
    expect(ctrl().printerSettings.single.name, 'Caja');
    expect(ctrl().defaultPrinter?.name, 'Caja');
    expect(find.text('Caja'), findsWidgets);
  });

  screenTest('admin con internet, impresora de red: se agrega', (tester) async {
    await boot(tester);
    await openScreen(tester);

    await fillAndAdd(tester, name: 'Cocina', ip: '192.168.1.50');

    expect(tester.takeException(), isNull);
    expect(server.rows.values.single.ipAddress, '192.168.1.50');
    expect(ctrl().printerSettings.single.name, 'Cocina');
  });

  screenTest('ya hay una impresora: se agrega la segunda y no le quita la '
      'predeterminada a la primera', (tester) async {
    await boot(tester);
    await openScreen(tester);
    await fillAndAdd(tester, name: 'Caja', usb: 'POS-80');
    await fillAndAdd(tester, name: 'Cocina', ip: '192.168.1.50');

    expect(tester.takeException(), isNull);
    expect(ctrl().printerSettings.map((p) => p.name).toSet(), {'Caja', 'Cocina'});
    expect(ctrl().defaultPrinter?.name, 'Caja');
    expect((await stored(tester)).length, 2);
  });

  screenTest('sin internet: se agrega aquí y queda en cola', (tester) async {
    await boot(tester);
    when(() => network.isConnected).thenAnswer((_) async => false);
    await openScreen(tester);

    await fillAndAdd(tester, name: 'Caja', usb: 'POS-80');

    expect(tester.takeException(), isNull);
    expect(ctrl().printerSettings.single.name, 'Caja');
    expect(queue.ops.single['op'], 'create');
    expect(server.creates, 0);
  });

  screenTest('con internet pero el servidor no responde: se agrega aquí y '
      'queda en cola', (tester) async {
    await boot(tester);
    server.down = true;
    await openScreen(tester);

    await fillAndAdd(tester, name: 'Caja', usb: 'POS-80');

    expect(tester.takeException(), isNull);
    expect(ctrl().printerSettings.single.name, 'Caja');
    expect(queue.ops.single['op'], 'create');
  });

  screenTest('cajero (el servidor responde 403): la impresora queda en '
      'este equipo', (tester) async {
    await boot(tester);
    server.role = 'cashier';
    await openScreen(tester);

    await fillAndAdd(tester, name: 'Caja', usb: 'POS-80');

    expect(tester.takeException(), isNull);
    expect(ctrl().printerSettings.single.name, 'Caja');
    expect(ctrl().defaultPrinter?.name, 'Caja');
    expect(queue.ops, isEmpty);
  });

  screenTest('el servidor rechaza los datos (400): la impresora NO se '
      'pierde, queda en este equipo como en 1.0.7', (tester) async {
    await boot(tester);
    await openScreen(tester);

    // 101 caracteres: el servidor acepta hasta 100.
    await fillAndAdd(tester, name: 'C' * 101, usb: 'POS-80');

    expect(tester.takeException(), isNull);
    expect(
      ctrl().printerSettings.length,
      1,
      reason: 'Un rechazo del servidor impide usar la impresora del equipo',
    );
    expect(ctrl().defaultPrinter, isNotNull);
  });

  screenTest('editar: cambia el nombre en la lista y en el servidor', (tester) async {
    await boot(tester);
    await openScreen(tester);
    await fillAndAdd(tester, name: 'Caja', usb: 'POS-80');

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await settle(tester, rounds: 4);
    await tester.tap(find.text('Editar').last);
    await settle(tester, rounds: 4);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Caja principal',
    );
    final update = find.text('Actualizar');
    await tester.ensureVisible(update);
    await tester.pump();
    await tester.tap(update);
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(server.rows.values.single.name, 'Caja principal');
    expect(ctrl().printerSettings.single.name, 'Caja principal');
    expect((await stored(tester)).length, 1);
  });

  screenTest('marcar predeterminada la segunda impresora', (tester) async {
    await boot(tester);
    await openScreen(tester);
    await fillAndAdd(tester, name: 'Caja', usb: 'POS-80');
    await fillAndAdd(tester, name: 'Cocina', ip: '192.168.1.50');

    // La segunda de la lista (la primera es la predeterminada).
    await tester.tap(find.byType(PopupMenuButton<String>).last);
    await settle(tester, rounds: 4);
    await tester.tap(find.text('Establecer por defecto').last);
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(ctrl().defaultPrinter?.name, 'Cocina');
    expect(
      ctrl().printerSettings.where((p) => p.isDefault).map((p) => p.name),
      ['Cocina'],
    );
  });

  screenTest('eliminar: se va de la lista, y el doble toque solo manda un '
      'borrado', (tester) async {
    await boot(tester);
    await openScreen(tester);
    await fillAndAdd(tester, name: 'Caja', usb: 'POS-80');

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await settle(tester, rounds: 4);
    await tester.tap(find.text('Eliminar').last);
    await settle(tester, rounds: 4);
    final confirm = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Eliminar'),
    );
    await tester.tap(confirm.last);
    await tester.pump();
    if (confirm.evaluate().isNotEmpty) {
      await tester.tap(confirm.last, warnIfMissed: false);
    }
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsNothing);
    expect(server.deletes, 1);
    expect(server.rows, isEmpty);
    expect(ctrl().printerSettings, isEmpty);
    expect(await stored(tester), isEmpty);
  });

  screenTest('agregar → eliminar → agregar otra vez: cada alta llega al '
      'servidor y la lista queda con una sola impresora', (tester) async {
    await boot(tester);
    await openScreen(tester);
    await fillAndAdd(tester, name: 'Caja', usb: 'POS-80');
    expect(server.creates, 1);

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await settle(tester, rounds: 4);
    await tester.tap(find.text('Eliminar').last);
    await settle(tester, rounds: 4);
    await tester.tap(
      find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Eliminar'),
          )
          .last,
    );
    await settle(tester);
    expect(server.rows, isEmpty);
    expect(queue.ops, isEmpty, reason: 'Con internet, eliminar no encola');

    await fillAndAdd(tester, name: 'Caja', usb: 'POS-80');

    expect(tester.takeException(), isNull);
    expect(server.creates, 2);
    expect(server.rows.length, 1);
    expect(ctrl().printerSettings.single.name, 'Caja');
    expect((await stored(tester)).length, 1);
    expect(queue.ops, isEmpty);
  });

  screenTest('una sincronización que termina mientras se llena el '
      'formulario no lo desmonta ni le quita el cursor', (tester) async {
    await boot(tester);
    await openScreen(tester);
    final nameField = find.byType(TextFormField).at(0);
    await tester.tap(nameField);
    await tester.enterText(nameField, 'Caj');
    await tester.pump();
    final editing = tester.state<EditableTextState>(
      find.descendant(of: nameField, matching: find.byType(EditableText)),
    );
    expect(editing.widget.focusNode.hasFocus, isTrue);

    // Termina una sincronización (subida o bajada) en segundo plano.
    var sawLoading = false;
    queue.syncStateObs.value = SyncState.syncing;
    await tester.pump(const Duration(milliseconds: 100));
    queue.syncStateObs.value = SyncState.idle;
    for (var i = 0; i < 30; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 15)),
      );
      await tester.pump(const Duration(milliseconds: 60));
      sawLoading = sawLoading || ctrl().isLoadingPrinterSettings;
    }

    expect(
      sawLoading,
      isFalse,
      reason: 'La pantalla cambió el formulario por el indicador de carga',
    );
    expect(
      editing.mounted,
      isTrue,
      reason: 'El campo donde se estaba escribiendo fue destruido',
    );
    expect(editing.widget.focusNode.hasFocus, isTrue);

    // Y se puede terminar de agregar.
    await fillAndAdd(tester, name: 'Caja', usb: 'POS-80');
    expect(ctrl().printerSettings.single.name, 'Caja');
  });
}
