// lib/app/simple_app_binding.dart
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'data/local/isar_database.dart';
import 'data/local/repositories_registry.dart';

class SimpleAppBinding implements Bindings {
  @override
  void dependencies() {
    print('🚀 SimpleAppBinding: Iniciando dependencias básicas offline-first...');

    // ==================== CORE DEPENDENCIES ====================
    _registerCoreDependencies();

    // ==================== OFFLINE INFRASTRUCTURE ====================
    _registerOfflineInfrastructure();

    print('✅ SimpleAppBinding: Dependencias básicas registradas exitosamente');
  }

  void _registerCoreDependencies() {
    print('📦 Registrando dependencias core básicas...');

    // External dependencies
    Get.lazyPut<Dio>(() => Dio(), fenix: true);
    Get.lazyPut<FlutterSecureStorage>(() => const FlutterSecureStorage(), fenix: true);
    Get.lazyPut<Connectivity>(() => Connectivity(), fenix: true);

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
}