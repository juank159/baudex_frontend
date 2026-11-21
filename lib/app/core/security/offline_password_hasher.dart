// lib/app/core/security/offline_password_hasher.dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show compute;

/// Huella de la contraseña para entrar sin internet.
///
/// Formato nuevo: `pbkdf2-sha256$<vueltas>$<sal base64>$<huella base64>`
/// (PBKDF2-HMAC-SHA256, sal aleatoria de 16 bytes, 32 bytes de salida).
///
/// Formato viejo (versiones anteriores): SHA-256 en hexadecimal de
/// `"<correo>:<contraseña>"`. Se sigue aceptando para no dejar a nadie sin
/// entrar sin internet, y se reemplaza en el siguiente inicio de sesión
/// exitoso ([needsUpgrade]).
class OfflinePasswordHasher {
  OfflinePasswordHasher._();

  static const String prefix = 'pbkdf2-sha256';

  /// Vueltas de PBKDF2. OWASP sugiere más para SHA-256, pero en Dart puro
  /// esto ya cuesta del orden de 100-300 ms en un equipo modesto.
  static const int iterations = 120000;

  static const int _saltBytes = 16;
  static const int _keyBytes = 32;

  /// Calcula la huella nueva (sal aleatoria). Corre en otro hilo para no
  /// congelar la pantalla.
  static Future<String> hash(String password, {int rounds = iterations}) {
    final salt = _randomSalt();
    return compute(_hashJob, [password, salt, rounds]);
  }

  /// Huella con una sal dada (para pruebas y para [hash]).
  static String hashWithSalt(String password, List<int> salt, int rounds) {
    final dk = pbkdf2Sha256(utf8.encode(password), salt, rounds, _keyBytes);
    return '$prefix\$$rounds\$${base64Encode(salt)}\$${base64Encode(dk)}';
  }

  /// Huella del formato viejo.
  static String legacyHash(String password, String email) {
    final salted = '${email.toLowerCase().trim()}:$password';
    return sha256.convert(utf8.encode(salted)).toString();
  }

  /// true si [password] corresponde a [stored] (formato nuevo o viejo).
  static Future<bool> verify({
    required String password,
    required String email,
    required String stored,
  }) async {
    if (stored.startsWith('$prefix\$')) {
      final parts = stored.split('\$');
      if (parts.length != 4) return false;
      final rounds = int.tryParse(parts[1]);
      if (rounds == null || rounds < 1 || rounds > 10000000) return false;
      final List<int> salt;
      final List<int> expected;
      try {
        salt = base64Decode(parts[2]);
        expected = base64Decode(parts[3]);
      } catch (_) {
        return false;
      }
      if (expected.isEmpty) return false;
      final actual = await compute(
        _deriveJob,
        [password, salt, rounds, expected.length],
      );
      return _constantTimeEquals(actual, expected);
    }
    return _constantTimeEquals(
      utf8.encode(legacyHash(password, email)),
      utf8.encode(stored),
    );
  }

  /// true si la huella guardada debe recalcularse (vieja o con menos vueltas).
  static bool needsUpgrade(String stored) {
    if (!stored.startsWith('$prefix\$')) return true;
    final parts = stored.split('\$');
    final rounds = parts.length > 1 ? int.tryParse(parts[1]) : null;
    return rounds == null || rounds < iterations;
  }

  /// PBKDF2-HMAC-SHA256 (RFC 8018).
  ///
  /// Implementación propia de SHA-256 que guarda el estado de las claves
  /// interna y externa de HMAC: cada vuelta cuesta 2 compresiones en vez de
  /// 4 y no crea objetos. Es unas 3-4 veces más rápida que `Hmac` de
  /// `package:crypto` y da el mismo resultado (ver pruebas con los vectores
  /// del RFC 7914).
  static Uint8List pbkdf2Sha256(
    List<int> password,
    List<int> salt,
    int rounds,
    int length,
  ) {
    // Clave HMAC de 64 bytes.
    var key = password;
    if (key.length > 64) key = sha256.convert(key).bytes;
    final ipad = Uint8List(64);
    final opad = Uint8List(64);
    for (var i = 0; i < 64; i++) {
      final k = i < key.length ? key[i] : 0;
      ipad[i] = k ^ 0x36;
      opad[i] = k ^ 0x5c;
    }
    final innerState = Uint32List.fromList(_h0);
    final outerState = Uint32List.fromList(_h0);
    final w = Uint32List(64);
    _compress(innerState, _toWords(ipad, 0), w);
    _compress(outerState, _toWords(opad, 0), w);

    final out = Uint8List(length);
    var offset = 0;
    for (var block = 1; offset < length; block++) {
      // U1 = HMAC(P, S || INT(block)) con package:crypto (una sola vez).
      final first = Uint8List(salt.length + 4)
        ..setAll(0, salt)
        ..[salt.length] = (block >> 24) & 0xff
        ..[salt.length + 1] = (block >> 16) & 0xff
        ..[salt.length + 2] = (block >> 8) & 0xff
        ..[salt.length + 3] = block & 0xff;
      final u1 = Hmac(sha256, password).convert(first).bytes;

      // Bloque de 64 bytes reutilizable: 32 de datos + relleno fijo para un
      // mensaje total de 64 + 32 = 96 bytes (768 bits).
      final msg = Uint32List(16);
      for (var i = 0; i < 8; i++) {
        msg[i] = (u1[i * 4] << 24) | (u1[i * 4 + 1] << 16) | (u1[i * 4 + 2] << 8) | u1[i * 4 + 3];
      }
      final t = Uint32List.fromList(msg.sublist(0, 8));
      final st = Uint32List(8);
      for (var r = 1; r < rounds; r++) {
        // interno: H(ipad || U)
        msg[8] = 0x80000000;
        for (var i = 9; i < 15; i++) {
          msg[i] = 0;
        }
        msg[15] = 768;
        st.setAll(0, innerState);
        _compress(st, msg, w);
        // externo: H(opad || interno)
        for (var i = 0; i < 8; i++) {
          msg[i] = st[i];
        }
        st.setAll(0, outerState);
        _compress(st, msg, w);
        for (var i = 0; i < 8; i++) {
          msg[i] = st[i];
          t[i] ^= st[i];
        }
      }
      for (var i = 0; i < 8 && offset < length; i++) {
        final v = t[i];
        for (var b = 3; b >= 0 && offset < length; b--) {
          out[offset++] = (v >> (b * 8)) & 0xff;
        }
      }
    }
    return out;
  }

  static const List<int> _h0 = [
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
  ];

  static const List<int> _k = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  ];

  static Uint32List _toWords(Uint8List bytes, int start) {
    final words = Uint32List(16);
    for (var i = 0; i < 16; i++) {
      final j = start + i * 4;
      words[i] = (bytes[j] << 24) | (bytes[j + 1] << 16) | (bytes[j + 2] << 8) | bytes[j + 3];
    }
    return words;
  }

  static int _rotr(int x, int n) => ((x >> n) | (x << (32 - n))) & 0xffffffff;

  /// Una compresión SHA-256 de [block] (16 palabras) sobre [state].
  static void _compress(Uint32List state, Uint32List block, Uint32List w) {
    for (var i = 0; i < 16; i++) {
      w[i] = block[i];
    }
    for (var i = 16; i < 64; i++) {
      final a = w[i - 15];
      final b = w[i - 2];
      final s0 = _rotr(a, 7) ^ _rotr(a, 18) ^ (a >> 3);
      final s1 = _rotr(b, 17) ^ _rotr(b, 19) ^ (b >> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xffffffff;
    }
    var a = state[0], b = state[1], c = state[2], d = state[3];
    var e = state[4], f = state[5], g = state[6], h = state[7];
    for (var i = 0; i < 64; i++) {
      final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
      final ch = (e & f) ^ ((~e & 0xffffffff) & g);
      final t1 = (h + s1 + ch + _k[i] + w[i]) & 0xffffffff;
      final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final t2 = (s0 + maj) & 0xffffffff;
      h = g;
      g = f;
      f = e;
      e = (d + t1) & 0xffffffff;
      d = c;
      c = b;
      b = a;
      a = (t1 + t2) & 0xffffffff;
    }
    state[0] = (state[0] + a) & 0xffffffff;
    state[1] = (state[1] + b) & 0xffffffff;
    state[2] = (state[2] + c) & 0xffffffff;
    state[3] = (state[3] + d) & 0xffffffff;
    state[4] = (state[4] + e) & 0xffffffff;
    state[5] = (state[5] + f) & 0xffffffff;
    state[6] = (state[6] + g) & 0xffffffff;
    state[7] = (state[7] + h) & 0xffffffff;
  }

  // Trabajos para `compute` (otro hilo en escritorio; en web corre aquí).
  static String _hashJob(List<Object> a) =>
      hashWithSalt(a[0] as String, a[1] as List<int>, a[2] as int);

  static Uint8List _deriveJob(List<Object> a) => pbkdf2Sha256(
      utf8.encode(a[0] as String), a[1] as List<int>, a[2] as int, a[3] as int);

  static List<int> _randomSalt() {
    final r = Random.secure();
    return List<int>.generate(_saltBytes, (_) => r.nextInt(256));
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
