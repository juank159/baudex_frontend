// Prueba de la causa del "al volver a la factura se congela":
// cada escaneo repetido en la factura muestra un Get.snackbar de 2 s
// ("Producto Actualizado"). GetX los pone EN FILA y, mientras haya uno
// abierto, Get.back() solo cierra el aviso y NO vuelve de pantalla
// (get 4.7.3, extension_navigation.dart:825). Con 100 escaneos quedan
// ~90 avisos en fila (~4 min) y el botón "volver" parece muerto.
//
// Esta prueba documenta ese comportamiento: si un día se cambia la forma de
// avisar (o de volver), debe dejar de cumplirse la primera parte.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  testWidgets('con avisos en fila, Get.back() no vuelve de pantalla', (t) async {
    await t.pumpWidget(GetMaterialApp(
      initialRoute: '/factura',
      getPages: [
        GetPage(name: '/factura', page: () => const Scaffold(body: Text('factura'))),
        GetPage(name: '/productos', page: () => const Scaffold(body: Text('productos'))),
      ],
    ));
    Get.toNamed('/productos');
    await t.pumpAndSettle();
    expect(Get.currentRoute, '/productos');

    // 20 escaneos repetidos = 20 avisos "Producto Actualizado" en fila
    for (var i = 0; i < 20; i++) {
      Get.snackbar('Producto Actualizado', 'x → $i unidades', duration: const Duration(seconds: 2));
    }
    await t.pump(const Duration(milliseconds: 500));

    // El cajero pulsa "volver" 5 veces: sigue en Productos
    for (var i = 0; i < 5; i++) {
      Get.back();
      await t.pump(const Duration(milliseconds: 600));
    }
    expect(Get.currentRoute, '/productos',
        reason: 'Get.back() se gasta cerrando avisos en vez de volver');

    // Volver de verdad exige cerrar los avisos o usar el Navigator
    Get.closeAllSnackbars();
    await t.pump(const Duration(seconds: 1));
    Get.back();
    await t.pumpAndSettle();
    expect(Get.currentRoute, '/factura');
  });
}
