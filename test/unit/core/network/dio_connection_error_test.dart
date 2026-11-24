// Un fallo para llegar al servidor siempre es ConnectionException y dice por qué.
import 'dart:io';

import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final options = RequestOptions(path: '/auth/login');

  setUpAll(() {
    dotenv.testLoad(
        fileInput: 'SERVER_IP=servidor.prueba\nSERVER_PORT=443\nAPP_ENV=production');
  });

  test('certificado que el equipo no reconoce (dio lo entrega como "unknown" sin mensaje)', () {
    final e = DioClient.connectionExceptionFor(DioException(
      requestOptions: options,
      error: const HandshakeException(
          'Handshake error in client (OS Error: CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate)'),
    ));
    expect(e, isA<ConnectionException>());
    expect(e.message, contains('certificado'));
    expect(e.message, contains('CERTIFICATE_VERIFY_FAILED'));
    expect(e.message, isNot(contains('null')));
  });

  test('sin red (dio 5 lo entrega como connectionError)', () {
    final e = DioClient.connectionExceptionFor(DioException.connectionError(
      requestOptions: options,
      reason: "Failed host lookup: 'servidor.prueba'",
      error: const SocketException("Failed host lookup: 'servidor.prueba'"),
    ));
    expect(e, isA<ConnectionException>());
    expect(e.message, contains('Sin conexión con el servidor'));
    expect(e.message, contains('Failed host lookup'));
    expect(e.message, contains('https://servidor.prueba/api'));
  });

  test('badCertificate', () {
    final e = DioClient.connectionExceptionFor(
        DioException.badCertificate(requestOptions: options));
    expect(e.message, contains('certificado'));
  });
}
