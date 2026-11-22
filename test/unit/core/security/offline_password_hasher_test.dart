import 'dart:convert';

import 'package:baudex_desktop/app/core/security/offline_password_hasher.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

String hex(List<int> b) => b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

/// PBKDF2 de referencia con `Hmac` de package:crypto.
List<int> referencePbkdf2(List<int> p, List<int> s, int c) {
  final mac = Hmac(sha256, p);
  var u = mac.convert([...s, 0, 0, 0, 1]).bytes;
  final t = [...u];
  for (var i = 1; i < c; i++) {
    u = mac.convert(u).bytes;
    for (var j = 0; j < 32; j++) {
      t[j] ^= u[j];
    }
  }
  return t;
}

void main() {
  group('PBKDF2-HMAC-SHA256', () {
    test('vector del RFC 7914 (passwd / salt / 1 vuelta / 64 bytes)', () {
      final dk = OfflinePasswordHasher.pbkdf2Sha256(
          utf8.encode('passwd'), utf8.encode('salt'), 1, 64);
      expect(
        hex(dk),
        '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc'
        '49ca9cccf179b645991664b39d77ef317c71b845b1e30bd509112041d3a19783',
      );
    });

    test('vector del RFC 7914 (Password / NaCl / 80000 vueltas)', () {
      final dk = OfflinePasswordHasher.pbkdf2Sha256(
          utf8.encode('Password'), utf8.encode('NaCl'), 80000, 64);
      expect(
        hex(dk),
        '4ddcd8f60b98be21830cee5ef22701f9641a4418d04c0414aeff08876b34ab56'
        'a1d425a1225833549adb841b51c9b3176a272bdebba1d078478f62b397f33c8d',
      );
    });

    test('igual a la referencia con contraseña larga (más de 64 bytes)', () {
      final p = utf8.encode('x' * 100);
      expect(OfflinePasswordHasher.pbkdf2Sha256(p, [1, 2, 3], 777, 32),
          referencePbkdf2(p, [1, 2, 3], 777));
    });

    test('tiempo de una huella con las vueltas de la app', () {
      final sw = Stopwatch()..start();
      OfflinePasswordHasher.pbkdf2Sha256(
          utf8.encode('clave'), List.filled(16, 1), OfflinePasswordHasher.iterations, 32);
      sw.stop();
      // En pruebas corre sin compilar (más lento que la app). Solo evita
      // que alguien suba las vueltas a algo que congele el inicio de sesión.
      expect(sw.elapsedMilliseconds, lessThan(5000));
      // ignore: avoid_print
      print('PBKDF2 ${OfflinePasswordHasher.iterations} vueltas: ${sw.elapsedMilliseconds} ms (JIT)');
    });
  });

  group('huella para entrar sin internet', () {
    test('formato nuevo: acepta la contraseña correcta y rechaza otra', () async {
      final stored = await OfflinePasswordHasher.hash('Secreta#1', rounds: 1000);
      expect(stored, startsWith('pbkdf2-sha256\$1000\$'));
      expect(await OfflinePasswordHasher.verify(
          password: 'Secreta#1', email: 'a@b.co', stored: stored), isTrue);
      expect(await OfflinePasswordHasher.verify(
          password: 'secreta#1', email: 'a@b.co', stored: stored), isFalse);
    });

    test('sal aleatoria: dos huellas de la misma clave son distintas', () async {
      final a = await OfflinePasswordHasher.hash('x', rounds: 100);
      final b = await OfflinePasswordHasher.hash('x', rounds: 100);
      expect(a, isNot(b));
    });

    test('formato viejo (SHA-256 con el correo) sigue sirviendo', () async {
      final legacy = OfflinePasswordHasher.legacyHash('Secreta#1', ' Caja@Tienda.co ');
      expect(await OfflinePasswordHasher.verify(
          password: 'Secreta#1', email: 'caja@tienda.co', stored: legacy), isTrue);
      expect(await OfflinePasswordHasher.verify(
          password: 'otra', email: 'caja@tienda.co', stored: legacy), isFalse);
    });

    test('needsUpgrade: vieja o con menos vueltas sí, actual no', () {
      expect(OfflinePasswordHasher.needsUpgrade('abc123'), isTrue);
      expect(OfflinePasswordHasher.needsUpgrade(
          OfflinePasswordHasher.hashWithSalt('x', [1], 1000)), isTrue);
      expect(OfflinePasswordHasher.needsUpgrade(OfflinePasswordHasher.hashWithSalt(
          'x', [1], OfflinePasswordHasher.iterations)), isFalse);
    });

    test('huella dañada: no deja entrar', () async {
      for (final bad in [
        'pbkdf2-sha256\$abc\$AAAA\$AAAA',
        'pbkdf2-sha256\$1000\$no-base64!\$AAAA',
        'pbkdf2-sha256\$1000\$AAAA',
        'pbkdf2-sha256\$1000\$AAAA\$',
      ]) {
        expect(await OfflinePasswordHasher.verify(
            password: 'x', email: 'a@b.co', stored: bad), isFalse, reason: bad);
      }
    });
  });
}
