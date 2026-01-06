// lib/features/customer_credits/data/datasources/customer_credit_local_datasource.dart

import 'dart:convert';
import '../../../../app/core/storage/secure_storage_service.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../models/customer_credit_model.dart';

/// Contrato para el datasource local de créditos de clientes
abstract class CustomerCreditLocalDataSource {
  Future<void> cacheCredits(List<CustomerCreditModel> credits);
  Future<List<CustomerCreditModel>> getCachedCredits();
  Future<void> cacheCredit(CustomerCreditModel credit);
  Future<CustomerCreditModel?> getCachedCredit(String id);
  Future<void> removeCachedCredit(String id);
  Future<void> clearCreditCache();
  Future<bool> isCacheValid();
}

/// Implementación del datasource local usando SecureStorage
class CustomerCreditLocalDataSourceImpl implements CustomerCreditLocalDataSource {
  final SecureStorageService storageService;

  // Keys para el almacenamiento
  static const String _creditsKey = 'cached_customer_credits';
  static const String _creditKeyPrefix = 'cached_customer_credit_';
  static const String _cacheTimestampKey = 'customer_credits_cache_timestamp';

  // Cache válido por 30 minutos
  static const Duration _cacheValidDuration = Duration(minutes: 30);

  const CustomerCreditLocalDataSourceImpl({required this.storageService});

  @override
  Future<void> cacheCredits(List<CustomerCreditModel> credits) async {
    try {
      final creditsJson = credits.map((credit) => credit.toJson()).toList();
      await storageService.write(_creditsKey, json.encode(creditsJson));
      await _updateCacheTimestamp();
    } catch (e) {
      throw CacheException('Error al guardar créditos en cache: $e');
    }
  }

  @override
  Future<List<CustomerCreditModel>> getCachedCredits() async {
    try {
      final creditsData = await storageService.read(_creditsKey);
      if (creditsData == null) {
        throw CacheException.notFound;
      }

      final creditsJson = json.decode(creditsData) as List;
      return creditsJson
          .map((json) => CustomerCreditModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('Error al obtener créditos del cache: $e');
    }
  }

  @override
  Future<void> cacheCredit(CustomerCreditModel credit) async {
    try {
      // Guardar crédito individual
      final creditKey = '$_creditKeyPrefix${credit.id}';
      await storageService.write(creditKey, json.encode(credit.toJson()));

      // También actualizar la lista principal
      try {
        final creditsData = await storageService.read(_creditsKey);
        List<CustomerCreditModel> credits = [];

        if (creditsData != null) {
          final creditsJson = json.decode(creditsData) as List;
          credits = creditsJson
              .map((json) => CustomerCreditModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }

        // Buscar si el crédito ya existe y actualizarlo, o agregarlo si es nuevo
        final existingIndex = credits.indexWhere((c) => c.id == credit.id);
        if (existingIndex >= 0) {
          credits[existingIndex] = credit;
          print('📝 Crédito actualizado en lista principal: ${credit.id}');
        } else {
          credits.add(credit);
          print('➕ Crédito agregado a lista principal: ${credit.id}');
        }

        // Guardar lista actualizada
        final creditsJson = credits.map((c) => c.toJson()).toList();
        await storageService.write(_creditsKey, json.encode(creditsJson));
      } catch (e) {
        print('⚠️ Error actualizando lista principal (solo cache individual guardado): $e');
      }

      await _updateCacheTimestamp();
    } catch (e) {
      throw CacheException('Error al guardar crédito en cache: $e');
    }
  }

  @override
  Future<CustomerCreditModel?> getCachedCredit(String id) async {
    try {
      final creditKey = '$_creditKeyPrefix$id';
      final creditData = await storageService.read(creditKey);

      if (creditData == null) {
        return null;
      }

      final creditJson = json.decode(creditData) as Map<String, dynamic>;
      return CustomerCreditModel.fromJson(creditJson);
    } catch (e) {
      throw CacheException('Error al obtener crédito del cache: $e');
    }
  }

  @override
  Future<void> removeCachedCredit(String id) async {
    try {
      // Eliminar crédito individual
      final creditKey = '$_creditKeyPrefix$id';
      await storageService.delete(creditKey);

      // También eliminar de la lista principal
      try {
        final creditsData = await storageService.read(_creditsKey);
        if (creditsData != null) {
          final creditsJson = json.decode(creditsData) as List;
          final credits = creditsJson
              .map((json) => CustomerCreditModel.fromJson(json as Map<String, dynamic>))
              .toList();

          // Remover crédito de la lista
          credits.removeWhere((c) => c.id == id);

          // Guardar lista actualizada
          final updatedCreditsJson = credits.map((c) => c.toJson()).toList();
          await storageService.write(_creditsKey, json.encode(updatedCreditsJson));
          print('🗑️ Crédito eliminado de lista principal: $id');
        }
      } catch (e) {
        print('⚠️ Error eliminando de lista principal (solo cache individual eliminado): $e');
      }
    } catch (e) {
      throw CacheException('Error al eliminar crédito del cache: $e');
    }
  }

  @override
  Future<void> clearCreditCache() async {
    try {
      // Limpiar cache general
      await storageService.delete(_creditsKey);
      await storageService.delete(_cacheTimestampKey);

      // Limpiar créditos individuales
      final allData = await storageService.readAll();
      for (final key in allData.keys) {
        if (key.startsWith(_creditKeyPrefix)) {
          await storageService.delete(key);
        }
      }
    } catch (e) {
      throw CacheException('Error al limpiar cache de créditos: $e');
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
}
