// lib/app/core/storage/value_protector.dart
//
// Cifrado de valores con la protección de datos de Windows (DPAPI): solo
// el mismo usuario de Windows en el mismo equipo puede leerlos. No depende
// del Administrador de credenciales, que es donde `flutter_secure_storage`
// guarda su llave.
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

abstract class ValueProtector {
  /// Texto cifrado listo para guardar, o null si no se pudo cifrar.
  String? protect(String plain);

  /// El valor original, o null si no se pudo descifrar (otro equipo, otro
  /// usuario o dato dañado).
  String? unprotect(String stored);
}

class DpapiProtector implements ValueProtector {
  const DpapiProtector();

  static const _prefix = 'dpapi:v1:';

  /// Disponible solo en Windows.
  static bool get isSupported => Platform.isWindows;

  @override
  String? protect(String plain) {
    final out = _crypt(Uint8List.fromList(utf8.encode(plain)), protect: true);
    return out == null ? null : '$_prefix${base64Encode(out)}';
  }

  @override
  String? unprotect(String stored) {
    if (!stored.startsWith(_prefix)) return null;
    try {
      final out = _crypt(
        base64Decode(stored.substring(_prefix.length)),
        protect: false,
      );
      return out == null ? null : utf8.decode(out);
    } catch (_) {
      return null;
    }
  }

  Uint8List? _crypt(Uint8List input, {required bool protect}) {
    if (!isSupported) return null;
    final inBlob = calloc<CRYPT_INTEGER_BLOB>();
    final outBlob = calloc<CRYPT_INTEGER_BLOB>();
    final buffer = calloc<Uint8>(input.isEmpty ? 1 : input.length);
    try {
      buffer.asTypedList(input.length).setAll(0, input);
      inBlob.ref
        ..cbData = input.length
        ..pbData = buffer;
      // 0x1 = CRYPTPROTECT_UI_FORBIDDEN: nunca abrir ventanas.
      final ok = protect
          ? CryptProtectData(inBlob, nullptr, nullptr, nullptr, nullptr, 0x1, outBlob)
          : CryptUnprotectData(inBlob, nullptr, nullptr, nullptr, nullptr, 0x1, outBlob);
      if (ok == 0 || outBlob.ref.pbData == nullptr) return null;
      final result = Uint8List.fromList(
        outBlob.ref.pbData.asTypedList(outBlob.ref.cbData),
      );
      LocalFree(outBlob.ref.pbData);
      return result;
    } catch (_) {
      return null;
    } finally {
      calloc.free(buffer);
      calloc.free(inBlob);
      calloc.free(outBlob);
    }
  }
}
