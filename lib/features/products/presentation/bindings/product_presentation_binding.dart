// lib/features/products/presentation/bindings/product_presentation_binding.dart
import 'package:get/get.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../data/datasources/product_presentation_remote_datasource.dart';
import '../../data/datasources/product_presentation_local_datasource.dart';
import '../../data/repositories/product_presentation_repository_impl.dart';
import '../../domain/repositories/product_presentation_repository.dart';
import '../../domain/usecases/get_product_presentations_usecase.dart';
import '../../domain/usecases/create_product_presentation_usecase.dart';
import '../../domain/usecases/update_product_presentation_usecase.dart';
import '../../domain/usecases/delete_product_presentation_usecase.dart';
import '../controllers/product_presentations_controller.dart';

class ProductPresentationBinding implements Bindings {
  @override
  void dependencies() {
    // Núcleo (data + use cases) — también se registra desde InitialBinding
    // para que esté disponible globalmente (ej: el dialog selector en el POS
    // necesita GetProductPresentationsUseCase sin haber entrado antes a esta
    // pantalla). Idempotente vía isRegistered.
    registerCore();

    // Controller específico de esta pantalla
    Get.lazyPut(
      () => ProductPresentationsController(
        getPresentationsUseCase: Get.find<GetProductPresentationsUseCase>(),
        createPresentationUseCase: Get.find<CreateProductPresentationUseCase>(),
        updatePresentationUseCase: Get.find<UpdateProductPresentationUseCase>(),
        deletePresentationUseCase: Get.find<DeleteProductPresentationUseCase>(),
      ),
      fenix: true,
    );
  }

  /// Registra datasources, repository y use cases del módulo
  /// ProductPresentation. Llamable desde InitialBinding para garantizar
  /// disponibilidad global; idempotente: comprueba isRegistered antes de
  /// cada lazyPut, así llamarlo varias veces es seguro.
  static void registerCore() {
    if (!Get.isRegistered<ProductPresentationRemoteDataSource>()) {
      Get.lazyPut<ProductPresentationRemoteDataSource>(
        () => ProductPresentationRemoteDataSourceImpl(
          dioClient: Get.find<DioClient>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<ProductPresentationLocalDataSource>()) {
      Get.lazyPut<ProductPresentationLocalDataSource>(
        () => ProductPresentationLocalDataSourceIsar(
          Get.find<IsarDatabase>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<ProductPresentationRepository>()) {
      Get.lazyPut<ProductPresentationRepository>(
        () => ProductPresentationRepositoryImpl(
          remoteDataSource: Get.find<ProductPresentationRemoteDataSource>(),
          localDataSource: Get.find<ProductPresentationLocalDataSource>(),
          networkInfo: Get.find<NetworkInfo>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<GetProductPresentationsUseCase>()) {
      Get.lazyPut(
        () => GetProductPresentationsUseCase(
          Get.find<ProductPresentationRepository>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<CreateProductPresentationUseCase>()) {
      Get.lazyPut(
        () => CreateProductPresentationUseCase(
          Get.find<ProductPresentationRepository>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<UpdateProductPresentationUseCase>()) {
      Get.lazyPut(
        () => UpdateProductPresentationUseCase(
          Get.find<ProductPresentationRepository>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<DeleteProductPresentationUseCase>()) {
      Get.lazyPut(
        () => DeleteProductPresentationUseCase(
          Get.find<ProductPresentationRepository>(),
        ),
        fenix: true,
      );
    }
  }
}
