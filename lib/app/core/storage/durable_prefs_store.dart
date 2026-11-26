// lib/app/core/storage/durable_prefs_store.dart
//
// Preferencias del equipo que no se dañan (Windows y Linux).
//
// El complemento original (`shared_preferences_windows`) reescribe el
// archivo COMPLETO en cada cambio, encima del anterior y sin copia: si la
// app se cierra, se cuelga o el computador se apaga a mitad de esa
// escritura, `shared_preferences.json` queda cortado, vacío o lleno de
// ceros. Desde ahí cada lectura lanza `FormatException` y la app pierde lo
// que guardaba ahí: marcas de sincronización, modo del almacén de sesión,
// impresora elegida, cachés.
//
// Este almacén usa el MISMO archivo, pero:
//  - escribe primero un archivo temporal y lo cambia de nombre (el archivo
//    bueno nunca queda a medias);
//  - conserva la versión anterior en `.bak`;
//  - junta los cambios seguidos en una sola escritura, de una en una y
//    fuera del hilo de la pantalla;
//  - si al abrir el archivo está dañado, recupera del temporal, del `.bak`
//    o rescata lo legible, en vez de empezar de cero;
//  - nunca lanza: en el peor caso arranca vacío y lo deja anotado.
// ignore_for_file: depend_on_referenced_packages
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

/// De dónde salieron las preferencias al abrir.
enum PrefsLoadSource {
  /// El archivo estaba bien (o no existía: equipo nuevo).
  file,

  /// El archivo faltaba o estaba dañado; se usó la escritura que quedó a
  /// medio cambiar de nombre (completa y válida).
  pendingWrite,

  /// El archivo faltaba o estaba dañado; se usó la copia anterior.
  backup,

  /// No había copia: se rescató lo legible del archivo dañado.
  salvaged,

  /// No se pudo recuperar nada: se empieza vacío.
  empty,
}

class PrefsLoadReport {
  const PrefsLoadReport({
    required this.source,
    required this.keys,
    this.problem,
    this.setAside,
  });

  final PrefsLoadSource source;
  final int keys;

  /// Qué tenía de malo el archivo (null si estaba bien).
  final String? problem;

  /// Dónde quedó el archivo dañado, si se apartó.
  final String? setAside;

  bool get recovered => source != PrefsLoadSource.file;

  @override
  String toString() =>
      'preferencias: ${source.name}, $keys claves'
      '${problem == null ? '' : ', problema: $problem'}'
      '${setAside == null ? '' : ', apartado: $setAside'}';
}

/// Lee un archivo de preferencias. Null si no existe o está vacío; lanza
/// si existe pero no es un objeto JSON válido.
Map<String, Object>? _readJsonFile(File file) {
  if (!file.existsSync()) return null;
  final text = file.readAsStringSync();
  if (text.isEmpty) return null;
  return _toPrefsMap(json.decode(text));
}

Map<String, Object> _toPrefsMap(Object? data) {
  if (data is! Map) throw const FormatException('no es un objeto JSON');
  final out = <String, Object>{};
  data.forEach((key, value) {
    if (key is! String || value == null) return;
    if (value is List) {
      out[key] = value.map((e) => e.toString()).toList();
    } else if (value is bool || value is num || value is String) {
      out[key] = value as Object;
    }
  });
  return out;
}

/// Rescata lo legible de un archivo cortado: prueba a cerrar el objeto en
/// cada frontera `,"` desde el final hacia atrás. Devuelve vacío si no hay
/// nada que rescatar (por ejemplo, archivo lleno de ceros).
Map<String, Object> salvagePrefsJson(String text, {int maxAttempts = 400}) {
  final clean = text.replaceAll('\u0000', '');
  if (!clean.trimLeft().startsWith('{')) return {};
  var end = clean.length;
  for (var i = 0; i < maxAttempts; i++) {
    final cut = clean.lastIndexOf(',"', end - 1);
    if (cut <= 0) break;
    try {
      return _toPrefsMap(json.decode('${clean.substring(0, cut)}}'));
    } catch (_) {
      end = cut;
    }
  }
  return {};
}

String? _setAside(File file, DateTime now) {
  if (!file.existsSync()) return null;
  final target = '${file.path}.danado-${now.millisecondsSinceEpoch}';
  try {
    file.renameSync(target);
    return target;
  } catch (_) {
    try {
      file.deleteSync();
    } catch (_) {}
    return null;
  }
}

File? _newestDamaged(File file) {
  try {
    final name = file.uri.pathSegments.last;
    final found =
        file.parent
            .listSync()
            .whereType<File>()
            .where((f) => f.uri.pathSegments.last.startsWith('$name.danado-'))
            .toList()
          ..sort((a, b) => b.path.compareTo(a.path));
    return found.isEmpty ? null : found.first;
  } catch (_) {
    return null;
  }
}

/// Abre las preferencias de [file] recuperando lo que haga falta. Nunca
/// lanza.
({Map<String, Object> values, PrefsLoadReport report}) loadDurablePrefs(
  File file, {
  DateTime? now,
}) {
  final tmp = File('${file.path}.tmp');
  final bak = File('${file.path}.bak');
  final stamp = now ?? DateTime.now();

  Map<String, Object>? tryRead(File f) {
    try {
      return _readJsonFile(f);
    } catch (_) {
      return null;
    }
  }

  String? problem;
  String? damagedText;
  String? aside;
  try {
    final main = _readJsonFile(file);
    if (main != null) {
      return (
        values: main,
        report: PrefsLoadReport(source: PrefsLoadSource.file, keys: main.length),
      );
    }
    // No existe o está vacío. Vacío con copias al lado = escritura perdida.
    if (file.existsSync()) problem = 'archivo vacío';
  } catch (e) {
    problem = e.toString().split('\n').first;
    try {
      damagedText = file.readAsStringSync();
    } catch (_) {
      try {
        damagedText = latin1.decode(file.readAsBytesSync());
      } catch (_) {}
    }
    aside = _setAside(file, stamp);
  }

  final pending = tryRead(tmp);
  if (pending != null && pending.isNotEmpty) {
    return (
      values: pending,
      report: PrefsLoadReport(
        source: PrefsLoadSource.pendingWrite,
        keys: pending.length,
        problem: problem ?? 'faltaba el archivo',
        setAside: aside,
      ),
    );
  }

  final backup = tryRead(bak);
  if (backup != null && backup.isNotEmpty) {
    return (
      values: backup,
      report: PrefsLoadReport(
        source: PrefsLoadSource.backup,
        keys: backup.length,
        problem: problem ?? 'faltaba el archivo',
        setAside: aside,
      ),
    );
  }

  // Sin copias: rescatar lo legible del archivo dañado de ahora o, si una
  // versión anterior ya lo había apartado y aún no hay nada nuevo, del
  // apartado más reciente.
  if (damagedText == null) {
    final old = _newestDamaged(file);
    if (old != null) {
      try {
        damagedText = old.readAsStringSync();
        problem ??= 'faltaba el archivo; había uno dañado apartado';
      } catch (_) {}
    }
  }
  if (damagedText != null) {
    final rescued = salvagePrefsJson(damagedText);
    if (rescued.isNotEmpty) {
      return (
        values: rescued,
        report: PrefsLoadReport(
          source: PrefsLoadSource.salvaged,
          keys: rescued.length,
          problem: problem,
          setAside: aside,
        ),
      );
    }
  }

  if (problem == null) {
    // Equipo nuevo: no había nada y no es un problema.
    return (
      values: <String, Object>{},
      report: const PrefsLoadReport(source: PrefsLoadSource.file, keys: 0),
    );
  }
  return (
    values: <String, Object>{},
    report: PrefsLoadReport(
      source: PrefsLoadSource.empty,
      keys: 0,
      problem: problem,
      setAside: aside,
    ),
  );
}

/// Escribe [values] en [file] sin dejarlo nunca a medias: temporal →
/// (el actual pasa a `.bak`) → el temporal toma su lugar.
///
/// [currentIsGood]: si ya se sabe que el archivo actual es legible (lo
/// escribió este mismo almacén) no se vuelve a leer para comprobarlo.
Future<void> writeDurablePrefs(
  File file,
  Map<String, Object> values, {
  bool? currentIsGood,
}) async {
  final tmp = File('${file.path}.tmp');
  final bak = File('${file.path}.bak');
  if (!file.parent.existsSync()) file.parent.createSync(recursive: true);
  await tmp.writeAsString(json.encode(values), flush: true);
  if (file.existsSync()) {
    // Solo se guarda como copia si es legible: nunca pisar una copia buena
    // con un archivo dañado.
    var good = currentIsGood ?? false;
    if (currentIsGood == null) {
      try {
        good = _readJsonFile(file) != null;
      } catch (_) {}
    }
    if (good) {
      await file.rename(bak.path);
    } else {
      try {
        await file.delete();
      } catch (_) {}
    }
  }
  await tmp.rename(file.path);
}

class DurablePrefsStore extends SharedPreferencesStorePlatform {
  DurablePrefsStore(this.file, {this.onProblem});

  final File file;

  /// Aviso de fallos de escritura (nunca se propagan a quien guarda).
  final void Function(Object error, StackTrace stack)? onProblem;

  static const String _defaultPrefix = 'flutter.';

  Map<String, Object>? _values;
  PrefsLoadReport? _report;

  /// Cómo se abrieron las preferencias (null antes de abrirlas).
  PrefsLoadReport? get loadReport => _report;

  Map<String, Object> _load() {
    final cached = _values;
    if (cached != null) return cached;
    final loaded = loadDurablePrefs(file);
    _report = loaded.report;
    _values = loaded.values;
    // Lo recuperado se deja escrito ya, con su copia.
    if (loaded.report.recovered && loaded.values.isNotEmpty) {
      unawaited(_persist());
    }
    return loaded.values;
  }

  /// Abre (y recupera si hace falta) ahora mismo.
  PrefsLoadReport open() {
    _load();
    return _report!;
  }

  bool _dirty = false;
  bool _wroteOnce = false;
  Future<bool>? _writer;

  /// Cambios seguidos salen en una sola escritura; quien espera, espera a
  /// que SU cambio esté en disco.
  Future<bool> _persist() {
    _dirty = true;
    return _writer ??= _drain();
  }

  Future<bool> _drain() async {
    var ok = true;
    try {
      // Deja que se junten los cambios hechos en el mismo instante.
      await Future<void>.delayed(Duration.zero);
      while (_dirty) {
        _dirty = false;
        try {
          await writeDurablePrefs(
            file,
            Map<String, Object>.of(_values!),
            currentIsGood: _wroteOnce ? true : null,
          );
          _wroteOnce = true;
          ok = true;
        } catch (e, st) {
          ok = false;
          try {
            onProblem?.call(e, st);
          } catch (_) {}
        }
      }
    } finally {
      _writer = null;
    }
    return ok;
  }

  /// Espera a que no quede nada por escribir (para pruebas y al cerrar).
  Future<void> flush() async {
    while (_writer != null) {
      await _writer;
    }
  }

  bool _matches(String key, PreferencesFilter filter) =>
      key.startsWith(filter.prefix) &&
      (filter.allowList == null || filter.allowList!.contains(key));

  @override
  Future<bool> clear() => clearWithParameters(
    ClearParameters(filter: PreferencesFilter(prefix: _defaultPrefix)),
  );

  @override
  Future<bool> clearWithPrefix(String prefix) => clearWithParameters(
    ClearParameters(filter: PreferencesFilter(prefix: prefix)),
  );

  @override
  Future<bool> clearWithParameters(ClearParameters parameters) {
    _load().removeWhere((key, _) => _matches(key, parameters.filter));
    return _persist();
  }

  @override
  Future<Map<String, Object>> getAll() => getAllWithParameters(
    GetAllParameters(filter: PreferencesFilter(prefix: _defaultPrefix)),
  );

  @override
  Future<Map<String, Object>> getAllWithPrefix(String prefix) =>
      getAllWithParameters(
        GetAllParameters(filter: PreferencesFilter(prefix: prefix)),
      );

  @override
  Future<Map<String, Object>> getAllWithParameters(
    GetAllParameters parameters,
  ) async {
    final all = Map<String, Object>.of(_load());
    all.removeWhere((key, _) => !_matches(key, parameters.filter));
    return all;
  }

  @override
  Future<bool> remove(String key) {
    if (_load().remove(key) == null) return Future.value(true);
    return _persist();
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    final values = _load();
    final old = values[key];
    if (old == value && value is! List) return Future.value(true);
    values[key] = value is List ? List<String>.from(value) : value;
    return _persist();
  }
}

/// Resultado de instalar el almacén al arrancar (para reportarlo cuando la
/// central de errores y Diagnóstico ya estén listos).
PrefsLoadReport? durablePrefsStartupReport;

/// El almacén instalado en este arranque (null en macOS y celulares).
DurablePrefsStore? installedDurablePrefs;

/// Llamar UNA vez al arrancar, antes de cualquier uso de preferencias.
/// En Windows y Linux reemplaza al complemento original por
/// [DurablePrefsStore] y abre el archivo recuperando lo que haga falta.
/// En las demás plataformas no hace nada. Nunca lanza.
Future<PrefsLoadReport?> installDurablePrefs({
  void Function(Object error, StackTrace stack)? onProblem,
  File? fileOverride,
}) async {
  if (fileOverride == null && !Platform.isWindows && !Platform.isLinux) {
    return null;
  }
  try {
    final file =
        fileOverride ??
        File(
          '${(await getApplicationSupportDirectory()).path}'
          '${Platform.pathSeparator}shared_preferences.json',
        );
    final store = DurablePrefsStore(file, onProblem: onProblem);
    final report = store.open();
    SharedPreferencesStorePlatform.instance = store;
    installedDurablePrefs = store;
    durablePrefsStartupReport = report;
    // Que el primer `getInstance()` lea de este almacén.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.resetStatic();
    return report;
  } catch (e, st) {
    try {
      onProblem?.call(e, st);
    } catch (_) {}
    return null;
  }
}
