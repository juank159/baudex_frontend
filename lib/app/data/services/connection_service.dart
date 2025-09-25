// lib/app/data/services/connection_service.dart
import 'dart:async';
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'sync_service.dart';

enum ConnectionStatus { connected, disconnected, checking }

/// Service for managing network connectivity and automatic synchronization
class ConnectionService extends GetxController {
  final NetworkInfo _networkInfo;
  final SyncService _syncService;
  final Connectivity _connectivity = Connectivity();

  // Observables
  final _connectionStatus = ConnectionStatus.checking.obs;
  final _connectionType = ConnectivityResult.none.obs;
  final _autoSyncOnConnection = true.obs;
  final _showConnectionNotifications = true.obs;

  // Private fields
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _connectionCheckTimer;
  bool _wasDisconnected = false;
  DateTime? _lastConnectionCheck;
  DateTime? _lastAutoSync;

  // Configuration
  static const Duration _connectionCheckInterval = Duration(seconds: 30);
  static const Duration _autoSyncCooldown = Duration(minutes: 2);

  ConnectionService(this._networkInfo, this._syncService);

  // Getters
  ConnectionStatus get connectionStatus => _connectionStatus.value;
  ConnectivityResult get connectionType => _connectionType.value;
  bool get isConnected => _connectionStatus.value == ConnectionStatus.connected;
  bool get isDisconnected =>
      _connectionStatus.value == ConnectionStatus.disconnected;
  bool get autoSyncOnConnection => _autoSyncOnConnection.value;
  bool get showConnectionNotifications => _showConnectionNotifications.value;

  @override
  void onInit() {
    super.onInit();
    _initializeConnectionMonitoring();
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    _connectionCheckTimer?.cancel();
    super.onClose();
  }

  /// Initialize connection monitoring
  Future<void> _initializeConnectionMonitoring() async {
    // Check initial connection status
    await _checkConnectionStatus();

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (error) {
        Get.log('Connection monitoring error: $error', isError: true);
      },
    );

    // Start periodic connection checks
    _startPeriodicConnectionCheck();
  }

  /// Start periodic connection checking
  void _startPeriodicConnectionCheck() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = Timer.periodic(_connectionCheckInterval, (_) {
      _checkConnectionStatus();
    });
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) async {
    // Take the first result or default to none if empty
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    _connectionType.value = result;

    // Give the connection a moment to stabilize
    await Future.delayed(const Duration(seconds: 2));

    await _checkConnectionStatus();
  }

  /// Check actual internet connectivity (not just network interface)
  Future<void> _checkConnectionStatus() async {
    _connectionStatus.value = ConnectionStatus.checking;
    _lastConnectionCheck = DateTime.now();

    try {
      final isConnected = await _networkInfo.isConnected;
      final newStatus =
          isConnected
              ? ConnectionStatus.connected
              : ConnectionStatus.disconnected;

      // Handle connection state changes
      if (_connectionStatus.value != newStatus) {
        _onConnectionStatusChanged(newStatus);
      }

      _connectionStatus.value = newStatus;
    } catch (e) {
      Get.log('Connection check failed: $e', isError: true);
      _connectionStatus.value = ConnectionStatus.disconnected;
    }
  }

  /// Handle connection status changes
  void _onConnectionStatusChanged(ConnectionStatus newStatus) {
    if (newStatus == ConnectionStatus.connected && _wasDisconnected) {
      _onConnectionRestored();
    } else if (newStatus == ConnectionStatus.disconnected) {
      _onConnectionLost();
    }
  }

  /// Handle connection restored
  void _onConnectionRestored() {
    _wasDisconnected = false;

    Get.log('Connection restored');

    if (_showConnectionNotifications.value) {
      _showConnectionNotification(
        title: 'Conexión Restaurada',
        message: 'Conectado a internet',
        isSuccess: true,
      );
    }

    // Trigger auto-sync if enabled
    if (_autoSyncOnConnection.value) {
      _triggerAutoSync();
    }
  }

  /// Handle connection lost
  void _onConnectionLost() {
    _wasDisconnected = true;

    Get.log('Connection lost');

    if (_showConnectionNotifications.value) {
      _showConnectionNotification(
        title: 'Sin Conexión',
        message: 'Trabajando sin conexión a internet',
        isSuccess: false,
      );
    }
  }

  /// Trigger automatic synchronization
  void _triggerAutoSync() async {
    // Check cooldown period
    if (_lastAutoSync != null) {
      final timeSinceLastSync = DateTime.now().difference(_lastAutoSync!);
      if (timeSinceLastSync < _autoSyncCooldown) {
        Get.log('Auto-sync skipped due to cooldown period');
        return;
      }
    }

    // Check if sync is needed
    final needsSync = await _syncService.needsSync();
    if (!needsSync) {
      Get.log('Auto-sync skipped - no pending changes');
      return;
    }

    Get.log('Triggering auto-sync...');
    _lastAutoSync = DateTime.now();

    try {
      final result = await _syncService.syncAll(showProgress: false);

      if (result.isSuccess && _showConnectionNotifications.value) {
        _showConnectionNotification(
          title: 'Sincronización Completada',
          message: '${result.syncedEntities} elementos sincronizados',
          isSuccess: true,
        );
      } else if (result.hasErrors && _showConnectionNotifications.value) {
        _showConnectionNotification(
          title: 'Sincronización Parcial',
          message:
              '${result.syncedEntities}/${result.totalEntities} elementos sincronizados',
          isSuccess: false,
        );
      }
    } catch (e) {
      Get.log('Auto-sync failed: $e', isError: true);
    }
  }

  /// Force connection check
  Future<void> forceConnectionCheck() async {
    await _checkConnectionStatus();
  }

  /// Force sync if connected
  Future<void> forceSyncIfConnected() async {
    if (isConnected) {
      await _syncService.forceSync();
    } else {
      _showConnectionNotification(
        title: 'Sin Conexión',
        message: 'No se puede sincronizar sin conexión a internet',
        isSuccess: false,
      );
    }
  }

  /// Enable/disable auto-sync on connection
  void setAutoSyncOnConnection(bool enabled) {
    _autoSyncOnConnection.value = enabled;
    Get.log('Auto-sync on connection ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Enable/disable connection notifications
  void setShowConnectionNotifications(bool enabled) {
    _showConnectionNotifications.value = enabled;
    Get.log('Connection notifications ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Get connection information
  Map<String, dynamic> getConnectionInfo() {
    return {
      'status': _connectionStatus.value.name,
      'type': _connectionType.value.name,
      'lastCheck': _lastConnectionCheck?.toIso8601String(),
      'lastAutoSync': _lastAutoSync?.toIso8601String(),
      'autoSyncEnabled': _autoSyncOnConnection.value,
      'notificationsEnabled': _showConnectionNotifications.value,
      'wasDisconnected': _wasDisconnected,
    };
  }

  /// Show connection notification
  void _showConnectionNotification({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    Get.snackbar(
      title,
      message,
      duration: const Duration(seconds: 3),
      backgroundColor:
          isSuccess
              ? Get.theme.colorScheme.surface.withOpacity(0.9)
              : Get.theme.colorScheme.errorContainer.withOpacity(0.9),
      colorText:
          isSuccess
              ? Get.theme.colorScheme.onSurface
              : Get.theme.colorScheme.onErrorContainer,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      leftBarIndicatorColor:
          isSuccess
              ? Get.theme.colorScheme.primary
              : Get.theme.colorScheme.error,
      shouldIconPulse: false,
      icon: Icon(
        isSuccess ? Icons.wifi : Icons.wifi_off,
        color:
            isSuccess
                ? Get.theme.colorScheme.primary
                : Get.theme.colorScheme.error,
      ),
    );
  }

  /// Get detailed network status for debugging
  Future<Map<String, dynamic>> getDetailedNetworkStatus() async {
    final connectivityResults = await _connectivity.checkConnectivity();
    final connectivityResult = connectivityResults.isNotEmpty ? connectivityResults.first : ConnectivityResult.none;
    final isActuallyConnected = await _networkInfo.isConnected;

    return {
      'connectivityResult': connectivityResult.name,
      'actualConnection': isActuallyConnected,
      'currentStatus': _connectionStatus.value.name,
      'connectionType': _connectionType.value.name,
      'lastCheck': _lastConnectionCheck?.toIso8601String(),
      'timeSinceLastCheck':
          _lastConnectionCheck != null
              ? DateTime.now().difference(_lastConnectionCheck!).inSeconds
              : null,
      'wasDisconnected': _wasDisconnected,
      'autoSyncEnabled': _autoSyncOnConnection.value,
      'lastAutoSync': _lastAutoSync?.toIso8601String(),
      'syncServiceStatus': _syncService.syncStatus.name,
    };
  }
}
