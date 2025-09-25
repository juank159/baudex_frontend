// lib/app/services/sync_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import '../../features/products/data/repositories/product_repository_impl.dart';
import '../core/network/network_info.dart';

/// Servicio para sincronización automática cuando se restaura la conexión
class SyncService extends GetxService {
  // Dependencies will be resolved lazily
  NetworkInfo? _networkInfo;
  ProductRepositoryImpl? _productRepository;
  Connectivity? _connectivity;

  // Stream subscription para monitorear cambios de conectividad
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Estado interno
  final _isConnected = false.obs;
  final _isSyncing = false.obs;
  final _lastSyncTime = Rxn<DateTime>();

  SyncService();

  // Getters
  bool get isConnected => _isConnected.value;
  bool get isSyncing => _isSyncing.value;
  DateTime? get lastSyncTime => _lastSyncTime.value;

  // Lazy dependency resolution
  NetworkInfo? get _networkInfoSafe {
    _networkInfo ??= Get.isRegistered<NetworkInfo>() ? Get.find<NetworkInfo>() : null;
    return _networkInfo;
  }

  ProductRepositoryImpl? get _productRepositorySafe {
    _productRepository ??= Get.isRegistered<ProductRepositoryImpl>() ? Get.find<ProductRepositoryImpl>() : null;
    return _productRepository;
  }

  Connectivity? get _connectivitySafe {
    _connectivity ??= Get.isRegistered<Connectivity>() ? Get.find<Connectivity>() : null;
    return _connectivity;
  }

  @override
  void onInit() {
    super.onInit();
    print('🔄 SyncService: Iniciando servicio de sincronización...');
    _startConnectivityMonitoring();
  }

  @override
  void onClose() {
    print('🔄 SyncService: Deteniendo servicio de sincronización...');
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  /// Iniciar monitoreo de conectividad
  void _startConnectivityMonitoring() {
    print('📡 SyncService: Iniciando monitoreo de conectividad...');

    // Verificar estado inicial
    _checkInitialConnectivity();

    // Escuchar cambios de conectividad
    final connectivity = _connectivitySafe;
    if (connectivity != null) {
      _connectivitySubscription = connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error) {
          print('❌ SyncService: Error en monitoreo de conectividad: $error');
        },
      );
    } else {
      print('⚠️ SyncService: Connectivity no disponible - omitiendo monitoreo');
    }
  }

  /// Verificar conectividad inicial
  void _checkInitialConnectivity() async {
    try {
      final networkInfo = _networkInfoSafe;
      if (networkInfo != null) {
        final isConnected = await networkInfo.isConnected;
        _isConnected.value = isConnected;
        print('📡 SyncService: Estado inicial de conectividad: $isConnected');
      } else {
        print('⚠️ SyncService: NetworkInfo no disponible');
        _isConnected.value = false;
      }
    } catch (e) {
      print('⚠️ SyncService: Error verificando conectividad inicial: $e');
      _isConnected.value = false;
    }
  }

  /// Manejar cambios de conectividad
  void _onConnectivityChanged(List<ConnectivityResult> results) async {
    try {
      // Verificar si hay alguna conexión válida
      final hasConnection = results.any((result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet);

      final wasConnected = _isConnected.value;
      _isConnected.value = hasConnection;

      print('📡 SyncService: Cambio de conectividad detectado: $hasConnection');
      print('   Resultados: ${results.map((r) => r.name).join(', ')}');

      // Si se restauró la conexión, iniciar sincronización automática
      if (!wasConnected && hasConnection) {
        print('🌐 SyncService: Conexión restaurada - iniciando sincronización automática...');
        await _performAutoSync();
      }
    } catch (e) {
      print('❌ SyncService: Error procesando cambio de conectividad: $e');
    }
  }

  /// Realizar sincronización automática
  Future<void> _performAutoSync() async {
    if (_isSyncing.value) {
      print('⏳ SyncService: Sincronización ya en progreso, omitiendo...');
      return;
    }

    _isSyncing.value = true;

    try {
      print('🔄 SyncService: Iniciando sincronización automática...');

      // Sincronizar productos offline
      final productRepository = _productRepositorySafe;
      if (productRepository == null) {
        print('⚠️ SyncService: ProductRepository no disponible - omitiendo sincronización');
        return;
      }

      final result = await productRepository.syncOfflineProducts();

      result.fold(
        (failure) {
          print('❌ SyncService: Error en sincronización automática: ${failure.message}');
          _showSyncErrorNotification(failure.message);
        },
        (syncedProducts) {
          if (syncedProducts.isNotEmpty) {
            print('✅ SyncService: Sincronización completada exitosamente');
            print('   Productos sincronizados: ${syncedProducts.length}');
            _lastSyncTime.value = DateTime.now();
            _showSyncSuccessNotification(syncedProducts.length);
          } else {
            print('ℹ️ SyncService: No hay productos para sincronizar');
          }
        },
      );
    } catch (e) {
      print('💥 SyncService: Error inesperado durante sincronización: $e');
      _showSyncErrorNotification('Error inesperado: $e');
    } finally {
      _isSyncing.value = false;
    }
  }

  /// Forzar sincronización manual
  Future<void> forceSyncNow() async {
    if (!_isConnected.value) {
      print('📵 SyncService: No hay conexión disponible para sincronización manual');
      _showSyncErrorNotification('No hay conexión a internet');
      return;
    }

    print('🔄 SyncService: Iniciando sincronización manual...');
    await _performAutoSync();
  }

  /// Verificar si hay datos pendientes de sincronización
  Future<bool> hasPendingData() async {
    try {
      final productRepository = _productRepositorySafe;
      if (productRepository == null) return false;

      final result = await productRepository.getUnsyncedProducts();
      return result.fold(
        (failure) => false,
        (products) => products.isNotEmpty,
      );
    } catch (e) {
      print('⚠️ SyncService: Error verificando datos pendientes: $e');
      return false;
    }
  }

  /// Obtener cantidad de elementos pendientes
  Future<int> getPendingCount() async {
    try {
      final productRepository = _productRepositorySafe;
      if (productRepository == null) return 0;

      final result = await productRepository.getUnsyncedProducts();
      return result.fold(
        (failure) => 0,
        (products) => products.length,
      );
    } catch (e) {
      print('⚠️ SyncService: Error obteniendo count pendiente: $e');
      return 0;
    }
  }

  /// Mostrar notificación de éxito
  void _showSyncSuccessNotification(int count) {
    if (Get.isSnackbarOpen) return;

    Get.snackbar(
      '✅ Sincronización Exitosa',
      '$count producto(s) sincronizado(s) con el servidor',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      backgroundColor: Get.theme.colorScheme.surface,
      colorText: Get.theme.colorScheme.onSurface,
    );
  }

  /// Mostrar notificación de error
  void _showSyncErrorNotification(String message) {
    if (Get.isSnackbarOpen) return;

    Get.snackbar(
      '❌ Error de Sincronización',
      message,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 5),
      backgroundColor: Get.theme.colorScheme.errorContainer,
      colorText: Get.theme.colorScheme.onErrorContainer,
    );
  }

  /// Reiniciar servicio (útil para debugging)
  void restart() {
    print('🔄 SyncService: Reiniciando servicio...');
    _connectivitySubscription?.cancel();
    _startConnectivityMonitoring();
  }

  /// Debug: Información del estado actual
  Map<String, dynamic> getDebugInfo() {
    return {
      'isConnected': _isConnected.value,
      'isSyncing': _isSyncing.value,
      'lastSyncTime': _lastSyncTime.value?.toIso8601String(),
      'hasSubscription': _connectivitySubscription != null,
    };
  }
}