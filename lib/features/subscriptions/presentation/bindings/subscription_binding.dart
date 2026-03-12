// lib/features/subscriptions/presentation/bindings/subscription_binding.dart

import 'package:get/get.dart';

import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../data/datasources/subscription_remote_datasource.dart';
import '../../data/datasources/subscription_local_datasource.dart';
import '../../data/repositories/subscription_repository_impl.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../controllers/subscription_controller.dart';

class SubscriptionBinding extends Bindings {
  @override
  void dependencies() {
    // Remote DataSource
    Get.lazyPut<SubscriptionRemoteDataSource>(
      () => SubscriptionRemoteDataSourceImpl(
        dioClient: Get.find<DioClient>(),
      ),
      fenix: true,
    );

    // Local DataSource
    Get.lazyPut<SubscriptionLocalDataSource>(
      () => SubscriptionLocalDataSourceImpl(
        database: IsarDatabase.instance,
      ),
      fenix: true,
    );

    // Repository
    Get.lazyPut<SubscriptionRepository>(
      () => SubscriptionRepositoryImpl(
        remoteDataSource: Get.find<SubscriptionRemoteDataSource>(),
        localDataSource: Get.find<SubscriptionLocalDataSource>(),
        networkInfo: Get.find<NetworkInfo>(),
      ),
      fenix: true,
    );

    // Controller
    Get.lazyPut<SubscriptionController>(
      () => SubscriptionController(
        repository: Get.find<SubscriptionRepository>(),
        networkInfo: Get.find<NetworkInfo>(),
      ),
      fenix: true,
    );
  }
}

/// Binding para inicializar suscripciones de forma permanente
/// Usar en AppBinding para que el controller siempre este disponible
class SubscriptionPermanentBinding {
  static void init() {
    // Remote DataSource
    if (!Get.isRegistered<SubscriptionRemoteDataSource>()) {
      Get.put<SubscriptionRemoteDataSource>(
        SubscriptionRemoteDataSourceImpl(
          dioClient: Get.find<DioClient>(),
        ),
        permanent: true,
      );
    }

    // Local DataSource
    if (!Get.isRegistered<SubscriptionLocalDataSource>()) {
      Get.put<SubscriptionLocalDataSource>(
        SubscriptionLocalDataSourceImpl(
          database: IsarDatabase.instance,
        ),
        permanent: true,
      );
    }

    // Repository
    if (!Get.isRegistered<SubscriptionRepository>()) {
      Get.put<SubscriptionRepository>(
        SubscriptionRepositoryImpl(
          remoteDataSource: Get.find<SubscriptionRemoteDataSource>(),
          localDataSource: Get.find<SubscriptionLocalDataSource>(),
          networkInfo: Get.find<NetworkInfo>(),
        ),
        permanent: true,
      );
    }

    // Controller (permanente para estar siempre disponible)
    if (!Get.isRegistered<SubscriptionController>()) {
      Get.put<SubscriptionController>(
        SubscriptionController(
          repository: Get.find<SubscriptionRepository>(),
          networkInfo: Get.find<NetworkInfo>(),
        ),
        permanent: true,
      );
    }
  }
}
