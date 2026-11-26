// tool/probes/impresoras_probe.dart
//
// Recorre en un equipo real lo que hace un cajero con las impresoras:
// agregar (USB y red), página de prueba, cerrar y abrir, facturar,
// eliminar, agregar → eliminar → agregar, y una base "con historia"
// (restos de versiones anteriores, preferencias del equipo dañadas).
//
// Controlador, repositorio y base local son los reales, sobre una base
// Isar temporal. El servidor es de mentira (en memoria) y valida como el
// real (backend/src/printer-settings). No toca datos de ningún cliente.
//
// Cada paso escribe `PRUEBA IMPRESORAS | <paso> | OK|FALLA|OMITIDA | …`.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/app/data/local/sync_queue.dart';
import 'package:baudex_desktop/app/data/local/sync_service.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice_item.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/thermal_printer_controller.dart';
import 'package:baudex_desktop/features/settings/data/datasources/printer_settings_remote_datasource.dart';
import 'package:baudex_desktop/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:baudex_desktop/features/settings/data/models/printer_settings_model.dart';
import 'package:baudex_desktop/features/settings/data/printer_diagnostics.dart';
import 'package:baudex_desktop/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:baudex_desktop/features/settings/domain/entities/printer_settings.dart';
import 'package:baudex_desktop/features/settings/domain/usecases/get_app_settings_usecase.dart';
import 'package:baudex_desktop/features/settings/domain/usecases/get_invoice_settings_usecase.dart';
import 'package:baudex_desktop/features/settings/domain/usecases/get_printer_settings_usecase.dart';
import 'package:baudex_desktop/features/settings/domain/usecases/save_app_settings_usecase.dart';
import 'package:baudex_desktop/features/settings/domain/usecases/save_invoice_settings_usecase.dart';
import 'package:baudex_desktop/features/settings/domain/usecases/save_printer_settings_usecase.dart';
import 'package:baudex_desktop/features/settings/presentation/controllers/settings_controller.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImpresorasProbeConfig {
  const ImpresorasProbeConfig({
    this.windowsPrinter,
    this.printerOutput,
    this.prefsFile,
    this.label = '',
  });

  /// Impresora instalada en este Windows (la de mentira del trabajo de
  /// GitHub). Sin ella se omiten los pasos que imprimen.
  final String? windowsPrinter;

  /// Archivo donde esa impresora deja lo que recibe.
  final String? printerOutput;

  /// Archivo real de preferencias del equipo, para dañarlo a propósito
  /// ANTES de usarlas. Null = se omite ese paso.
  final File? prefsFile;
  final String label;
}

class ImpresorasProbeResult {
  ImpresorasProbeResult(this.failures, this.steps);
  final int failures;
  final int steps;
  bool get ok => failures == 0 && steps > 0;
}

/// Cola de sincronización en memoria.
class _Queue extends SyncService {
  _Queue() : super(null);
  final ops = <Map<String, dynamic>>[];

  @override
  // ignore: must_call_super
  Future<void> onInit() async {}

  @override
  Future<void> addOperation({
    required String entityType,
    required String entityId,
    required SyncOperationType operationType,
    required Map<String, dynamic> data,
    required String organizationId,
    int priority = 0,
  }) async => ops.add({'entityId': entityId, 'op': operationType.name});

  @override
  Future<void> addOperationForCurrentUser({
    required String entityType,
    required String entityId,
    required SyncOperationType operationType,
    required Map<String, dynamic> data,
    int priority = 0,
  }) async => ops.add({'entityId': entityId, 'op': operationType.name});

  @override
  Future<void> deleteSyncOperationsByEntityId(String entityId) async =>
      ops.removeWhere((op) => op['entityId'] == entityId);
}

class _Online implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Servidor de mentira: valida como `CreatePrinterSettingsDto`
/// (lista blanca de campos) y responde como el real.
class _Server implements PrinterSettingsRemoteDataSource {
  final rows = <String, PrinterSettings>{};
  int creates = 0, deletes = 0, _next = 1;

  static const _fields = {
    'name', 'connectionType', 'ipAddress', 'port', 'usbPath',
    'paperSize', 'autoCut', 'cashDrawer', 'isDefault',
  };

  void _validate(Map<String, dynamic> d) {
    final errors = <String>[
      for (final k in d.keys)
        if (!_fields.contains(k)) 'property $k should not exist',
      if (d['name'] is! String || (d['name'] as String).length > 100)
        'name must be a string shorter than or equal to 100 characters',
      if (!const ['network', 'usb'].contains(d['connectionType']))
        'connectionType must be one of: network, usb',
      if (!const ['mm58', 'mm80'].contains(d['paperSize']))
        'paperSize must be one of: mm58, mm80',
    ];
    if (errors.isNotEmpty) {
      throw ServerException(
        'Solicitud incorrecta: ${errors.join(', ')}',
        statusCode: 400,
      );
    }
  }

  PrinterSettings _build(String id, Map<String, dynamic> d) {
    final now = DateTime.now();
    return PrinterSettings(
      id: id,
      name: d['name'] as String,
      connectionType: d['connectionType'] == 'usb'
          ? PrinterConnectionType.usb
          : PrinterConnectionType.network,
      ipAddress: d['ipAddress'] as String?,
      port: d['port'] as int?,
      usbPath: d['usbPath'] as String?,
      paperSize: d['paperSize'] == 'mm58' ? PaperSize.mm58 : PaperSize.mm80,
      autoCut: d['autoCut'] as bool? ?? true,
      cashDrawer: d['cashDrawer'] as bool? ?? false,
      isDefault: d['isDefault'] as bool? ?? false,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<PrinterSettings> createPrinterSetting(Map<String, dynamic> data) async {
    _validate(data);
    creates++;
    final id =
        '00000000-0000-4000-8000-${(_next++).toString().padLeft(12, '0')}';
    return rows[id] = _build(id, data);
  }

  @override
  Future<PrinterSettings> updatePrinterSetting(
    String id,
    Map<String, dynamic> data,
  ) async {
    if (!rows.containsKey(id)) {
      throw const ServerException(
        'Recurso no encontrado: Impresora no encontrada',
        statusCode: 404,
      );
    }
    _validate(data);
    return rows[id] = _build(id, data);
  }

  @override
  Future<void> deletePrinterSetting(String id) async {
    deletes++;
    if (rows.remove(id) == null) {
      throw const ServerException(
        'Recurso no encontrado: Impresora no encontrada',
        statusCode: 404,
      );
    }
  }

  @override
  Future<List<PrinterSettings>> getAllPrinterSettings() async =>
      rows.values.toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Invoice _invoice(String number) {
  final now = DateTime.now();
  return Invoice(
    id: 'id-$number',
    number: number,
    date: now,
    dueDate: now,
    status: InvoiceStatus.paid,
    paymentMethod: PaymentMethod.cash,
    subtotal: 5000,
    taxPercentage: 0,
    taxAmount: 0,
    discountPercentage: 0,
    discountAmount: 0,
    total: 5000,
    paidAmount: 5000,
    balanceDue: 0,
    customerId: 'c1',
    createdById: 'u1',
    items: [
      for (var i = 1; i <= 2; i++)
        InvoiceItem(
          id: 'i$i',
          description: 'Producto de prueba $i',
          quantity: 1,
          unitPrice: 2500,
          discountPercentage: 0,
          discountAmount: 0,
          subtotal: 2500,
          invoiceId: 'id-$number',
          createdAt: now,
          updatedAt: now,
        ),
    ],
    payments: const [],
    createdAt: now,
    updatedAt: now,
  );
}

Future<ImpresorasProbeResult> runImpresorasProbe({
  required ImpresorasProbeConfig config,
  required void Function(String line) log,
}) async {
  var failures = 0;
  var steps = 0;
  final problems = <String>[];
  printerProblemSink = (op, error, _) => problems.add('$op: $error');

  void out(String step, String state, [String detail = '']) =>
      log('PRUEBA IMPRESORAS | $step | $state${detail.isEmpty ? '' : ' | $detail'}');

  Future<void> step(String name, Future<String?> Function() body) async {
    steps++;
    try {
      final problem = await body().timeout(const Duration(seconds: 90));
      if (problem == null) {
        out(name, 'OK');
      } else if (problem.startsWith('OMITIDA')) {
        steps--;
        out(name, 'OMITIDA', problem.substring(7).trim());
      } else {
        failures++;
        out(name, 'FALLA', problem);
      }
    } catch (e, st) {
      failures++;
      out(name, 'FALLA', 'excepción: $e');
      log(st.toString().split('\n').take(6).join('\n'));
    }
  }

  log('PRUEBA IMPRESORAS | inicio | ${config.label} | '
      '${Platform.operatingSystem} ${Platform.operatingSystemVersion}');

  final dir = await Directory.systemTemp.createTemp('baudex_impresoras_probe');
  late Isar isar;
  Future<void> openDb() async {
    isar = await Isar.open(IsarDatabase.schemas, directory: dir.path);
    IsarDatabase.debugSetDatabase(isar);
  }

  final server = _Server();
  late _Queue queue;
  late SettingsController settings;
  late ThermalPrinterController thermal;

  /// Arranque de la app: todo en memoria se crea de nuevo.
  Future<void> start() async {
    Get.reset();
    queue = _Queue();
    Get.put<SyncService>(queue);
    final repo = SettingsRepositoryImpl(
      localDataSource: SettingsLocalDataSourceImpl(),
      printerRemoteDataSource: server,
      networkInfo: _Online(),
    );
    settings = Get.put<SettingsController>(
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
    await settings.loadPrinterSettings();
    thermal = Get.put(ThermalPrinterController());
  }

  /// Apagar el equipo y volver a abrir Baudex.
  Future<void> restart() async {
    Get.reset();
    IsarDatabase.debugSetDatabase(null);
    await isar.close();
    await openDb();
    await start();
  }

  PrinterSettings form({required String name, String? usb, String? ip, int? port}) {
    final id = 'printer_offline_${DateTime.now().microsecondsSinceEpoch}';
    return usb != null
        ? PrinterSettings.usbPrinter(id: id, name: name, usbPath: usb)
        : PrinterSettings.networkPrinter(
            id: id,
            name: name,
            ipAddress: ip!,
            port: port ?? 9100,
          );
  }

  PrinterSettings? byName(String name) =>
      settings.printerSettings.firstWhereOrNull((p) => p.name == name);

  int outputSize() {
    final path = config.printerOutput;
    if (path == null) return -1;
    final f = File(path);
    return f.existsSync() ? f.lengthSync() : 0;
  }

  Future<bool> outputGrew(int before) async {
    for (var i = 0; i < 100; i++) {
      if (outputSize() > before) return true;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return false;
  }

  final usbName = config.windowsPrinter ?? 'POS 80 Printer (copia 1)';
  final canPrint = Platform.isWindows && config.windowsPrinter != null;

  // Una impresora de red de mentira: un puerto local que recibe.
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  var networkBytes = 0;
  socket.listen((client) {
    client.listen((data) => networkBytes += data.length, onError: (_) {});
  });

  var prefsBroke = false;
  try {
    // ---- 0. Preferencias dañadas: ANTES de que nadie las lea ----
    await step('preferencias del equipo dañadas: se detecta', () async {
      final file = config.prefsFile;
      if (file == null) return 'OMITIDA sin archivo de preferencias';
      file.parent.createSync(recursive: true);
      // Como queda tras un apagón a media escritura.
      file.writeAsBytesSync([...utf8.encode('{"flutter.default_pr'), 0, 0, 0, 0]);
      try {
        await SharedPreferences.getInstance();
        // Informativo: en este equipo el complemento tolera el archivo
        // dañado, así que no hay nada que reparar.
        log('PRUEBA IMPRESORAS | el complemento falla con el archivo dañado | NO');
        prefsBroke = false;
      } catch (e) {
        log('PRUEBA IMPRESORAS | el complemento falla con el archivo dañado | SÍ: $e');
        prefsBroke = true;
      }
      return null;
    });

    await openDb();
    await start();

    await step('alta USB (primera impresora del equipo)', () async {
      await settings.savePrinterSettings(form(name: 'Caja', usb: usbName));
      final p = byName('Caja');
      if (p == null) return 'no aparece en la lista (${settings.printerSettings.length})';
      if (server.creates != 1) return 'POST al servidor: ${server.creates}';
      if (settings.defaultPrinter?.id != p.id) return 'no quedó para facturar';
      if (!RegExp(r'^[0-9a-f-]{36}$').hasMatch(p.id)) return 'id local: ${p.id}';
      return null;
    });

    await step('preferencias del equipo: quedaron reparadas', () async {
      final file = config.prefsFile;
      if (file == null) return 'OMITIDA sin archivo de preferencias';
      if (!prefsBroke) return 'OMITIDA el complemento no falló';
      final prefs = await SharedPreferences.getInstance();
      final chosen = prefs.getString('default_printer_id');
      final aside = file.parent.listSync().any(
        (f) => f.path.contains('shared_preferences.json.danado-'),
      );
      if (!aside) return 'el archivo dañado no se apartó';
      if (chosen != settings.defaultPrinter?.id) return 'elección guardada: $chosen';
      if (!problems.any((p) => p.contains('preferencias del equipo'))) {
        return 'el fallo no quedó registrado';
      }
      return null;
    });

    await step('página de prueba', () async {
      if (!canPrint) return 'OMITIDA sin impresora de Windows';
      final before = outputSize();
      final ok = await settings.printTestPage(byName('Caja')!);
      if (!ok) return 'no imprimió: ${thermal.lastError}';
      return await outputGrew(before) ? null : 'nada llegó al archivo';
    });

    await step('apagar y prender: la factura encuentra la impresora', () async {
      await restart();
      final ready = await thermal.ensurePrinterConfigLoaded();
      if (!ready) return 'No hay impresora configurada';
      if (thermal.currentPrinterConfig?.usbPath != usbName) {
        return 'impresora: ${thermal.currentPrinterConfig?.usbPath}';
      }
      return settings.printerSettings.length == 1
          ? null
          : 'lista: ${settings.printerSettings.length}';
    });

    await step('factura por USB', () async {
      if (!canPrint) return 'OMITIDA sin impresora de Windows';
      final before = outputSize();
      final ok = await thermal.printInvoice(_invoice('FV-PRUEBA-1'));
      if (!ok) return 'no imprimió: ${thermal.lastError}';
      return await outputGrew(before) ? null : 'nada llegó al archivo';
    });

    await step('alta de red', () async {
      await settings.savePrinterSettings(
        form(name: 'Cocina', ip: '127.0.0.1', port: socket.port),
      );
      if (byName('Cocina') == null) return 'no aparece en la lista';
      if (settings.printerSettings.length != 2) {
        return 'lista: ${settings.printerSettings.length}';
      }
      if (settings.defaultPrinter?.name != 'Caja') {
        return 'cambió la de facturar: ${settings.defaultPrinter?.name}';
      }
      return server.creates == 2 ? null : 'POST: ${server.creates}';
    });

    await step('eliminar la USB: se factura por la de red', () async {
      final id = byName('Caja')!.id;
      await settings.deletePrinterSettings(id);
      if (byName('Caja') != null) return 'sigue en la lista';
      if (server.rows.containsKey(id)) return 'sigue en el servidor';
      if (queue.ops.isNotEmpty) return 'quedó en cola: ${queue.ops}';
      if (settings.defaultPrinter?.name != 'Cocina') {
        return 'para facturar: ${settings.defaultPrinter?.name}';
      }
      await thermal.ensurePrinterConfigLoaded();
      final before = networkBytes;
      final ok = await thermal.printInvoice(_invoice('FV-PRUEBA-2'));
      if (!ok) return 'la factura de red no salió: ${thermal.lastError}';
      for (var i = 0; i < 50 && networkBytes == before; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      return networkBytes > before ? null : 'nada llegó a la impresora de red';
    });

    await step('agregar → eliminar → agregar', () async {
      for (var i = 0; i < 3; i++) {
        await settings.savePrinterSettings(form(name: 'Barra', usb: usbName));
        final p = byName('Barra');
        if (p == null) return 'vuelta $i: no se agregó';
        await settings.deletePrinterSettings(p.id);
        if (byName('Barra') != null) return 'vuelta $i: no se eliminó';
      }
      await settings.savePrinterSettings(form(name: 'Barra', usb: usbName));
      if (byName('Barra') == null) return 'la última alta no quedó';
      if (queue.ops.isNotEmpty) return 'cola: ${queue.ops}';
      final stored = await isar.printerSettingsModels.count();
      return stored == 2 ? null : 'filas en la base: $stored';
    });

    await step('base con restos de versiones anteriores', () async {
      PrinterSettingsModel old(String id, {bool deleted = false}) =>
          PrinterSettingsModel.fromEntity(
              PrinterSettings.usbPrinter(
                id: id,
                name: 'Resto $id',
                usbPath: 'Vieja',
                isDefault: true,
              ),
            )
            ..deletedAt = deleted ? DateTime(2026, 11, 20) : null;
      await isar.writeTxn(
        () => isar.printerSettingsModels.putAll([
          old(''),
          old('aaaaaaaa-0000-4000-8000-000000000001', deleted: true),
          old('printer_offline_1764000000000'),
        ]),
      );
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('default_printer_id', 'ya-no-existe');
      } catch (_) {}
      await restart();
      await settings.savePrinterSettings(form(name: 'Nueva', usb: usbName));
      if (byName('Nueva') == null) return 'no se agregó';
      await settings.setDefaultPrinter(byName('Nueva')!.id);
      await restart();
      final ready = await thermal.ensurePrinterConfigLoaded();
      if (!ready) return 'tras reiniciar no hay impresora';
      if (settings.defaultPrinter?.name != 'Nueva') {
        return 'para facturar: ${settings.defaultPrinter?.name}';
      }
      for (final p in [...settings.printerSettings]) {
        await settings.deletePrinterSettings(p.id);
      }
      return settings.printerSettings.isEmpty
          ? null
          : 'no se pudieron eliminar: ${settings.printerSettings.map((p) => p.name)}';
    });

    await step('impresora que no está instalada en este equipo: aviso claro', () async {
      if (!Platform.isWindows) return 'OMITIDA solo aplica en Windows';
      await settings.savePrinterSettings(
        form(name: 'De otro equipo', usb: 'Impresora-Que-No-Existe-123'),
      );
      await thermal.ensurePrinterConfigLoaded();
      final ok = await thermal.printInvoice(_invoice('FV-PRUEBA-3'));
      if (ok) return 'dijo que imprimió en una impresora que no existe';
      final message = thermal.lastError ?? '';
      log('PRUEBA IMPRESORAS | aviso mostrado | $message');
      return message.contains('no está instalada en este equipo')
          ? null
          : 'aviso: $message';
    });
  } finally {
    await socket.close();
    try {
      Get.reset();
      IsarDatabase.debugSetDatabase(null);
      await isar.close(deleteFromDisk: true);
      await dir.delete(recursive: true);
    } catch (_) {}
  }

  for (final p in problems) {
    log('PRUEBA IMPRESORAS | fallo registrado | $p');
  }
  log('PRUEBA IMPRESORAS | RESULTADO: '
      '${failures == 0 ? 'CUMPLE' : 'FALLA'} — ${steps - failures} de $steps pasos');
  return ImpresorasProbeResult(failures, steps);
}
