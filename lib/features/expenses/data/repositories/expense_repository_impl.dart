// lib/features/expenses/data/repositories/expense_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/services/file_service.dart';
import '../../../../app/core/utils/app_logger.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../../../app/data/local/enums/isar_enums.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
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
import '../models/expense_category_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDataSource remoteDataSource;
  final ExpenseLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  ExpenseRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  /// Formatea un DateTime como 'YYYY-MM-DD' preservando los componentes
  /// locales del objeto (si es TZDateTime, ya viene en la TZ del tenant).
  /// Evita el bug de que toIso8601String() convierta a UTC y corra el día.
  static String _ymd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

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
        AppLogger.d(' [EXPENSE_REPO] Cacheando ${response.data.length} gastos en ISAR...');
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
            await isar.isarExpenses.putByServerId(isarExpense);
          });
        }
        AppLogger.i(' [EXPENSE_REPO] ${response.data.length} gastos cacheados en ISAR');

        // ✅ Limpiar registros ISAR huérfanos con IDs temporales
        // Estos son gastos creados offline cuyo sync handler antiguo no actualizó ISAR
        try {
          final orphanedExpenses = await isar.isarExpenses
              .filter()
              .serverIdStartsWith('expense_offline_')
              .findAll();

          if (orphanedExpenses.isNotEmpty) {
            // Verificar cuáles tienen operaciones de sync pendientes
            final isarDb = IsarDatabase.instance;
            final pendingOps = await isarDb.getPendingSyncOperationsByType('expense');
            final pendingEntityIds = pendingOps.map((op) => op.entityId).toSet();

            // También verificar con 'Expense' (PascalCase)
            final pendingOpsUpper = await isarDb.getPendingSyncOperationsByType('Expense');
            pendingEntityIds.addAll(pendingOpsUpper.map((op) => op.entityId));

            final toDelete = orphanedExpenses
                .where((e) => !pendingEntityIds.contains(e.serverId))
                .toList();

            if (toDelete.isNotEmpty) {
              await isar.writeTxn(() async {
                await isar.isarExpenses.deleteAll(
                  toDelete.map((e) => e.id).toList(),
                );
              });
              AppLogger.i(
                ' [EXPENSE_REPO] Limpiados ${toDelete.length} gastos huérfanos de ISAR',
              );
            }
          }
        } catch (e) {
          AppLogger.w(' [EXPENSE_REPO] Error limpiando huérfanos: $e');
        }

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
        AppLogger.w(' [EXPENSE_REPO] ServerException: ${e.message} - Fallback a cache...');
        return _getExpensesFromCache(page, limit,
          status: status, type: type, categoryId: categoryId,
          startDate: startDate, endDate: endDate, search: search,
        );
      } catch (e) {
        AppLogger.w(' [EXPENSE_REPO] Exception: $e - Fallback a cache...');
        return _getExpensesFromCache(page, limit,
          status: status, type: type, categoryId: categoryId,
          startDate: startDate, endDate: endDate, search: search,
        );
      }
    } else {
      AppLogger.d(' [EXPENSE_REPO] OFFLINE - Cargando desde cache...');
      return _getExpensesFromCache(page, limit,
        status: status, type: type, categoryId: categoryId,
        startDate: startDate, endDate: endDate, search: search,
      );
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
        AppLogger.w('ServerException en getExpenseById, fallback cache: ${e.message}');
        return _getExpenseByIdFromCache(id);
      } catch (e) {
        AppLogger.w('Exception en getExpenseById, fallback cache: $e');
        return _getExpenseByIdFromCache(id);
      }
    } else {
      return _getExpenseByIdFromCache(id);
    }
  }

  /// Obtiene un gasto desde cache (ISAR → SecureStorage)
  Future<Either<Failure, Expense>> _getExpenseByIdFromCache(String id) async {
    try {
      // Intentar ISAR primero
      final isar = IsarDatabase.instance.database;
      final isarExpense = await isar.isarExpenses
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarExpense != null) {
        return Right(isarExpense.toEntity());
      }

      // Fallback a SecureStorage
      final cachedExpense = await localDataSource.getCachedExpenseById(id);
      if (cachedExpense != null) {
        return Right(cachedExpense.toEntity());
      }

      return const Left(CacheFailure('Gasto no encontrado en cache'));
    } catch (e) {
      return Left(CacheFailure('Error al obtener gasto del cache: $e'));
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
    ExpensePaidFrom? paidFrom,
    String? bankAccountId,
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
          paidFrom: paidFrom,
          bankAccountId: bankAccountId,
        );

        final expenseModel = await remoteDataSource.createExpense(request);
        await localDataSource.cacheExpense(expenseModel);
        return Right(expenseModel.toEntity());
      } on ServerException catch (e) {
        AppLogger.w(' ExpenseRepository: ServerException en createExpense, cambiando a modo offline');
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
          paidFrom: paidFrom,
          bankAccountId: bankAccountId,
        );
      } on ConnectionException catch (e) {
        AppLogger.w(' ExpenseRepository: ConnectionException en createExpense, cambiando a modo offline');
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
          paidFrom: paidFrom,
          bankAccountId: bankAccountId,
        );
      } catch (e) {
        AppLogger.w(' ExpenseRepository: Error genérico en createExpense: $e - Fallback offline...');
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
          paidFrom: paidFrom,
          bankAccountId: bankAccountId,
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
        paidFrom: paidFrom,
        bankAccountId: bankAccountId,
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
        AppLogger.w(' [EXPENSE_REPO] ServerException en update: ${e.message} - Fallback offline...');
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
        AppLogger.w(' [EXPENSE_REPO] Exception en update: $e - Fallback offline...');
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
      AppLogger.d(' [EXPENSE_REPO] OFFLINE - Actualizando gasto offline...');
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
    AppLogger.d(' ExpenseRepository: Actualizando gasto offline: $id');
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
      AppLogger.i(' ExpenseRepository: Gasto actualizado en ISAR');

      // ✅ PASO 2: Actualizar SecureStorage
      try {
        final cachedExpense = await localDataSource.getCachedExpenseById(id);
        if (cachedExpense != null) {
          await localDataSource.cacheExpense(cachedExpense);
          AppLogger.i(' ExpenseRepository: Gasto actualizado en SecureStorage');
        }
      } catch (e) {
        AppLogger.w(' Error actualizando SecureStorage (no crítico): $e');
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
        AppLogger.d(' ExpenseRepository: UPDATE agregado a cola de sincronización');
      } catch (e) {
        AppLogger.w(' ExpenseRepository: Error agregando UPDATE a cola: $e');
      }

      AppLogger.i(' ExpenseRepository: Gasto actualizado offline exitosamente');
      return Right(isarExpense.toEntity());
    } catch (e) {
      AppLogger.e(' Error actualizando gasto offline: $e');
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
            AppLogger.i(' Expense marcado como eliminado en ISAR: $id');
          }
        } catch (e) {
          AppLogger.w(' Error actualizando ISAR (no crítico): $e');
        }

        await localDataSource.removeCachedExpense(id);
        return const Right(null);
      } on ServerException catch (e) {
        AppLogger.w('ServerException en deleteExpense, fallback offline: ${e.message}');
        return _deleteExpenseOffline(id);
      } catch (e) {
        AppLogger.w('Exception en deleteExpense, fallback offline: $e');
        return _deleteExpenseOffline(id);
      }
    } else {
      return _deleteExpenseOffline(id);
    }
  }

  /// Elimina un gasto en modo offline
  /// Soft delete en ISAR + agrega a cola de sincronización
  Future<Either<Failure, void>> _deleteExpenseOffline(String id) async {
    AppLogger.d(' ExpenseRepository: Deleting expense offline: $id');
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
        AppLogger.i(' Expense marcado como eliminado en ISAR (offline): $id');
      }

      try {
        await localDataSource.removeCachedExpense(id);
      } catch (e) {
        AppLogger.w(' Error al actualizar cache (no crítico): $e');
      }

      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Expense',
          entityId: id,
          operationType: SyncOperationType.delete,
          data: {'id': id},
          priority: 1,
        );
        AppLogger.d(' ExpenseRepository: Eliminación agregada a cola de sincronización');
      } catch (e) {
        AppLogger.w(' ExpenseRepository: Error agregando eliminación a cola: $e');
      }

      AppLogger.i(' ExpenseRepository: Expense deleted offline successfully');
      return const Right(null);
    } catch (e) {
      AppLogger.e(' ExpenseRepository: Error deleting expense offline: $e');
      return Left(CacheFailure('Error al eliminar gasto offline: $e'));
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
        AppLogger.w('ServerException en submitExpense, fallback offline: ${e.message}');
        return _updateExpenseStatusOffline(id, IsarExpenseStatus.pending, 'expense_submit');
      } catch (e) {
        AppLogger.w('Exception en submitExpense, fallback offline: $e');
        return _updateExpenseStatusOffline(id, IsarExpenseStatus.pending, 'expense_submit');
      }
    } else {
      return _updateExpenseStatusOffline(id, IsarExpenseStatus.pending, 'expense_submit');
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
        AppLogger.w('ServerException en approveExpense, fallback offline: ${e.message}');
        return _updateExpenseStatusOffline(
          id, IsarExpenseStatus.approved, 'expense_approve',
          additionalData: notes != null ? {'notes': notes} : null,
        );
      } catch (e) {
        AppLogger.w('Exception en approveExpense, fallback offline: $e');
        return _updateExpenseStatusOffline(
          id, IsarExpenseStatus.approved, 'expense_approve',
          additionalData: notes != null ? {'notes': notes} : null,
        );
      }
    } else {
      return _updateExpenseStatusOffline(
        id, IsarExpenseStatus.approved, 'expense_approve',
        additionalData: notes != null ? {'notes': notes} : null,
      );
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
        AppLogger.w('ServerException en rejectExpense, fallback offline: ${e.message}');
        return _updateExpenseStatusOffline(
          id, IsarExpenseStatus.rejected, 'expense_reject',
          additionalData: {'reason': reason},
        );
      } catch (e) {
        AppLogger.w('Exception en rejectExpense, fallback offline: $e');
        return _updateExpenseStatusOffline(
          id, IsarExpenseStatus.rejected, 'expense_reject',
          additionalData: {'reason': reason},
        );
      }
    } else {
      return _updateExpenseStatusOffline(
        id, IsarExpenseStatus.rejected, 'expense_reject',
        additionalData: {'reason': reason},
      );
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
        AppLogger.w('ServerException en markAsPaid, fallback offline: ${e.message}');
        return _updateExpenseStatusOffline(id, IsarExpenseStatus.paid, 'expense_paid');
      } catch (e) {
        AppLogger.w('Exception en markAsPaid, fallback offline: $e');
        return _updateExpenseStatusOffline(id, IsarExpenseStatus.paid, 'expense_paid');
      }
    } else {
      return _updateExpenseStatusOffline(id, IsarExpenseStatus.paid, 'expense_paid');
    }
  }

  /// Helper para actualizar estado de expense offline
  Future<Either<Failure, Expense>> _updateExpenseStatusOffline(
    String id,
    IsarExpenseStatus newStatus,
    String syncEntityType, {
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final isar = IsarDatabase.instance.database;
      final expense = await isar.isarExpenses
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (expense == null) {
        return const Left(CacheFailure('Gasto no encontrado en cache local'));
      }

      // Actualizar estado
      expense.status = newStatus;
      expense.updatedAt = DateTime.now();
      expense.isSynced = false;

      // Campos específicos según el estado
      if (newStatus == IsarExpenseStatus.approved) {
        expense.approvedAt = DateTime.now();
      } else if (newStatus == IsarExpenseStatus.rejected && additionalData?['reason'] != null) {
        expense.rejectionReason = additionalData!['reason'] as String;
      }

      await isar.writeTxn(() async {
        await isar.isarExpenses.put(expense);
      });

      // Agregar a cola de sincronización
      // NOTA: Usamos 'Expense' como entityType (soportado) con 'action' en data
      // para indicar la operación específica de estado
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Expense',
          entityId: id,
          operationType: SyncOperationType.update,
          data: {
            'action': syncEntityType,
            'status': newStatus.name,
            ...?additionalData,
          },
          priority: 1,
        );
      } catch (e) {
        AppLogger.w(' Could not add expense status to sync queue: $e');
      }

      return Right(expense.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error actualizando estado offline: $e'));
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
        AppLogger.w('ServerException en searchExpenses, fallback cache: ${e.message}');
        return _searchExpensesFromCache(query);
      } catch (e) {
        AppLogger.w('Exception en searchExpenses, fallback cache: $e');
        return _searchExpensesFromCache(query);
      }
    } else {
      return _searchExpensesFromCache(query);
    }
  }

  /// Busca gastos en cache (ISAR → SecureStorage)
  Future<Either<Failure, List<Expense>>> _searchExpensesFromCache(String query) async {
    try {
      final queryLower = query.toLowerCase();

      // Intentar ISAR primero
      final isar = IsarDatabase.instance.database;
      final isarExpenses = await isar.isarExpenses
          .filter()
          .deletedAtIsNull()
          .findAll();

      if (isarExpenses.isNotEmpty) {
        final filtered = isarExpenses
            .where((e) =>
                e.description.toLowerCase().contains(queryLower) ||
                (e.vendor?.toLowerCase().contains(queryLower) ?? false) ||
                (e.notes?.toLowerCase().contains(queryLower) ?? false) ||
                (e.reference?.toLowerCase().contains(queryLower) ?? false))
            .map((e) => e.toEntity())
            .toList();
        return Right(filtered);
      }

      // Fallback a SecureStorage
      final cachedExpenses = await localDataSource.getCachedExpenses();
      final filteredExpenses = cachedExpenses
          .where((expense) =>
              expense.description.toLowerCase().contains(queryLower) ||
              (expense.vendor?.toLowerCase().contains(queryLower) ?? false))
          .map((e) => e.toEntity())
          .toList();
      return Right(filteredExpenses);
    } catch (e) {
      return Left(CacheFailure('Error al buscar en cache: $e'));
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
        AppLogger.w('ServerException en getExpenseStats, fallback offline: ${e.message}');
        return _calculateStatsFromIsar(startDate, endDate);
      } catch (e) {
        AppLogger.w('Exception en getExpenseStats, fallback offline: $e');
        return _calculateStatsFromIsar(startDate, endDate);
      }
    } else {
      return _calculateStatsFromIsar(startDate, endDate);
    }
  }

  /// Calcula estadísticas de gastos desde ISAR cuando está offline
  Future<Either<Failure, ExpenseStats>> _calculateStatsFromIsar(
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      final isar = IsarDatabase.instance.database;
      var query = isar.isarExpenses.filter().deletedAtIsNull();

      final allExpenses = await query.findAll();

      // Filtrar por rango de fechas si se proporcionan
      final filtered = allExpenses.where((e) {
        if (startDate != null && e.date.isBefore(startDate)) return false;
        if (endDate != null && e.date.isAfter(endDate)) return false;
        return true;
      }).toList();

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfDay = DateTime(now.year, now.month, now.day);

      double totalAmount = 0;
      double monthlyAmount = 0;
      double weeklyAmount = 0;
      double dailyAmount = 0;
      int pendingExpenses = 0;
      double pendingAmount = 0;
      int approvedExpenses = 0;
      double approvedAmount = 0;
      int paidExpenses = 0;
      double paidAmount = 0;
      int rejectedExpenses = 0;
      double rejectedAmount = 0;
      final expensesByCategory = <String, double>{};
      final expensesByType = <String, double>{};
      final expensesByStatus = <String, int>{};
      int monthlyCount = 0;

      for (final e in filtered) {
        totalAmount += e.amount;

        if (!e.date.isBefore(startOfMonth)) {
          monthlyAmount += e.amount;
          monthlyCount++;
        }
        if (!e.date.isBefore(startOfWeek)) weeklyAmount += e.amount;
        if (!e.date.isBefore(startOfDay)) dailyAmount += e.amount;

        final statusName = e.status.name;
        expensesByStatus[statusName] = (expensesByStatus[statusName] ?? 0) + 1;

        switch (e.status) {
          case IsarExpenseStatus.pending:
            pendingExpenses++;
            pendingAmount += e.amount;
            break;
          case IsarExpenseStatus.approved:
            approvedExpenses++;
            approvedAmount += e.amount;
            break;
          case IsarExpenseStatus.paid:
            paidExpenses++;
            paidAmount += e.amount;
            break;
          case IsarExpenseStatus.rejected:
            rejectedExpenses++;
            rejectedAmount += e.amount;
            break;
          default:
            break;
        }

        expensesByCategory[e.categoryId] =
            (expensesByCategory[e.categoryId] ?? 0) + e.amount;
        expensesByType[e.type.name] =
            (expensesByType[e.type.name] ?? 0) + e.amount;
      }

      return Right(ExpenseStats(
        totalExpenses: filtered.length,
        totalAmount: totalAmount,
        monthlyAmount: monthlyAmount,
        weeklyAmount: weeklyAmount,
        dailyAmount: dailyAmount,
        pendingExpenses: pendingExpenses,
        pendingAmount: pendingAmount,
        approvedExpenses: approvedExpenses,
        approvedAmount: approvedAmount,
        paidExpenses: paidExpenses,
        paidAmount: paidAmount,
        rejectedExpenses: rejectedExpenses,
        rejectedAmount: rejectedAmount,
        averageExpenseAmount: filtered.isNotEmpty
            ? totalAmount / filtered.length
            : 0,
        expensesByCategory: expensesByCategory,
        expensesByType: expensesByType,
        expensesByStatus: expensesByStatus,
        monthlyTrends: [],
        monthlyCount: monthlyCount,
      ));
    } catch (e) {
      return Left(CacheFailure('Error calculando estadísticas offline: $e'));
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

        // Cache categories
        for (final cat in categoriesResponse.data) {
          await localDataSource.cacheExpenseCategory(cat);
        }

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
        AppLogger.w('ServerException en getExpenseCategories, fallback cache: ${e.message}');
        return _getExpenseCategoriesFromCache(page, limit);
      } catch (e) {
        AppLogger.w('Exception en getExpenseCategories, fallback cache: $e');
        return _getExpenseCategoriesFromCache(page, limit);
      }
    } else {
      return _getExpenseCategoriesFromCache(page, limit);
    }
  }

  /// Obtiene categorías de gastos desde cache
  Future<Either<Failure, PaginatedResponse<ExpenseCategory>>> _getExpenseCategoriesFromCache(
    int page,
    int limit,
  ) async {
    try {
      final cachedCategories = await localDataSource.getCachedExpenseCategories();
      final domainCategories = cachedCategories.map((e) => e.toEntity()).toList();

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
            totalPages: domainCategories.isEmpty ? 0 : (domainCategories.length / limit).ceil(),
            hasNext: endIndex < domainCategories.length,
            hasPrev: page > 1,
          ),
        ),
      );
    } catch (e) {
      return Left(CacheFailure('Error al obtener categorías del cache: $e'));
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
        AppLogger.w('ServerException en getExpenseCategoriesWithStats, fallback cache: ${e.message}');
        return _getExpenseCategoriesFromCache(page, limit);
      } catch (e) {
        AppLogger.w('Exception en getExpenseCategoriesWithStats, fallback cache: $e');
        return _getExpenseCategoriesFromCache(page, limit);
      }
    } else {
      return _getExpenseCategoriesFromCache(page, limit);
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
        AppLogger.w('ServerException en getExpenseCategoryById, fallback cache: ${e.message}');
        return _getExpenseCategoryByIdFromCache(id);
      } catch (e) {
        AppLogger.w('Exception en getExpenseCategoryById, fallback cache: $e');
        return _getExpenseCategoryByIdFromCache(id);
      }
    } else {
      return _getExpenseCategoryByIdFromCache(id);
    }
  }

  /// Obtiene una categoría desde cache
  Future<Either<Failure, ExpenseCategory>> _getExpenseCategoryByIdFromCache(String id) async {
    try {
      final cachedCategory = await localDataSource.getCachedExpenseCategoryById(id);
      if (cachedCategory != null) {
        return Right(cachedCategory.toEntity());
      }
      return const Left(CacheFailure('Categoría no encontrada en cache'));
    } catch (e) {
      return Left(CacheFailure('Error al obtener categoría del cache: $e'));
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
        AppLogger.w(' [EXPENSE_REPO] ServerException en createExpenseCategory, fallback offline');
        return _createExpenseCategoryOffline(
          name: name,
          description: description,
          color: color,
          monthlyBudget: monthlyBudget,
          sortOrder: sortOrder,
        );
      } on ConnectionException catch (e) {
        AppLogger.w(' [EXPENSE_REPO] ConnectionException en createExpenseCategory, fallback offline');
        return _createExpenseCategoryOffline(
          name: name,
          description: description,
          color: color,
          monthlyBudget: monthlyBudget,
          sortOrder: sortOrder,
        );
      } catch (e) {
        AppLogger.w(' [EXPENSE_REPO] Error en createExpenseCategory: $e - Fallback offline');
        return _createExpenseCategoryOffline(
          name: name,
          description: description,
          color: color,
          monthlyBudget: monthlyBudget,
          sortOrder: sortOrder,
        );
      }
    } else {
      return _createExpenseCategoryOffline(
        name: name,
        description: description,
        color: color,
        monthlyBudget: monthlyBudget,
        sortOrder: sortOrder,
      );
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
        AppLogger.w(' [EXPENSE_REPO] ServerException en updateExpenseCategory, fallback offline');
        return _updateExpenseCategoryOffline(
          id: id, name: name, description: description, color: color,
          monthlyBudget: monthlyBudget, sortOrder: sortOrder, status: status,
        );
      } catch (e) {
        AppLogger.w(' [EXPENSE_REPO] Error en updateExpenseCategory: $e - Fallback offline');
        return _updateExpenseCategoryOffline(
          id: id, name: name, description: description, color: color,
          monthlyBudget: monthlyBudget, sortOrder: sortOrder, status: status,
        );
      }
    } else {
      return _updateExpenseCategoryOffline(
        id: id, name: name, description: description, color: color,
        monthlyBudget: monthlyBudget, sortOrder: sortOrder, status: status,
      );
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
        AppLogger.w(' [EXPENSE_REPO] ServerException en deleteExpenseCategory, fallback offline');
        return _deleteExpenseCategoryOffline(id);
      } catch (e) {
        AppLogger.w(' [EXPENSE_REPO] Error en deleteExpenseCategory: $e - Fallback offline');
        return _deleteExpenseCategoryOffline(id);
      }
    } else {
      return _deleteExpenseCategoryOffline(id);
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
        AppLogger.w('ServerException en searchExpenseCategories, fallback cache: ${e.message}');
        return _searchExpenseCategoriesFromCache(query);
      } catch (e) {
        AppLogger.w('Exception en searchExpenseCategories, fallback cache: $e');
        return _searchExpenseCategoriesFromCache(query);
      }
    } else {
      return _searchExpenseCategoriesFromCache(query);
    }
  }

  /// Busca categorías de gastos en cache
  Future<Either<Failure, List<ExpenseCategory>>> _searchExpenseCategoriesFromCache(
    String query,
  ) async {
    try {
      final cachedCategories = await localDataSource.getCachedExpenseCategories();
      final queryLower = query.toLowerCase();
      final filteredCategories = cachedCategories
          .where((category) =>
              category.name.toLowerCase().contains(queryLower) ||
              (category.description?.toLowerCase().contains(queryLower) ?? false))
          .map((e) => e.toEntity())
          .toList();
      return Right(filteredCategories);
    } catch (e) {
      return Left(CacheFailure('Error al buscar categorías en cache: $e'));
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
    ExpensePaidFrom? paidFrom,
    String? bankAccountId,
  }) async {
    AppLogger.d(' ExpenseRepository: Creando gasto offline: $description');
    try {
      // Generar un ID temporal único para el gasto offline
      final now = DateTime.now();
      final tempId = 'expense_offline_${now.millisecondsSinceEpoch}_${description.hashCode}';

      // Obtener el usuario actual (si está disponible)
      String createdById = 'offline_user';
      try {
        final authController = Get.find<AuthController>();
        if (authController.currentUser != null) {
          createdById = authController.currentUser!.id;
        }
      } catch (e) {
        AppLogger.w(' ExpenseRepository: No se pudo obtener usuario actual: $e');
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
        paidFromValue: paidFrom?.value,
        bankAccountId: bankAccountId,
      );

      // Guardar en ISAR
      final isar = IsarDatabase.instance.database;
      await isar.writeTxn(() async {
        await isar.isarExpenses.put(isarExpense);
      });
      AppLogger.i(' ExpenseRepository: Gasto guardado en ISAR con ID temporal: $tempId');

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
        paidFrom: paidFrom,
        bankAccountId: bankAccountId,
      );

      // Guardar en SecureStorage
      await localDataSource.cacheExpense(expenseModel);
      AppLogger.i(' ExpenseRepository: Gasto guardado en SecureStorage');

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
            // YYYY-MM-DD en TZ del tenant (el TZDateTime ya viene en esa TZ).
            // Si enviáramos ISO8601, al hacer DateTime.parse() de vuelta en el
            // sync, perdemos la TZ original y el día puede correrse al siguiente.
            'date': _ymd(date),
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
            if (paidFrom != null) 'paidFrom': paidFrom.value,
            if (bankAccountId != null) 'bankAccountId': bankAccountId,
          },
          priority: 1, // Alta prioridad para creación
        );
        AppLogger.d(' ExpenseRepository: Operación agregada a cola de sincronización');
      } catch (e) {
        AppLogger.w(' ExpenseRepository: Error agregando a cola de sync: $e');
      }

      AppLogger.i(' ExpenseRepository: Gasto creado offline exitosamente');
      return Right(expense);
    } catch (e) {
      AppLogger.e(' ExpenseRepository: Error creando gasto offline: $e');
      return Left(CacheFailure('Error al crear gasto offline: $e'));
    }
  }

  // ==================== EXPENSE CATEGORY OFFLINE METHODS ====================

  /// Crea una categoría de gasto en modo offline
  Future<Either<Failure, ExpenseCategory>> _createExpenseCategoryOffline({
    required String name,
    String? description,
    String? color,
    double? monthlyBudget,
    int? sortOrder,
  }) async {
    AppLogger.d(' [EXPENSE_REPO] Creando categoría de gasto offline: $name');
    try {
      final now = DateTime.now();
      final tempId = 'expense_category_offline_${now.millisecondsSinceEpoch}_${name.hashCode}';

      // Crear modelo para cache
      final categoryModel = ExpenseCategoryModel(
        id: tempId,
        name: name,
        description: description,
        color: color,
        status: ExpenseCategoryStatus.active,
        monthlyBudget: monthlyBudget ?? 0.0,
        isRequired: false,
        sortOrder: sortOrder ?? 0,
        createdAt: now,
        updatedAt: now,
      );

      // Guardar en SecureStorage
      await localDataSource.cacheExpenseCategory(categoryModel);
      AppLogger.i(' [EXPENSE_REPO] Categoría guardada en cache: $tempId');

      // Agregar a cola de sincronización
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'ExpenseCategory',
          entityId: tempId,
          operationType: SyncOperationType.create,
          data: {
            'name': name,
            'description': description,
            'color': color,
            'monthlyBudget': monthlyBudget ?? 0.0,
            'sortOrder': sortOrder ?? 0,
          },
          priority: 2,
        );
        AppLogger.d(' [EXPENSE_REPO] CREATE de categoría agregado a cola de sync');
      } catch (e) {
        AppLogger.w(' [EXPENSE_REPO] Error agregando categoría a cola de sync: $e');
      }

      return Right(categoryModel.toEntity());
    } catch (e) {
      AppLogger.e(' [EXPENSE_REPO] Error creando categoría offline: $e');
      return Left(CacheFailure('Error al crear categoría offline: $e'));
    }
  }

  /// Actualiza una categoría de gasto en modo offline
  Future<Either<Failure, ExpenseCategory>> _updateExpenseCategoryOffline({
    required String id,
    String? name,
    String? description,
    String? color,
    double? monthlyBudget,
    int? sortOrder,
    ExpenseCategoryStatus? status,
  }) async {
    AppLogger.d(' [EXPENSE_REPO] Actualizando categoría offline: $id');
    try {
      // Leer categoría actual del cache
      final existing = await localDataSource.getCachedExpenseCategoryById(id);
      if (existing == null) {
        return Left(CacheFailure('Categoría no encontrada en cache: $id'));
      }

      // Crear modelo actualizado
      final updatedModel = ExpenseCategoryModel(
        id: id,
        name: name ?? existing.name,
        description: description ?? existing.description,
        color: color ?? existing.color,
        status: status ?? existing.status,
        monthlyBudget: monthlyBudget ?? existing.monthlyBudget,
        isRequired: existing.isRequired,
        sortOrder: sortOrder ?? existing.sortOrder,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
      );

      // Actualizar en cache
      await localDataSource.cacheExpenseCategory(updatedModel);

      // Agregar a cola de sincronización
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'ExpenseCategory',
          entityId: id,
          operationType: SyncOperationType.update,
          data: {
            'name': name ?? existing.name,
            'description': description ?? existing.description,
            'color': color ?? existing.color,
            'monthlyBudget': monthlyBudget ?? existing.monthlyBudget,
            'sortOrder': sortOrder ?? existing.sortOrder,
          },
          priority: 2,
        );
        AppLogger.d(' [EXPENSE_REPO] UPDATE de categoría agregado a cola de sync');
      } catch (e) {
        AppLogger.w(' [EXPENSE_REPO] Error agregando UPDATE de categoría a cola: $e');
      }

      return Right(updatedModel.toEntity());
    } catch (e) {
      AppLogger.e(' [EXPENSE_REPO] Error actualizando categoría offline: $e');
      return Left(CacheFailure('Error al actualizar categoría offline: $e'));
    }
  }

  /// Elimina una categoría de gasto en modo offline
  Future<Either<Failure, void>> _deleteExpenseCategoryOffline(String id) async {
    AppLogger.d(' [EXPENSE_REPO] Eliminando categoría offline: $id');
    try {
      // Eliminar del cache
      await localDataSource.removeCachedExpenseCategory(id);

      // Si es una categoría offline que aún no se sincronizó, no necesita sync de delete
      if (id.startsWith('expense_category_offline_')) {
        // Eliminar operaciones pendientes de esta categoría
        try {
          final isarDb = IsarDatabase.instance;
          final pendingOps = await isarDb.getPendingSyncOperations();
          for (final op in pendingOps) {
            if (op.entityId == id) {
              await isarDb.deleteSyncOperation(op.id);
            }
          }
          AppLogger.d(' [EXPENSE_REPO] Operaciones pendientes de categoría offline eliminadas');
        } catch (e) {
          AppLogger.w(' [EXPENSE_REPO] Error limpiando ops pendientes: $e');
        }
        return const Right(null);
      }

      // Si es una categoría real del servidor, agregar DELETE a cola
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'ExpenseCategory',
          entityId: id,
          operationType: SyncOperationType.delete,
          data: {'id': id},
          priority: 2,
        );
        AppLogger.d(' [EXPENSE_REPO] DELETE de categoría agregado a cola de sync');
      } catch (e) {
        AppLogger.w(' [EXPENSE_REPO] Error agregando DELETE de categoría a cola: $e');
      }

      return const Right(null);
    } catch (e) {
      AppLogger.e(' [EXPENSE_REPO] Error eliminando categoría offline: $e');
      return Left(CacheFailure('Error al eliminar categoría offline: $e'));
    }
  }

  // ==================== SYNC OPERATIONS ====================

  /// Sincronizar gastos creados offline con el servidor
  Future<Either<Failure, List<Expense>>> syncOfflineExpenses() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No hay conexión a internet'));
    }

    try {
      AppLogger.d(' ExpenseRepository: Starting offline expenses sync...');

      // Obtener gastos no sincronizados desde ISAR
      final isar = IsarDatabase.instance.database;
      final unsyncedExpenses = await isar.isarExpenses
          .filter()
          .isSyncedEqualTo(false)
          .and()
          .deletedAtIsNull()
          .findAll();

      if (unsyncedExpenses.isEmpty) {
        AppLogger.i(' ExpenseRepository: No expenses to sync');
        return const Right([]);
      }

      AppLogger.d(' ExpenseRepository: Syncing ${unsyncedExpenses.length} offline expenses...');
      final syncedExpenses = <Expense>[];

      for (final isarExpense in unsyncedExpenses) {
        try {
          // Determinar si es CREATE o UPDATE basándose en el serverId
          final isCreate = isarExpense.serverId.startsWith('expense_offline_');

          if (isCreate) {
            // CREATE: Enviar al servidor y actualizar con ID real
            AppLogger.d(' Creating expense: ${isarExpense.description}');

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
            AppLogger.i(' Expense created and synced: ${isarExpense.description} -> ${created.id}');
          } else {
            // UPDATE: Enviar actualización al servidor
            AppLogger.d(' Updating expense: ${isarExpense.description}');

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
            AppLogger.i(' Expense updated and synced: ${isarExpense.description}');
          }
        } catch (e) {
          AppLogger.e(' Error sincronizando gasto ${isarExpense.description}: $e');
          // Continuar con la siguiente
        }
      }

      AppLogger.i(' ExpenseRepository: Sync completed. Success: ${syncedExpenses.length}');
      return Right(syncedExpenses);
    } catch (e) {
      AppLogger.e(' ExpenseRepository: Error during offline expenses sync: $e');
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

  // String-based mappers for cache filtering
  IsarExpenseStatus? _mapExpenseStatusString(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return IsarExpenseStatus.draft;
      case 'pending':
        return IsarExpenseStatus.pending;
      case 'approved':
        return IsarExpenseStatus.approved;
      case 'rejected':
        return IsarExpenseStatus.rejected;
      case 'paid':
        return IsarExpenseStatus.paid;
      default:
        return null;
    }
  }

  IsarExpenseType? _mapExpenseTypeString(String type) {
    switch (type.toLowerCase()) {
      case 'operating':
        return IsarExpenseType.operating;
      case 'administrative':
        return IsarExpenseType.administrative;
      case 'sales':
        return IsarExpenseType.sales;
      case 'financial':
        return IsarExpenseType.financial;
      case 'extraordinary':
        return IsarExpenseType.extraordinary;
      default:
        return null;
    }
  }

  /// Obtiene gastos desde cache (ISAR primero, luego SecureStorage como fallback)
  /// Aplica filtros de status, type, categoría, fechas y búsqueda
  Future<Either<Failure, PaginatedResponse<Expense>>> _getExpensesFromCache(
    int page,
    int limit, {
    String? status,
    String? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
  }) async {
    try {
      AppLogger.d(' [EXPENSE_REPO] Intentando cargar gastos desde cache con filtros...');
      AppLogger.d(' [EXPENSE_REPO] Filtros: status=$status, type=$type, category=$categoryId, startDate=$startDate, endDate=$endDate, search=$search');

      // PASO 1: Intentar desde ISAR primero con filtros aplicados
      final isar = IsarDatabase.instance.database;
      var query = isar.isarExpenses.filter().deletedAtIsNull();

      // Aplicar filtros ISAR nativos
      if (status != null) {
        final isarStatus = _mapExpenseStatusString(status);
        if (isarStatus != null) {
          query = query.and().statusEqualTo(isarStatus);
        }
      }
      if (type != null) {
        final isarType = _mapExpenseTypeString(type);
        if (isarType != null) {
          query = query.and().typeEqualTo(isarType);
        }
      }
      if (categoryId != null) {
        query = query.and().categoryIdEqualTo(categoryId);
      }
      if (startDate != null) {
        query = query.and().dateGreaterThan(startDate);
      }
      if (endDate != null) {
        query = query.and().dateLessThan(endDate);
      }

      final isarExpenses = await query.sortByDateDesc().findAll();

      List<Expense> expenses;

      if (isarExpenses.isNotEmpty) {
        AppLogger.d(' [EXPENSE_REPO] ISAR tiene ${isarExpenses.length} gastos (filtrados)');
        expenses = isarExpenses.map((ie) => ie.toEntity()).toList();
      } else {
        // PASO 2: Si ISAR está vacío, intentar desde SecureStorage
        AppLogger.d(' [EXPENSE_REPO] ISAR vacío (filtrado), intentando SecureStorage...');
        final cachedExpenses = await localDataSource.getCachedExpenses();

        if (cachedExpenses.isEmpty) {
          AppLogger.w(' [EXPENSE_REPO] SecureStorage también vacío');
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

        AppLogger.d(' [EXPENSE_REPO] SecureStorage tiene ${cachedExpenses.length} gastos');
        expenses = cachedExpenses.map((e) => e.toEntity()).toList();

        // Aplicar filtros en Dart para datos de SecureStorage
        if (status != null) {
          expenses = expenses.where((e) => e.status.name == status).toList();
        }
        if (type != null) {
          expenses = expenses.where((e) => e.type.name == type).toList();
        }
        if (categoryId != null) {
          expenses = expenses.where((e) => e.categoryId == categoryId).toList();
        }
        if (startDate != null) {
          expenses = expenses.where((e) => e.date.isAfter(startDate)).toList();
        }
        if (endDate != null) {
          expenses = expenses.where((e) => e.date.isBefore(endDate)).toList();
        }
      }

      // PASO 2.5: Filtro de búsqueda en Dart (no soportado por ISAR directamente)
      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        expenses = expenses.where((e) =>
          e.description.toLowerCase().contains(searchLower) ||
          (e.vendor?.toLowerCase().contains(searchLower) ?? false)
        ).toList();
      }

      // PASO 3: Aplicar paginación
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
        totalPages: expenses.isEmpty ? 0 : (expenses.length / limit).ceil(),
        hasNext: endIndex < expenses.length,
        hasPrev: page > 1,
      );

      AppLogger.i(' [EXPENSE_REPO] Gastos cargados desde cache (filtrados): ${paginatedData.length} de ${expenses.length} total');
      return Right(PaginatedResponse<Expense>(data: paginatedData, meta: meta));
    } catch (e) {
      AppLogger.e(' [EXPENSE_REPO] Error cargando desde cache: $e');
      return Left(CacheFailure('Error al obtener gastos del cache: $e'));
    }
  }
}