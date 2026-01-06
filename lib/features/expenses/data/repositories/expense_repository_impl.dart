// lib/features/expenses/data/repositories/expense_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/services/file_service.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../../../app/data/local/enums/isar_enums.dart';
import '../models/isar/isar_expense.dart';

import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/entities/expense_stats.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_remote_datasource.dart';
import '../datasources/expense_local_datasource.dart';
import '../models/expense_model.dart';
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

        // Cache the results in SecureStorage
        await localDataSource.cacheExpenses(response.data);

        // Cache in ISAR for offline-first support
        print('💾 [EXPENSE_REPO] Cacheando ${response.data.length} gastos en ISAR...');
        final isar = IsarDatabase.instance.database;
        for (final expenseModel in response.data) {
          final expense = expenseModel.toEntity();

          // Crear IsarExpense desde ExpenseModel
          final isarExpense = IsarExpense.create(
            serverId: expenseModel.id,
            description: expenseModel.description,
            amount: expenseModel.amount,
            date: expenseModel.date,
            categoryId: expenseModel.categoryId,
            type: _mapExpenseType(expenseModel.type),
            paymentMethod: _mapPaymentMethod(expenseModel.paymentMethod),
            status: _mapExpenseStatus(expenseModel.status),
            vendor: expenseModel.vendor,
            invoiceNumber: expenseModel.invoiceNumber,
            reference: expenseModel.reference,
            notes: expenseModel.notes,
            attachmentsJson: expenseModel.attachments?.isNotEmpty == true
                ? expenseModel.attachments!.join('|')
                : null,
            tagsJson: expenseModel.tags?.isNotEmpty == true
                ? expenseModel.tags!.join('|')
                : null,
            metadataJson: expenseModel.metadata?.toString(),
            approvedById: expenseModel.approvedById,
            approvedAt: expenseModel.approvedAt,
            rejectionReason: expenseModel.rejectionReason,
            createdById: expenseModel.createdById,
            createdAt: expenseModel.createdAt,
            updatedAt: expenseModel.updatedAt,
            deletedAt: expenseModel.deletedAt,
            isSynced: true,
            lastSyncAt: DateTime.now(),
          );

          await isar.writeTxn(() async {
            await isar.isarExpenses.put(isarExpense);
          });
        }
        print('✅ [EXPENSE_REPO] ${response.data.length} gastos cacheados en ISAR');

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
        print('⚠️ [EXPENSE_REPO] ServerException: ${e.message} - Fallback a cache...');
        return _getExpensesFromCache(page, limit);
      } catch (e) {
        print('⚠️ [EXPENSE_REPO] Exception: $e - Fallback a cache...');
        return _getExpensesFromCache(page, limit);
      }
    } else {
      print('📴 [EXPENSE_REPO] OFFLINE - Cargando desde cache...');
      return _getExpensesFromCache(page, limit);
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
        print('⚠️ ExpenseRepository: ServerException en createExpense, cambiando a modo offline');
        return _createExpenseOffline(
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
      } on ConnectionException catch (e) {
        print('⚠️ ExpenseRepository: ConnectionException en createExpense, cambiando a modo offline');
        return _createExpenseOffline(
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
      } catch (e) {
        print('⚠️ ExpenseRepository: Error genérico en createExpense: $e - Fallback offline...');
        return _createExpenseOffline(
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
      }
    } else {
      // Modo offline directo
      return _createExpenseOffline(
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
        print('⚠️ [EXPENSE_REPO] ServerException en update: ${e.message} - Fallback offline...');
        return _updateExpenseOffline(
          id: id,
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
      } catch (e) {
        print('⚠️ [EXPENSE_REPO] Exception en update: $e - Fallback offline...');
        return _updateExpenseOffline(
          id: id,
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
      }
    } else {
      // Sin conexión, actualizar en modo offline
      print('📴 [EXPENSE_REPO] OFFLINE - Actualizando gasto offline...');
      return _updateExpenseOffline(
        id: id,
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
    }
  }

  /// Actualiza un gasto en modo offline
  /// Guarda en ISAR + SecureStorage y agrega a cola de sincronización
  Future<Either<Failure, Expense>> _updateExpenseOffline({
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
    print('💾 ExpenseRepository: Actualizando gasto offline: $id');
    try {
      final isar = IsarDatabase.instance.database;

      // ✅ PASO 1: Actualizar en ISAR primero
      final isarExpense = await isar.isarExpenses
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarExpense == null) {
        return Left(CacheFailure('Gasto no encontrado en ISAR: $id'));
      }

      // Actualizar campos en ISAR
      if (description != null) isarExpense.description = description;
      if (amount != null) isarExpense.amount = amount;
      if (date != null) isarExpense.date = date;
      if (categoryId != null) isarExpense.categoryId = categoryId;
      if (type != null) isarExpense.type = _mapExpenseType(type);
      if (paymentMethod != null) {
        isarExpense.paymentMethod = _mapPaymentMethod(paymentMethod);
      }
      if (vendor != null) isarExpense.vendor = vendor;
      if (invoiceNumber != null) isarExpense.invoiceNumber = invoiceNumber;
      if (reference != null) isarExpense.reference = reference;
      if (notes != null) isarExpense.notes = notes;
      if (attachments != null) {
        isarExpense.attachmentsJson =
            attachments.isNotEmpty ? attachments.join('|') : null;
      }
      if (tags != null) {
        isarExpense.tagsJson = tags.isNotEmpty ? tags.join('|') : null;
      }
      if (metadata != null) {
        isarExpense.metadataJson = metadata.toString();
      }

      isarExpense.markAsUnsynced();

      await isar.writeTxn(() async {
        await isar.isarExpenses.put(isarExpense);
      });
      print('✅ ExpenseRepository: Gasto actualizado en ISAR');

      // ✅ PASO 2: Actualizar SecureStorage
      try {
        final cachedExpense = await localDataSource.getCachedExpenseById(id);
        if (cachedExpense != null) {
          await localDataSource.cacheExpense(cachedExpense);
          print('✅ ExpenseRepository: Gasto actualizado en SecureStorage');
        }
      } catch (e) {
        print('⚠️ Error actualizando SecureStorage (no crítico): $e');
      }

      // ✅ PASO 3: Agregar a la cola de sincronización
      try {
        final syncService = Get.find<SyncService>();
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

        await syncService.addOperationForCurrentUser(
          entityType: 'Expense',
          entityId: id,
          operationType: SyncOperationType.update,
          data: request.toJson(),
          priority: 1,
        );
        print('📤 ExpenseRepository: UPDATE agregado a cola de sincronización');
      } catch (e) {
        print('⚠️ ExpenseRepository: Error agregando UPDATE a cola: $e');
      }

      print('✅ ExpenseRepository: Gasto actualizado offline exitosamente');
      return Right(isarExpense.toEntity());
    } catch (e) {
      print('❌ Error actualizando gasto offline: $e');
      return Left(CacheFailure('Error al actualizar gasto offline: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteExpense(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteExpense(id);

        // Soft delete en ISAR después de eliminar en servidor
        try {
          final isar = IsarDatabase.instance.database;
          final isarExpense = await isar.isarExpenses
              .filter()
              .serverIdEqualTo(id)
              .findFirst();

          if (isarExpense != null) {
            isarExpense.softDelete();
            await isar.writeTxn(() async {
              await isar.isarExpenses.put(isarExpense);
            });
            print('✅ Expense marcado como eliminado en ISAR: $id');
          }
        } catch (e) {
          print('⚠️ Error actualizando ISAR (no crítico): $e');
        }

        await localDataSource.removeCachedExpense(id);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      // Sin conexión, marcar para eliminación offline y sincronizar después
      print('📱 ExpenseRepository: Deleting expense offline: $id');
      try {
        // Soft delete en ISAR
        final isar = IsarDatabase.instance.database;
        final isarExpense = await isar.isarExpenses
            .filter()
            .serverIdEqualTo(id)
            .findFirst();

        if (isarExpense != null) {
          isarExpense.softDelete();
          await isar.writeTxn(() async {
            await isar.isarExpenses.put(isarExpense);
          });
          print('✅ Expense marcado como eliminado en ISAR (offline): $id');
        }

        // Remover del cache (no crítico)
        try {
          await localDataSource.removeCachedExpense(id);
        } catch (e) {
          print('⚠️ Error al actualizar cache (no crítico): $e');
        }

        // Agregar a la cola de sincronización
        try {
          final syncService = Get.find<SyncService>();
          await syncService.addOperationForCurrentUser(
            entityType: 'Expense',
            entityId: id,
            operationType: SyncOperationType.delete,
            data: {'id': id},
            priority: 1,
          );
          print('📤 ExpenseRepository: Eliminación agregada a cola de sincronización');
        } catch (e) {
          print('⚠️ ExpenseRepository: Error agregando eliminación a cola: $e');
        }

        print('✅ ExpenseRepository: Expense deleted offline successfully');
        return const Right(null);
      } catch (e) {
        print('❌ ExpenseRepository: Error deleting expense offline: $e');
        return Left(CacheFailure('Error al eliminar gasto offline: $e'));
      }
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

  // ==================== OFFLINE CREATE METHOD ====================

  /// Crea un gasto en modo offline cuando no hay conexión
  ///
  /// Genera un ID temporal, guarda en ISAR y SecureStorage,
  /// y agrega la operación a la cola de sincronización
  Future<Either<Failure, Expense>> _createExpenseOffline({
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
    print('📱 ExpenseRepository: Creando gasto offline: $description');
    try {
      // Generar un ID temporal único para el gasto offline
      final now = DateTime.now();
      final tempId = 'expense_offline_${now.millisecondsSinceEpoch}_${description.hashCode}';

      // Obtener el usuario actual (si está disponible)
      String createdById = 'offline_user';
      try {
        final authController = Get.find<dynamic>();
        if (authController.currentUser != null) {
          createdById = authController.currentUser.id;
        }
      } catch (e) {
        print('⚠️ ExpenseRepository: No se pudo obtener usuario actual: $e');
      }

      // Mapear el status
      IsarExpenseStatus isarStatus;
      if (status != null) {
        switch (status) {
          case ExpenseStatus.draft:
            isarStatus = IsarExpenseStatus.draft;
            break;
          case ExpenseStatus.pending:
            isarStatus = IsarExpenseStatus.pending;
            break;
          case ExpenseStatus.approved:
            isarStatus = IsarExpenseStatus.approved;
            break;
          case ExpenseStatus.rejected:
            isarStatus = IsarExpenseStatus.rejected;
            break;
          case ExpenseStatus.paid:
            isarStatus = IsarExpenseStatus.paid;
            break;
        }
      } else {
        isarStatus = IsarExpenseStatus.draft;
      }

      // Crear IsarExpense con ID temporal
      final isarExpense = IsarExpense.create(
        serverId: tempId,
        description: description,
        amount: amount,
        date: date,
        categoryId: categoryId,
        type: _mapExpenseType(type),
        paymentMethod: _mapPaymentMethod(paymentMethod),
        status: isarStatus,
        vendor: vendor,
        invoiceNumber: invoiceNumber,
        reference: reference,
        notes: notes,
        attachmentsJson: attachments?.isNotEmpty == true
            ? attachments!.join('|')
            : null,
        tagsJson: tags?.isNotEmpty == true
            ? tags!.join('|')
            : null,
        metadataJson: metadata?.toString(),
        approvedById: null,
        approvedAt: null,
        rejectionReason: null,
        createdById: createdById,
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        isSynced: false,
        lastSyncAt: null,
      );

      // Guardar en ISAR
      final isar = IsarDatabase.instance.database;
      await isar.writeTxn(() async {
        await isar.isarExpenses.put(isarExpense);
      });
      print('✅ ExpenseRepository: Gasto guardado en ISAR con ID temporal: $tempId');

      // Convertir a entidad domain para guardar en SecureStorage
      final expense = isarExpense.toEntity();

      // Convertir a ExpenseModel para guardar en SecureStorage
      final expenseModel = ExpenseModel(
        id: tempId,
        description: description,
        amount: amount,
        date: date,
        categoryId: categoryId,
        type: type,
        paymentMethod: paymentMethod,
        status: status ?? ExpenseStatus.draft,
        vendor: vendor,
        invoiceNumber: invoiceNumber,
        reference: reference,
        notes: notes,
        attachments: attachments,
        tags: tags,
        metadata: metadata,
        approvedById: null,
        approvedAt: null,
        rejectionReason: null,
        createdById: createdById,
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
      );

      // Guardar en SecureStorage
      await localDataSource.cacheExpense(expenseModel);
      print('✅ ExpenseRepository: Gasto guardado en SecureStorage');

      // Agregar a la cola de sincronización
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'expense',
          entityId: tempId,
          operationType: SyncOperationType.create,
          data: {
            'description': description,
            'amount': amount,
            'date': date.toIso8601String(),
            'categoryId': categoryId,
            'type': type.name,
            'paymentMethod': paymentMethod.name,
            'vendor': vendor,
            'invoiceNumber': invoiceNumber,
            'reference': reference,
            'notes': notes,
            'attachments': attachments,
            'tags': tags,
            'metadata': metadata,
            'status': status?.name,
          },
          priority: 1, // Alta prioridad para creación
        );
        print('📤 ExpenseRepository: Operación agregada a cola de sincronización');
      } catch (e) {
        print('⚠️ ExpenseRepository: Error agregando a cola de sync: $e');
      }

      print('✅ ExpenseRepository: Gasto creado offline exitosamente');
      return Right(expense);
    } catch (e) {
      print('❌ ExpenseRepository: Error creando gasto offline: $e');
      return Left(CacheFailure('Error al crear gasto offline: $e'));
    }
  }

  // ==================== SYNC OPERATIONS ====================

  /// Sincronizar gastos creados offline con el servidor
  Future<Either<Failure, List<Expense>>> syncOfflineExpenses() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No hay conexión a internet'));
    }

    try {
      print('🔄 ExpenseRepository: Starting offline expenses sync...');

      // Obtener gastos no sincronizados desde ISAR
      final isar = IsarDatabase.instance.database;
      final unsyncedExpenses = await isar.isarExpenses
          .filter()
          .isSyncedEqualTo(false)
          .and()
          .deletedAtIsNull()
          .findAll();

      if (unsyncedExpenses.isEmpty) {
        print('✅ ExpenseRepository: No expenses to sync');
        return const Right([]);
      }

      print('📤 ExpenseRepository: Syncing ${unsyncedExpenses.length} offline expenses...');
      final syncedExpenses = <Expense>[];

      for (final isarExpense in unsyncedExpenses) {
        try {
          // Determinar si es CREATE o UPDATE basándose en el serverId
          final isCreate = isarExpense.serverId.startsWith('expense_offline_');

          if (isCreate) {
            // CREATE: Enviar al servidor y actualizar con ID real
            print('📝 Creating expense: ${isarExpense.description}');

            final request = CreateExpenseRequestModel.fromParams(
              description: isarExpense.description,
              amount: isarExpense.amount,
              date: isarExpense.date,
              categoryId: isarExpense.categoryId,
              type: _reverseMapExpenseType(isarExpense.type),
              paymentMethod: _reverseMapPaymentMethod(isarExpense.paymentMethod),
              vendor: isarExpense.vendor,
              invoiceNumber: isarExpense.invoiceNumber,
              reference: isarExpense.reference,
              notes: isarExpense.notes,
              attachments: isarExpense.attachmentsJson?.split('|'),
              tags: isarExpense.tagsJson?.split('|'),
              status: _reverseMapExpenseStatus(isarExpense.status),
            );

            final created = await remoteDataSource.createExpense(request);

            // Actualizar ISAR con el ID real del servidor
            isarExpense.serverId = created.id;
            isarExpense.markAsSynced();

            await isar.writeTxn(() async {
              await isar.isarExpenses.put(isarExpense);
            });

            // También actualizar en SecureStorage
            await localDataSource.cacheExpense(created);

            syncedExpenses.add(created.toEntity());
            print('✅ Expense created and synced: ${isarExpense.description} -> ${created.id}');
          } else {
            // UPDATE: Enviar actualización al servidor
            print('📝 Updating expense: ${isarExpense.description}');

            final request = UpdateExpenseRequestModel.fromParams(
              description: isarExpense.description,
              amount: isarExpense.amount,
              date: isarExpense.date,
              categoryId: isarExpense.categoryId,
              type: _reverseMapExpenseType(isarExpense.type),
              paymentMethod: _reverseMapPaymentMethod(isarExpense.paymentMethod),
              vendor: isarExpense.vendor,
              invoiceNumber: isarExpense.invoiceNumber,
              reference: isarExpense.reference,
              notes: isarExpense.notes,
              attachments: isarExpense.attachmentsJson?.split('|'),
              tags: isarExpense.tagsJson?.split('|'),
            );

            final updated = await remoteDataSource.updateExpense(
              isarExpense.serverId,
              request,
            );

            isarExpense.markAsSynced();

            await isar.writeTxn(() async {
              await isar.isarExpenses.put(isarExpense);
            });

            // También actualizar en SecureStorage
            await localDataSource.cacheExpense(updated);

            syncedExpenses.add(updated.toEntity());
            print('✅ Expense updated and synced: ${isarExpense.description}');
          }
        } catch (e) {
          print('❌ Error sincronizando gasto ${isarExpense.description}: $e');
          // Continuar con la siguiente
        }
      }

      print('🎯 ExpenseRepository: Sync completed. Success: ${syncedExpenses.length}');
      return Right(syncedExpenses);
    } catch (e) {
      print('💥 ExpenseRepository: Error during offline expenses sync: $e');
      return Left(ServerFailure('Error al sincronizar gastos offline: $e'));
    }
  }

  // ==================== HELPER METHODS ====================

  IsarExpenseType _mapExpenseType(ExpenseType type) {
    switch (type) {
      case ExpenseType.operating:
        return IsarExpenseType.operating;
      case ExpenseType.administrative:
        return IsarExpenseType.administrative;
      case ExpenseType.sales:
        return IsarExpenseType.sales;
      case ExpenseType.financial:
        return IsarExpenseType.financial;
      case ExpenseType.extraordinary:
        return IsarExpenseType.extraordinary;
    }
  }

  IsarPaymentMethod _mapPaymentMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return IsarPaymentMethod.cash;
      case PaymentMethod.creditCard:
        return IsarPaymentMethod.creditCard;
      case PaymentMethod.debitCard:
        return IsarPaymentMethod.debitCard;
      case PaymentMethod.bankTransfer:
        return IsarPaymentMethod.bankTransfer;
      case PaymentMethod.check:
        return IsarPaymentMethod.check;
      case PaymentMethod.other:
        return IsarPaymentMethod.other;
    }
  }

  IsarExpenseStatus _mapExpenseStatus(ExpenseStatus status) {
    switch (status) {
      case ExpenseStatus.draft:
        return IsarExpenseStatus.draft;
      case ExpenseStatus.pending:
        return IsarExpenseStatus.pending;
      case ExpenseStatus.approved:
        return IsarExpenseStatus.approved;
      case ExpenseStatus.rejected:
        return IsarExpenseStatus.rejected;
      case ExpenseStatus.paid:
        return IsarExpenseStatus.paid;
    }
  }

  // Reverse mappers (ISAR -> Domain)
  ExpenseType _reverseMapExpenseType(IsarExpenseType type) {
    switch (type) {
      case IsarExpenseType.operating:
        return ExpenseType.operating;
      case IsarExpenseType.administrative:
        return ExpenseType.administrative;
      case IsarExpenseType.sales:
        return ExpenseType.sales;
      case IsarExpenseType.financial:
        return ExpenseType.financial;
      case IsarExpenseType.extraordinary:
        return ExpenseType.extraordinary;
    }
  }

  PaymentMethod _reverseMapPaymentMethod(IsarPaymentMethod method) {
    switch (method) {
      case IsarPaymentMethod.cash:
        return PaymentMethod.cash;
      case IsarPaymentMethod.creditCard:
        return PaymentMethod.creditCard;
      case IsarPaymentMethod.debitCard:
        return PaymentMethod.debitCard;
      case IsarPaymentMethod.bankTransfer:
        return PaymentMethod.bankTransfer;
      case IsarPaymentMethod.check:
        return PaymentMethod.check;
      case IsarPaymentMethod.credit:
        return PaymentMethod.other; // Expenses no tiene 'credit', mapear a 'other'
      case IsarPaymentMethod.clientBalance:
        return PaymentMethod.other; // Expenses no tiene 'clientBalance', mapear a 'other'
      case IsarPaymentMethod.other:
        return PaymentMethod.other;
    }
  }

  ExpenseStatus _reverseMapExpenseStatus(IsarExpenseStatus status) {
    switch (status) {
      case IsarExpenseStatus.draft:
        return ExpenseStatus.draft;
      case IsarExpenseStatus.pending:
        return ExpenseStatus.pending;
      case IsarExpenseStatus.approved:
        return ExpenseStatus.approved;
      case IsarExpenseStatus.rejected:
        return ExpenseStatus.rejected;
      case IsarExpenseStatus.paid:
        return ExpenseStatus.paid;
    }
  }

  /// Obtiene gastos desde cache (ISAR primero, luego SecureStorage como fallback)
  Future<Either<Failure, PaginatedResponse<Expense>>> _getExpensesFromCache(
    int page,
    int limit,
  ) async {
    try {
      print('💾 [EXPENSE_REPO] Intentando cargar gastos desde cache...');

      // ✅ PASO 1: Intentar desde ISAR primero
      final isar = IsarDatabase.instance.database;
      final isarExpenses = await isar.isarExpenses
          .filter()
          .deletedAtIsNull()
          .sortByCreatedAtDesc()
          .findAll();

      List<Expense> expenses;

      if (isarExpenses.isNotEmpty) {
        print('💾 [EXPENSE_REPO] ISAR tiene ${isarExpenses.length} gastos');
        expenses = isarExpenses.map((ie) => ie.toEntity()).toList();
      } else {
        // ✅ PASO 2: Si ISAR está vacío, intentar desde SecureStorage
        print('💾 [EXPENSE_REPO] ISAR vacío, intentando SecureStorage...');
        final cachedExpenses = await localDataSource.getCachedExpenses();

        if (cachedExpenses.isEmpty) {
          print('⚠️ [EXPENSE_REPO] SecureStorage también vacío');
          return Right(PaginatedResponse<Expense>(
            data: [],
            meta: PaginationMeta(
              page: page,
              limit: limit,
              total: 0,
              totalPages: 0,
              hasNext: false,
              hasPrev: false,
            ),
          ));
        }

        print('💾 [EXPENSE_REPO] SecureStorage tiene ${cachedExpenses.length} gastos');
        expenses = cachedExpenses.map((e) => e.toEntity()).toList();
      }

      // ✅ PASO 3: Aplicar paginación
      final startIndex = (page - 1) * limit;
      final endIndex = startIndex + limit;
      final paginatedData = expenses.sublist(
        startIndex.clamp(0, expenses.length),
        endIndex.clamp(0, expenses.length),
      );

      final meta = PaginationMeta(
        page: page,
        limit: limit,
        total: expenses.length,
        totalPages: (expenses.length / limit).ceil(),
        hasNext: endIndex < expenses.length,
        hasPrev: page > 1,
      );

      print('✅ [EXPENSE_REPO] Gastos cargados desde cache: ${paginatedData.length}');
      return Right(PaginatedResponse<Expense>(data: paginatedData, meta: meta));
    } catch (e) {
      print('❌ [EXPENSE_REPO] Error cargando desde cache: $e');
      return Left(CacheFailure('Error al obtener gastos del cache: $e'));
    }
  }
}