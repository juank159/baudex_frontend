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
import 'shared/controllers/app_drawer_controller.dart';
import '../features/auth/presentation/bindings/auth_binding_stub.dart';
import '../features/settings/presentation/bindings/settings_binding.dart';
import 'services/sync_service.dart';

class InitialBinding implements Bindings {
  @override
  void dependencies() {
    print('🚀 SimpleAppBinding: Iniciando dependencias básicas offline-first...');

    // ==================== CORE DEPENDENCIES ====================
    _registerCoreDependencies();

    // ==================== OFFLINE INFRASTRUCTURE ====================
    _registerOfflineInfrastructure();

    // ==================== AUTH CONTROLLER ====================
    _registerAuthController();

    // ==================== SETTINGS CONTROLLER ====================
    _registerSettingsController();

    // ==================== SYNC SERVICE ====================
    _registerSyncService();

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
    print('🔄 Registrando servicio de sincronización...');

    // SyncService now uses lazy dependency resolution
    Get.put<SyncService>(
      SyncService(),
      permanent: true,
    );

    print('✅ Servicio de sincronización registrado');
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