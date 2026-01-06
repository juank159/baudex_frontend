// lib/app/simple_app_binding.dart
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'data/local/isar_database.dart';
import 'data/local/repositories_registry.dart';
import 'controllers/simple_auth_controller.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/network/dio_client.dart';
import 'core/network/network_info.dart';
import 'core/services/audio_notification_service.dart';
import 'core/services/file_service.dart';
import 'services/password_validation_service.dart';
import 'shared/controllers/app_drawer_controller.dart';
import '../features/auth/presentation/bindings/auth_binding_stub.dart';
import '../features/settings/presentation/bindings/settings_binding.dart';
import 'data/local/sync_service.dart';
import 'core/services/conflict_resolver.dart';
// Offline Repositories
import '../features/bank_accounts/data/repositories/bank_account_repository_impl.dart';
import '../features/bank_accounts/data/datasources/bank_account_remote_datasource.dart';
import '../features/bank_accounts/domain/repositories/bank_account_repository.dart';
import '../features/products/data/repositories/product_repository_impl.dart';
import '../features/products/data/datasources/product_remote_datasource.dart';
import '../features/products/data/datasources/product_local_datasource_isar.dart';
import '../features/products/domain/repositories/product_repository.dart';
import '../features/customers/data/repositories/customer_repository_impl.dart';
import '../features/customers/data/datasources/customer_remote_datasource.dart';
import '../features/customers/data/datasources/customer_local_datasource.dart';
import '../features/customers/domain/repositories/customer_repository.dart';
import '../features/expenses/data/repositories/expense_repository_impl.dart';
import '../features/expenses/data/datasources/expense_remote_datasource.dart';
import '../features/expenses/data/datasources/expense_local_datasource.dart';
import '../features/expenses/domain/repositories/expense_repository.dart';
import '../features/dashboard/data/datasources/dashboard_local_datasource_isar.dart';
import '../features/dashboard/data/datasources/dashboard_local_datasource.dart';
import '../features/categories/data/repositories/category_repository_impl.dart';
import '../features/categories/data/datasources/category_remote_datasource.dart';
import '../features/categories/data/datasources/category_local_datasource.dart';
import '../features/categories/domain/repositories/category_repository.dart';

class InitialBinding implements Bindings {
  @override
  void dependencies() {
    print('🚀 SimpleAppBinding: Iniciando dependencias básicas offline-first...');

    // ==================== CORE DEPENDENCIES ====================
    _registerCoreDependencies();

    // ==================== OFFLINE INFRASTRUCTURE ====================
    _registerOfflineInfrastructure();

    // ==================== OFFLINE REPOSITORIES ====================
    _registerOfflineRepositories();

    // ==================== AUTH CONTROLLER ====================
    _registerAuthController();

    // ==================== SETTINGS CONTROLLER ====================
    _registerSettingsController();

    // ==================== SYNC SERVICE ====================
    _registerSyncService();

    // ==================== CONFLICT RESOLVER SERVICE ====================
    _registerConflictResolver();

    // ==================== AUDIO NOTIFICATION SERVICE ====================
    _registerAudioService();

    print('✅ SimpleAppBinding: Dependencias básicas registradas exitosamente');
  }

  void _registerCoreDependencies() {
    print('📦 Registrando dependencias core básicas...');

    // External dependencies
    Get.lazyPut<Dio>(() => Dio(), fenix: true);
    Get.lazyPut<FlutterSecureStorage>(() => const FlutterSecureStorage(), fenix: true);
    Get.lazyPut<Connectivity>(() => Connectivity(), fenix: true);

    // Core network and storage services
    Get.lazyPut<SecureStorageService>(() => SecureStorageService(), fenix: true);
    Get.lazyPut<NetworkInfo>(() => NetworkInfoImpl(Get.find<Connectivity>()), fenix: true);
    Get.lazyPut<DioClient>(() => DioClient(), fenix: true);

    // Core services
    Get.lazyPut<FileService>(() => FileServiceImpl(), fenix: true);

    // Security services
    Get.lazyPut<PasswordValidationService>(() => PasswordValidationService(Get.find<DioClient>()), fenix: true);

    // UI Controllers
    Get.lazyPut<AppDrawerController>(() => AppDrawerController(), fenix: true);

    print('✅ Dependencias core básicas registradas');
  }

  void _registerOfflineInfrastructure() {
    print('💾 Registrando infraestructura offline básica...');

    // ISAR Database (singleton)
    Get.put<IsarDatabase>(IsarDatabase.instance, permanent: true);

    // Simplified Registry
    Get.lazyPut<RepositoriesRegistry>(() => RepositoriesRegistry.instance, fenix: true);

    print('✅ Infraestructura offline básica registrada');
  }

  void _registerOfflineRepositories() {
    print('📦 Registrando repositorios offline-first...');

    // Dashboard - Local DataSource
    Get.lazyPut<DashboardLocalDataSource>(
      () => DashboardLocalDataSourceIsar(),
      fenix: true,
    );

    // Bank Accounts - Remote DataSource
    Get.lazyPut<BankAccountRemoteDataSource>(
      () => BankAccountRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
      fenix: true,
    );

    // Bank Accounts - Offline-First Repository (online + offline)
    Get.lazyPut<BankAccountRepository>(
      () => BankAccountRepositoryImpl(
        remoteDataSource: Get.find<BankAccountRemoteDataSource>(),
        networkInfo: Get.find<NetworkInfo>(),
      ),
      fenix: true,
    );

    // Products - Remote DataSource (necesario para SyncService)
    Get.lazyPut<ProductRemoteDataSource>(
      () => ProductRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
      fenix: true,
    );

    // Products - Hybrid Repository (backend + offline)
    Get.lazyPut<ProductRepository>(
      () => ProductRepositoryImpl(
        remoteDataSource: Get.find<ProductRemoteDataSource>(),
        localDataSource: ProductLocalDataSourceIsar(Get.find<IsarDatabase>()),
        networkInfo: Get.find<NetworkInfo>(),
      ),
      fenix: true,
    );

    // Categories - Remote DataSource (necesario para SyncService)
    Get.lazyPut<CategoryRemoteDataSource>(
      () => CategoryRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
      fenix: true,
    );

    // Categories - Local DataSource
    Get.lazyPut<CategoryLocalDataSource>(
      () => CategoryLocalDataSourceImpl(
        storageService: Get.find<SecureStorageService>(),
      ),
      fenix: true,
    );

    // Categories - Hybrid Repository (backend + offline)
    Get.lazyPut<CategoryRepository>(
      () => CategoryRepositoryImpl(
        remoteDataSource: Get.find<CategoryRemoteDataSource>(),
        localDataSource: Get.find<CategoryLocalDataSource>(),
        networkInfo: Get.find<NetworkInfo>(),
      ),
      fenix: true,
    );

    // Customers - Offline-First Repository (online + offline)
    Get.lazyPut<CustomerRepository>(
      () => CustomerRepositoryImpl(
        remoteDataSource: CustomerRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
        localDataSource: CustomerLocalDataSourceImpl(storageService: Get.find<SecureStorageService>()),
        networkInfo: Get.find<NetworkInfo>(),
      ),
      fenix: true,
    );

    // Expenses - Remote DataSource
    Get.lazyPut<ExpenseRemoteDataSource>(
      () => ExpenseRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
      fenix: true,
    );

    // Expenses - Local DataSource
    Get.lazyPut<ExpenseLocalDataSource>(
      () => ExpenseLocalDataSourceImpl(secureStorage: Get.find<SecureStorageService>()),
      fenix: true,
    );

    // Expenses - Offline-First Repository (online + offline)
    Get.lazyPut<ExpenseRepository>(
      () => ExpenseRepositoryImpl(
        remoteDataSource: Get.find<ExpenseRemoteDataSource>(),
        localDataSource: Get.find<ExpenseLocalDataSource>(),
        networkInfo: Get.find<NetworkInfo>(),
      ),
      fenix: true,
    );

    print('✅ Repositorios offline-first registrados');
  }

  void _registerAuthController() {
    print('🔐 Registrando sistema de autenticación completo...');

    // Usar AuthBindingStub para registrar todo el sistema de auth
    AuthBindingStub().dependencies();
    
    // Mantener SimpleAuthController como fallback
    if (!Get.isRegistered<SimpleAuthController>()) {
      final authController = SimpleAuthController();
      Get.put<SimpleAuthController>(authController, permanent: true);
    }

    print('✅ Sistema de autenticación completo registrado');
  }

  void _registerSettingsController() {
    print('⚙️ Registrando SettingsController globalmente...');

    // Importar SettingsBinding para registrar sus dependencias
    try {
      // Usar el método estático del SettingsBinding para registrar solo el controlador
      final settingsBinding = SettingsBinding();
      settingsBinding.dependencies();
      print('✅ SettingsController registrado globalmente');
    } catch (e) {
      print('⚠️ Error al registrar SettingsController: $e');
    }
  }

  void _registerSyncService() {
    print('🔄 Registrando servicio de sincronización offline-first...');

    // SyncService requiere IsarDatabase como dependencia
    final syncService = SyncService(Get.find<IsarDatabase>());
    Get.put<SyncService>(
      syncService,
      permanent: true,
    );

    // IMPORTANTE: GetxService no llama onInit() automáticamente, debemos llamarlo manualmente
    syncService.onInit();

    print('✅ Servicio de sincronización offline-first registrado e inicializado');
  }

  void _registerConflictResolver() {
    print('⚔️ Registrando servicio de resolución de conflictos...');

    // ConflictResolver como servicio permanente
    Get.put<ConflictResolver>(
      ConflictResolver(),
      permanent: true,
    );

    print('✅ Servicio de resolución de conflictos registrado');
  }

  void _registerAudioService() {
    print('🔊 Registrando servicio de notificaciones de audio...');

    // AudioNotificationService inicialización asíncrona
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioNotificationService.instance.initialize().then((_) {
        print('✅ Servicio de audio TTS inicializado correctamente');
      }).catchError((e) {
        print('⚠️ Error al inicializar servicio de audio: $e');
      });
    });

    print('✅ Servicio de notificaciones de audio registrado');
  }
}