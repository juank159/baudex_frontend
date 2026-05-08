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
    // El controller permanente se registra en `app_binding.dart` al
    // arranque para que el badge del AppBar y el banner del dashboard
    // mantengan el estado en vivo. Aquí solo aseguramos que existe
    // (por si alguien navega directo a la pantalla sin pasar por el
    // dashboard).
    if (!Get.isRegistered<CashRegisterController>()) {
      Get.put<CashRegisterController>(
        CashRegisterController(
          repository: Get.find<CashRegisterRepository>(),
        ),
        permanent: true,
      );
    }
  }
}
