// lib/features/cash_register/presentation/bindings/cash_register_binding.dart
import 'package:get/get.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/network/network_info.dart';
import '../../data/datasources/cash_register_remote_datasource.dart';
import '../../data/repositories/cash_register_repository_impl.dart';
import '../../domain/repositories/cash_register_repository.dart';
import '../controllers/cash_register_controller.dart';

class CashRegisterBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CashRegisterRemoteDataSource>()) {
      Get.lazyPut<CashRegisterRemoteDataSource>(
        () => CashRegisterRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
      );
    }
    if (!Get.isRegistered<CashRegisterRepository>()) {
      Get.lazyPut<CashRegisterRepository>(
        () => CashRegisterRepositoryImpl(
          remoteDataSource: Get.find<CashRegisterRemoteDataSource>(),
          networkInfo: Get.find<NetworkInfo>(),
        ),
      );
    }
    Get.lazyPut<CashRegisterController>(
      () => CashRegisterController(
        repository: Get.find<CashRegisterRepository>(),
      ),
    );
  }
}
