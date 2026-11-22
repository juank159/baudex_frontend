// DELETE que el servidor responde con 404: el registro ya no existe allá,
// así que la eliminación cuenta como hecha (caso real: printer_settings).
import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/data/local/sync_failure_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const notFound = ServerException(
    'Recurso no encontrado: Impresora no encontrada',
    statusCode: 404,
  );

  group('isDeleteAlreadyGone', () {
    test('DELETE + 404 → confirmado', () {
      expect(isDeleteAlreadyGone(isDelete: true, error: notFound), isTrue);
    });

    test('CREATE o UPDATE con 404 no se confirman', () {
      expect(isDeleteAlreadyGone(isDelete: false, error: notFound), isFalse);
    });

    test('DELETE con otro código o sin código no se confirma', () {
      expect(
        isDeleteAlreadyGone(
          isDelete: true,
          error: const ServerException('Conflicto', statusCode: 409),
        ),
        isFalse,
      );
      expect(
        isDeleteAlreadyGone(isDelete: true, error: const ConnectionException('sin red')),
        isFalse,
      );
      expect(isDeleteAlreadyGone(isDelete: true, error: Exception('x')), isFalse);
    });

    test('ruta inexistente ("Cannot DELETE") no cuenta como borrado', () {
      expect(
        isDeleteAlreadyGone(
          isDelete: true,
          error: const ServerException(
            'Recurso no encontrado: Cannot DELETE /api/printer-settings/1',
            statusCode: 404,
          ),
        ),
        isFalse,
      );
    });
  });

  group('isFailedDeleteAlreadyGone (operaciones que ya quedaron fallidas)', () {
    test('error guardado del caso de Granada → se limpia', () {
      expect(
        isFailedDeleteAlreadyGone(
          isDelete: true,
          storedError:
              'RECHAZADA POR EL SERVIDOR: Recurso no encontrado: Impresora no encontrada',
        ),
        isTrue,
      );
    });

    test('otros errores, otras operaciones o sin error → se conservan', () {
      expect(
        isFailedDeleteAlreadyGone(
          isDelete: true,
          storedError: 'RECHAZADA POR EL SERVIDOR: Solicitud incorrecta: tiene existencias',
        ),
        isFalse,
      );
      expect(
        isFailedDeleteAlreadyGone(
          isDelete: false,
          storedError: 'Recurso no encontrado: Producto no encontrado',
        ),
        isFalse,
      );
      expect(isFailedDeleteAlreadyGone(isDelete: true, storedError: null), isFalse);
      expect(
        isFailedDeleteAlreadyGone(
          isDelete: true,
          storedError: 'Recurso no encontrado: Cannot DELETE /api/x/1',
        ),
        isFalse,
      );
    });
  });

  test('la clasificación general no cambia: un 404 sigue siendo rechazo', () {
    expect(
      classifySyncFailure(entityType: 'printer_settings', error: notFound),
      SyncFailureKind.rejected,
    );
  });
}
