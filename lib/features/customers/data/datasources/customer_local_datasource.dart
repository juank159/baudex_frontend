// lib/features/customers/data/datasources/customer_local_datasource.dart
import 'dart:convert';
import '../../../../app/core/storage/secure_storage_service.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../models/customer_model.dart';
import '../models/customer_stats_model.dart';

/// Contrato para el datasource local de clientes
abstract class CustomerLocalDataSource {
  Future<void> cacheCustomers(List<CustomerModel> customers);
  Future<List<CustomerModel>> getCachedCustomers();
  Future<void> cacheCustomerStats(CustomerStatsModel stats);
  Future<CustomerStatsModel?> getCachedCustomerStats();
  Future<void> cacheCustomer(CustomerModel customer);
  Future<CustomerModel?> getCachedCustomer(String id);
  Future<void> removeCachedCustomer(String id);
  Future<void> clearCustomerCache();
  Future<bool> isCacheValid();
}

/// Implementación del datasource local usando SecureStorage
class CustomerLocalDataSourceImpl implements CustomerLocalDataSource {
  final SecureStorageService storageService;

  // Keys para el almacenamiento
  static const String _customersKey = 'cached_customers';
  static const String _customerStatsKey = 'cached_customer_stats';
  static const String _customerKeyPrefix = 'cached_customer_';
  static const String _cacheTimestampKey = 'customers_cache_timestamp';

  // Cache válido por 30 minutos
  static const Duration _cacheValidDuration = Duration(minutes: 30);

  const CustomerLocalDataSourceImpl({required this.storageService});

  @override
  Future<void> cacheCustomers(List<CustomerModel> customers) async {
    try {
      final customersJson =
          customers.map((customer) => customer.toJson()).toList();
      await storageService.write(_customersKey, json.encode(customersJson));
      await _updateCacheTimestamp();
    } catch (e) {
      throw CacheException('Error al guardar clientes en cache: $e');
    }
  }

  @override
  Future<List<CustomerModel>> getCachedCustomers() async {
    try {
      final customersData = await storageService.read(_customersKey);
      if (customersData == null) {
        throw CacheException.notFound;
      }

      final customersJson = json.decode(customersData) as List;
      return customersJson
          .map((json) => CustomerModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('Error al obtener clientes del cache: $e');
    }
  }

  @override
  Future<void> cacheCustomerStats(CustomerStatsModel stats) async {
    try {
      await storageService.write(
        _customerStatsKey,
        json.encode(stats.toJson()),
      );
      await _updateCacheTimestamp();
    } catch (e) {
      throw CacheException('Error al guardar estadísticas en cache: $e');
    }
  }

  @override
  Future<CustomerStatsModel?> getCachedCustomerStats() async {
    try {
      final statsData = await storageService.read(_customerStatsKey);
      if (statsData == null) {
        return null;
      }

      final statsJson = json.decode(statsData) as Map<String, dynamic>;
      return CustomerStatsModel.fromJson(statsJson);
    } catch (e) {
      throw CacheException('Error al obtener estadísticas del cache: $e');
    }
  }

  @override
  Future<void> cacheCustomer(CustomerModel customer) async {
    try {
      final customerKey = '$_customerKeyPrefix${customer.id}';
      await storageService.write(customerKey, json.encode(customer.toJson()));
      await _updateCacheTimestamp();
    } catch (e) {
      throw CacheException('Error al guardar cliente en cache: $e');
    }
  }

  @override
  Future<CustomerModel?> getCachedCustomer(String id) async {
    try {
      final customerKey = '$_customerKeyPrefix$id';
      final customerData = await storageService.read(customerKey);

      if (customerData == null) {
        return null;
      }

      final customerJson = json.decode(customerData) as Map<String, dynamic>;
      return CustomerModel.fromJson(customerJson);
    } catch (e) {
      throw CacheException('Error al obtener cliente del cache: $e');
    }
  }

  @override
  Future<void> removeCachedCustomer(String id) async {
    try {
      final customerKey = '$_customerKeyPrefix$id';
      await storageService.delete(customerKey);
    } catch (e) {
      throw CacheException('Error al eliminar cliente del cache: $e');
    }
  }

  @override
  Future<void> clearCustomerCache() async {
    try {
      // Limpiar cache general
      await storageService.delete(_customersKey);
      await storageService.delete(_customerStatsKey);
      await storageService.delete(_cacheTimestampKey);

      // Limpiar clientes individuales
      final allData = await storageService.readAll();
      for (final key in allData.keys) {
        if (key.startsWith(_customerKeyPrefix)) {
          await storageService.delete(key);
        }
      }
    } catch (e) {
      throw CacheException('Error al limpiar cache de clientes: $e');
    }
  }

  @override
  Future<bool> isCacheValid() async {
    try {
      final timestampData = await storageService.read(_cacheTimestampKey);
      if (timestampData == null) {
        return false;
      }

      final timestamp = DateTime.parse(timestampData);
      final now = DateTime.now();
      final difference = now.difference(timestamp);

      return difference <= _cacheValidDuration;
    } catch (e) {
      return false;
    }
  }

  /// Actualizar timestamp del cache
  Future<void> _updateCacheTimestamp() async {
    try {
      final now = DateTime.now().toIso8601String();
      await storageService.write(_cacheTimestampKey, now);
    } catch (e) {
      print('Error al actualizar timestamp del cache: $e');
    }
  }

  /// Verificar si existe cache de clientes
  Future<bool> hasCachedCustomers() async {
    try {
      return await storageService.containsKey(_customersKey);
    } catch (e) {
      return false;
    }
  }

  /// Obtener información del cache
  Future<CacheInfo> getCacheInfo() async {
    try {
      final hasCustomers = await hasCachedCustomers();
      final isValid = await isCacheValid();

      DateTime? lastUpdate;
      final timestampData = await storageService.read(_cacheTimestampKey);
      if (timestampData != null) {
        lastUpdate = DateTime.parse(timestampData);
      }

      return CacheInfo(
        hasCustomers: hasCustomers,
        isValid: isValid,
        lastUpdate: lastUpdate,
      );
    } catch (e) {
      return const CacheInfo(
        hasCustomers: false,
        isValid: false,
        lastUpdate: null,
      );
    }
  }
}

/// Información del cache
class CacheInfo {
  final bool hasCustomers;
  final bool isValid;
  final DateTime? lastUpdate;

  const CacheInfo({
    required this.hasCustomers,
    required this.isValid,
    this.lastUpdate,
  });

  @override
  String toString() =>
      'CacheInfo(hasCustomers: $hasCustomers, isValid: $isValid)';
}
