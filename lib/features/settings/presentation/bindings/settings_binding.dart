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
    // Settings Local DataSource (permanent: dependencia del SettingsController global)
    if (!Get.isRegistered<SettingsLocalDataSource>()) {
      Get.put<SettingsLocalDataSource>(
        SettingsLocalDataSourceImpl(),
        permanent: true,
      );
      print('✅ SettingsLocalDataSource registrado (permanent)');
    }

    // Organization Remote DataSource (permanent: dependencia del repo/controller global)
    if (!Get.isRegistered<OrganizationRemoteDataSource>()) {
      Get.put<OrganizationRemoteDataSource>(
        OrganizationRemoteDataSourceImpl(
          dioClient: Get.find(),
        ),
        permanent: true,
      );
      print('✅ OrganizationRemoteDataSource registrado (permanent)');
    }

    // Printer Settings Remote DataSource (permanent: dependencia del SettingsController global)
    if (!Get.isRegistered<PrinterSettingsRemoteDataSource>()) {
      Get.put<PrinterSettingsRemoteDataSource>(
        PrinterSettingsRemoteDataSourceImpl(
          dioClient: Get.find(),
        ),
        permanent: true,
      );
      print('✅ PrinterSettingsRemoteDataSource registrado (permanent)');
    }
  }

  void _registerRepositories() {
    // Settings Repository (permanent: dependencia del SettingsController global)
    if (!Get.isRegistered<SettingsRepository>()) {
      PrinterSettingsRemoteDataSource? printerRemoteDS;
      try {
        printerRemoteDS = Get.find<PrinterSettingsRemoteDataSource>();
      } catch (_) {
        print('⚠️ PrinterSettingsRemoteDataSource no disponible - modo offline');
      }

      Get.put<SettingsRepository>(
        SettingsRepositoryImpl(
          localDataSource: Get.find<SettingsLocalDataSource>(),
          printerRemoteDataSource: printerRemoteDS,
          networkInfo: Get.isRegistered<NetworkInfo>() ? Get.find<NetworkInfo>() : null,
        ),
        permanent: true,
      );
      print('✅ SettingsRepository registrado (permanent)');
    }

    // Organization Repository (permanent: dependencia de OrganizationController global)
    if (!Get.isRegistered<OrganizationRepository>()) {
      Get.put<OrganizationRepository>(
        OrganizationRepositoryImpl(
          remoteDataSource: Get.find<OrganizationRemoteDataSource>(),
          networkInfo: Get.find<NetworkInfo>(),
          offlineRepository: OrganizationOfflineRepository(),
        ),
        permanent: true,
      );
      print('✅ OrganizationRepository registrado (permanent)');
    }
  }

  void _registerUseCases() {
    final repo = Get.find<SettingsRepository>();

    if (!Get.isRegistered<GetAppSettingsUseCase>()) {
      Get.put(GetAppSettingsUseCase(repo), permanent: true);
    }
    if (!Get.isRegistered<SaveAppSettingsUseCase>()) {
      Get.put(SaveAppSettingsUseCase(repo), permanent: true);
    }
    if (!Get.isRegistered<GetInvoiceSettingsUseCase>()) {
      Get.put(GetInvoiceSettingsUseCase(repo), permanent: true);
    }
    if (!Get.isRegistered<SaveInvoiceSettingsUseCase>()) {
      Get.put(SaveInvoiceSettingsUseCase(repo), permanent: true);
    }
    if (!Get.isRegistered<GetAllPrinterSettingsUseCase>()) {
      Get.put(GetAllPrinterSettingsUseCase(repo), permanent: true);
    }
    if (!Get.isRegistered<GetDefaultPrinterSettingsUseCase>()) {
      Get.put(GetDefaultPrinterSettingsUseCase(repo), permanent: true);
    }
    if (!Get.isRegistered<SavePrinterSettingsUseCase>()) {
      Get.put(SavePrinterSettingsUseCase(repo), permanent: true);
    }
    if (!Get.isRegistered<DeletePrinterSettingsUseCase>()) {
      Get.put(DeletePrinterSettingsUseCase(repo), permanent: true);
    }
    if (!Get.isRegistered<SetDefaultPrinterUseCase>()) {
      Get.put(SetDefaultPrinterUseCase(repo), permanent: true);
    }
    if (!Get.isRegistered<TestPrinterConnectionUseCase>()) {
      Get.put(TestPrinterConnectionUseCase(repo), permanent: true);
    }

    print('✅ Casos de uso registrados (permanent)');
  }

  void _registerControllers() {
    // Settings Controller (permanent: ThermalPrinterController lo necesita al imprimir desde cualquier pantalla)
    if (!Get.isRegistered<SettingsController>()) {
      Get.put<SettingsController>(
        SettingsController(
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
        permanent: true,
      );
      print('✅ SettingsController registrado (permanent)');
    }

    // Organization Controller (permanent: usado globalmente por suscripción, settings, multi-moneda)
    if (!Get.isRegistered<OrganizationController>()) {
      Get.put<OrganizationController>(
        OrganizationController(
          Get.find<OrganizationRepository>(),
        ),
        permanent: true,
      );
      print('✅ OrganizationController registrado (permanent)');
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
