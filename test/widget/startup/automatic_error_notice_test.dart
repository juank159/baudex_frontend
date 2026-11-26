// El aviso "Error del servidor" al entrar / al pasar a facturar.
//
// Las cargas automáticas (negocio al iniciar sesión, clientes la primera
// vez que se abre crear factura) fallan contra un servidor que responde
// error: NO debe salir ningún aviso en pantalla; queda en Diagnóstico.
// Lo que el usuario pide (refrescar, buscar) SÍ avisa.
import 'package:baudex_desktop/app/core/errors/automatic_work.dart';
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:baudex_desktop/features/auth/presentation/controllers/auth_controller.dart';
import 'package:baudex_desktop/features/customers/domain/usecases/delete_customer_usecase.dart';
import 'package:baudex_desktop/features/customers/domain/usecases/get_customers_usecase.dart';
import 'package:baudex_desktop/features/customers/domain/usecases/search_customers_usecase.dart';
import 'package:baudex_desktop/features/customers/presentation/controllers/customers_controller.dart';
import 'package:baudex_desktop/features/settings/domain/entities/organization.dart';
import 'package:baudex_desktop/features/settings/domain/repositories/organization_repository.dart';
import 'package:baudex_desktop/features/settings/domain/usecases/get_user_preferences_usecase.dart';
import 'package:baudex_desktop/features/settings/domain/usecases/update_user_preferences_usecase.dart';
import 'package:baudex_desktop/features/settings/presentation/controllers/organization_controller.dart';
import 'package:baudex_desktop/features/settings/presentation/controllers/user_preferences_controller.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _Auth extends Mock implements AuthController {
  @override
  InternalFinalCallback<void> get onStart =>
      InternalFinalCallback(callback: () {});
  @override
  InternalFinalCallback<void> get onDelete =>
      InternalFinalCallback(callback: () {});
}

/// El servidor rechaza la consulta del negocio.
class _FailingOrganizationRepository implements OrganizationRepository {
  int calls = 0;
  @override
  Future<Either<Failure, Organization>> getCurrentOrganization() async {
    calls++;
    return const Left(ServerFailure('Error interno del servidor: boom', code: 500));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GetCustomers extends Mock implements GetCustomersUseCase {}

class _DeleteCustomer extends Mock implements DeleteCustomerUseCase {}

class _SearchCustomers extends Mock implements SearchCustomersUseCase {}

class _GetPreferences extends Mock implements GetUserPreferencesUseCase {}

class _UpdatePreferences extends Mock implements UpdateUserPreferencesUseCase {}

void main() {
  late _Auth auth;
  late RxBool authenticated;

  setUpAll(() {
    registerFallbackValue(const GetCustomersParams());
    registerFallbackValue(const SearchCustomersParams(searchTerm: 'x'));
    registerFallbackValue(NoParams());
  });

  setUp(() {
    Get.testMode = true;
    BackgroundFailureLog.instance.clear();
    auth = _Auth();
    authenticated = true.obs;
    when(() => auth.isAuthenticated).thenAnswer((_) => authenticated.value);
    when(() => auth.isAuthenticatedRx).thenReturn(authenticated);
    Get.put<AuthController>(auth);
  });

  tearDown(Get.reset);

  Future<void> app(WidgetTester tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: Text('Baudex'))));
  }

  Future<void> dismiss(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 8));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('negocio: al entrar, sin el negocio en el equipo y con el '
      'servidor rechazando, NO sale "Error del servidor"; queda anotado',
      (tester) async {
    await app(tester);
    final repo = _FailingOrganizationRepository();
    final controller = Get.put(OrganizationController(repo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(repo.calls, 1);
    expect(Get.isSnackbarOpen, isFalse);
    expect(find.textContaining('Error del servidor'), findsNothing);
    final log = BackgroundFailureLog.instance;
    expect(log.silencedNotices, 1);
    expect(log.entries.single.source, 'negocio: recarga automática');
    expect(log.entries.single.message,
        contains('Error del servidor. Intente nuevamente.'));
    expect(controller.error, isNotNull, reason: 'el estado de error se conserva');

    // Varias pantallas la piden al entrar: no se repite la consulta.
    for (var i = 0; i < 5; i++) {
      await controller.loadCurrentOrganization();
    }
    await tester.pump(const Duration(milliseconds: 100));
    expect(repo.calls, 1, reason: 'una sola consulta por entrada');

    // El botón de refrescar SÍ avisa (lo pidió el usuario).
    await controller.forceRefreshFromServer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(repo.calls, 2);
    expect(find.text('Error del servidor. Intente nuevamente.'), findsOneWidget);
    await dismiss(tester);
    await Get.delete<OrganizationController>(force: true);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('clientes: la primera vez que se abre crear factura la lista '
      'falla → sin aviso; una búsqueda del usuario que falla → con aviso',
      (tester) async {
    await app(tester);
    final getCustomers = _GetCustomers();
    final search = _SearchCustomers();
    when(() => getCustomers(any())).thenAnswer((_) async =>
        const Left(ServerFailure('Error interno del servidor: boom', code: 500)));
    when(() => search(any())).thenAnswer((_) async =>
        const Left(ServerFailure('Error interno del servidor: boom', code: 500)));
    final controller = Get.put(CustomersController(
      getCustomersUseCase: getCustomers,
      deleteCustomerUseCase: _DeleteCustomer(),
      searchCustomersUseCase: search,
    ));
    await tester.pump(); // onReady
    await tester.pump(const Duration(milliseconds: 100));

    verify(() => getCustomers(any())).called(1);
    expect(Get.isSnackbarOpen, isFalse);
    expect(find.textContaining('Error al cargar clientes'), findsNothing);
    expect(BackgroundFailureLog.instance.entries.single.line,
        allOf(contains('clientes: carga al abrir'),
            contains('Error al cargar clientes'),
            contains('Error interno del servidor')));

    await controller.searchCustomers('juan');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Error en búsqueda'), findsOneWidget);
    await dismiss(tester);
  });

  testWidgets('preferencias: sin sesión no se le pregunta al servidor; al '
      'entrar se piden una sola vez aunque las pidan varios', (tester) async {
    authenticated.value = false;
    await app(tester);
    final getPreferences = _GetPreferences();
    var calls = 0;
    when(() => getPreferences(any())).thenAnswer((_) async {
      calls++;
      return const Left(ServerFailure('No autorizado', code: 401));
    });
    final controller = Get.put(UserPreferencesController(
      getUserPreferencesUseCase: getPreferences,
      updateUserPreferencesUseCase: _UpdatePreferences(),
    ));
    await tester.pump(const Duration(seconds: 2));
    expect(calls, 0, reason: 'en la pantalla de inicio de sesión: nada');

    authenticated.value = true; // inició sesión
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await controller.onSyncCompleted(); // cada sincronización las pedía
    }
    await tester.pump(const Duration(milliseconds: 100));
    expect(calls, 1);
    expect(controller.skippedLoads, 4);
    expect(Get.isSnackbarOpen, isFalse);
  });
}
