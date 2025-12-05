// lib/features/expenses/data/repositories/expense_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart' as dio;
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/services/file_service.dart';

import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/entities/expense_stats.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_remote_datasource.dart';
import '../datasources/expense_local_datasource.dart';
import '../models/create_expense_request_model.dart';
import '../models/update_expense_request_model.dart';
import '../models/create_expense_category_request_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDataSource remoteDataSource;
  final ExpenseLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  ExpenseRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, PaginatedResponse<Expense>>> getExpenses({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
    String? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? orderBy,
    String? orderDirection,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getExpenses(
          page: page,
          limit: limit,
          search: search,
          status: status,
          type: type,
          categoryId: categoryId,
          startDate: startDate,
          endDate: endDate,
          orderBy: orderBy,
          orderDirection: orderDirection,
        );

        // Cache the results
        await localDataSource.cacheExpenses(response.data);

        // Convert to domain response
        final paginatedResponse = response.toPaginatedResponse();
        final domainExpenses = paginatedResponse.data.map((e) => e.toEntity()).toList();
        
        return Right(
          PaginatedResponse<Expense>(
            data: domainExpenses,
            meta: paginatedResponse.meta,
          ),
        );
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      try {
        final cachedExpenses = await localDataSource.getCachedExpenses();
        final domainExpenses = cachedExpenses.map((e) => e.toEntity()).toList();

        // Simple pagination for cached data
        final startIndex = (page - 1) * limit;
        final endIndex = startIndex + limit;
        final paginatedData = domainExpenses.sublist(
          startIndex.clamp(0, domainExpenses.length),
          endIndex.clamp(0, domainExpenses.length),
        );

        return Right(
          PaginatedResponse<Expense>(
            data: paginatedData,
            meta: PaginationMeta(
              page: page,
              limit: limit,
              total: domainExpenses.length,
              totalPages: (domainExpenses.length / limit).ceil(),
              hasNext: endIndex < domainExpenses.length,
              hasPrev: page > 1,
            ),
          ),
        );
      } catch (e) {
        return Left(CacheFailure('Error al obtener datos del cache: $e'));
      }
    }
  }

  @override
  Future<Either<Failure, Expense>> getExpenseById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final expenseModel = await remoteDataSource.getExpenseById(id);
        await localDataSource.cacheExpense(expenseModel);
        return Right(expenseModel.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      try {
        final cachedExpense = await localDataSource.getCachedExpenseById(id);
        if (cachedExpense != null) {
          return Right(cachedExpense.toEntity());
        }
        return const Left(CacheFailure('Gasto no encontrado en cache'));
      } catch (e) {
        return Left(CacheFailure('Error al obtener datos del cache: $e'));
      }
    }
  }

  @override
  Future<Either<Failure, Expense>> createExpense({
    required String description,
    required double amount,
    required DateTime date,
    required String categoryId,
    required ExpenseType type,
    required PaymentMethod paymentMethod,
    String? vendor,
    String? invoiceNumber,
    String? reference,
    String? notes,
    List<String>? attachments,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    ExpenseStatus? status,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final request = CreateExpenseRequestModel.fromParams(
          description: description,
          amount: amount,
          date: date,
          categoryId: categoryId,
          type: type,
          paymentMethod: paymentMethod,
          vendor: vendor,
          invoiceNumber: invoiceNumber,
          reference: reference,
          notes: notes,
          attachments: attachments,
          tags: tags,
          metadata: metadata,
          status: status,
        );

        final expenseModel = await remoteDataSource.createExpense(request);
        await localDataSource.cacheExpense(expenseModel);
        return Right(expenseModel.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return const Left(ConnectionFailure('No hay conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, Expense>> updateExpense({
    required String id,
    String? description,
    double? amount,
    DateTime? date,
    String? categoryId,
    ExpenseType? type,
    PaymentMethod? paymentMethod,
    String? vendor,
    String? invoiceNumber,
    String? reference,
    String? notes,
    List<String>? attachments,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final request = UpdateExpenseRequestModel.fromParams(
          description: description,
          amount: amount,
          date: date,
          categoryId: categoryId,
          type: type,
          paymentMethod: paymentMethod,
          vendor: vendor,
          invoiceNumber: invoiceNumber,
          reference: reference,
          notes: notes,
          attachments: attachments,
          tags: tags,
          metadata: metadata,
        );

        final expenseModel = await remoteDataSource.updateExpense(id, request);
        await localDataSource.cacheExpense(expenseModel);
        return Right(expenseModel.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return const Left(ConnectionFailure('No hay conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteExpense(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteExpense(id);
        await localDataSource.removeCachedExpense(id);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return const Left(ConnectionFailure('No hay conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, Expense>> submitExpense(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final expenseModel = await remoteDataSource.submitExpense(id);
        await localDataSource.cacheExpense(expenseModel);
        return Right(expenseModel.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return const Left(ConnectionFailure('No hay conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, Expense>> approveExpense({
    required String id,
    String? notes,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final expenseModel = await remoteDataSource.approveExpense(id, notes);
        await localDataSource.cacheExpense(expenseModel);
        return Right(expenseModel.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return const Left(ConnectionFailure('No hay conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, Expense>> rejectExpense({
    required String id,
    required String reason,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final expenseModel = await remoteDataSource.rejectExpense(id, reason);
        await localDataSource.cacheExpense(expenseModel);
        return Right(expenseModel.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return const Left(ConnectionFailure('No hay conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, Expense>> markAsPaid(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final expenseModel = await remoteDataSource.markAsPaid(id);
        await localDataSource.cacheExpense(expenseModel);
        return Right(expenseModel.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return const Left(ConnectionFailure('No hay conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> searchExpenses(String query) async {
    if (await networkInfo.isConnected) {
      try {
        final expenseModels = await remoteDataSource.searchExpenses(query);
        final domainExpenses = expenseModels.map((e) => e.toEntity()).toList();
        return Right(domainExpenses);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      try {
        final cachedExpenses = await localDataSource.getCachedExpenses();
        final filteredExpenses = cachedExpenses
            .where(
              (expense) =>
                  expense.description.toLowerCase().contains(query.toLowerCase()) ||
                  (expense.vendor?.toLowerCase().contains(query.toLowerCase()) ?? false),
            )
            .map((e) => e.toEntity())
            .toList();
        return Right(filteredExpenses);
      } catch (e) {
        return Left(CacheFailure('Error al buscar en cache: $e'));
      }
    }
  }

  @override
  Future<Either<Failure, ExpenseStats>> getExpenseStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final statsModel = await remoteDataSource.getExpenseStats(
          startDate: startDate,
          endDate: endDate,
        );
        return Right(statsModel.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return const Left(ConnectionFailure('No hay conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResponse<ExpenseCategory>>> getExpenseCategories({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
    String? orderBy,
    String? orderDirection,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final categoriesResponse = await remoteDataSource.getExpenseCategories(
          page: page,
          limit: limit,
          search: search,
          status: status,
          orderBy: orderBy,
          orderDirection: orderDirection,
        );

        final domainCategories = categoriesResponse.data
            .map((category) => category.toEntity())
            .toList();

        return Right(
          PaginatedResponse<ExpenseCategory>(
            data: domainCategories,
            meta: categoriesResponse.meta != null
                ? PaginationMeta(
                    page: categoriesResponse.meta!.page,
                    limit: categoriesResponse.meta!.limit,
                    total: categoriesResponse.meta!.totalItems,
                    totalPages: categoriesResponse.meta!.totalPages,
                    hasNext: categoriesResponse.meta!.hasNextPage,
                    hasPrev: categoriesResponse.meta!.hasPreviousPage,
                  )
                : PaginationMeta(
                    page: page,
                    limit: limit,
                    total: domainCategories.length,
                    totalPages: (domainCategories.length / limit).ceil(),
                    hasNext: false,
                    hasPrev: false,
                  ),
          ),
        );
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      try {
        final cachedCategories = await localDataSource.getCachedExpenseCategories();
        final domainCategories = cachedCategories.map((e) => e.toEntity()).toList();

        // Simple pagination for cached data
        final startIndex = (page - 1) * limit;
        final endIndex = startIndex + limit;
        final paginatedData = domainCategories.sublist(
          startIndex.clamp(0, domainCategories.length),
          endIndex.clamp(0, domainCategories.length),
        );

        return Right(
          PaginatedResponse<ExpenseCategory>(
            data: paginatedData,
            meta: PaginationMeta(
              page: page,
              limit: limit,
              total: domainCategories.length,
              totalPages: (domainCategories.length / limit).ceil(),
              hasNext: endIndex < domainCategories.length,
              hasPrev: page > 1,
            ),
          ),
        );
      } catch (e) {
        return Left(CacheFailure('Error al obtener datos del cache: $e'));
      }
    }
  }

  @override
  Future<Either<Failure, PaginatedResponse<ExpenseCategory>>> getExpenseCategoriesWithStats({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
    String? orderBy,
    String? orderDirection,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final categoriesResponse = await remoteDataSource.getExpenseCategoriesWithStats(
          page: page,
          limit: limit,
          search: search,
          status: status,
          orderBy: orderBy,
          orderDirection: orderDirection,
        );

        final domainCategories = categoriesResponse.data
            .map((category) => category.toEntity())
            .toList();

        return Right(
          PaginatedResponse<ExpenseCategory>(
            data: domainCategories,
            meta: categoriesResponse.meta != null
                ? PaginationMeta(
                    page: categoriesResponse.meta!.page,
                    limit: categoriesResponse.meta!.limit,
                    total: categoriesResponse.meta!.totalItems,
                    totalPages: categoriesResponse.meta!.totalPages,
                    hasNext: categoriesResponse.meta!.hasNextPage,
                    hasPrev: categoriesResponse.meta!.hasPreviousPage,
                  )
                : PaginationMeta(
                    page: page,
                    limit: limit,
                    total: domainCategories.length,
                    totalPages: (domainCategories.length / limit).ceil(),
                    hasNext: false,
                    hasPrev: false,
                  ),
          ),
        );
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      // Fallback to regular categories without stats when offline
      return getExpenseCategories(
        page: page,
        limit: limit,
        search: search,
        status: status,
        orderBy: orderBy,
        orderDirection: orderDirection,
      );
    }
  }

  @override
  Future<Either<Failure, ExpenseCategory>> getExpenseCategoryById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final categoryModel = await remoteDataSource.getExpenseCategoryById(id);
        await localDataSource.cacheExpenseCategory(categoryModel);
        return Right(categoryModel.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      try {
        final cachedCategory = await localDataSource.getCachedExpenseCategoryById(id);
        if (cachedCategory != null) {
          return Right(cachedCategory.toEntity());
        }
        return const Left(CacheFailure('Categoría no encontrada en cache'));
      } catch (e) {
        return Left(CacheFailure('Error al obtener datos del cache: $e'));
      }
    }
  }

  @override
  Future<Either<Failure, ExpenseCategory>> createExpenseCategory({
    required String name,
    String? description,
    String? color,
    double? monthlyBudget,
    int? sortOrder,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final request = CreateExpenseCategoryRequestModel.fromParams(
          name: name,
          description: description,
          color: color,
          monthlyBudget: monthlyBudget,
          sortOrder: sortOrder,
        );

        final categoryModel = await remoteDataSource.createExpenseCategory(request);
        await localDataSource.cacheExpenseCategory(categoryModel);
        return Right(categoryModel.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return const Left(ConnectionFailure('No hay conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, ExpenseCategory>> updateExpenseCategory({
    required String id,
    String? name,
    String? description,
    String? color,
    double? monthlyBudget,
    int? sortOrder,
    ExpenseCategoryStatus? status,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final request = CreateExpenseCategoryRequestModel.fromParams(
          name: name ?? '',
          description: description,
          color: color,
          monthlyBudget: monthlyBudget,
          sortOrder: sortOrder,
        );

        final categoryModel = await remoteDataSource.updateExpenseCategory(id, request);
        await localDataSource.cacheExpenseCategory(categoryModel);
        return Right(categoryModel.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return const Left(ConnectionFailure('No hay conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteExpenseCategory(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteExpenseCategory(id);
        await localDataSource.removeCachedExpenseCategory(id);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return const Left(ConnectionFailure('No hay conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, List<ExpenseCategory>>> searchExpenseCategories(String query) async {
    if (await networkInfo.isConnected) {
      try {
        final categoryModels = await remoteDataSource.searchExpenseCategories(query);
        final domainCategories = categoryModels.map((e) => e.toEntity()).toList();
        return Right(domainCategories);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      try {
        final cachedCategories = await localDataSource.getCachedExpenseCategories();
        final filteredCategories = cachedCategories
            .where(
              (category) =>
                  category.name.toLowerCase().contains(query.toLowerCase()) ||
                  (category.description?.toLowerCase().contains(query.toLowerCase()) ?? false),
            )
            .map((e) => e.toEntity())
            .toList();
        return Right(filteredCategories);
      } catch (e) {
        return Left(CacheFailure('Error al buscar en cache: $e'));
      }
    }
  }

  @override
  Future<Either<Failure, List<String>>> uploadAttachments(
    String expenseId,
    List<AttachmentFile> files,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        // Convert AttachmentFile to MultipartFile
        final multipartFiles = <dio.MultipartFile>[];

        for (final file in files) {
          if (file.bytes != null) {
            multipartFiles.add(
              dio.MultipartFile.fromBytes(
                file.bytes!,
                filename: file.name,
              ),
            );
          }
        }

        final urls = await remoteDataSource.uploadAttachments(
          expenseId,
          multipartFiles,
        );
        return Right(urls);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error al subir adjuntos: $e'));
      }
    } else {
      return Left(NetworkFailure('No hay conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAttachment(
    String expenseId,
    String filename,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteAttachment(expenseId, filename);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error al eliminar adjunto: $e'));
      }
    } else {
      return Left(NetworkFailure('No hay conexión a internet'));
    }
  }
}