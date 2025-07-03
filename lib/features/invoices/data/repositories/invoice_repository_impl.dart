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

// // lib/features/invoices/data/repositories/invoice_repository_impl.dart
// import 'package:dartz/dartz.dart';
// import '../../../../app/core/errors/failures.dart';
// import '../../../../app/core/errors/exceptions.dart';
// import '../../../../app/core/network/network_info.dart';
// import '../../../../app/core/models/pagination_meta.dart';

// import '../../domain/entities/invoice.dart';
// import '../../domain/entities/invoice_stats.dart';
// import '../../domain/repositories/invoice_repository.dart';

// import '../datasources/invoice_local_datasource.dart';
// import '../datasources/invoice_remote_datasource.dart';
// import '../models/invoice_model.dart';
// import '../models/invoice_stats_model.dart';

// import '../models/create_invoice_request_model.dart';
// import '../models/update_invoice_request_model.dart';
// import '../models/add_payment_request_model.dart';
// import '../models/invoice_item_model.dart' show CreateInvoiceItemRequestModel;

// class InvoiceRepositoryImpl implements InvoiceRepository {
//   final InvoiceRemoteDataSource remoteDataSource;
//   final InvoiceLocalDataSource localDataSource;
//   final NetworkInfo networkInfo;

//   const InvoiceRepositoryImpl({
//     required this.remoteDataSource,
//     required this.localDataSource,
//     required this.networkInfo,
//   });

//   // ==================== READ OPERATIONS ====================

//   @override
//   Future<Either<Failure, PaginatedResult<Invoice>>> getInvoices({
//     int page = 1,
//     int limit = 10,
//     String? search,
//     InvoiceStatus? status,
//     PaymentMethod? paymentMethod,
//     String? customerId,
//     String? createdById,
//     DateTime? startDate,
//     DateTime? endDate,
//     double? minAmount,
//     double? maxAmount,
//     String sortBy = 'createdAt',
//     String sortOrder = 'DESC',
//   }) async {
//     try {
//       print('📄 InvoiceRepository: Obteniendo facturas...');

//       // Crear parámetros de query
//       final queryParams = InvoiceQueryParams(
//         page: page,
//         limit: limit,
//         search: search,
//         status: status,
//         paymentMethod: paymentMethod,
//         customerId: customerId,
//         createdById: createdById,
//         startDate: startDate,
//         endDate: endDate,
//         minAmount: minAmount,
//         maxAmount: maxAmount,
//         sortBy: sortBy,
//         sortOrder: sortOrder,
//       );

//       if (await networkInfo.isConnected) {
//         // Intentar obtener desde el servidor
//         try {
//           print('🌐 Obteniendo facturas del servidor...');
//           final remoteResponse = await remoteDataSource.getInvoices(
//             queryParams,
//           );

//           // Cachear los resultados si es la primera página y no hay filtros específicos
//           if (page == 1 &&
//               search == null &&
//               status == null &&
//               customerId == null) {
//             try {
//               await localDataSource.cacheInvoices(remoteResponse.data);
//               print('💾 Facturas cacheadas exitosamente');
//             } catch (e) {
//               print('⚠️ Error al cachear facturas: $e');
//               // No es crítico, continuar
//             }
//           }

//           return Right(remoteResponse.toPaginatedResult());
//         } catch (e) {
//           print('❌ Error al obtener facturas del servidor: $e');
//           // Si falla el servidor, usar datos mock
//           return _getInvoicesFromMockOrCache(queryParams);
//         }
//       } else {
//         print('📱 Sin conexión, usando datos mock/cache...');
//         return _getInvoicesFromMockOrCache(queryParams);
//       }
//     } catch (e) {
//       print('❌ Error inesperado en getInvoices: $e');
//       return Left(ServerFailure('Error inesperado al obtener facturas'));
//     }
//   }

//   @override
//   Future<Either<Failure, Invoice>> getInvoiceById(String id) async {
//     try {
//       print('📄 InvoiceRepository: Obteniendo factura por ID: $id');

//       if (await networkInfo.isConnected) {
//         try {
//           print('🌐 Obteniendo factura del servidor...');
//           final remoteInvoice = await remoteDataSource.getInvoiceById(id);

//           // Cachear la factura individual
//           try {
//             await localDataSource.cacheInvoice(remoteInvoice);
//             print('💾 Factura cacheada exitosamente');
//           } catch (e) {
//             print('⚠️ Error al cachear factura: $e');
//           }

//           return Right(remoteInvoice);
//         } catch (e) {
//           print('❌ Error al obtener factura del servidor: $e');

//           // Intentar desde cache
//           final cachedInvoice = await localDataSource.getCachedInvoice(id);
//           if (cachedInvoice != null) {
//             print('💾 Factura obtenida desde cache');
//             return Right(cachedInvoice);
//           }

//           // Si no hay en cache, usar mock
//           final mockInvoice = _getMockInvoiceById(id);
//           if (mockInvoice != null) {
//             return Right(mockInvoice);
//           }

//           return Left(_mapExceptionToFailure(e));
//         }
//       } else {
//         print('📱 Sin conexión, obteniendo desde cache/mock...');
//         final cachedInvoice = await localDataSource.getCachedInvoice(id);
//         if (cachedInvoice != null) {
//           return Right(cachedInvoice);
//         }

//         // Usar mock si no hay cache
//         final mockInvoice = _getMockInvoiceById(id);
//         if (mockInvoice != null) {
//           return Right(mockInvoice);
//         }

//         return const Left(ConnectionFailure('Sin conexión a internet'));
//       }
//     } catch (e) {
//       print('❌ Error inesperado en getInvoiceById: $e');
//       return Left(ServerFailure('Error inesperado al obtener factura'));
//     }
//   }

//   @override
//   Future<Either<Failure, Invoice>> getInvoiceByNumber(String number) async {
//     try {
//       print('📄 InvoiceRepository: Obteniendo factura por número: $number');

//       if (await networkInfo.isConnected) {
//         try {
//           final remoteInvoice = await remoteDataSource.getInvoiceByNumber(
//             number,
//           );

//           // Cachear la factura
//           try {
//             await localDataSource.cacheInvoice(remoteInvoice);
//           } catch (e) {
//             print('⚠️ Error al cachear factura: $e');
//           }

//           return Right(remoteInvoice);
//         } catch (e) {
//           print('❌ Error al obtener factura del servidor: $e');

//           // Intentar desde cache
//           final cachedInvoice = await localDataSource.getCachedInvoiceByNumber(
//             number,
//           );
//           if (cachedInvoice != null) {
//             return Right(cachedInvoice);
//           }

//           // Usar mock
//           final mockInvoice = _getMockInvoiceByNumber(number);
//           if (mockInvoice != null) {
//             return Right(mockInvoice);
//           }

//           return Left(_mapExceptionToFailure(e));
//         }
//       } else {
//         final cachedInvoice = await localDataSource.getCachedInvoiceByNumber(
//           number,
//         );
//         if (cachedInvoice != null) {
//           return Right(cachedInvoice);
//         }

//         // Usar mock
//         final mockInvoice = _getMockInvoiceByNumber(number);
//         if (mockInvoice != null) {
//           return Right(mockInvoice);
//         }

//         return const Left(ConnectionFailure('Sin conexión a internet'));
//       }
//     } catch (e) {
//       return Left(
//         ServerFailure('Error inesperado al obtener factura por número'),
//       );
//     }
//   }

//   @override
//   Future<Either<Failure, List<Invoice>>> getOverdueInvoices() async {
//     try {
//       print('📄 InvoiceRepository: Obteniendo facturas vencidas...');

//       if (await networkInfo.isConnected) {
//         try {
//           final remoteInvoices = await remoteDataSource.getOverdueInvoices();
//           return Right(remoteInvoices);
//         } catch (e) {
//           print('❌ Error al obtener facturas vencidas del servidor: $e');

//           // Intentar desde cache
//           try {
//             final cachedInvoices =
//                 await localDataSource.getCachedOverdueInvoices();
//             if (cachedInvoices.isNotEmpty) {
//               return Right(cachedInvoices);
//             }
//           } catch (cacheError) {
//             print(
//               '⚠️ Error al obtener facturas vencidas del cache: $cacheError',
//             );
//           }

//           // Usar mock
//           return Right(_getMockOverdueInvoices());
//         }
//       } else {
//         try {
//           final cachedInvoices =
//               await localDataSource.getCachedOverdueInvoices();
//           if (cachedInvoices.isNotEmpty) {
//             return Right(cachedInvoices);
//           }
//         } catch (e) {
//           print('⚠️ Error al obtener facturas vencidas del cache: $e');
//         }

//         // Usar mock como fallback
//         return Right(_getMockOverdueInvoices());
//       }
//     } catch (e) {
//       return Left(
//         ServerFailure('Error inesperado al obtener facturas vencidas'),
//       );
//     }
//   }

//   @override
//   Future<Either<Failure, InvoiceStats>> getInvoiceStats() async {
//     try {
//       print('📊 InvoiceRepository: Obteniendo estadísticas...');

//       if (await networkInfo.isConnected) {
//         try {
//           final remoteStats = await remoteDataSource.getInvoiceStats();

//           // Cachear estadísticas
//           try {
//             await localDataSource.cacheInvoiceStats(remoteStats);
//             print('💾 Estadísticas cacheadas exitosamente');
//           } catch (e) {
//             print('⚠️ Error al cachear estadísticas: $e');
//           }

//           return Right(remoteStats);
//         } catch (e) {
//           print('❌ Error al obtener estadísticas del servidor: $e');

//           // Intentar desde cache
//           try {
//             final cachedStats = await localDataSource.getCachedInvoiceStats();
//             if (cachedStats != null) {
//               print('💾 Estadísticas obtenidas desde cache');
//               return Right(cachedStats);
//             }
//           } catch (cacheError) {
//             print('⚠️ Error al obtener estadísticas del cache: $cacheError');
//           }

//           // ✅ USAR MOCK COMO FALLBACK
//           print('🎭 Usando estadísticas mock como fallback');
//           return Right(_getMockInvoiceStats());
//         }
//       } else {
//         print('📱 Sin conexión, obteniendo desde cache/mock...');
//         try {
//           final cachedStats = await localDataSource.getCachedInvoiceStats();
//           if (cachedStats != null) {
//             return Right(cachedStats);
//           }
//         } catch (e) {
//           print('⚠️ Error al obtener estadísticas del cache: $e');
//         }

//         // ✅ USAR MOCK COMO FALLBACK
//         print('🎭 Usando estadísticas mock');
//         return Right(_getMockInvoiceStats());
//       }
//     } catch (e) {
//       print('❌ Error inesperado en getInvoiceStats: $e');
//       // ✅ INCLUSO EN ERROR INESPERADO, RETORNAR MOCK
//       return Right(_getMockInvoiceStats());
//     }
//   }

//   @override
//   Future<Either<Failure, List<Invoice>>> getInvoicesByCustomer(
//     String customerId,
//   ) async {
//     try {
//       print(
//         '👤 InvoiceRepository: Obteniendo facturas del cliente: $customerId',
//       );

//       if (await networkInfo.isConnected) {
//         try {
//           final remoteInvoices = await remoteDataSource.getInvoicesByCustomer(
//             customerId,
//           );
//           return Right(remoteInvoices);
//         } catch (e) {
//           print('❌ Error al obtener facturas del cliente del servidor: $e');

//           // Intentar desde cache
//           final cachedInvoices = await localDataSource
//               .getCachedInvoicesByCustomer(customerId);
//           if (cachedInvoices.isNotEmpty) {
//             return Right(cachedInvoices);
//           }

//           // Usar mock filtrado
//           final mockInvoices = _getMockInvoicesByCustomer(customerId);
//           return Right(mockInvoices);
//         }
//       } else {
//         final cachedInvoices = await localDataSource
//             .getCachedInvoicesByCustomer(customerId);
//         if (cachedInvoices.isNotEmpty) {
//           return Right(cachedInvoices);
//         }

//         // Usar mock filtrado
//         final mockInvoices = _getMockInvoicesByCustomer(customerId);
//         return Right(mockInvoices);
//       }
//     } catch (e) {
//       return Left(
//         ServerFailure('Error inesperado al obtener facturas del cliente'),
//       );
//     }
//   }

//   @override
//   Future<Either<Failure, List<Invoice>>> searchInvoices(
//     String searchTerm,
//   ) async {
//     try {
//       print('🔍 InvoiceRepository: Buscando facturas: $searchTerm');

//       if (await networkInfo.isConnected) {
//         try {
//           final remoteInvoices = await remoteDataSource.searchInvoices(
//             searchTerm,
//           );
//           return Right(remoteInvoices);
//         } catch (e) {
//           print('❌ Error al buscar facturas en el servidor: $e');

//           // Intentar desde cache
//           final cachedInvoices = await localDataSource.searchCachedInvoices(
//             searchTerm,
//           );
//           return Right(cachedInvoices);
//         }
//       } else {
//         final cachedInvoices = await localDataSource.searchCachedInvoices(
//           searchTerm,
//         );
//         return Right(cachedInvoices);
//       }
//     } catch (e) {
//       return Left(ServerFailure('Error inesperado al buscar facturas'));
//     }
//   }

//   // ==================== WRITE OPERATIONS ====================

//   @override
//   Future<Either<Failure, Invoice>> createInvoice({
//     required String customerId,
//     required List<CreateInvoiceItemParams> items,
//     String? number,
//     DateTime? date,
//     DateTime? dueDate,
//     PaymentMethod paymentMethod = PaymentMethod.cash,
//     InvoiceStatus? status,
//     double taxPercentage = 19,
//     double discountPercentage = 0,
//     double discountAmount = 0,
//     String? notes,
//     String? terms,
//     Map<String, dynamic>? metadata,
//   }) async {
//     if (!(await networkInfo.isConnected)) {
//       return const Left(
//         ConnectionFailure(
//           'Se requiere conexión a internet para crear facturas',
//         ),
//       );
//     }

//     try {
//       print('📄 InvoiceRepository: Creando factura...');

//       // Convertir parámetros a request model
//       final request = CreateInvoiceRequestModel(
//         customerId: customerId,
//         items:
//             items
//                 .map((item) => CreateInvoiceItemRequestModel.fromEntity(item))
//                 .toList(),
//         number: number,
//         date: date?.toIso8601String(),
//         dueDate: dueDate?.toIso8601String(),
//         paymentMethod: paymentMethod.value,
//         status: status?.value,
//         taxPercentage: taxPercentage,
//         discountPercentage: discountPercentage,
//         discountAmount: discountAmount,
//         notes: notes,
//         terms: terms,
//         metadata: metadata,
//       );

//       final createdInvoice = await remoteDataSource.createInvoice(request);

//       // Cachear la nueva factura
//       try {
//         await localDataSource.cacheInvoice(createdInvoice);
//         print('💾 Nueva factura cacheada');
//       } catch (e) {
//         print('⚠️ Error al cachear nueva factura: $e');
//       }

//       return Right(createdInvoice);
//     } catch (e) {
//       print('❌ Error al crear factura: $e');
//       return Left(_mapExceptionToFailure(e));
//     }
//   }

//   @override
//   Future<Either<Failure, Invoice>> updateInvoice({
//     required String id,
//     String? number,
//     DateTime? date,
//     DateTime? dueDate,
//     PaymentMethod? paymentMethod,
//     InvoiceStatus? status,
//     double? taxPercentage,
//     double? discountPercentage,
//     double? discountAmount,
//     String? notes,
//     String? terms,
//     Map<String, dynamic>? metadata,
//     String? customerId,
//     List<CreateInvoiceItemParams>? items,
//   }) async {
//     if (!(await networkInfo.isConnected)) {
//       return const Left(
//         ConnectionFailure(
//           'Se requiere conexión a internet para actualizar facturas',
//         ),
//       );
//     }

//     try {
//       print('📄 InvoiceRepository: Actualizando factura: $id');

//       final request = UpdateInvoiceRequestModel(
//         number: number,
//         date: date?.toIso8601String(),
//         dueDate: dueDate?.toIso8601String(),
//         paymentMethod: paymentMethod?.value,
//         status: status?.value,
//         taxPercentage: taxPercentage,
//         discountPercentage: discountPercentage,
//         discountAmount: discountAmount,
//         notes: notes,
//         terms: terms,
//         metadata: metadata,
//         customerId: customerId,
//         items:
//             items
//                 ?.map((item) => CreateInvoiceItemRequestModel.fromEntity(item))
//                 .toList(),
//       );

//       final updatedInvoice = await remoteDataSource.updateInvoice(id, request);

//       // Actualizar cache
//       try {
//         await localDataSource.cacheInvoice(updatedInvoice);
//         print('💾 Factura actualizada en cache');
//       } catch (e) {
//         print('⚠️ Error al actualizar factura en cache: $e');
//       }

//       return Right(updatedInvoice);
//     } catch (e) {
//       return Left(_mapExceptionToFailure(e));
//     }
//   }

//   @override
//   Future<Either<Failure, Invoice>> confirmInvoice(String id) async {
//     if (!(await networkInfo.isConnected)) {
//       return const Left(
//         ConnectionFailure(
//           'Se requiere conexión a internet para confirmar facturas',
//         ),
//       );
//     }

//     try {
//       final confirmedInvoice = await remoteDataSource.confirmInvoice(id);

//       // Actualizar cache
//       try {
//         await localDataSource.cacheInvoice(confirmedInvoice);
//       } catch (e) {
//         print('⚠️ Error al actualizar factura confirmada en cache: $e');
//       }

//       return Right(confirmedInvoice);
//     } catch (e) {
//       return Left(_mapExceptionToFailure(e));
//     }
//   }

//   @override
//   Future<Either<Failure, Invoice>> cancelInvoice(String id) async {
//     if (!(await networkInfo.isConnected)) {
//       return const Left(
//         ConnectionFailure(
//           'Se requiere conexión a internet para cancelar facturas',
//         ),
//       );
//     }

//     try {
//       final cancelledInvoice = await remoteDataSource.cancelInvoice(id);

//       // Actualizar cache
//       try {
//         await localDataSource.cacheInvoice(cancelledInvoice);
//       } catch (e) {
//         print('⚠️ Error al actualizar factura cancelada en cache: $e');
//       }

//       return Right(cancelledInvoice);
//     } catch (e) {
//       return Left(_mapExceptionToFailure(e));
//     }
//   }

//   @override
//   Future<Either<Failure, Invoice>> addPayment({
//     required String invoiceId,
//     required double amount,
//     required PaymentMethod paymentMethod,
//     DateTime? paymentDate,
//     String? reference,
//     String? notes,
//   }) async {
//     if (!(await networkInfo.isConnected)) {
//       return const Left(
//         ConnectionFailure('Se requiere conexión a internet para agregar pagos'),
//       );
//     }

//     try {
//       final request = AddPaymentRequestModel(
//         amount: amount,
//         paymentMethod: paymentMethod.value,
//         paymentDate: paymentDate?.toIso8601String(),
//         reference: reference,
//         notes: notes,
//       );

//       final updatedInvoice = await remoteDataSource.addPayment(
//         invoiceId,
//         request,
//       );

//       // Actualizar cache
//       try {
//         await localDataSource.cacheInvoice(updatedInvoice);
//       } catch (e) {
//         print('⚠️ Error al actualizar factura con pago en cache: $e');
//       }

//       return Right(updatedInvoice);
//     } catch (e) {
//       return Left(_mapExceptionToFailure(e));
//     }
//   }

//   @override
//   Future<Either<Failure, void>> deleteInvoice(String id) async {
//     if (!(await networkInfo.isConnected)) {
//       return const Left(
//         ConnectionFailure(
//           'Se requiere conexión a internet para eliminar facturas',
//         ),
//       );
//     }

//     try {
//       await remoteDataSource.deleteInvoice(id);

//       // Remover del cache
//       try {
//         await localDataSource.removeCachedInvoice(id);
//       } catch (e) {
//         print('⚠️ Error al remover factura del cache: $e');
//       }

//       return const Right(null);
//     } catch (e) {
//       return Left(_mapExceptionToFailure(e));
//     }
//   }

//   // ==================== HELPER METHODS ====================

//   /// ✅ NUEVO: Obtener facturas desde mock o cache
//   Future<Either<Failure, PaginatedResult<Invoice>>> _getInvoicesFromMockOrCache(
//     InvoiceQueryParams params,
//   ) async {
//     try {
//       // Primero intentar cache
//       try {
//         return await _getInvoicesFromCache(params);
//       } catch (e) {
//         print('⚠️ Error al obtener desde cache: $e');
//         // Si falla cache, usar mock
//         return _getInvoicesFromMock(params);
//       }
//     } catch (e) {
//       print('❌ Error al obtener facturas desde mock/cache: $e');
//       return const Left(CacheFailure('Error al obtener facturas'));
//     }
//   }

//   /// ✅ NUEVO: Obtener facturas desde datos mock
//   Either<Failure, PaginatedResult<Invoice>> _getInvoicesFromMock(
//     InvoiceQueryParams params,
//   ) {
//     print('🎭 Usando datos mock para facturas');

//     List<InvoiceModel> mockInvoices = _getMockInvoices();

//     // Aplicar filtros básicos
//     if (params.search != null && params.search!.isNotEmpty) {
//       final searchTerm = params.search!.toLowerCase();
//       mockInvoices =
//           mockInvoices
//               .where(
//                 (invoice) =>
//                     invoice.number.toLowerCase().contains(searchTerm) ||
//                     invoice.customerName.toLowerCase().contains(searchTerm) ||
//                     (invoice.notes?.toLowerCase().contains(searchTerm) ??
//                         false),
//               )
//               .toList();
//     }

//     if (params.status != null) {
//       mockInvoices =
//           mockInvoices
//               .where((invoice) => invoice.status == params.status)
//               .toList();
//     }

//     if (params.customerId != null) {
//       mockInvoices =
//           mockInvoices
//               .where((invoice) => invoice.customerId == params.customerId)
//               .toList();
//     }

//     // Aplicar ordenamiento
//     if (params.sortBy == 'createdAt') {
//       mockInvoices.sort(
//         (a, b) =>
//             params.sortOrder == 'DESC'
//                 ? b.createdAt.compareTo(a.createdAt)
//                 : a.createdAt.compareTo(b.createdAt),
//       );
//     }

//     // Aplicar paginación
//     final startIndex = (params.page - 1) * params.limit;
//     final endIndex = startIndex + params.limit;

//     final paginatedInvoices =
//         mockInvoices.length > startIndex
//             ? mockInvoices.sublist(
//               startIndex,
//               endIndex > mockInvoices.length ? mockInvoices.length : endIndex,
//             )
//             : <InvoiceModel>[];

//     // Crear meta de paginación
//     final totalPages = (mockInvoices.length / params.limit).ceil();
//     final meta = PaginationMeta(
//       page: params.page,
//       limit: params.limit,
//       totalItems: mockInvoices.length,
//       totalPages: totalPages,
//       hasNextPage: params.page < totalPages,
//       hasPreviousPage: params.page > 1,
//     );

//     return Right(PaginatedResult<Invoice>(data: paginatedInvoices, meta: meta));
//   }

//   /// Obtener facturas desde cache con filtrado básico
//   Future<Either<Failure, PaginatedResult<Invoice>>> _getInvoicesFromCache(
//     InvoiceQueryParams params,
//   ) async {
//     try {
//       List<InvoiceModel> cachedInvoices =
//           await localDataSource.getCachedInvoices();

//       // Aplicar filtros básicos
//       if (params.search != null && params.search!.isNotEmpty) {
//         cachedInvoices = await localDataSource.searchCachedInvoices(
//           params.search!,
//         );
//       }

//       if (params.status != null) {
//         cachedInvoices =
//             cachedInvoices
//                 .where((invoice) => invoice.status == params.status)
//                 .toList();
//       }

//       if (params.customerId != null) {
//         cachedInvoices =
//             cachedInvoices
//                 .where((invoice) => invoice.customerId == params.customerId)
//                 .toList();
//       }

//       // Aplicar ordenamiento básico
//       if (params.sortBy == 'createdAt') {
//         cachedInvoices.sort(
//           (a, b) =>
//               params.sortOrder == 'DESC'
//                   ? b.createdAt.compareTo(a.createdAt)
//                   : a.createdAt.compareTo(b.createdAt),
//         );
//       }

//       // Aplicar paginación básica
//       final startIndex = (params.page - 1) * params.limit;
//       final endIndex = startIndex + params.limit;

//       final paginatedInvoices =
//           cachedInvoices.length > startIndex
//               ? cachedInvoices.sublist(
//                 startIndex,
//                 endIndex > cachedInvoices.length
//                     ? cachedInvoices.length
//                     : endIndex,
//               )
//               : <InvoiceModel>[];

//       // Crear meta de paginación
//       final totalPages = (cachedInvoices.length / params.limit).ceil();
//       final meta = PaginationMeta(
//         page: params.page,
//         limit: params.limit,
//         totalItems: cachedInvoices.length,
//         totalPages: totalPages,
//         hasNextPage: params.page < totalPages,
//         hasPreviousPage: params.page > 1,
//       );

//       return Right(
//         PaginatedResult<Invoice>(data: paginatedInvoices, meta: meta),
//       );
//     } catch (e) {
//       print('❌ Error al obtener facturas desde cache: $e');
//       return const Left(CacheFailure('Error al obtener facturas desde cache'));
//     }
//   }

//   /// ✅ NUEVO: Generar datos mock para facturas
//   List<InvoiceModel> _getMockInvoices() {
//     final now = DateTime.now();

//     return [
//       InvoiceModel(
//         id: 'invoice-1',
//         number: 'INV-2024-001',
//         date: now.subtract(const Duration(days: 45)),
//         dueDate: now.subtract(const Duration(days: 15)),
//         status: InvoiceStatus.overdue,
//         paymentMethod: PaymentMethod.bankTransfer,
//         subtotal: 1500.00,
//         taxPercentage: 19,
//         taxAmount: 285.00,
//         discountPercentage: 0,
//         discountAmount: 0,
//         total: 1785.00,
//         paidAmount: 0,
//         balanceDue: 1785.00,
//         notes: 'Factura vencida - requiere seguimiento',
//         customerId: 'customer-1',
//         createdById: 'user-1',
//         items: [],
//         createdAt: now.subtract(const Duration(days: 45)),
//         updatedAt: now.subtract(const Duration(days: 40)),
//       ),
//       InvoiceModel(
//         id: 'invoice-2',
//         number: 'INV-2024-002',
//         date: now.subtract(const Duration(days: 35)),
//         dueDate: now.subtract(const Duration(days: 5)),
//         status: InvoiceStatus.overdue,
//         paymentMethod: PaymentMethod.cash,
//         subtotal: 2800.00,
//         taxPercentage: 19,
//         taxAmount: 532.00,
//         discountPercentage: 0,
//         discountAmount: 0,
//         total: 3332.00,
//         paidAmount: 0,
//         balanceDue: 3332.00,
//         notes: 'Pago pendiente por transferencia',
//         customerId: 'customer-2',
//         createdById: 'user-1',
//         items: [],
//         createdAt: now.subtract(const Duration(days: 35)),
//         updatedAt: now.subtract(const Duration(days: 30)),
//       ),
//       InvoiceModel(
//         id: 'invoice-3',
//         number: 'INV-2024-003',
//         date: now.subtract(const Duration(days: 30)),
//         dueDate: now.add(const Duration(days: 15)),
//         status: InvoiceStatus.pending,
//         paymentMethod: PaymentMethod.creditCard,
//         subtotal: 4200.00,
//         taxPercentage: 19,
//         taxAmount: 798.00,
//         discountPercentage: 5,
//         discountAmount: 210.00,
//         total: 4788.00,
//         paidAmount: 0,
//         balanceDue: 4788.00,
//         notes: 'Cliente prefiere pago con tarjeta',
//         customerId: 'customer-3',
//         createdById: 'user-1',
//         items: [],
//         createdAt: now.subtract(const Duration(days: 30)),
//         updatedAt: now.subtract(const Duration(days: 25)),
//       ),
//       InvoiceModel(
//         id: 'invoice-4',
//         number: 'INV-2024-004',
//         date: now.subtract(const Duration(days: 25)),
//         dueDate: now.add(const Duration(days: 20)),
//         status: InvoiceStatus.paid,
//         paymentMethod: PaymentMethod.bankTransfer,
//         subtotal: 6500.00,
//         taxPercentage: 19,
//         taxAmount: 1235.00,
//         discountPercentage: 0,
//         discountAmount: 0,
//         total: 7735.00,
//         paidAmount: 7735.00,
//         balanceDue: 0,
//         notes: 'Pagado completamente - cliente VIP',
//         customerId: 'customer-4',
//         createdById: 'user-1',
//         items: [],
//         createdAt: now.subtract(const Duration(days: 25)),
//         updatedAt: now.subtract(const Duration(days: 20)),
//       ),
//       InvoiceModel(
//         id: 'invoice-5',
//         number: 'INV-2024-005',
//         date: now.subtract(const Duration(days: 20)),
//         dueDate: now.add(const Duration(days: 25)),
//         status: InvoiceStatus.paid,
//         paymentMethod: PaymentMethod.cash,
//         subtotal: 3200.00,
//         taxPercentage: 19,
//         taxAmount: 608.00,
//         discountPercentage: 10,
//         discountAmount: 320.00,
//         total: 3488.00,
//         paidAmount: 3488.00,
//         balanceDue: 0,
//         notes: 'Pago en efectivo - descuento aplicado',
//         customerId: 'customer-5',
//         createdById: 'user-1',
//         items: [],
//         createdAt: now.subtract(const Duration(days: 20)),
//         updatedAt: now.subtract(const Duration(days: 15)),
//       ),
//       InvoiceModel(
//         id: 'invoice-6',
//         number: 'INV-2024-006',
//         date: now.subtract(const Duration(days: 15)),
//         dueDate: now.add(const Duration(days: 30)),
//         status: InvoiceStatus.pending,
//         paymentMethod: PaymentMethod.bankTransfer,
//         subtotal: 8900.00,
//         taxPercentage: 19,
//         taxAmount: 1691.00,
//         discountPercentage: 0,
//         discountAmount: 0,
//         total: 10591.00,
//         paidAmount: 0,
//         balanceDue: 10591.00,
//         notes: 'Proyecto grande - pago en 30 días',
//         customerId: 'customer-6',
//         createdById: 'user-1',
//         items: [],
//         createdAt: now.subtract(const Duration(days: 15)),
//         updatedAt: now.subtract(const Duration(days: 10)),
//       ),
//       InvoiceModel(
//         id: 'invoice-7',
//         number: 'INV-2024-007',
//         date: now.subtract(const Duration(days: 10)),
//         dueDate: now.add(const Duration(days: 35)),
//         status: InvoiceStatus.partiallyPaid,
//         paymentMethod: PaymentMethod.creditCard,
//         subtotal: 5400.00,
//         taxPercentage: 19,
//         taxAmount: 1026.00,
//         discountPercentage: 0,
//         discountAmount: 0,
//         total: 6426.00,
//         paidAmount: 3000.00,
//         balanceDue: 3426.00,
//         notes: 'Pago parcial recibido - saldo pendiente',
//         customerId: 'customer-7',
//         createdById: 'user-1',
//         items: [],
//         createdAt: now.subtract(const Duration(days: 10)),
//         updatedAt: now.subtract(const Duration(days: 5)),
//       ),
//       InvoiceModel(
//         id: 'invoice-8',
//         number: 'INV-2024-008',
//         date: now.subtract(const Duration(days: 8)),
//         dueDate: now.add(const Duration(days: 37)),
//         status: InvoiceStatus.paid,
//         paymentMethod: PaymentMethod.bankTransfer,
//         subtotal: 2100.00,
//         taxPercentage: 19,
//         taxAmount: 399.00,
//         discountPercentage: 0,
//         discountAmount: 0,
//         total: 2499.00,
//         paidAmount: 2499.00,
//         balanceDue: 0,
//         notes: 'Pago rápido - cliente confiable',
//         customerId: 'customer-8',
//         createdById: 'user-1',
//         items: [],
//         createdAt: now.subtract(const Duration(days: 8)),
//         updatedAt: now.subtract(const Duration(days: 3)),
//       ),
//       InvoiceModel(
//         id: 'invoice-9',
//         number: 'INV-2024-009',
//         date: now.subtract(const Duration(days: 5)),
//         dueDate: now.add(const Duration(days: 40)),
//         status: InvoiceStatus.pending,
//         paymentMethod: PaymentMethod.cash,
//         subtotal: 1800.00,
//         taxPercentage: 19,
//         taxAmount: 342.00,
//         discountPercentage: 0,
//         discountAmount: 0,
//         total: 2142.00,
//         paidAmount: 0,
//         balanceDue: 2142.00,
//         notes: 'Cliente nuevo - primer pedido',
//         customerId: 'customer-9',
//         createdById: 'user-1',
//         items: [],
//         createdAt: now.subtract(const Duration(days: 5)),
//         updatedAt: now.subtract(const Duration(days: 1)),
//       ),
//       InvoiceModel(
//         id: 'invoice-10',
//         number: 'INV-2024-010',
//         date: now.subtract(const Duration(days: 3)),
//         dueDate: now.add(const Duration(days: 42)),
//         status: InvoiceStatus.draft,
//         paymentMethod: PaymentMethod.bankTransfer,
//         subtotal: 7200.00,
//         taxPercentage: 19,
//         taxAmount: 1368.00,
//         discountPercentage: 0,
//         discountAmount: 0,
//         total: 8568.00,
//         paidAmount: 0,
//         balanceDue: 8568.00,
//         notes: 'Borrador - pendiente de envío',
//         customerId: 'customer-10',
//         createdById: 'user-1',
//         items: [],
//         createdAt: now.subtract(const Duration(days: 3)),
//         updatedAt: now.subtract(const Duration(hours: 12)),
//       ),
//       InvoiceModel(
//         id: 'invoice-11',
//         number: 'INV-2024-011',
//         date: now.subtract(const Duration(days: 2)),
//         dueDate: now.add(const Duration(days: 43)),
//         status: InvoiceStatus.paid,
//         paymentMethod: PaymentMethod.creditCard,
//         subtotal: 950.00,
//         taxPercentage: 19,
//         taxAmount: 180.50,
//         discountPercentage: 15,
//         discountAmount: 142.50,
//         total: 988.00,
//         paidAmount: 988.00,
//         balanceDue: 0,
//         notes: 'Pago inmediato - descuento por pronto pago',
//         customerId: 'customer-11',
//         createdById: 'user-1',
//         items: [],
//         createdAt: now.subtract(const Duration(days: 2)),
//         updatedAt: now.subtract(const Duration(hours: 6)),
//       ),
//       InvoiceModel(
//         id: 'invoice-12',
//         number: 'INV-2024-012',
//         date: now.subtract(const Duration(days: 1)),
//         dueDate: now.add(const Duration(days: 44)),
//         status: InvoiceStatus.pending,
//         paymentMethod: PaymentMethod.bankTransfer,
//         subtotal: 12500.00,
//         taxPercentage: 19,
//         taxAmount: 2375.00,
//         discountPercentage: 0,
//         discountAmount: 0,
//         total: 14875.00,
//         paidAmount: 0,
//         balanceDue: 14875.00,
//         notes: 'Orden grande - cliente corporativo',
//         customerId: 'customer-12',
//         createdById: 'user-1',
//         items: [],
//         createdAt: now.subtract(const Duration(days: 1)),
//         updatedAt: now.subtract(const Duration(hours: 2)),
//       ),
//     ];
//   }

//   /// ✅ NUEVO: Obtener estadísticas mock
//   InvoiceStatsModel _getMockInvoiceStats() {
//     final mockInvoices = _getMockInvoices();

//     // Calcular estadísticas desde las facturas mock
//     int total = mockInvoices.length;
//     int draft = 0;
//     int pending = 0;
//     int paid = 0;
//     int overdue = 0;
//     int cancelled = 0;
//     int partiallyPaid = 0;

//     double totalSales = 0;
//     double pendingAmount = 0;
//     double overdueAmount = 0;

//     final now = DateTime.now();

//     for (final invoice in mockInvoices) {
//       totalSales += invoice.total;

//       switch (invoice.status) {
//         case InvoiceStatus.draft:
//           draft++;
//           break;
//         case InvoiceStatus.pending:
//           if (invoice.dueDate.isBefore(now)) {
//             overdue++;
//             overdueAmount += invoice.balanceDue;
//           } else {
//             pending++;
//             pendingAmount += invoice.balanceDue;
//           }
//           break;
//         case InvoiceStatus.paid:
//           paid++;
//           break;
//         case InvoiceStatus.overdue:
//           overdue++;
//           overdueAmount += invoice.balanceDue;
//           break;
//         case InvoiceStatus.cancelled:
//           cancelled++;
//           break;
//         case InvoiceStatus.partiallyPaid:
//           if (invoice.dueDate.isBefore(now)) {
//             overdue++;
//             overdueAmount += invoice.balanceDue;
//           } else {
//             partiallyPaid++;
//             pendingAmount += invoice.balanceDue;
//           }
//           break;
//       }
//     }

//     return InvoiceStatsModel(
//       total: total,
//       draft: draft,
//       pending: pending,
//       paid: paid,
//       overdue: overdue,
//       cancelled: cancelled,
//       partiallyPaid: partiallyPaid,
//       totalSales: totalSales,
//       pendingAmount: pendingAmount,
//       overdueAmount: overdueAmount,
//     );
//   }

//   /// ✅ NUEVO: Obtener facturas vencidas mock
//   List<InvoiceModel> _getMockOverdueInvoices() {
//     final allInvoices = _getMockInvoices();
//     final now = DateTime.now();

//     return allInvoices
//         .where(
//           (invoice) =>
//               (invoice.status == InvoiceStatus.overdue) ||
//               (invoice.dueDate.isBefore(now) &&
//                   (invoice.status == InvoiceStatus.pending ||
//                       invoice.status == InvoiceStatus.partiallyPaid)),
//         )
//         .toList();
//   }

//   /// ✅ NUEVO: Obtener factura mock por ID
//   InvoiceModel? _getMockInvoiceById(String id) {
//     final allInvoices = _getMockInvoices();
//     try {
//       return allInvoices.firstWhere((invoice) => invoice.id == id);
//     } catch (e) {
//       return null;
//     }
//   }

//   /// ✅ NUEVO: Obtener factura mock por número
//   InvoiceModel? _getMockInvoiceByNumber(String number) {
//     final allInvoices = _getMockInvoices();
//     try {
//       return allInvoices.firstWhere((invoice) => invoice.number == number);
//     } catch (e) {
//       return null;
//     }
//   }

//   /// ✅ NUEVO: Obtener facturas mock por cliente
//   List<InvoiceModel> _getMockInvoicesByCustomer(String customerId) {
//     final allInvoices = _getMockInvoices();
//     return allInvoices
//         .where((invoice) => invoice.customerId == customerId)
//         .toList();
//   }

//   /// Mapear excepciones a failures
//   Failure _mapExceptionToFailure(Object exception) {
//     if (exception is ServerException) {
//       return ServerFailure(exception.message);
//     } else if (exception is ConnectionException) {
//       return ConnectionFailure(exception.message);
//     } else if (exception is CacheException) {
//       return CacheFailure(exception.message);
//     } else {
//       return ServerFailure('Error inesperado: ${exception.toString()}');
//     }
//   }
// }
