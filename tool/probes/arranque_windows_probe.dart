// tool/probes/arranque_windows_probe.dart
//
// App de medición del ARRANQUE y del INICIO DE SESIÓN, con reloj real.
// Abre la app de verdad (llama al `main()` de lib/main.dart) contra un
// servidor de mentira en 127.0.0.1 que cuenta cada petición, con la base
// local en una carpeta de prueba. Hay que compilarla con un `.env` que
// apunte a http://127.0.0.1:3990 (SERVER_IP=127.0.0.1, SERVER_PORT=3990,
// APP_ENV=development); si no, se niega a correr. Cada ejecución es UN
// arranque; el job la lanza varias veces seguidas (ver "probar-arranque" en
// .github/workflows/windows-instalador.yml) cambiando el estado de las
// preferencias del equipo: sanas, vacías (recién apartadas) y dañadas.
//
//   flutter build windows --release -t tool/probes/arranque_windows_probe.dart
//
// Variables:
//   BAUDEX_PROBE_OUT    archivo de salida. OBLIGATORIA: sin ella no hace nada
//                       (nunca corre por accidente en el equipo de un cliente).
//   BAUDEX_PROBE_DIR    carpeta de la base local de prueba (se conserva entre
//                       arranques de una misma serie). OBLIGATORIA.
//   BAUDEX_PROBE_PASO   nombre del paso para el log ("instalar", "dañadas"…).
//   BAUDEX_PROBE_LABEL  etiqueta (p. ej. "1.0.10" o "1.0.9").
//   BAUDEX_PROBE_PREFS  sanas (no tocar) | vacias (borra el archivo) |
//                       danadas (lo deja cortado, como tras un apagón).
//   BAUDEX_PROBE_T0_MS  hora (ms desde 1970) en que se lanzó el proceso.
//   BAUDEX_PROBE_ALMACEN  dat-ceros | dat-cortado | dat-borrado: antes de
//                       arrancar deja así el archivo del almacén seguro
//                       (flutter_secure_storage.dat), como tras un apagón
//                       o un cierre a mitad de escritura (ver
//                       almacen_seguro_windows.dart).
//   BAUDEX_PROBE_ESPERA  directo-copia | login | directo: lo que debe pasar
//                       en este arranque. Si no se cumple (o el almacén no
//                       quedó como se pidió) escribe "PASO VERIFICADO |
//                       FALLA | …" y sale con 5.
//   BAUDEX_PROBE_MAX_LECTURAS  tope de lecturas del archivo del almacén de
//                       sesión en este arranque; si se supera, sale con 5.
//   BAUDEX_PROBE_NEGOCIO a | b: usuario y negocio del servidor de mentira.
//   BAUDEX_PROBE_CERRAR_SESION_AL_SALIR=1  al terminar borra el token (como
//                       si el servidor ya no aceptara la sesión): el arranque
//                       siguiente mide el inicio de sesión.
//   BAUDEX_PROBE_IMPRESORAS=0  no leer las impresoras tras entrar.
//   BAUDEX_PROBE_FACTURAS (6000), BAUDEX_PROBE_PRODUCTOS (3000),
//   BAUDEX_PROBE_LATENCIA_MS (0), BAUDEX_PROBE_MAX_S (180),
//   BAUDEX_PROBE_PUERTO (3990), BAUDEX_PROBE_PRESENTACIONES (2500).
//   BAUDEX_PROBE_HUELLA=nueva  la app cree que se acaba de instalar una
//                       versión nueva (vuelve a bajar todos los módulos).
//   BAUDEX_PROBE_TECLEO=1  mide el tecleo a mano (teclas del sistema a
//                       120 ms): contraseña en iniciar sesión, buscador de
//                       la factura ("500"/"700" + Enter, producto sin
//                       registrar) y abrir Diagnóstico. Líneas
//                       "MEDICION TECLEO | etiqueta | paso | …".
//   BAUDEX_PROBE_TECLEO_REPS (6) repeticiones en la factura.
//   BAUDEX_PROBE_RENDIMIENTO  full (por defecto) | light | auto: tema
//                       completo, liviano forzado o automático.
//   BAUDEX_PROBE_CAPTURAS=<carpeta>  guarda capturas reales de la ventana
//                       (login, tablero, factura, diálogo de sin registrar).
//   BAUDEX_PROBE_CALMA_S (8) espera en calma antes de teclear en la factura.
//   BAUDEX_PROBE_LENTO=1  modo "equipo lento": la app queda con
//                       BAUDEX_PROBE_NUCLEOS (2) núcleos y prioridad baja,
//                       con BAUDEX_PROBE_CARGA_CPU (2) bucles de procesador
//                       y uno de disco al lado, y la ventana maximizada.
//                       Líneas "MEDICION ARRANQUE LENTO | etiqueta | paso |
//                       t=… ms | tarea | duró …" (la línea de tiempo del
//                       arranque sale siempre, con o sin modo lento).
//   BAUDEX_PROBE_SANDBOX=1  almacén seguro y preferencias de mentira dentro
//                       de BAUDEX_PROBE_DIR (siempre así fuera de Windows:
//                       no toca el llavero ni las preferencias del equipo).
//                       En Windows, sin esto, usa los complementos REALES
//                       (DPAPI y shared_preferences.json): solo para el
//                       equipo de pruebas de GitHub.
//
// Líneas "MEDICION ARRANQUE | etiqueta | paso | …". Sale con 0 al terminar,
// 2 si se colgó, 3 si faltan variables.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:baudex_desktop/app/config/constants/api_constants.dart';
import 'package:baudex_desktop/app/config/env/env_config.dart';
import 'package:baudex_desktop/app/config/routes/app_routes.dart';
import 'package:baudex_desktop/app/core/diagnostics/paint_probe.dart';
import 'package:baudex_desktop/app/core/diagnostics/startup_trace.dart';
import 'package:baudex_desktop/app/core/services/audio_notification_service.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/app/core/theme/performance_mode.dart';
import 'package:baudex_desktop/app/core/storage/secure_store_stats.dart';
import 'package:baudex_desktop/app/core/storage/session_startup_trace.dart';
import 'package:baudex_desktop/app/data/local/full_sync_service.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/app/data/local/local_first.dart';
import 'package:baudex_desktop/features/auth/presentation/controllers/auth_controller.dart';
import 'package:baudex_desktop/features/invoices/data/models/isar/isar_invoice.dart';
import 'package:baudex_desktop/app/core/navigation/navigation_guard.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/invoice_tabs_controller.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:baudex_desktop/features/settings/presentation/controllers/settings_controller.dart';
import 'package:baudex_desktop/main.dart' as app;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/types.dart';

import 'almacen_seguro_windows.dart';
import 'arranque_servidor.dart';
import 'equipo_lento.dart';
import 'tecleo_medicion.dart';

// ==================== Preferencias medidas ====================

/// Cuenta y cronometra cada escritura de preferencias (en Windows cada una
/// reescribe el archivo entero en el hilo de la pantalla).
class _TimedPrefs extends SharedPreferencesStorePlatform {
  _TimedPrefs(this._inner);
  final SharedPreferencesStorePlatform _inner;
  int writes = 0;
  int failedReads = 0;
  double writeMs = 0;
  double worstWriteMs = 0;

  Future<T> _timed<T>(Future<T> Function() op) async {
    final watch = Stopwatch()..start();
    try {
      return await op();
    } finally {
      final ms = watch.elapsedMicroseconds / 1000;
      writes++;
      writeMs += ms;
      if (ms > worstWriteMs) worstWriteMs = ms;
    }
  }

  Future<T> _read<T>(Future<T> Function() op) async {
    try {
      return await op();
    } catch (_) {
      failedReads++;
      rethrow;
    }
  }

  @override
  Future<Map<String, Object>> getAll() => _read(_inner.getAll);
  @override
  Future<Map<String, Object>> getAllWithParameters(GetAllParameters parameters) =>
      _read(() => _inner.getAllWithParameters(parameters));
  @override
  Future<bool> setValue(String valueType, String key, Object value) =>
      _timed(() => _inner.setValue(valueType, key, value));
  @override
  Future<bool> remove(String key) => _timed(() => _inner.remove(key));
  @override
  Future<bool> clear() => _timed(_inner.clear);
  @override
  Future<bool> clearWithParameters(ClearParameters parameters) =>
      _timed(() => _inner.clearWithParameters(parameters));
}

/// Cuenta y cronometra cada operación del almacén de sesión (en Windows es
/// un archivo cifrado: cada lectura lo abre y lo descifra).
class _TimedSecure extends FlutterSecureStoragePlatform {
  _TimedSecure(this._inner);
  final FlutterSecureStoragePlatform _inner;
  int reads = 0;
  int writes = 0;
  double readMs = 0;
  double worstReadMs = 0;
  double writeMs = 0;

  Future<T> _time<T>(bool read, Future<T> Function() op) async {
    final watch = Stopwatch()..start();
    try {
      return await op();
    } finally {
      final ms = watch.elapsedMicroseconds / 1000;
      if (read) {
        reads++;
        readMs += ms;
        if (ms > worstReadMs) worstReadMs = ms;
      } else {
        writes++;
        writeMs += ms;
      }
    }
  }

  @override
  Future<String?> read({required String key, required Map<String, String> options}) =>
      _time(true, () => _inner.read(key: key, options: options));
  @override
  Future<bool> containsKey({required String key, required Map<String, String> options}) =>
      _time(true, () => _inner.containsKey(key: key, options: options));
  @override
  Future<Map<String, String>> readAll({required Map<String, String> options}) =>
      _time(true, () => _inner.readAll(options: options));
  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) =>
      _time(false, () => _inner.write(key: key, value: value, options: options));
  @override
  Future<void> delete({required String key, required Map<String, String> options}) =>
      _time(false, () => _inner.delete(key: key, options: options));
  @override
  Future<void> deleteAll({required Map<String, String> options}) =>
      _time(false, () => _inner.deleteAll(options: options));
}

/// Preferencias de mentira que se portan como el complemento de Windows: un
/// archivo JSON que se lee una vez, se reescribe entero en cada cambio y,
/// si está dañado, lanza `FormatException` en cada lectura.
class _FilePrefs extends SharedPreferencesStorePlatform {
  _FilePrefs(this.file);
  final File file;
  Map<String, Object>? _cache;

  Map<String, Object> _load() {
    final cached = _cache;
    if (cached != null) return cached;
    var data = <String, Object>{};
    if (file.existsSync()) {
      final text = file.readAsStringSync();
      if (text.isNotEmpty) {
        data = (json.decode(text) as Map<String, dynamic>).cast<String, Object>();
      }
    }
    return _cache = data;
  }

  void _save() => file.writeAsStringSync(json.encode(_cache));

  @override
  Future<Map<String, Object>> getAll() async => Map.of(_load());
  @override
  Future<Map<String, Object>> getAllWithParameters(GetAllParameters parameters) async {
    final prefix = parameters.filter.prefix;
    return {
      for (final e in _load().entries)
        if (e.key.startsWith(prefix)) e.key: e.value,
    };
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    _load()[key] = value;
    _save();
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _load().remove(key);
    _save();
    return true;
  }

  @override
  Future<bool> clear() async {
    _load().clear();
    _save();
    return true;
  }

  @override
  Future<bool> clearWithParameters(ClearParameters parameters) async {
    _load().removeWhere((k, _) => k.startsWith(parameters.filter.prefix));
    _save();
    return true;
  }
}

/// Almacén seguro de mentira que se guarda en un archivo de la carpeta de
/// prueba (para que la sesión sobreviva entre arranques sin tocar el llavero).
class _FileSecureStore extends TestFlutterSecureStoragePlatform {
  _FileSecureStore(this.file, Map<String, String> data) : super(data);
  final File file;

  static _FileSecureStore open(File file) {
    var data = <String, String>{};
    try {
      if (file.existsSync()) {
        data = (json.decode(file.readAsStringSync()) as Map).cast<String, String>();
      }
    } catch (_) {}
    return _FileSecureStore(file, data);
  }

  void _save() => file.writeAsStringSync(json.encode(data));

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async {
    await super.write(key: key, value: value, options: options);
    _save();
  }

  @override
  Future<void> delete({required String key, required Map<String, String> options}) async {
    await super.delete(key: key, options: options);
    _save();
  }

  @override
  Future<void> deleteAll({required Map<String, String> options}) async {
    await super.deleteAll(options: options);
    _save();
  }
}

// ==================== Trabas del hilo de la pantalla ====================

class _Stalls {
  static const _every = Duration(milliseconds: 8);
  final Stopwatch _clock = Stopwatch()..start();
  int _last = 0;
  int over100 = 0;
  int over500 = 0;
  double worstMs = 0;
  double stalledMs = 0;

  /// Reloj (ms) de la última traba de más de 100 ms.
  int lastBigStallAt = 0;

  void start() {
    _last = _clock.elapsedMicroseconds;
    Timer.periodic(_every, (_) {
      final now = _clock.elapsedMicroseconds;
      final late = (now - _last) / 1000 - _every.inMilliseconds;
      _last = now;
      if (late > 100) {
        over100++;
        stalledMs += late;
        lastBigStallAt = _clock.elapsedMilliseconds;
      }
      if (late > 500) over500++;
      if (late > worstMs) worstMs = late;
    });
  }

  int get nowMs => _clock.elapsedMilliseconds;

  void reset() {
    over100 = 0;
    over500 = 0;
    worstMs = 0;
    stalledMs = 0;
  }
}

String _f(num ms) => ms.toStringAsFixed(0);

/// Captura REAL de la ventana (lo que pintó el motor, con desenfoques y
/// sombras) a un PNG. Devuelve la ruta o un texto con el motivo.
Future<String> _capture(String dir, String name) async {
  try {
    final view = WidgetsBinding.instance.renderViews.first;
    // ignore: invalid_use_of_protected_member
    final layer = view.layer! as OffsetLayer;
    // La capa raíz está en píxeles del equipo (pantallas de alta densidad).
    final size = view.size * view.flutterView.devicePixelRatio;
    final image = await layer.toImage(Offset.zero & size, pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final safe = name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    final file = File('$dir${Platform.pathSeparator}$safe.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(data!.buffer.asUint8List());
    return file.path;
  } catch (e) {
    return 'no se pudo capturar ($e)';
  }
}

Future<void> main() async {
  final bootAt = DateTime.now().millisecondsSinceEpoch;
  WidgetsFlutterBinding.ensureInitialized();
  final env = Platform.environment;
  final outPath = env['BAUDEX_PROBE_OUT'] ?? '';
  final dirPath = env['BAUDEX_PROBE_DIR'] ?? '';
  if (outPath.isEmpty || dirPath.isEmpty) exit(3);

  final label = env['BAUDEX_PROBE_LABEL'] ?? '';
  final step = env['BAUDEX_PROBE_PASO'] ?? 'paso';
  int number(String key, int fallback) => int.tryParse(env[key] ?? '') ?? fallback;
  final maxSeconds = number('BAUDEX_PROBE_MAX_S', 180);
  final launchedAt = number('BAUDEX_PROBE_T0_MS', bootAt);
  final lento = env['BAUDEX_PROBE_LENTO'] == '1';
  final notasLento = <String>[];
  if (lento) {
    notasLento.add(limitarProceso(number('BAUDEX_PROBE_NUCLEOS', 2)));
    notasLento.add(await cargaDeFondo(
      cpu: number('BAUDEX_PROBE_CARGA_CPU', 2),
      dir: '$dirPath${Platform.pathSeparator}carga',
    ));
  }

  final sink = File(outPath);
  sink.parent.createSync(recursive: true);
  void log(String text) {
    final line = 'MEDICION ARRANQUE | $label | $step | $text';
    // ignore: avoid_print
    print(line);
    sink.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
  }

  Timer(Duration(seconds: maxSeconds + 90), () {
    log('NO TERMINÓ en ${maxSeconds + 90} s');
    exit(2);
  });

  var flutterErrors = 0;
  FlutterError.onError = (details) {
    if (++flutterErrors <= 3) {
      log('aviso de Flutter: ${details.exceptionAsString().split('\n').first}');
    }
  };

  final dir = Directory(dirPath)..createSync(recursive: true);
  final sep = Platform.pathSeparator;
  final sandbox = !Platform.isWindows || env['BAUDEX_PROBE_SANDBOX'] == '1';

  // ---------- Preferencias del equipo en el estado pedido ----------
  final File prefsFile;
  if (sandbox) {
    prefsFile = File('${dir.path}${sep}shared_preferences.json');
  } else {
    final support = await getApplicationSupportDirectory();
    prefsFile = File('${support.path}${sep}shared_preferences.json');
  }
  final prefsState = env['BAUDEX_PROBE_PREFS'] ?? 'sanas';
  if (prefsState == 'vacias') {
    if (prefsFile.existsSync()) prefsFile.deleteSync();
  } else if (prefsState == 'danadas') {
    // Cortado a la mitad y con ceros, como queda tras un apagón al escribir.
    final text = prefsFile.existsSync() ? prefsFile.readAsStringSync() : '{"flutter.x":"y"}';
    final half = text.substring(0, (text.length / 2).ceil().clamp(1, text.length));
    prefsFile.parent.createSync(recursive: true);
    prefsFile.writeAsBytesSync([...utf8.encode(half), ...List.filled(64, 0)]);
  }
  String prefsHealth() {
    if (!prefsFile.existsSync()) return 'no existe';
    final bytes = prefsFile.lengthSync();
    try {
      final text = prefsFile.readAsStringSync();
      if (text.isNotEmpty) json.decode(text);
      return 'sano ($bytes bytes)';
    } catch (_) {
      return 'DAÑADO ($bytes bytes)';
    }
  }

  int setAside() => prefsFile.parent
      .listSync()
      .where((f) => f.path.contains('shared_preferences.json.danado-'))
      .length;

  log('preferencias al abrir: $prefsState → archivo ${prefsHealth()}'
      '${sandbox ? ' (almacenes de mentira)' : ' (complementos reales de Windows)'}');

  if (sandbox) {
    SharedPreferencesStorePlatform.instance = _FilePrefs(prefsFile);
    FlutterSecureStoragePlatform.instance =
        _FileSecureStore.open(File('${dir.path}${sep}almacen_seguro.json'));
  }
  // ---------- Almacén seguro en el estado pedido ----------
  // BAUDEX_PROBE_ALMACEN: dat-ceros | dat-cortado | dat-borrado. Va ANTES
  // de que la app toque el almacén (ver almacen_seguro_windows.dart).
  final storeState = env['BAUDEX_PROBE_ALMACEN'] ?? '';
  final expectation = env['BAUDEX_PROBE_ESPERA'] ?? '';
  final stepProblems = <String>[];
  if (!sandbox) {
    final support = await getApplicationSupportDirectory();
    log(describeSessionOnDisk(support, prefsFile));
    if (storeState.isNotEmpty) {
      final done = sabotageSecureStorage(support, storeState);
      log('almacén seguro ($secureStorageFileName): '
          '${done == null ? 'NO había archivo que tocar' : 'dejado $done'}');
      if (done == null) {
        stepProblems.add('no había archivo del almacén seguro: el paso no simula nada');
      } else if (storeState == 'dat-borrado') {
        // Aquí sí se puede leer sin alterar lo que verá la app.
        String? value;
        try {
          value = await const FlutterSecureStorage().read(key: ApiConstants.tokenKey);
        } catch (e) {
          log('almacén seguro al leer: error $e');
        }
        log('almacén seguro devolvió: ${value == null ? 'null' : 'valor'}');
        if (value != null) {
          stepProblems.add('el almacén seguro siguió devolviendo el token: el paso no simula nada');
        }
      } else {
        // Dañado: no se lee aquí (el complemento lo borraría antes de que
        // la app lo vea). Que no se puede leer lo prueba el veredicto: el
        // token debe venir de la copia protegida, o pedirse inicio de sesión.
        log('almacén seguro devolvió: (no se lee antes; la app lo encuentra dañado)');
      }
    }
  } else if (storeState.isNotEmpty) {
    stepProblems.add('el paso necesita los complementos reales de Windows');
  }

  // Después de tocar el almacén: de aquí en adelante se cuenta cada lectura.
  final secure = _TimedSecure(FlutterSecureStoragePlatform.instance);
  FlutterSecureStoragePlatform.instance = secure;
  final prefs = _TimedPrefs(SharedPreferencesStorePlatform.instance);
  SharedPreferencesStorePlatform.instance = prefs;

  // ---------- Servidor de mentira ----------
  final port = number('BAUDEX_PROBE_PUERTO', 3990);
  final server = await startArranqueServer(ArranqueServerConfig(
    invoices: number('BAUDEX_PROBE_FACTURAS', 6000),
    products: number('BAUDEX_PROBE_PRODUCTOS', 3000),
    presentations: number('BAUDEX_PROBE_PRESENTACIONES', 2500),
    latencyMs: number('BAUDEX_PROBE_LATENCIA_MS', 0),
    port: port,
  ));
  final stalls = _Stalls()..start();
  var frames = 0;
  var framesOver100 = 0;
  var requests = 0;
  var changeRequests = 0;
  var lastRequestAt = 0;
  final downloaded = <String, int>{};
  final paths = <String, int>{};
  server.served.listen((r) {
    requests++;
    lastRequestAt = stalls.nowMs;
    paths[r.path] = (paths[r.path] ?? 0) + 1;
    if (r.entity != null) {
      changeRequests++;
      downloaded[r.entity!] = (downloaded[r.entity!] ?? 0) + r.records;
    }
  });

  // ---------- La app de verdad: el `main()` de lib/main.dart ----------
  // La dirección del servidor sale del `.env` con que se compiló: tiene que
  // ser el servidor de mentira, o no se mide nada.
  await EnvConfig.initialize();
  if (EnvConfig.baseUrl != 'http://127.0.0.1:$port/api') {
    log('ABORTADO: la app no apunta al servidor de mentira (${EnvConfig.baseUrl})');
    exit(3);
  }

  final isarWatch = Stopwatch()..start();
  final isar = await Isar.open(
    IsarDatabase.schemas,
    directory: dir.path,
    name: 'medicion_arranque',
  );
  IsarDatabase.debugSetDatabase(isar);
  await IsarDatabase.instance.initialize();
  final openMs = isarWatch.elapsedMilliseconds;
  final invoicesBefore = await isar.isarInvoices.count();
  final productsBefore = await isar.isarProducts.count();
  log('base local al abrir: $invoicesBefore facturas, $productsBefore productos '
      '(abrirla tardó $openMs ms)');

  SchedulerBinding.instance.addTimingsCallback((timings) {
    for (final t in timings) {
      frames++;
      if (t.totalSpan.inMilliseconds > 100) framesOver100++;
    }
  });
  final appWatch = Stopwatch()..start();
  // `main()` no devuelve un Future: termina cuando ya montó la app.
  app.main();
  while (WidgetsBinding.instance.rootElement == null) {
    if (appWatch.elapsed > const Duration(seconds: 60)) {
      log('ABORTADO: la app no llegó a montarse en 60 s');
      exit(2);
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  final mainMs = appWatch.elapsedMilliseconds;
  if (env['BAUDEX_PROBE_HUELLA'] == 'nueva') {
    // Como recién instalada: la huella guardada ya no coincide.
    // ignore: invalid_use_of_visible_for_testing_member
    Get.find<FullSyncService>().debugInstallFingerprint =
        () async => 'medicion|$bootAt';
    log('huella de instalación: NUEVA (la app cree que se acaba de actualizar)');
  }
  final tecleo = env['BAUDEX_PROBE_TECLEO'] == '1';
  final medidor = MedidorDeTecleo();
  void logTecleo(String text) {
    final line = 'MEDICION TECLEO | $label | $step | $text';
    // ignore: avoid_print
    print(line);
    sink.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
  }

  String veredicto(Tanda tanda) {
    final peor = tanda.peorVisibleMs;
    if (!tanda.todasVisibles) return 'NO CUMPLE (alguna tecla no se vio)';
    return peor != null && peor < 50 ? 'cumple (<50 ms)' : 'NO CUMPLE (peor ${_f(peor ?? -1)} ms)';
  }

  void logLento(String text) {
    final line = 'MEDICION ARRANQUE LENTO | $label | $step | $text';
    // ignore: avoid_print
    print(line);
    sink.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
  }

  final capturas = env['BAUDEX_PROBE_CAPTURAS'] ?? '';
  Future<void> captura(String what) async {
    if (capturas.isEmpty) return;
    final mode = env['BAUDEX_PROBE_RENDIMIENTO'] ?? 'full';
    logLento('captura $what: ${await _capture(capturas, '${step.split(' ').first}-$mode-$what')}');
  }

  // Tema de la medición: completo (por defecto, para comparar versiones),
  // liviano forzado o automático (la app decide según cómo pinta).
  await PerformanceMode.choose(
    PerformanceSetting.fromId(env['BAUDEX_PROBE_RENDIMIENTO'] ?? 'full'),
  );
  logLento('modo: ${lento ? 'EQUIPO LENTO' : 'normal'}'
      '${notasLento.isEmpty ? '' : '; ${notasLento.join('; ')}'}');
  if (StartupTrace.instance.phases.isEmpty) {
    // Versión anterior sin instrumentar: al menos las trabas y los cuadros.
    StartupTrace.instance.startPhase('al abrir');
  }
  // La ventana, ¿atiende el teclado durante el arranque? Una tecla que la
  // app no usa cada 100 ms, desde ya y por 15 s (splash + iniciar sesión).
  Future<Latido>? latidoArranque;
  if (tecleo) {
    medidor.start();
    if (lento) maximizarVentana();
    await ventanaAlFrente();
    latidoArranque = medidor.latido(seconds: 15);
  }

  // ¿Cuánto tarda la app en saber si hay sesión? El splash decide a los
  // 2.500 ms con lo que haya: si aún no se sabe, manda a iniciar sesión.
  int? sessionKnownMs;
  bool? sessionAtStart;
  unawaited(Get.find<SecureStorageService>().isAuthenticated().then((value) {
    sessionKnownMs = appWatch.elapsedMilliseconds;
    sessionAtStart = value;
  }));

  int? firstFrameMs;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    firstFrameMs = DateTime.now().millisecondsSinceEpoch - launchedAt;
  });

  Future<bool> until(bool Function() test, {required int seconds}) async {
    final deadline = stalls.nowMs + seconds * 1000;
    while (!test()) {
      if (stalls.nowMs > deadline) return false;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    return true;
  }

  String route() => Get.currentRoute;
  bool onLogin() => route() == AppRoutes.login;
  bool onDashboard() => route() == AppRoutes.dashboard;

  await until(() => onLogin() || onDashboard(), seconds: 60);
  final firstScreenMs = DateTime.now().millisecondsSinceEpoch - launchedAt;
  final direct = onDashboard();
  log('preparar la app (main): $mainMs ms; proceso → primer cuadro: ${_f(firstFrameMs ?? -1)} ms; '
      'proceso → primera pantalla: $firstScreenMs ms '
      '(${direct ? 'PRINCIPAL: entra directo' : onLogin() ? 'INICIAR SESIÓN' : 'ninguna: ${route()}'})');
  log('¿hay sesión guardada?: ${sessionAtStart == null ? 'aún no se sabe' : sessionAtStart! ? 'sí' : 'no'}; '
      'la app lo supo a los ${sessionKnownMs ?? '>${appWatch.elapsedMilliseconds}'} ms '
      '(el splash decide a los 2500 ms)');
  // Lo mismo que queda en Diagnóstico para el dueño del negocio.
  log('diagnóstico | ${SessionStartupTrace.sessionLine()}');
  log('diagnóstico | ${SessionStartupTrace.prefsLine()}');
  // ---------- Veredicto del paso (si el job pidió uno) ----------
  final firstScreen = direct ? 'principal' : onLogin() ? 'login' : 'otra';
  var mixed = false;
  String? savedUserOrg;
  try {
    final storage = Get.find<SecureStorageService>();
    final user = await storage.getUserData();
    final org = await storage.getCurrentOrganization();
    final token = await storage.getToken();
    final esperado = probeOrganizationId;
    final delUsuario = user?['organizationId'];
    final delNegocio = org?['id'];
    final mezclada = token != null &&
        ((delUsuario != null && delUsuario != esperado) ||
            (delNegocio != null && delNegocio != esperado));
    mixed = mezclada;
    savedUserOrg = delUsuario?.toString();
    log('sesión guardada | token: ${token == null ? 'no' : 'sí'}; '
        'negocio del usuario: ${delUsuario ?? '-'}; negocio guardado: ${delNegocio ?? '-'}; '
        'negocio de esta corrida: $esperado'
        '${mezclada ? ' | MEZCLADA CON OTRO NEGOCIO' : ''}');
  } catch (e) {
    log('sesión guardada | no se pudo leer: $e');
  }
  if (!sandbox) {
    try {
      final support = await getApplicationSupportDirectory();
      log('tras arrancar | ${describeSessionOnDisk(support, prefsFile)} | '
          'la app dice: ${SessionStartupTrace.storageMode}');
    } catch (_) {}
  }
  if (expectation.isNotEmpty) {
    // directo-copia: entra directo y el token vino de la copia protegida.
    // login: la primera pantalla es iniciar sesión.
    // directo: entra directo (sin exigir de dónde vino el token).
    switch (expectation) {
      case 'directo-copia':
        if (firstScreen != 'principal') {
          stepProblems.add('debía entrar directo y la primera pantalla fue: $firstScreen');
        }
        if (SessionStartupTrace.tokenSource != 'copia protegida') {
          stepProblems.add(
            'el token no vino de la copia protegida (vino de: ${SessionStartupTrace.tokenSource ?? 'no se sabe'})',
          );
        }
        if (savedUserOrg != probeOrganizationId) {
          stepProblems.add('la sesión es de otro negocio: $savedUserOrg');
        }
      case 'login':
        if (firstScreen != 'login') {
          stepProblems.add('debía pedir iniciar sesión y la primera pantalla fue: $firstScreen');
        }
      case 'directo':
        if (firstScreen != 'principal') {
          stepProblems.add('debía entrar directo y la primera pantalla fue: $firstScreen');
        }
      default:
        stepProblems.add('expectativa desconocida: $expectation');
    }
    if (mixed) stepProblems.add('sesión MEZCLADA con otro negocio');
    log('PASO VERIFICADO | ${stepProblems.isEmpty ? 'OK' : 'FALLA'} | espera: $expectation'
        '${storeState.isEmpty ? '' : '; almacén: $storeState'}'
        '${stepProblems.isEmpty ? '' : ' | ${stepProblems.join('; ')}'}');
  }

  /// Espera a que la pantalla deje de trabarse: 600 ms seguidos sin una
  /// traba de más de 100 ms. Devuelve los ms desde [from].
  Future<int> usable(int from) async {
    await until(
      () => stalls.nowMs - (stalls.lastBigStallAt > from ? stalls.lastBigStallAt : from) >= 600,
      seconds: maxSeconds,
    );
    final quietSince = stalls.lastBigStallAt > from ? stalls.lastBigStallAt : from;
    return quietSince - from;
  }

  // ---------- Iniciar sesión (si la app lo pide) ----------
  if (onLogin()) {
    final auth = Get.find<AuthController>();
    if (!await until(() => auth.loginFormKey.currentState != null, seconds: 30)) {
      // Sin cuadros no hay formulario (ventana tapada o equipo dormido):
      // esta corrida no vale como medición.
      log('MEDICIÓN INVÁLIDA: la pantalla de iniciar sesión no se dibujó '
          '(cuadros: $frames)');
      exit(4);
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await captura('login');
    if (tecleo) {
      logTecleo(await ventanaAlFrente());
      EditableTextState? box;
      for (final candidate in cajasDeTexto()) {
        if (identical(candidate.widget.controller, auth.loginPasswordController)) {
          box = candidate;
        }
      }
      if (box == null) {
        logTecleo('iniciar sesión: no se encontró la caja de la contraseña');
      } else {
        box.widget.focusNode.requestFocus();
        await Future<void>.delayed(const Duration(milliseconds: 400));
        final before = requests;
        final syncing = Get.find<FullSyncService>().isSyncing.value;
        final tanda = await medidor.escribir(box, '12345678');
        logTecleo('iniciar sesión, contraseña (8 teclas a 120 ms): ${veredicto(tanda)}; '
            '${tanda.detalle}; ${tanda.cuadrosTexto}; '
            'peticiones mientras tanto: ${requests - before}; descarga en curso: ${syncing ? 'sí' : 'no'}');
      }
    }
    if (tecleo) {
      final arranque = await latidoArranque;
      if (arranque != null) {
        logLento('ventana durante el arranque y el login (15 s): ${arranque.texto}');
      }
      logLento('login recordado: negocio "${auth.loginBusinessController.text}", '
          'correo "${auth.loginEmailController.text.isEmpty ? '(vacío)' : 'sí'}"');
      // La voz: ¿cuánto traba la primera frase?
      final vozLatido = medidor.latido(seconds: 6);
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      final vozStalls = StartupTrace.instance.phases.isEmpty
          ? 0
          : StartupTrace.instance.phases.last.stallsOver50;
      final vozWatch = Stopwatch()..start();
      try {
        await AudioNotificationService.instance.announceProductNotRegistered();
      } catch (e) {
        logLento('la voz lanzó: ${'$e'.split('\n').first}');
      }
      final vozMs = vozWatch.elapsedMilliseconds;
      final voz = await vozLatido;
      logLento('voz, primera frase ("Producto no registrado"): la llamada tardó $vozMs ms; '
          'trabas de la app de más de 50 ms mientras tanto: '
          '${(StartupTrace.instance.phases.isEmpty ? 0 : StartupTrace.instance.phases.last.stallsOver50) - vozStalls}; '
          'ventana: ${voz.texto}');
    }
    auth.loginBusinessController.text = probeBusiness;
    auth.loginEmailController.text = probeEmail;
    auth.loginPasswordController.text = probePassword;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    stalls.reset();
    final requestsBefore = requests;
    final clickAt = stalls.nowMs;
    unawaited(auth.login());
    final entered = await until(onDashboard, seconds: maxSeconds);
    final enteredMs = stalls.nowMs - clickAt;
    if (!entered) {
      log('INICIAR SESIÓN NO ENTRÓ en $maxSeconds s (sigue en ${route()})');
    } else {
      final usableMs = await usable(clickAt + enteredMs);
      log('iniciar sesión → pantalla principal: $enteredMs ms; '
          'principal sin trabas ${usableMs == 0 ? 'de inmediato' : 'tras $usableMs ms más'}; '
          'peticiones hasta entrar: ${requests - requestsBefore}');
    }
  } else if (direct) {
    final usableMs = await usable(stalls.nowMs);
    log('pantalla principal sin trabas ${usableMs == 0 ? 'de inmediato' : 'tras $usableMs ms'}');
  }

  // ---------- ¿Las pantallas leen del equipo o esperan al servidor? ----------
  // Mientras un módulo "no está descargado", cada lista y cada búsqueda va
  // al servidor en vez de la base local.
  final readyFrom = stalls.nowMs;
  final readyAt = <String, int?>{'facturas': null, 'productos': null};
  Future<void> watchReady(String name, IsarCollection<dynamic> collection) async {
    while (stalls.nowMs - readyFrom < (maxSeconds + 30) * 1000) {
      var ready = false;
      try {
        ready = await localCollectionReady(collection);
      } catch (_) {}
      if (ready) {
        readyAt[name] = stalls.nowMs - readyFrom;
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  if (onDashboard()) {
    unawaited(watchReady('facturas', isar.isarInvoices));
    unawaited(watchReady('productos', isar.isarProducts));
  }

  // ---------- Leer impresoras (lo que en 1.0.10 dispara la reparación) ----------
  if (onDashboard() && env['BAUDEX_PROBE_IMPRESORAS'] != '0') {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final storage = Get.find<SecureStorageService>();
    final before = await storage.isAuthenticated();
    try {
      await Get.find<SettingsController>().loadPrinterSettings();
    } catch (e) {
      log('leer impresoras lanzó: ${'$e'.split('\n').first}');
    }
    final after = await storage.isAuthenticated();
    log('sesión antes de leer impresoras: ${before ? 'sí' : 'NO'}; '
        'después: ${after ? 'sí' : 'NO'}'
        '${before && !after ? ' → LA SESIÓN SE PIERDE A MITAD DE USO' : ''}; '
        'archivo de preferencias ahora: ${prefsHealth()}; apartados: ${setAside()}');
  }

  final sync = Get.find<FullSyncService>();

  // ---------- Tecleo a mano en la factura, con la descarga corriendo ----------
  if (tecleo && onDashboard()) {
    logTecleo(await ventanaAlFrente());
    if (frames < 5) {
      logTecleo('MEDICIÓN INVÁLIDA: la ventana no está dibujando (pantalla apagada, bloqueada o tapada)');
    }
    String descarga() => sync.isSyncing.value || sync.hasPendingFullDownload
        ? 'EN CURSO'
        : 'quieta';
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    await captura('tablero');
    final navMark = medidor.marca;
    final navAt = stalls.nowMs;
    // Como el menú lateral, sin la pregunta de "abrir caja" (la medición
    // no abre caja).
    if (Get.isDialogOpen == true) Get.back<void>();
    NavigationGuard.instance.openModule(AppRoutes.invoicesWithTabs);
    final opened = await medidor.esperar(
      () => cajasDeTexto().isNotEmpty && route() == AppRoutes.invoicesWithTabs,
      seconds: 20,
    );
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    logTecleo('abrir crear factura: ${opened ? '${stalls.nowMs - navAt - 1200} ms hasta tener cajas de texto' : 'NO ABRIÓ en 20 s'}; '
        '${medidor.cuadrosDesde(navMark).cuadrosTexto}; descarga: ${descarga()}; '
        'ruta: ${route()}, cajas de texto: ${cajasDeTexto().length}, diálogo abierto: ${Get.isDialogOpen == true}'
        '${opened ? '' : '; en pantalla: ${textosEnPantalla()}'}');

    EditableTextState? buscador() {
      final focused = cajaConFoco();
      if (focused != null) return focused;
      final boxes = cajasDeTexto();
      if (boxes.isEmpty) return null;
      boxes.first.widget.focusNode.requestFocus();
      return boxes.first;
    }

    // Espera en calma antes del primer tecleo: que la pantalla termine de
    // abrirse y de pintarse, para que dos versiones sean comparables.
    final calma = number('BAUDEX_PROBE_CALMA_S', 8);
    await Future<void>.delayed(Duration(seconds: calma));
    logTecleo('factura: $calma s en calma antes de teclear; descarga: ${descarga()}');
    await captura('factura');
    final visibles = <double>[];
    final enters = <double>[];
    final segundos = <double>[];
    var noVistas = 0;
    final reps = number('BAUDEX_PROBE_TECLEO_REPS', 6);
    for (var rep = 1; opened && rep <= reps; rep++) {
      final search = buscador();
      if (search == null) {
        logTecleo('factura $rep: no hay caja de texto para escribir');
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (search.widget.controller.text.isNotEmpty) search.widget.controller.clear();
      final value = rep.isOdd ? '500' : '700';
      final before = requests;
      final state = descarga();
      final stallsBefore = stalls.over100;
      final readsBefore = secure.reads;
      final readMsBefore = secure.readMs;
      final paintsBefore = PaintCounters.snapshot();
      final tanda = await medidor.escribir(search, value);
      final capasTecleo = PaintCounters.since(paintsBefore);
      for (final k in tanda.porTecla) {
        if (k.$4 == null) {
          noVistas++;
        } else {
          visibles.add(k.$4!);
        }
      }
      final card = await medidor.esperar(() => hayTexto('sin registrar'), seconds: 5);
      final enter = await medidor.pulsar(
        teclaEnter,
        () {
          final box = cajaConFoco();
          return box != null && !identical(box, search);
        },
        box: search,
      );
      final nameBox = cajaConFoco();
      if (enter.$2 != null) enters.add(enter.$2!);
      if (rep == 1) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        await captura('sin-registrar');
      }
      String enterText((double?, double?) r) => r.$1 == null
          ? 'NO APARECIÓ en 10 s'
          : '${_f(r.$1!)} ms (visible ${r.$2 == null ? 'n/d' : _f(r.$2!)} ms) → '
              '${r.$1! < 150 ? 'cumple (<150 ms)' : 'NO CUMPLE'}';
      logTecleo('factura $rep "$value" (descarga: $state): tecleo ${veredicto(tanda)}; '
          '${tanda.detalle}; "sin registrar" a la vista: ${card ? 'sí' : 'NO'}; '
          'Enter → campo del nombre con foco: ${enterText(enter)}; '
          '${tanda.cuadrosTexto}; trabas >100 ms: ${stalls.over100 - stallsBefore}; '
          'peticiones mientras tanto: ${requests - before}; '
          'lecturas del almacén de sesión: ${secure.reads - readsBefore} '
          '(${_f(secure.readMs - readMsBefore)} ms); '
          'capas pintadas al teclear: $capasTecleo; '
          'capas pintadas en toda la repetición: ${PaintCounters.since(paintsBefore)}');

      // Terminar la línea: un nombre corto + Enter (vuelve al buscador).
      var back = false;
      if (nameBox != null && !identical(nameBox, search)) {
        final nombre = await medidor.escribir(nameBox, '9');
        final done = await medidor.pulsar(
          teclaEnter,
          () {
            final box = cajaConFoco();
            return box != null && !identical(box, nameBox);
          },
          box: nameBox,
          seconds: 6,
        );
        back = done.$1 != null;
        if (done.$2 != null) segundos.add(done.$2!);
        logTecleo('factura $rep nombre "9": tecleo ${veredicto(nombre)}; ${nombre.detalle}; '
            'segundo Enter (línea agregada → buscador con foco): '
            '${done.$1 == null ? 'NO en 6 s' : '${_f(done.$1!)} ms (visible ${done.$2 == null ? 'n/d' : _f(done.$2!)} ms) → ${done.$1! < 150 ? 'cumple (<150 ms)' : 'NO CUMPLE'}'}');
      }
      if (!back) {
        await medidor.pulsar(teclaEscape, () => false, seconds: 1);
        if (Get.isDialogOpen == true) Get.back<void>();
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
      if (rep == (reps / 2).ceil()) {
        try {
          final before = stalls.nowMs;
          Get.find<InvoiceTabsController>().currentTab!.controller.clearItems();
          await Future<void>.delayed(const Duration(milliseconds: 600));
          logTecleo('factura vaciada tras $rep repeticiones (${stalls.nowMs - before} ms)');
        } catch (e) {
          logTecleo('no se pudo vaciar la factura: ${'$e'.split('\n').first}');
        }
      }
    }

    String resumen(List<double> values) {
      if (values.isEmpty) return 'sin datos';
      final sorted = [...values]..sort();
      return 'mediana ${_f(sorted[(sorted.length - 1) ~/ 2])} ms, peor ${_f(sorted.last)} ms '
          '(${sorted.length} muestras)';
    }

    logTecleo('factura RESUMEN ($reps repeticiones): tecla → visible: ${resumen(visibles)}'
        '${noVistas > 0 ? ', $noVistas tecla(s) sin verse' : ''}; '
        'Enter → nombre visible: ${resumen(enters)}; '
        'segundo Enter → buscador visible: ${resumen(segundos)}');

    // ---------- Diagnóstico ----------
    final diagMark = medidor.marca;
    final diagStalls = stalls.over100;
    final diagWorstBefore = stalls.worstMs;
    stalls.worstMs = 0;
    final diagAt = stalls.nowMs;
    unawaited(Get.toNamed(AppRoutes.diagnostics));
    final diagOpen = await medidor.esperar(() => route() == AppRoutes.diagnostics, seconds: 20);
    final diagOpenMs = stalls.nowMs - diagAt;
    await Future<void>.delayed(const Duration(seconds: 12));
    logTecleo('Diagnóstico (12 s abierto, descarga: ${descarga()}): '
        '${diagOpen ? 'abrió en $diagOpenMs ms' : 'NO ABRIÓ en 20 s'}; '
        '${medidor.cuadrosDesde(diagMark).cuadrosTexto}; '
        'trabas >100 ms: ${stalls.over100 - diagStalls}, peor traba: ${_f(stalls.worstMs)} ms');
    if (stalls.worstMs < diagWorstBefore) stalls.worstMs = diagWorstBefore;
    try {
      Get.back<void>();
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  // ---------- Esperar a que termine la descarga ----------
  final idleFrom = stalls.nowMs;
  await Future<void>.delayed(const Duration(seconds: 6));
  final settled = await until(
    () => !sync.isSyncing.value && stalls.nowMs - lastRequestAt > 4000,
    seconds: maxSeconds,
  );
  final idleMs = (settled ? lastRequestAt : stalls.nowMs) - idleFrom;
  log('descarga: ${settled ? 'terminó' : 'NO TERMINÓ en $maxSeconds s'}; '
      'última petición a los ${_f(idleMs < 0 ? 0 : idleMs / 1000)} s de entrar');
  String readyText(String name) {
    final at = readyAt[name];
    if (at == null) return '$name NUNCA (siempre esperan al servidor)';
    return at < 300 ? '$name de inmediato' : '$name tras ${_f(at / 1000)} s esperando al servidor';
  }

  log('las pantallas leen del equipo: ${readyText('facturas')}; ${readyText('productos')}');
  log('peticiones al servidor: $requests (de descarga: $changeRequests); '
      'registros descargados: ${downloaded['invoices'] ?? 0} facturas, '
      '${downloaded['products'] ?? 0} productos');
  final top = paths.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  log('rutas más pedidas: ${top.take(6).map((e) => '${e.key} ×${e.value}').join(', ')}');
  log('trabas del hilo de la pantalla: de más de 100 ms: ${stalls.over100}, '
      'de más de 500 ms: ${stalls.over500}, peor: ${_f(stalls.worstMs)} ms, '
      'tiempo trabado: ${_f(stalls.stalledMs)} ms; '
      'cuadros: $frames, de más de 100 ms: $framesOver100');
  log('preferencias: ${prefs.writes} escrituras, ${_f(prefs.writeMs)} ms en total, '
      'peor ${_f(prefs.worstWriteMs)} ms; lecturas fallidas: ${prefs.failedReads}; '
      'archivo al cerrar: ${prefsHealth()}; apartados: ${setAside()}');
  logLento(PerformanceMode.describe());
  for (final line in StartupTrace.instance.timelineLines()) {
    logLento(line);
  }
  for (final line in StartupTrace.instance.phaseLines()) {
    logLento(line.trim());
  }
  final minutes = stalls.nowMs / 60000;
  logTecleo('almacén de sesión: ${secure.reads} lecturas en ${_f(stalls.nowMs / 1000)} s '
      '(${_f(secure.reads / (minutes <= 0 ? 1 : minutes))} por minuto), '
      '${secure.reads == 0 ? 0 : (secure.readMs / secure.reads).toStringAsFixed(1)} ms cada una, '
      'peor ${_f(secure.worstReadMs)} ms, ${_f(secure.readMs)} ms en total; '
      'escrituras: ${secure.writes} (${_f(secure.writeMs)} ms)');
  log('base local al cerrar: ${await isar.isarInvoices.count()} facturas, '
      '${await isar.isarProducts.count()} productos; '
      'sesión al cerrar: ${await Get.find<SecureStorageService>().isAuthenticated() ? 'sí' : 'NO'}; '
      'avisos de Flutter: $flutterErrors');

  if (env['BAUDEX_PROBE_CERRAR_SESION_AL_SALIR'] == '1') {
    try {
      final storage = Get.find<SecureStorageService>();
      await storage.deleteToken();
      await storage.deleteRefreshToken();
      log('token borrado al salir: el próximo arranque pide iniciar sesión');
    } catch (e) {
      log('no se pudo borrar el token: $e');
    }
  }
  await Future<void>.delayed(const Duration(milliseconds: 300));
  try {
    await isar.close();
  } catch (_) {}
  // BAUDEX_PROBE_MAX_LECTURAS: tope de lecturas del ARCHIVO del almacén de
  // sesión en todo el arranque (con la caché en memoria deben ser muy
  // pocas; antes eran cientos por minuto, en el hilo de la pantalla).
  final maxReads = int.tryParse(env['BAUDEX_PROBE_MAX_LECTURAS'] ?? '');
  var tooManyReads = false;
  if (maxReads != null) {
    tooManyReads = secure.reads > maxReads;
    log('PASO VERIFICADO | ${tooManyReads ? 'FALLA' : 'OK'} | lecturas del archivo del '
        'almacén de sesión: ${secure.reads} (tope: $maxReads); escrituras: ${secure.writes}');
  }
  log('reporte de la app | ${SecureStoreStats.report().replaceAll('\n', ' | ')}');
  exit((expectation.isNotEmpty && stepProblems.isNotEmpty) || tooManyReads ? 5 : 0);
}
