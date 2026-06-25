// lib/features/invoices/data/datasources/invoice_local_datasource.dart
import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:baudex_desktop/features/invoices/data/models/invoice_model.dart';
import 'package:baudex_desktop/features/invoices/data/models/invoice_stats_model.dart';

import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/storage/secure_storage_service.dart';
import '../../../../app/data/local/isar_database.dart';
import '../models/isar/isar_invoice.dart';

/// Contrato para el datasource local de facturas
abstract class InvoiceLocalDataSource {
  Future<void> cacheInvoices(List<InvoiceModel> invoices);
  Future<void> cacheInvoice(InvoiceModel invoice);
  Future<List<InvoiceModel>> getCachedInvoices();
  Future<InvoiceModel?> getCachedInvoice(String id);
  Future<InvoiceModel?> getCachedInvoiceByNumber(String number);
  Future<void> cacheInvoiceStats(InvoiceStatsModel stats);
  Future<InvoiceStatsModel?> getCachedInvoiceStats();
  Future<void> removeCachedInvoice(String id);
  Future<void> clearInvoiceCache();
  Future<List<InvoiceModel>> searchCachedInvoices(String searchTerm);
  Future<List<InvoiceModel>> getCachedOverdueInvoices();
  Future<List<InvoiceModel>> getCachedInvoicesByCustomer(String customerId);
  Future<DateTime?> getLastCacheTime();
  Future<bool> hasCachedData();

  // ⭐ FASE 1: Método para acceder a versión ISAR (detección de conflictos)
  Future<IsarInvoice?> getIsarInvoice(String id);
}

/// Implementación del datasource local usando SecureStorage
class InvoiceLocalDataSourceImpl implements InvoiceLocalDataSource {
  final SecureStorageService storageService;

  // Claves para el cache
  static const String _invoicesListKey = 'invoices_cache';
  static const String _invoiceDetailKey = 'invoice_detail_';
  static const String _invoiceStatsKey = 'invoice_stats_cache';
  static const String _lastCacheTimeKey = 'invoices_last_cache_time';

  // Tiempo de vida del cache - IMPORTANTE: NO eliminar cache expirado
  // Solo marcar como "stale" pero seguir sirviendo datos
  static const int _cacheStaleMinutes = 15; // Cache considerado "stale" después de 15 min
  static const int _cacheMaxAgeMinutes = 1440; // Cache máximo: 24 horas (nunca eliminar antes)

  const InvoiceLocalDataSourceImpl({required this.storageService});

  @override
  Future<void> cacheInvoices(List<InvoiceModel> invoices) async {
    try {

      final invoicesJson = invoices.map((invoice) => invoice.toJson()).toList();
      final cacheData = {
        'invoices': invoicesJson,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'version': '1.0', // Para futuras migraciones
      };

      await storageService.write(_invoicesListKey, jsonEncode(cacheData));
      await storageService.write(
        _lastCacheTimeKey,
        DateTime.now().millisecondsSinceEpoch.toString(),
      );

    } catch (e) {
      throw CacheException('Error al cachear facturas: $e');
    }
  }

  @override
  Future<void> cacheInvoice(InvoiceModel invoice) async {
    try {
      // ✅ GUARDAR EN ISAR PRIMERO (persistencia offline real)
      try {
        final isar = IsarDatabase.instance.database;
        await isar.writeTxn(() async {
          // Buscar si existe
          var isarInvoice = await isar.isarInvoices
              .filter()
              .serverIdEqualTo(invoice.id)
              .findFirst();

          if (isarInvoice != null) {
            // Actualizar existente
            isarInvoice.updateFromModel(invoice);
          } else {
            // Crear nuevo
            isarInvoice = IsarInvoice.fromModel(invoice);
          }

          // ✅ IMPORTANTE: Guardar items y payments como JSON en metadataJson
          // Ya que IsarInvoiceItem y IsarInvoicePayment no son colecciones separadas
          final fullData = {
            'items': invoice.items.map((item) => {
              'id': item.id,
              'description': item.description,
              'quantity': item.quantity,
              'unitPrice': item.unitPrice,
              'discountPercentage': item.discountPercentage,
              'discountAmount': item.discountAmount,
              'subtotal': item.subtotal,
              'unit': item.unit,
              'notes': item.notes,
              'invoiceId': item.invoiceId,
              'productId': item.productId,
            }).toList(),
            'payments': invoice.payments.map((payment) => {
              'id': payment.id,
              'amount': payment.amount,
              'paymentMethod': payment.paymentMethod.value,
              'paymentDate': payment.paymentDate.toIso8601String(),
              'reference': payment.reference,
              'notes': payment.notes,
              'invoiceId': payment.invoiceId,
            }).toList(),
            'metadata': invoice.metadata,
          };

          isarInvoice.metadataJson = jsonEncode(fullData);

          // Guardar factura con items y payments embebidos
          await isar.isarInvoices.put(isarInvoice);
        });
      } catch (e) {
      }

      // Guardar en SecureStorage (fallback legacy)
      final invoiceJson = invoice.toJson();
      final cacheData = {
        'invoice': invoiceJson,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'version': '1.0',
      };

      await storageService.write(
        '$_invoiceDetailKey${invoice.id}',
        jsonEncode(cacheData),
      );
    } catch (e) {
      // Fallar silenciosamente en lugar de lanzar excepción
      // Esto permite que la app funcione aunque el cache no esté disponible
    }
  }

  @override
  Future<List<InvoiceModel>> getCachedInvoices() async {
    try {

      final cachedData = await storageService.read(_invoicesListKey);
      if (cachedData == null) {
        throw const CacheException('No hay facturas en cache');
      }

      final cacheMap = jsonDecode(cachedData) as Map<String, dynamic>;
      final timestamp = cacheMap['timestamp'] as int;

      // ✅ OFFLINE-FIRST: NUNCA eliminar cache, siempre servir datos aunque sean viejos
      // Datos stale son infinitamente mejores que no tener datos cuando estás offline
      if (_isCacheTooOld(timestamp)) {
      } else if (_isCacheStale(timestamp)) {
      }

      final invoicesJson = cacheMap['invoices'] as List;
      final invoices =
          invoicesJson
              .map(
                (json) => InvoiceModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();

      return invoices;
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('Error al obtener facturas del cache: $e');
    }
  }

  @override
  Future<InvoiceModel?> getCachedInvoice(String id) async {
    try {

      final cachedData = await storageService.read('$_invoiceDetailKey$id');
      if (cachedData == null) {
        return null;
      }

      final cacheMap = jsonDecode(cachedData) as Map<String, dynamic>;
      final timestamp = cacheMap['timestamp'] as int;

      // ✅ OFFLINE-FIRST: NUNCA eliminar cache individual, siempre servir
      if (_isCacheTooOld(timestamp)) {
      } else if (_isCacheStale(timestamp)) {
      }

      final invoiceJson = cacheMap['invoice'] as Map<String, dynamic>;
      final invoice = InvoiceModel.fromJson(invoiceJson);

      return invoice;
    } catch (e) {
      throw CacheException('Error al obtener factura del cache: $e');
    }
  }

  @override
  Future<InvoiceModel?> getCachedInvoiceByNumber(String number) async {
    try {

      final invoices = await getCachedInvoices();
      for (final invoice in invoices) {
        if (invoice.number == number) {
          return invoice;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheInvoiceStats(InvoiceStatsModel stats) async {
    try {

      final statsJson = stats.toJson();
      final cacheData = {
        'stats': statsJson,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'version': '1.0',
      };

      await storageService.write(_invoiceStatsKey, jsonEncode(cacheData));
    } catch (e) {
      throw CacheException('Error al cachear estadísticas: $e');
    }
  }

  @override
  Future<InvoiceStatsModel?> getCachedInvoiceStats() async {
    try {

      final cachedData = await storageService.read(_invoiceStatsKey);
      if (cachedData == null) {
        return null;
      }

      final cacheMap = jsonDecode(cachedData) as Map<String, dynamic>;
      final timestamp = cacheMap['timestamp'] as int;

      // ✅ OFFLINE-FIRST: NUNCA eliminar cache de estadísticas, siempre servir
      if (_isCacheTooOld(timestamp)) {
      } else if (_isCacheStale(timestamp)) {
      }

      final statsJson = cacheMap['stats'] as Map<String, dynamic>;
      final stats = InvoiceStatsModel.fromJson(statsJson);

      return stats;
    } catch (e) {
      throw CacheException('Error al obtener estadísticas del cache: $e');
    }
  }

  @override
  Future<void> removeCachedInvoice(String id) async {
    try {

      await storageService.delete('$_invoiceDetailKey$id');

      // También remover de la lista si existe
      try {
        final invoices = await getCachedInvoices();
        final filteredInvoices = invoices.where((i) => i.id != id).toList();
        await cacheInvoices(filteredInvoices);
      } catch (e) {
      }

    } catch (e) {
      throw CacheException('Error al remover factura del cache: $e');
    }
  }

  @override
  Future<void> clearInvoiceCache() async {
    try {

      await Future.wait([
        storageService.delete(_invoicesListKey),
        storageService.delete(_invoiceStatsKey),
        storageService.delete(_lastCacheTimeKey),
      ]);

    } catch (e) {
      throw CacheException('Error al limpiar cache de facturas: $e');
    }
  }

  @override
  Future<List<InvoiceModel>> searchCachedInvoices(String searchTerm) async {
    try {

      final invoices = await getCachedInvoices();
      final term = searchTerm.toLowerCase();

      final filteredInvoices =
          invoices.where((invoice) {
            return invoice.number.toLowerCase().contains(term) ||
                invoice.customerName.toLowerCase().contains(term) ||
                (invoice.notes?.toLowerCase().contains(term) ?? false) ||
                invoice.total.toString().contains(term);
          }).toList();

      return filteredInvoices;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<InvoiceModel>> getCachedOverdueInvoices() async {
    try {

      final invoices = await getCachedInvoices();
      final now = DateTime.now();

      final overdueInvoices =
          invoices.where((invoice) {
            return invoice.dueDate.isBefore(now) &&
                (invoice.status.value == 'pending' ||
                    invoice.status.value == 'partially_paid');
          }).toList();

      // Ordenar por fecha de vencimiento (más antiguas primero)
      overdueInvoices.sort((a, b) => a.dueDate.compareTo(b.dueDate));

      return overdueInvoices;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<InvoiceModel>> getCachedInvoicesByCustomer(
    String customerId,
  ) async {
    try {

      final invoices = await getCachedInvoices();
      final customerInvoices =
          invoices.where((invoice) {
            return invoice.customerId == customerId;
          }).toList();

      // Ordenar por fecha de creación (más recientes primero)
      customerInvoices.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return customerInvoices;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<DateTime?> getLastCacheTime() async {
    try {
      final timestampStr = await storageService.read(_lastCacheTimeKey);
      if (timestampStr != null) {
        final timestamp = int.parse(timestampStr);
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> hasCachedData() async {
    try {
      final cachedData = await storageService.read(_invoicesListKey);
      if (cachedData == null) return false;

      // ✅ OFFLINE-FIRST: Retorna true si hay CUALQUIER dato, sin importar antigüedad
      final cacheMap = jsonDecode(cachedData) as Map<String, dynamic>;
      final invoices = cacheMap['invoices'] as List?;
      return invoices != null && invoices.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ==================== HELPER METHODS ====================

  /// Verificar si el cache está "stale" (viejo pero usable)
  bool _isCacheStale(int timestamp) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - timestamp;
    final diffMinutes = diff / (1000 * 60);
    return diffMinutes > _cacheStaleMinutes;
  }

  /// Verificar si el cache es demasiado antiguo para usar (>24h)
  bool _isCacheTooOld(int timestamp) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - timestamp;
    final diffMinutes = diff / (1000 * 60);
    return diffMinutes > _cacheMaxAgeMinutes;
  }

  /// Obtener estadísticas básicas desde cache
  Future<Map<String, int>> getCachedInvoiceBasicStats() async {
    try {
      final invoices = await getCachedInvoices();
      final now = DateTime.now();

      int draft = 0,
          pending = 0,
          paid = 0,
          overdue = 0,
          cancelled = 0,
          partiallyPaid = 0;

      for (final invoice in invoices) {
        switch (invoice.status.value) {
          case 'draft':
            draft++;
            break;
          case 'pending':
            if (invoice.dueDate.isBefore(now)) {
              overdue++;
            } else {
              pending++;
            }
            break;
          case 'paid':
            paid++;
            break;
          case 'overdue':
            overdue++;
            break;
          case 'cancelled':
            cancelled++;
            break;
          case 'partially_paid':
            if (invoice.dueDate.isBefore(now)) {
              overdue++;
            } else {
              partiallyPaid++;
            }
            break;
        }
      }

      return {
        'total': invoices.length,
        'draft': draft,
        'pending': pending,
        'paid': paid,
        'overdue': overdue,
        'cancelled': cancelled,
        'partiallyPaid': partiallyPaid,
      };
    } catch (e) {
      return {};
    }
  }

  // ⭐ FASE 1: Obtener IsarInvoice directamente para acceder a campos de versionamiento
  @override
  Future<IsarInvoice?> getIsarInvoice(String id) async {
    try {
      final isar = IsarDatabase.instance.database;
      final isarInvoice = await isar.isarInvoices
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      return isarInvoice;
    } catch (e) {
      return null;
    }
  }
}
