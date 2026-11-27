// ignore_for_file: must_call_super
// Entradas y salidas de stock A MANO solo para el ADMINISTRADOR (decisión del
// dueño, 2026-11-27). Antes de esto un gerente o cajero podía subir o bajar
// stock creando un movimiento manual (compra/venta sin factura detrás) o
// cargando "Inventario Inicial". Aquí: la regla, cada acceso y cada
// controlador, por rol (admin / gerente / usuario / sin usuario).
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/services/tenant_datetime_service.dart';
import 'package:baudex_desktop/app/data/local/sync_service.dart';
import 'package:baudex_desktop/app/shared/models/drawer_menu_item.dart';
import 'package:baudex_desktop/app/shared/utils/drawer_permission_filter.dart';
import 'package:baudex_desktop/features/auth/domain/entities/user.dart';
import 'package:baudex_desktop/features/categories/domain/usecases/get_categories_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/entities/inventory_movement.dart';
import 'package:baudex_desktop/features/inventory/domain/inventory_adjust_permission.dart';
import 'package:baudex_desktop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/calculate_fifo_consumption_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/cancel_inventory_movement_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/confirm_inventory_movement_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/create_inventory_movement_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_expired_products_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_inventory_balances_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_inventory_movement_by_id_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_inventory_movements_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_inventory_stats_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_low_stock_products_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_near_expiry_products_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_out_of_stock_products_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_warehouse_movements_usecase.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/inventory_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/inventory_movements_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/inventory_list_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/widgets/create_movement_dialog.dart';
import 'package:baudex_desktop/features/inventory/presentation/widgets/inventory_quick_actions.dart';
import 'package:baudex_desktop/features/products/domain/usecases/create_product_usecase.dart';
import 'package:baudex_desktop/features/products/domain/usecases/search_products_usecase.dart';
import 'package:baudex_desktop/features/products/presentation/controllers/initial_inventory_controller.dart';
import 'package:baudex_desktop/features/products/presentation/screens/initial_inventory_screen.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import '../../../helpers/session_role.dart';

class _CreateMovement extends Mock implements CreateInventoryMovementUseCase {}

class _GetMovements extends Mock implements GetInventoryMovementsUseCase {}

class _GetWarehouseMovements extends Mock
    implements GetWarehouseMovementsUseCase {}

class _GetMovementById extends Mock implements GetInventoryMovementByIdUseCase {}

class _Confirm extends Mock implements ConfirmInventoryMovementUseCase {}

class _Cancel extends Mock implements CancelInventoryMovementUseCase {}

class _Fifo extends Mock implements CalculateFifoConsumptionUseCase {}

class _Search extends Mock implements SearchProductsUseCase {}

class _Balances extends Mock implements GetInventoryBalancesUseCase {}

class _Stats extends Mock implements GetInventoryStatsUseCase {}

class _Low extends Mock implements GetLowStockProductsUseCase {}

class _Out extends Mock implements GetOutOfStockProductsUseCase {}

class _Expired extends Mock implements GetExpiredProductsUseCase {}

class _Near extends Mock implements GetNearExpiryProductsUseCase {}

class _CreateProduct extends Mock implements CreateProductUseCase {}

class _Categories extends Mock implements GetCategoriesUseCase {}

class _UiSync extends GetxService with Mock implements SyncService {
  @override
  Future<void> onInit() async {}
  @override
  bool get isOnline => true;
  @override
  int get permanentlyFailedCount => 0;
  @override
  SyncState get syncState => SyncState.idle;
  @override
  int get pendingOperationsCount => 0;
  @override
  DateTime? get lastSyncTime => DateTime(2026, 11, 27, 9);
}

class _MovC extends InventoryMovementsController {
  _MovC({
    required CreateInventoryMovementUseCase create,
    required ConfirmInventoryMovementUseCase confirm,
    required CancelInventoryMovementUseCase cancel,
  }) : super(
          getInventoryMovementsUseCase: _GetMovements(),
          getWarehouseMovementsUseCase: _GetWarehouseMovements(),
          createInventoryMovementUseCase: create,
          getInventoryMovementByIdUseCase: _GetMovementById(),
          confirmInventoryMovementUseCase: confirm,
          cancelInventoryMovementUseCase: cancel,
          calculateFifoConsumptionUseCase: _Fifo(),
          searchProductsUseCase: _Search(),
        );
  @override
  void onInit() {}
}

class _InvC extends InventoryController {
  _InvC()
      : super(
          getInventoryBalancesUseCase: _Balances(),
          getInventoryMovementsUseCase: _GetMovements(),
          getInventoryStatsUseCase: _Stats(),
          getLowStockProductsUseCase: _Low(),
          getOutOfStockProductsUseCase: _Out(),
          getExpiredProductsUseCase: _Expired(),
          getNearExpiryProductsUseCase: _Near(),
        );
  @override
  void onInit() {}
  @override
  void onReady() {}
}

const _roles = <UserRole?>[UserRole.admin, UserRole.manager, UserRole.user, null];

String _name(UserRole? r) => r?.name ?? 'sin usuario';

/// Deja pasar los avisos (snackbars) que quedan programados.
Future<void> _drain(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
    registerFallbackValue(
      CreateInventoryMovementParams(
        productId: 'x',
        type: InventoryMovementType.inbound,
        reason: InventoryMovementReason.adjustment,
        quantity: 1,
        unitCost: 0,
      ),
    );
  });

  setUp(() {
    Get.testMode = true;
    Get.put(TenantDateTimeService());
  });
  tearDown(Get.reset);

  // ─────────────────────────── REGLA ───────────────────────────
  group('regla canCreateManualMovement', () {
    test('solo el administrador; sin usuario tampoco', () {
      expect(canCreateManualMovement(UserRole.admin), isTrue);
      expect(canCreateManualMovement(UserRole.manager), isFalse);
      expect(canCreateManualMovement(UserRole.user), isFalse);
      expect(canCreateManualMovement(null), isFalse);
    });

    test('tipos ofrecidos: todos al administrador, ninguno a los demás', () {
      expect(movementTypesFor(UserRole.admin), InventoryMovementType.values);
      expect(movementTypesFor(UserRole.manager), isEmpty);
      expect(movementTypesFor(UserRole.user), isEmpty);
      expect(movementTypesFor(null), isEmpty);
    });
  });

  // ──────────────────── CONTROLADOR DE MOVIMIENTOS ────────────────────
  group('controlador de movimientos: crear, confirmar, cancelar', () {
    for (final role in _roles) {
      final allowed = role == UserRole.admin;
      for (final type in [
        InventoryMovementType.inbound,
        InventoryMovementType.outbound,
      ]) {
        testWidgets(
            'crear ${type.name} con ${_name(role)}: '
            '${allowed ? 'se envía' : 'no se envía nada'}', (tester) async {
          await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));
          putSessionRole(role);
          final create = _CreateMovement();
          when(() => create(any()))
              .thenAnswer((_) async => const Left(ServerFailure('prueba')));
          final c = _MovC(create: create, confirm: _Confirm(), cancel: _Cancel())
            ..selectedProductId.value = 'p1'
            ..selectedProductName.value = 'Gaseosa'
            ..quantity.value = 3
            ..selectedType.value = type;

          expect(c.ensureAllowedManualMovement(), allowed);
          await c.createMovement();
          await tester.pump(const Duration(seconds: 1));
          if (allowed) {
            verify(() => create(any())).called(1);
          } else {
            verifyNever(() => create(any()));
          }
          await _drain(tester);
        });
      }

      testWidgets(
          'confirmar y cancelar con ${_name(role)}: '
          '${allowed ? 'se envía' : 'no se envía nada'}', (tester) async {
        await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));
        putSessionRole(role);
        final confirm = _Confirm();
        final cancel = _Cancel();
        when(() => confirm(any()))
            .thenAnswer((_) async => const Left(ServerFailure('prueba')));
        when(() => cancel(any()))
            .thenAnswer((_) async => const Left(ServerFailure('prueba')));
        final c = _MovC(create: _CreateMovement(), confirm: confirm, cancel: cancel);

        await c.confirmMovement('m1');
        await c.cancelMovement('m1');
        await tester.pump(const Duration(seconds: 1));
        if (allowed) {
          verify(() => confirm('m1')).called(1);
          verify(() => cancel('m1')).called(1);
        } else {
          verifyNever(() => confirm(any()));
          verifyNever(() => cancel(any()));
        }
        await _drain(tester);
      });
    }
  });

  // ─────────────────────── DIÁLOGO NUEVO MOVIMIENTO ───────────────────────
  // Nota: el formulario del administrador no se monta aquí: ese diálogo no
  // lo abre ninguna pantalla hoy y su formulario ya fallaba antes de este
  // cambio (campo con `initialValue` y `controller` a la vez). Lo que se
  // prueba es que a los demás no les llegue.
  group('diálogo "Crear Movimiento"', () {
    for (final role in [UserRole.manager, UserRole.user, null]) {
      testWidgets(
          '${_name(role)}: ve el aviso, sin botón',
          (tester) async {
        tester.view.physicalSize = const Size(1440, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        putSessionRole(role);
        Get.put<InventoryMovementsController>(
          _MovC(create: _CreateMovement(), confirm: _Confirm(), cancel: _Cancel()),
        );
        await tester.pumpWidget(
          const GetMaterialApp(home: Scaffold(body: CreateMovementDialog())),
        );
        await tester.pump();

        expect(find.text('Crear Movimiento'), findsNothing);
        expect(find.byKey(const ValueKey('adjust-admin-only')), findsOneWidget);
        expect(find.text(kManualMovementAdminOnlyMessage), findsOneWidget);
      });
    }
  });

  // ─────────────────────── ACCIONES RÁPIDAS ───────────────────────
  group('acciones rápidas: "Nuevo Movimiento"', () {
    for (final size in [const Size(1440, 900), const Size(390, 844)]) {
      final label = size.width < 600 ? 'celular' : 'escritorio';
      for (final role in _roles) {
        final allowed = role == UserRole.admin;
        testWidgets('$label, ${_name(role)}: ${allowed ? 'se ve' : 'no se ve'}',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          putSessionRole(role);
          await tester.pumpWidget(
            const GetMaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(child: InventoryQuickActions()),
              ),
            ),
          );
          await tester.pump();
          expect(find.text('Nuevo Movimiento'), allowed ? findsOneWidget : findsNothing);
          // Consultar sigue para todos.
          expect(find.text('Ver Balances'), findsOneWidget);
        });
      }
    }
  });

  // ─────────────────────── LISTA DE INVENTARIO ───────────────────────
  group('lista de inventario: botón "Crear" y "Crear movimiento"', () {
    for (final role in _roles) {
      final allowed = role == UserRole.admin;
      testWidgets('${_name(role)}: ${allowed ? 'se ven' : 'no se ven'}',
          (tester) async {
        final previous = FlutterError.onError;
        FlutterError.onError = (d) {
          if (d.exceptionAsString().contains('overflowed')) return;
          previous?.call(d);
        };
        addTearDown(() => FlutterError.onError = previous);
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        putSessionRole(role);
        Get.put<SyncService>(_UiSync());
        Get.put<InventoryController>(_InvC());
        await tester.pumpWidget(const GetMaterialApp(home: InventoryListScreen()));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byTooltip('Crear'), allowed ? findsOneWidget : findsNothing);
        // Lista vacía: el botón de crear movimiento solo al administrador.
        expect(
          find.text('Crear movimiento'),
          allowed ? findsOneWidget : findsNothing,
        );
        if (allowed) {
          await tester.tap(find.byTooltip('Crear'));
          await tester.pumpAndSettle();
          expect(find.text('Movimiento'), findsOneWidget);
          expect(find.text('Ajuste'), findsOneWidget);
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      });
    }
  });

  // ─────────────────────── INVENTARIO INICIAL ───────────────────────
  group('Inventario Inicial (carga stock a mano)', () {
    for (final role in _roles) {
      final allowed = role == UserRole.admin;
      testWidgets(
          'controlador con ${_name(role)}: '
          '${allowed ? 'permite' : 'se niega sin crear nada'}', (tester) async {
        await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));
        putSessionRole(role);
        final product = _CreateProduct();
        final movement = _CreateMovement();
        final c = InitialInventoryController(
          createProductUseCase: product,
          getCategoriesUseCase: _Categories(),
          createMovementUseCase: movement,
        );
        expect(c.ensureAllowedToLoadStock(), allowed);
        if (!allowed) {
          await c.submitAll();
          verifyZeroInteractions(product);
          verifyZeroInteractions(movement);
        }
        await _drain(tester);
      });
    }

    for (final role in [UserRole.manager, UserRole.user, null]) {
      testWidgets('pantalla con ${_name(role)}: aviso en lugar del formulario',
          (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        putSessionRole(role);
        Get.put<SyncService>(_UiSync());
        await tester.pumpWidget(
          const GetMaterialApp(home: InitialInventoryScreen()),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byKey(const ValueKey('adjust-admin-only')), findsOneWidget);
        expect(find.text(kManualMovementAdminOnlyMessage), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      });
    }

    const menu = [
      DrawerMenuItem(
        id: 'inventory_group',
        title: 'Inventario',
        icon: Icons.inventory_rounded,
        submenu: [
          DrawerMenuItem(id: 'products', title: 'Productos', icon: Icons.inventory_2, route: '/products'),
          DrawerMenuItem(id: 'initial_inventory', title: 'Inventario Inicial', icon: Icons.playlist_add, route: '/products/initial-inventory'),
          DrawerMenuItem(id: 'inventory', title: 'Gestión de Inventario', icon: Icons.warehouse, route: '/inventory'),
        ],
      ),
    ];

    for (final role in _roles) {
      final allowed = role == UserRole.admin;
      test('menú con ${_name(role)}: "Inventario Inicial" ${allowed ? 'se ve' : 'no se ve'}', () {
        putSessionRole(role);
        final ids = DrawerPermissionFilter.apply(menu)
            .single
            .submenu!
            .map((i) => i.id)
            .toList();
        expect(ids.contains('initial_inventory'), allowed);
        // Lo demás del grupo sigue igual.
        expect(ids, containsAll(['products', 'inventory']));
      });
    }
  });
}
