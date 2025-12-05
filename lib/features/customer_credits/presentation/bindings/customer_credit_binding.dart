// lib/features/customer_credits/presentation/bindings/customer_credit_binding.dart

import 'package:get/get.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../customers/data/datasources/customer_remote_datasource.dart';
import '../../data/datasources/customer_credit_remote_datasource.dart';
import '../../data/repositories/customer_credit_repository_impl.dart';
import '../controllers/customer_credit_controller.dart';

/// Binding para inyección de dependencias de créditos
class CustomerCreditBinding extends Bindings {
  @override
  void dependencies() {
    // Customer Datasource (para búsqueda de clientes en crear crédito)
    if (!Get.isRegistered<CustomerRemoteDataSource>()) {
      Get.lazyPut<CustomerRemoteDataSource>(
        () => CustomerRemoteDataSourceImpl(
          dioClient: Get.find<DioClient>(),
        ),
        fenix: true,
      );
    }

    // Datasource - fenix: true para que se recree si fue eliminado
    Get.lazyPut<CustomerCreditRemoteDataSource>(
      () => CustomerCreditRemoteDataSourceImpl(
        dioClient: Get.find<DioClient>(),
      ),
      fenix: true,
    );

    // Repository - fenix: true para que se recree si fue eliminado
    Get.lazyPut<CustomerCreditRepository>(
      () => CustomerCreditRepositoryImpl(
        remoteDataSource: Get.find<CustomerCreditRemoteDataSource>(),
        networkInfo: Get.find<NetworkInfo>(),
      ),
      fenix: true,
    );

    // Controller - fenix: true para que se recree automáticamente
    // Esto garantiza que siempre haya un controller disponible
    Get.lazyPut<CustomerCreditController>(
      () => CustomerCreditController(
        repository: Get.find<CustomerCreditRepository>(),
      ),
      fenix: true,
    );
  }
}
