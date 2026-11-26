// tool/probes/almacen_seguro_windows.dart
//
// Para las pruebas en Windows real: provocar DE VERDAD que el almacén
// seguro no devuelva la sesión, como puede pasar al apagar el equipo.
//
// Cómo guarda `flutter_secure_storage_windows` 3.1.2 (la parte que de
// verdad se usa es la de Dart, `lib/src/flutter_secure_storage_windows_
// ffi.dart`; el .cpp es solo compatibilidad con versiones viejas):
//  - TODO va en un solo archivo, `flutter_secure_storage.dat`, en
//    %APPDATA%\<empresa>\<producto> (la misma carpeta de las
//    preferencias): un JSON cifrado con DPAPI.
//  - Cada cambio reescribe el archivo entero, encima del anterior.
//  - Al leer, si no lo puede descifrar o no es JSON, BORRA el archivo y
//    lanza error: la sesión se pierde sin aviso.
import 'dart:io';

const String secureStorageFileName = 'flutter_secure_storage.dat';

File secureStorageFile(Directory supportDirectory) => File(
  '${supportDirectory.path}${Platform.pathSeparator}$secureStorageFileName',
);

/// Deja el archivo del almacén seguro en el estado pedido y dice qué hizo.
/// [state]: dat-ceros (mismo tamaño, lleno de ceros: apagón), dat-cortado
/// (a la mitad: cierre a mitad de escritura), dat-borrado.
/// Devuelve null si no había archivo que tocar.
String? sabotageSecureStorage(Directory supportDirectory, String state) {
  final file = secureStorageFile(supportDirectory);
  if (!file.existsSync()) return null;
  final size = file.lengthSync();
  if (size == 0) return null;
  switch (state) {
    case 'dat-ceros':
      file.writeAsBytesSync(List<int>.filled(size, 0), flush: true);
      return 'en ceros ($size bytes)';
    case 'dat-cortado':
      final bytes = file.readAsBytesSync();
      file.writeAsBytesSync(bytes.sublist(0, size ~/ 2), flush: true);
      return 'cortado a ${size ~/ 2} de $size bytes';
    case 'dat-borrado':
      file.deleteSync();
      return 'borrado ($size bytes)';
  }
  return null;
}

/// Lo que hay en disco de la sesión, para saber en qué modo está el equipo.
String describeSessionOnDisk(Directory supportDirectory, File prefsFile) {
  final dat = secureStorageFile(supportDirectory);
  final datText = dat.existsSync() ? '${dat.lengthSync()} bytes' : 'no existe';
  var backups = 0;
  var hasCopy = false;
  try {
    if (prefsFile.existsSync()) {
      final text = prefsFile.readAsStringSync();
      backups = RegExp(r'"flutter\.secure_').allMatches(text).length;
      hasCopy = text.contains('"flutter.vault_session_v2"');
    }
  } catch (_) {}
  final mode = backups > 0 && !dat.existsSync()
      ? 'preferencias'
      : dat.existsSync()
      ? 'almacén seguro'
      : 'ninguno (sin sesión guardada)';
  return 'modo de sesión: $mode | $secureStorageFileName: $datText; '
      'respaldo secure_* en preferencias: $backups; copia protegida: ${hasCopy ? 'sí' : 'no'}';
}
