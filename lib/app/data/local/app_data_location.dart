// lib/app/data/local/app_data_location.dart
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'local_db_mover.dart';

/// Carpeta interna de la app para datos que el usuario no maneja a mano
/// (base local, logos guardados). Documentos queda solo para lo que el
/// usuario exporta (PDF, Excel).
///
/// - Windows: `%LOCALAPPDATA%\<empresa>\<app>\data` (ver [windowsLocalDataPath]).
/// - macOS: `~/Library/Application Support/<bundle>/data`.
/// - Android/iOS/Linux: carpeta de soporte de la app + `data`.
class AppDataLocation {
  AppDataLocation._();

  static String? _cached;

  /// Solo para pruebas.
  static void debugOverride(String? path) => _cached = path;

  static Future<String> dataDirectory() async {
    if (_cached != null) return _cached!;
    final support = await getApplicationSupportDirectory();
    String? path;
    if (Platform.isWindows) {
      path = windowsLocalDataPath(
        supportPath: support.path,
        roamingAppData: Platform.environment['APPDATA'],
        localAppData: Platform.environment['LOCALAPPDATA'],
      );
    }
    path ??= '${support.path}${Platform.pathSeparator}data';
    _cached = path;
    return path;
  }

  /// Carpeta vieja (Documentos), donde vivía todo antes.
  static Future<String> legacyDirectory() async =>
      (await getApplicationDocumentsDirectory()).path;

  // ---------- logos de la organización ----------

  static Future<String> _logosDir() async =>
      '${await dataDirectory()}${Platform.pathSeparator}org_logos';

  static Future<String> _legacyLogosDir() async =>
      '${await legacyDirectory()}${Platform.pathSeparator}org_logos';

  /// Ruta donde se guarda el logo nuevo (crea la carpeta).
  static Future<String> orgLogoSavePath(String orgId) async {
    final dir = Directory(await _logosDir());
    if (!await dir.exists()) await dir.create(recursive: true);
    return '${dir.path}${Platform.pathSeparator}$orgId.png';
  }

  /// Logo guardado: primero en la carpeta nueva, si no en Documentos
  /// (versiones anteriores). Null si no hay.
  static Future<File?> orgLogoFile(String orgId) async {
    for (final dir in [await _logosDir(), await _legacyLogosDir()]) {
      final f = File('$dir${Platform.pathSeparator}$orgId.png');
      if (await f.exists()) return f;
    }
    return null;
  }

  /// Borra el logo en ambas carpetas.
  static Future<void> deleteOrgLogo(String orgId) async {
    for (final dir in [await _logosDir(), await _legacyLogosDir()]) {
      final f = File('$dir${Platform.pathSeparator}$orgId.png');
      try {
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }
}
