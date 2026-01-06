// lib/features/invoices/data/repositories/invoice_offline_repository_simple.dart
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';

import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_stats.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../models/isar/isar_invoice.dart';
import '../models/isar/isar_invoice_item.dart';
import '../../../../app/data/local/enums/isar_enums.dart';
import '../datasources/invoice_local_datasource.dart';
import '../models/invoice_model.dart';

/// Implementación offline simplificada del repositorio de facturas usando ISAR
///
/// Implementa solo los métodos esenciales para funcionar offline
class InvoiceOfflineRepositorySimple implements InvoiceRepository {
  final IsarDatabase _database;
  final InvoiceLocalDataSource? _localDataSource;

  InvoiceOfflineRepositorySimple({
    IsarDatabase? database,
    InvoiceLocalDataSource? localDataSource,
  })  : _database = database ?? IsarDatabase.instance,
        _localDataSource = localDataSource;

  Isar get _isar => _database.database;

  // ==================== READ OPERATIONS ====================

  @override
  Future<Either<Failure, PaginatedResult<Invoice>>> getInvoices({
    int page = 1,
    int limit = 10,
    String? search,
    InvoiceStatus? status,
    PaymentMethod? paymentMethod,
    String? customerId,
    String? createdById,
    String? bankAccountId,
    String? bankAccountName, // Filtro por nombre de método de pago (no aplica en offline)
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    String sortBy = 'createdAt',
    String sortOrder = 'DESC',
  }) async {
    try {
      print('📱 ISAR: Cargando facturas offline...');
      
      final collection = _isar.isarInvoices;
      
      // Build base query (exclude deleted items)
      var query = collection.filter().deletedAtIsNull();
      
      // Apply search filter
      if (search != null && search.isNotEmpty) {
        query = query.numberContains(search, caseSensitive: false);
      }
      
      // Apply status filter
      if (status != null) {
        final isarStatus = _mapInvoiceStatusToIsar(status);
        query = query.statusEqualTo(isarStatus);
      }
      
      // Apply customer filter
      if (customerId != null) {
        query = query.customerIdEqualTo(customerId);
      }
      
      // Apply date range filters
      if (startDate != null) {
        query = query.dateGreaterThan(startDate);
      }
      if (endDate != null) {
        query = query.dateLessThan(endDate);
      }
      
      // Obtener todos los resultados (ordenar y paginar en Dart)
      final allResults = await query.findAll();
      final totalItems = allResults.length;

      // Ordenar en Dart
      allResults.sort((a, b) {
        int comparison = 0;
        switch (sortBy) {
          case 'number':
            comparison = a.number.compareTo(b.number);
            break;
          case 'date':
            comparison = a.date.compareTo(b.date);
            break;
          case 'total':
            comparison = a.total.compareTo(b.total);
            break;
          case 'createdAt':
          default:
            comparison = a.createdAt.compareTo(b.createdAt);
        }
        return sortOrder == 'DESC' ? -comparison : comparison;
      });

      // Paginar manualmente
      final offset = (page - 1) * limit;
      final start = offset.clamp(0, allResults.length);
      final end = (start + limit).clamp(0, allResults.length);
      final isarInvoices = allResults.sublist(start, end);

      // Convert to domain entities
      final invoices = isarInvoices.map((isar) => isar.toEntity()).toList();
      
      final totalPages = (totalItems / limit).ceil();
      final meta = PaginationMeta(
        page: page,
        limit: limit,
        totalItems: totalItems,
        totalPages: totalPages,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1,
      );

      print('✅ ISAR: ${invoices.length} facturas cargadas');
      return Right(PaginatedResult(data: invoices, meta: meta));
    } catch (e) {
      print('❌ ISAR: Error loading invoices: $e');
      return Left(CacheFailure('Error loading invoices: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Invoice>>> getOverdueInvoices() async {
    try {
      print('📱 ISAR: Cargando facturas vencidas offline...');
      
      final now = DateTime.now();
      final isarInvoices = await _isar.isarInvoices
          .filter()
          .deletedAtIsNull()
          .and()
          .dueDateLessThan(now)
          .and()
          .statusEqualTo(IsarInvoiceStatus.pending)
          .sortByDueDateDesc()
          .limit(50)
          .findAll();
      
      final invoices = isarInvoices.map((isar) => isar.toEntity()).toList();
      print('✅ ISAR: ${invoices.length} facturas vencidas cargadas');
      return Right(invoices);
    } catch (e) {
      print('❌ ISAR: Error loading overdue invoices: $e');
      return Left(CacheFailure('Error loading overdue invoices: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Invoice>> getInvoiceById(String id) async {
    try {
      final isarInvoice = await _isar.isarInvoices
          .filter()
          .serverIdEqualTo(id)
          .and()
          .deletedAtIsNull()
          .findFirst();
      
      if (isarInvoice == null) {
        return Left(CacheFailure('Invoice not found'));
      }
      
      return Right(isarInvoice.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error loading invoice: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Invoice>> getInvoiceByNumber(String number) async {
    try {
      final isarInvoice = await _isar.isarInvoices
          .filter()
          .numberEqualTo(number)
          .and()
          .deletedAtIsNull()
          .findFirst();
      
      if (isarInvoice == null) {
        return Left(CacheFailure('Invoice not found'));
      }
      
      return Right(isarInvoice.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error loading invoice: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Invoice>>> searchInvoices(String searchTerm) async {
    try {
      final isarInvoices = await _isar.isarInvoices
          .filter()
          .deletedAtIsNull()
          .and()
          .group((q) => q
            .numberContains(searchTerm, caseSensitive: false)
            .or()
            .notesContains(searchTerm, caseSensitive: false)
          )
          .sortByCreatedAtDesc()
          .limit(10)
          .findAll();
      
      final invoices = isarInvoices.map((isar) => isar.toEntity()).toList();
      return Right(invoices);
    } catch (e) {
      return Left(CacheFailure('Error searching invoices: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, InvoiceStats>> getInvoiceStats() async {
    try {
      print('📱 ISAR: Cargando estadísticas offline...');
      
      final collection = _isar.isarInvoices;
      
      // Get all invoices for calculations
      final allInvoices = await collection.filter().deletedAtIsNull().findAll();
      
      // Calculate stats
      final totalInvoices = allInvoices.length;
      final paidInvoices = allInvoices.where((inv) => inv.status == IsarInvoiceStatus.paid).length;
      final pendingInvoices = allInvoices.where((inv) => inv.status == IsarInvoiceStatus.pending).length;
      final cancelledInvoices = allInvoices.where((inv) => inv.status == IsarInvoiceStatus.cancelled).length;
      
      final totalAmount = allInvoices.fold<double>(0, (sum, inv) => sum + inv.total);
      // final paidAmount = allInvoices
      //     .where((inv) => inv.status == IsarInvoiceStatus.paid)
      //     .fold<double>(0, (sum, inv) => sum + inv.total);
      final pendingAmount = allInvoices
          .where((inv) => inv.status == IsarInvoiceStatus.pending)
          .fold<double>(0, (sum, inv) => sum + inv.total);
      
      // Count overdue invoices
      final now = DateTime.now();
      final overdueInvoices = allInvoices
          .where((inv) => inv.status == IsarInvoiceStatus.pending && inv.dueDate.isBefore(now))
          .length;

      final stats = InvoiceStats(
        total: totalInvoices,
        draft: 0, // Not tracked in current implementation
        pending: pendingInvoices,
        paid: paidInvoices,
        overdue: overdueInvoices,
        cancelled: cancelledInvoices,
        partiallyPaid: 0, // Not tracked in current implementation
        totalSales: totalAmount,
        pendingAmount: pendingAmount,
        overdueAmount: allInvoices
            .where((inv) => inv.status == IsarInvoiceStatus.pending && inv.dueDate.isBefore(now))
            .fold<double>(0, (sum, inv) => sum + inv.total),
      );

      print('✅ ISAR: Estadísticas cargadas');
      return Right(stats);
    } catch (e) {
      print('❌ ISAR: Error loading invoice stats: $e');
      return Left(CacheFailure('Error loading invoice stats: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Invoice>>> getInvoicesByCustomer(String customerId) async {
    try {
      final isarInvoices = await _isar.isarInvoices
          .filter()
          .customerIdEqualTo(customerId)
          .and()
          .deletedAtIsNull()
          .sortByCreatedAtDesc()
          .findAll();
      
      final invoices = isarInvoices.map((isar) => isar.toEntity()).toList();
      return Right(invoices);
    } catch (e) {
      return Left(CacheFailure('Error loading customer invoices: ${e.toString()}'));
    }
  }

  // ==================== WRITE OPERATIONS (STUB IMPLEMENTATIONS) ====================
  // For offline mode, these return errors since they require server operations

  @override
  Future<Either<Failure, Invoice>> createInvoice({
    required String customerId,
    required List items, // Using dynamic to avoid type issues
    String? number,
    DateTime? date,
    DateTime? dueDate,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    InvoiceStatus? status,
    double taxPercentage = 19,
    double discountPercentage = 0,
    double discountAmount = 0,
    String? notes,
    String? terms,
    Map<String, dynamic>? metadata,
    String? bankAccountId, // 🏦 ID de la cuenta bancaria para registrar el pago
  }) async {
    print('📱 InvoiceOfflineRepository: Creando factura offline para cliente: $customerId');
    try {
      // ✅ PASO 1: Generar ID temporal único
      final now = DateTime.now();
      final tempId = 'invoice_offline_${now.millisecondsSinceEpoch}_${customerId.hashCode}';

      // ✅ PASO 2: Generar número de factura temporal si no se proporciona
      final invoiceNumber = number ?? 'TEMP-${now.millisecondsSinceEpoch}';

      // ✅ PASO 3: Establecer fechas por defecto
      final invoiceDate = date ?? now;
      final invoiceDueDate = dueDate ?? now.add(const Duration(days: 30));

      // ✅ PASO 4: Establecer status por defecto
      final invoiceStatus = status ?? InvoiceStatus.draft;
      final isarStatus = _mapInvoiceStatusToIsar(invoiceStatus);

      // ✅ PASO 5: Calcular totales a partir de los items
      double calculatedSubtotal = 0;
      final invoiceItems = <IsarInvoiceItem>[];

      for (final item in items) {
        // Cast to dynamic to access properties
        final dynamic itemData = item;
        final double itemQuantity = (itemData.quantity as num).toDouble();
        final double itemUnitPrice = (itemData.unitPrice as num).toDouble();
        final double itemDiscountAmount = ((itemData.discountAmount ?? 0) as num).toDouble();
        final double itemDiscountPercentage = ((itemData.discountPercentage ?? 0) as num).toDouble();

        final itemSubtotal = (itemQuantity * itemUnitPrice) - itemDiscountAmount;
        calculatedSubtotal += itemSubtotal;

        // Crear IsarInvoiceItem para cada item
        final isarItem = IsarInvoiceItem.create(
          serverId: 'item_offline_${now.millisecondsSinceEpoch}_${itemData.hashCode}',
          description: itemData.description?.toString() ?? '',
          quantity: itemQuantity,
          unitPrice: itemUnitPrice,
          discountPercentage: itemDiscountPercentage,
          discountAmount: itemDiscountAmount,
          subtotal: itemSubtotal,
          unit: itemData.unit?.toString(),
          notes: itemData.notes?.toString(),
          invoiceId: tempId,
          productId: itemData.productId?.toString(),
          createdAt: now,
          updatedAt: now,
          isSynced: false,
          lastSyncAt: null,
        );

        invoiceItems.add(isarItem);
      }

      // ✅ PASO 6: Aplicar descuentos a nivel de factura
      final discountAtInvoiceLevel = discountAmount > 0
          ? discountAmount
          : (calculatedSubtotal * discountPercentage / 100);

      final subtotalAfterDiscount = calculatedSubtotal - discountAtInvoiceLevel;

      // ✅ PASO 7: Calcular impuestos
      final calculatedTaxAmount = subtotalAfterDiscount * taxPercentage / 100;

      // ✅ PASO 8: Calcular total
      final calculatedTotal = subtotalAfterDiscount + calculatedTaxAmount;

      // ✅ PASO 9: Obtener el usuario actual (si está disponible)
      String createdById = 'offline_user';
      try {
        final authController = Get.find<dynamic>();
        if (authController.currentUser != null) {
          createdById = authController.currentUser.id;
        }
      } catch (e) {
        print('⚠️ InvoiceOfflineRepository: No se pudo obtener usuario actual: $e');
      }

      // ✅ PASO 10: Crear IsarInvoice
      final isarInvoice = IsarInvoice.create(
        serverId: tempId,
        number: invoiceNumber,
        date: invoiceDate,
        dueDate: invoiceDueDate,
        status: isarStatus,
        paymentMethod: _mapPaymentMethodToIsar(paymentMethod),
        subtotal: calculatedSubtotal,
        taxPercentage: taxPercentage,
        taxAmount: calculatedTaxAmount,
        discountPercentage: discountPercentage,
        discountAmount: discountAtInvoiceLevel,
        total: calculatedTotal,
        paidAmount: 0.0,
        balanceDue: calculatedTotal,
        notes: notes,
        terms: terms,
        metadataJson: metadata?.toString(),
        customerId: customerId,
        createdById: createdById,
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        isSynced: false,
        lastSyncAt: null,
      );

      // ✅ PASO 11: Guardar en ISAR (factura + items)
      await _isar.writeTxn(() async {
        await _isar.isarInvoices.put(isarInvoice);
        // Note: Items are not stored separately in ISAR for now
        // They will be included in the sync operation
      });
      print('✅ InvoiceOfflineRepository: Factura guardada en ISAR con ID temporal: $tempId');

      // ✅ PASO 12: Convertir a entidad domain
      final invoice = Invoice(
        id: tempId,
        number: invoiceNumber,
        date: invoiceDate,
        dueDate: invoiceDueDate,
        status: invoiceStatus,
        paymentMethod: paymentMethod,
        subtotal: calculatedSubtotal,
        taxPercentage: taxPercentage,
        taxAmount: calculatedTaxAmount,
        discountPercentage: discountPercentage,
        discountAmount: discountAtInvoiceLevel,
        total: calculatedTotal,
        paidAmount: 0.0,
        balanceDue: calculatedTotal,
        notes: notes,
        terms: terms,
        metadata: metadata,
        customerId: customerId,
        createdById: createdById,
        items: invoiceItems.map((i) => i.toEntity()).toList(),
        payments: [],
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
      );

      // ✅ PASO 13: Guardar en SecureStorage si está disponible
      if (_localDataSource != null) {
        try {
          final invoiceModel = InvoiceModel.fromEntity(invoice);
          await _localDataSource.cacheInvoice(invoiceModel);
          print('✅ InvoiceOfflineRepository: Factura guardada en SecureStorage');
        } catch (e) {
          print('⚠️ Error guardando en SecureStorage (no crítico): $e');
        }
      }

      // ✅ PASO 14: Agregar a la cola de sincronización
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Invoice',
          entityId: tempId,
          operationType: SyncOperationType.create,
          data: {
            'customerId': customerId,
            'items': items.map((item) {
              final dynamic itemData = item;
              return {
                'description': itemData.description,
                'quantity': itemData.quantity,
                'unitPrice': itemData.unitPrice,
                'discountPercentage': itemData.discountPercentage,
                'discountAmount': itemData.discountAmount,
                'unit': itemData.unit,
                'notes': itemData.notes,
                'productId': itemData.productId,
              };
            }).toList(),
            'number': invoiceNumber,
            'date': invoiceDate.toIso8601String(),
            'dueDate': invoiceDueDate.toIso8601String(),
            'paymentMethod': paymentMethod.value,
            'status': invoiceStatus.value,
            'taxPercentage': taxPercentage,
            'discountPercentage': discountPercentage,
            'discountAmount': discountAtInvoiceLevel,
            'notes': notes,
            'terms': terms,
            'metadata': metadata,
            'bankAccountId': bankAccountId,
          },
          priority: 1, // Alta prioridad para creación
        );
        print('📤 InvoiceOfflineRepository: Operación agregada a cola de sincronización');
      } catch (e) {
        print('⚠️ Error agregando a sync queue (no crítico): $e');
      }

      print('✅ InvoiceOfflineRepository: Factura creada offline exitosamente');
      return Right(invoice);
    } catch (e) {
      print('❌ InvoiceOfflineRepository: Error creando factura offline: $e');
      return Left(CacheFailure('Error al crear factura offline: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Invoice>> updateInvoice({
    required String id,
    String? number,
    DateTime? date,
    DateTime? dueDate,
    PaymentMethod? paymentMethod,
    InvoiceStatus? status,
    double? taxPercentage,
    double? discountPercentage,
    double? discountAmount,
    String? notes,
    String? terms,
    Map<String, dynamic>? metadata,
    String? customerId,
    List? items,
  }) async {
    try {
      print('💾 InvoiceOfflineRepository: Actualizando factura offline: $id');

      // ✅ PASO 1: Actualizar en ISAR
      final isarInvoice = await _isar.isarInvoices
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarInvoice == null) {
        return Left(CacheFailure('Factura no encontrada en ISAR: $id'));
      }

      // Actualizar campos básicos
      if (number != null) isarInvoice.number = number;
      if (date != null) isarInvoice.date = date;
      if (dueDate != null) isarInvoice.dueDate = dueDate;
      if (taxPercentage != null) isarInvoice.taxPercentage = taxPercentage;
      if (discountPercentage != null) {
        isarInvoice.discountPercentage = discountPercentage;
      }
      if (discountAmount != null) isarInvoice.discountAmount = discountAmount;
      if (notes != null) isarInvoice.notes = notes;
      if (terms != null) isarInvoice.terms = terms;
      if (customerId != null) isarInvoice.customerId = customerId;
      if (status != null) isarInvoice.status = _mapInvoiceStatusToIsar(status);

      isarInvoice.markAsUnsynced();

      await _isar.writeTxn(() async {
        await _isar.isarInvoices.put(isarInvoice);
      });
      print('✅ InvoiceOfflineRepository: Factura actualizada en ISAR');

      // ✅ PASO 2: Agregar a la cola de sincronización
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Invoice',
          entityId: id,
          operationType: SyncOperationType.update,
          data: {
            if (number != null) 'number': number,
            if (date != null) 'date': date.toIso8601String(),
            if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
            if (paymentMethod != null) 'paymentMethod': paymentMethod.value,
            if (status != null) 'status': status.value,
            if (taxPercentage != null) 'taxPercentage': taxPercentage,
            if (discountPercentage != null) 'discountPercentage': discountPercentage,
            if (discountAmount != null) 'discountAmount': discountAmount,
            if (notes != null) 'notes': notes,
            if (terms != null) 'terms': terms,
            if (metadata != null) 'metadata': metadata,
            if (customerId != null) 'customerId': customerId,
          },
        );
        print('✅ InvoiceOfflineRepository: Factura agregada a cola de sincronización');
      } catch (e) {
        print('⚠️ Error agregando a sync queue (no crítico): $e');
      }

      // ✅ PASO 3: Actualizar SecureStorage si está disponible
      if (_localDataSource != null) {
        try {
          final invoiceModel = InvoiceModel.fromEntity(isarInvoice.toEntity());
          await _localDataSource.cacheInvoice(invoiceModel);
          print('✅ InvoiceOfflineRepository: Factura actualizada en SecureStorage');
        } catch (e) {
          print('⚠️ Error actualizando SecureStorage (no crítico): $e');
        }
      }

      return Right(isarInvoice.toEntity());
    } catch (e) {
      print('❌ Error actualizando factura offline: $e');
      return Left(CacheFailure('Error actualizando factura offline: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Invoice>> confirmInvoice(String id) async {
    return Left(ServerFailure('Confirm invoice not available offline'));
  }

  @override
  Future<Either<Failure, Invoice>> cancelInvoice(String id) async {
    return Left(ServerFailure('Cancel invoice not available offline'));
  }

  @override
  Future<Either<Failure, Invoice>> addPayment({
    required String invoiceId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? bankAccountId,
    DateTime? paymentDate,
    String? reference,
    String? notes,
  }) async {
    return Left(ServerFailure('Add payment not available offline'));
  }

  @override
  Future<Either<Failure, MultiplePaymentsResult>> addMultiplePayments({
    required String invoiceId,
    required List<PaymentItemData> payments,
    DateTime? paymentDate,
    bool createCreditForRemaining = false,
    String? generalNotes,
  }) async {
    return Left(ServerFailure('Add multiple payments not available offline'));
  }

  @override
  Future<Either<Failure, void>> deleteInvoice(String id) async {
    return Left(ServerFailure('Delete invoice not available offline'));
  }

  @override
  Future<Either<Failure, List<int>>> downloadInvoicePdf(String id) async {
    return Left(ServerFailure('Download PDF not available offline'));
  }

  // ==================== CACHE OPERATIONS ====================

  Future<Either<Failure, Unit>> bulkInsertInvoices(List<Invoice> invoices) async {
    try {
      final isarInvoices = invoices.map((inv) => IsarInvoice.fromEntity(inv)).toList();
      
      await _isar.writeTxn(() async {
        await _isar.isarInvoices.putAll(isarInvoices);
      });
      
      return Right(unit);
    } catch (e) {
      return Left(CacheFailure('Error bulk inserting invoices: ${e.toString()}'));
    }
  }

  Future<Either<Failure, Unit>> clearInvoiceCache() async {
    try {
      await _isar.writeTxn(() async {
        await _isar.isarInvoices.clear();
      });
      
      return Right(unit);
    } catch (e) {
      return Left(CacheFailure('Error clearing invoice cache: ${e.toString()}'));
    }
  }

  // ==================== HELPER METHODS ====================

  IsarInvoiceStatus _mapInvoiceStatusToIsar(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return IsarInvoiceStatus.draft;
      case InvoiceStatus.pending:
        return IsarInvoiceStatus.pending;
      case InvoiceStatus.paid:
        return IsarInvoiceStatus.paid;
      case InvoiceStatus.cancelled:
        return IsarInvoiceStatus.cancelled;
      case InvoiceStatus.overdue:
        return IsarInvoiceStatus.overdue;
      case InvoiceStatus.partiallyPaid:
        return IsarInvoiceStatus.partiallyPaid;
      case InvoiceStatus.credited:
        return IsarInvoiceStatus.credited;
      case InvoiceStatus.partiallyCredited:
        return IsarInvoiceStatus.partiallyCredited;
    }
  }

  IsarPaymentMethod _mapPaymentMethodToIsar(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return IsarPaymentMethod.cash;
      case PaymentMethod.credit:
        return IsarPaymentMethod.credit;
      case PaymentMethod.creditCard:
        return IsarPaymentMethod.creditCard;
      case PaymentMethod.debitCard:
        return IsarPaymentMethod.debitCard;
      case PaymentMethod.bankTransfer:
        return IsarPaymentMethod.bankTransfer;
      case PaymentMethod.check:
        return IsarPaymentMethod.check;
      case PaymentMethod.clientBalance:
        return IsarPaymentMethod.clientBalance;
      case PaymentMethod.other:
        return IsarPaymentMethod.other;
    }
  }
}