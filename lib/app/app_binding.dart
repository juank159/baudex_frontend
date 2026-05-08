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
import 'core/services/tenant_datetime_service.dart';
import 'services/password_validation_service.dart';
import 'shared/controllers/app_drawer_controller.dart';
import '../features/auth/presentation/bindings/auth_binding_stub.dart';
import '../features/products/presentation/bindings/product_presentation_binding.dart';
import 'data/local/sync_event_log_service.dart';
import '../features/settings/presentation/bindings/settings_binding.dart';
import '../features/settings/data/datasources/user_preferences_remote_datasource.dart';
import '../features/settings/data/datasources/user_preferences_local_datasource.dart';
import '../features/settings/data/repositories/user_preferences_repository_impl.dart';
import '../features/settings/domain/repositories/user_preferences_repository.dart';
import '../features/settings/domain/usecases/get_user_preferences_usecase.dart';
import '../features/settings/domain/usecases/update_user_preferences_usecase.dart';
import '../features/settings/presentation/controllers/user_preferences_controller.dart';
import 'data/local/sync_service.dart';
import 'data/local/full_sync_service.dart';
import 'core/services/conflict_resolver.dart';
import 'core/services/idempotency_service.dart';
import 'core/services/conflict_resolution_service.dart';
import 'data/local/atomic_transaction_helper.dart';
// Offline Repositories
import '../features/bank_accounts/data/repositories/bank_account_repository_impl.dart';
import '../features/bank_accounts/data/repositories/bank_account_offline_repository.dart';
import '../features/bank_accounts/data/datasources/bank_account_remote_datasource.dart';
import '../features/bank_accounts/domain/repositories/bank_account_repository.dart';
import '../features/cash_register/data/datasources/cash_register_remote_datasource.dart';
import '../features/cash_register/data/repositories/cash_register_repository_impl.dart';
import '../features/cash_register/domain/repositories/cash_register_repository.dart';
import '../features/cash_register/presentation/controllers/cash_register_controller.dart';
import '../features/products/data/repositories/product_repository_impl.dart';
import '../features/products/data/repositories/product_offline_repository.dart';
import '../features/products/data/datasources/product_remote_datasource.dart';
import '../features/products/data/datasources/product_local_datasource_isar.dart';
import '../features/products/domain/repositories/product_repository.dart';
import '../features/customers/data/repositories/customer_repository_impl.dart';
import '../features/customers/data/repositories/customer_offline_repository.dart';
import '../features/customers/data/datasources/customer_remote_datasource.dart';
import '../features/customers/data/datasources/customer_local_datasource_isar.dart';
import '../features/customers/domain/repositories/customer_repository.dart';
import '../features/expenses/data/repositories/expense_repository_impl.dart';
import '../features/expenses/data/repositories/expense_offline_repository.dart';
import '../features/expenses/data/datasources/expense_remote_datasource.dart';
import '../features/expenses/data/datasources/expense_local_datasource.dart';
import '../features/expenses/data/datasources/expense_local_datasource_isar.dart';
import '../features/expenses/domain/repositories/expense_repository.dart';
import '../features/dashboard/data/datasources/dashboard_local_datasource_isar.dart';
import '../features/dashboard/data/datasources/dashboard_local_datasource.dart';
import '../features/categories/data/repositories/category_repository_impl.dart';
import '../features/categories/data/repositories/category_offline_repository.dart';
import '../features/categories/data/datasources/category_remote_datasource.dart';
import '../features/categories/data/datasources/category_local_datasource.dart';
import '../features/categories/data/datasources/category_local_datasource_isar.dart';
import '../features/categories/domain/repositories/category_repository.dart';
import '../features/invoices/data/repositories/invoice_offline_repository.dart';
import '../features/dashboard/data/repositories/notification_offline_repository.dart';
// ⭐ FASE 1 - Repositorios Offline adicionales para SyncService
import '../features/suppliers/data/repositories/supplier_offline_repository.dart';
import '../features/purchase_orders/data/repositories/purchase_order_offline_repository.dart';
import '../features/inventory/data/repositories/inventory_offline_repository.dart';
import '../features/credit_notes/data/repositories/credit_note_offline_repository.dart';
import '../features/customer_credits/data/repositories/customer_credit_offline_repository.dart';
import '../features/settings/data/datasources/organization_remote_datasource.dart';
import '../features/settings/data/repositories/organization_offline_repository.dart';
// Subscription services
import '../features/subscriptions/presentation/bindings/subscription_binding.dart';
import 'shared/services/subscription_offline_policy.dart';

class InitialBinding implements Bindings {
  static bool _initialized = false;

  @override
  void dependencies() {
    if (_initialized) {
      print('⚠️ InitialBinding: Ya inicializado, omitiendo...');
      return;
    }
    _initialized = true;

    print('🚀 SimpleAppBinding: Iniciando dependencias básicas offline-first...');

    // ==================== CORE DEPENDENCIES ====================
    _registerCoreDependencies();

    // ==================== TENANT DATETIME SERVICE ====================
    Get.put(TenantDateTimeService(), permanent: true);

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

    // ==================== IDEMPOTENCY SERVICE ====================
    _registerIdempotencyService();

    // ==================== CONFLICT RESOLUTION SERVICE ====================
    _registerConflictResolutionService();

    // ==================== ATOMIC TRANSACTION HELPER ====================
    _registerAtomicTransactionHelper();

    // ==================== AUDIO NOTIFICATION SERVICE ====================
    _registerAudioService();

    // ==================== SUBSCRIPTION SERVICES ====================
    _registerSubscriptionServices();

    // ==================== USER PREFERENCES ====================
    _registerUserPreferences();

    // ==================== PRODUCT PRESENTATIONS (Fase 3) ====================
    // Registrar core (datasources + repo + use cases) globalmente para que
    // el dialog selector del POS funcione sin haber visitado antes la
    // pantalla de "Gestionar presentaciones". Idempotente, lazy.
    ProductPresentationBinding.registerCore();

    // ==================== DIAGNÓSTICO / LOG DE EVENTOS DE SYNC ===========
    // Servicio singleton para persistir eventos del sync en Isar. El
    // sync_service lo invoca opcionalmente y la pantalla de diagnóstico
    // lo lee. Tolerante a fallas: si Isar falla escribir, el sync sigue.
    Get.lazyPut<SyncEventLogService>(() => SyncEventLogService(), fenix: true);

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

    // Cash Register - Remote DataSource + Repository + Controller permanente.
    // Se registra como permanente porque el badge del AppBar y el banner
    // del dashboard se montan/desmontan en distintas pantallas y deben
    // compartir el mismo estado en vivo. El controller auto-refresca cada 60s.
    Get.lazyPut<CashRegisterRemoteDataSource>(
      () => CashRegisterRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
      fenix: true,
    );
    Get.lazyPut<CashRegisterRepository>(
      () => CashRegisterRepositoryImpl(
        remoteDataSource: Get.find<CashRegisterRemoteDataSource>(),
        networkInfo: Get.find<NetworkInfo>(),
        secureStorage: Get.find<SecureStorageService>(),
      ),
      fenix: true,
    );
    Get.put<CashRegisterController>(
      CashRegisterController(
        repository: Get.find<CashRegisterRepository>(),
      ),
      permanent: true,
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

    // Categories - Local DataSource (ISAR - persistencia offline)
    Get.lazyPut<CategoryLocalDataSource>(
      () => CategoryLocalDataSourceIsar(),
      fenix: true,
    );

    // Categories - Hybrid Repository (backend + offline)
    Get.lazyPut<CategoryRepository>(
      () => CategoryRepositoryImpl(
        remoteDataSource: Get.find<CategoryRemoteDataSource>(),
        localDataSource: Get.find<CategoryLocalDataSource>(),
        networkInfo: Get.find<NetworkInfo>(),
        database: Get.find<IsarDatabase>(),
      ),
      fenix: true,
    );

    // Customers - Offline-First Repository (online + offline, ISAR local)
    Get.lazyPut<CustomerRepository>(
      () => CustomerRepositoryImpl(
        remoteDataSource: CustomerRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
        localDataSource: CustomerLocalDataSourceIsar(),
        networkInfo: Get.find<NetworkInfo>(),
        database: Get.find<IsarDatabase>(),
      ),
      fenix: true,
    );

    // Expenses - Remote DataSource
    Get.lazyPut<ExpenseRemoteDataSource>(
      () => ExpenseRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
      fenix: true,
    );

    // Expenses - Local DataSource (ISAR - persistencia offline)
    Get.lazyPut<ExpenseLocalDataSource>(
      () => ExpenseLocalDataSourceIsar(),
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

    // Notifications - Offline Repository
    Get.lazyPut<NotificationOfflineRepository>(
      () => NotificationOfflineRepository(
        database: Get.find<IsarDatabase>(),
      ),
      fenix: true,
    );

    // ⭐ FASE 1 - PROBLEMA 3: Repositorios Offline adicionales para lectura fresca en SyncService

    // Products - Offline Repository (para SyncService)
    Get.lazyPut<ProductOfflineRepository>(
      () => ProductOfflineRepository(
        database: Get.find<IsarDatabase>(),
      ),
      fenix: true,
    );

    // Categories - Offline Repository (para SyncService)
    Get.lazyPut<CategoryOfflineRepository>(
      () => CategoryOfflineRepository(
        database: Get.find<IsarDatabase>(),
      ),
      fenix: true,
    );

    // Customers - Offline Repository (para SyncService)
    Get.lazyPut<CustomerOfflineRepository>(
      () => CustomerOfflineRepository(
        database: Get.find<IsarDatabase>(),
      ),
      fenix: true,
    );

    // Invoices - Offline Repository (para SyncService)
    Get.lazyPut<InvoiceOfflineRepository>(
      () => InvoiceOfflineRepository(
        database: Get.find<IsarDatabase>(),
      ),
      fenix: true,
    );

    // Suppliers - Offline Repository (para SyncService)
    Get.lazyPut<SupplierOfflineRepository>(
      () => SupplierOfflineRepository(
        database: Get.find<IsarDatabase>(),
      ),
      fenix: true,
    );

    // Expenses - Offline Repository (para SyncService)
    Get.lazyPut<ExpenseOfflineRepository>(
      () => ExpenseOfflineRepository(
        database: Get.find<IsarDatabase>(),
      ),
      fenix: true,
    );

    // BankAccounts - Offline Repository (para SyncService)
    Get.lazyPut<BankAccountOfflineRepository>(
      () => BankAccountOfflineRepository(
        database: Get.find<IsarDatabase>(),
      ),
      fenix: true,
    );

    // PurchaseOrders - Offline Repository (para SyncService)
    Get.lazyPut<PurchaseOrderOfflineRepository>(
      () => PurchaseOrderOfflineRepository(
        database: Get.find<IsarDatabase>(),
      ),
      fenix: true,
    );

    // Inventory - Offline Repository (para SyncService)
    Get.lazyPut<InventoryOfflineRepository>(
      () => InventoryOfflineRepository(
        database: Get.find<IsarDatabase>(),
      ),
      fenix: true,
    );

    // CreditNotes - Offline Repository (para SyncService)
    Get.lazyPut<CreditNoteOfflineRepository>(
      () => CreditNoteOfflineRepository(
        database: Get.find<IsarDatabase>(),
      ),
      fenix: true,
    );

    // CustomerCredits - Offline Repository (para SyncService)
    Get.lazyPut<CustomerCreditOfflineRepository>(
      () => CustomerCreditOfflineRepository(
        database: Get.find<IsarDatabase>(),
      ),
      fenix: true,
    );

    // Organization - Remote DataSource (necesario para FullSyncService)
    if (!Get.isRegistered<OrganizationRemoteDataSource>()) {
      Get.lazyPut<OrganizationRemoteDataSource>(
        () => OrganizationRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
        fenix: true,
      );
    }

    // Organization - Offline Repository (para SyncService)
    Get.lazyPut<OrganizationOfflineRepository>(
      () => OrganizationOfflineRepository(),
      fenix: true,
    );

    // RepositoriesRegistry - Centralized access to all offline repositories
    Get.lazyPut<RepositoriesRegistry>(
      () {
        // Note: We need to check if repositories are registered before accessing them
        return RepositoriesRegistry(
          products: Get.isRegistered<ProductOfflineRepository>()
              ? Get.find<ProductOfflineRepository>()
              : null,
          customers: Get.isRegistered<CustomerOfflineRepository>()
              ? Get.find<CustomerOfflineRepository>()
              : null,
          categories: Get.isRegistered<CategoryOfflineRepository>()
              ? Get.find<CategoryOfflineRepository>()
              : null,
          invoices: Get.isRegistered<InvoiceOfflineRepository>()
              ? Get.find<InvoiceOfflineRepository>()
              : null,
          notifications: Get.isRegistered<NotificationOfflineRepository>()
              ? Get.find<NotificationOfflineRepository>()
              : null,
          // ⭐ FASE 1 - Repositorios adicionales
          inventory: Get.isRegistered<InventoryOfflineRepository>()
              ? Get.find<InventoryOfflineRepository>()
              : null,
          suppliers: Get.isRegistered<SupplierOfflineRepository>()
              ? Get.find<SupplierOfflineRepository>()
              : null,
          expenses: Get.isRegistered<ExpenseOfflineRepository>()
              ? Get.find<ExpenseOfflineRepository>()
              : null,
          bankAccounts: Get.isRegistered<BankAccountOfflineRepository>()
              ? Get.find<BankAccountOfflineRepository>()
              : null,
          purchaseOrders: Get.isRegistered<PurchaseOrderOfflineRepository>()
              ? Get.find<PurchaseOrderOfflineRepository>()
              : null,
          creditNotes: Get.isRegistered<CreditNoteOfflineRepository>()
              ? Get.find<CreditNoteOfflineRepository>()
              : null,
          customerCredits: Get.isRegistered<CustomerCreditOfflineRepository>()
              ? Get.find<CustomerCreditOfflineRepository>()
              : null,
        );
      },
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
    // Guard: evitar doble inicialización si dependencies() se llama más de una vez
    if (Get.isRegistered<SyncService>()) {
      print('🔄 SyncService ya registrado, omitiendo...');
      return;
    }

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

    // FullSyncService - Descarga completa del servidor a ISAR (post-login)
    Get.lazyPut<FullSyncService>(
      () => FullSyncService(Get.find<IsarDatabase>()),
      fenix: true,
    );
    print('✅ FullSyncService registrado');
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

  void _registerIdempotencyService() {
    print('🔑 Registrando servicio de idempotencia...');

    // IdempotencyService como servicio permanente
    Get.put<IdempotencyService>(
      IdempotencyService(),
      permanent: true,
    );

    print('✅ Servicio de idempotencia registrado');
  }

  void _registerConflictResolutionService() {
    print('⚔️ Registrando servicio de resolución de conflictos...');

    // ConflictResolutionService como servicio permanente
    Get.put<ConflictResolutionService>(
      ConflictResolutionService(),
      permanent: true,
    );

    print('✅ Servicio de resolución de conflictos registrado');
  }

  void _registerAtomicTransactionHelper() {
    print('⚛️ Registrando helper de transacciones atómicas...');

    // AtomicTransactionHelper para operaciones compuestas
    Get.lazyPut<AtomicTransactionHelper>(
      () => AtomicTransactionHelper(),
      fenix: true, // Recrear si se elimina
    );

    print('✅ Helper de transacciones atómicas registrado');
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

  void _registerSubscriptionServices() {
    print('📋 Registrando servicios de suscripción...');

    try {
      // Subscription Offline Policy Service
      Get.put<SubscriptionOfflinePolicy>(
        SubscriptionOfflinePolicy(),
        permanent: true,
      );

      // Usar el binding permanente para registrar todos los servicios de suscripción
      SubscriptionPermanentBinding.init();

      print('✅ Servicios de suscripción registrados');
    } catch (e) {
      print('⚠️ Error al registrar servicios de suscripción: $e');
    }
  }

  void _registerUserPreferences() {
    try {
      Get.lazyPut<UserPreferencesRemoteDataSource>(
        () => UserPreferencesRemoteDataSourceImpl(
          dioClient: Get.find<DioClient>(),
        ),
        fenix: true,
      );

      Get.lazyPut<UserPreferencesLocalDataSource>(
        () => UserPreferencesLocalDataSourceImpl(),
        fenix: true,
      );

      Get.lazyPut<UserPreferencesRepository>(
        () => UserPreferencesRepositoryImpl(
          remoteDataSource: Get.find<UserPreferencesRemoteDataSource>(),
          localDataSource: Get.find<UserPreferencesLocalDataSource>(),
          networkInfo: Get.find<NetworkInfo>(),
        ),
        fenix: true,
      );

      Get.lazyPut(
        () => GetUserPreferencesUseCase(Get.find<UserPreferencesRepository>()),
        fenix: true,
      );
      Get.lazyPut(
        () => UpdateUserPreferencesUseCase(Get.find<UserPreferencesRepository>()),
        fenix: true,
      );

      Get.put<UserPreferencesController>(
        UserPreferencesController(
          getUserPreferencesUseCase: Get.find<GetUserPreferencesUseCase>(),
          updateUserPreferencesUseCase: Get.find<UpdateUserPreferencesUseCase>(),
        ),
        permanent: true,
      );

      print('✅ UserPreferencesController registrado permanentemente');
    } catch (e) {
      print('⚠️ Error al registrar UserPreferences: $e');
    }
  }
}