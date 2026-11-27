// Revisión del paso visual de Inventario: las funciones de texto nuevas de
// `inventory_states.dart` no deben cambiar el sentido de lo que ve el cajero.
import 'package:flutter_test/flutter_test.dart';
import 'package:baudex_desktop/features/inventory/presentation/widgets/inventory_states.dart';

void main() {
  group('formatInventoryQuantityText', () {
    test('mantiene el signo y agrega miles', () {
      expect(formatInventoryQuantityText('+120003'), '+120.003');
      expect(formatInventoryQuantityText('-5'), '−5');
      expect(formatInventoryQuantityText('0'), '0');
    });

    test('un texto que no es número queda igual', () {
      expect(formatInventoryQuantityText('N/A'), 'N/A');
    });
  });

  group('friendlyInventoryError', () {
    test('sin conexión da el mensaje de internet', () {
      expect(friendlyInventoryError('SocketException: Failed host lookup'),
          startsWith('Sin conexión'));
    });

    test('un mensaje claro en español se muestra tal cual', () {
      expect(friendlyInventoryError('No tienes permiso para ver almacenes'),
          'No tienes permiso para ver almacenes');
    });

    test('texto técnico se reemplaza por uno genérico', () {
      expect(
          friendlyInventoryError('Error inesperado: Null check operator',
              what: 'los lotes'),
          contains('los lotes'));
    });

    // Un número de 3 cifras no vuelve "técnico" un mensaje útil.
    test('mensaje claro con un número de 3 cifras se muestra tal cual', () {
      expect(friendlyInventoryError('Solo hay 120 unidades disponibles'),
          'Solo hay 120 unidades disponibles');
    });
  });
}
