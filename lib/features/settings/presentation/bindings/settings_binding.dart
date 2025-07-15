// lib/features/settings/presentation/bindings/settings_binding.dart
import 'package:get/get.dart';
import '../../../../app/core/database/isar_service.dart';
import '../../data/datasources/settings_local_datasource.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/get_app_settings_usecase.dart';
import '../../domain/usecases/save_app_settings_usecase.dart';
import '../../domain/usecases/get_invoice_settings_usecase.dart';
import '../../domain/usecases/save_invoice_settings_usecase.dart';
import '../../domain/usecases/get_printer_settings_usecase.dart';
import '../../domain/usecases/save_printer_settings_usecase.dart';
import '../controllers/settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    print('🔧 SettingsBinding: Registrando dependencias...');

    // Core Services
    _registerCoreServices();

    // Data Sources
    _registerDataSources();

    // Repositories
    _registerRepositories();

    // Use Cases
    _registerUseCases();

    // Controllers
    _registerControllers();

    print('✅ SettingsBinding: Todas las dependencias registradas exitosamente');
  }

  void _registerCoreServices() {
    // Isar Service (Singleton)
    if (!Get.isRegistered<IsarService>()) {
      Get.put<IsarService>(IsarService.instance, permanent: true);
      print('✅ IsarService registrado como singleton');
    }
  }

  void _registerDataSources() {
    // Settings Local DataSource
    if (!Get.isRegistered<SettingsLocalDataSource>()) {
      Get.lazyPut<SettingsLocalDataSource>(
        () => SettingsLocalDataSourceImpl(
          isarService: Get.find<IsarService>(),
        ),
      );
      print('✅ SettingsLocalDataSource registrado');
    }
  }

  void _registerRepositories() {
    // Settings Repository
    if (!Get.isRegistered<SettingsRepository>()) {
      Get.lazyPut<SettingsRepository>(
        () => SettingsRepositoryImpl(
          localDataSource: Get.find<SettingsLocalDataSource>(),
        ),
      );
      print('✅ SettingsRepository registrado');
    }
  }

  void _registerUseCases() {
    // App Settings Use Cases
    if (!Get.isRegistered<GetAppSettingsUseCase>()) {
      Get.lazyPut<GetAppSettingsUseCase>(
        () => GetAppSettingsUseCase(Get.find<SettingsRepository>()),
      );
    }

    if (!Get.isRegistered<SaveAppSettingsUseCase>()) {
      Get.lazyPut<SaveAppSettingsUseCase>(
        () => SaveAppSettingsUseCase(Get.find<SettingsRepository>()),
      );
    }

    // Invoice Settings Use Cases
    if (!Get.isRegistered<GetInvoiceSettingsUseCase>()) {
      Get.lazyPut<GetInvoiceSettingsUseCase>(
        () => GetInvoiceSettingsUseCase(Get.find<SettingsRepository>()),
      );
    }

    if (!Get.isRegistered<SaveInvoiceSettingsUseCase>()) {
      Get.lazyPut<SaveInvoiceSettingsUseCase>(
        () => SaveInvoiceSettingsUseCase(Get.find<SettingsRepository>()),
      );
    }

    // Printer Settings Use Cases
    if (!Get.isRegistered<GetAllPrinterSettingsUseCase>()) {
      Get.lazyPut<GetAllPrinterSettingsUseCase>(
        () => GetAllPrinterSettingsUseCase(Get.find<SettingsRepository>()),
      );
    }

    if (!Get.isRegistered<GetDefaultPrinterSettingsUseCase>()) {
      Get.lazyPut<GetDefaultPrinterSettingsUseCase>(
        () => GetDefaultPrinterSettingsUseCase(Get.find<SettingsRepository>()),
      );
    }

    if (!Get.isRegistered<SavePrinterSettingsUseCase>()) {
      Get.lazyPut<SavePrinterSettingsUseCase>(
        () => SavePrinterSettingsUseCase(Get.find<SettingsRepository>()),
      );
    }

    if (!Get.isRegistered<DeletePrinterSettingsUseCase>()) {
      Get.lazyPut<DeletePrinterSettingsUseCase>(
        () => DeletePrinterSettingsUseCase(Get.find<SettingsRepository>()),
      );
    }

    if (!Get.isRegistered<SetDefaultPrinterUseCase>()) {
      Get.lazyPut<SetDefaultPrinterUseCase>(
        () => SetDefaultPrinterUseCase(Get.find<SettingsRepository>()),
      );
    }

    if (!Get.isRegistered<TestPrinterConnectionUseCase>()) {
      Get.lazyPut<TestPrinterConnectionUseCase>(
        () => TestPrinterConnectionUseCase(Get.find<SettingsRepository>()),
      );
    }

    print('✅ Casos de uso registrados');
  }

  void _registerControllers() {
    // Settings Controller
    if (!Get.isRegistered<SettingsController>()) {
      Get.lazyPut<SettingsController>(
        () => SettingsController(
          getAppSettingsUseCase: Get.find<GetAppSettingsUseCase>(),
          saveAppSettingsUseCase: Get.find<SaveAppSettingsUseCase>(),
          getInvoiceSettingsUseCase: Get.find<GetInvoiceSettingsUseCase>(),
          saveInvoiceSettingsUseCase: Get.find<SaveInvoiceSettingsUseCase>(),
          getAllPrinterSettingsUseCase: Get.find<GetAllPrinterSettingsUseCase>(),
          getDefaultPrinterSettingsUseCase: Get.find<GetDefaultPrinterSettingsUseCase>(),
          savePrinterSettingsUseCase: Get.find<SavePrinterSettingsUseCase>(),
          deletePrinterSettingsUseCase: Get.find<DeletePrinterSettingsUseCase>(),
          setDefaultPrinterUseCase: Get.find<SetDefaultPrinterUseCase>(),
          testPrinterConnectionUseCase: Get.find<TestPrinterConnectionUseCase>(),
        ),
      );
      print('✅ SettingsController registrado');
    }
  }

  /// Método estático para verificar si las dependencias base están registradas
  static bool areBaseDependenciesRegistered() {
    return Get.isRegistered<IsarService>() &&
        Get.isRegistered<SettingsLocalDataSource>() &&
        Get.isRegistered<SettingsRepository>();
  }

  /// Método estático para registrar solo el controlador si las dependencias ya existen
  static void registerControllerOnly() {
    if (areBaseDependenciesRegistered() && !Get.isRegistered<SettingsController>()) {
      final binding = SettingsBinding();
      binding._registerUseCases();
      binding._registerControllers();
      print('✅ SettingsController registrado independientemente');
    }
  }
}