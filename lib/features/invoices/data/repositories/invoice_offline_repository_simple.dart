// lib/features/invoices/data/repositories/invoice_offline_repository_simple.dart
import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../../app/core/utils/app_logger.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../../../app/shared/services/subscription_validation_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_payment.dart';
import '../../domain/entities/invoice_stats.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../models/isar/isar_invoice.dart';
import '../models/isar/isar_invoice_item.dart';
import '../../../../app/data/local/enums/isar_enums.dart';
import '../datasources/invoice_local_datasource.dart';
import '../models/invoice_model.dart';
import '../../../customer_credits/domain/entities/customer_credit.dart';
import '../../../customer_credits/data/datasources/customer_credit_local_datasource_isar.dart';
import '../../../customers/data/models/isar/isar_customer.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../customer_credits/data/models/isar/isar_customer_credit.dart';
import '../../../inventory/data/repositories/inventory_offline_repository.dart';
import '../../../inventory/domain/entities/inventory_movement.dart';
import '../../../inventory/domain/repositories/inventory_repository.dart';
import '../../../products/data/models/isar/isar_product.dart';
import '../../../settings/presentation/controllers/user_preferences_controller.dart';

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
      AppLogger.d('ISAR: Cargando facturas offline...');
      
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

      // Convert to domain entities y resolver customers
      final rawInvoices = isarInvoices.map((isar) => isar.toEntity()).toList();
      final invoices = await _resolveCustomersForInvoices(rawInvoices);

      final totalPages = (totalItems / limit).ceil();
      final meta = PaginationMeta(
        page: page,
        limit: limit,
        totalItems: totalItems,
        totalPages: totalPages,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1,
      );

      AppLogger.i('ISAR: ${invoices.length} facturas cargadas');
      return Right(PaginatedResult(data: invoices, meta: meta));
    } catch (e) {
      AppLogger.e('ISAR: Error loading invoices: $e');
      return Left(CacheFailure('Error loading invoices: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Invoice>>> getOverdueInvoices() async {
    try {
      AppLogger.d('ISAR: Cargando facturas vencidas offline...');
      
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
      
      final rawInvoices = isarInvoices.map((isar) => isar.toEntity()).toList();
      final invoices = await _resolveCustomersForInvoices(rawInvoices);
      AppLogger.i('ISAR: ${invoices.length} facturas vencidas cargadas');
      return Right(invoices);
    } catch (e) {
      AppLogger.e('ISAR: Error loading overdue invoices: $e');
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

      final invoice = isarInvoice.toEntity();

      // Resolver customer desde ISAR para que customerName funcione
      final resolvedInvoice = await _resolveCustomerForInvoice(invoice);

      return Right(resolvedInvoice);
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

      final invoice = isarInvoice.toEntity();
      final resolvedInvoice = await _resolveCustomerForInvoice(invoice);
      return Right(resolvedInvoice);
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

      final rawInvoices = isarInvoices.map((isar) => isar.toEntity()).toList();
      final invoices = await _resolveCustomersForInvoices(rawInvoices);
      return Right(invoices);
    } catch (e) {
      return Left(CacheFailure('Error searching invoices: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, InvoiceStats>> getInvoiceStats() async {
    try {
      AppLogger.d('ISAR: Cargando estadísticas offline...');
      
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

      AppLogger.i('ISAR: Estadísticas cargadas');
      return Right(stats);
    } catch (e) {
      AppLogger.e('ISAR: Error loading invoice stats: $e');
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
      
      final rawInvoices = isarInvoices.map((isar) => isar.toEntity()).toList();
      final invoices = await _resolveCustomersForInvoices(rawInvoices);
      return Right(invoices);
    } catch (e) {
      return Left(CacheFailure('Error loading customer invoices: ${e.toString()}'));
    }
  }

  // ==================== HELPER: Resolver Customer desde ISAR ====================

  /// Carga el Customer desde ISAR y lo adjunta al Invoice via copyWith.
  /// Esto permite que invoice.customerName funcione correctamente offline.
  Future<Invoice> _resolveCustomerForInvoice(Invoice invoice) async {
    if (invoice.customerId.isEmpty) return invoice;
    try {
      final isarCustomer = await _isar.isarCustomers
          .filter()
          .serverIdEqualTo(invoice.customerId)
          .findFirst();

      if (isarCustomer != null) {
        return invoice.copyWith(customer: isarCustomer.toEntity());
      }
    } catch (e) {
      AppLogger.w('Error resolviendo customer para factura ${invoice.id}: $e');
    }
    return invoice;
  }

  /// Resuelve customers en batch para una lista de facturas.
  /// Optimizado: carga todos los customerIds de una vez.
  Future<List<Invoice>> _resolveCustomersForInvoices(List<Invoice> invoices) async {
    if (invoices.isEmpty) return invoices;
    try {
      // Recopilar customerIds únicos
      final customerIds = invoices.map((i) => i.customerId).where((id) => id.isNotEmpty).toSet();
      if (customerIds.isEmpty) return invoices;

      // Cargar todos los customers de una vez
      final customerMap = <String, IsarCustomer>{};
      for (final cid in customerIds) {
        final isarCustomer = await _isar.isarCustomers
            .filter()
            .serverIdEqualTo(cid)
            .findFirst();
        if (isarCustomer != null) {
          customerMap[cid] = isarCustomer;
        }
      }

      // Adjuntar customer a cada invoice
      return invoices.map((invoice) {
        final isarCustomer = customerMap[invoice.customerId];
        if (isarCustomer != null) {
          return invoice.copyWith(customer: isarCustomer.toEntity());
        }
        return invoice;
      }).toList();
    } catch (e) {
      AppLogger.w('Error resolviendo customers en batch: $e');
      return invoices;
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
    AppLogger.d('InvoiceOfflineRepository: Creando factura offline para cliente: $customerId');

    // 🔒 VALIDACIÓN DE SUSCRIPCIÓN (Segunda capa de defensa - ASYNC para ISAR)
    // Esta validación es crítica para modo offline donde el backend no puede validar
    final subscriptionInfo = await SubscriptionValidationService.getSubscriptionInfoAsync();
    if (subscriptionInfo != null && subscriptionInfo.isExpired) {
      AppLogger.w('OFFLINE REPO: Suscripción expirada - BLOQUEANDO creación de factura');
      AppLogger.w('   - Status: ${subscriptionInfo.status}');
      AppLogger.w('   - End Date: ${subscriptionInfo.endDate}');
      AppLogger.w('   - Source: ${subscriptionInfo.source}');
      return const Left(
        SubscriptionFailure(
          'Tu suscripción ha expirado. No puedes crear facturas hasta que renueves tu suscripción.',
        ),
      );
    }

    // Si no hay info de suscripción en ningún lado, BLOQUEAR
    if (subscriptionInfo == null) {
      AppLogger.w(' OFFLINE REPO: Sin info de suscripción disponible - BLOQUEANDO');
      return const Left(
        SubscriptionFailure(
          'No se puede verificar tu suscripción. Conéctate a internet para continuar.',
        ),
      );
    }

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

      // ✅ PASO 4.5: VALIDACIÓN CRÍTICA - Verificar que hay items
      if (items.isEmpty) {
        AppLogger.e('InvoiceOfflineRepository: No se puede crear factura sin items');
        return const Left(ValidationFailure(['Una factura debe tener al menos un item']));
      }

      // ✅ PASO 5: Calcular totales a partir de los items
      double calculatedSubtotal = 0;
      final invoiceItems = <IsarInvoiceItem>[];

      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        // Cast to dynamic to access properties
        final dynamic itemData = item;

        // Validar campos requeridos del item
        if (itemData.quantity == null || itemData.unitPrice == null) {
          AppLogger.e('InvoiceOfflineRepository: Item $i tiene campos requeridos faltantes');
          return Left(ValidationFailure(['Item ${i + 1} no tiene cantidad o precio unitario']));
        }

        final double itemQuantity = (itemData.quantity as num).toDouble();
        if (itemQuantity <= 0) {
          AppLogger.e('InvoiceOfflineRepository: Item $i tiene cantidad inválida: $itemQuantity');
          return Left(ValidationFailure(['Item ${i + 1} debe tener cantidad mayor a 0']));
        }

        final double itemUnitPrice = (itemData.unitPrice as num).toDouble();
        if (itemUnitPrice < 0) {
          AppLogger.e('InvoiceOfflineRepository: Item $i tiene precio negativo: $itemUnitPrice');
          return Left(ValidationFailure(['Item ${i + 1} no puede tener precio negativo']));
        }

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
      String organizationId = '';
      try {
        final authController = Get.find<AuthController>();
        if (authController.currentUser != null) {
          createdById = authController.currentUser!.id;
          organizationId = authController.currentUser!.organizationId;
        }
      } catch (e) {
        AppLogger.w(' InvoiceOfflineRepository: No se pudo obtener usuario actual: $e');
      }

      // ✅ PASO 10: Convertir items a JSON para almacenamiento
      final itemsJsonString = _encodeInvoiceItems(invoiceItems);
      AppLogger.d(' InvoiceOfflineRepository: ${invoiceItems.length} items codificados para ISAR');

      // ✅ PASO 10.5: Procesar pagos del metadata
      final paymentResult = _processPaymentsFromMetadata(
        metadata: metadata,
        invoiceId: tempId,
        invoiceTotal: calculatedTotal,
        primaryPaymentMethod: paymentMethod,
        invoiceStatus: invoiceStatus,
        bankAccountId: bankAccountId,
        createdById: createdById,
        organizationId: organizationId,
        now: now,
      );
      final totalPaid = paymentResult.$1;
      final paymentRecords = paymentResult.$2;
      final effectiveBalanceDue = calculatedTotal - totalPaid;

      AppLogger.d('InvoiceOfflineRepository: Pagos: paid=\$${totalPaid.toStringAsFixed(2)}, due=\$${effectiveBalanceDue.toStringAsFixed(2)}, records=${paymentRecords.length}');

      // ✅ PASO 11: Crear IsarInvoice CON items y pagos
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
        paidAmount: totalPaid,
        balanceDue: effectiveBalanceDue > 0 ? effectiveBalanceDue : 0,
        notes: notes,
        terms: terms,
        metadataJson: metadata != null ? _encodeMetadata(metadata) : null,
        paymentsJson: _encodePaymentsJson(paymentRecords),
        itemsJson: itemsJsonString,
        customerId: customerId,
        createdById: createdById,
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        isSynced: false,
        lastSyncAt: null,
      );

      // ✅ PASO 12: Guardar en ISAR (factura con items incluidos)
      await _isar.writeTxn(() async {
        await _isar.isarInvoices.put(isarInvoice);
      });
      AppLogger.i('InvoiceOfflineRepository: Factura guardada en ISAR con ID temporal: $tempId');

      // ✅ PASO 12: Resolver customer desde ISAR
      Customer? resolvedCustomer;
      try {
        final isarCustomer = await _isar.isarCustomers
            .filter()
            .serverIdEqualTo(customerId)
            .findFirst();
        if (isarCustomer != null) {
          resolvedCustomer = isarCustomer.toEntity();
        }
      } catch (e) {
        AppLogger.w('Error resolviendo customer al crear factura offline: $e');
      }

      // ✅ PASO 12.1: Convertir a entidad domain
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
        paidAmount: totalPaid,
        balanceDue: effectiveBalanceDue > 0 ? effectiveBalanceDue : 0,
        notes: notes,
        terms: terms,
        metadata: metadata,
        customerId: customerId,
        customer: resolvedCustomer,
        createdById: createdById,
        items: invoiceItems.map((i) => i.toEntity()).toList(),
        payments: paymentRecords,
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
      );

      // ✅ PASO 13: Guardar en SecureStorage si está disponible
      if (_localDataSource != null) {
        try {
          final invoiceModel = InvoiceModel.fromEntity(invoice);
          await _localDataSource.cacheInvoice(invoiceModel);
          AppLogger.i('InvoiceOfflineRepository: Factura guardada en SecureStorage');
        } catch (e) {
          AppLogger.w(' Error guardando en SecureStorage (no crítico): $e');
        }
      }

      // ✅ PASO 14: Agregar a la cola de sincronización
      try {
        final syncService = Get.find<SyncService>();

        final syncItems = items.map((item) {
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
        }).toList();

        await syncService.addOperationForCurrentUser(
          entityType: 'Invoice',
          entityId: tempId,
          operationType: SyncOperationType.create,
          data: {
            'customerId': customerId,
            'items': syncItems, // ✅ Usar items ya mapeados
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
        AppLogger.i(' InvoiceOfflineRepository: Operación agregada a cola de sincronización');
      } catch (e) {
        AppLogger.w(' Error agregando a sync queue (no crítico): $e');
      }

      // ✅ PASO 14.5: Deducir saldo a favor del cliente si fue aplicado
      await _deductClientBalanceIfNeeded(
        metadata: metadata,
        invoiceId: tempId,
        invoiceNumber: invoiceNumber,
        customerId: customerId,
        now: now,
      );

      // ✅ PASO 14.7: Descontar inventario FIFO si está habilitado
      if (invoiceStatus != InvoiceStatus.draft) {
        await _processInventoryForOfflineInvoice(
          invoice: invoice,
          createdById: createdById,
        );
      }

      // ✅ PASO 15: Generar crédito automático si hay saldo pendiente o venta a crédito
      await _generateCreditForRemainingIfNeeded(
        metadata: metadata,
        invoiceId: tempId,
        invoiceNumber: invoiceNumber,
        customerId: customerId,
        createdById: createdById,
        dueDate: invoiceDueDate,
        now: now,
        paymentMethod: paymentMethod,
        invoiceStatus: invoiceStatus,
        invoiceTotal: calculatedTotal,
      );

      AppLogger.i('InvoiceOfflineRepository: Factura creada offline exitosamente');
      return Right(invoice);
    } catch (e) {
      AppLogger.e('InvoiceOfflineRepository: Error creando factura offline: $e');
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
      AppLogger.d(' InvoiceOfflineRepository: Actualizando factura offline: $id');

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
      AppLogger.i('InvoiceOfflineRepository: Factura actualizada en ISAR');

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
        AppLogger.i('InvoiceOfflineRepository: Factura agregada a cola de sincronización');
      } catch (e) {
        AppLogger.w(' Error agregando a sync queue (no crítico): $e');
      }

      // ✅ PASO 3: Actualizar SecureStorage si está disponible
      if (_localDataSource != null) {
        try {
          final invoiceModel = InvoiceModel.fromEntity(isarInvoice.toEntity());
          await _localDataSource.cacheInvoice(invoiceModel);
          AppLogger.i('InvoiceOfflineRepository: Factura actualizada en SecureStorage');
        } catch (e) {
          AppLogger.w(' Error actualizando SecureStorage (no crítico): $e');
        }
      }

      return Right(isarInvoice.toEntity());
    } catch (e) {
      AppLogger.e(' Error actualizando factura offline: $e');
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
    String? paymentCurrency,
    double? paymentCurrencyAmount,
    double? exchangeRate,
  }) async {
    AppLogger.d('InvoiceOfflineRepository: addPayment offline invoiceId=$invoiceId amount=$amount');
    try {
      // 1. Buscar factura en ISAR
      final isarInvoice = await _isar.isarInvoices
          .filter()
          .serverIdEqualTo(invoiceId)
          .findFirst();

      if (isarInvoice == null) {
        return Left(CacheFailure('Factura no encontrada en ISAR: $invoiceId'));
      }

      final now = DateTime.now();

      // 2. Calcular nuevos montos
      final newPaidAmount = isarInvoice.paidAmount + amount;
      final newBalanceDue = (isarInvoice.total - newPaidAmount).clamp(0.0, double.infinity);

      // 3. Determinar nuevo status
      IsarInvoiceStatus newStatus;
      InvoiceStatus newEntityStatus;
      if (newBalanceDue <= 0) {
        newStatus = IsarInvoiceStatus.paid;
        newEntityStatus = InvoiceStatus.paid;
      } else if (newPaidAmount > 0) {
        newStatus = IsarInvoiceStatus.partiallyPaid;
        newEntityStatus = InvoiceStatus.partiallyPaid;
      } else {
        newStatus = isarInvoice.status;
        newEntityStatus = InvoiceStatus.pending;
      }

      // 4. Crear InvoicePayment con ID temporal
      final paymentTempId = 'payment_offline_${now.millisecondsSinceEpoch}_${invoiceId.hashCode}';
      String createdById = '';
      String organizationId = '';
      try {
        final authController = Get.find<AuthController>();
        if (authController.currentUser != null) {
          createdById = authController.currentUser!.id;
          organizationId = authController.currentUser!.organizationId;
        }
      } catch (_) {}

      final newPayment = InvoicePayment(
        id: paymentTempId,
        amount: amount,
        paymentMethod: paymentMethod,
        paymentDate: paymentDate ?? now,
        reference: reference,
        notes: notes,
        invoiceId: invoiceId,
        createdById: createdById,
        organizationId: organizationId,
        bankAccountId: bankAccountId,
        paymentCurrency: paymentCurrency,
        paymentCurrencyAmount: paymentCurrencyAmount,
        exchangeRate: exchangeRate,
        createdAt: now,
        updatedAt: now,
      );

      // 5. Decodificar pagos existentes, agregar nuevo, re-codificar
      final existingPayments = IsarInvoice.decodePayments(isarInvoice.paymentsJson);
      existingPayments.add(newPayment);

      // 6. Actualizar ISAR invoice
      isarInvoice.paidAmount = newPaidAmount;
      isarInvoice.balanceDue = newBalanceDue;
      isarInvoice.status = newStatus;
      isarInvoice.paymentsJson = IsarInvoice.encodePayments(existingPayments);
      isarInvoice.updatedAt = now;
      isarInvoice.isSynced = false;

      await _isar.writeTxn(() async {
        await _isar.isarInvoices.put(isarInvoice);
      });

      AppLogger.i('InvoiceOfflineRepository: Pago offline registrado: \$$amount → paidAmount=\$$newPaidAmount, balanceDue=\$$newBalanceDue, status=$newEntityStatus');

      // 7. Encolar en sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperation(
          entityType: 'Invoice',
          entityId: invoiceId,
          operationType: SyncOperationType.update,
          data: {
            'action': 'addPayment',
            'amount': amount,
            'paymentMethod': paymentMethod.value,
            'bankAccountId': bankAccountId,
            'paymentDate': (paymentDate ?? now).toIso8601String(),
            'reference': reference,
            if (paymentCurrency != null) 'paymentCurrency': paymentCurrency,
            if (paymentCurrencyAmount != null) 'paymentCurrencyAmount': paymentCurrencyAmount,
            if (exchangeRate != null) 'exchangeRate': exchangeRate,
            'notes': notes,
          },
          organizationId: organizationId,
        );
        AppLogger.d('InvoiceOfflineRepository: Operación addPayment encolada para sync');
      } catch (e) {
        AppLogger.w('InvoiceOfflineRepository: Error encolando addPayment: $e');
      }

      // 8. Cross-update: actualizar CustomerCredit asociado en ISAR
      await _crossUpdateCreditFromInvoicePayment(
        invoiceId: invoiceId,
        paymentAmount: amount,
      );

      // 9. Retornar la factura actualizada
      final updatedInvoice = isarInvoice.toEntity();
      final resolvedInvoice = await _resolveCustomerForInvoice(updatedInvoice);
      return Right(resolvedInvoice);
    } catch (e) {
      AppLogger.e('InvoiceOfflineRepository: Error en addPayment offline: $e');
      return Left(CacheFailure('Error al agregar pago offline: $e'));
    }
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

  /// Codifica los items de factura a JSON para almacenamiento en ISAR
  String _encodeInvoiceItems(List<IsarInvoiceItem> items) {
    if (items.isEmpty) return '[]';
    try {
      final list = items.map((item) => {
        'id': item.serverId,
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
        'createdAt': item.createdAt.toIso8601String(),
        'updatedAt': item.updatedAt.toIso8601String(),
      }).toList();
      return jsonEncode(list);
    } catch (e) {
      AppLogger.w(' Error codificando items: $e');
      return '[]';
    }
  }

  /// Codifica metadata a JSON string
  String _encodeMetadata(Map<String, dynamic> metadata) {
    if (metadata.isEmpty) return '{}';
    try {
      return jsonEncode(metadata);
    } catch (e) {
      AppLogger.w(' Error codificando metadata: $e');
      return '{}';
    }
  }

  // ==================== PROCESAMIENTO DE PAGOS OFFLINE ====================

  /// Procesa la información de pagos del metadata de la factura.
  /// Retorna un record con (totalPaid, paymentRecords).
  (double, List<InvoicePayment>) _processPaymentsFromMetadata({
    required Map<String, dynamic>? metadata,
    required String invoiceId,
    required double invoiceTotal,
    required PaymentMethod primaryPaymentMethod,
    required InvoiceStatus invoiceStatus,
    required String? bankAccountId,
    required String createdById,
    required String organizationId,
    required DateTime now,
  }) {
    final paymentRecords = <InvoicePayment>[];
    double totalPaid = 0;

    // Para draft o pending (crédito puro), no se crean pagos
    if (invoiceStatus == InvoiceStatus.draft ||
        invoiceStatus == InvoiceStatus.pending) {
      AppLogger.d('InvoiceOfflineRepository: Status=$invoiceStatus - sin pagos');
      return (0.0, paymentRecords);
    }

    // Procesar saldo a favor aplicado (si existe)
    final balanceApplied = (metadata?['clientBalanceApplied'] as num?)?.toDouble() ?? 0;
    if (balanceApplied > 0) {
      paymentRecords.add(InvoicePayment(
        id: 'payment_balance_offline_${now.millisecondsSinceEpoch}_${invoiceId.hashCode}',
        amount: balanceApplied,
        paymentMethod: PaymentMethod.clientBalance,
        paymentDate: now,
        reference: 'Saldo a favor aplicado',
        notes: 'Deducción automática de saldo del cliente',
        invoiceId: invoiceId,
        createdById: createdById,
        organizationId: organizationId,
        createdAt: now,
        updatedAt: now,
      ));
      totalPaid += balanceApplied;
      AppLogger.d('InvoiceOfflineRepository: Saldo a favor aplicado: \$${balanceApplied.toStringAsFixed(2)}');
    }

    // Verificar si hay pagos múltiples en metadata
    final isMultiplePayment = metadata?['isMultiplePayment'] == true;
    final multiplePayments = metadata?['multiplePayments'] as List?;

    if (isMultiplePayment && multiplePayments != null && multiplePayments.isNotEmpty) {
      // Procesar pagos múltiples del metadata
      for (int i = 0; i < multiplePayments.length; i++) {
        final paymentData = multiplePayments[i] as Map<String, dynamic>;
        final amount = (paymentData['amount'] as num).toDouble();
        final methodName = paymentData['method'] as String? ?? 'cash';
        final payBankAccountId = paymentData['bankAccountId'] as String?;
        final payBankAccountName = paymentData['bankAccountName'] as String?;

        final method = PaymentMethod.fromString(
          _normalizePaymentMethodName(methodName),
        );

        // Multi-moneda del pago individual
        final payCurrency = paymentData['paymentCurrency'] as String?;
        final payCurrencyAmount = (paymentData['paymentCurrencyAmount'] as num?)?.toDouble();
        final payExchangeRate = (paymentData['exchangeRate'] as num?)?.toDouble();

        paymentRecords.add(InvoicePayment(
          id: 'payment_offline_${now.millisecondsSinceEpoch}_${i}_${invoiceId.hashCode}',
          amount: amount,
          paymentMethod: method,
          paymentDate: now,
          reference: payBankAccountName != null ? 'Cuenta: $payBankAccountName' : null,
          notes: 'Pago ${i + 1} de ${multiplePayments.length}',
          invoiceId: invoiceId,
          createdById: createdById,
          organizationId: organizationId,
          bankAccountId: payBankAccountId,
          paymentCurrency: payCurrency,
          paymentCurrencyAmount: payCurrencyAmount,
          exchangeRate: payExchangeRate,
          createdAt: now,
          updatedAt: now,
        ));
        totalPaid += amount;
      }
      AppLogger.d('InvoiceOfflineRepository: ${multiplePayments.length} pagos múltiples procesados, total: \$${totalPaid.toStringAsFixed(2)}');
    } else if (invoiceStatus == InvoiceStatus.paid ||
               invoiceStatus == InvoiceStatus.partiallyPaid) {
      // Pago simple: crear un registro de pago por el monto correspondiente
      final cashAmount = invoiceTotal - balanceApplied;
      // Multi-moneda del pago simple (desde metadata)
      final simpleCurrency = metadata?['paymentCurrency'] as String?;
      final simpleCurrencyAmount = (metadata?['paymentCurrencyAmount'] as num?)?.toDouble();
      final simpleExchangeRate = (metadata?['exchangeRate'] as num?)?.toDouble();

      if (cashAmount > 0) {
        paymentRecords.add(InvoicePayment(
          id: 'payment_offline_${now.millisecondsSinceEpoch}_${invoiceId.hashCode}',
          amount: cashAmount,
          paymentMethod: primaryPaymentMethod,
          paymentDate: now,
          invoiceId: invoiceId,
          createdById: createdById,
          organizationId: organizationId,
          bankAccountId: bankAccountId,
          paymentCurrency: simpleCurrency,
          paymentCurrencyAmount: simpleCurrencyAmount,
          exchangeRate: simpleExchangeRate,
          createdAt: now,
          updatedAt: now,
        ));
        totalPaid += cashAmount;
        AppLogger.d('InvoiceOfflineRepository: Pago simple de \$${cashAmount.toStringAsFixed(2)} via ${primaryPaymentMethod.displayName}');
      }
    }

    return (totalPaid, paymentRecords);
  }

  /// Normaliza el nombre del método de pago del metadata al formato value del enum.
  /// El metadata almacena el .name del enum (ej: 'cash', 'creditCard', 'bankTransfer')
  /// mientras que PaymentMethod.fromString espera el .value (ej: 'cash', 'credit_card', 'bank_transfer')
  String _normalizePaymentMethodName(String name) {
    switch (name.toLowerCase()) {
      case 'cash':
        return 'cash';
      case 'credit':
        return 'credit';
      case 'creditcard':
        return 'credit_card';
      case 'debitcard':
        return 'debit_card';
      case 'banktransfer':
        return 'bank_transfer';
      case 'check':
        return 'check';
      case 'clientbalance':
        return 'client_balance';
      case 'other':
        return 'other';
      default:
        return name;
    }
  }

  /// Codifica una lista de InvoicePayment a JSON para almacenamiento en ISAR.
  /// Usa el mismo formato que IsarInvoice._encodePayments para consistencia.
  String _encodePaymentsJson(List<InvoicePayment> payments) {
    if (payments.isEmpty) return '[]';
    try {
      final list = payments.map((payment) => {
        'id': payment.id,
        'amount': payment.amount,
        'paymentMethod': payment.paymentMethod.value,
        'paymentDate': payment.paymentDate.toIso8601String(),
        'reference': payment.reference,
        'notes': payment.notes,
        'invoiceId': payment.invoiceId,
        'createdById': payment.createdById,
        'organizationId': payment.organizationId,
        'bankAccountId': payment.bankAccountId,
        'createdAt': payment.createdAt.toIso8601String(),
        'updatedAt': payment.updatedAt.toIso8601String(),
      }).toList();
      return jsonEncode(list);
    } catch (e) {
      AppLogger.w('InvoiceOfflineRepository: Error codificando pagos: $e');
      return '[]';
    }
  }

  // ==================== DEDUCCIÓN DE SALDO A FAVOR ====================

  /// Deduce el saldo a favor del cliente en ISAR cuando se aplica en una factura offline.
  Future<void> _deductClientBalanceIfNeeded({
    required Map<String, dynamic>? metadata,
    required String invoiceId,
    required String invoiceNumber,
    required String customerId,
    required DateTime now,
  }) async {
    if (metadata == null) return;

    final balanceApplied = (metadata['clientBalanceApplied'] as num?)?.toDouble() ?? 0;
    if (balanceApplied <= 0) return;

    try {
      await _isar.writeTxn(() async {
        final customer = await _isar.isarCustomers
            .filter()
            .serverIdEqualTo(customerId)
            .findFirst();

        if (customer != null) {
          final oldBalance = customer.currentBalance;
          customer.currentBalance = (oldBalance - balanceApplied).clamp(0, double.infinity);
          customer.markAsUnsynced();
          await _isar.isarCustomers.put(customer);
          AppLogger.i('InvoiceOfflineRepository: Saldo cliente: \$${oldBalance.toStringAsFixed(2)} → \$${customer.currentBalance.toStringAsFixed(2)}');
        }
      });

      // NOTA: No se agrega a sync queue porque el backend procesa la deducción
      // de saldo automáticamente al recibir la factura con metadata.clientBalanceApplied.
      // La actualización local en ISAR es suficiente para mostrar datos correctos offline.
    } catch (e) {
      AppLogger.e('InvoiceOfflineRepository: Error deduciendo saldo a favor: $e');
    }
  }

  // ==================== DESCUENTO DE INVENTARIO OFFLINE (FIFO) ====================

  /// Procesa el descuento de inventario para una factura creada offline.
  /// Utiliza el método FIFO del InventoryOfflineRepository para descontar
  /// de los lotes más antiguos primero, y actualiza el stock del producto en ISAR.
  Future<void> _processInventoryForOfflineInvoice({
    required Invoice invoice,
    required String createdById,
  }) async {
    try {
      // Verificar si el descuento automático está habilitado en preferencias
      bool autoDeduct = true;
      try {
        final userPrefsController = Get.find<UserPreferencesController>();
        autoDeduct = userPrefsController.autoDeductInventory;
      } catch (e) {
        AppLogger.w('InvoiceOfflineRepository: No se pudo obtener preferencias, autoDeduct=true por defecto');
      }

      if (!autoDeduct) return;

      final inventoryRepo = InventoryOfflineRepository();

      // Recopilar todas las deducciones de stock para hacer una sola transacción ISAR
      final stockDeductions = <String, int>{}; // productId -> totalQuantity
      int processedCount = 0;

      for (final item in invoice.items) {
        if (item.productId == null || item.productId!.isEmpty) continue;

        final quantityToDeduct = item.quantity.toInt();
        if (quantityToDeduct <= 0) continue;

        final params = ProcessFifoMovementParams(
          productId: item.productId!,
          quantity: quantityToDeduct,
          reason: InventoryMovementReason.sale,
          referenceType: 'invoice',
          referenceId: invoice.id,
          notes: 'Venta automática offline - Factura ${invoice.number}',
        );

        final result = await inventoryRepo.processOutboundMovementFifo(params);

        result.fold(
          (failure) {
            AppLogger.e('InvoiceOfflineRepository: Error FIFO producto ${item.productId}: ${failure.message}');
          },
          (movement) {
            processedCount++;
          },
        );

        // Acumular deducción para batch update
        stockDeductions[item.productId!] =
            (stockDeductions[item.productId!] ?? 0) + quantityToDeduct;
      }

      // Actualizar todos los stocks de productos en UNA SOLA transacción ISAR
      if (stockDeductions.isNotEmpty) {
        await _batchUpdateProductStocks(stockDeductions);
      }

      if (processedCount > 0) {
        AppLogger.i('InvoiceOfflineRepository: Inventario FIFO procesado - $processedCount items');
      }
    } catch (e) {
      AppLogger.e('InvoiceOfflineRepository: Error procesando inventario offline: $e');
    }
  }

  /// Actualiza el stock de múltiples productos en una sola transacción ISAR.
  /// Mucho más eficiente que N transacciones individuales.
  Future<void> _batchUpdateProductStocks(Map<String, int> stockDeductions) async {
    try {
      // Pre-fetch todos los productos necesarios en una sola consulta
      final productIds = stockDeductions.keys.toList();
      final products = <IsarProduct>[];

      for (final productId in productIds) {
        final product = await _isar.isarProducts
            .filter()
            .serverIdEqualTo(productId)
            .findFirst();
        if (product != null) {
          final deduction = stockDeductions[productId]!;
          product.stock = (product.stock - deduction).clamp(0, double.infinity).toDouble();
          product.markAsUnsynced();
          products.add(product);
        }
      }

      if (products.isEmpty) return;

      // Una sola transacción para todos los productos
      await _isar.writeTxn(() async {
        await _isar.isarProducts.putAll(products);
      });

      AppLogger.d('InvoiceOfflineRepository: Stock actualizado para ${products.length} productos en batch');
    } catch (e) {
      AppLogger.e('InvoiceOfflineRepository: Error actualizando stocks en batch: $e');
    }
  }

  // ==================== GENERACIÓN DE CRÉDITO PARA SALDO PENDIENTE ====================

  /// Genera un CustomerCredit automáticamente cuando la factura tiene pago parcial
  /// y el metadata indica createCreditForRemaining = true.
  /// Replica el comportamiento del backend para modo offline.
  Future<void> _generateCreditForRemainingIfNeeded({
    required Map<String, dynamic>? metadata,
    required String invoiceId,
    required String invoiceNumber,
    required String customerId,
    required String createdById,
    required DateTime dueDate,
    required DateTime now,
    PaymentMethod? paymentMethod,
    InvoiceStatus? invoiceStatus,
    double? invoiceTotal,
  }) async {
    // Detectar factura a crédito puro (método crédito + estado pendiente)
    final bool isPureCreditInvoice = paymentMethod == PaymentMethod.credit &&
        invoiceStatus == InvoiceStatus.pending &&
        (invoiceTotal ?? 0) > 0;

    final createCredit = metadata?['createCreditForRemaining'] == true;
    final remainingBalance = (metadata?['remainingBalance'] as num?)?.toDouble() ?? 0;

    if (!createCredit && !isPureCreditInvoice) return;

    final creditAmount = isPureCreditInvoice ? (invoiceTotal ?? 0) : remainingBalance;
    if (creditAmount <= 0) return;

    AppLogger.i('InvoiceOfflineRepository: Generando crédito offline${isPureCreditInvoice ? " (venta a crédito)" : " (saldo pendiente)"}: \$$creditAmount');

    try {
      // Obtener organizationId del usuario actual
      String organizationId = '';
      String createdByName = '';
      try {
        final authController = Get.find<AuthController>();
        if (authController.currentUser != null) {
          organizationId = authController.currentUser!.organizationId;
          final firstName = authController.currentUser!.firstName;
          final lastName = authController.currentUser!.lastName;
          createdByName = '$firstName $lastName'.trim();
        }
      } catch (e) {
        AppLogger.w('InvoiceOfflineRepository: No se pudo obtener info de usuario para crédito: $e');
      }

      // Obtener nombre del cliente desde ISAR
      String? customerName;
      try {
        final customer = await _isar.isarCustomers
            .filter()
            .serverIdEqualTo(customerId)
            .findFirst();
        if (customer != null) {
          customerName = '${customer.firstName} ${customer.lastName}'.trim();
        }
      } catch (e) {
        AppLogger.w('InvoiceOfflineRepository: No se pudo obtener nombre de cliente: $e');
      }

      // Generar ID temporal para el crédito
      final creditTempId = 'credit_offline_${now.millisecondsSinceEpoch}_${invoiceId.hashCode}';

      // Crear la entidad CustomerCredit
      final credit = CustomerCredit(
        id: creditTempId,
        originalAmount: creditAmount,
        paidAmount: 0,
        balanceDue: creditAmount,
        status: CreditStatus.pending,
        dueDate: dueDate,
        description: isPureCreditInvoice
            ? 'Crédito por venta a crédito - factura $invoiceNumber'
            : 'Crédito por saldo pendiente de factura $invoiceNumber',
        notes: 'Generado automáticamente al crear factura offline',
        customerId: customerId,
        customerName: customerName,
        invoiceId: invoiceId,
        invoiceNumber: invoiceNumber,
        organizationId: organizationId,
        createdById: createdById,
        createdByName: createdByName,
        payments: [],
        createdAt: now,
        updatedAt: now,
      );

      // Guardar en ISAR usando CustomerCreditLocalDataSourceIsar
      final creditLocalDs = CustomerCreditLocalDataSourceIsar(_database);
      await creditLocalDs.cacheCreditForSync(credit);

      // NOTA: No se agrega a sync queue porque el backend genera el crédito
      // automáticamente al recibir la factura con metadata.createCreditForRemaining.
      // El crédito local en ISAR es suficiente para mostrar datos correctos offline.

      AppLogger.i('InvoiceOfflineRepository: Crédito local generado por \$$creditAmount para factura $invoiceNumber');
    } catch (e) {
      AppLogger.e('InvoiceOfflineRepository: Error generando crédito offline: $e');
      // No fallar la creación de factura por error en crédito
    }
  }

  // ==================== CROSS-UPDATE: CRÉDITO DESDE PAGO DE FACTURA ====================

  /// Cuando se hace un pago en una factura, actualiza el CustomerCredit asociado en ISAR.
  /// NO encola a sync queue - el backend maneja la cross-update al procesar el pago.
  Future<void> _crossUpdateCreditFromInvoicePayment({
    required String invoiceId,
    required double paymentAmount,
  }) async {
    try {
      final isarCredit = await _isar.isarCustomerCredits
          .filter()
          .invoiceIdEqualTo(invoiceId)
          .and()
          .deletedAtIsNull()
          .findFirst();

      if (isarCredit == null) {
        AppLogger.d('InvoiceOfflineRepository: No hay CustomerCredit asociado a factura $invoiceId');
        return;
      }

      final newPaidAmount = isarCredit.paidAmount + paymentAmount;
      final newBalanceDue = (isarCredit.originalAmount - newPaidAmount).clamp(0.0, double.infinity);

      isarCredit.paidAmount = newPaidAmount;
      isarCredit.balanceDue = newBalanceDue;
      isarCredit.updatedAt = DateTime.now();

      if (newBalanceDue <= 0) {
        isarCredit.status = IsarCreditStatus.paid;
      } else if (newPaidAmount > 0) {
        isarCredit.status = IsarCreditStatus.partiallyPaid;
      }

      await _isar.writeTxn(() async {
        await _isar.isarCustomerCredits.put(isarCredit);
      });

      AppLogger.i('InvoiceOfflineRepository: CustomerCredit ${isarCredit.serverId} actualizado: paidAmount=\$$newPaidAmount, balanceDue=\$$newBalanceDue');
    } catch (e) {
      AppLogger.w('InvoiceOfflineRepository: Error en cross-update crédito: $e');
    }
  }
}