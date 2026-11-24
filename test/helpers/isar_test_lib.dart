import 'dart:ffi';
import 'dart:io';

import 'package:isar/isar.dart';

/// Biblioteca nativa de Isar para pruebas, en macOS, Windows y Linux
/// (se toma de la caché de pub; no usa la base real del equipo).
String isarTestLibraryPath() {
  final env = Platform.environment;
  final cache = env['PUB_CACHE'] ??
      (Platform.isWindows
          ? '${env['LOCALAPPDATA']}\\Pub\\Cache'
          : '${env['HOME']}/.pub-cache');
  final base = '$cache/hosted/pub.dev/isar_flutter_libs-3.1.0+1';
  if (Platform.isWindows) return '$base/windows/isar.dll';
  if (Platform.isLinux) return '$base/linux/libisar.so';
  return '$base/macos/libisar.dylib';
}

Future<void> initIsarForTests() =>
    Isar.initializeIsarCore(libraries: {Abi.current(): isarTestLibraryPath()});
