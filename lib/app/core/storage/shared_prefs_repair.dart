// lib/app/core/storage/shared_prefs_repair.dart
//
// En Windows y Linux las preferencias del equipo son un archivo JSON
// (`shared_preferences.json`) que el complemento escribe sin protección: si
// el computador se apaga mientras escribe, queda cortado o lleno de ceros.
// A partir de ahí `SharedPreferences.getInstance()` lanza `FormatException`
// para siempre y todo lo que lo usa falla.
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Si [file] existe y no es JSON válido, lo aparta (`.danado-<fecha>`) para
/// que las preferencias vuelvan a funcionar. Devuelve true si lo apartó.
/// Lo que había adentro ya no se podía leer; se conserva por si hace falta.
bool setAsideIfCorruptJson(File file, {DateTime? now}) {
  if (!file.existsSync()) return false;
  final String text;
  try {
    text = file.readAsStringSync();
  } catch (_) {
    // Ni siquiera se puede leer como texto: está dañado.
    return _setAside(file, now);
  }
  if (text.isEmpty) return false; // El complemento lo trata como vacío.
  try {
    json.decode(text);
    return false;
  } catch (_) {
    return _setAside(file, now);
  }
}

bool _setAside(File file, DateTime? now) {
  final stamp = (now ?? DateTime.now()).millisecondsSinceEpoch;
  try {
    file.renameSync('${file.path}.danado-$stamp');
    return true;
  } catch (_) {
    try {
      file.deleteSync();
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Revisa el archivo real de preferencias de este equipo. Solo aplica en
/// Windows y Linux (en macOS y celulares no es un archivo JSON).
Future<bool> repairDevicePreferencesFile() async {
  if (!Platform.isWindows && !Platform.isLinux) return false;
  try {
    final dir = await getApplicationSupportDirectory();
    final sep = Platform.pathSeparator;
    return setAsideIfCorruptJson(File('${dir.path}${sep}shared_preferences.json'));
  } catch (_) {
    return false;
  }
}
