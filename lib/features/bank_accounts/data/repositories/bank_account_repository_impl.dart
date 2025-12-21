// lib/features/bank_accounts/data/repositories/bank_account_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
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
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final accounts = await remoteDataSource.getBankAccounts(
        type: type?.value,
        isActive: isActive,
        includeInactive: includeInactive,
      );
      return Right(accounts.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, List<BankAccount>>> getActiveBankAccounts() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final accounts = await remoteDataSource.getActiveBankAccounts();
      return Right(accounts.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, BankAccount>> getBankAccountById(String id) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final account = await remoteDataSource.getBankAccountById(id);
      return Right(account.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, BankAccount?>> getDefaultBankAccount() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final account = await remoteDataSource.getDefaultBankAccount();
      return Right(account?.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error inesperado: $e'));
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
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

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
      return Right(account.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error inesperado: $e'));
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
      return Left(NetworkFailure('Sin conexión a internet'));
    }

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
      return Right(account.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBankAccount(String id) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      await remoteDataSource.deleteBankAccount(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, BankAccount>> setDefaultBankAccount(String id) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final account = await remoteDataSource.setDefaultBankAccount(id);
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
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final account = await remoteDataSource.toggleBankAccountActive(id);
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
}
