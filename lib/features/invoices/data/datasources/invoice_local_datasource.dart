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

  // Tiempo de vida del cache (en minutos)
  static const int _cacheExpirationMinutes = 15;

  const InvoiceLocalDataSourceImpl({required this.storageService});

  @override
  Future<void> cacheInvoices(List<InvoiceModel> invoices) async {
    try {
      print(
        '💾 InvoiceLocalDataSource: Cacheando ${invoices.length} facturas...',
      );

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

      print('✅ InvoiceLocalDataSource: Facturas cacheadas exitosamente');
    } catch (e) {
      print('❌ Error al cachear facturas: $e');
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
        print('✅ Invoice guardada en ISAR con ${invoice.items.length} items y ${invoice.payments.length} payments: ${invoice.id}');
      } catch (e) {
        print('⚠️ Error guardando en ISAR (continuando...): $e');
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
      print('⚠️ Cache no disponible (continuando sin cache): $e');
    }
  }

  @override
  Future<List<InvoiceModel>> getCachedInvoices() async {
    try {
      print('📖 InvoiceLocalDataSource: Obteniendo facturas del cache...');

      final cachedData = await storageService.read(_invoicesListKey);
      if (cachedData == null) {
        throw const CacheException('No hay facturas en cache');
      }

      final cacheMap = jsonDecode(cachedData) as Map<String, dynamic>;
      final timestamp = cacheMap['timestamp'] as int;

      if (_isCacheExpired(timestamp)) {
        print('⏰ Cache de facturas expirado, limpiando...');
        await storageService.delete(_invoicesListKey);
        throw const CacheException('Cache de facturas expirado');
      }

      final invoicesJson = cacheMap['invoices'] as List;
      final invoices =
          invoicesJson
              .map(
                (json) => InvoiceModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();

      print(
        '✅ InvoiceLocalDataSource: ${invoices.length} facturas obtenidas del cache',
      );
      return invoices;
    } catch (e) {
      if (e is CacheException) rethrow;
      print('❌ Error al obtener facturas del cache: $e');
      throw CacheException('Error al obtener facturas del cache: $e');
    }
  }

  @override
  Future<InvoiceModel?> getCachedInvoice(String id) async {
    try {
      print('📖 InvoiceLocalDataSource: Obteniendo factura del cache: $id');

      final cachedData = await storageService.read('$_invoiceDetailKey$id');
      if (cachedData == null) {
        print('⚠️ Factura no encontrada en cache: $id');
        return null;
      }

      final cacheMap = jsonDecode(cachedData) as Map<String, dynamic>;
      final timestamp = cacheMap['timestamp'] as int;

      if (_isCacheExpired(timestamp)) {
        print('⏰ Cache de factura expirado: $id');
        await storageService.delete('$_invoiceDetailKey$id');
        return null;
      }

      final invoiceJson = cacheMap['invoice'] as Map<String, dynamic>;
      final invoice = InvoiceModel.fromJson(invoiceJson);

      print('✅ InvoiceLocalDataSource: Factura obtenida del cache');
      return invoice;
    } catch (e) {
      print('❌ Error al obtener factura del cache: $e');
      throw CacheException('Error al obtener factura del cache: $e');
    }
  }

  @override
  Future<InvoiceModel?> getCachedInvoiceByNumber(String number) async {
    try {
      print('📖 InvoiceLocalDataSource: Buscando factura por número: $number');

      final invoices = await getCachedInvoices();
      for (final invoice in invoices) {
        if (invoice.number == number) {
          print('✅ Factura encontrada por número: $number');
          return invoice;
        }
      }

      print('⚠️ Factura no encontrada por número: $number');
      return null;
    } catch (e) {
      print('❌ Error al buscar factura por número: $e');
      return null;
    }
  }

  @override
  Future<void> cacheInvoiceStats(InvoiceStatsModel stats) async {
    try {
      print('💾 InvoiceLocalDataSource: Cacheando estadísticas de facturas...');

      final statsJson = stats.toJson();
      final cacheData = {
        'stats': statsJson,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'version': '1.0',
      };

      await storageService.write(_invoiceStatsKey, jsonEncode(cacheData));
      print('✅ InvoiceLocalDataSource: Estadísticas cacheadas');
    } catch (e) {
      print('❌ Error al cachear estadísticas: $e');
      throw CacheException('Error al cachear estadísticas: $e');
    }
  }

  @override
  Future<InvoiceStatsModel?> getCachedInvoiceStats() async {
    try {
      print('📖 InvoiceLocalDataSource: Obteniendo estadísticas del cache...');

      final cachedData = await storageService.read(_invoiceStatsKey);
      if (cachedData == null) {
        print('⚠️ Estadísticas no encontradas en cache');
        return null;
      }

      final cacheMap = jsonDecode(cachedData) as Map<String, dynamic>;
      final timestamp = cacheMap['timestamp'] as int;

      if (_isCacheExpired(timestamp)) {
        print('⏰ Cache de estadísticas expirado');
        await storageService.delete(_invoiceStatsKey);
        return null;
      }

      final statsJson = cacheMap['stats'] as Map<String, dynamic>;
      final stats = InvoiceStatsModel.fromJson(statsJson);

      print('✅ InvoiceLocalDataSource: Estadísticas obtenidas del cache');
      return stats;
    } catch (e) {
      print('❌ Error al obtener estadísticas del cache: $e');
      throw CacheException('Error al obtener estadísticas del cache: $e');
    }
  }

  @override
  Future<void> removeCachedInvoice(String id) async {
    try {
      print('🗑️ InvoiceLocalDataSource: Removiendo factura del cache: $id');

      await storageService.delete('$_invoiceDetailKey$id');

      // También remover de la lista si existe
      try {
        final invoices = await getCachedInvoices();
        final filteredInvoices = invoices.where((i) => i.id != id).toList();
        await cacheInvoices(filteredInvoices);
        print('✅ Factura removida de la lista de cache');
      } catch (e) {
        print(
          '⚠️ No se pudo actualizar la lista después de remover factura: $e',
        );
      }

      print('✅ InvoiceLocalDataSource: Factura removida del cache');
    } catch (e) {
      print('❌ Error al remover factura del cache: $e');
      throw CacheException('Error al remover factura del cache: $e');
    }
  }

  @override
  Future<void> clearInvoiceCache() async {
    try {
      print(
        '🧹 InvoiceLocalDataSource: Limpiando todo el cache de facturas...',
      );

      await Future.wait([
        storageService.delete(_invoicesListKey),
        storageService.delete(_invoiceStatsKey),
        storageService.delete(_lastCacheTimeKey),
      ]);

      print('✅ InvoiceLocalDataSource: Cache limpiado completamente');
    } catch (e) {
      print('❌ Error al limpiar cache de facturas: $e');
      throw CacheException('Error al limpiar cache de facturas: $e');
    }
  }

  @override
  Future<List<InvoiceModel>> searchCachedInvoices(String searchTerm) async {
    try {
      print(
        '🔍 InvoiceLocalDataSource: Buscando facturas en cache: $searchTerm',
      );

      final invoices = await getCachedInvoices();
      final term = searchTerm.toLowerCase();

      final filteredInvoices =
          invoices.where((invoice) {
            return invoice.number.toLowerCase().contains(term) ||
                invoice.customerName.toLowerCase().contains(term) ||
                (invoice.notes?.toLowerCase().contains(term) ?? false) ||
                invoice.total.toString().contains(term);
          }).toList();

      print('✅ ${filteredInvoices.length} facturas encontradas en cache');
      return filteredInvoices;
    } catch (e) {
      print('❌ Error al buscar facturas en cache: $e');
      return [];
    }
  }

  @override
  Future<List<InvoiceModel>> getCachedOverdueInvoices() async {
    try {
      print(
        '📅 InvoiceLocalDataSource: Obteniendo facturas vencidas del cache...',
      );

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

      print(
        '✅ ${overdueInvoices.length} facturas vencidas encontradas en cache',
      );
      return overdueInvoices;
    } catch (e) {
      print('❌ Error al obtener facturas vencidas del cache: $e');
      return [];
    }
  }

  @override
  Future<List<InvoiceModel>> getCachedInvoicesByCustomer(
    String customerId,
  ) async {
    try {
      print(
        '👤 InvoiceLocalDataSource: Obteniendo facturas del cliente del cache: $customerId',
      );

      final invoices = await getCachedInvoices();
      final customerInvoices =
          invoices.where((invoice) {
            return invoice.customerId == customerId;
          }).toList();

      // Ordenar por fecha de creación (más recientes primero)
      customerInvoices.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print(
        '✅ ${customerInvoices.length} facturas del cliente encontradas en cache',
      );
      return customerInvoices;
    } catch (e) {
      print('❌ Error al obtener facturas del cliente del cache: $e');
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
      print('❌ Error al obtener tiempo del último cache: $e');
      return null;
    }
  }

  @override
  Future<bool> hasCachedData() async {
    try {
      final cachedData = await storageService.read(_invoicesListKey);
      if (cachedData == null) return false;

      final cacheMap = jsonDecode(cachedData) as Map<String, dynamic>;
      final timestamp = cacheMap['timestamp'] as int;

      return !_isCacheExpired(timestamp);
    } catch (e) {
      print('❌ Error al verificar datos en cache: $e');
      return false;
    }
  }

  // ==================== HELPER METHODS ====================

  /// Verificar si el cache ha expirado
  bool _isCacheExpired(int timestamp) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - timestamp;
    final diffMinutes = diff / (1000 * 60);
    return diffMinutes > _cacheExpirationMinutes;
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
      print('❌ Error al calcular estadísticas básicas: $e');
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
      print('⚠️ Error al obtener IsarInvoice: $e');
      return null;
    }
  }
}
