// Imágenes reales de las pantallas tocadas en la rama de estrés:
//   BAUDEX_VISUAL_OUT=/ruta flutter test test/visual/estres_screens_visual_test.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/models/pagination_meta.dart';
import 'package:baudex_desktop/features/credit_notes/domain/entities/credit_note.dart';
import 'package:baudex_desktop/features/credit_notes/domain/repositories/credit_note_repository.dart';
import 'package:baudex_desktop/features/credit_notes/domain/usecases/cancel_credit_note.dart';
import 'package:baudex_desktop/features/credit_notes/domain/usecases/confirm_credit_note.dart';
import 'package:baudex_desktop/features/credit_notes/domain/usecases/delete_credit_note.dart';
import 'package:baudex_desktop/features/credit_notes/domain/usecases/download_credit_note_pdf.dart';
import 'package:baudex_desktop/features/credit_notes/domain/usecases/get_credit_notes.dart';
import 'package:baudex_desktop/features/credit_notes/presentation/controllers/credit_note_list_controller.dart';
import 'package:baudex_desktop/features/credit_notes/presentation/screens/credit_note_list_screen.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_warehouses_usecase.dart';
import 'package:baudex_desktop/features/purchase_orders/domain/usecases/approve_purchase_order_usecase.dart';
import 'package:baudex_desktop/features/purchase_orders/domain/usecases/cancel_purchase_order_usecase.dart';
import 'package:baudex_desktop/features/purchase_orders/domain/usecases/delete_purchase_order_usecase.dart';
import 'package:baudex_desktop/features/purchase_orders/domain/usecases/get_purchase_order_by_id_usecase.dart';
import 'package:baudex_desktop/features/purchase_orders/domain/usecases/receive_purchase_order_and_update_inventory_usecase.dart';
import 'package:baudex_desktop/features/purchase_orders/domain/usecases/send_purchase_order_usecase.dart';
import 'package:baudex_desktop/features/purchase_orders/domain/usecases/update_purchase_order_usecase.dart';
import 'package:baudex_desktop/features/purchase_orders/presentation/controllers/purchase_order_detail_controller.dart';
import 'package:baudex_desktop/features/purchase_orders/presentation/screens/futuristic_purchase_order_detail_screen.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures/credit_note_fixtures.dart';
import '../helpers/fake_sync_service.dart';
import 'package:baudex_desktop/app/data/local/sync_service.dart';

final _out = Platform.environment['BAUDEX_VISUAL_OUT'];
const _fonts = '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts';

class _Get extends Mock implements GetCreditNotes {}
class _Confirm extends Mock implements ConfirmCreditNote {}
class _FakeQuery extends Fake implements QueryCreditNotesParams {}
class _GetById extends Mock implements GetPurchaseOrderByIdUseCase {}

void main() {
  if (_out == null) {
    test('imágenes de estrés (omitida: falta BAUDEX_VISUAL_OUT)', () {}, skip: 'Solo para revisión visual');
    return;
  }
  final boundaryKey = GlobalKey();

  setUpAll(() async {
    registerFallbackValue(_FakeQuery());
    await initializeDateFormatting('es');
    await initializeDateFormatting('es_CO');
    Future<void> load(String family, List<String> files) async {
      final loader = FontLoader(family);
      for (final file in files) {
        final bytes = File('$_fonts/$file').readAsBytesSync();
        loader.addFont(Future.value(ByteData.view(bytes.buffer)));
      }
      await loader.load();
    }

    await load('Roboto', ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf', 'Roboto-Black.ttf']);
    await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
  });
  setUp(() {
    Get.testMode = true;
    Get.put<SyncService>(FakeSyncService());
  });
  tearDown(Get.reset);

  Widget app(Widget home) => RepaintBoundary(
        key: boundaryKey,
        child: GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto', useMaterial3: true),
          home: home,
        ),
      );

  Future<void> shot(WidgetTester t, String name) async {
    await t.runAsync(() async {
      final b = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await b.toImage(pixelRatio: 1.5);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_out/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(data!.buffer.asUint8List());
    });
  }

  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets('notas crédito: confirmando una nota', (t) async {
    t.view.physicalSize = const Size(1280, 760);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final getNotes = _Get();
    final confirm = _Confirm();
    final notes = [
      CreditNoteFixtures.createDraftCreditNote(id: 'n1'),
      CreditNoteFixtures.createConfirmedCreditNote(id: 'n2'),
    ];
    when(() => getNotes(any())).thenAnswer((_) async => Right(PaginatedResult(
          data: notes,
          meta: const PaginationMeta(page: 1, limit: 20, totalItems: 2, totalPages: 1,
              hasNextPage: false, hasPreviousPage: false),
        )));
    final pending = Completer<Either<Failure, CreditNote>>();
    when(() => confirm('n1')).thenAnswer((_) => pending.future);
    final controller = Get.put(CreditNoteListController(
      getCreditNotesUseCase: getNotes,
      deleteCreditNoteUseCase: DeleteCreditNote(_Repo()),
      confirmCreditNoteUseCase: confirm,
      cancelCreditNoteUseCase: CancelCreditNote(_Repo()),
      downloadCreditNotePdfUseCase: DownloadCreditNotePdf(_Repo()),
    ));
    await t.pumpWidget(app(const CreditNoteListScreen()));
    await settle(t);
    await shot(t, 'notas-credito-lista');
    unawaited(controller.confirmCreditNote('n1'));
    await settle(t);
    await shot(t, 'notas-credito-confirmando');
    pending.complete(Right(CreditNoteFixtures.createConfirmedCreditNote(id: 'n1')));
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 500));
    }
  });

  testWidgets('orden de compra: no se pudo cargar (con botón de volver)', (t) async {
    t.view.physicalSize = const Size(1280, 760);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final getById = _GetById();
    when(() => getById(any())).thenAnswer((_) async => const Left(ServerFailure('No se pudo conectar con el servidor')));
    final c = PurchaseOrderDetailController(
      getPurchaseOrderByIdUseCase: getById,
      deletePurchaseOrderUseCase: _Del(),
      updatePurchaseOrderUseCase: _Upd(),
      approvePurchaseOrderUseCase: _App(),
      sendPurchaseOrderUseCase: _Snd(),
      receivePurchaseOrderAndUpdateInventoryUseCase: _Rcv(),
      cancelPurchaseOrderUseCase: _Cnl(),
      getWarehousesUseCase: _Wh(),
      resolveTempId: (_) async => null,
    );
    c.purchaseOrderId.value = '9605083f-19ff-4acc-ad1d-5a323518ab6e';
    Get.put(c);
    await c.loadPurchaseOrder();
    await t.pumpWidget(app(const FuturisticPurchaseOrderDetailScreen()));
    await settle(t);
    await shot(t, 'orden-compra-error');
  });
}

class _Repo extends Mock implements CreditNoteRepository {}

class _Del extends Mock implements DeletePurchaseOrderUseCase {}
class _Upd extends Mock implements UpdatePurchaseOrderUseCase {}
class _App extends Mock implements ApprovePurchaseOrderUseCase {}
class _Snd extends Mock implements SendPurchaseOrderUseCase {}
class _Rcv extends Mock implements ReceivePurchaseOrderAndUpdateInventoryUseCase {}
class _Cnl extends Mock implements CancelPurchaseOrderUseCase {}
class _Wh extends Mock implements GetWarehousesUseCase {}
