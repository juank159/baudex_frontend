// lib/features/suppliers/data/datasources/supplier_local_datasource.dart
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/models/pagination_meta.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/supplier_model.dart';
import '../models/supplier_stats_model.dart';
import '../../domain/repositories/supplier_repository.dart';

abstract class SupplierLocalDataSource {
  Future<PaginatedResult<SupplierModel>> getSuppliers(
    SupplierQueryParams params,
  );
  Future<SupplierModel?> getSupplierById(String id);
  Future<List<SupplierModel>> searchSuppliers(
    String searchTerm, {
    int limit = 10,
  });
  Future<List<SupplierModel>> getActiveSuppliers();
  Future<List<SupplierModel>> getCachedSuppliers();
  Future<void> cacheSuppliers(List<SupplierModel> suppliers);
  Future<void> cacheSupplier(SupplierModel supplier);
  Future<void> removeCachedSupplier(String id);
  Future<void> clearSuppliersCache();
  Future<SupplierStatsModel?> getCachedSupplierStats();
  Future<void> cacheSupplierStats(SupplierStatsModel stats);
}

class SupplierLocalDataSourceImpl implements SupplierLocalDataSource {
  final FlutterSecureStorage secureStorage;

  static const String _suppliersKey = 'suppliers_cache';
  static const String _supplierStatsKey = 'supplier_stats_cache';
  static const String _supplierPrefix = 'supplier_';

  SupplierLocalDataSourceImpl({required this.secureStorage});

  @override
  Future<PaginatedResult<SupplierModel>> getSuppliers(
    SupplierQueryParams params,
  ) async {
    try {
      final suppliers = await getCachedSuppliers();

      // Aplicar filtros localmente
      List<SupplierModel> filteredSuppliers = suppliers;

      // Filtro por búsqueda
      if (params.search != null && params.search!.isNotEmpty) {
        final searchLower = params.search!.toLowerCase();
        filteredSuppliers =
            filteredSuppliers
                .where(
                  (supplier) =>
                      supplier.name.toLowerCase().contains(searchLower) ||
                      (supplier.contactPerson?.toLowerCase().contains(
                            searchLower,
                          ) ??
                          false) ||
                      (supplier.email?.toLowerCase().contains(searchLower) ??
                          false) ||
                      (supplier.code?.toLowerCase().contains(searchLower) ??
                          false) ||
                      (supplier.documentNumber.toLowerCase().contains(
                            searchLower,
                          ) ??
                          false),
                )
                .toList();
      }

      // Filtro por estado
      if (params.status != null) {
        filteredSuppliers =
            filteredSuppliers
                .where((supplier) => supplier.status == params.status)
                .toList();
      }

      // Filtro por tipo de documento
      if (params.documentType != null) {
        filteredSuppliers =
            filteredSuppliers
                .where(
                  (supplier) => supplier.documentType == params.documentType,
                )
                .toList();
      }

      // Filtro por moneda
      if (params.currency != null) {
        filteredSuppliers =
            filteredSuppliers
                .where((supplier) => supplier.currency == params.currency)
                .toList();
      }

      // Filtros booleanos
      if (params.hasEmail == true) {
        filteredSuppliers =
            filteredSuppliers.where((supplier) => supplier.hasEmail).toList();
      }

      if (params.hasPhone == true) {
        filteredSuppliers =
            filteredSuppliers
                .where((supplier) => supplier.hasPhone || supplier.hasMobile)
                .toList();
      }

      if (params.hasCreditLimit == true) {
        filteredSuppliers =
            filteredSuppliers
                .where((supplier) => supplier.hasCreditLimit)
                .toList();
      }

      if (params.hasDiscount == true) {
        filteredSuppliers =
            filteredSuppliers
                .where((supplier) => supplier.hasDiscount)
                .toList();
      }

      // Ordenamiento
      if (params.sortBy != null) {
        filteredSuppliers.sort((a, b) {
          int comparison = 0;
          switch (params.sortBy) {
            case 'name':
              comparison = a.name.compareTo(b.name);
              break;
            case 'createdAt':
              comparison = a.createdAt.compareTo(b.createdAt);
              break;
            case 'updatedAt':
              comparison = a.updatedAt.compareTo(b.updatedAt);
              break;
            case 'paymentTermsDays':
              comparison = a.paymentTermsDays.compareTo(b.paymentTermsDays);
              break;
            case 'creditLimit':
              comparison = a.creditLimit.compareTo(b.creditLimit);
              break;
            default:
              comparison = a.name.compareTo(b.name);
          }

          if (params.sortOrder == 'desc') {
            comparison = -comparison;
          }

          return comparison;
        });
      }

      // Paginación
      final totalItems = filteredSuppliers.length;
      final totalPages = (totalItems / params.limit).ceil();
      final startIndex = (params.page - 1) * params.limit;
      final endIndex = (startIndex + params.limit).clamp(0, totalItems);

      final paginatedSuppliers =
          startIndex < totalItems
              ? filteredSuppliers.sublist(startIndex, endIndex)
              : <SupplierModel>[];

      final meta = PaginationMeta(
        page: params.page,
        limit: params.limit,
        totalItems: totalItems,
        totalPages: totalPages,
        hasNextPage: params.page < totalPages,
        hasPreviousPage: params.page > 1,
      );

      return PaginatedResult<SupplierModel>(
        data: paginatedSuppliers,
        meta: meta,
      );
    } catch (e) {
      throw CacheException('Error al obtener proveedores desde cache: $e');
    }
  }

  @override
  Future<SupplierModel?> getSupplierById(String id) async {
    try {
      final supplierDataJson = await secureStorage.read(
        key: '$_supplierPrefix$id',
      );
      final supplierData =
          supplierDataJson != null ? json.decode(supplierDataJson) : null;
      if (supplierData != null) {
        return SupplierModel.fromJson(supplierData);
      }
      return null;
    } catch (e) {
      throw CacheException('Error al obtener proveedor desde cache: $e');
    }
  }

  @override
  Future<List<SupplierModel>> searchSuppliers(
    String searchTerm, {
    int limit = 10,
  }) async {
    try {
      final suppliers = await getCachedSuppliers();
      final searchLower = searchTerm.toLowerCase();

      final results =
          suppliers
              .where(
                (supplier) =>
                    supplier.name.toLowerCase().contains(searchLower) ||
                    (supplier.contactPerson?.toLowerCase().contains(
                          searchLower,
                        ) ??
                        false) ||
                    (supplier.email?.toLowerCase().contains(searchLower) ??
                        false) ||
                    (supplier.code?.toLowerCase().contains(searchLower) ??
                        false) ||
                    (supplier.documentNumber.toLowerCase().contains(
                          searchLower,
                        ) ??
                        false),
              )
              .take(limit)
              .toList();

      return results;
    } catch (e) {
      throw CacheException('Error en búsqueda local de proveedores: $e');
    }
  }

  @override
  Future<List<SupplierModel>> getActiveSuppliers() async {
    try {
      final suppliers = await getCachedSuppliers();
      return suppliers.where((supplier) => supplier.isActive).toList();
    } catch (e) {
      throw CacheException(
        'Error al obtener proveedores activos desde cache: $e',
      );
    }
  }

  @override
  Future<List<SupplierModel>> getCachedSuppliers() async {
    try {
      final suppliersDataJson = await secureStorage.read(key: _suppliersKey);
      final suppliersData =
          suppliersDataJson != null ? json.decode(suppliersDataJson) : null;
      if (suppliersData != null && suppliersData is List) {
        return suppliersData
            .map((data) => SupplierModel.fromJson(data as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      // En macOS, si hay problema con Keychain, devolvemos lista vacía
      print('⚠️ Error al leer cache de proveedores (se ignora): $e');
      return [];
    }
  }

  @override
  Future<void> cacheSuppliers(List<SupplierModel> suppliers) async {
    try {
      final suppliersJson =
          suppliers.map((supplier) => supplier.toJson()).toList();
      await secureStorage.write(
        key: _suppliersKey,
        value: json.encode(suppliersJson),
      );

      // También cachear cada proveedor individualmente
      for (final supplier in suppliers) {
        await secureStorage.write(
          key: '$_supplierPrefix${supplier.id}',
          value: json.encode(supplier.toJson()),
        );
      }
    } catch (e) {
      // En macOS, el error -34018 indica problema con entitlements del Keychain
      // Simplemente loggeamos y continuamos sin fallar
      print('⚠️ Error al cachear proveedores (se ignora): $e');
      // No lanzamos excepción para permitir que la app funcione sin cache
    }
  }

  @override
  Future<void> cacheSupplier(SupplierModel supplier) async {
    try {
      await secureStorage.write(
        key: '$_supplierPrefix${supplier.id}',
        value: json.encode(supplier.toJson()),
      );

      // Actualizar también el cache general
      final suppliers = await getCachedSuppliers();
      final existingIndex = suppliers.indexWhere((s) => s.id == supplier.id);

      if (existingIndex >= 0) {
        suppliers[existingIndex] = supplier;
      } else {
        suppliers.add(supplier);
      }

      final suppliersJson = suppliers.map((s) => s.toJson()).toList();
      await secureStorage.write(
        key: _suppliersKey,
        value: json.encode(suppliersJson),
      );
    } catch (e) {
      // En macOS, ignoramos errores de Keychain para mantener funcionalidad
      print('⚠️ Error al cachear proveedor (se ignora): $e');
    }
  }

  @override
  Future<void> removeCachedSupplier(String id) async {
    try {
      await secureStorage.delete(key: '$_supplierPrefix$id');

      // Actualizar también el cache general
      final suppliers = await getCachedSuppliers();
      suppliers.removeWhere((supplier) => supplier.id == id);

      final suppliersJson =
          suppliers.map((supplier) => supplier.toJson()).toList();
      await secureStorage.write(
        key: _suppliersKey,
        value: json.encode(suppliersJson),
      );
    } catch (e) {
      throw CacheException('Error al remover proveedor del cache: $e');
    }
  }

  @override
  Future<void> clearSuppliersCache() async {
    try {
      await secureStorage.delete(key: _suppliersKey);
      await secureStorage.delete(key: _supplierStatsKey);

      // Remover todos los proveedores individuales
      final suppliers = await getCachedSuppliers();
      for (final supplier in suppliers) {
        await secureStorage.delete(key: '$_supplierPrefix${supplier.id}');
      }
    } catch (e) {
      throw CacheException('Error al limpiar cache de proveedores: $e');
    }
  }

  @override
  Future<SupplierStatsModel?> getCachedSupplierStats() async {
    try {
      final statsDataJson = await secureStorage.read(key: _supplierStatsKey);
      final statsData =
          statsDataJson != null ? json.decode(statsDataJson) : null;
      if (statsData != null) {
        return SupplierStatsModel.fromJson(statsData);
      }
      return null;
    } catch (e) {
      throw CacheException('Error al obtener estadísticas desde cache: $e');
    }
  }

  @override
  Future<void> cacheSupplierStats(SupplierStatsModel stats) async {
    try {
      await secureStorage.write(
        key: _supplierStatsKey,
        value: json.encode(stats.toJson()),
      );
    } catch (e) {
      throw CacheException('Error al cachear estadísticas: $e');
    }
  }
}
