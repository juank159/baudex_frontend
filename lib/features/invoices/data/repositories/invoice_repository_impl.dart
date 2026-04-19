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

          // ✅ Resetear estado de conectividad si el servidor respondió
          networkInfo.resetServerReachability();

          // FASE 3: Cachear TODAS las páginas a ISAR (upsert por serverId evita duplicados)
          try {
            await localDataSource.cacheInvoices(remoteResponse.data);
            print('💾 Facturas cacheadas exitosamente');
          } catch (e) {
            print('⚠️ Error al cachear facturas: $e');
            // No es crítico, continuar
          }

          return Right(remoteResponse.toPaginatedResult());
        } on ConnectionException catch (e) {
          print('❌ ConnectionException: $e');
          // ✅ Marcar servidor como no alcanzable para evitar timeouts repetidos
          networkInfo.markServerUnreachable();
          return _getInvoicesFromCache(queryParams);
        } on ServerException catch (e) {
          print('❌ ServerException: $e');
          if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
          return _getInvoicesFromCache(queryParams);
        } catch (e) {
          print('❌ Error al obtener facturas del servidor: $e');
          if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
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

          // ⭐ FASE 1: Resolución de conflictos con ConflictResolver
          Invoice finalInvoice = remoteInvoice;
          try {
            // Obtener versión local de ISAR para acceder a campos de versionamiento
            final localIsarInvoice = await localDataSource.getIsarInvoice(id);

            if (localIsarInvoice != null && !localIsarInvoice.isSynced) {
              // Hay una versión local no sincronizada, verificar conflictos
              print('🔍 Versión local no sincronizada encontrada, verificando conflictos...');

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
                print('⚠️ CONFLICTO DETECTADO Y RESUELTO: ${resolution.message}');
                print('   Estrategia usada: ${resolution.strategy.name}');

                // Usar los datos resueltos
                finalInvoice = resolution.resolvedData.toEntity();
              } else {
                print('✅ No hay conflicto, usando datos del servidor');
              }
            } else if (localIsarInvoice == null) {
              print('   📝 No hay versión local, usando datos del servidor');
            } else {
              print('   ✅ Versión local ya sincronizada, usando datos del servidor');
            }
          } catch (e) {
            print('⚠️ Error al verificar conflictos: $e');
            // Continuar con datos del servidor si falla la resolución de conflictos
          }

          // Cachear la factura final (resuelta)
          try {
            await localDataSource.cacheInvoice(InvoiceModel.fromEntity(finalInvoice));
            print('💾 Factura cacheada exitosamente');
          } catch (e) {
            print('⚠️ Error al cachear factura: $e');
          }

          return Right(finalInvoice);
        } catch (e) {
          print('❌ Error al obtener factura del servidor: $e');

          // Intento 1: SecureStorage cache
          try {
            final cachedInvoice = await localDataSource.getCachedInvoice(id);
            if (cachedInvoice != null) {
              print('💾 Factura obtenida desde cache');
              return Right(cachedInvoice);
            }
          } catch (cacheError) {
            print('❌ SecureStorage falló para getInvoiceById: $cacheError');
          }

          // Intento 2: ISAR offline repository
          print('🔄 Intentando con ISAR offline repository...');
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

          return Left(_mapExceptionToFailure(e));
        }
      } else {
        print('📱 Sin conexión, obteniendo desde cache...');

        // Intento 1: SecureStorage cache
        try {
          final cachedInvoice = await localDataSource.getCachedInvoice(id);
          if (cachedInvoice != null) {
            return Right(cachedInvoice);
          }
        } catch (cacheError) {
          print('❌ SecureStorage falló en modo offline: $cacheError');
        }

        // Intento 2: ISAR offline repository (siempre intentar si SecureStorage no encontró)
        print('🔄 Intentando con ISAR offline repository...');
        try {
          final offlineRepo = offlineRepository ?? InvoiceOfflineRepositorySimple(localDataSource: localDataSource);
          final result = await offlineRepo.getInvoiceById(id);

          return result.fold(
            (failure) {
              print('❌ ISAR tampoco encontró la factura: ${failure.message}');
              return const Left(ConnectionFailure('Sin conexión a internet'));
            },
            (invoice) {
              print('✅ ISAR: Factura obtenida offline exitosamente');
              return Right(invoice);
            },
          );
        } catch (isarError) {
          print('❌ Error crítico en ISAR offline: $isarError');
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
          networkInfo.resetServerReachability();
          return Right(remoteInvoices);
        } catch (e) {
          print('❌ Error al obtener facturas vencidas del servidor: $e');

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
        print('💾 ${cachedInvoices.length} facturas vencidas desde SecureStorage');
        return Right(cachedInvoices);
      }
    } catch (e) {
      print('⚠️ SecureStorage vacío para facturas vencidas: $e');
    }

    // ✅ Fallback a ISAR
    try {
      final offlineRepo = offlineRepository ?? InvoiceOfflineRepositorySimple(localDataSource: localDataSource);
      final isarResult = await offlineRepo.getOverdueInvoices();
      return isarResult.fold(
        (failure) {
          print('⚠️ ISAR también falló para facturas vencidas');
          return const Right(<Invoice>[]);
        },
        (invoices) {
          print('💾 ISAR: ${invoices.length} facturas vencidas cargadas');
          return Right(invoices);
        },
      );
    } catch (e) {
      print('⚠️ Error en ISAR fallback para facturas vencidas: $e');
      return const Right(<Invoice>[]);
    }
  }

  @override
  Future<Either<Failure, InvoiceStats>> getInvoiceStats() async {
    try {
      print('📊 InvoiceRepository: Obteniendo estadísticas...');

      if (await networkInfo.isConnected) {
        try {
          final remoteStats = await remoteDataSource.getInvoiceStats();

          // ✅ Resetear estado de conectividad si el servidor respondió
          networkInfo.resetServerReachability();

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

          // ✅ Marcar servidor como no alcanzable en timeout
          if (_isTimeoutError(e)) {
            networkInfo.markServerUnreachable();
          }

          // Intentar desde cache → ISAR fallback
          return _getStatsFromCacheOrIsar();
        }
      } else {
        print('📱 Sin conexión, obteniendo estadísticas desde cache/ISAR...');
        return _getStatsFromCacheOrIsar();
      }
    } catch (e) {
      print('❌ Error inesperado en getInvoiceStats: $e');
      return Left(ServerFailure('Error inesperado al obtener estadísticas'));
    }
  }

  /// ✅ Obtener estadísticas: SecureStorage primero, luego calcular desde ISAR
  Future<Either<Failure, InvoiceStats>> _getStatsFromCacheOrIsar() async {
    // Intentar SecureStorage primero
    try {
      final cachedStats = await localDataSource.getCachedInvoiceStats();
      if (cachedStats != null) {
        print('💾 Estadísticas obtenidas desde SecureStorage cache');
        return Right(cachedStats);
      }
    } catch (e) {
      print('⚠️ SecureStorage vacío para estadísticas: $e');
    }

    // ✅ Fallback: Calcular estadísticas desde facturas en ISAR
    try {
      print('📊 Calculando estadísticas desde ISAR...');
      final offlineRepo = offlineRepository ?? InvoiceOfflineRepositorySimple(localDataSource: localDataSource);
      final invoicesResult = await offlineRepo.getInvoices(page: 1, limit: 1000);

      return invoicesResult.fold(
        (failure) {
          print('⚠️ No hay datos en ISAR para calcular estadísticas');
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

          print('📊 ISAR: Estadísticas calculadas - ${invoices.length} facturas, ventas: \$${totalSales.toStringAsFixed(0)}');
          return Right(stats);
        },
      );
    } catch (e) {
      print('⚠️ Error calculando estadísticas desde ISAR: $e');
      return Right(InvoiceStats.empty());
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
          networkInfo.resetServerReachability();
          return Right(remoteInvoices);
        } catch (e) {
          print('❌ Error al obtener facturas del cliente del servidor: $e');
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
      print('🔍 InvoiceRepository: Buscando facturas: $searchTerm');

      if (await networkInfo.isConnected) {
        try {
          final remoteInvoices = await remoteDataSource.searchInvoices(
            searchTerm,
          );
          networkInfo.resetServerReachability();
          return Right(remoteInvoices);
        } catch (e) {
          print('❌ Error al buscar facturas en el servidor: $e');
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
        print('💾 Nueva factura cacheada');
      } catch (e) {
        print('⚠️ Error al cachear nueva factura: $e');
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
    String? paymentCurrency,
    double? paymentCurrencyAmount,
    double? exchangeRate,
  }) async {
    if (!(await networkInfo.isConnected)) {
      if (offlineRepository != null) {
        print('📱 Sin conexión - procesando pago offline para factura $invoiceId');
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
      final request = AddPaymentRequestModel(
        amount: amount,
        paymentMethod: paymentMethod.value,
        bankAccountId: bankAccountId,
        paymentDate: paymentDate?.toIso8601String(),
        reference: reference,
        notes: notes,
        paymentCurrency: paymentCurrency,
        paymentCurrencyAmount: paymentCurrencyAmount,
        exchangeRate: exchangeRate,
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
        print('📱 Timeout/error de conexión - procesando pago offline para factura $invoiceId');
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
      print('💳 InvoiceRepository: Agregando ${payments.length} pagos a factura: $invoiceId');

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
  /// ✅ IMPORTANTE: Intenta ISAR primero (más rápido), luego SecureStorage
  Future<Either<Failure, PaginatedResult<Invoice>>> _getInvoicesFromCache(
    InvoiceQueryParams params,
  ) async {
    // ✅ PASO 1: Intentar ISAR primero (más persistente y rápido)
    try {
      print('💾 Intentando cargar facturas desde ISAR primero...');
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
        print('✅ ISAR: ${isarData.data.length} facturas cargadas');
        return Right(isarData);
      }
    } catch (e) {
      print('⚠️ ISAR falló: $e');
    }

    // ✅ PASO 2: Fallback a SecureStorage
    try {
      print('🔄 Intentando SecureStorage como fallback...');
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
      print('❌ SecureStorage también falló: $e');
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
      print('💳 Creando crédito para factura a crédito: $invoiceNumber (\$$amount)');

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
      print('✅ Crédito creado en servidor: ${createdCredit.id} por \$$amount');

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
        print('💾 Crédito cacheado en ISAR: ${createdCredit.id}');
      } catch (cacheError) {
        print('⚠️ Error cacheando crédito en ISAR: $cacheError');
      }
    } catch (e) {
      print('⚠️ Error creando crédito para factura a crédito: $e');
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
}
