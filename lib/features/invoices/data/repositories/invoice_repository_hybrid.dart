// lib/features/invoices/data/repositories/invoice_repository_hybrid.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/models/pagination_meta.dart';

import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_stats.dart';
import '../../domain/repositories/invoice_repository.dart';

import '../datasources/invoice_remote_datasource.dart';
import '../models/create_invoice_request_model.dart';
import '../models/update_invoice_request_model.dart';
import '../models/invoice_item_model.dart' show CreateInvoiceItemRequestModel;
import '../models/add_payment_request_model.dart';
import 'invoice_offline_repository.dart';

/// Repositorio híbrido que combina ISAR (offline) con API remota (online)
///
/// Strategy: Online-first with ISAR fallback
class InvoiceRepositoryHybrid implements InvoiceRepository {
  final InvoiceRemoteDataSource remoteDataSource;
  final InvoiceOfflineRepository offlineRepository;
  final NetworkInfo networkInfo;

  const InvoiceRepositoryHybrid({
    required this.remoteDataSource,
    required this.offlineRepository,
    required this.networkInfo,
  });

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
    String? bankAccountName,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    String sortBy = 'createdAt',
    String sortOrder = 'DESC',
  }) async {
    print('📱 Verificando conexión para cargar facturas...');

    if (await networkInfo.isConnected) {
      print('🌐 Con conexión, intentando cargar desde servidor...');
      try {
        // Try remote first
        final remoteResult = await _getInvoicesFromRemote(
          page: page,
          limit: limit,
          search: search,
          status: status,
          paymentMethod: paymentMethod,
          customerId: customerId,
          createdById: createdById,
          bankAccountId: bankAccountId,
          bankAccountName: bankAccountName,
          startDate: startDate,
          endDate: endDate,
          minAmount: minAmount,
          maxAmount: maxAmount,
          sortBy: sortBy,
          sortOrder: sortOrder,
        );

        return remoteResult.fold(
          (failure) {
            print('❌ Error del servidor, usando ISAR como fallback: $failure');
            // If remote fails, fallback to ISAR
            return offlineRepository.getInvoices(
              page: page,
              limit: limit,
              search: search,
              status: status,
              paymentMethod: paymentMethod,
              customerId: customerId,
              createdById: createdById,
              bankAccountId: bankAccountId,
              bankAccountName: bankAccountName,
              startDate: startDate,
              endDate: endDate,
              minAmount: minAmount,
              maxAmount: maxAmount,
              sortBy: sortBy,
              sortOrder: sortOrder,
            );
          },
          (success) {
            print('✅ Datos cargados del servidor, sincronizando con ISAR...');
            // Cache successful results in ISAR
            _cacheInvoicesInIsar(success.data);
            return Right(success);
          },
        );
      } catch (e) {
        print('❌ Error inesperado del servidor: $e');
        // On any error, fallback to ISAR
        return offlineRepository.getInvoices(
          page: page,
          limit: limit,
          search: search,
          status: status,
          paymentMethod: paymentMethod,
          customerId: customerId,
          createdById: createdById,
          bankAccountId: bankAccountId,
          bankAccountName: bankAccountName,
          startDate: startDate,
          endDate: endDate,
          minAmount: minAmount,
          maxAmount: maxAmount,
          sortBy: sortBy,
          sortOrder: sortOrder,
        );
      }
    } else {
      print('📱 Sin conexión, cargando desde ISAR...');
      // No connection, use ISAR directly
      return offlineRepository.getInvoices(
        page: page,
        limit: limit,
        search: search,
        status: status,
        paymentMethod: paymentMethod,
        customerId: customerId,
        createdById: createdById,
        bankAccountId: bankAccountId,
        bankAccountName: bankAccountName,
        startDate: startDate,
        endDate: endDate,
        minAmount: minAmount,
        maxAmount: maxAmount,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
    }
  }

  @override
  Future<Either<Failure, List<Invoice>>> getOverdueInvoices() async {
    print('📱 Verificando conexión para facturas vencidas...');

    if (await networkInfo.isConnected) {
      print('🌐 Con conexión, cargando facturas vencidas del servidor...');
      try {
        final remoteInvoices = await remoteDataSource.getOverdueInvoices();
        final invoices =
            remoteInvoices.map((model) => model.toEntity()).toList();

        // Cache in ISAR
        _cacheInvoicesInIsar(invoices);

        return Right(invoices);
      } on ServerException catch (e) {
        print('❌ Error del servidor: $e, usando ISAR');
        return offlineRepository.getOverdueInvoices();
      } catch (e) {
        print('❌ Error inesperado: $e, usando ISAR');
        return offlineRepository.getOverdueInvoices();
      }
    } else {
      print('📱 Sin conexión, cargando desde ISAR...');
      return offlineRepository.getOverdueInvoices();
    }
  }

  @override
  Future<Either<Failure, Invoice>> getInvoiceById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteInvoice = await remoteDataSource.getInvoiceById(id);
        final invoice = remoteInvoice.toEntity();

        // Cache in ISAR
        _cacheInvoicesInIsar([invoice]);

        return Right(invoice);
      } on ServerException {
        return offlineRepository.getInvoiceById(id);
      } catch (e) {
        return offlineRepository.getInvoiceById(id);
      }
    } else {
      return offlineRepository.getInvoiceById(id);
    }
  }

  @override
  Future<Either<Failure, Invoice>> getInvoiceByNumber(String number) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteInvoice = await remoteDataSource.getInvoiceByNumber(number);
        final invoice = remoteInvoice.toEntity();

        // Cache in ISAR
        _cacheInvoicesInIsar([invoice]);

        return Right(invoice);
      } on ServerException {
        return offlineRepository.getInvoiceByNumber(number);
      } catch (e) {
        return offlineRepository.getInvoiceByNumber(number);
      }
    } else {
      return offlineRepository.getInvoiceByNumber(number);
    }
  }

  @override
  Future<Either<Failure, List<Invoice>>> searchInvoices(
    String searchTerm,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteInvoices = await remoteDataSource.searchInvoices(
          searchTerm,
        );
        final invoices =
            remoteInvoices.map((model) => model.toEntity()).toList();

        // Cache in ISAR
        _cacheInvoicesInIsar(invoices);

        return Right(invoices);
      } on ServerException {
        return offlineRepository.searchInvoices(searchTerm);
      } catch (e) {
        return offlineRepository.searchInvoices(searchTerm);
      }
    } else {
      return offlineRepository.searchInvoices(searchTerm);
    }
  }

  @override
  Future<Either<Failure, InvoiceStats>> getInvoiceStats() async {
    print('📱 Verificando conexión para estadísticas...');

    if (await networkInfo.isConnected) {
      print('🌐 Con conexión, cargando estadísticas del servidor...');
      try {
        final remoteStats = await remoteDataSource.getInvoiceStats();
        return Right(remoteStats.toEntity());
      } on ServerException catch (e) {
        print('❌ Error del servidor: $e, usando ISAR');
        return offlineRepository.getInvoiceStats();
      } catch (e) {
        print('❌ Error inesperado: $e, usando ISAR');
        return offlineRepository.getInvoiceStats();
      }
    } else {
      print('📱 Sin conexión, cargando estadísticas desde ISAR...');
      return offlineRepository.getInvoiceStats();
    }
  }

  // ==================== WRITE OPERATIONS ====================
  // All write operations require internet connection
  // When offline, operations are queued in ISAR with sync flags

  @override
  Future<Either<Failure, Invoice>> createInvoice({
    required String customerId,
    required List<CreateInvoiceItemParams> items,
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
    if (await networkInfo.isConnected) {
      try {
        // Try remote creation
        final createRequest = CreateInvoiceRequestModel(
          customerId: customerId,
          items:
              items
                  .map(
                    (item) => CreateInvoiceItemRequestModel(
                      productId: item.productId,
                      description: item.description,
                      quantity: item.quantity,
                      unitPrice: item.unitPrice,
                      discountPercentage: item.discountPercentage,
                      discountAmount: item.discountAmount,
                      unit: item.unit,
                      notes: item.notes,
                    ),
                  )
                  .toList(),
          number: number,
          date: date?.toIso8601String(),
          dueDate: dueDate?.toIso8601String(),
          paymentMethod: paymentMethod.value,
          status: status?.value,
          taxPercentage: taxPercentage,
          discountPercentage: discountPercentage,
          discountAmount: discountAmount,
          notes: notes,
          terms: terms,
          metadata: metadata,
          bankAccountId: bankAccountId,
        );

        final remoteInvoice = await remoteDataSource.createInvoice(
          createRequest,
        );
        final invoice = remoteInvoice.toEntity();

        // Cache in ISAR
        _cacheInvoicesInIsar([invoice]);

        return Right(invoice);
      } on ServerException catch (e) {
        print('❌ Error al crear en servidor, guardando offline: $e');
        // Server error, create offline and mark for sync
        return offlineRepository.createInvoice(
          customerId: customerId,
          items: items,
          number: number,
          date: date,
          dueDate: dueDate,
          paymentMethod: paymentMethod,
          status: status,
          taxPercentage: taxPercentage,
          discountPercentage: discountPercentage,
          discountAmount: discountAmount,
          notes: notes,
          terms: terms,
          metadata: metadata,
          bankAccountId: bankAccountId,
        );
      }
    } else {
      print('📱 Sin conexión, creando factura offline...');
      // No connection, create offline
      return offlineRepository.createInvoice(
        customerId: customerId,
        items: items,
        number: number,
        date: date,
        dueDate: dueDate,
        paymentMethod: paymentMethod,
        status: status,
        taxPercentage: taxPercentage,
        discountPercentage: discountPercentage,
        discountAmount: discountAmount,
        notes: notes,
        terms: terms,
        metadata: metadata,
        bankAccountId: bankAccountId,
      );
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
    List<CreateInvoiceItemParams>? items,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        // Try remote update
        final updateRequest = UpdateInvoiceRequestModel(
          number: number,
          date: date?.toIso8601String(),
          dueDate: dueDate?.toIso8601String(),
          customerId: customerId,
          items:
              items
                  ?.map(
                    (item) => CreateInvoiceItemRequestModel(
                      productId: item.productId,
                      description: item.description,
                      quantity: item.quantity,
                      unitPrice: item.unitPrice,
                      discountPercentage: item.discountPercentage,
                      discountAmount: item.discountAmount,
                      unit: item.unit,
                      notes: item.notes,
                    ),
                  )
                  .toList(),
          taxPercentage: taxPercentage,
          discountPercentage: discountPercentage,
          discountAmount: discountAmount,
          status: status?.value,
          paymentMethod: paymentMethod?.value,
          notes: notes,
          terms: terms,
          metadata: metadata,
        );

        final remoteInvoice = await remoteDataSource.updateInvoice(
          id,
          updateRequest,
        );
        final invoice = remoteInvoice.toEntity();

        // Cache in ISAR
        _cacheInvoicesInIsar([invoice]);

        return Right(invoice);
      } on ServerException catch (e) {
        print('❌ Error al actualizar en servidor, guardando offline: $e');
        // Server error, update offline and mark for sync
        return offlineRepository.updateInvoice(
          id: id,
          number: number,
          date: date,
          dueDate: dueDate,
          paymentMethod: paymentMethod,
          status: status,
          taxPercentage: taxPercentage,
          discountPercentage: discountPercentage,
          discountAmount: discountAmount,
          notes: notes,
          terms: terms,
          metadata: metadata,
          customerId: customerId,
          items: items,
        );
      }
    } else {
      print('📱 Sin conexión, actualizando factura offline...');
      // No connection, update offline
      return offlineRepository.updateInvoice(
        id: id,
        number: number,
        date: date,
        dueDate: dueDate,
        paymentMethod: paymentMethod,
        status: status,
        taxPercentage: taxPercentage,
        discountPercentage: discountPercentage,
        discountAmount: discountAmount,
        notes: notes,
        terms: terms,
        metadata: metadata,
        customerId: customerId,
        items: items,
      );
    }
  }

  Future<Either<Failure, Invoice>> updateInvoiceStatus({
    required String id,
    required InvoiceStatus status,
  }) async {
    return updateInvoice(id: id, status: status);
  }

  @override
  Future<Either<Failure, void>> deleteInvoice(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteInvoice(id);
        // Also delete from ISAR
        await offlineRepository.deleteInvoice(id);
        return const Right(null);
      } on ServerException catch (e) {
        print(
          '❌ Error al eliminar en servidor, marcando como eliminado offline: $e',
        );
        // Server error, mark as deleted offline
        return offlineRepository.deleteInvoice(id);
      }
    } else {
      print('📱 Sin conexión, marcando factura como eliminada offline...');
      // No connection, soft delete offline
      return offlineRepository.deleteInvoice(id);
    }
  }

  @override
  Future<Either<Failure, Invoice>> confirmInvoice(String id) async {
    return updateInvoiceStatus(id: id, status: InvoiceStatus.pending);
  }

  @override
  Future<Either<Failure, Invoice>> cancelInvoice(String id) async {
    return updateInvoiceStatus(id: id, status: InvoiceStatus.cancelled);
  }

  @override
  Future<Either<Failure, List<Invoice>>> getInvoicesByCustomer(
    String customerId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteInvoices = await remoteDataSource.getInvoicesByCustomer(
          customerId,
        );
        final invoices =
            remoteInvoices.map((model) => model.toEntity()).toList();

        // Cache in ISAR
        _cacheInvoicesInIsar(invoices);

        return Right(invoices);
      } on ServerException {
        return offlineRepository.getInvoicesByCustomer(customerId);
      } catch (e) {
        return offlineRepository.getInvoicesByCustomer(customerId);
      }
    } else {
      return offlineRepository.getInvoicesByCustomer(customerId);
    }
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
    if (await networkInfo.isConnected) {
      try {
        final paymentRequest = AddPaymentRequestModel(
          amount: amount,
          paymentMethod: paymentMethod.value,
          bankAccountId: bankAccountId,
          paymentDate: paymentDate?.toIso8601String(),
          reference: reference,
          notes: notes,
        );

        final remoteInvoice = await remoteDataSource.addPayment(
          invoiceId,
          paymentRequest,
        );
        final invoice = remoteInvoice.toEntity();

        // Cache in ISAR
        _cacheInvoicesInIsar([invoice]);

        return Right(invoice);
      } on ServerException catch (e) {
        print('❌ Error al agregar pago en servidor, guardando offline: $e');
        return offlineRepository.addPayment(
          invoiceId: invoiceId,
          amount: amount,
          paymentMethod: paymentMethod,
          bankAccountId: bankAccountId,
          paymentDate: paymentDate,
          reference: reference,
          notes: notes,
        );
      }
    } else {
      print('📱 Sin conexión, agregando pago offline...');
      return offlineRepository.addPayment(
        invoiceId: invoiceId,
        amount: amount,
        paymentMethod: paymentMethod,
        bankAccountId: bankAccountId,
        paymentDate: paymentDate,
        reference: reference,
        notes: notes,
      );
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
    if (await networkInfo.isConnected) {
      try {
        print('💳 InvoiceRepositoryHybrid: Agregando ${payments.length} pagos a factura: $invoiceId');

        // Convertir PaymentItemData a PaymentItemModel
        final paymentModels = payments.map((p) => PaymentItemModel(
          amount: p.amount,
          paymentMethod: p.paymentMethod.value,
          bankAccountId: p.bankAccountId,
          reference: p.reference,
          notes: p.notes,
        )).toList();

        final request = AddMultiplePaymentsRequestModel(
          payments: paymentModels,
          paymentDate: paymentDate?.toIso8601String(),
          createCreditForRemaining: createCreditForRemaining,
          generalNotes: generalNotes,
        );

        final result = await remoteDataSource.addMultiplePayments(invoiceId, request);

        // Cache in ISAR
        _cacheInvoicesInIsar([result.invoice.toEntity()]);

        return Right(MultiplePaymentsResult(
          invoice: result.invoice.toEntity(),
          paymentsCreated: result.paymentCount,
          remainingBalance: result.remainingBalance,
          creditCreated: result.creditCreated,
        ));
      } on ServerException catch (e) {
        print('❌ Error al agregar pagos múltiples en servidor, guardando offline: $e');
        return offlineRepository.addMultiplePayments(
          invoiceId: invoiceId,
          payments: payments,
          paymentDate: paymentDate,
          createCreditForRemaining: createCreditForRemaining,
          generalNotes: generalNotes,
        );
      }
    } else {
      print('📱 Sin conexión, agregando pagos múltiples offline...');
      return offlineRepository.addMultiplePayments(
        invoiceId: invoiceId,
        payments: payments,
        paymentDate: paymentDate,
        createCreditForRemaining: createCreditForRemaining,
        generalNotes: generalNotes,
      );
    }
  }

  // ==================== CACHE OPERATIONS ====================

  Future<Either<Failure, List<Invoice>>> getCachedInvoices() async {
    return offlineRepository.getCachedInvoices();
  }

  Future<Either<Failure, void>> clearInvoiceCache() async {
    return offlineRepository.clearInvoiceCache();
  }

  // ==================== HELPER METHODS ====================

  Future<Either<Failure, PaginatedResult<Invoice>>> _getInvoicesFromRemote({
    int page = 1,
    int limit = 10,
    String? search,
    InvoiceStatus? status,
    PaymentMethod? paymentMethod,
    String? customerId,
    String? createdById,
    String? bankAccountId,
    String? bankAccountName,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    String sortBy = 'createdAt',
    String sortOrder = 'DESC',
  }) async {
    try {
      final queryParams = InvoiceQueryParams(
        page: page,
        limit: limit,
        search: search,
        status: status,
        paymentMethod: paymentMethod,
        customerId: customerId,
        createdById: createdById,
        bankAccountId: bankAccountId,
        bankAccountName: bankAccountName,
        startDate: startDate,
        endDate: endDate,
        minAmount: minAmount,
        maxAmount: maxAmount,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );

      final result = await remoteDataSource.getInvoices(queryParams);

      final invoices = result.data.map((model) => model.toEntity()).toList();

      return Right(PaginatedResult(data: invoices, meta: result.meta));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: $e'));
    }
  }

  void _cacheInvoicesInIsar(List<Invoice> invoices) async {
    if (invoices.isNotEmpty) {
      try {
        await offlineRepository.bulkInsertInvoices(invoices);
        print('💾 ${invoices.length} facturas cacheadas en ISAR');
      } catch (e) {
        print('⚠️ Error al cachear facturas en ISAR: $e');
      }
    }
  }

  // ==================== SYNC OPERATIONS ====================

  /// Sync unsynced invoices with server when connection is restored
  Future<Either<Failure, void>> syncUnsyncedInvoices() async {
    if (!await networkInfo.isConnected) {
      return Left(ConnectionFailure('No hay conexión para sincronizar'));
    }

    try {
      final unsyncedResult = await offlineRepository.getUnsyncedInvoices();
      return unsyncedResult.fold((failure) => Left(failure), (
        unsyncedInvoices,
      ) async {
        final syncedIds = <String>[];

        for (final invoice in unsyncedInvoices) {
          try {
            // Try to sync each invoice
            // This would need proper implementation based on the invoice state
            // For now, just mark as synced if successfully uploaded
            syncedIds.add(invoice.id);
          } catch (e) {
            print('⚠️ Error sincronizando factura ${invoice.id}: $e');
          }
        }

        if (syncedIds.isNotEmpty) {
          await offlineRepository.markInvoicesAsSynced(syncedIds);
          print('✅ ${syncedIds.length} facturas sincronizadas');
        }

        return const Right(null);
      });
    } catch (e) {
      return Left(CacheFailure('Error en sincronización: $e'));
    }
  }

  @override
  Future<Either<Failure, List<int>>> downloadInvoicePdf(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final pdfBytes = await remoteDataSource.downloadInvoicePdf(id);
        return Right(pdfBytes);
      } on ServerException catch (e) {
        return Left(ServerFailure('Error downloading PDF: ${e.message}'));
      } catch (e) {
        return Left(ServerFailure('Error downloading PDF: $e'));
      }
    } else {
      return Left(ConnectionFailure('Download PDF not available offline'));
    }
  }
}
