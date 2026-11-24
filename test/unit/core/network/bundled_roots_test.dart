// Las raíces de Let's Encrypt que lleva la app son las auténticas y se pueden cargar.
import 'dart:convert';
import 'dart:io';

import 'package:baudex_desktop/app/core/network/bundled_roots.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

String fingerprint(String pem) {
  final b64 = pem
      .split('\n')
      .where((l) => l.isNotEmpty && !l.startsWith('-----'))
      .join();
  return sha256
      .convert(base64Decode(b64))
      .bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(':');
}

void main() {
  test('ISRG Root X1 y X2 tienen la huella publicada por Let\'s Encrypt', () {
    expect(fingerprint(BundledRoots.isrgRootX1),
        '96:BC:EC:06:26:49:76:F3:74:60:77:9A:CF:28:C5:A7:CF:E8:A3:C0:AA:E1:1A:8F:FC:EE:05:C0:BD:DF:08:C6');
    expect(fingerprint(BundledRoots.isrgRootX2),
        '69:72:9B:8E:15:A8:6E:FC:17:7A:57:AF:B7:17:1D:FC:64:AD:D2:8C:2F:CA:8C:F1:50:7E:34:45:3C:CB:14:70');
  });

  test('un contexto sin raíces del sistema las acepta', () {
    final ctx = SecurityContext(withTrustedRoots: false);
    for (final pem in BundledRoots.all) {
      ctx.setTrustedCertificatesBytes(utf8.encode(pem));
    }
  });

  test('agregarlas al contexto por defecto no falla y se puede repetir', () {
    BundledRoots.debugReset();
    BundledRoots.ensureTrusted(force: true);
    BundledRoots.ensureTrusted(force: true);
    expect(BundledRoots.problems, isEmpty);
    BundledRoots.debugReset();
  });
}
