// lib/features/invoices/data/repositories/invoice_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';

import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_stats.dart';
import '../../domain/repositories/invoice_repository.dart';

import '../datasources/invoice_local_datasource.dart';
import '../datasources/invoice_remote_datasource.dart';
import '../models/invoice_model.dart';
import '../models/isar/isar_invoice.dart';
import 'invoice_offline_repository_simple.dart';

import '../models/create_invoice_request_model.dart';
import '../models/update_invoice_request_model.dart';
import '../models/add_payment_request_model.dart';
import '../models/invoice_item_model.dart' show CreateInvoiceItemRequestModel;

class InvoiceRepositoryImpl implements InvoiceRepository {
  final InvoiceRemoteDataSource remoteDataSource;
  final InvoiceLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final InvoiceOfflineRepositorySimple? offlineRepository;

  const InvoiceRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    this.offlineRepository,
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
    try {
      print('📄 InvoiceRepository: Obteniendo facturas...');

      // Crear parámetros de query
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

      if (await networkInfo.isConnected) {
        // Intentar obtener desde el servidor
        try {
          print('🌐 Obteniendo facturas del servidor...');
          final remoteResponse = await remoteDataSource.getInvoices(
            queryParams,
          );

          // Cachear los resultados si es la primera página y no hay filtros específicos
          if (page == 1 &&
              search == null &&
              status == null &&
              customerId == null) {
            try {
              await localDataSource.cacheInvoices(remoteResponse.data);
              print('💾 Facturas cacheadas exitosamente');
            } catch (e) {
              print('⚠️ Error al cachear facturas: $e');
              // No es crítico, continuar
            }
          }

          return Right(remoteResponse.toPaginatedResult());
        } catch (e) {
          print('❌ Error al obtener facturas del servidor: $e');

          // Si falla el servidor, intentar desde cache
          return _getInvoicesFromCache(queryParams);
        }
      } else {
        print('📱 Sin conexión, obteniendo desde cache...');
        return _getInvoicesFromCache(queryParams);
      }
    } catch (e) {
      print('❌ Error inesperado en getInvoices: $e');
      return Left(ServerFailure('Error inesperado al obtener facturas'));
    }
  }

  @override
  Future<Either<Failure, Invoice>> getInvoiceById(String id) async {
    try {
      print('📄 InvoiceRepository: Obteniendo factura por ID: $id');

      if (await networkInfo.isConnected) {
        try {
          print('🌐 Obteniendo factura del servidor...');
          final remoteInvoice = await remoteDataSource.getInvoiceById(id);

          // Cachear la factura individual
          try {
            await localDataSource.cacheInvoice(remoteInvoice);
            print('💾 Factura cacheada exitosamente');
          } catch (e) {
            print('⚠️ Error al cachear factura: $e');
          }

          return Right(remoteInvoice);
        } catch (e) {
          print('❌ Error al obtener factura del servidor: $e');

          // Intentar desde cache
          try {
            final cachedInvoice = await localDataSource.getCachedInvoice(id);
            if (cachedInvoice != null) {
              print('💾 Factura obtenida desde cache');
              return Right(cachedInvoice);
            }
          } catch (cacheError) {
            print('❌ SecureStorage falló para getInvoiceById: $cacheError');
            print('🔄 Intentando con ISAR offline repository...');
            
            // Fallback to ISAR when SecureStorage fails
            try {
              final offlineRepo = offlineRepository ?? InvoiceOfflineRepositorySimple(localDataSource: localDataSource);
              final result = await offlineRepo.getInvoiceById(id);
              
              return result.fold(
                (failure) => Left(_mapExceptionToFailure(e)),
                (invoice) {
                  print('✅ ISAR: Factura obtenida como fallback');
                  return Right(invoice);
                },
              );
            } catch (isarError) {
              print('❌ Error crítico en ISAR fallback: $isarError');
            }
          }

          return Left(_mapExceptionToFailure(e));
        }
      } else {
        print('📱 Sin conexión, obteniendo desde cache...');
        try {
          final cachedInvoice = await localDataSource.getCachedInvoice(id);
          if (cachedInvoice != null) {
            return Right(cachedInvoice);
          }
        } catch (cacheError) {
          print('❌ SecureStorage falló en modo offline: $cacheError');
          print('🔄 Intentando con ISAR offline repository...');
          
          // Fallback to ISAR when SecureStorage fails
          try {
            final offlineRepo = offlineRepository ?? InvoiceOfflineRepositorySimple(localDataSource: localDataSource);
            final result = await offlineRepo.getInvoiceById(id);
            
            return result.fold(
              (failure) => const Left(ConnectionFailure('Sin conexión a internet')),
              (invoice) {
                print('✅ ISAR: Factura obtenida offline como fallback');
                return Right(invoice);
              },
            );
          } catch (isarError) {
            print('❌ Error crítico en ISAR offline: $isarError');
          }
        }

        return const Left(ConnectionFailure('Sin conexión a internet'));
      }
    } catch (e) {
      print('❌ Error inesperado en getInvoiceById: $e');
      return Left(ServerFailure('Error inesperado al obtener factura'));
    }
  }

  @override
  Future<Either<Failure, Invoice>> getInvoiceByNumber(String number) async {
    try {
      print('📄 InvoiceRepository: Obteniendo factura por número: $number');

      if (await networkInfo.isConnected) {
        try {
          final remoteInvoice = await remoteDataSource.getInvoiceByNumber(
            number,
          );

          // Cachear la factura
          try {
            await localDataSource.cacheInvoice(remoteInvoice);
          } catch (e) {
            print('⚠️ Error al cachear factura: $e');
          }

          return Right(remoteInvoice);
        } catch (e) {
          print('❌ Error al obtener factura del servidor: $e');

          // Intentar desde cache
          final cachedInvoice = await localDataSource.getCachedInvoiceByNumber(
            number,
          );
          if (cachedInvoice != null) {
            return Right(cachedInvoice);
          }

          return Left(_mapExceptionToFailure(e));
        }
      } else {
        final cachedInvoice = await localDataSource.getCachedInvoiceByNumber(
          number,
        );
        if (cachedInvoice != null) {
          return Right(cachedInvoice);
        }

        return const Left(ConnectionFailure('Sin conexión a internet'));
      }
    } catch (e) {
      return Left(
        ServerFailure('Error inesperado al obtener factura por número'),
      );
    }
  }

  @override
  Future<Either<Failure, List<Invoice>>> getOverdueInvoices() async {
    try {
      print('📄 InvoiceRepository: Obteniendo facturas vencidas...');

      if (await networkInfo.isConnected) {
        try {
          final remoteInvoices = await remoteDataSource.getOverdueInvoices();
          return Right(remoteInvoices);
        } catch (e) {
          print('❌ Error al obtener facturas vencidas del servidor: $e');

          // Intentar desde cache
          final cachedInvoices =
              await localDataSource.getCachedOverdueInvoices();
          return Right(cachedInvoices);
        }
      } else {
        final cachedInvoices = await localDataSource.getCachedOverdueInvoices();
        return Right(cachedInvoices);
      }
    } catch (e) {
      return Left(
        ServerFailure('Error inesperado al obtener facturas vencidas'),
      );
    }
  }

  @override
  Future<Either<Failure, InvoiceStats>> getInvoiceStats() async {
    try {
      print('📊 InvoiceRepository: Obteniendo estadísticas...');

      if (await networkInfo.isConnected) {
        try {
          final remoteStats = await remoteDataSource.getInvoiceStats();

          // Cachear estadísticas
          try {
            await localDataSource.cacheInvoiceStats(remoteStats);
            print('💾 Estadísticas cacheadas exitosamente');
          } catch (e) {
            print('⚠️ Error al cachear estadísticas: $e');
          }

          return Right(remoteStats);
        } catch (e) {
          print('❌ Error al obtener estadísticas del servidor: $e');

          // Intentar desde cache
          final cachedStats = await localDataSource.getCachedInvoiceStats();
          if (cachedStats != null) {
            print('💾 Estadísticas obtenidas desde cache');
            return Right(cachedStats);
          }

          return Left(_mapExceptionToFailure(e));
        }
      } else {
        print('📱 Sin conexión, obteniendo desde cache...');
        final cachedStats = await localDataSource.getCachedInvoiceStats();
        if (cachedStats != null) {
          return Right(cachedStats);
        }

        return const Left(ConnectionFailure('Sin conexión a internet'));
      }
    } catch (e) {
      print('❌ Error inesperado en getInvoiceStats: $e');
      return Left(ServerFailure('Error inesperado al obtener estadísticas'));
    }
  }

  @override
  Future<Either<Failure, List<Invoice>>> getInvoicesByCustomer(
    String customerId,
  ) async {
    try {
      print(
        '👤 InvoiceRepository: Obteniendo facturas del cliente: $customerId',
      );

      if (await networkInfo.isConnected) {
        try {
          final remoteInvoices = await remoteDataSource.getInvoicesByCustomer(
            customerId,
          );
          return Right(remoteInvoices);
        } catch (e) {
          print('❌ Error al obtener facturas del cliente del servidor: $e');

          // Intentar desde cache
          final cachedInvoices = await localDataSource
              .getCachedInvoicesByCustomer(customerId);
          return Right(cachedInvoices);
        }
      } else {
        final cachedInvoices = await localDataSource
            .getCachedInvoicesByCustomer(customerId);
        return Right(cachedInvoices);
      }
    } catch (e) {
      return Left(
        ServerFailure('Error inesperado al obtener facturas del cliente'),
      );
    }
  }

  @override
  Future<Either<Failure, List<Invoice>>> searchInvoices(
    String searchTerm,
  ) async {
    try {
      print('🔍 InvoiceRepository: Buscando facturas: $searchTerm');

      if (await networkInfo.isConnected) {
        try {
          final remoteInvoices = await remoteDataSource.searchInvoices(
            searchTerm,
          );
          return Right(remoteInvoices);
        } catch (e) {
          print('❌ Error al buscar facturas en el servidor: $e');

          // Intentar desde cache
          final cachedInvoices = await localDataSource.searchCachedInvoices(
            searchTerm,
          );
          return Right(cachedInvoices);
        }
      } else {
        final cachedInvoices = await localDataSource.searchCachedInvoices(
          searchTerm,
        );
        return Right(cachedInvoices);
      }
    } catch (e) {
      return Left(ServerFailure('Error inesperado al buscar facturas'));
    }
  }

  // ==================== WRITE OPERATIONS ====================

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
    if (!(await networkInfo.isConnected)) {
      // ============ MODO OFFLINE: Delegar al repositorio offline ============
      if (offlineRepository != null) {
        print('💾 InvoiceRepository: Modo offline - delegando a offline repository');
        return offlineRepository!.createInvoice(
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
      return const Left(
        ConnectionFailure(
          'No hay conexión a internet y repositorio offline no disponible',
        ),
      );
    }

    try {
      print('📄 InvoiceRepository: Creando factura...');
      if (bankAccountId != null) {
        print('🏦 Cuenta bancaria seleccionada: $bankAccountId');
      }

      // Convertir parámetros a request model
      final request = CreateInvoiceRequestModel(
        customerId: customerId,
        items:
            items
                .map((item) => CreateInvoiceItemRequestModel.fromEntity(item))
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

      final createdInvoice = await remoteDataSource.createInvoice(request);

      // Cachear la nueva factura
      try {
        await localDataSource.cacheInvoice(createdInvoice);
        print('💾 Nueva factura cacheada');
      } catch (e) {
        print('⚠️ Error al cachear nueva factura: $e');
      }

      return Right(createdInvoice);
    } on ServerException catch (e) {
      print('⚠️ [INVOICE_REPO] ServerException al crear: ${e.message}');
      if (offlineRepository != null) {
        print('🔄 Fallback a offline repository...');
        return offlineRepository!.createInvoice(
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
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      print('⚠️ [INVOICE_REPO] Exception al crear: $e - Intentando offline...');
      if (offlineRepository != null) {
        print('🔄 Fallback a offline repository...');
        return offlineRepository!.createInvoice(
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
      return Left(_mapExceptionToFailure(e));
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
    if (!(await networkInfo.isConnected)) {
      // ============ MODO OFFLINE: Delegar al repositorio offline ============
      if (offlineRepository != null) {
        print('💾 InvoiceRepository: Modo offline - delegando a offline repository');
        return offlineRepository!.updateInvoice(
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
      return const Left(
        ConnectionFailure(
          'No hay conexión a internet y repositorio offline no disponible',
        ),
      );
    }

    try {
      print('📄 InvoiceRepository: Actualizando factura: $id');

      final request = UpdateInvoiceRequestModel(
        number: number,
        date: date?.toIso8601String(),
        dueDate: dueDate?.toIso8601String(),
        paymentMethod: paymentMethod?.value,
        status: status?.value,
        taxPercentage: taxPercentage,
        discountPercentage: discountPercentage,
        discountAmount: discountAmount,
        notes: notes,
        terms: terms,
        metadata: metadata,
        customerId: customerId,
        items:
            items
                ?.map((item) => CreateInvoiceItemRequestModel.fromEntity(item))
                .toList(),
      );

      final updatedInvoice = await remoteDataSource.updateInvoice(id, request);

      // Actualizar cache
      try {
        await localDataSource.cacheInvoice(updatedInvoice);
        print('💾 Factura actualizada en cache');
      } catch (e) {
        print('⚠️ Error al actualizar factura en cache: $e');
      }

      return Right(updatedInvoice);
    } on ServerException catch (e) {
      print('⚠️ [INVOICE_REPO] ServerException al actualizar: ${e.message}');
      if (offlineRepository != null) {
        print('🔄 Fallback a offline repository...');
        return offlineRepository!.updateInvoice(
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
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      print('⚠️ [INVOICE_REPO] Exception al actualizar: $e - Intentando offline...');
      if (offlineRepository != null) {
        return offlineRepository!.updateInvoice(
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
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Invoice>> confirmInvoice(String id) async {
    if (!(await networkInfo.isConnected)) {
      return const Left(
        ConnectionFailure(
          'Se requiere conexión a internet para confirmar facturas',
        ),
      );
    }

    try {
      final confirmedInvoice = await remoteDataSource.confirmInvoice(id);

      // Actualizar cache
      try {
        await localDataSource.cacheInvoice(confirmedInvoice);
      } catch (e) {
        print('⚠️ Error al actualizar factura confirmada en cache: $e');
      }

      return Right(confirmedInvoice);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Invoice>> cancelInvoice(String id) async {
    if (!(await networkInfo.isConnected)) {
      return const Left(
        ConnectionFailure(
          'Se requiere conexión a internet para cancelar facturas',
        ),
      );
    }

    try {
      final cancelledInvoice = await remoteDataSource.cancelInvoice(id);

      // Actualizar cache
      try {
        await localDataSource.cacheInvoice(cancelledInvoice);
      } catch (e) {
        print('⚠️ Error al actualizar factura cancelada en cache: $e');
      }

      return Right(cancelledInvoice);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
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
    if (!(await networkInfo.isConnected)) {
      return const Left(
        ConnectionFailure('Se requiere conexión a internet para agregar pagos'),
      );
    }

    try {
      final request = AddPaymentRequestModel(
        amount: amount,
        paymentMethod: paymentMethod.value,
        bankAccountId: bankAccountId,
        paymentDate: paymentDate?.toIso8601String(),
        reference: reference,
        notes: notes,
      );

      final updatedInvoice = await remoteDataSource.addPayment(
        invoiceId,
        request,
      );

      // Actualizar cache
      try {
        await localDataSource.cacheInvoice(updatedInvoice);
      } catch (e) {
        print('⚠️ Error al actualizar factura con pago en cache: $e');
      }

      return Right(updatedInvoice);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
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
    if (!(await networkInfo.isConnected)) {
      return const Left(
        ConnectionFailure('Se requiere conexión a internet para agregar pagos'),
      );
    }

    try {
      print('💳 InvoiceRepository: Agregando ${payments.length} pagos a factura: $invoiceId');

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

      // Actualizar cache con la factura actualizada
      try {
        await localDataSource.cacheInvoice(result.invoice);
        print('💾 Factura actualizada en cache después de pagos múltiples');
      } catch (e) {
        print('⚠️ Error al actualizar factura en cache: $e');
      }

      return Right(MultiplePaymentsResult(
        invoice: result.invoice,
        paymentsCreated: result.paymentCount,
        remainingBalance: result.remainingBalance,
        creditCreated: result.creditCreated,
      ));
    } catch (e) {
      print('❌ Error al agregar pagos múltiples: $e');
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteInvoice(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteInvoice(id);

        // Soft delete en ISAR después de eliminar en servidor
        try {
          final isar = IsarDatabase.instance.database;
          final isarInvoice = await isar.isarInvoices
              .filter()
              .serverIdEqualTo(id)
              .findFirst();

          if (isarInvoice != null) {
            isarInvoice.softDelete();
            await isar.writeTxn(() async {
              await isar.isarInvoices.put(isarInvoice);
            });
            print('✅ Invoice marcada como eliminada en ISAR: $id');
          }
        } catch (e) {
          print('⚠️ Error actualizando ISAR (no crítico): $e');
        }

        // Remover del cache
        try {
          await localDataSource.removeCachedInvoice(id);
        } catch (e) {
          print('⚠️ Error al remover factura del cache: $e');
        }

        return const Right(null);
      } on ServerException catch (e) {
        print('⚠️ [INVOICE_REPO] ServerException al eliminar: ${e.message} - Fallback offline...');
        return _deleteInvoiceOffline(id);
      } catch (e) {
        print('⚠️ [INVOICE_REPO] Exception al eliminar: $e - Fallback offline...');
        return _deleteInvoiceOffline(id);
      }
    } else {
      // Sin conexión, marcar para eliminación offline y sincronizar después
      return _deleteInvoiceOffline(id);
    }
  }

  Future<Either<Failure, void>> _deleteInvoiceOffline(String id) async {
    print('📱 InvoiceRepository: Deleting invoice offline: $id');
      try {
        // Soft delete en ISAR
        final isar = IsarDatabase.instance.database;
        final isarInvoice = await isar.isarInvoices
            .filter()
            .serverIdEqualTo(id)
            .findFirst();

        if (isarInvoice != null) {
          isarInvoice.softDelete();
          await isar.writeTxn(() async {
            await isar.isarInvoices.put(isarInvoice);
          });
          print('✅ Invoice marcada como eliminada en ISAR (offline): $id');
        }

        // Remover del cache (no crítico)
        try {
          await localDataSource.removeCachedInvoice(id);
        } catch (e) {
          print('⚠️ Error al actualizar cache (no crítico): $e');
        }

        // Agregar a la cola de sincronización
        try {
          final syncService = Get.find<SyncService>();
          await syncService.addOperationForCurrentUser(
            entityType: 'Invoice',
            entityId: id,
            operationType: SyncOperationType.delete,
            data: {'id': id},
            priority: 1,
          );
          print('📤 InvoiceRepository: Eliminación agregada a cola de sincronización');
        } catch (e) {
          print('⚠️ InvoiceRepository: Error agregando eliminación a cola: $e');
        }

        print('✅ InvoiceRepository: Invoice deleted offline successfully');
        return const Right(null);
      } catch (e) {
        print('❌ InvoiceRepository: Error deleting invoice offline: $e');
        return Left(CacheFailure('Error al eliminar factura offline: $e'));
      }
  }

  // ==================== HELPER METHODS ====================

  /// Obtener facturas desde cache con filtrado básico
  Future<Either<Failure, PaginatedResult<Invoice>>> _getInvoicesFromCache(
    InvoiceQueryParams params,
  ) async {
    try {
      print('💾 Intentando cargar facturas desde SecureStorage...');
      List<InvoiceModel> cachedInvoices =
          await localDataSource.getCachedInvoices();

      // Aplicar filtros básicos
      if (params.search != null && params.search!.isNotEmpty) {
        cachedInvoices = await localDataSource.searchCachedInvoices(
          params.search!,
        );
      }

      if (params.status != null) {
        cachedInvoices =
            cachedInvoices
                .where((invoice) => invoice.status == params.status)
                .toList();
      }

      if (params.customerId != null) {
        cachedInvoices =
            cachedInvoices
                .where((invoice) => invoice.customerId == params.customerId)
                .toList();
      }

      // Aplicar ordenamiento básico
      if (params.sortBy == 'createdAt') {
        cachedInvoices.sort(
          (a, b) =>
              params.sortOrder == 'DESC'
                  ? b.createdAt.compareTo(a.createdAt)
                  : a.createdAt.compareTo(b.createdAt),
        );
      }

      // Aplicar paginación básica
      final startIndex = (params.page - 1) * params.limit;
      final endIndex = startIndex + params.limit;

      final paginatedInvoices =
          cachedInvoices.length > startIndex
              ? cachedInvoices.sublist(
                startIndex,
                endIndex > cachedInvoices.length
                    ? cachedInvoices.length
                    : endIndex,
              )
              : <InvoiceModel>[];

      // Crear meta de paginación
      final totalPages = (cachedInvoices.length / params.limit).ceil();
      final meta = PaginationMeta(
        page: params.page,
        limit: params.limit,
        totalItems: cachedInvoices.length,
        totalPages: totalPages,
        hasNextPage: params.page < totalPages,
        hasPreviousPage: params.page > 1,
      );

      print('✅ SecureStorage: ${paginatedInvoices.length} facturas cargadas');
      return Right(
        PaginatedResult<Invoice>(data: paginatedInvoices, meta: meta),
      );
    } catch (e) {
      print('❌ SecureStorage falló: $e');
      print('🔄 Intentando con ISAR offline repository...');
      
      // Fallback to ISAR when SecureStorage fails
      try {
        final offlineRepo = offlineRepository ?? InvoiceOfflineRepositorySimple(localDataSource: localDataSource);
        final result = await offlineRepo.getInvoices(
          page: params.page,
          limit: params.limit,
          search: params.search,
          status: params.status,
          paymentMethod: params.paymentMethod,
          customerId: params.customerId,
          createdById: params.createdById,
          startDate: params.startDate,
          endDate: params.endDate,
          minAmount: params.minAmount,
          maxAmount: params.maxAmount,
          sortBy: params.sortBy,
          sortOrder: params.sortOrder,
        );
        
        return result.fold(
          (failure) {
            print('❌ ISAR también falló: ${failure.message}');
            return Left(CacheFailure('Error al obtener facturas desde cache y ISAR'));
          },
          (paginatedResult) {
            print('✅ ISAR: ${paginatedResult.data.length} facturas cargadas como fallback');
            return Right(paginatedResult);
          },
        );
      } catch (isarError) {
        print('❌ Error crítico en ISAR fallback: $isarError');
        return Left(CacheFailure('Error crítico al obtener facturas: $isarError'));
      }
    }
  }

  /// Mapear excepciones a failures
  Failure _mapExceptionToFailure(Object exception) {
    if (exception is ServerException) {
      if (exception.statusCode != null) {
        return ServerFailure.fromStatusCode(
          exception.statusCode!,
          exception.message,
        );
      } else {
        return ServerFailure(exception.message);
      }
    } else if (exception is ConnectionException) {
      return ConnectionFailure(exception.message);
    } else if (exception is CacheException) {
      return CacheFailure(exception.message);
    } else {
      return ServerFailure('Error inesperado: ${exception.toString()}');
    }
  }

  /// ✅ NUEVO: Descargar PDF de factura
  @override
  Future<Either<Failure, List<int>>> downloadInvoicePdf(String id) async {
    try {
      print('📄 InvoiceRepositoryImpl: Descargando PDF de factura $id');

      final pdfBytes = await remoteDataSource.downloadInvoicePdf(id);

      print('✅ PDF descargado: ${pdfBytes.length} bytes');
      return Right(pdfBytes);
    } catch (exception) {
      print('❌ Error al descargar PDF: $exception');
      return Left(_mapExceptionToFailure(exception));
    }
  }

  // ==================== SYNC OPERATIONS ====================

  /// Sincronizar facturas creadas offline con el servidor
  ///
  /// NOTA: Este método delega al offlineRepository si está disponible
  /// porque Invoices es más complejo (tiene items relacionados)
  Future<Either<Failure, List<Invoice>>> syncOfflineInvoices() async {
    if (!await networkInfo.isConnected) {
      return const Left(ConnectionFailure.noInternet);
    }

    // NOTA: Por ahora syncOfflineInvoices está deshabilitado porque requiere
    // manejo complejo de items relacionados. Las facturas offline se sincronizan
    // cuando se procesa la sync queue general.
    print('⚠️ syncOfflineInvoices: Método no implementado completamente');
    print('   Las facturas offline se sincronizan via SyncService');
    return const Right([]);

    /* TODO: Implementar sync completo de invoices con items
    try {
      print('🔄 InvoiceRepository: Starting offline invoices sync...');

      // Obtener facturas no sincronizadas desde ISAR
      final isar = IsarDatabase.instance.database;
      final unsyncedInvoices = await isar.isarInvoices
          .filter()
          .isSyncedEqualTo(false)
          .and()
          .deletedAtIsNull()
          .findAll();

      if (unsyncedInvoices.isEmpty) {
        print('✅ InvoiceRepository: No invoices to sync');
        return const Right([]);
      }

      print('📤 InvoiceRepository: Syncing ${unsyncedInvoices.length} offline invoices...');
      final syncedInvoices = <Invoice>[];

      for (final isarInvoice in unsyncedInvoices) {
        try {
          // Determinar si es CREATE o UPDATE basándose en el serverId
          final isCreate = isarInvoice.serverId.startsWith('invoice_offline_');

          if (isCreate) {
            // CREATE: Enviar al servidor y actualizar con ID real
            print('📝 Creating invoice: ${isarInvoice.number}');

            // Cargar items de la factura desde ISAR
            await isar.isarInvoices.filter().serverIdEqualTo(isarInvoice.serverId).findFirst();
            await isarInvoice.items.load();

            // Convertir items a CreateInvoiceItemParams
            final itemsParams = isarInvoice.items.map((item) {
              return CreateInvoiceItemParams(
                productId: item.productId,
                description: item.description,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                taxPercentage: item.taxPercentage ?? 0,
                discountPercentage: item.discountPercentage ?? 0,
                discountAmount: item.discountAmount ?? 0,
              );
            }).toList();

            final request = CreateInvoiceRequestModel(
              customerId: isarInvoice.customerId,
              items: itemsParams.map((item) => CreateInvoiceItemRequestModel.fromEntity(item)).toList(),
              number: isarInvoice.number,
              date: isarInvoice.date.toIso8601String(),
              dueDate: isarInvoice.dueDate?.toIso8601String(),
              paymentMethod: isarInvoice.paymentMethod,
              status: isarInvoice.status,
              taxPercentage: isarInvoice.taxPercentage,
              discountPercentage: isarInvoice.discountPercentage,
              discountAmount: isarInvoice.discountAmount,
              notes: isarInvoice.notes,
              terms: isarInvoice.terms,
              bankAccountId: isarInvoice.bankAccountId,
            );

            final created = await remoteDataSource.createInvoice(request);

            // Actualizar ISAR con el ID real del servidor
            isarInvoice.serverId = created.id;
            isarInvoice.markAsSynced();

            await isar.writeTxn(() async {
              await isar.isarInvoices.put(isarInvoice);
            });

            // También actualizar en SecureStorage
            await localDataSource.cacheInvoice(created);

            syncedInvoices.add(created);
            print('✅ Invoice created and synced: ${isarInvoice.number} -> ${created.id}');
          } else {
            // UPDATE: Enviar actualización al servidor
            print('📝 Updating invoice: ${isarInvoice.number}');

            // Cargar items de la factura desde ISAR
            await isarInvoice.items.load();

            // Convertir items a CreateInvoiceItemParams
            final itemsParams = isarInvoice.items.map((item) {
              return CreateInvoiceItemParams(
                productId: item.productId,
                description: item.description,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                taxPercentage: item.taxPercentage ?? 0,
                discountPercentage: item.discountPercentage ?? 0,
                discountAmount: item.discountAmount ?? 0,
              );
            }).toList();

            final request = UpdateInvoiceRequestModel(
              number: isarInvoice.number,
              date: isarInvoice.date.toIso8601String(),
              dueDate: isarInvoice.dueDate?.toIso8601String(),
              paymentMethod: isarInvoice.paymentMethod,
              status: isarInvoice.status,
              taxPercentage: isarInvoice.taxPercentage,
              discountPercentage: isarInvoice.discountPercentage,
              discountAmount: isarInvoice.discountAmount,
              notes: isarInvoice.notes,
              terms: isarInvoice.terms,
              customerId: isarInvoice.customerId,
              items: itemsParams.map((item) => CreateInvoiceItemRequestModel.fromEntity(item)).toList(),
            );

            final updated = await remoteDataSource.updateInvoice(
              isarInvoice.serverId,
              request,
            );

            isarInvoice.markAsSynced();

            await isar.writeTxn(() async {
              await isar.isarInvoices.put(isarInvoice);
            });

            // También actualizar en SecureStorage
            await localDataSource.cacheInvoice(updated);

            syncedInvoices.add(updated);
            print('✅ Invoice updated and synced: ${isarInvoice.number}');
          }
        } catch (e) {
          print('❌ Error sincronizando factura ${isarInvoice.number}: $e');
          // Continuar con la siguiente
        }
      }

      print('🎯 InvoiceRepository: Sync completed. Success: ${syncedInvoices.length}');
      return Right(syncedInvoices);
    } catch (e) {
      print('💥 InvoiceRepository: Error during offline invoices sync: $e');
      return Left(ServerFailure('Error al sincronizar facturas offline: $e'));
    }
    */
  }
}
