// lib/features/bank_accounts/presentation/bindings/bank_account_movements_binding.dart
import 'package:get/get.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/network/network_info.dart';
import '../../data/datasources/bank_account_remote_datasource.dart';
import '../../data/repositories/bank_account_repository_impl.dart';
import '../../domain/repositories/bank_account_repository.dart';
import '../controllers/bank_account_movements_controller.dart';

/// Binding para la pantalla de movimientos de cuentas bancarias
class BankAccountMovementsBinding extends Bindings {
  @override
  void dependencies() {
    // Datasource - verificar si ya está registrado (puede venir de InitialBinding)
    if (!Get.isRegistered<BankAccountRemoteDataSource>()) {
      Get.lazyPut<BankAccountRemoteDataSource>(
        () => BankAccountRemoteDataSourceImpl(
          dioClient: Get.find<DioClient>(),
        ),
      );
    }

    // Repository - verificar si ya está registrado (puede venir de InitialBinding)
    if (!Get.isRegistered<BankAccountRepository>()) {
      Get.lazyPut<BankAccountRepository>(
        () => BankAccountRepositoryImpl(
          remoteDataSource: Get.find<BankAccountRemoteDataSource>(),
          networkInfo: Get.find<NetworkInfo>(),
        ),
      );
    }

    // Controller - siempre crear nuevo para la pantalla
    Get.lazyPut<BankAccountMovementsController>(
      () => BankAccountMovementsController(
        repository: Get.find<BankAccountRepository>(),
      ),
    );
  }
}
