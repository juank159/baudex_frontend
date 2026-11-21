import 'package:baudex_desktop/app/core/navigation/navigation_guard.dart';
import 'package:flutter_test/flutter_test.dart';

/// Abrir módulos desde el menú o Alt+número sin perder la venta en curso.
void main() {
  const pos = '/invoices/tabs';
  const products = '/products';
  const dashboard = '/dashboard';

  ModuleNav nav(String route, List<String> open, {bool sale = false}) =>
      moduleNavigation(
        route: route,
        currentRoute: open.last,
        openRoutes: open,
        mustKeep: (r) => sale && r == pos,
      );

  test('Alt+6 con una venta a medias: Productos se abre ENCIMA de Facturación', () {
    final r = nav(products, [pos], sale: true);
    expect(r.kind, ModuleNavKind.pushKeeping);
    expect(r.keep, pos);
  });

  test('Alt+2 desde Productos: vuelve a la Facturación abierta (con su venta)', () {
    expect(nav(pos, [pos, products], sale: true).kind, ModuleNavKind.returnToOpen);
  });

  test('sin venta a medias: reemplaza la pila como el menú', () {
    expect(nav(products, [pos]).kind, ModuleNavKind.replaceAll);
  });

  test('ir a un módulo abierto DEBAJO de la venta no la cierra', () {
    final r = nav(dashboard, [dashboard, pos], sale: true);
    expect(r.kind, ModuleNavKind.pushKeeping);
    expect(r.keep, pos);
  });

  test('desde Productos (encima de la venta) a otro módulo: sigue encima de la venta', () {
    final r = nav('/customers', [pos, products], sale: true);
    expect(r.kind, ModuleNavKind.pushKeeping);
    expect(r.keep, pos);
  });
}
