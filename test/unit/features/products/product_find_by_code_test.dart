import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/core/network/dio_client.dart';
import 'package:baudex_desktop/features/products/data/datasources/product_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Dio extends Mock implements DioClient {}

/// Buscar un producto por código (barras o SKU) en el servidor. La app pedía
/// "/products/find/:code", que el servidor no tiene: siempre 404.
void main() {
  late _Dio dio;
  late ProductRemoteDataSourceImpl source;
  setUp(() {
    dio = _Dio();
    source = ProductRemoteDataSourceImpl(dioClient: dio);
    when(() => dio.get(any(), queryParameters: any(named: 'queryParameters')))
        .thenThrow(const ServerException('Recurso no encontrado: no existe', statusCode: 404));
  });

  test('usa las rutas que sí existen: primero código de barras y luego SKU', () async {
    await expectLater(source.findBySkuOrBarcode('7701'), throwsA(isA<ServerException>()));
    verify(() => dio.get('/products/barcode/7701', queryParameters: any(named: 'queryParameters'))).called(1);
    verify(() => dio.get('/products/sku/7701', queryParameters: any(named: 'queryParameters'))).called(1);
    verifyNever(() => dio.get('/products/find/7701', queryParameters: any(named: 'queryParameters')));
  });
}
