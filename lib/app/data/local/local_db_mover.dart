// lib/app/data/local/local_db_mover.dart
import 'dart:io';

/// Qué pasó al decidir dónde vive la base local.
enum LocalDbMoveOutcome {
  /// No había base en ningún lado: se crea en la carpeta nueva.
  fresh,

  /// La base ya estaba en la carpeta nueva (traslado hecho antes).
  alreadyMoved,

  /// Se trasladó en este arranque y quedó verificada.
  moved,

  /// El traslado falló: se sigue usando la base vieja, intacta.
  keptLegacy,
}

/// Carpeta que debe usar la app para abrir la base, y por qué.
class LocalDbLocation {
  const LocalDbLocation(this.directory, this.outcome, {this.error, this.counts});

  final String directory;
  final LocalDbMoveOutcome outcome;

  /// Error del traslado (solo con [LocalDbMoveOutcome.keptLegacy]).
  final Object? error;

  /// Registros contados en la base trasladada (solo con `moved`).
  final Map<String, int>? counts;

  bool get usesLegacy => outcome == LocalDbMoveOutcome.keptLegacy;
}

/// Abre la base `<name>.isar` que está en [directory], cuenta sus registros y
/// la cierra. Si no se puede abrir debe lanzar.
typedef LocalDbCounter = Future<Map<String, int>> Function(
  String directory,
  String name,
);

/// Aviso para la central de errores. Nunca lleva rutas (tienen el nombre del
/// usuario de Windows) ni datos del negocio: solo cifras.
typedef LocalDbProblem = void Function(
  Object error,
  StackTrace? stack,
  Map<String, dynamic> context,
);

class LocalDbMoveException implements Exception {
  LocalDbMoveException(this.message);
  final String message;
  @override
  String toString() => 'LocalDbMoveException: $message';
}

/// Traslada la base Isar de la carpeta vieja (Documentos, que en Windows suele
/// estar sincronizada con OneDrive) a la carpeta interna de la app.
///
/// Reglas:
/// - Corre ANTES de abrir Isar.
/// - Copia a un archivo temporal dentro de la carpeta nueva y solo lo pone con
///   su nombre final después de verificarlo (mismo tamaño, abre y tiene los
///   mismos registros que la vieja). Si la app se cierra a mitad, la carpeta
///   nueva no tiene `<name>.isar` y el próximo arranque empieza de cero desde
///   la vieja, que no se tocó.
/// - La vieja no se borra: se renombra a `<name>.isar.migrado-AAAAMMDD`.
/// - Ante cualquier error devuelve la carpeta vieja: nunca se abre una base
///   vacía si existía una con datos.
/// - El `.isar.lock` viejo no se copia (Isar lo recrea).
class LocalDbMover {
  LocalDbMover({
    required this.legacyDirectory,
    required this.newDirectory,
    required this.counter,
    this.name = 'baudex_offline',
    this.onProblem,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final String legacyDirectory;
  final String newDirectory;
  final String name;
  final LocalDbCounter counter;
  final LocalDbProblem? onProblem;
  final DateTime Function() _now;

  static const stagingFolder = '.traslado';

  /// Tamaño mínimo para tratar el archivo como una base de Isar.
  static const minDbBytes = 64 * 1024;

  String get _dbFile => '$name.isar';
  File get _legacyFile => File(_join(legacyDirectory, _dbFile));
  File get _newFile => File(_join(newDirectory, _dbFile));
  Directory get _staging => Directory(_join(newDirectory, stagingFolder));

  Future<LocalDbLocation> resolve() async {
    final legacy = _legacyFile;

    if (await _newFile.exists()) {
      // Traslado hecho. Si la vieja sigue con su nombre, la app se cerró
      // justo antes de renombrarla: se termina ese paso.
      if (await legacy.exists()) {
        await _archiveLegacy(legacy, reason: 'leftover');
      }
      await _deleteStaging();
      return LocalDbLocation(newDirectory, LocalDbMoveOutcome.alreadyMoved);
    }

    if (!await legacy.exists()) {
      try {
        await Directory(newDirectory).create(recursive: true);
        await _deleteStaging();
        return LocalDbLocation(newDirectory, LocalDbMoveOutcome.fresh);
      } catch (e, st) {
        // Sin carpeta nueva no hay dónde abrir; la vieja sigue sirviendo.
        _report(e, st, {'step': 'create_dir'});
        return LocalDbLocation(legacyDirectory, LocalDbMoveOutcome.keptLegacy, error: e);
      }
    }

    String step = 'start';
    Map<String, int>? before;
    try {
      step = 'prepare';
      await Directory(newDirectory).create(recursive: true);
      await _deleteStaging(); // restos de un traslado cortado a mitad
      await _staging.create(recursive: true);

      // Un archivo diminuto no es una base de Isar (la más pequeña mide 1 MiB)
      // e Isar lo reescribiría al abrirlo: no se toca y se sigue como hoy.
      step = 'check_legacy';
      final legacyLen = await legacy.length();
      if (legacyLen < minDbBytes) {
        throw LocalDbMoveException('la base vieja no parece válida ($legacyLen bytes)');
      }

      step = 'count_legacy';
      before = await counter(legacyDirectory, name);

      step = 'copy';
      final partial = File(_join(_staging.path, '$_dbFile.parcial'));
      await legacy.copy(partial.path);

      step = 'size';
      final srcLen = await legacy.length();
      final dstLen = await partial.length();
      if (srcLen != dstLen || srcLen == 0) {
        throw LocalDbMoveException('tamaño distinto: origen $srcLen, copia $dstLen');
      }

      step = 'count_copy';
      final staged = await partial.rename(_join(_staging.path, _dbFile));
      final after = await counter(_staging.path, name);
      if (!sameCounts(before, after)) {
        throw LocalDbMoveException('registros distintos: antes $before, copia $after');
      }

      step = 'commit';
      await staged.rename(_newFile.path);
    } catch (e, st) {
      await _deleteStaging();
      _report(e, st, {'step': step, if (before != null) 'counts': before});
      return LocalDbLocation(legacyDirectory, LocalDbMoveOutcome.keptLegacy, error: e);
    }

    await _deleteStaging();
    await _archiveLegacy(legacy, reason: 'moved');
    return LocalDbLocation(newDirectory, LocalDbMoveOutcome.moved, counts: before);
  }

  /// Nombre del respaldo: `<name>.isar.migrado-AAAAMMDD` (con hora si ya
  /// existe uno de ese día).
  String backupName() {
    final d = _now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '$_dbFile.migrado-${d.year}${two(d.month)}${two(d.day)}';
  }

  Future<void> _archiveLegacy(File legacy, {required String reason}) async {
    try {
      var target = File(_join(legacyDirectory, backupName()));
      if (await target.exists()) {
        final d = _now();
        String two(int n) => n.toString().padLeft(2, '0');
        target = File('${target.path}-${two(d.hour)}${two(d.minute)}${two(d.second)}');
      }
      await legacy.rename(target.path);
    } catch (e, st) {
      // No es grave: la app ya usa la nueva y el próximo arranque lo reintenta.
      _report(e, st, {'step': 'archive', 'reason': reason}, level: 'warning');
    }
  }

  Future<void> _deleteStaging() async {
    try {
      if (await _staging.exists()) await _staging.delete(recursive: true);
    } catch (_) {}
  }

  void _report(Object e, StackTrace? st, Map<String, dynamic> context, {String level = 'error'}) {
    try {
      onProblem?.call(e, st, {...context, 'level': level});
    } catch (_) {}
  }

  static bool sameCounts(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  static String _join(String dir, String child) {
    final sep = Platform.pathSeparator;
    return dir.endsWith(sep) || dir.endsWith('/') ? '$dir$child' : '$dir$sep$child';
  }
}

/// Carpeta de datos en Windows: la misma subcarpeta `<empresa>\<app>` que da
/// `getApplicationSupportDirectory()` (en Roaming), pero bajo `%LOCALAPPDATA%`.
///
/// Por qué Local y no Roaming: la base es del equipo (cola de subida, ids
/// temporales) y puede pesar cientos de MB. Microsoft reserva Roaming para
/// ajustes pequeños que siguen al usuario; en redes con perfiles móviles
/// Roaming se copia completo al entrar y salir de Windows, lo que choca con
/// el archivo bloqueado de Isar. Ninguna de las dos la sincroniza OneDrive.
///
/// Devuelve null si no se puede calcular (se usa entonces la de soporte).
String? windowsLocalDataPath({
  required String supportPath,
  required String? roamingAppData,
  required String? localAppData,
}) {
  if (roamingAppData == null || roamingAppData.isEmpty) return null;
  if (localAppData == null || localAppData.isEmpty) return null;
  final roaming = roamingAppData.replaceAll(RegExp(r'[\\/]+$'), '');
  final local = localAppData.replaceAll(RegExp(r'[\\/]+$'), '');
  if (!supportPath.toLowerCase().startsWith(roaming.toLowerCase())) return null;
  final rest = supportPath.substring(roaming.length);
  if (rest.isEmpty || !(rest.startsWith(r'\') || rest.startsWith('/'))) return null;
  return '$local$rest\\data';
}
