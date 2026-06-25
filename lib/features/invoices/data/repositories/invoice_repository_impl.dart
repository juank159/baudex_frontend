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
import '../../../../app/core/services/conflict_resolver.dart';

import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_stats.dart';
import '../../domain/repositories/invoice_repository.dart';

import '../datasources/invoice_local_datasource.dart';
import '../datasources/invoice_remote_datasource.dart';
import '../models/invoice_model.dart';
import '../models/isar/isar_invoice.dart';
import 'invoice_offline_repository_simple.dart';
import '../../../inventory/data/models/isar/isar_inventory_batch.dart';
import '../../../products/data/models/isar/isar_product.dart';

import '../models/create_invoice_request_model.dart';
import '../models/update_invoice_request_model.dart';
import '../models/add_payment_request_model.dart';
import '../models/invoice_item_model.dart' show CreateInvoiceItemRequestModel;
import '../../../settings/presentation/controllers/user_preferences_controller.dart';

import '../../../customer_credits/data/models/customer_credit_model.dart'
    show CreateCustomerCreditDto;
import '../../../customer_credits/data/datasources/customer_credit_remote_datasource.dart';
import '../../../customer_credits/data/models/isar/isar_customer_credit.dart';
import '../../../customer_credits/domain/entities/customer_credit.dart' show CreditStatus;
import '../../../../app/core/network/dio_client.dart';

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
          final remoteResponse = await remoteDataSource.getInvoices(
            queryParams,
          );

          // ✅ Resetear estado de conectividad si el servidor respondió
          networkInfo.resetServerReachability();

          // FASE 3: Cachear TODAS las páginas a ISAR (upsert por serverId evita duplicados)
          try {
            await localDataSource.cacheInvoices(remoteResponse.data);
          } catch (e) {
            // No es crítico, continuar
          }

          return Right(remoteResponse.toPaginatedResult());
        } on ConnectionException catch (e) {
          // ✅ Marcar servidor como no alcanzable para evitar timeouts repetidos
          networkInfo.markServerUnreachable();
          return _getInvoicesFromCache(queryParams);
        } on ServerException catch (e) {
          if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
          return _getInvoicesFromCache(queryParams);
        } catch (e) {
          if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
          return _getInvoicesFromCache(queryParams);
        }
      } else {
        return _getInvoicesFromCache(queryParams);
      }
    } catch (e) {
      return Left(ServerFailure('Error inesperado al obtener facturas'));
    }
  }

  @override
  Future<Either<Failure, Invoice>> getInvoiceById(String id) async {
    try {

      if (await networkInfo.isConnected) {
        try {
          final remoteInvoice = await remoteDataSource.getInvoiceById(id);

          // ⭐ FASE 1: Resolución de conflictos con ConflictResolver
          Invoice finalInvoice = remoteInvoice;
          try {
            // Obtener versión local de ISAR para acceder a campos de versionamiento
            final localIsarInvoice = await localDataSource.getIsarInvoice(id);

            if (localIsarInvoice != null && !localIsarInvoice.isSynced) {
              // Hay una versión local no sincronizada, verificar conflictos

              // Crear versión ISAR del servidor para comparar
              final serverIsarInvoice = IsarInvoice.fromModel(InvoiceModel.fromEntity(remoteInvoice));

              // Usar ConflictResolver para detectar y resolver
              final resolver = Get.find<ConflictResolver>();
              final resolution = resolver.resolveConflict<IsarInvoice>(
                localData: localIsarInvoice,
                serverData: serverIsarInvoice,
                strategy: ConflictResolutionStrategy.newerWins, // Estrategia: el más reciente gana
                hasConflictWith: (local, server) => local.hasConflictWith(server),
                getVersion: (data) => data.version,
                getLastModifiedAt: (data) => data.lastModifiedAt,
              );

              if (resolution.hadConflict) {

                // Usar los datos resueltos
                finalInvoice = resolution.resolvedData.toEntity();
              } else {
              }
            } else if (localIsarInvoice == null) {
            } else {
            }
          } catch (e) {
            // Continuar con datos del servidor si falla la resolución de conflictos
          }

          // Cachear la factura final (resuelta)
          try {
            await localDataSource.cacheInvoice(InvoiceModel.fromEntity(finalInvoice));
          } catch (e) {
          }

          return Right(finalInvoice);
        } catch (e) {

          // Intento 1: SecureStorage cache
          try {
            final cachedInvoice = await localDataSource.getCachedInvoice(id);
            if (cachedInvoice != null) {
              return Right(cachedInvoice);
            }
          } catch (cacheError) {
          }

          // Intento 2: ISAR offline repository
          try {
            final offlineRepo = offlineRepository ?? InvoiceOfflineRepositorySimple(localDataSource: localDataSource);
            final result = await offlineRepo.getInvoiceById(id);

            return result.fold(
              (failure) => Left(_mapExceptionToFailure(e)),
              (invoice) {
                return Right(invoice);
              },
            );
          } catch (isarError) {
          }

          return Left(_mapExceptionToFailure(e));
        }
      } else {

        // Intento 1: SecureStorage cache
        try {
          final cachedInvoice = await localDataSource.getCachedInvoice(id);
          if (cachedInvoice != null) {
            return Right(cachedInvoice);
          }
        } catch (cacheError) {
        }

        // Intento 2: ISAR offline repository (siempre intentar si SecureStorage no encontró)
        try {
          final offlineRepo = offlineRepository ?? InvoiceOfflineRepositorySimple(localDataSource: localDataSource);
          final result = await offlineRepo.getInvoiceById(id);

          return result.fold(
            (failure) {
              return const Left(ConnectionFailure('Sin conexión a internet'));
            },
            (invoice) {
              return Right(invoice);
            },
          );
        } catch (isarError) {
        }

        return const Left(ConnectionFailure('Sin conexión a internet'));
      }
    } catch (e) {
      return Left(ServerFailure('Error inesperado al obtener factura'));
    }
  }

  @override
  Future<Either<Failure, Invoice>> getInvoiceByNumber(String number) async {
    try {

      if (await networkInfo.isConnected) {
        try {
          final remoteInvoice = await remoteDataSource.getInvoiceByNumber(
            number,
          );

          // Cachear la factura
          try {
            await localDataSource.cacheInvoice(remoteInvoice);
          } catch (e) {
          }

          return Right(remoteInvoice);
        } catch (e) {

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

      if (await networkInfo.isConnected) {
        try {
          final remoteInvoices = await remoteDataSource.getOverdueInvoices();
          networkInfo.resetServerReachability();
          return Right(remoteInvoices);
        } catch (e) {

          // ✅ Marcar servidor como no alcanzable en timeout
          if (_isTimeoutError(e)) {
            networkInfo.markServerUnreachable();
          }

          // Intentar desde cache → ISAR fallback
          return _getOverdueFromCacheOrIsar();
        }
      } else {
        return _getOverdueFromCacheOrIsar();
      }
    } catch (e) {
      return Left(
        ServerFailure('Error inesperado al obtener facturas vencidas'),
      );
    }
  }

  /// ✅ Obtener facturas vencidas: SecureStorage primero, luego ISAR
  Future<Either<Failure, List<Invoice>>> _getOverdueFromCacheOrIsar() async {
    // Intentar SecureStorage primero
    try {
      final cachedInvoices = await localDataSource.getCachedOverdueInvoices();
      if (cachedInvoices.isNotEmpty) {
        return Right(cachedInvoices);
      }
    } catch (e) {
    }

    // ✅ Fallback a ISAR
    try {
      final offlineRepo = offlineRepository ?? InvoiceOfflineRepositorySimple(localDataSource: localDataSource);
      final isarResult = await offlineRepo.getOverdueInvoices();
      return isarResult.fold(
        (failure) {
          return const Right(<Invoice>[]);
        },
        (invoices) {
          return Right(invoices);
        },
      );
    } catch (e) {
      return const Right(<Invoice>[]);
    }
  }

  @override
  Future<Either<Failure, InvoiceStats>> getInvoiceStats() async {
    try {

      if (await networkInfo.isConnected) {
        try {
          final remoteStats = await remoteDataSource.getInvoiceStats();

          // ✅ Resetear estado de conectividad si el servidor respondió
          networkInfo.resetServerReachability();

          // Cachear estadísticas
          try {
            await localDataSource.cacheInvoiceStats(remoteStats);
          } catch (e) {
          }

          return Right(remoteStats);
        } catch (e) {

          // ✅ Marcar servidor como no alcanzable en timeout
          if (_isTimeoutError(e)) {
            networkInfo.markServerUnreachable();
          }

          // Intentar desde cache → ISAR fallback
          return _getStatsFromCacheOrIsar();
        }
      } else {
        return _getStatsFromCacheOrIsar();
      }
    } catch (e) {
      return Left(ServerFailure('Error inesperado al obtener estadísticas'));
    }
  }

  /// ✅ Obtener estadísticas: SecureStorage primero, luego calcular desde ISAR
  Future<Either<Failure, InvoiceStats>> _getStatsFromCacheOrIsar() async {
    // Intentar SecureStorage primero
    try {
      final cachedStats = await localDataSource.getCachedInvoiceStats();
      if (cachedStats != null) {
        return Right(cachedStats);
      }
    } catch (e) {
    }

    // ✅ Fallback: Calcular estadísticas desde facturas en ISAR
    try {
      final offlineRepo = offlineRepository ?? InvoiceOfflineRepositorySimple(localDataSource: localDataSource);
      final invoicesResult = await offlineRepo.getInvoices(page: 1, limit: 1000);

      return invoicesResult.fold(
        (failure) {
          return Right(InvoiceStats.empty());
        },
        (paginatedResult) {
          final invoices = paginatedResult.data;
          if (invoices.isEmpty) {
            return Right(InvoiceStats.empty());
          }

          // Calcular estadísticas desde los datos locales
          final now = DateTime.now();
          int draft = 0, pending = 0, paid = 0, overdue = 0, cancelled = 0, partiallyPaid = 0;
          double totalSales = 0, pendingAmount = 0, overdueAmount = 0;

          for (final invoice in invoices) {
            totalSales += invoice.total;

            switch (invoice.status) {
              case InvoiceStatus.draft:
                draft++;
                break;
              case InvoiceStatus.pending:
                if (invoice.dueDate.isBefore(now)) {
                  overdue++;
                  overdueAmount += invoice.balanceDue;
                } else {
                  pending++;
                  pendingAmount += invoice.balanceDue;
                }
                break;
              case InvoiceStatus.paid:
                paid++;
                break;
              case InvoiceStatus.overdue:
                overdue++;
                overdueAmount += invoice.balanceDue;
                break;
              case InvoiceStatus.cancelled:
                cancelled++;
                break;
              case InvoiceStatus.partiallyPaid:
                if (invoice.dueDate.isBefore(now)) {
                  overdue++;
                  overdueAmount += invoice.balanceDue;
                } else {
                  partiallyPaid++;
                  pendingAmount += invoice.balanceDue;
                }
                break;
              default:
                break;
            }
          }

          final stats = InvoiceStats(
            total: invoices.length,
            draft: draft,
            pending: pending,
            paid: paid,
            overdue: overdue,
            cancelled: cancelled,
            partiallyPaid: partiallyPaid,
            totalSales: totalSales,
            pendingAmount: pendingAmount,
            overdueAmount: overdueAmount,
          );

          return Right(stats);
        },
      );
    } catch (e) {
      return Right(InvoiceStats.empty());
    }
  }

  @override
  Future<Either<Failure, List<Invoice>>> getInvoicesByCustomer(
    String customerId,
  ) async {
    try {

      if (await networkInfo.isConnected) {
        try {
          final remoteInvoices = await remoteDataSource.getInvoicesByCustomer(
            customerId,
          );
          networkInfo.resetServerReachability();
          return Right(remoteInvoices);
        } catch (e) {
          if (_isTimeoutError(e)) networkInfo.markServerUnreachable();

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

      if (await networkInfo.isConnected) {
        try {
          final remoteInvoices = await remoteDataSource.searchInvoices(
            searchTerm,
          );
          networkInfo.resetServerReachability();
          return Right(remoteInvoices);
        } catch (e) {
          if (_isTimeoutError(e)) networkInfo.markServerUnreachable();

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
      if (bankAccountId != null) {
      }

      // Determinar si se debe saltar la validación de stock
      bool skipStock = false;
      try {
        final prefsCtrl = Get.find<UserPreferencesController>();
        skipStock = !prefsCtrl.validateStockBeforeInvoice || prefsCtrl.allowOverselling;
      } catch (_) {}

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
        skipStockValidation: skipStock,
      );

      final createdInvoice = await remoteDataSource.createInvoice(request);

      // Cachear la nueva factura
      try {
        await localDataSource.cacheInvoice(createdInvoice);
      } catch (e) {
      }

      // ✅ DESCUENTO LOCAL INMEDIATO (espejo del flujo offline).
      // El backend ya descontó stock y FIFO en su transacción. Sin esto,
      // ISAR seguiría con el stock viejo hasta que el FullSync periódico
      // (cada ~60s) lo refresque. Aplicamos el mismo descuento localmente
      // para que la siguiente venta vea cantidades correctas al instante.
      // NOTA: NO marcamos productos como unsynced — backend ya tiene la
      // verdad. NO encolamos movement — backend ya lo registró.
      // Si esto falla, NO afecta la factura ya creada.
      try {
        await _applyLocalInventoryDeductionAfterOnlineSale(
          items: createdInvoice.items,
        );
      } catch (e) {
      }

      // ✅ Para facturas a crédito puro, crear el CustomerCredit en el servidor
      if (paymentMethod == PaymentMethod.credit &&
          (status == InvoiceStatus.pending || status == null) &&
          createdInvoice.total > 0) {
        await _createCreditForPureCreditInvoice(
          invoiceId: createdInvoice.id,
          invoiceNumber: createdInvoice.number ?? '',
          customerId: customerId,
          amount: createdInvoice.total,
          dueDate: dueDate ?? DateTime.now().add(const Duration(days: 30)),
        );
      }

      return Right(createdInvoice);
    } on ServerException catch (e) {
      // ⚠️ FALLBACK OFFLINE SELECTIVO.
      //
      // Históricamente cualquier `ServerException` caía a offline, lo
      // que escondía bugs reales del usuario: si el backend rechazaba
      // por límite de crédito, cliente inválido, stock, etc. (4xx), la
      // factura quedaba huérfana en ISAR con `error permanente` y nunca
      // se sincronizaba — el usuario veía "Factura creada" pero el
      // servidor jamás la conocía.
      //
      // Ahora solo caemos a offline si el error parece de RED:
      // - statusCode null (sin respuesta — timeout / red caída)
      // - statusCode 5xx (error del servidor reintentable)
      // - statusCode 408 (request timeout) o 429 (rate limit)
      //
      // Para 4xx de validación (400, 401, 403, 404, 409, 422, etc.)
      // propagamos el mensaje real al UI para que el cajero corrija.
      final shouldFallbackOffline = e.statusCode == null ||
          e.statusCode! >= 500 ||
          e.statusCode == 408 ||
          e.statusCode == 429;
      if (shouldFallbackOffline && offlineRepository != null) {
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
      // Cualquier excepción NO-ServerException la tratamos como red caída
      // (DioException de timeout/conexión, errores de parse, etc.).
      if (offlineRepository != null) {
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
      } catch (e) {
      }

      return Right(updatedInvoice);
    } on ServerException catch (e) {
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
    } catch (e) {
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
    String? paymentCurrency,
    double? paymentCurrencyAmount,
    double? exchangeRate,
  }) async {
    if (!(await networkInfo.isConnected)) {
      if (offlineRepository != null) {
        networkInfo.markServerUnreachable();
        return offlineRepository!.addPayment(
          invoiceId: invoiceId,
          amount: amount,
          paymentMethod: paymentMethod,
          bankAccountId: bankAccountId,
          paymentDate: paymentDate,
          reference: reference,
          notes: notes,
          paymentCurrency: paymentCurrency,
          paymentCurrencyAmount: paymentCurrencyAmount,
          exchangeRate: exchangeRate,
        );
      }
      return const Left(
        ConnectionFailure('Se requiere conexión a internet para agregar pagos'),
      );
    }

    try {
      // idempotencyKey protege contra double-clicks/double-submits en el path online.
      final onlineIdempotencyKey = 'payment_online_${DateTime.now().millisecondsSinceEpoch}_${invoiceId.hashCode}';
      final request = AddPaymentRequestModel(
        amount: amount,
        paymentMethod: paymentMethod.value,
        bankAccountId: bankAccountId,
        paymentDate: (paymentDate ?? DateTime.now()).toIso8601String(),
        reference: reference,
        notes: notes,
        paymentCurrency: paymentCurrency,
        paymentCurrencyAmount: paymentCurrencyAmount,
        exchangeRate: exchangeRate,
        idempotencyKey: onlineIdempotencyKey,
      );

      final updatedInvoice = await remoteDataSource.addPayment(
        invoiceId,
        request,
      );

      // Actualizar cache
      try {
        await localDataSource.cacheInvoice(updatedInvoice);
      } catch (e) {
      }

      // Cross-update crédito asociado en ISAR (el backend ya lo hizo en DB)
      try {
        await offlineRepository?.crossUpdateCreditFromInvoicePayment(
          invoiceId: invoiceId,
          paymentAmount: amount,
        );
      } catch (_) {}

      return Right(updatedInvoice);
    } catch (e) {
      // ✅ Fallback offline en caso de error de conexión/timeout
      if (_isTimeoutError(e) && offlineRepository != null) {
        networkInfo.markServerUnreachable();
        return offlineRepository!.addPayment(
          invoiceId: invoiceId,
          amount: amount,
          paymentMethod: paymentMethod,
          bankAccountId: bankAccountId,
          paymentDate: paymentDate,
          reference: reference,
          notes: notes,
        );
      }
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

      // Convertir PaymentItemData a PaymentItemModel
      final paymentModels = payments.map((p) => PaymentItemModel(
        amount: p.amount,
        paymentMethod: p.paymentMethod.value,
        bankAccountId: p.bankAccountId,
        reference: p.reference,
        notes: p.notes,
        paymentCurrency: p.paymentCurrency,
        paymentCurrencyAmount: p.paymentCurrencyAmount,
        exchangeRate: p.exchangeRate,
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
      } catch (e) {
      }

      return Right(MultiplePaymentsResult(
        invoice: result.invoice,
        paymentsCreated: result.paymentCount,
        remainingBalance: result.remainingBalance,
        creditCreated: result.creditCreated,
      ));
    } catch (e) {
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
          }
        } catch (e) {
        }

        // Remover del cache
        try {
          await localDataSource.removeCachedInvoice(id);
        } catch (e) {
        }

        return const Right(null);
      } on ServerException catch (e) {
        return _deleteInvoiceOffline(id);
      } catch (e) {
        return _deleteInvoiceOffline(id);
      }
    } else {
      // Sin conexión, marcar para eliminación offline y sincronizar después
      return _deleteInvoiceOffline(id);
    }
  }

  Future<Either<Failure, void>> _deleteInvoiceOffline(String id) async {
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
        }

        // Remover del cache (no crítico)
        try {
          await localDataSource.removeCachedInvoice(id);
        } catch (e) {
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
        } catch (e) {
        }

        return const Right(null);
      } catch (e) {
        return Left(CacheFailure('Error al eliminar factura offline: $e'));
      }
  }

  // ==================== HELPER METHODS ====================

  /// Obtener facturas desde cache con filtrado básico
  /// ✅ IMPORTANTE: Intenta ISAR primero (más rápido), luego SecureStorage
  Future<Either<Failure, PaginatedResult<Invoice>>> _getInvoicesFromCache(
    InvoiceQueryParams params,
  ) async {
    // ✅ PASO 1: Intentar ISAR primero (más persistente y rápido)
    try {
      final offlineRepo = offlineRepository ?? InvoiceOfflineRepositorySimple(localDataSource: localDataSource);
      final isarResult = await offlineRepo.getInvoices(
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

      final isarData = isarResult.fold(
        (failure) => null,
        (result) => result.data.isNotEmpty ? result : null,
      );

      if (isarData != null) {
        return Right(isarData);
      }
    } catch (e) {
    }

    // ✅ PASO 2: Fallback a SecureStorage
    try {
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

      return Right(
        PaginatedResult<Invoice>(data: paginatedInvoices, meta: meta),
      );
    } catch (e) {
      // Si ambos fallaron, retornar error con datos vacíos
      return Left(CacheFailure('No hay facturas disponibles offline'));
    }
  }

  /// ✅ Verificar si un error es de timeout/conexión para marcar servidor como no alcanzable
  bool _isTimeoutError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('timeout') ||
        msg.contains('tiempo') ||
        msg.contains('socketexception') ||
        msg.contains('conexión') ||
        msg.contains('connection') ||
        error is ConnectionException;
  }

  /// Mapear excepciones a failures
  /// Crear CustomerCredit en el servidor para facturas a crédito puro
  Future<void> _createCreditForPureCreditInvoice({
    required String invoiceId,
    required String invoiceNumber,
    required String customerId,
    required double amount,
    required DateTime dueDate,
  }) async {
    try {

      CustomerCreditRemoteDataSource creditRemoteDs;
      if (Get.isRegistered<CustomerCreditRemoteDataSource>()) {
        creditRemoteDs = Get.find<CustomerCreditRemoteDataSource>();
      } else {
        creditRemoteDs = CustomerCreditRemoteDataSourceImpl(
          dioClient: Get.find<DioClient>(),
        );
      }

      final dto = CreateCustomerCreditDto(
        customerId: customerId,
        originalAmount: amount,
        dueDate: dueDate.toIso8601String().split('T').first,
        description: 'Crédito por venta a crédito - Factura $invoiceNumber',
        invoiceId: invoiceId,
      );

      final createdCredit = await creditRemoteDs.createCredit(dto);

      // ✅ Cachear el crédito en ISAR para que aparezca inmediatamente en la pantalla de créditos
      try {
        final isar = IsarDatabase.instance.database;
        final isarCredit = IsarCustomerCredit(
          serverId: createdCredit.id,
          originalAmount: createdCredit.originalAmount,
          paidAmount: createdCredit.paidAmount,
          balanceDue: createdCredit.balanceDue,
          status: _mapCreditStatusToIsar(createdCredit.status),
          dueDate: createdCredit.dueDate,
          description: createdCredit.description,
          notes: createdCredit.notes,
          customerId: createdCredit.customerId,
          customerName: createdCredit.customerName,
          invoiceId: createdCredit.invoiceId,
          invoiceNumber: createdCredit.invoiceNumber,
          organizationId: createdCredit.organizationId,
          createdById: createdCredit.createdById,
          createdByName: createdCredit.createdByName,
          createdAt: createdCredit.createdAt,
          updatedAt: createdCredit.updatedAt,
          isSynced: true,
          lastSyncAt: DateTime.now(),
        );
        await isar.writeTxn(() async {
          await isar.isarCustomerCredits.putByServerId(isarCredit);
        });
      } catch (cacheError) {
      }
    } catch (e) {
      // No fallar la creación de factura por error en crédito
    }
  }

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

      final pdfBytes = await remoteDataSource.downloadInvoicePdf(id);

      return Right(pdfBytes);
    } catch (exception) {
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
    return const Right([]);

    /* TODO: Implementar sync completo de invoices con items
    try {

      // Obtener facturas no sincronizadas desde ISAR
      final isar = IsarDatabase.instance.database;
      final unsyncedInvoices = await isar.isarInvoices
          .filter()
          .isSyncedEqualTo(false)
          .and()
          .deletedAtIsNull()
          .findAll();

      if (unsyncedInvoices.isEmpty) {
        return const Right([]);
      }

      final syncedInvoices = <Invoice>[];

      for (final isarInvoice in unsyncedInvoices) {
        try {
          // Determinar si es CREATE o UPDATE basándose en el serverId
          final isCreate = isarInvoice.serverId.startsWith('invoice_offline_');

          if (isCreate) {
            // CREATE: Enviar al servidor y actualizar con ID real

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
                presentationId: item.presentationId,
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
          } else {
            // UPDATE: Enviar actualización al servidor

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
                presentationId: item.presentationId,
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
          }
        } catch (e) {
          // Continuar con la siguiente
        }
      }

      return Right(syncedInvoices);
    } catch (e) {
      return Left(ServerFailure('Error al sincronizar facturas offline: $e'));
    }
    */
  }

  /// Mapear CreditStatus (entity) a IsarCreditStatus
  IsarCreditStatus _mapCreditStatusToIsar(CreditStatus status) {
    switch (status) {
      case CreditStatus.pending:
        return IsarCreditStatus.pending;
      case CreditStatus.partiallyPaid:
        return IsarCreditStatus.partiallyPaid;
      case CreditStatus.paid:
        return IsarCreditStatus.paid;
      case CreditStatus.cancelled:
        return IsarCreditStatus.cancelled;
      case CreditStatus.overdue:
        return IsarCreditStatus.overdue;
    }
  }

  // ==================== INVENTARIO LOCAL POST-VENTA ONLINE ====================

  /// Descuenta stock e inventario FIFO localmente DESPUÉS de un POST online
  /// exitoso. El backend ya hizo el descuento en su transacción; este método
  /// solo refleja el cambio en ISAR para que la UI no espere al próximo
  /// FullSync (~60s) para mostrar stocks correctos.
  ///
  /// Diferencias clave con el descuento offline:
  ///   * NO marca productos como `isSynced=false` — backend tiene la verdad.
  ///   * NO encola operaciones de inventory_movement — backend ya las registró.
  ///   * Si algo falla, simplemente loguea y continúa (la factura YA existe
  ///     en backend; el FullSync próximo corregirá cualquier discrepancia).
  Future<void> _applyLocalInventoryDeductionAfterOnlineSale({
    required List<dynamic> items,
  }) async {
    final isar = IsarDatabase.instance.database;
    final stockDeductions = <String, double>{}; // productId → qty acumulada

    for (final item in items) {
      // dynamic accept Invoice items o item maps con productId/quantity
      final productId = item.productId as String?;
      if (productId == null || productId.isEmpty) continue;
      // Si el item tiene presentationFactor, multiplicamos para obtener
      // la cantidad base real que debe descontarse del inventario.
      final rawQty = (item.quantity as num).toDouble();
      final factor = item.presentationFactor != null
          ? (item.presentationFactor as num).toDouble()
          : 1.0;
      final qty = rawQty * factor;
      if (qty <= 0) continue;

      // 1) Consumir batches FIFO (más antiguos primero, igual que backend)
      final batches = await isar.isarInventoryBatchs
          .filter()
          .deletedAtIsNull()
          .and()
          .productIdEqualTo(productId)
          .findAll();
      batches.sort((a, b) => a.entryDate.compareTo(b.entryDate));

      int remaining = qty.toInt();
      final updatedBatches = <IsarInventoryBatch>[];
      for (final batch in batches) {
        if (remaining <= 0) break;
        final canTake = batch.currentQuantity;
        if (canTake <= 0) continue;
        final consumed = remaining > canTake ? canTake : remaining;
        batch.consume(consumed, modifiedBy: 'online_sale');
        updatedBatches.add(batch);
        remaining -= consumed;
      }
      if (updatedBatches.isNotEmpty) {
        await isar.writeTxn(() async {
          await isar.isarInventoryBatchs.putAll(updatedBatches);
        });
      }

      stockDeductions[productId] = (stockDeductions[productId] ?? 0) + qty;
    }

    // 2) Decrementar IsarProduct.stock en una sola transacción
    if (stockDeductions.isNotEmpty) {
      final productsToUpdate = <IsarProduct>[];
      for (final entry in stockDeductions.entries) {
        final p = await isar.isarProducts
            .filter()
            .serverIdEqualTo(entry.key)
            .findFirst();
        if (p == null) continue;
        p.stock = (p.stock - entry.value).clamp(0.0, double.infinity).toDouble();
        // Importante: NO p.markAsUnsynced(). El backend ya tiene el dato
        // correcto. Si markamos unsynced, el siguiente FullSync skipearía
        // este producto (por el patrón del commit 7b57055) y nunca llegaría
        // un refresh fresco — quedaría protegido para siempre.
        productsToUpdate.add(p);
      }
      if (productsToUpdate.isNotEmpty) {
        await isar.writeTxn(() async {
          await isar.isarProducts.putAll(productsToUpdate);
        });
      }
    }
  }
}
