import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/data/local/sync_failure_policy.dart';
import 'package:flutter_test/flutter_test.dart';

SyncFailureKind kind(Object error, {String entity = 'Invoice', bool permanent = false}) =>
    classifySyncFailure(
      entityType: entity,
      error: error,
      isPermanentValidation: permanent,
    );

void main() {
  group('Fallas transitorias: se reintentan solas, nunca se pierden', () {
    test('sin conexión / timeout', () {
      expect(kind(const ConnectionException('Sin conexión a internet')), SyncFailureKind.transient);
      expect(kind(ConnectionException.timeout), SyncFailureKind.transient);
      expect(kind(Exception('SocketException: Connection refused')), SyncFailureKind.transient);
    });

    test('servidor caído o con error interno (5xx)', () {
      for (final code in [500, 502, 503, 504]) {
        expect(kind(ServerException('Error', statusCode: code)), SyncFailureKind.transient, reason: '$code');
      }
    });

    test('sesión vencida, timeout del servidor y límite de peticiones', () {
      for (final code in [401, 408, 429]) {
        expect(kind(ServerException('Error', statusCode: code)), SyncFailureKind.transient, reason: '$code');
      }
    });

    test('dependencia que aún no sube', () {
      expect(
        kind(Exception('Credit customercredit_offline_1 aún no sincronizado - reintentando después')),
        SyncFailureKind.transient,
      );
    });

    test('error inesperado sin código', () {
      expect(kind(StateError('algo raro')), SyncFailureKind.transient);
      expect(kind(const ServerException('Respuesta inválida del servidor')), SyncFailureKind.transient);
    });

    test('número de movimiento de inventario duplicado por carrera', () {
      expect(
        kind(const ServerException('Solicitud incorrecta: duplicate key value violates unique constraint', statusCode: 400),
            entity: 'InventoryMovement'),
        SyncFailureKind.transient,
      );
    });
  });

  group('Rechazos del servidor: se conservan y se avisa (antes se daban por hechos)', () {
    test('límite de crédito excedido (400)', () {
      expect(
        kind(const ServerException('Solicitud incorrecta: LÍMITE DE CRÉDITO EXCEDIDO...', statusCode: 400)),
        SyncFailureKind.rejected,
      );
    });

    test('caja cerrada (400)', () {
      expect(
        kind(const ServerException('Solicitud incorrecta: No hay una caja abierta.', statusCode: 400)),
        SyncFailureKind.rejected,
      );
    });

    test('crédito ya pagado (400) — "ya está" no es "ya existe"', () {
      expect(
        kind(const ServerException('Solicitud incorrecta: El crédito ya está pagado completamente', statusCode: 400),
            entity: 'CustomerCredit'),
        SyncFailureKind.rejected,
      );
    });

    test('no encontrado / sin permiso / datos inválidos', () {
      expect(kind(const ServerException('Recurso no encontrado: Crédito no encontrado', statusCode: 404)), SyncFailureKind.rejected);
      expect(kind(const ServerException('No tiene permiso', statusCode: 403)), SyncFailureKind.rejected);
      expect(kind(const ServerException('Datos inválidos', statusCode: 422)), SyncFailureKind.rejected);
    });

    test('un texto con "404" dentro (monto, número de factura) NO borra la operación', () {
      expect(
        kind(const ServerException('Solicitud incorrecta: Factura INV-2026-404123 por \$40.400', statusCode: 400)),
        SyncFailureKind.rejected,
      );
    });

    test('validación detectada por el handler', () {
      expect(kind(Exception('x'), permanent: true), SyncFailureKind.rejected);
    });

    test('validación sin código HTTP', () {
      expect(kind(Exception('Solicitud incorrecta: amount must be a valid number')), SyncFailureKind.rejected);
    });
  });

  group('Suscripción vencida: se pausa y se conserva (antes se descartaba)', () {
    test('403 con mensaje de suscripción', () {
      expect(
        kind(const ServerException('Su suscripción ha expirado. Actualice su plan', statusCode: 403)),
        SyncFailureKind.subscription,
      );
    });
  });

  group('Ya existe en el servidor: única falla que confirma', () {
    test('409 / registro duplicado', () {
      expect(kind(const ServerException('Conflicto: La factura ya existe', statusCode: 409)), SyncFailureKind.alreadyOnServer);
      expect(kind(Exception('duplicate key value violates unique constraint "UQ_x"')), SyncFailureKind.alreadyOnServer);
    });

    test('409 sin texto de duplicado es un rechazo, no una confirmación', () {
      expect(kind(const ServerException('Conflicto: stock insuficiente', statusCode: 409)), SyncFailureKind.rejected);
    });
  });
}
