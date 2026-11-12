import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/features/dashboard/data/datasources/dashboard_local_datasource.dart';
import 'package:baudex_desktop/features/dashboard/data/models/dashboard_stats_model.dart';
import 'package:baudex_desktop/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:baudex_desktop/features/dashboard/domain/entities/recent_activity_advanced.dart';
import 'package:baudex_desktop/features/dashboard/domain/entities/smart_notification.dart';
import 'package:baudex_desktop/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_notifications_usecase.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_profitability_stats_usecase.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_recent_activity_usecase.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_unread_notifications_count_usecase.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/mark_notification_as_read_usecase.dart';
import 'package:baudex_desktop/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../fixtures/dashboard_fixtures.dart';

DashboardStatsModel statsWith({
  required double collected,
  required double billed,
  required double expenses,
  double creditNotes = 0,
}) =>
    DashboardStatsModel(
      sales: DashboardFixtures.createSalesStatsModel(totalAmount: billed),
      invoices: DashboardFixtures.createInvoiceStatsModel(),
      products: DashboardFixtures.createProductStatsModel(),
      customers: DashboardFixtures.createCustomerStatsModel(),
      expenses: DashboardFixtures.createExpenseStatsModel(
          totalAmount: expenses, expensesByCategory: const {}),
      profitability: DashboardFixtures.createProfitabilityStatsModel(),
      paymentMethodsBreakdown: const [],
      incomeTypeBreakdown: const IncomeTypeBreakdown(
          invoices: 0, newInvoices: 0, paymentsOnOldInvoices: 0, credits: 0, total: 0),
      totalCollected: collected,
      totalBilled: billed,
      creditNotesTotal: creditNotes,
      creditNotesCount: creditNotes > 0 ? 1 : 0,
      netRevenue: collected - creditNotes,
    );

class _Repo extends Fake implements DashboardRepository {
  Either<Failure, DashboardStats>? answer;
  int calls = 0;

  @override
  Future<Either<Failure, DashboardStats>> getDashboardStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    calls++;
    return answer!;
  }
}

class _Local extends Fake implements DashboardLocalDataSource {
  DashboardStatsModel? stats;

  @override
  Future<DashboardStatsModel?> getCachedDashboardStats(
          {DateTime? startDate, DateTime? endDate}) async =>
      stats;

  @override
  Future<List<RecentActivityAdvanced>> getOfflineRecentActivities(
          {int limit = 10}) async =>
      const [];

  @override
  Future<List<SmartNotification>> getOfflineSmartNotifications(
          {int limit = 10}) async =>
      const [];
}

/// Sin conexión: el tablero solo tiene el cálculo del equipo.
class _Offline extends Fake implements NetworkInfo {
  @override
  bool get isServerReachable => false;

  @override
  Future<bool> get isConnected async => false;
}

/// Mezcla servidor/local: con respuesta del servidor se muestran sus cifras
/// completas; lo local solo sin respuesta o con cambios por subir.
void main() {
  late _Repo repo;
  late _Local local;
  late DashboardController controller;

  // El equipo calcula MÁS que el servidor en todo (antes eso hacía que
  // "ganara" el equipo y se descartara la respuesta del servidor).
  final localStats =
      statsWith(collected: 500, billed: 900, expenses: 70, creditNotes: 30);
  final serverStats =
      statsWith(collected: 100, billed: 400, expenses: 7, creditNotes: 3);

  setUp(() async {
    Get.testMode = true;
    repo = _Repo();
    local = _Local()..stats = localStats;
    Get.put<DashboardLocalDataSource>(local);
    Get.put<NetworkInfo>(_Offline());
    controller = DashboardController(
      getDashboardStatsUseCase: GetDashboardStatsUseCase(repo),
      getRecentActivityUseCase: GetRecentActivityUseCase(repo),
      getNotificationsUseCase: GetDashboardNotificationsUseCase(repo),
      markNotificationAsReadUseCase: MarkDashboardNotificationAsReadUseCase(repo),
      getUnreadNotificationsCountUseCase: GetUnreadNotificationsCountUseCase(repo),
      getProfitabilityStatsUseCase: GetProfitabilityStatsUseCase(repo),
    );
    controller.pendingSyncOperations = () => 0;
    // Primer paso de toda carga: el cálculo del equipo.
    await controller.refreshAll();
    expect(controller.totalCollected, 500);
  });

  tearDown(Get.reset);

  test('con respuesta del servidor se muestran sus cifras completas', () async {
    repo.answer = Right(serverStats);
    await controller.loadDashboardStats();

    expect(controller.totalCollected, 100);
    expect(controller.totalBilled, 400);
    expect(controller.totalExpenses, 7);
    expect(controller.creditNotesTotal, 3);
    expect(controller.netRevenue, 97);
    expect(controller.dashboardStats, same(serverStats));
  });

  test('sin respuesta del servidor queda el cálculo del equipo', () async {
    repo.answer = const Left(ServerFailure('caído'));
    await controller.loadDashboardStats();

    expect(controller.dashboardStats, same(localStats));
    expect(controller.statsError, isNotNull);
  });

  test('con cambios por subir no se consulta al servidor', () async {
    controller.pendingSyncOperations = () => 2;
    repo.answer = Right(serverStats);
    await controller.loadDashboardStats();

    expect(repo.calls, 0);
    expect(controller.dashboardStats, same(localStats));
  });

  test('si no se cobró nada muestra 0, no lo facturado', () async {
    repo.answer = Right(statsWith(collected: 0, billed: 400, expenses: 0));
    await controller.loadDashboardStats();

    expect(controller.totalRevenue, 400);
    expect(controller.totalCollected, 0);
    expect(controller.totalBilled, 400);
  });
}
