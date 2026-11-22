// test/helpers/isar_core.dart
import 'dart:ffi';
import 'dart:io';

import 'package:isar/isar.dart';

/// Librería nativa de Isar de la caché de pub según el sistema (macOS,
/// Windows o Linux), para que las pruebas con Isar real corran en todos.
String isarLibPath() {
  final env = Platform.environment;
  final sep = Platform.pathSeparator;
  String cache;
  if (env['PUB_CACHE'] != null && env['PUB_CACHE']!.isNotEmpty) {
    cache = env['PUB_CACHE']!;
  } else if (Platform.isWindows) {
    cache = '${env['LOCALAPPDATA']}${sep}Pub${sep}Cache';
  } else {
    cache = '${env['HOME']}$sep.pub-cache';
  }
  final pkg = '$cache${sep}hosted${sep}pub.dev${sep}isar_flutter_libs-3.1.0+1';
  if (Platform.isWindows) return '$pkg${sep}windows${sep}isar.dll';
  if (Platform.isMacOS) return '$pkg${sep}macos${sep}libisar.dylib';
  return '$pkg${sep}linux${sep}libisar.so';
}

Future<void> initIsarCore() =>
    Isar.initializeIsarCore(libraries: {Abi.current(): isarLibPath()});
