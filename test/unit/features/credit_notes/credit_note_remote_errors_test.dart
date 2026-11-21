import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/core/network/dio_client.dart';
import 'package:baudex_desktop/features/credit_notes/data/datasources/credit_note_remote_datasource.dart';
import 'package:baudex_desktop/features/credit_notes/data/models/credit_note_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Dio extends Mock implements DioClient {}

class _FakeOptions extends Fake implements Options {}

/// El cliente HTTP de la app ya convierte los errores (sin conexión →
/// ConnectionException; rechazo → ServerException con su código). Antes esta
/// fuente los volvía TODOS "Error inesperado" sin código: al confirmar una
/// nota con el servidor lento, el cajero veía un error aunque el servidor sí
/// la confirmaba, y un rechazo (400) al crear se guardaba como pendiente.
void main() {
  late _Dio dio;
  late CreditNoteRemoteDataSourceImpl source;

  setUpAll(() => registerFallbackValue(_FakeOptions()));
  setUp(() {
    dio = _Dio();
    source = CreditNoteRemoteDataSourceImpl(dioClient: dio);
  });

  void postThrows(Object error) {
    when(() => dio.post(any(), data: any(named: 'data'), options: any(named: 'options')))
        .thenThrow(error);
  }

  test('confirmar: la espera agotada llega como falta de conexión', () async {
    postThrows(const ConnectionException('Tiempo de conexión agotado.'));
    await expectLater(source.confirmCreditNote('n1'), throwsA(isA<ConnectionException>()));
  });

  test('confirmar: el rechazo del servidor conserva su código y motivo', () async {
    postThrows(const ServerException('Solicitud incorrecta: Solo borradores', statusCode: 400));
    await expectLater(
      source.confirmCreditNote('n1'),
      throwsA(isA<ServerException>()
          .having((e) => e.statusCode, 'código', 400)
          .having((e) => e.message, 'motivo', contains('Solo borradores'))),
    );
  });

  test('confirmar: pide al servidor una espera larga (la confirmación es pesada)', () async {
    when(() => dio.post(any(), data: any(named: 'data'), options: any(named: 'options')))
        .thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
              data: {'success': true, 'data': {'id': 'x'}},
            ));
    try {
      await source.confirmCreditNote('n1');
    } catch (_) {
      // El modelo de prueba está incompleto; aquí solo importa la espera.
    }
    final options = verify(() => dio.post('/credit-notes/n1/confirm',
            data: any(named: 'data'), options: captureAny(named: 'options')))
        .captured
        .single as Options;
    expect(options.receiveTimeout, greaterThanOrEqualTo(const Duration(seconds: 90)));
  });

  test('crear: un 400 sigue siendo 400 (no se guarda como pendiente)', () async {
    postThrows(const ServerException('Solicitud incorrecta: cantidad mayor a la facturada', statusCode: 400));
    await expectLater(
      source.createCreditNote(const CreateCreditNoteRequestModel(
        invoiceId: 'f1',
        type: 'full',
        reason: 'returned_goods',
        items: [],
      )),
      throwsA(isA<ServerException>().having((e) => e.statusCode, 'código', 400)),
    );
  });

  test('anular: sin conexión llega como falta de conexión', () async {
    postThrows(const ConnectionException());
    await expectLater(source.cancelCreditNote('n1'), throwsA(isA<ConnectionException>()));
  });
}
