// lib/features/expenses/presentation/bindings/expense_binding.dart
import 'package:get/get.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/storage/secure_storage_service.dart';
import '../../../../app/core/services/file_service.dart';
import '../../data/datasources/expense_remote_datasource.dart';
import '../../data/datasources/expense_local_datasource.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/usecases/get_expenses_usecase.dart';
import '../../domain/usecases/get_expense_by_id_usecase.dart';
import '../../domain/usecases/create_expense_usecase.dart';
import '../../domain/usecases/update_expense_usecase.dart';
import '../../domain/usecases/delete_expense_usecase.dart';
import '../../domain/usecases/get_expense_stats_usecase.dart';
import '../../domain/usecases/approve_expense_usecase.dart';
import '../../domain/usecases/submit_expense_usecase.dart';
import '../../domain/usecases/get_expense_categories_usecase.dart';
import '../../domain/usecases/create_expense_category_usecase.dart';
import '../../domain/usecases/update_expense_category_usecase.dart';
import '../../domain/usecases/delete_expense_category_usecase.dart';
import '../controllers/expenses_controller.dart';
import '../controllers/enhanced_expenses_controller.dart';
import '../controllers/expense_form_controller.dart';
import '../controllers/expense_categories_controller.dart';

class ExpenseBinding extends Bindings {
  @override
  void dependencies() {
    print('🔄 Inicializando Expense Binding...');

    // ==================== SERVICES ====================
    
    // Registrar FileService si no está ya registrado
    if (!Get.isRegistered<FileService>()) {
      Get.lazyPut<FileService>(
        () => FileServiceImpl(),
        fenix: true,
      );
    }

    // ==================== DATA SOURCES ====================

    Get.lazyPut<ExpenseRemoteDataSource>(
      () => ExpenseRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
      fenix: true,
    );

    Get.lazyPut<ExpenseLocalDataSource>(
      () => ExpenseLocalDataSourceImpl(secureStorage: Get.find<SecureStorageService>()),
      fenix: true,
    );

    // ==================== REPOSITORY ====================

    Get.lazyPut<ExpenseRepository>(
      () => ExpenseRepositoryImpl(
        remoteDataSource: Get.find<ExpenseRemoteDataSource>(),
        localDataSource: Get.find<ExpenseLocalDataSource>(),
        networkInfo: Get.find<NetworkInfo>(),
      ),
      fenix: true,
    );

    // ==================== USE CASES ====================

    Get.lazyPut<GetExpensesUseCase>(
      () => GetExpensesUseCase(Get.find<ExpenseRepository>()),
      fenix: true,
    );

    Get.lazyPut<GetExpenseByIdUseCase>(
      () => GetExpenseByIdUseCase(Get.find<ExpenseRepository>()),
      fenix: true,
    );

    Get.lazyPut<CreateExpenseUseCase>(
      () => CreateExpenseUseCase(Get.find<ExpenseRepository>()),
      fenix: true,
    );

    Get.lazyPut<UpdateExpenseUseCase>(
      () => UpdateExpenseUseCase(Get.find<ExpenseRepository>()),
      fenix: true,
    );

    Get.lazyPut<DeleteExpenseUseCase>(
      () => DeleteExpenseUseCase(Get.find<ExpenseRepository>()),
      fenix: true,
    );

    Get.lazyPut<GetExpenseStatsUseCase>(
      () => GetExpenseStatsUseCase(Get.find<ExpenseRepository>()),
      fenix: true,
    );

    Get.lazyPut<ApproveExpenseUseCase>(
      () => ApproveExpenseUseCase(Get.find<ExpenseRepository>()),
      fenix: true,
    );

    Get.lazyPut<SubmitExpenseUseCase>(
      () => SubmitExpenseUseCase(Get.find<ExpenseRepository>()),
      fenix: true,
    );

    Get.lazyPut<GetExpenseCategoriesUseCase>(
      () => GetExpenseCategoriesUseCase(Get.find<ExpenseRepository>()),
      fenix: true,
    );

    Get.lazyPut<CreateExpenseCategoryUseCase>(
      () => CreateExpenseCategoryUseCase(Get.find<ExpenseRepository>()),
      fenix: true,
    );

    Get.lazyPut<UpdateExpenseCategoryUseCase>(
      () => UpdateExpenseCategoryUseCase(Get.find<ExpenseRepository>()),
      fenix: true,
    );

    Get.lazyPut<DeleteExpenseCategoryUseCase>(
      () => DeleteExpenseCategoryUseCase(Get.find<ExpenseRepository>()),
      fenix: true,
    );

    // ==================== CONTROLLERS ====================

    // ✅ Usar EnhancedExpensesController como controlador principal
    Get.lazyPut<EnhancedExpensesController>(
      () => EnhancedExpensesController(
        getExpensesUseCase: Get.find<GetExpensesUseCase>(),
        deleteExpenseUseCase: Get.find<DeleteExpenseUseCase>(),
        getExpenseStatsUseCase: Get.find<GetExpenseStatsUseCase>(),
        approveExpenseUseCase: Get.find<ApproveExpenseUseCase>(),
        submitExpenseUseCase: Get.find<SubmitExpenseUseCase>(),
      ),
      fenix: true,
    );

    // ✅ Mantener el controlador original como fallback si es necesario
    Get.lazyPut<ExpensesController>(
      () => ExpensesController(
        getExpensesUseCase: Get.find<GetExpensesUseCase>(),
        deleteExpenseUseCase: Get.find<DeleteExpenseUseCase>(),
        getExpenseStatsUseCase: Get.find<GetExpenseStatsUseCase>(),
        approveExpenseUseCase: Get.find<ApproveExpenseUseCase>(),
        submitExpenseUseCase: Get.find<SubmitExpenseUseCase>(),
      ),
      fenix: true,
    );

    Get.lazyPut<ExpenseFormController>(
      () => ExpenseFormController(
        createExpenseUseCase: Get.find<CreateExpenseUseCase>(),
        updateExpenseUseCase: Get.find<UpdateExpenseUseCase>(),
        getExpenseByIdUseCase: Get.find<GetExpenseByIdUseCase>(),
        getExpenseCategoriesUseCase: Get.find<GetExpenseCategoriesUseCase>(),
        createExpenseCategoryUseCase: Get.find<CreateExpenseCategoryUseCase>(),
        fileService: Get.find<FileService>(),
      ),
      fenix: true,
    );

    Get.lazyPut<ExpenseCategoriesController>(
      () => ExpenseCategoriesController(
        getExpenseCategoriesUseCase: Get.find<GetExpenseCategoriesUseCase>(),
        createExpenseCategoryUseCase: Get.find<CreateExpenseCategoryUseCase>(),
        updateExpenseCategoryUseCase: Get.find<UpdateExpenseCategoryUseCase>(),
        deleteExpenseCategoryUseCase: Get.find<DeleteExpenseCategoryUseCase>(),
      ),
      fenix: true,
    );

    print('✅ Expense Binding inicializado correctamente');
  }
}