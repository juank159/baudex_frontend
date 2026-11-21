import 'package:baudex_desktop/app/core/navigation/getx_route_janitor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
// ignore: implementation_imports
import 'package:get/get_navigation/src/router_report.dart';

class _CtrlA extends GetxController {}

class _CtrlB extends GetxController {}

class _Repo {}

class _Page extends StatelessWidget {
  const _Page(this.build_);
  final void Function() build_;
  @override
  Widget build(BuildContext context) {
    build_();
    return const SizedBox();
  }
}

String _dump() {
  String out = '';
  final prev = Get.log;
  Get.log = (t, {bool isError = false}) => out = t;
  RouterReportManager().printInstanceStack();
  Get.log = prev;
  return out;
}

int _entries() => ': ['.allMatches(_dump()).length;

void main() {
  group('planRelink / splitRegistryKeys', () {
    test('separa llaves respetando genéricos', () {
      expect(splitRegistryKeys('A, B<C, D>, Etag'), ['A', 'B<C, D>', 'Etag']);
      expect(splitRegistryKeys(''), isEmpty);
    });

    test('lee las entradas en orden aunque todas las rutas se impriman igual', () {
      // Así imprime GetX en las versiones compiladas (no en las pruebas).
      const r = "Instance of 'GetPageRoute<dynamic>'";
      expect(parseRegistryEntries('{$r: [A, B<C, D>], $r: [], $r: [E]}'), [
        ['A', 'B<C, D>'],
        <String>[],
        ['E'],
      ]);
      expect(parseRegistryEntries('{}'), isEmpty);
      expect(parseRegistryEntries('basura'), isNull);
    });

    test('vuelve a anotar solo lo de las pantallas que se conservan', () {
      final plan = relinkPlan(
        owners: ['muerta', 'viva', 'muerta2', 'viva'],
        keys: [
          ['A'],
          ['B'],
          ['C'],
          ['D'],
        ],
        keep: {'viva'},
      );
      expect(plan.single.owner, 'viva');
      expect(plan.single.keys, ['B', 'D']);
    });
  });

  group('con GetX de verdad', () {
    setUp(() {
      Get.reset();
      RouterReportManager.clearRouteKeys();
      GetxRouteJanitor.instance.reset();
    });

    Future<void> pumpApp(WidgetTester tester) async {
      await tester.pumpWidget(GetMaterialApp(
        initialRoute: '/a',
        navigatorObservers: [GetxRouteJanitor.instance],
        getPages: [
          GetPage(
            name: '/a',
            page: () => _Page(() {
              Get.find<_Repo>();
              Get.find<_CtrlA>();
            }),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => _Repo());
              Get.lazyPut(() => _CtrlA());
            }),
          ),
          GetPage(
            name: '/b',
            page: () => _Page(() => Get.find<_CtrlB>()),
            binding: BindingsBuilder(() => Get.lazyPut(() => _CtrlB())),
          ),
        ],
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('el menú (offAllNamed) y apilar/volver ya no acumulan pantallas', (tester) async {
      await pumpApp(tester);
      for (var i = 0; i < 40; i++) {
        Get.offAllNamed(i.isEven ? '/b' : '/a');
        await tester.pumpAndSettle();
      }
      // Sin limpieza GetX guarda una entrada por cada pantalla visitada.
      expect(_entries(), greaterThan(30));

      await tester.pump(const Duration(seconds: 3));
      expect(GetxRouteJanitor.instance.sweeps, greaterThan(0));
      expect(_entries(), 1, reason: _dump());

      // La pantalla abierta sigue siendo dueña de su controlador: al salir de
      // ella GetX lo borra igual que antes.
      expect(Get.isRegistered<_CtrlA>(), isTrue);
      Get.offAllNamed('/b');
      await tester.pumpAndSettle();
      expect(Get.isRegistered<_CtrlA>(), isFalse);
      expect(Get.isRegistered<_CtrlB>(), isTrue);
      // Apilar (toNamed) y volver: se borra el de arriba y /a conserva el suyo.
      Get.offAllNamed('/a');
      await tester.pumpAndSettle();
      for (var i = 0; i < 10; i++) {
        Get.toNamed('/b');
        await tester.pumpAndSettle();
        expect(Get.isRegistered<_CtrlB>(), isTrue);
        Get.back();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        expect(Get.isRegistered<_CtrlB>(), isFalse);
        expect(Get.isRegistered<_CtrlA>(), isTrue);
      }
      // Navegar rápido (sin dejar limpiar entre pantallas), como el menú.
      for (var i = 0; i < 20; i++) {
        Get.toNamed('/b');
        await tester.pump(const Duration(milliseconds: 400));
        Get.back();
        await tester.pump(const Duration(milliseconds: 400));
      }
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      final j = GetxRouteJanitor.instance;
      expect(j.closingCount, 0, reason: 'no guarda pantallas ya desechadas');
      expect(_entries(), 1, reason: 'sw=${j.sweeps} sk=${j.skipped} ${j.lastSkip}');
      // /a debajo conserva su anotación (repositorio y controlador).
      expect(_dump(), contains('_Repo'));
      GetxRouteJanitor.instance.reset();
    });

  });
}
