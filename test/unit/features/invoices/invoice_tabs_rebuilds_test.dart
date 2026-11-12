import 'package:baudex_desktop/app/core/services/tenant_datetime_service.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/create_invoice_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/get_invoice_by_id_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/update_invoice_usecase.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/invoice_tabs_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tzdata;

class _Create extends Mock implements CreateInvoiceUseCase {}

class _Update extends Mock implements UpdateInvoiceUseCase {}

class _GetById extends Mock implements GetInvoiceByIdUseCase {}

/// Rendimiento de las pestañas de factura: toda la pantalla (barra, menú y
/// formulario) se redibuja cada vez que cambia la lista de pestañas. Cambiar
/// de pestaña NO debe tocar esa lista, y renombrar debe avisar una sola vez.
void main() {
  late InvoiceTabsController tabs;
  late int listChanges;

  Future<void> settle(WidgetTester tester) async {
    // Las cargas diferidas de cada pestaña (cliente por defecto, avisos).
    // Cada una se programa tras un cuadro y luego espera con temporizadores,
    // así que hay que avanzar varios cuadros.
    for (var i = 0; i < 8; i++) {
      tester.binding.scheduleFrame();
      await tester.pump(const Duration(seconds: 3));
    }
  }

  setUpAll(tzdata.initializeTimeZones);

  setUp(() {
    Get.testMode = true;
    Get.put<TenantDateTimeService>(TenantDateTimeService());
    Get.put<CreateInvoiceUseCase>(_Create());
    Get.put<UpdateInvoiceUseCase>(_Update());
    Get.put<GetInvoiceByIdUseCase>(_GetById());
  });

  tearDown(Get.reset);

  Future<void> open(WidgetTester tester, int count) async {
    tabs = Get.put(InvoiceTabsController());
    for (var i = 1; i < count; i++) {
      tabs.addNewTab();
    }
    expect(tabs.tabs.map((t) => t.id).toSet().length, count,
        reason: 'cada pestaña necesita su propio identificador');
    await settle(tester);
    listChanges = 0;
    (tabs.tabs as RxList<InvoiceTab>).listen((_) => listChanges++);
  }

  testWidgets('cambiar de pestaña no redibuja toda la pantalla', (tester) async {
    await open(tester, 4);

    for (final index in [0, 2, 1, 3, 0]) {
      tabs.switchToTab(index);
      await tester.pump();
      expect(tabs.currentTabIndex, index);
    }

    expect(listChanges, 0);
    await settle(tester);
  });

  testWidgets('cambiar de pestaña sigue registrando la última actividad', (tester) async {
    await open(tester, 2);
    final before = DateTime(2000);
    tabs.tabs[0].lastActivity = before;

    tabs.switchToTab(0);

    expect(tabs.tabs[0].lastActivity.isAfter(before), isTrue);
    await settle(tester);
  });

  testWidgets('renombrar una pestaña avisa una sola vez, y nada si el título no cambia', (tester) async {
    await open(tester, 2);
    final id = tabs.tabs[1].id;

    tabs.updateTabTitle(id, 'Mesa 4');
    await tester.pump();
    expect(tabs.tabs[1].title, 'Mesa 4');
    expect(listChanges, 1);

    tabs.updateTabTitle(id, 'Mesa 4');
    await tester.pump();
    expect(listChanges, 1);
    await settle(tester);
  });

  testWidgets('abrir una pestaña avisa una sola vez', (tester) async {
    await open(tester, 1);

    tabs.addNewTab();
    await tester.pump();

    expect(tabs.tabs.length, 2);
    expect(listChanges, 1);
    await settle(tester);
  });
}
