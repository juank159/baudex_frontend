// lib/app/core/diagnostics/speed_test_probes.dart
//
// Las mediciones reales de la "Prueba de velocidad de este equipo" (ver
// `speed_test.dart`). Ninguna toca datos del negocio: usan un archivo, una
// clave y una base de prueba propias, que se borran al terminar.
import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:win32/win32.dart' as win32;

import '../../config/constants/api_constants.dart';
import '../../data/local/isar_database.dart';
import '../../data/local/sync_event_log.dart';
import '../storage/secure_storage_service.dart';
import '../storage/secure_store_migration.dart';
import '../storage/session_startup_trace.dart';
import '../utils/app_version.dart';
import 'speed_test.dart';

const String _probeKey = 'baudex_speed_probe';
const String _probeIsarName = 'baudex_prueba_velocidad';

/// Carpeta de datos de la app (donde viven preferencias y la base local).
Future<Directory> _dataDir() async {
  final known = IsarDatabase.databaseDirectory;
  if (known != null) return Directory(known);
  return getApplicationSupportDirectory();
}

/// Arma la prueba con las mediciones reales. Todo es reemplazable para las
/// pruebas automáticas y las imágenes.
SpeedTestRunner buildDeviceSpeedTest({
  Future<Directory> Function()? dataDir,
  SecureKeyValueStore? secureStore,
  String? healthUrl,
  bool includeIsar = true,
}) {
  final dir = dataDir ?? _dataDir;
  final store = secureStore ?? SecureStorageService.speedProbeStore;
  final payload = 'baudex ' * 128; // ~1 KB
  var counter = 0;

  Future<File> probeFile() async =>
      File('${(await dir()).path}${Platform.pathSeparator}baudex_prueba_velocidad.tmp');

  return SpeedTestRunner(
    appVersion: AppVersion.label,
    facts: () async => collectDeviceFacts(await dir()),
    // Nada de la prueba queda en el equipo.
    cleanup: () async {
      try {
        final file = await probeFile();
        if (await file.exists()) await file.delete();
      } catch (_) {}
      try {
        final prefs = await SharedPreferences.getInstance();
        unawaited(prefs.remove(_probeKey).catchError((Object _) => false));
      } catch (_) {}
      if (includeIsar) {
        try {
          final isar = await _openProbeIsar((await dir()).path);
          await isar.close(deleteFromDisk: true);
        } catch (_) {}
      }
    },
    checks: [
      SpeedCheck(
        id: 'disk_write',
        title: 'Guardar un archivo en el disco',
        hint: 'El disco de este equipo tarda en guardar: suele ser un disco '
            'viejo o lleno, un antivirus revisando cada archivo o una carpeta '
            'que se sincroniza con la nube.',
        fastMs: 40,
        slowMs: 250,
        repeat: 20,
        run: () async {
          final file = await probeFile();
          final watch = Stopwatch()..start();
          await file.writeAsString('$payload${counter++}', flush: true);
          return watch.elapsedMicroseconds / 1000;
        },
      ),
      SpeedCheck(
        id: 'disk_read',
        title: 'Leer un archivo del disco',
        hint: 'El disco de este equipo tarda en leer: suele ser un antivirus '
            'revisando cada archivo o un disco con problemas.',
        fastMs: 20,
        slowMs: 150,
        repeat: 20,
        run: () async {
          final file = await probeFile();
          if (!await file.exists()) await file.writeAsString(payload);
          final watch = Stopwatch()..start();
          await file.readAsString();
          return watch.elapsedMicroseconds / 1000;
        },
      ),
      SpeedCheck(
        id: 'prefs_write',
        title: 'Guardar un ajuste de la app',
        hint: 'Guardar ajustes tarda: la app guarda la sesión y los ajustes '
            'en el disco de este equipo, y ese disco está lento.',
        fastMs: 80,
        slowMs: 500,
        repeat: 5,
        run: () async {
          final prefs = await SharedPreferences.getInstance();
          final watch = Stopwatch()..start();
          await prefs.setString(_probeKey, 'v${counter++}');
          return watch.elapsedMicroseconds / 1000;
        },
      ),
      SpeedCheck(
        id: 'prefs_read',
        title: 'Leer un ajuste de la app',
        hint: 'Leer ajustes debería ser inmediato; si tarda, la app está '
            'ocupada con otra cosa.',
        fastMs: 20,
        slowMs: 150,
        repeat: 5,
        run: () async {
          final watch = Stopwatch()..start();
          final prefs = await SharedPreferences.getInstance();
          prefs.getString(_probeKey);
          final ms = watch.elapsedMicroseconds / 1000;
          return ms;
        },
      ),
      SpeedCheck(
        id: 'secure_write',
        title: 'Guardar en el almacén seguro del sistema',
        hint: 'El almacén seguro de este equipo (donde el sistema guarda '
            'claves) responde lento o no responde; la app usa su respaldo.',
        fastMs: 150,
        slowMs: 1000,
        timeout: const Duration(seconds: 15),
        run: () async {
          final watch = Stopwatch()..start();
          await store.write(_probeKey, 'v${counter++}');
          return watch.elapsedMicroseconds / 1000;
        },
      ),
      SpeedCheck(
        id: 'secure_read',
        title: 'Leer del almacén seguro del sistema',
        hint: 'El almacén seguro de este equipo responde lento o no '
            'responde; la app usa su respaldo.',
        fastMs: 150,
        slowMs: 1000,
        timeout: const Duration(seconds: 15),
        run: () async {
          final watch = Stopwatch()..start();
          await store.read(_probeKey);
          final ms = watch.elapsedMicroseconds / 1000;
          // Sin esperar: si el almacén no responde, la prueba sigue.
          unawaited(store.delete(_probeKey).catchError((Object _) {}));
          return ms;
        },
      ),
      if (includeIsar) ...[
        SpeedCheck(
          id: 'isar_open',
          title: 'Abrir la base de datos local',
          hint: 'Abrir la base local tarda: el disco está lento o un '
              'antivirus revisa el archivo de la base.',
          fastMs: 300,
          slowMs: 1500,
          run: () async {
            final watch = Stopwatch()..start();
            final isar = await _openProbeIsar((await dir()).path);
            final ms = watch.elapsedMicroseconds / 1000;
            await isar.close();
            return ms;
          },
        ),
        SpeedCheck(
          id: 'isar_write',
          title: 'Guardar y leer en la base de datos local',
          hint: 'Cada venta se guarda en la base local de este equipo; si '
              'esto tarda, procesar una venta tarda.',
          fastMs: 60,
          slowMs: 400,
          repeat: 5,
          run: () async {
            final isar = await _openProbeIsar((await dir()).path);
            try {
              final watch = Stopwatch()..start();
              final row = IsarSyncEventLog.create(
                severity: SyncEventSeverity.info,
                eventType: SyncEventType.diagnostic,
                operation: 'prueba',
                message: payload,
                organizationId: 'prueba',
              );
              late int id;
              await isar.writeTxn(() async => id = await isar.isarSyncEventLogs.put(row));
              await isar.isarSyncEventLogs.get(id);
              return watch.elapsedMicroseconds / 1000;
            } finally {
              await isar.close();
            }
          },
        ),
      ],
      SpeedCheck(
        id: 'server',
        title: 'Respuesta del servidor',
        hint: 'El servidor tarda en responder desde este equipo: revisa el '
            'internet, el cortafuegos o el antivirus.',
        fastMs: 800,
        slowMs: 3000,
        repeat: 3,
        timeout: const Duration(seconds: 12),
        run: () async {
          final url = healthUrl ?? '${ApiConstants.baseUrl}/health';
          final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
          try {
            final watch = Stopwatch()..start();
            final request = await client.getUrl(Uri.parse(url));
            final response = await request.close();
            await response.drain<void>();
            final ms = watch.elapsedMicroseconds / 1000;
            if (response.statusCode >= 500) {
              throw HttpException('el servidor respondió ${response.statusCode}');
            }
            return ms;
          } finally {
            client.close(force: true);
          }
        },
      ),
    ],
  );
}

Future<Isar> _openProbeIsar(String directory) => Isar.open(
      [IsarSyncEventLogSchema],
      directory: directory,
      name: _probeIsarName,
      inspector: false,
    );

/// Datos del equipo que se pueden saber sin complementos nuevos.
Future<DeviceFacts> collectDeviceFacts(Directory dataDir) async {
  final env = Platform.environment;
  final cloudRoots = [env['OneDrive'], env['OneDriveConsumer'], env['OneDriveCommercial']];
  final exe = Platform.resolvedExecutable;
  final dataCloud = cloudFolderOf(dataDir.path, cloudRoots: cloudRoots);
  final exeCloud = cloudFolderOf(exe, cloudRoots: cloudRoots);
  final exeRisk = riskyProgramLocation(exe);
  final free = freeDiskBytes(dataDir.path);
  final lowSpace = free != null && free < 5 * 1024 * 1024 * 1024;
  return DeviceFacts([
    ('Sistema', '${Platform.operatingSystem} ${Platform.operatingSystemVersion}', false),
    ('Núcleos del procesador', '${Platform.numberOfProcessors}', Platform.numberOfProcessors <= 2),
    (
      'Carpeta de datos',
      '${maskUserInPath(dataDir.path)}'
          '${dataCloud == null ? '' : ' — DENTRO DE $dataCloud (se sincroniza con la nube)'}',
      dataCloud != null,
    ),
    (
      'Programa',
      '${maskUserInPath(exe)}'
          '${exeCloud == null ? '' : ' — DENTRO DE $exeCloud'}'
          '${exeRisk == null ? '' : ' — se abre desde $exeRisk'}',
      exeCloud != null || exeRisk != null,
    ),
    (
      'Espacio libre en el disco',
      free == null ? 'no disponible' : '${formatBytes(free)}${lowSpace ? ' — queda poco' : ''}',
      lowSpace,
    ),
    ('Sesión guardada en', SessionStartupTrace.storageMode, false),
    // Cada preferencia que se guarda reescribe este archivo entero.
    _sizeFact('Archivo de preferencias', '${dataDir.path}${Platform.pathSeparator}shared_preferences.json',
        alertOver: 2 * 1024 * 1024),
    _sizeFact(
      'Base de datos local',
      '${IsarDatabase.databaseDirectory ?? dataDir.path}${Platform.pathSeparator}'
          '${IsarDatabase.databaseName}.isar',
      alertOver: 2 * 1024 * 1024 * 1024,
    ),
  ]);
}

/// Espacio libre del disco de [path] (solo Windows; null si no se sabe).
int? freeDiskBytes(String path) {
  if (!Platform.isWindows) return null;
  try {
    final lpPath = path.toNativeUtf16();
    final free = calloc<Uint64>();
    try {
      final ok = win32.GetDiskFreeSpaceEx(lpPath, free, nullptr, nullptr);
      return ok == 0 ? null : free.value;
    } finally {
      calloc.free(lpPath);
      calloc.free(free);
    }
  } catch (_) {
    return null;
  }
}

(String, String, bool) _sizeFact(String name, String path, {required int alertOver}) {
  try {
    final file = File(path);
    if (!file.existsSync()) return (name, 'no existe en esta carpeta', false);
    final bytes = file.lengthSync();
    final text = bytes < 1024 * 1024
        ? '${(bytes / 1024).toStringAsFixed(0)} KB'
        : formatBytes(bytes);
    return (name, '$text${bytes > alertOver ? ' — muy grande' : ''}', bytes > alertOver);
  } catch (_) {
    return (name, 'no disponible', false);
  }
}
