// lib/features/reports/presentation/bindings/reports_binding.dart
import 'package:get/get.dart';
import '../../data/datasources/reports_remote_datasource.dart';
import '../../data/repositories/reports_repository_impl.dart';
import '../../domain/repositories/reports_repository.dart';
import '../../domain/usecases/get_inventory_valuation_by_categories_usecase.dart';
import '../../domain/usecases/get_inventory_valuation_by_products_usecase.dart';
import '../../domain/usecases/get_inventory_valuation_summary_usecase.dart';
import '../../domain/usecases/get_profitability_by_categories_usecase.dart';
import '../../domain/usecases/get_profitability_by_products_usecase.dart';
import '../../domain/usecases/get_profitability_trends_usecase.dart';
import '../../domain/usecases/get_top_profitable_products_usecase.dart';
import '../../domain/usecases/get_valuation_variances_usecase.dart';
import '../controllers/reports_controller.dart';

class ReportsBinding extends Bindings {
  @override
  void dependencies() {
    // Data Sources
    Get.lazyPut<ReportsRemoteDataSource>(
      () => ReportsRemoteDataSourceImpl(dio: Get.find()),
    );

    // Repository
    Get.lazyPut<ReportsRepository>(
      () => ReportsRepositoryImpl(
        remoteDataSource: Get.find(),
        networkInfo: Get.find(),
      ),
    );

    // Use Cases
    Get.lazyPut(() => GetProfitabilityByProductsUseCase(Get.find()));
    Get.lazyPut(() => GetProfitabilityByCategoriesUseCase(Get.find()));
    Get.lazyPut(() => GetTopProfitableProductsUseCase(Get.find()));
    Get.lazyPut(() => GetInventoryValuationSummaryUseCase(Get.find()));
    Get.lazyPut(() => GetInventoryValuationByProductsUseCase(Get.find()));
    Get.lazyPut(() => GetInventoryValuationByCategoriesUseCase(Get.find()));
    Get.lazyPut(() => GetProfitabilityTrendsUseCase(Get.find()));
    Get.lazyPut(() => GetValuationVariancesUseCase(Get.find()));

    // Controller
    Get.lazyPut(
      () => ReportsController(
        getProfitabilityByProductsUseCase: Get.find(),
        getProfitabilityByCategoriesUseCase: Get.find(),
        getTopProfitableProductsUseCase: Get.find(),
        getInventoryValuationSummaryUseCase: Get.find(),
        getInventoryValuationByProductsUseCase: Get.find(),
        getInventoryValuationByCategoriesUseCase: Get.find(),
        getProfitabilityTrendsUseCase: Get.find(),
        getValuationVariancesUseCase: Get.find(),
      ),
    );
  }
}