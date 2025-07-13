// lib/features/invoices/data/repositories/invoice_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/models/pagination_meta.dart';

import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_stats.dart';
import '../../domain/repositories/invoice_repository.dart';

import '../datasources/invoice_local_datasource.dart';
import '../datasources/invoice_remote_datasource.dart';
import '../models/invoice_model.dart';

import '../models/create_invoice_request_model.dart';
import '../models/update_invoice_request_model.dart';
import '../models/add_payment_request_model.dart';
import '../models/invoice_item_model.dart' show CreateInvoiceItemRequestModel;

class InvoiceRepositoryImpl implements InvoiceRepository {
  final InvoiceRemoteDataSource remoteDataSource;
  final InvoiceLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  const InvoiceRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
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
          final cachedInvoice = await localDataSource.getCachedInvoice(id);
          if (cachedInvoice != null) {
            print('💾 Factura obtenida desde cache');
            return Right(cachedInvoice);
          }

          return Left(_mapExceptionToFailure(e));
        }
      } else {
        print('📱 Sin conexión, obteniendo desde cache...');
        final cachedInvoice = await localDataSource.getCachedInvoice(id);
        if (cachedInvoice != null) {
          return Right(cachedInvoice);
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
  }) async {
    if (!(await networkInfo.isConnected)) {
      return const Left(
        ConnectionFailure(
          'Se requiere conexión a internet para crear facturas',
        ),
      );
    }

    try {
      print('📄 InvoiceRepository: Creando factura...');

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
    } catch (e) {
      print('❌ Error al crear factura: $e');
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
      return const Left(
        ConnectionFailure(
          'Se requiere conexión a internet para actualizar facturas',
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
    } catch (e) {
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
  Future<Either<Failure, void>> deleteInvoice(String id) async {
    if (!(await networkInfo.isConnected)) {
      return const Left(
        ConnectionFailure(
          'Se requiere conexión a internet para eliminar facturas',
        ),
      );
    }

    try {
      await remoteDataSource.deleteInvoice(id);

      // Remover del cache
      try {
        await localDataSource.removeCachedInvoice(id);
      } catch (e) {
        print('⚠️ Error al remover factura del cache: $e');
      }

      return const Right(null);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  // ==================== HELPER METHODS ====================

  /// Obtener facturas desde cache con filtrado básico
  Future<Either<Failure, PaginatedResult<Invoice>>> _getInvoicesFromCache(
    InvoiceQueryParams params,
  ) async {
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
      print('❌ Error al obtener facturas desde cache: $e');
      return const Left(CacheFailure('Error al obtener facturas desde cache'));
    }
  }

  /// Mapear excepciones a failures
  Failure _mapExceptionToFailure(Object exception) {
    if (exception is ServerException) {
      return ServerFailure(exception.message);
    } else if (exception is ConnectionException) {
      return ConnectionFailure(exception.message);
    } else if (exception is CacheException) {
      return CacheFailure(exception.message);
    } else {
      return ServerFailure('Error inesperado: ${exception.toString()}');
    }
  }
}
