// tool/probes/almacen_seguro_windows.dart
//
// Para las pruebas en Windows real: provocar DE VERDAD que el almacén
// seguro (`flutter_secure_storage_windows` 3.1.2) no devuelva lo guardado.
//
// Cómo guarda ese complemento (leído de su .cpp y su CMakeLists):
//  - Cada valor va a un archivo `<prefijo><clave>.secure` en
//    %APPDATA%\<empresa>\<producto> (los del recurso de versión del .exe),
//    cifrado con AES-GCM.
//  - La llave AES vive en el Administrador de credenciales como credencial
//    genérica `key_<prefijo>`, con <prefijo> = `<NOMBRE DEL EJECUTABLE>_
//    VGhpcyBpcyB0aGUgcHJlZml4IGZv_`.
//  - Al leer: si la credencial no existe crea una llave NUEVA; el archivo
//    viejo ya no se puede descifrar y devuelve null, sin error. Si el
//    archivo no existe también devuelve null.
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

const _suffix = '_VGhpcyBpcyB0aGUgcHJlZml4IGZv_';
const _credTypeGeneric = 1;

/// Prefijo que el complemento antepone a todo (depende del nombre del .exe).
String secureStoragePrefix() {
  final exe = Platform.resolvedExecutable.split(Platform.pathSeparator).last;
  final name = exe.toLowerCase().endsWith('.exe')
      ? exe.substring(0, exe.length - 4)
      : exe;
  return '$name$_suffix';
}

/// Nombre exacto de la credencial que guarda la llave.
String secureStorageKeyCredential() => 'key_${secureStoragePrefix()}';

/// ¿Existe la credencial de la llave?
bool secureStorageKeyExists() {
  if (!Platform.isWindows) return false;
  final target = secureStorageKeyCredential().toNativeUtf16();
  final out = calloc<Pointer<CREDENTIAL>>();
  try {
    final ok = CredRead(target, _credTypeGeneric, 0, out) != 0;
    if (ok) CredFree(out.value);
    return ok;
  } finally {
    calloc.free(target);
    calloc.free(out);
  }
}

/// Borra la credencial de la llave. Devuelve true si existía y ya no está.
bool deleteSecureStorageKey() {
  if (!Platform.isWindows || !secureStorageKeyExists()) return false;
  final target = secureStorageKeyCredential().toNativeUtf16();
  try {
    CredDelete(target, _credTypeGeneric, 0);
  } finally {
    calloc.free(target);
  }
  return !secureStorageKeyExists();
}

/// Borra los archivos `.secure` de [directory]. Devuelve cuántos borró.
int deleteSecureFiles(Directory directory) {
  var deleted = 0;
  if (!directory.existsSync()) return 0;
  for (final f in directory.listSync().whereType<File>()) {
    if (f.path.toLowerCase().endsWith('.secure')) {
      try {
        f.deleteSync();
        deleted++;
      } catch (_) {}
    }
  }
  return deleted;
}
