// lib/features/settings/presentation/bindings/settings_binding.dart
import 'package:get/get.dart';
import '../../../../app/core/network/network_info.dart';
import '../../data/datasources/settings_local_datasource.dart';
import '../../data/datasources/organization_remote_datasource.dart';
import '../../data/datasources/printer_settings_remote_datasource.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/repositories/organization_repository_impl.dart';
import '../../data/repositories/organization_offline_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/organization_repository.dart';
import '../../domain/usecases/get_app_settings_usecase.dart';
import '../../domain/usecases/save_app_settings_usecase.dart';
import '../../domain/usecases/get_invoice_settings_usecase.dart';
import '../../domain/usecases/save_invoice_settings_usecase.dart';
import '../../domain/usecases/get_printer_settings_usecase.dart';
import '../../domain/usecases/save_printer_settings_usecase.dart';
import '../controllers/settings_controller.dart';
import '../controllers/organization_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    print('🔧 SettingsBinding: Registrando dependencias...');

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

  void _registerDataSources() {
    // Settings Local DataSource
    if (!Get.isRegistered<SettingsLocalDataSource>()) {
      Get.lazyPut<SettingsLocalDataSource>(
        () => SettingsLocalDataSourceImpl(),
      );
      print('✅ SettingsLocalDataSource registrado');
    }

    // Organization Remote DataSource
    if (!Get.isRegistered<OrganizationRemoteDataSource>()) {
      Get.lazyPut<OrganizationRemoteDataSource>(
        () => OrganizationRemoteDataSourceImpl(
          dioClient: Get.find(),
        ),
      );
      print('✅ OrganizationRemoteDataSource registrado');
    }

    // Printer Settings Remote DataSource
    if (!Get.isRegistered<PrinterSettingsRemoteDataSource>()) {
      Get.lazyPut<PrinterSettingsRemoteDataSource>(
        () => PrinterSettingsRemoteDataSourceImpl(
          dioClient: Get.find(),
        ),
      );
      print('✅ PrinterSettingsRemoteDataSource registrado');
    }
  }

  void _registerRepositories() {
    // Settings Repository
    if (!Get.isRegistered<SettingsRepository>()) {
      Get.lazyPut<SettingsRepository>(
        () {
          // Obtener remote datasource de forma segura
          PrinterSettingsRemoteDataSource? printerRemoteDS;
          try {
            if (Get.isRegistered<PrinterSettingsRemoteDataSource>()) {
              printerRemoteDS = Get.find<PrinterSettingsRemoteDataSource>();
            } else {
              printerRemoteDS = PrinterSettingsRemoteDataSourceImpl(
                dioClient: Get.find(),
              );
            }
          } catch (_) {
            print('⚠️ PrinterSettingsRemoteDataSource no disponible - modo offline');
          }

          return SettingsRepositoryImpl(
            localDataSource: Get.find<SettingsLocalDataSource>(),
            printerRemoteDataSource: printerRemoteDS,
            networkInfo: Get.isRegistered<NetworkInfo>() ? Get.find<NetworkInfo>() : null,
          );
        },
      );
      print('✅ SettingsRepository registrado');
    }

    // Organization Repository
    if (!Get.isRegistered<OrganizationRepository>()) {
      Get.lazyPut<OrganizationRepository>(
        () => OrganizationRepositoryImpl(
          remoteDataSource: Get.find<OrganizationRemoteDataSource>(),
          networkInfo: Get.find<NetworkInfo>(),
          offlineRepository: OrganizationOfflineRepository(),
        ),
      );
      print('✅ OrganizationRepository registrado');
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

    // Organization Controller
    if (!Get.isRegistered<OrganizationController>()) {
      Get.lazyPut<OrganizationController>(
        () => OrganizationController(
          Get.find<OrganizationRepository>(),
        ),
      );
      print('✅ OrganizationController registrado');
    }
  }

  /// Método estático para verificar si las dependencias base están registradas
  static bool areBaseDependenciesRegistered() {
    return Get.isRegistered<SettingsLocalDataSource>() &&
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
