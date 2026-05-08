// lib/features/bank_accounts/data/repositories/bank_account_offline_repository.dart
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../domain/entities/bank_account.dart';
import '../../domain/entities/bank_account_movement.dart';
import '../../domain/entities/bank_account_transaction.dart';
import '../../domain/repositories/bank_account_repository.dart';
import '../models/isar/isar_bank_account.dart';
import '../models/isar/isar_bank_account_movement.dart';

/// Implementación offline del repositorio de cuentas bancarias usando ISAR
class BankAccountOfflineRepository implements BankAccountRepository {
  final IsarDatabase _database;

  BankAccountOfflineRepository({IsarDatabase? database})
    : _database = database ?? IsarDatabase.instance;

  Isar get _isar => _database.database;

  // ==================== READ OPERATIONS ====================

  @override
  Future<Either<Failure, List<BankAccount>>> getBankAccounts({
    BankAccountType? type,
    bool? isActive,
    bool includeInactive = false,
  }) async {
    try {
      var filterQuery = _isar.isarBankAccounts.filter().deletedAtIsNull();

      if (type != null) {
        final isarType = _mapBankAccountType(type);
        filterQuery = filterQuery.and().typeEqualTo(isarType);
      }

      if (isActive != null) {
        filterQuery = filterQuery.and().isActiveEqualTo(isActive);
      } else if (!includeInactive) {
        filterQuery = filterQuery.and().isActiveEqualTo(true);
      }

      final isarBankAccounts = await filterQuery.sortBySortOrder().findAll();

      final bankAccounts = isarBankAccounts.map((isar) => isar.toEntity()).toList();
      return Right(bankAccounts);
    } catch (e) {
      return Left(CacheFailure('Error loading bank accounts: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<BankAccount>>> getActiveBankAccounts() async {
    return getBankAccounts(isActive: true);
  }

  @override
  Future<Either<Failure, BankAccount>> getBankAccountById(String id) async {
    try {
      final isarBankAccount = await _isar.isarBankAccounts
        .filter()
        .serverIdEqualTo(id)
        .and()
        .deletedAtIsNull()
        .findFirst();

      if (isarBankAccount == null) {
        return Left(CacheFailure('Bank account not found'));
      }

      return Right(isarBankAccount.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error loading bank account: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, BankAccount?>> getDefaultBankAccount() async {
    try {
      final isarBankAccount = await _isar.isarBankAccounts
        .filter()
        .isDefaultEqualTo(true)
        .and()
        .deletedAtIsNull()
        .findFirst();

      return Right(isarBankAccount?.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error loading default bank account: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, BankAccountTransactionsResponse>> getBankAccountTransactions(
    String accountId, {
    String? startDate,
    String? endDate,
    int? page,
    int? limit,
    String? search,
  }) async {
    // For offline, we don't have transactions stored separately
    // Return empty response with dummy data
    try {
      final isarBankAccount = await _isar.isarBankAccounts
        .filter()
        .serverIdEqualTo(accountId)
        .and()
        .deletedAtIsNull()
        .findFirst();

      if (isarBankAccount == null) {
        return Left(CacheFailure('Bank account not found'));
      }

      return Right(BankAccountTransactionsResponse(
        account: TransactionAccountInfo(
          id: isarBankAccount.serverId,
          name: isarBankAccount.name,
          type: isarBankAccount.type.name,
          currentBalance: 0.0, // TODO: Calculate from transactions when implemented
          bankName: isarBankAccount.bankName,
          accountNumber: isarBankAccount.accountNumber,
        ),
        transactions: [],
        pagination: TransactionsPagination(
          page: page ?? 1,
          limit: limit ?? 10,
          total: 0,
          totalPages: 0,
        ),
        summary: const TransactionsSummary(
          totalIncome: 0.0,
          transactionCount: 0,
          averageTransaction: 0.0,
        ),
      ));
    } catch (e) {
      return Left(CacheFailure('Error loading transactions: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, BankAccountMovementsPage>> listMovements(
    String accountId, {
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      var qb = _isar.isarBankAccountMovements
          .filter()
          .bankAccountIdEqualTo(accountId)
          .deletedAtIsNull();
      if (startDate != null) {
        qb = qb.movementDateGreaterThan(startDate, include: true);
      }
      if (endDate != null) {
        qb = qb.movementDateLessThan(endDate, include: true);
      }

      final total = await qb.count();
      final items = await qb
          .sortByMovementDateDesc()
          .thenByCreatedAtDesc()
          .offset((page - 1) * limit)
          .limit(limit)
          .findAll();

      return Right(BankAccountMovementsPage(
        items: items.map((e) => e.toEntity()).toList(),
        total: total,
        page: page,
        limit: limit,
      ));
    } catch (e) {
      return Left(CacheFailure('Error leyendo movements: $e'));
    }
  }

  // ==================== WRITE OPERATIONS ====================

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
    try {
      final now = DateTime.now();
      final serverId = 'bank_${now.millisecondsSinceEpoch}_${name.hashCode}';

      // If this is the default, unset all other defaults
      if (isDefault) {
        await _unsetAllDefaults();
      }

      final isarBankAccount = IsarBankAccount.create(
        serverId: serverId,
        name: name,
        type: _mapBankAccountType(type),
        bankName: bankName,
        accountNumber: accountNumber,
        holderName: holderName,
        icon: icon,
        description: description,
        isActive: isActive,
        isDefault: isDefault,
        sortOrder: sortOrder,
        organizationId: 'offline', // TODO: Get from auth context
        createdAt: now,
        updatedAt: now,
        isSynced: false,
      );

      await _isar.writeTxn(() async {
        await _isar.isarBankAccounts.put(isarBankAccount);
      });

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'BankAccount',
          entityId: serverId,
          operationType: SyncOperationType.create,
          data: {
            'name': name,
            'type': type.name,
            'bankName': bankName,
            'accountNumber': accountNumber,
            'holderName': holderName,
            'icon': icon,
            'isActive': isActive,
            'isDefault': isDefault,
            'sortOrder': sortOrder,
            'description': description,
          },
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

      return Right(isarBankAccount.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error creating bank account: ${e.toString()}'));
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
    try {
      final isarBankAccount = await _isar.isarBankAccounts
        .filter()
        .serverIdEqualTo(id)
        .findFirst();

      if (isarBankAccount == null) {
        return Left(CacheFailure('Bank account not found'));
      }

      // If this is being set as default, unset all other defaults
      if (isDefault == true) {
        await _unsetAllDefaults();
      }

      if (name != null) isarBankAccount.name = name;
      if (type != null) isarBankAccount.type = _mapBankAccountType(type);
      if (bankName != null) isarBankAccount.bankName = bankName;
      if (accountNumber != null) isarBankAccount.accountNumber = accountNumber;
      if (holderName != null) isarBankAccount.holderName = holderName;
      if (icon != null) isarBankAccount.icon = icon;
      if (description != null) isarBankAccount.description = description;
      if (isActive != null) isarBankAccount.isActive = isActive;
      if (isDefault != null) isarBankAccount.isDefault = isDefault;
      if (sortOrder != null) isarBankAccount.sortOrder = sortOrder;

      isarBankAccount.markAsUnsynced();

      await _isar.writeTxn(() async {
        await _isar.isarBankAccounts.put(isarBankAccount);
      });

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'BankAccount',
          entityId: id,
          operationType: SyncOperationType.update,
          data: {'updated': true},
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

      return Right(isarBankAccount.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error updating bank account: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBankAccount(String id) async {
    try {
      final isarBankAccount = await _isar.isarBankAccounts
        .filter()
        .serverIdEqualTo(id)
        .findFirst();

      if (isarBankAccount == null) {
        return Left(CacheFailure('Bank account not found'));
      }

      isarBankAccount.softDelete();

      await _isar.writeTxn(() async {
        await _isar.isarBankAccounts.put(isarBankAccount);
      });

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'BankAccount',
          entityId: id,
          operationType: SyncOperationType.delete,
          data: {'deleted': true},
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error deleting bank account: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, BankAccount>> setDefaultBankAccount(String id) async {
    return updateBankAccount(id: id, isDefault: true);
  }

  @override
  Future<Either<Failure, BankAccount>> toggleBankAccountActive(String id) async {
    try {
      final isarBankAccount = await _isar.isarBankAccounts
        .filter()
        .serverIdEqualTo(id)
        .findFirst();

      if (isarBankAccount == null) {
        return Left(CacheFailure('Bank account not found'));
      }

      final newActiveStatus = !isarBankAccount.isActive;

      return updateBankAccount(id: id, isActive: newActiveStatus);
    } catch (e) {
      return Left(CacheFailure('Error toggling bank account active: ${e.toString()}'));
    }
  }

  // ==================== HELPER METHODS ====================

  Future<void> _unsetAllDefaults() async {
    final defaultAccounts = await _isar.isarBankAccounts
      .filter()
      .isDefaultEqualTo(true)
      .findAll();

    await _isar.writeTxn(() async {
      for (final account in defaultAccounts) {
        account.isDefault = false;
        account.markAsUnsynced();
        await _isar.isarBankAccounts.put(account);
      }
    });
  }

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

  // ==================== SYNC OPERATIONS ====================

  Future<Either<Failure, List<BankAccount>>> getUnsyncedBankAccounts() async {
    try {
      final isarBankAccounts = await _isar.isarBankAccounts
        .filter()
        .isSyncedEqualTo(false)
        .findAll();

      final bankAccounts = isarBankAccounts.map((isar) => isar.toEntity()).toList();
      return Right(bankAccounts);
    } catch (e) {
      return Left(CacheFailure('Error loading unsynced bank accounts: ${e.toString()}'));
    }
  }

  Future<Either<Failure, void>> markBankAccountsAsSynced(List<String> bankAccountIds) async {
    try {
      await _isar.writeTxn(() async {
        for (final id in bankAccountIds) {
          final isarBankAccount = await _isar.isarBankAccounts
            .filter()
            .serverIdEqualTo(id)
            .findFirst();

          if (isarBankAccount != null) {
            isarBankAccount.markAsSynced();
            await _isar.isarBankAccounts.put(isarBankAccount);
          }
        }
      });

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error marking bank accounts as synced: ${e.toString()}'));
    }
  }

  Future<Either<Failure, void>> bulkInsertBankAccounts(List<BankAccount> bankAccounts) async {
    try {
      final isarBankAccounts = bankAccounts
        .map((account) => IsarBankAccount.fromEntity(account))
        .toList();

      await _isar.writeTxn(() async {
        await _isar.isarBankAccounts.putAll(isarBankAccounts);
      });

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error bulk inserting bank accounts: ${e.toString()}'));
    }
  }
}
