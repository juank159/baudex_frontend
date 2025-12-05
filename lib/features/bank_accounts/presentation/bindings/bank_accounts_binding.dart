// lib/features/bank_accounts/presentation/bindings/bank_accounts_binding.dart
import 'package:get/get.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/network/network_info.dart';
import '../../data/datasources/bank_account_remote_datasource.dart';
import '../../data/repositories/bank_account_repository_impl.dart';
import '../../domain/repositories/bank_account_repository.dart';
import '../controllers/bank_accounts_controller.dart';

/// Binding para el módulo de cuentas bancarias
class BankAccountsBinding extends Bindings {
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
    Get.lazyPut<BankAccountsController>(
      () => BankAccountsController(
        repository: Get.find<BankAccountRepository>(),
      ),
    );
  }
}
