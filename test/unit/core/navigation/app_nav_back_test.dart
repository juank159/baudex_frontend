import 'package:baudex_desktop/app/core/navigation/navigation_guard.dart';
import 'package:baudex_desktop/app/core/utils/snackbar_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(GetMaterialApp(
      initialRoute: '/factura',
      getPages: [
        GetPage(name: '/factura', page: () => const Scaffold(body: Text('factura'))),
        GetPage(name: '/productos', page: () => const Scaffold(body: Text('productos'))),
      ],
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('con avisos en fila, Volver vuelve de una vez', (tester) async {
    await pumpApp(tester);
    Get.toNamed('/productos');
    await tester.pumpAndSettle();
    for (var i = 0; i < 20; i++) {
      Get.snackbar('Producto', 'actualizado $i', duration: const Duration(seconds: 2));
    }
    await tester.pump(const Duration(milliseconds: 500));
    expect(Get.isSnackbarOpen, isTrue);

    // Get.back() de GetX solo cierra el aviso (así quedaba "congelada").
    Get.back();
    await tester.pump(const Duration(milliseconds: 500));
    expect(Get.currentRoute, '/productos');

    expect(AppNav.back(), isTrue);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(Get.currentRoute, '/factura');
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(Get.isSnackbarOpen, isFalse, reason: 'los avisos en fila se descartan');
  });

  testWidgets('un solo aviso a la vez: el nuevo reemplaza al anterior', (tester) async {
    await pumpApp(tester);
    Future<bool> burst({required bool replace}) async {
      for (var i = 0; i < 15; i++) {
        if (replace) replacePreviousSnackbar();
        Get.snackbar('Aviso', '$i', duration: const Duration(seconds: 2));
        for (var k = 0; k < 12; k++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
      // 4 s después del último (su propia duración + animación): ya no queda nada.
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      return Get.isSnackbarOpen;
    }

    expect(await burst(replace: true), isFalse);
    // Sin la regla, la fila de GetX sigue mostrando avisos (15 × 4 s).
    expect(await burst(replace: false), isTrue);
    Get.closeAllSnackbars();
    for (var i = 0; i < 400; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  });

  testWidgets('Volver con un aviso recién pedido (aún sin mostrar) vuelve y no falla',
      (tester) async {
    await pumpApp(tester);
    for (var vuelta = 0; vuelta < 10; vuelta++) {
      Get.toNamed('/productos');
      await tester.pumpAndSettle();
      // Aviso pedido y Volver en el mismo instante, como hace el cajero
      // al escanear y salir: GetX aún no lo montó.
      replacePreviousSnackbar();
      Get.snackbar('Aviso', 'recién pedido $vuelta', duration: const Duration(seconds: 2));
      expect(AppNav.back(), isTrue);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(Get.currentRoute, '/factura', reason: 'vuelta $vuelta');
      expect(tester.takeException(), isNull, reason: 'vuelta $vuelta');
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(Get.isSnackbarOpen, isFalse, reason: 'vuelta $vuelta');
    }
  });

  testWidgets('aviso pedido mientras se cierran los anteriores: Volver vuelve y no falla',
      (tester) async {
    await pumpApp(tester);
    for (var vuelta = 0; vuelta < 10; vuelta++) {
      Get.toNamed('/productos');
      await tester.pumpAndSettle();
      Get.snackbar('Aviso', 'en pantalla $vuelta', duration: const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 400));
      // Volver cierra los avisos; la pantalla de abajo pide uno nuevo
      // mientras el anterior aún se está cerrando (queda en fila, sin
      // mostrar) y el cajero vuelve otra vez.
      expect(AppNav.back(), isTrue);
      Get.snackbar('Aviso', 'nuevo $vuelta', duration: const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 50));
      Get.toNamed('/productos');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 400));
      expect(AppNav.back(), isTrue, reason: 'vuelta $vuelta');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(Get.currentRoute, '/factura', reason: 'vuelta $vuelta');
      expect(tester.takeException(), isNull, reason: 'vuelta $vuelta');
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull, reason: 'vuelta $vuelta');
    }
  });
}
