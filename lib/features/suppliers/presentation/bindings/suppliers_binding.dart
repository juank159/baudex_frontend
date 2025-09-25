// lib/features/suppliers/presentation/bindings/suppliers_binding.dart
import 'package:get/get.dart';
import '../controllers/suppliers_controller.dart';
import '../controllers/supplier_detail_controller.dart';
import '../controllers/supplier_form_controller.dart';
import '../../domain/usecases/get_suppliers_usecase.dart';
import '../../domain/usecases/get_supplier_by_id_usecase.dart';
import '../../domain/usecases/create_supplier_usecase.dart';
import '../../domain/usecases/update_supplier_usecase.dart';
import '../../domain/usecases/delete_supplier_usecase.dart';
import '../../domain/usecases/search_suppliers_usecase.dart';
import '../../domain/usecases/get_supplier_stats_usecase.dart';
import '../../domain/usecases/check_document_uniqueness_usecase.dart';
import '../../data/repositories/supplier_repository_impl.dart';
import '../../data/datasources/supplier_remote_datasource.dart';
import '../../data/datasources/supplier_local_datasource.dart';
import '../../domain/repositories/supplier_repository.dart';

class SuppliersBinding extends Bindings {
  @override
  void dependencies() {
    // Data Sources
    Get.lazyPut<SupplierRemoteDataSource>(
      () => SupplierRemoteDataSourceImpl(dioClient: Get.find()),
    );
    
    Get.lazyPut<SupplierLocalDataSource>(
      () => SupplierLocalDataSourceImpl(secureStorage: Get.find()),
    );

    // Repository
    Get.lazyPut<SupplierRepository>(
      () => SupplierRepositoryImpl(
        remoteDataSource: Get.find<SupplierRemoteDataSource>(),
        localDataSource: Get.find<SupplierLocalDataSource>(),
        networkInfo: Get.find(),
      ),
    );

    // Use Cases
    Get.lazyPut(() => GetSuppliersUseCase(Get.find<SupplierRepository>()));
    Get.lazyPut(() => GetSupplierByIdUseCase(Get.find<SupplierRepository>()));
    Get.lazyPut(() => CreateSupplierUseCase(Get.find<SupplierRepository>()));
    Get.lazyPut(() => UpdateSupplierUseCase(Get.find<SupplierRepository>()));
    Get.lazyPut(() => DeleteSupplierUseCase(Get.find<SupplierRepository>()));
    Get.lazyPut(() => SearchSuppliersUseCase(Get.find<SupplierRepository>()));
    Get.lazyPut(() => GetSupplierStatsUseCase(Get.find<SupplierRepository>()));
    Get.lazyPut(() => CheckDocumentUniquenessUseCase(Get.find<SupplierRepository>()));

    // Controllers
    Get.lazyPut(() => SuppliersController(
      getSuppliersUseCase: Get.find(),
      deleteSupplierUseCase: Get.find(),
      searchSuppliersUseCase: Get.find(),
      getSupplierStatsUseCase: Get.find(),
    ));
  }
}

class SupplierDetailBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure base dependencies are available
    if (!Get.isRegistered<SupplierRepository>()) {
      SuppliersBinding().dependencies();
    }

    // Ensure all required use cases are registered
    if (!Get.isRegistered<GetSupplierByIdUseCase>()) {
      Get.lazyPut(() => GetSupplierByIdUseCase(Get.find<SupplierRepository>()));
    }
    if (!Get.isRegistered<DeleteSupplierUseCase>()) {
      Get.lazyPut(() => DeleteSupplierUseCase(Get.find<SupplierRepository>()));
    }
    if (!Get.isRegistered<UpdateSupplierUseCase>()) {
      Get.lazyPut(() => UpdateSupplierUseCase(Get.find<SupplierRepository>()));
    }

    // Controller
    Get.lazyPut(() => SupplierDetailController(
      getSupplierByIdUseCase: Get.find(),
      deleteSupplierUseCase: Get.find(),
      updateSupplierUseCase: Get.find(),
    ));
  }
}

class SupplierFormBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure base dependencies are available
    if (!Get.isRegistered<SupplierRepository>()) {
      SuppliersBinding().dependencies();
    }

    // Ensure all required use cases are registered
    if (!Get.isRegistered<CreateSupplierUseCase>()) {
      Get.lazyPut(() => CreateSupplierUseCase(Get.find<SupplierRepository>()));
    }
    if (!Get.isRegistered<UpdateSupplierUseCase>()) {
      Get.lazyPut(() => UpdateSupplierUseCase(Get.find<SupplierRepository>()));
    }
    if (!Get.isRegistered<GetSupplierByIdUseCase>()) {
      Get.lazyPut(() => GetSupplierByIdUseCase(Get.find<SupplierRepository>()));
    }
    if (!Get.isRegistered<CheckDocumentUniquenessUseCase>()) {
      Get.lazyPut(() => CheckDocumentUniquenessUseCase(Get.find<SupplierRepository>()));
    }

    // Controller
    Get.lazyPut(() => SupplierFormController(
      createSupplierUseCase: Get.find(),
      updateSupplierUseCase: Get.find(),
      getSupplierByIdUseCase: Get.find(),
      checkDocumentUniquenessUseCase: Get.find(),
    ));
  }
}