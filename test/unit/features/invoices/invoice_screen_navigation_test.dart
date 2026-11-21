import 'package:baudex_desktop/app/config/routes/app_routes.dart';
import 'package:baudex_desktop/app/core/navigation/navigation_guard.dart';
import 'package:baudex_desktop/app/core/navigation/route_stack_observer.dart';
import 'package:baudex_desktop/app/core/services/tenant_datetime_service.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/create_invoice_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/get_invoice_by_id_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/update_invoice_usecase.dart';
import 'package:baudex_desktop/features/invoices/presentation/screens/invoice_form_screen.dart';
import 'package:baudex_desktop/features/invoices/presentation/screens/invoice_form_tabs_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tzdata;

class _Create extends Mock implements CreateInvoiceUseCase {}

class _Update extends Mock implements UpdateInvoiceUseCase {}

class _GetById extends Mock implements GetInvoiceByIdUseCase {}

/// Facturación abierta → otra pantalla encima (atajo Alt+número, paleta de
/// comandos) → volver a Facturación desde el menú. La pantalla nueva quedaba
/// con un controlador ya cerrado (sin pestañas): se veía cargando para
/// siempre y no respondía.
void main() {
  setUpAll(tzdata.initializeTimeZones);
  setUp(() {
    Get.testMode = true;
    Get.put<TenantDateTimeService>(TenantDateTimeService());
    Get.put<CreateInvoiceUseCase>(_Create());
    Get.put<UpdateInvoiceUseCase>(_Update());
    Get.put<GetInvoiceByIdUseCase>(_GetById());
  });
  tearDown(() {
    Get.reset();
    RouteStackObserver.instance.reset();
  });

  Future<void> frames(WidgetTester t, [int n = 8]) async {
    for (var i = 0; i < n; i++) {
      await t.pump(const Duration(milliseconds: 400));
    }
  }

  Future<void> start(WidgetTester t) async {
    t.view.physicalSize = const Size(1440, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(GetMaterialApp(
      navigatorObservers: [RouteStackObserver.instance],
      initialRoute: AppRoutes.invoicesWithTabs,
      getPages: [
        GetPage(name: AppRoutes.invoicesWithTabs, page: () => const InvoiceFormTabsScreen()),
        GetPage(
          name: AppRoutes.products,
          page: () => const Scaffold(body: Text('Productos')),
        ),
      ],
    ));
    await frames(t);
    expect(find.byType(InvoiceFormScreen), findsOneWidget);
  }

  testWidgets('Productos encima y volver a Facturación desde el menú: la factura responde',
      (t) async {
    await start(t);
    // Atajo / paleta de antes: Productos ENCIMA de la factura.
    Get.toNamed(AppRoutes.products);
    await frames(t);
    // Menú lateral: volver a Facturación.
    AppNav.offAllNamed(AppRoutes.invoicesWithTabs);
    await frames(t);

    expect(find.byType(InvoiceFormScreen), findsOneWidget,
        reason: 'la pantalla de venta debe aparecer, no quedarse cargando');
    expect(find.byType(InvoiceFormTabsScreen), findsOneWidget);
    await frames(t, 40);
  });

  test('volver a una pantalla abierta solo si está debajo y sin argumentos', () {
    bool open(String r) => r == '/a';
    expect(shouldReturnToOpenScreen(route: '/a', currentRoute: '/b', hasArguments: false, isOpen: open), isTrue);
    expect(shouldReturnToOpenScreen(route: '/a', currentRoute: '/a', hasArguments: false, isOpen: open), isFalse);
    expect(shouldReturnToOpenScreen(route: '/a', currentRoute: '/b', hasArguments: true, isOpen: open), isFalse);
    expect(shouldReturnToOpenScreen(route: '/c', currentRoute: '/b', hasArguments: false, isOpen: open), isFalse);
  });

  testWidgets('ir y volver varias veces por el menú: la factura sigue respondiendo',
      (t) async {
    await start(t);
    for (var i = 0; i < 4; i++) {
      AppNav.offAllNamed(AppRoutes.products);
      await frames(t);
      AppNav.offAllNamed(AppRoutes.invoicesWithTabs);
      await frames(t);
    }
    expect(find.byType(InvoiceFormScreen), findsOneWidget);
    await frames(t, 40);
  });
}
