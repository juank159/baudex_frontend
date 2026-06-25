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

    // ==================== CORE DEPENDENCIES ====================
    _registerCoreDependencies();

    // ==================== OFFLINE INFRASTRUCTURE ====================
    _registerOfflineInfrastructure();

  }

  void _registerCoreDependencies() {

    // External dependencies
    Get.lazyPut<Dio>(() => Dio(), fenix: true);
    Get.lazyPut<FlutterSecureStorage>(() => const FlutterSecureStorage(), fenix: true);
    Get.lazyPut<Connectivity>(() => Connectivity(), fenix: true);

  }

  void _registerOfflineInfrastructure() {

    // ISAR Database (singleton)
    Get.put<IsarDatabase>(IsarDatabase.instance, permanent: true);

    // Simplified Registry
    Get.lazyPut<RepositoriesRegistry>(() => RepositoriesRegistry.instance, fenix: true);

  }
}