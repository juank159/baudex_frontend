// lib/features/bank_accounts/data/repositories/bank_account_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../../../app/data/local/enums/isar_enums.dart';
import '../models/isar/isar_bank_account.dart';
import '../../domain/entities/bank_account.dart';
import '../../domain/entities/bank_account_transaction.dart';
import '../../domain/repositories/bank_account_repository.dart';
import '../datasources/bank_account_remote_datasource.dart';
import '../models/bank_account_model.dart';
import '../models/bank_account_transaction_model.dart';

/// Implementación del repositorio de cuentas bancarias
class BankAccountRepositoryImpl implements BankAccountRepository {
  final BankAccountRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  BankAccountRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<BankAccount>>> getBankAccounts({
    BankAccountType? type,
    bool? isActive,
    bool includeInactive = false,
  }) async {
    if (await networkInfo.isConnected) {
      // ============ MODO ONLINE: Obtener del servidor y actualizar ISAR ============
      try {
        final accounts = await remoteDataSource.getBankAccounts(
          type: type?.value,
          isActive: isActive,
          includeInactive: includeInactive,
        );

        // ✅ Actualizar ISAR con los datos del servidor
        try {
          final isar = IsarDatabase.instance.database;
          final isarAccounts = accounts
              .map((model) => IsarBankAccount.fromEntity(model.toEntity()))
              .toList();

          await isar.writeTxn(() async {
            await isar.isarBankAccounts.putAll(isarAccounts);
          });
          print('✅ BankAccounts actualizadas en ISAR (${isarAccounts.length})');
        } catch (e) {
          print('⚠️ Error actualizando ISAR (no crítico): $e');
        }

        return Right(accounts.map((m) => m.toEntity()).toList());
      } on ServerException catch (e) {
        print('⚠️ [BANK_REPO] ServerException: ${e.message} - Fallback a ISAR...');
        return _getBankAccountsFromIsar(type, isActive, includeInactive);
      } catch (e) {
        print('⚠️ [BANK_REPO] Exception: $e - Fallback a ISAR...');
        return _getBankAccountsFromIsar(type, isActive, includeInactive);
      }
    } else {
      // ============ MODO OFFLINE: Leer de ISAR ============
      return _getBankAccountsFromIsar(type, isActive, includeInactive);
    }
  }

  /// Helper: Obtener cuentas bancarias desde ISAR
  Future<Either<Failure, List<BankAccount>>> _getBankAccountsFromIsar(
    BankAccountType? type,
    bool? isActive,
    bool includeInactive,
  ) async {
    try {
      print('💾 BankAccounts: Leyendo desde ISAR (modo offline)');
      final isar = IsarDatabase.instance.database;

      var query = isar.isarBankAccounts.filter().deletedAtIsNull();

      if (type != null) {
        query = query.and().typeEqualTo(_mapBankAccountType(type));
      }

      if (isActive != null && !includeInactive) {
        query = query.and().isActiveEqualTo(isActive);
      }

      final isarAccounts = await query.sortBySortOrder().findAll();
      final accounts = isarAccounts.map((a) => a.toEntity()).toList();

      print('✅ ${accounts.length} cuentas encontradas en ISAR');
      return Right(accounts);
    } catch (e) {
      print('❌ Error leyendo desde ISAR: $e');
      return Left(CacheFailure('Error leyendo cuentas desde cache: $e'));
    }
  }

  @override
  Future<Either<Failure, List<BankAccount>>> getActiveBankAccounts() async {
    // Delegar a getBankAccounts con isActive=true
    return getBankAccounts(isActive: true, includeInactive: false);
  }

  @override
  Future<Either<Failure, BankAccount>> getBankAccountById(String id) async {
    if (await networkInfo.isConnected) {
      // ============ MODO ONLINE: Obtener del servidor y actualizar ISAR ============
      try {
        final account = await remoteDataSource.getBankAccountById(id);

        // ✅ Actualizar ISAR con los datos del servidor
        try {
          final isar = IsarDatabase.instance.database;
          final isarAccount = IsarBankAccount.fromEntity(account.toEntity());

          await isar.writeTxn(() async {
            await isar.isarBankAccounts.put(isarAccount);
          });
          print('✅ BankAccount actualizada en ISAR: $id');
        } catch (e) {
          print('⚠️ Error actualizando ISAR (no crítico): $e');
        }

        return Right(account.toEntity());
      } on ServerException catch (e) {
        // Fallback a ISAR si el servidor falla
        return _getBankAccountByIdFromIsar(id);
      } catch (e) {
        return Left(UnknownFailure('Error inesperado: $e'));
      }
    } else {
      // ============ MODO OFFLINE: Leer de ISAR ============
      return _getBankAccountByIdFromIsar(id);
    }
  }

  /// Helper: Obtener cuenta bancaria por ID desde ISAR
  Future<Either<Failure, BankAccount>> _getBankAccountByIdFromIsar(
    String id,
  ) async {
    try {
      print('💾 BankAccount: Leyendo desde ISAR (modo offline): $id');
      final isar = IsarDatabase.instance.database;

      final isarAccount = await isar.isarBankAccounts
          .filter()
          .serverIdEqualTo(id)
          .and()
          .deletedAtIsNull()
          .findFirst();

      if (isarAccount == null) {
        return Left(CacheFailure('Cuenta bancaria no encontrada: $id'));
      }

      return Right(isarAccount.toEntity());
    } catch (e) {
      print('❌ Error leyendo desde ISAR: $e');
      return Left(CacheFailure('Error leyendo cuenta desde cache: $e'));
    }
  }

  @override
  Future<Either<Failure, BankAccount?>> getDefaultBankAccount() async {
    if (await networkInfo.isConnected) {
      try {
        final account = await remoteDataSource.getDefaultBankAccount();

        // ✅ Actualizar ISAR con la cuenta por defecto
        if (account != null) {
          try {
            final isar = IsarDatabase.instance.database;
            final isarAccount = IsarBankAccount.fromEntity(account.toEntity());
            await isar.writeTxn(() async {
              await isar.isarBankAccounts.put(isarAccount);
            });
          } catch (e) {
            print('⚠️ Error actualizando ISAR (no crítico): $e');
          }
        }

        return Right(account?.toEntity());
      } on ServerException catch (e) {
        // Fallback: buscar en ISAR la cuenta por defecto
        return _getDefaultFromIsar();
      } catch (e) {
        return Left(UnknownFailure('Error inesperado: $e'));
      }
    } else {
      // Modo offline: buscar en ISAR
      return _getDefaultFromIsar();
    }
  }

  /// Helper: Obtener cuenta por defecto desde ISAR
  Future<Either<Failure, BankAccount?>> _getDefaultFromIsar() async {
    try {
      final isar = IsarDatabase.instance.database;
      final defaultAccount = await isar.isarBankAccounts
          .filter()
          .isDefaultEqualTo(true)
          .and()
          .deletedAtIsNull()
          .findFirst();

      return Right(defaultAccount?.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error buscando cuenta por defecto: $e'));
    }
  }

  @override
  Future<Either<Failure, BankAccount>> createBankAccount({
    required String name,
    required BankAccountType type,
    String? bankName,
    String? accountNumber,
    String? holderName,
    String? icon,
    bool isActive = true,
    bool isDefault = false,
    int sortOrder = 0,
    String? description,
  }) async {
    if (await networkInfo.isConnected) {
      // ============ MODO ONLINE: Crear en servidor y actualizar ISAR ============
      try {
        final request = CreateBankAccountRequest(
          name: name,
          type: type.value,
          bankName: bankName,
          accountNumber: accountNumber,
          holderName: holderName,
          icon: icon,
          isActive: isActive,
          isDefault: isDefault,
          sortOrder: sortOrder,
          description: description,
        );
        final account = await remoteDataSource.createBankAccount(request);

        // ✅ Guardar en ISAR después de crear en servidor
        try {
          final isar = IsarDatabase.instance.database;
          final isarAccount = IsarBankAccount.fromEntity(account.toEntity());
          await isar.writeTxn(() async {
            await isar.isarBankAccounts.put(isarAccount);
          });
          print('✅ BankAccount guardada en ISAR: ${account.id}');
        } catch (e) {
          print('⚠️ Error guardando en ISAR (no crítico): $e');
        }

        return Right(account.toEntity());
      } on ServerException catch (e) {
        print('⚠️ ServerException al crear cuenta bancaria: ${e.message} - Creando offline...');
        return _createBankAccountOffline(
          name: name,
          type: type,
          bankName: bankName,
          accountNumber: accountNumber,
          holderName: holderName,
          icon: icon,
          isActive: isActive,
          isDefault: isDefault,
          sortOrder: sortOrder,
          description: description,
        );
      } on ConnectionException catch (e) {
        print('⚠️ ConnectionException al crear cuenta bancaria: ${e.message} - Creando offline...');
        return _createBankAccountOffline(
          name: name,
          type: type,
          bankName: bankName,
          accountNumber: accountNumber,
          holderName: holderName,
          icon: icon,
          isActive: isActive,
          isDefault: isDefault,
          sortOrder: sortOrder,
          description: description,
        );
      } catch (e, stackTrace) {
        print('❌ Error inesperado al crear cuenta bancaria: $e');
        print('📚 StackTrace: $stackTrace');
        print('🔄 Intentando crear offline como fallback...');
        return _createBankAccountOffline(
          name: name,
          type: type,
          bankName: bankName,
          accountNumber: accountNumber,
          holderName: holderName,
          icon: icon,
          isActive: isActive,
          isDefault: isDefault,
          sortOrder: sortOrder,
          description: description,
        );
      }
    } else {
      // ============ MODO OFFLINE: Crear directamente offline ============
      return _createBankAccountOffline(
        name: name,
        type: type,
        bankName: bankName,
        accountNumber: accountNumber,
        holderName: holderName,
        icon: icon,
        isActive: isActive,
        isDefault: isDefault,
        sortOrder: sortOrder,
        description: description,
      );
    }
  }

  @override
  Future<Either<Failure, BankAccount>> updateBankAccount({
    required String id,
    String? name,
    BankAccountType? type,
    String? bankName,
    String? accountNumber,
    String? holderName,
    String? icon,
    bool? isActive,
    bool? isDefault,
    int? sortOrder,
    String? description,
  }) async {
    if (!await networkInfo.isConnected) {
      // ============ MODO OFFLINE: Actualizar ISAR + Queue ============
      return _updateBankAccountOffline(
        id: id,
        name: name,
        type: type,
        bankName: bankName,
        accountNumber: accountNumber,
        holderName: holderName,
        icon: icon,
        isActive: isActive,
        isDefault: isDefault,
        sortOrder: sortOrder,
        description: description,
      );
    }

    // ============ MODO ONLINE: Actualizar en servidor + ISAR ============
    try {
      final request = UpdateBankAccountRequest(
        name: name,
        type: type?.value,
        bankName: bankName,
        accountNumber: accountNumber,
        holderName: holderName,
        icon: icon,
        isActive: isActive,
        isDefault: isDefault,
        sortOrder: sortOrder,
        description: description,
      );
      final account = await remoteDataSource.updateBankAccount(id, request);

      // ✅ Actualizar en ISAR después de actualizar en servidor
      try {
        final isar = IsarDatabase.instance.database;
        final isarAccount = IsarBankAccount.fromEntity(account.toEntity());
        await isar.writeTxn(() async {
          await isar.isarBankAccounts.put(isarAccount);
        });
        print('✅ BankAccount actualizada en ISAR (modo online): $id');
      } catch (e) {
        print('⚠️ Error actualizando ISAR (no crítico): $e');
      }

      return Right(account.toEntity());
    } on ServerException catch (e) {
      print('⚠️ [BANK_REPO] ServerException al actualizar: ${e.message} - Fallback offline...');
      return _updateBankAccountOffline(
        id: id,
        name: name,
        type: type,
        bankName: bankName,
        accountNumber: accountNumber,
        holderName: holderName,
        icon: icon,
        isActive: isActive,
        isDefault: isDefault,
        sortOrder: sortOrder,
        description: description,
      );
    } catch (e) {
      print('⚠️ [BANK_REPO] Exception al actualizar: $e - Fallback offline...');
      return _updateBankAccountOffline(
        id: id,
        name: name,
        type: type,
        bankName: bankName,
        accountNumber: accountNumber,
        holderName: holderName,
        icon: icon,
        isActive: isActive,
        isDefault: isDefault,
        sortOrder: sortOrder,
        description: description,
      );
    }
  }

  Future<Either<Failure, BankAccount>> _updateBankAccountOffline({
    required String id,
    String? name,
    BankAccountType? type,
    String? bankName,
    String? accountNumber,
    String? holderName,
    String? icon,
    bool? isActive,
    bool? isDefault,
    int? sortOrder,
    String? description,
  }) async {
    print('💾 BankAccountRepository: Modo offline - actualizando en ISAR');
    try {
      final isar = IsarDatabase.instance.database;

      // ✅ PASO 1: Actualizar en ISAR
      final isarAccount = await isar.isarBankAccounts
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarAccount == null) {
        return Left(CacheFailure('Cuenta bancaria no encontrada en ISAR: $id'));
      }

      // Actualizar campos
      if (name != null) isarAccount.name = name;
      if (type != null) isarAccount.type = _mapBankAccountType(type);
      if (bankName != null) isarAccount.bankName = bankName;
      if (accountNumber != null) isarAccount.accountNumber = accountNumber;
      if (holderName != null) isarAccount.holderName = holderName;
      if (icon != null) isarAccount.icon = icon;
      if (isActive != null) isarAccount.isActive = isActive;
      if (isDefault != null) isarAccount.isDefault = isDefault;
      if (sortOrder != null) isarAccount.sortOrder = sortOrder;
      if (description != null) isarAccount.description = description;

      isarAccount.markAsUnsynced();

      await isar.writeTxn(() async {
        await isar.isarBankAccounts.put(isarAccount);
      });
      print('✅ BankAccountRepository: Cuenta actualizada en ISAR');

      // ✅ PASO 2: Agregar a la cola de sincronización
      final syncService = Get.find<SyncService>();
      await syncService.addOperationForCurrentUser(
        entityType: 'BankAccount',
        entityId: id,
        operationType: SyncOperationType.update,
        data: {
          if (name != null) 'name': name,
          if (type != null) 'type': type.value,
          if (bankName != null) 'bankName': bankName,
          if (accountNumber != null) 'accountNumber': accountNumber,
          if (holderName != null) 'holderName': holderName,
          if (icon != null) 'icon': icon,
          if (isActive != null) 'isActive': isActive,
          if (isDefault != null) 'isDefault': isDefault,
          if (sortOrder != null) 'sortOrder': sortOrder,
          if (description != null) 'description': description,
        },
      );
      print('✅ BankAccountRepository: Cuenta agregada a cola de sincronización');

      return Right(isarAccount.toEntity());
    } catch (e) {
      print('❌ Error actualizando cuenta bancaria offline: $e');
      return Left(CacheFailure('Error actualizando cuenta offline: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBankAccount(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteBankAccount(id);

        // Soft delete en ISAR después de eliminar en servidor
        try {
          final isar = IsarDatabase.instance.database;
          final isarAccount = await isar.isarBankAccounts
              .filter()
              .serverIdEqualTo(id)
              .findFirst();

          if (isarAccount != null) {
            isarAccount.softDelete();
            await isar.writeTxn(() async {
              await isar.isarBankAccounts.put(isarAccount);
            });
            print('✅ BankAccount marcada como eliminada en ISAR: $id');
          }
        } catch (e) {
          print('⚠️ Error actualizando ISAR (no crítico): $e');
        }

        return const Right(null);
      } on ServerException catch (e) {
        print('⚠️ [BANK_REPO] ServerException al eliminar: ${e.message} - Fallback offline...');
        return _deleteBankAccountOffline(id);
      } catch (e) {
        print('⚠️ [BANK_REPO] Exception al eliminar: $e - Fallback offline...');
        return _deleteBankAccountOffline(id);
      }
    } else {
      // Sin conexión, marcar para eliminación offline y sincronizar después
      return _deleteBankAccountOffline(id);
    }
  }

  Future<Either<Failure, void>> _deleteBankAccountOffline(String id) async {
    print('📱 BankAccountRepository: Deleting bank account offline: $id');
    try {
      // Soft delete en ISAR
      final isar = IsarDatabase.instance.database;
      final isarAccount = await isar.isarBankAccounts
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarAccount != null) {
        isarAccount.softDelete();
        await isar.writeTxn(() async {
          await isar.isarBankAccounts.put(isarAccount);
        });
        print('✅ BankAccount marcada como eliminada en ISAR (offline): $id');
      }

      // Agregar a la cola de sincronización
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'BankAccount',
          entityId: id,
          operationType: SyncOperationType.delete,
          data: {'id': id},
          priority: 1,
        );
        print('📤 BankAccountRepository: Eliminación agregada a cola de sincronización');
      } catch (e) {
        print('⚠️ BankAccountRepository: Error agregando eliminación a cola: $e');
      }

      print('✅ BankAccountRepository: Bank account deleted offline successfully');
      return const Right(null);
    } catch (e) {
      print('❌ BankAccountRepository: Error deleting bank account offline: $e');
      return Left(CacheFailure('Error al eliminar cuenta bancaria offline: $e'));
    }
  }

  @override
  Future<Either<Failure, BankAccount>> setDefaultBankAccount(String id) async {
    if (!await networkInfo.isConnected) {
      // TODO: Implementar cambio de cuenta por defecto offline
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final account = await remoteDataSource.setDefaultBankAccount(id);

      // ✅ Actualizar en ISAR después de cambiar en servidor
      try {
        final isar = IsarDatabase.instance.database;
        final isarAccount = IsarBankAccount.fromEntity(account.toEntity());
        await isar.writeTxn(() async {
          await isar.isarBankAccounts.put(isarAccount);
        });
        print('✅ BankAccount por defecto actualizada en ISAR: $id');
      } catch (e) {
        print('⚠️ Error actualizando ISAR (no crítico): $e');
      }

      return Right(account.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, BankAccount>> toggleBankAccountActive(
    String id,
  ) async {
    if (!await networkInfo.isConnected) {
      // TODO: Implementar toggle offline
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final account = await remoteDataSource.toggleBankAccountActive(id);

      // ✅ Actualizar en ISAR después de toggle en servidor
      try {
        final isar = IsarDatabase.instance.database;
        final isarAccount = IsarBankAccount.fromEntity(account.toEntity());
        await isar.writeTxn(() async {
          await isar.isarBankAccounts.put(isarAccount);
        });
        print('✅ BankAccount toggle actualizada en ISAR: $id');
      } catch (e) {
        print('⚠️ Error actualizando ISAR (no crítico): $e');
      }

      return Right(account.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, BankAccountTransactionsResponse>>
      getBankAccountTransactions(
    String accountId, {
    String? startDate,
    String? endDate,
    int? page,
    int? limit,
    String? search,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final response = await remoteDataSource.getBankAccountTransactions(
        accountId,
        startDate: startDate,
        endDate: endDate,
        page: page,
        limit: limit,
        search: search,
      );

      // Extraer los datos si vienen envueltos en { success: true, data: {...} }
      final data = response is Map<String, dynamic> &&
              response.containsKey('data')
          ? response['data']
          : response;

      final transactionsResponse =
          BankAccountTransactionsResponseModel.fromJson(data);
      return Right(transactionsResponse);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error inesperado: $e'));
    }
  }

  // ==================== OFFLINE CREATE METHOD ====================

  /// Crea una cuenta bancaria en modo offline cuando no hay conexión
  ///
  /// Genera un ID temporal, guarda en ISAR,
  /// y agrega la operación a la cola de sincronización
  Future<Either<Failure, BankAccount>> _createBankAccountOffline({
    required String name,
    required BankAccountType type,
    String? bankName,
    String? accountNumber,
    String? holderName,
    String? icon,
    bool isActive = true,
    bool isDefault = false,
    int sortOrder = 0,
    String? description,
  }) async {
    print('📱 BankAccountRepository: Creando cuenta bancaria offline: $name');
    try {
      // Generar un ID temporal único para la cuenta offline
      final now = DateTime.now();
      final tempId = 'bank_account_offline_${now.millisecondsSinceEpoch}_${name.hashCode}';

      // Obtener organizationId del usuario actual
      String organizationId = 'offline_org';
      String? createdById;
      try {
        final authController = Get.find<dynamic>();
        if (authController.currentUser != null) {
          organizationId = authController.currentUser.organizationId ?? 'offline_org';
          createdById = authController.currentUser.id;
        }
      } catch (e) {
        print('⚠️ BankAccountRepository: No se pudo obtener usuario actual: $e');
      }

      // Calcular sortOrder si no se proporciona
      int calculatedSortOrder = sortOrder;
      if (sortOrder == 0) {
        try {
          final isar = IsarDatabase.instance.database;
          final count = await isar.isarBankAccounts
              .filter()
              .deletedAtIsNull()
              .count();
          calculatedSortOrder = count + 1;
        } catch (e) {
          print('⚠️ Error calculando sortOrder: $e');
          calculatedSortOrder = 1;
        }
      }

      // Si es la primera cuenta, puede ser default automáticamente
      bool shouldBeDefault = isDefault;
      if (!isDefault) {
        try {
          final isar = IsarDatabase.instance.database;
          final existingDefault = await isar.isarBankAccounts
              .filter()
              .isDefaultEqualTo(true)
              .and()
              .deletedAtIsNull()
              .findFirst();

          // Si no hay cuenta por defecto, esta será la default
          if (existingDefault == null) {
            shouldBeDefault = true;
          }
        } catch (e) {
          print('⚠️ Error verificando cuenta por defecto: $e');
        }
      }

      // Crear IsarBankAccount con ID temporal
      final isarAccount = IsarBankAccount.create(
        serverId: tempId,
        name: name,
        type: _mapBankAccountType(type),
        bankName: bankName,
        accountNumber: accountNumber,
        holderName: holderName,
        icon: icon,
        description: description,
        isActive: isActive,
        isDefault: shouldBeDefault,
        sortOrder: calculatedSortOrder,
        metadataJson: null,
        organizationId: organizationId,
        createdById: createdById,
        updatedById: null,
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        isSynced: false,
        lastSyncAt: null,
      );

      // Guardar en ISAR
      final isar = IsarDatabase.instance.database;
      await isar.writeTxn(() async {
        await isar.isarBankAccounts.put(isarAccount);
      });
      print('✅ BankAccountRepository: Cuenta guardada en ISAR con ID temporal: $tempId');

      // Convertir a entidad domain
      final bankAccount = isarAccount.toEntity();

      // Agregar a la cola de sincronización
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'bank_account',
          entityId: tempId,
          operationType: SyncOperationType.create,
          data: {
            'name': name,
            'type': type.value,
            if (bankName != null) 'bankName': bankName,
            if (accountNumber != null) 'accountNumber': accountNumber,
            if (holderName != null) 'holderName': holderName,
            if (icon != null) 'icon': icon,
            'isActive': isActive,
            'isDefault': shouldBeDefault,
            'sortOrder': calculatedSortOrder,
            if (description != null) 'description': description,
          },
          priority: 1, // Alta prioridad para creación
        );
        print('📤 BankAccountRepository: Operación agregada a cola de sincronización');
      } catch (e) {
        print('⚠️ BankAccountRepository: Error agregando a cola de sync: $e');
      }

      print('✅ BankAccountRepository: Cuenta bancaria creada offline exitosamente');
      return Right(bankAccount);
    } catch (e) {
      print('❌ BankAccountRepository: Error creando cuenta bancaria offline: $e');
      return Left(CacheFailure('Error al crear cuenta bancaria offline: $e'));
    }
  }

  // ==================== SYNC OPERATIONS ====================

  /// Sincronizar cuentas bancarias creadas offline con el servidor
  Future<Either<Failure, List<BankAccount>>> syncOfflineBankAccounts() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No hay conexión a internet'));
    }

    try {
      print('🔄 BankAccountRepository: Starting offline bank accounts sync...');

      // Obtener cuentas bancarias no sincronizadas desde ISAR
      final isar = IsarDatabase.instance.database;
      final unsyncedAccounts = await isar.isarBankAccounts
          .filter()
          .isSyncedEqualTo(false)
          .and()
          .deletedAtIsNull()
          .findAll();

      if (unsyncedAccounts.isEmpty) {
        print('✅ BankAccountRepository: No bank accounts to sync');
        return const Right([]);
      }

      print('📤 BankAccountRepository: Syncing ${unsyncedAccounts.length} offline bank accounts...');
      final syncedAccounts = <BankAccount>[];

      for (final isarAccount in unsyncedAccounts) {
        try {
          // Determinar si es CREATE o UPDATE basándose en el serverId
          final isCreate = isarAccount.serverId.startsWith('bank_account_offline_');

          if (isCreate) {
            // CREATE: Enviar al servidor y actualizar con ID real
            print('📝 Creating bank account: ${isarAccount.name}');

            final request = CreateBankAccountRequest(
              name: isarAccount.name,
              type: _reverseMapBankAccountType(isarAccount.type),
              bankName: isarAccount.bankName,
              accountNumber: isarAccount.accountNumber,
              holderName: isarAccount.holderName,
              icon: isarAccount.icon,
              isActive: isarAccount.isActive,
              isDefault: isarAccount.isDefault,
              sortOrder: isarAccount.sortOrder,
              description: isarAccount.description,
            );

            final created = await remoteDataSource.createBankAccount(request);

            // Actualizar ISAR con el ID real del servidor
            isarAccount.serverId = created.id;
            isarAccount.markAsSynced();

            await isar.writeTxn(() async {
              await isar.isarBankAccounts.put(isarAccount);
            });

            syncedAccounts.add(created.toEntity());
            print('✅ Bank account created and synced: ${isarAccount.name} -> ${created.id}');
          } else {
            // UPDATE: Enviar actualización al servidor
            print('📝 Updating bank account: ${isarAccount.name}');

            final request = UpdateBankAccountRequest(
              name: isarAccount.name,
              type: _reverseMapBankAccountType(isarAccount.type),
              bankName: isarAccount.bankName,
              accountNumber: isarAccount.accountNumber,
              holderName: isarAccount.holderName,
              icon: isarAccount.icon,
              isActive: isarAccount.isActive,
              isDefault: isarAccount.isDefault,
              sortOrder: isarAccount.sortOrder,
              description: isarAccount.description,
            );

            final updated = await remoteDataSource.updateBankAccount(
              isarAccount.serverId,
              request,
            );

            isarAccount.markAsSynced();

            await isar.writeTxn(() async {
              await isar.isarBankAccounts.put(isarAccount);
            });

            syncedAccounts.add(updated.toEntity());
            print('✅ Bank account updated and synced: ${isarAccount.name}');
          }
        } catch (e) {
          print('❌ Error sincronizando cuenta bancaria ${isarAccount.name}: $e');
          // Continuar con la siguiente
        }
      }

      print('🎯 BankAccountRepository: Sync completed. Success: ${syncedAccounts.length}');
      return Right(syncedAccounts);
    } catch (e) {
      print('💥 BankAccountRepository: Error during offline bank accounts sync: $e');
      return Left(ServerFailure('Error al sincronizar cuentas bancarias offline: $e'));
    }
  }

  // ==================== HELPER METHODS ====================

  IsarBankAccountType _mapBankAccountType(BankAccountType type) {
    switch (type) {
      case BankAccountType.cash:
        return IsarBankAccountType.cash;
      case BankAccountType.savings:
        return IsarBankAccountType.savings;
      case BankAccountType.checking:
        return IsarBankAccountType.checking;
      case BankAccountType.digitalWallet:
        return IsarBankAccountType.digitalWallet;
      case BankAccountType.creditCard:
        return IsarBankAccountType.creditCard;
      case BankAccountType.debitCard:
        return IsarBankAccountType.debitCard;
      case BankAccountType.other:
        return IsarBankAccountType.other;
    }
  }

  // Reverse mapper (ISAR -> Domain)
  String _reverseMapBankAccountType(IsarBankAccountType type) {
    switch (type) {
      case IsarBankAccountType.cash:
        return BankAccountType.cash.value;
      case IsarBankAccountType.savings:
        return BankAccountType.savings.value;
      case IsarBankAccountType.checking:
        return BankAccountType.checking.value;
      case IsarBankAccountType.digitalWallet:
        return BankAccountType.digitalWallet.value;
      case IsarBankAccountType.creditCard:
        return BankAccountType.creditCard.value;
      case IsarBankAccountType.debitCard:
        return BankAccountType.debitCard.value;
      case IsarBankAccountType.other:
        return BankAccountType.other.value;
    }
  }
}
