// lib/features/products/presentation/bindings/product_waste_binding.dart
import 'package:get/get.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/network/network_info.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../controllers/product_waste_controller.dart';

class ProductWasteBinding implements Bindings {
  @override
  void dependencies() {
    // DataSource (may already be registered by ProductBinding)
    if (!Get.isRegistered<ProductRemoteDataSource>()) {
      Get.lazyPut<ProductRemoteDataSource>(
        () => ProductRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
        fenix: true,
      );
    }

    // Controller
    Get.lazyPut(
      () => ProductWasteController(
        remoteDataSource: Get.find<ProductRemoteDataSource>(),
        networkInfo: Get.find<NetworkInfo>(),
      ),
      fenix: true,
    );
  }
}
