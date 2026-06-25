// lib/features/notifications/presentation/bindings/notification_binding.dart
import 'package:baudex_desktop/app/core/network/dio_client.dart';
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

// Notification Data Layer
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/datasources/notification_local_datasource.dart';
import '../../data/datasources/notification_local_datasource_isar.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../../../app/data/local/isar_database.dart';

// Notification Use Cases
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/get_notification_by_id_usecase.dart';
import '../../domain/usecases/create_notification_usecase.dart';
import '../../domain/usecases/mark_notification_as_read_usecase.dart';
import '../../domain/usecases/mark_all_as_read_usecase.dart';
import '../../domain/usecases/delete_notification_usecase.dart';
import '../../domain/usecases/get_unread_count_usecase.dart';
import '../../domain/usecases/search_notifications_usecase.dart';

// Notification Controllers
import '../controllers/notifications_controller.dart';

class NotificationBinding implements Bindings {
  @override
  void dependencies() {

    try {
      // ==================== STEP 1: VERIFICAR DEPENDENCIAS CORE ====================
      _verifyCoreDependencies();

      // ==================== STEP 2: REGISTRAR DATA LAYER ====================
      _registerDataLayer();

      // ==================== STEP 3: REGISTRAR USE CASES ====================
      _registerUseCases();

      // ==================== STEP 4: REGISTRAR CONTROLLERS ====================
      _registerControllers();

    } catch (e, stackTrace) {
      rethrow;
    }
  }

  /// Verificar dependencias core del sistema
  void _verifyCoreDependencies() {

    final requiredDependencies = <String, bool>{
      'DioClient': Get.isRegistered<DioClient>(),
      'SecureStorageService': Get.isRegistered<SecureStorageService>(),
      'NetworkInfo': Get.isRegistered<NetworkInfo>(),
      'Connectivity': Get.isRegistered<Connectivity>(),
      'IsarDatabase': Get.isRegistered<IsarDatabase>(),
    };

    final missingDependencies =
        requiredDependencies.entries
            .where((entry) => !entry.value)
            .map((entry) => entry.key)
            .toList();

    if (missingDependencies.isNotEmpty) {
      final errorMsg = '''
❌ NotificationBinding Error: Dependencias core faltantes

Dependencias faltantes: ${missingDependencies.join(', ')}

SOLUCIÓN:
1. Asegúrate de que InitialBinding().dependencies() se ejecute ANTES que NotificationBinding
2. Verifica que las dependencias core estén correctamente registradas en InitialBinding
''';

      throw Exception(
        'NotificationBinding requiere InitialBinding. Dependencias faltantes: ${missingDependencies.join(', ')}',
      );
    }

  }

  /// Registrar capa de datos
  void _registerDataLayer() {

    // Remote DataSource
    if (!Get.isRegistered<NotificationRemoteDataSource>()) {
      Get.lazyPut<NotificationRemoteDataSource>(
        () => NotificationRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
        fenix: true,
      );
    }

    // Local DataSource - ISAR Implementation (offline-first)
    if (!Get.isRegistered<NotificationLocalDataSource>()) {
      Get.lazyPut<NotificationLocalDataSource>(
        () => NotificationLocalDataSourceIsar(Get.find<IsarDatabase>()),
        fenix: true,
      );
    }

    // Repository
    if (!Get.isRegistered<NotificationRepository>()) {
      Get.lazyPut<NotificationRepository>(
        () => NotificationRepositoryImpl(
          remoteDataSource: Get.find<NotificationRemoteDataSource>(),
          localDataSource: Get.find<NotificationLocalDataSource>(),
          networkInfo: Get.find<NetworkInfo>(),
        ),
        fenix: true,
      );
    }
  }

  /// Registrar casos de uso
  void _registerUseCases() {

    final repository = Get.find<NotificationRepository>();

    // Read Operations
    Get.lazyPut(() => GetNotificationsUseCase(repository), fenix: true);
    Get.lazyPut(() => GetNotificationByIdUseCase(repository), fenix: true);
    Get.lazyPut(() => GetUnreadCountUseCase(repository), fenix: true);
    Get.lazyPut(() => SearchNotificationsUseCase(repository), fenix: true);

    // Write Operations
    Get.lazyPut(() => CreateNotificationUseCase(repository), fenix: true);
    Get.lazyPut(() => MarkNotificationAsReadUseCase(repository), fenix: true);
    Get.lazyPut(() => MarkAllAsReadUseCase(repository), fenix: true);
    Get.lazyPut(() => DeleteNotificationUseCase(repository), fenix: true);

  }

  /// Registrar controladores
  void _registerControllers() {

    // NotificationsController - PERMANENTE para evitar disposal al navegar
    if (!Get.isRegistered<NotificationsController>()) {
      Get.put<NotificationsController>(
        NotificationsController(
          getNotificationsUseCase: Get.find<GetNotificationsUseCase>(),
          getNotificationByIdUseCase: Get.find<GetNotificationByIdUseCase>(),
          createNotificationUseCase: Get.find<CreateNotificationUseCase>(),
          markAsReadUseCase: Get.find<MarkNotificationAsReadUseCase>(),
          markAllAsReadUseCase: Get.find<MarkAllAsReadUseCase>(),
          deleteNotificationUseCase: Get.find<DeleteNotificationUseCase>(),
          getUnreadCountUseCase: Get.find<GetUnreadCountUseCase>(),
          searchNotificationsUseCase: Get.find<SearchNotificationsUseCase>(),
        ),
        permanent: true, // ✅ PERMANENTE para evitar disposal al navegar
      );
    }
  }

  @override
  void onDispose() {

    try {
      // Controllers
      _cleanupControllers();

      // Use Cases
      _cleanupUseCases();

      // Data Layer (opcional, ya que son fenix)
      _cleanupDataLayer();

    } catch (e) {
    }
  }

  void _cleanupControllers() {
    try {
      if (Get.isRegistered<NotificationsController>()) {
        Get.delete<NotificationsController>(force: true);
      }
    } catch (e) {
    }
  }

  void _cleanupUseCases() {
    final useCases = [
      () => Get.delete<GetNotificationsUseCase>(force: true),
      () => Get.delete<GetNotificationByIdUseCase>(force: true),
      () => Get.delete<GetUnreadCountUseCase>(force: true),
      () => Get.delete<SearchNotificationsUseCase>(force: true),
      () => Get.delete<CreateNotificationUseCase>(force: true),
      () => Get.delete<MarkNotificationAsReadUseCase>(force: true),
      () => Get.delete<MarkAllAsReadUseCase>(force: true),
      () => Get.delete<DeleteNotificationUseCase>(force: true),
    ];

    final names = [
      'GetNotificationsUseCase',
      'GetNotificationByIdUseCase',
      'GetUnreadCountUseCase',
      'SearchNotificationsUseCase',
      'CreateNotificationUseCase',
      'MarkNotificationAsReadUseCase',
      'MarkAllAsReadUseCase',
      'DeleteNotificationUseCase',
    ];

    for (int i = 0; i < useCases.length; i++) {
      try {
        useCases[i]();
      } catch (e) {
      }
    }
  }

  void _cleanupDataLayer() {
    try {
      if (Get.isRegistered<NotificationRepository>()) {
        Get.delete<NotificationRepository>(force: true);
      }
    } catch (e) {
    }

    try {
      if (Get.isRegistered<NotificationRemoteDataSource>()) {
        Get.delete<NotificationRemoteDataSource>(force: true);
      }
    } catch (e) {
    }

    try {
      if (Get.isRegistered<NotificationLocalDataSource>()) {
        Get.delete<NotificationLocalDataSource>(force: true);
      }
    } catch (e) {
    }
  }

  // ==================== MÉTODOS DE UTILIDAD ====================

  /// Verificar si todas las dependencias están registradas
  static bool get isFullyInitialized {
    return Get.isRegistered<NotificationRepository>() &&
        Get.isRegistered<NotificationsController>() &&
        Get.isRegistered<GetNotificationsUseCase>() &&
        Get.isRegistered<CreateNotificationUseCase>();
  }

  /// Verificar dependencias específicas
  static void verifyDependencies() {

    final dependencies = {
      // Core Dependencies
      'DioClient': Get.isRegistered<DioClient>(),
      'SecureStorageService': Get.isRegistered<SecureStorageService>(),
      'NetworkInfo': Get.isRegistered<NetworkInfo>(),
      'Connectivity': Get.isRegistered<Connectivity>(),
      'IsarDatabase': Get.isRegistered<IsarDatabase>(),

      // Notification Dependencies
      'NotificationRepository': Get.isRegistered<NotificationRepository>(),
      'NotificationsController': Get.isRegistered<NotificationsController>(),

      // Notification Use Cases
      'GetNotificationsUseCase': Get.isRegistered<GetNotificationsUseCase>(),
      'CreateNotificationUseCase': Get.isRegistered<CreateNotificationUseCase>(),
      'MarkNotificationAsReadUseCase':
          Get.isRegistered<MarkNotificationAsReadUseCase>(),
      'GetUnreadCountUseCase': Get.isRegistered<GetUnreadCountUseCase>(),
    };

    dependencies.forEach((name, isRegistered) {
      final status = isRegistered ? '✅' : '❌';
    });

    final allCoreRegistered = [
      'DioClient',
      'NotificationRepository',
      'NotificationsController',
    ].every((key) => dependencies[key] == true);

    final statusMsg =
        allCoreRegistered
            ? '✅ DEPENDENCIAS CORE REGISTRADAS'
            : '❌ FALTAN DEPENDENCIAS CORE';

  }

  /// Obtener información de estado para debugging
  static Map<String, dynamic> getDebugInfo() {
    return {
      'isFullyInitialized': isFullyInitialized,
      'registeredControllers': {
        'NotificationsController': Get.isRegistered<NotificationsController>(),
      },
      'registeredUseCases': {
        'GetNotificationsUseCase': Get.isRegistered<GetNotificationsUseCase>(),
        'CreateNotificationUseCase':
            Get.isRegistered<CreateNotificationUseCase>(),
        'MarkNotificationAsReadUseCase':
            Get.isRegistered<MarkNotificationAsReadUseCase>(),
        'GetUnreadCountUseCase': Get.isRegistered<GetUnreadCountUseCase>(),
      },
    };
  }

  /// Imprimir información de debugging
  static void printDebugInfo() {
    final info = getDebugInfo();
  }
}
