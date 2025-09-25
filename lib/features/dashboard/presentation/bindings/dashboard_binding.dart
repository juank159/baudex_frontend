// lib/features/dashboard/presentation/bindings/dashboard_binding.dart
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_notifications_usecase.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_recent_activity_usecase.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_unread_notifications_count_usecase.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/mark_notification_as_read_usecase.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_profitability_stats_usecase.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/datasources/dashboard_local_datasource.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/storage/secure_storage_service.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // Data sources - mantener en memoria
    Get.lazyPut<DashboardRemoteDataSource>(
      () => DashboardRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
      fenix: true,
    );

    Get.lazyPut<DashboardLocalDataSource>(
      () => DashboardLocalDataSourceImpl(
        secureStorage: Get.find<SecureStorageService>(),
      ),
      fenix: true,
    );

    // Repository - mantener en memoria
    Get.lazyPut<DashboardRepository>(
      () => DashboardRepositoryImpl(
        remoteDataSource: Get.find<DashboardRemoteDataSource>(),
        localDataSource: Get.find<DashboardLocalDataSource>(),
        networkInfo: Get.find<NetworkInfo>(),
      ),
      fenix: true,
    );

    // Use cases - mantener en memoria
    Get.lazyPut(
      () => GetDashboardStatsUseCase(Get.find<DashboardRepository>()),
      fenix: true,
    );

    Get.lazyPut(
      () => GetRecentActivityUseCase(Get.find<DashboardRepository>()),
      fenix: true,
    );

    Get.lazyPut(
      () => GetNotificationsUseCase(Get.find<DashboardRepository>()),
      fenix: true,
    );

    Get.lazyPut(
      () => MarkNotificationAsReadUseCase(Get.find<DashboardRepository>()),
      fenix: true,
    );

    Get.lazyPut(
      () => GetUnreadNotificationsCountUseCase(Get.find<DashboardRepository>()),
      fenix: true,
    );

    Get.lazyPut(
      () => GetProfitabilityStatsUseCase(Get.find<DashboardRepository>()),
      fenix: true,
    );

    // Controller - mantener instancia persistente
    Get.lazyPut(
      () => DashboardController(
        getDashboardStatsUseCase: Get.find<GetDashboardStatsUseCase>(),
        getRecentActivityUseCase: Get.find<GetRecentActivityUseCase>(),
        getNotificationsUseCase: Get.find<GetNotificationsUseCase>(),
        markNotificationAsReadUseCase:
            Get.find<MarkNotificationAsReadUseCase>(),
        getUnreadNotificationsCountUseCase:
            Get.find<GetUnreadNotificationsCountUseCase>(),
        getProfitabilityStatsUseCase: Get.find<GetProfitabilityStatsUseCase>(),
      ),
      fenix: true, // ✅ CLAVE: Mantener instancia en memoria incluso después de eliminar
    );
  }
}
