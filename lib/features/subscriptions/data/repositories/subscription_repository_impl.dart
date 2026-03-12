// lib/features/subscriptions/data/repositories/subscription_repository_impl.dart

import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/network/network_info.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_enums.dart';
import '../../domain/entities/subscription_usage.dart';
import '../../domain/entities/action_validation.dart';
import '../../domain/entities/plan_limits.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_remote_datasource.dart';
import '../datasources/subscription_local_datasource.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource remoteDataSource;
  final SubscriptionLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  SubscriptionRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, Subscription>> getCurrentSubscription() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getCurrentSubscription();

        // Cachear resultado
        await localDataSource.cacheSubscription(result);

        // Limpiar flag de expiracion offline si aplica
        await localDataSource.clearExpiredOfflineFlag();

        return Right(result.toEntity());
      } on ServerException catch (e) {
        // Si falla el servidor, intentar cache local
        final localResult = await localDataSource.getCachedSubscription();
        return localResult.fold(
          (failure) => Left(ServerFailure(e.message)),
          (subscription) => Right(subscription),
        );
      }
    } else {
      // Modo offline - usar cache local
      final result = await localDataSource.getCachedSubscription();

      // Verificar si expiro mientras estaba offline
      final isExpired = await localDataSource.isCachedSubscriptionExpired();
      if (isExpired) {
        await localDataSource.markExpiredWhileOffline();
      }

      return result;
    }
  }

  @override
  Future<Either<Failure, PlanLimits>> getSubscriptionLimits() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getSubscriptionLimits();
        return Right(result.toEntity());
      } on ServerException catch (e) {
        // Si falla el servidor, usar limites del cache
        final subscriptionResult =
            await localDataSource.getCachedSubscription();
        return subscriptionResult.fold(
          (failure) => Left(ServerFailure(e.message)),
          (subscription) => Right(subscription.limits),
        );
      }
    } else {
      // Modo offline - usar limites del cache
      final subscriptionResult = await localDataSource.getCachedSubscription();
      return subscriptionResult.fold(
        (failure) => Left(failure),
        (subscription) => Right(subscription.limits),
      );
    }
  }

  @override
  Future<Either<Failure, SubscriptionUsage>> getSubscriptionUsage({
    int products = 0,
    int customers = 0,
    int users = 0,
    int invoicesThisMonth = 0,
    int expensesThisMonth = 0,
    int storageMB = 0,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getSubscriptionUsage(
          products: products,
          customers: customers,
          users: users,
          invoicesThisMonth: invoicesThisMonth,
          expensesThisMonth: expensesThisMonth,
          storageMB: storageMB,
        );
        return Right(result.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      // Modo offline - calcular uso basado en limites cacheados
      final subscriptionResult = await localDataSource.getCachedSubscription();
      return subscriptionResult.fold(
        (failure) => Left(failure),
        (subscription) {
          // Crear uso aproximado con los datos proporcionados
          final limits = subscription.limits;
          return Right(
            SubscriptionUsage(
              plan: subscription.plan,
              planDisplayName: subscription.planDisplayName,
              hasUnlimitedResources: limits.isFullyUnlimited,
              products: ResourceUsage.fromValues(products, limits.maxProducts),
              customers:
                  ResourceUsage.fromValues(customers, limits.maxCustomers),
              users: ResourceUsage.fromValues(users, limits.maxUsers),
              invoicesThisMonth: ResourceUsage.fromValues(
                invoicesThisMonth,
                limits.maxInvoicesPerMonth,
              ),
              expensesThisMonth: ResourceUsage.fromValues(
                expensesThisMonth,
                limits.maxExpensesPerMonth,
              ),
              storage: ResourceUsage.fromValues(storageMB, limits.maxStorageMB),
              warnings: [], // No hay advertencias en modo offline
              daysUntilExpiration: subscription.daysUntilExpiration,
              nextRenewalDate: subscription.nextBillingDate,
            ),
          );
        },
      );
    }
  }

  @override
  Future<Either<Failure, ActionValidation>> validateAction(
    String action, {
    int? currentUsage,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.validateAction(
          action,
          currentUsage: currentUsage,
        );
        return Right(result.toEntity());
      } on ServerException {
        // Si falla el servidor, validar localmente
        return _validateActionLocally(action, currentUsage: currentUsage);
      }
    } else {
      // Modo offline - validar con datos cacheados
      return _validateActionLocally(action, currentUsage: currentUsage);
    }
  }

  Future<Either<Failure, ActionValidation>> _validateActionLocally(
    String action, {
    int? currentUsage,
  }) async {
    final subscriptionResult = await localDataSource.getCachedSubscription();

    return subscriptionResult.fold(
      (failure) => Right(ActionValidation.noSubscription()),
      (subscription) {
        // Verificar si esta expirada
        if (subscription.isExpired) {
          // Verificar periodo de gracia
          return localDataSource.isInOfflineGracePeriod().then((inGrace) {
            if (inGrace) {
              // En periodo de gracia - permitir solo lectura
              if (_isReadOnlyAction(action)) {
                return Right(ActionValidation.allowed());
              }
              return Right(
                ActionValidation(
                  allowed: false,
                  reason:
                      'Solo lectura durante periodo de gracia offline. '
                      'Conectate para renovar tu suscripcion.',
                ),
              );
            }
            return Right(ActionValidation.subscriptionExpired());
          });
        }

        // Verificar feature
        if (!subscription.canPerformAction(action)) {
          return Right(
            ActionValidation.featureNotAllowed(
              reason:
                  'Esta funcion no esta disponible en tu plan ${subscription.planDisplayName}',
              requiredPlan: _getMinimumPlanForFeature(action),
            ),
          );
        }

        // Verificar limite si aplica
        if (currentUsage != null) {
          final limitResult = _checkLimit(action, currentUsage, subscription);
          if (!limitResult.allowed) {
            return Right(limitResult);
          }
        }

        return Right(ActionValidation.allowed());
      },
    );
  }

  bool _isReadOnlyAction(String action) {
    const readOnlyActions = [
      'view',
      'read',
      'list',
      'search',
      'export_pdf',
      'export_reports',
    ];
    return readOnlyActions.any((a) => action.contains(a));
  }

  ActionValidation _checkLimit(
    String action,
    int currentUsage,
    Subscription subscription,
  ) {
    final limits = subscription.limits;

    switch (action) {
      case 'create_product':
        if (!limits.canAddProduct(currentUsage)) {
          return ActionValidation.limitReached(
            reason: 'Has alcanzado el limite de productos',
            requiredPlan: _getNextPlan(subscription.plan),
            currentLimit: limits.maxProducts,
            currentUsage: currentUsage,
          );
        }
        break;
      case 'create_customer':
        if (!limits.canAddCustomer(currentUsage)) {
          return ActionValidation.limitReached(
            reason: 'Has alcanzado el limite de clientes',
            requiredPlan: _getNextPlan(subscription.plan),
            currentLimit: limits.maxCustomers,
            currentUsage: currentUsage,
          );
        }
        break;
      case 'create_invoice':
        if (!limits.canAddInvoice(currentUsage)) {
          return ActionValidation.limitReached(
            reason: 'Has alcanzado el limite de facturas mensuales',
            requiredPlan: _getNextPlan(subscription.plan),
            currentLimit: limits.maxInvoicesPerMonth,
            currentUsage: currentUsage,
          );
        }
        break;
      case 'create_user':
        if (!limits.canAddUser(currentUsage)) {
          return ActionValidation.limitReached(
            reason: 'Has alcanzado el limite de usuarios',
            requiredPlan: _getNextPlan(subscription.plan),
            currentLimit: limits.maxUsers,
            currentUsage: currentUsage,
          );
        }
        break;
      case 'create_expense':
        if (!limits.canAddExpense(currentUsage)) {
          return ActionValidation.limitReached(
            reason: 'Has alcanzado el limite de gastos mensuales',
            requiredPlan: _getNextPlan(subscription.plan),
            currentLimit: limits.maxExpensesPerMonth,
            currentUsage: currentUsage,
          );
        }
        break;
    }

    return ActionValidation.allowed();
  }

  SubscriptionPlan _getMinimumPlanForFeature(String feature) {
    // Determinar plan minimo basado en la feature
    // Esto deberia coincidir con la configuracion del backend
    final featurePlanMap = {
      'export_reports': SubscriptionPlan.basic,
      'export_excel': SubscriptionPlan.basic,
      'thermal_printer': SubscriptionPlan.basic,
      'advanced_reports': SubscriptionPlan.premium,
      'multiple_warehouses': SubscriptionPlan.premium,
      'custom_branding': SubscriptionPlan.premium,
      'api_integrations': SubscriptionPlan.enterprise,
    };

    return featurePlanMap[feature] ?? SubscriptionPlan.basic;
  }

  SubscriptionPlan _getNextPlan(SubscriptionPlan current) {
    switch (current) {
      case SubscriptionPlan.trial:
        return SubscriptionPlan.basic;
      case SubscriptionPlan.basic:
        return SubscriptionPlan.premium;
      case SubscriptionPlan.premium:
        return SubscriptionPlan.enterprise;
      case SubscriptionPlan.enterprise:
        return SubscriptionPlan.enterprise;
    }
  }

  @override
  Future<Either<Failure, Subscription>> getCachedSubscription() {
    return localDataSource.getCachedSubscription();
  }

  @override
  Future<Either<Failure, void>> cacheSubscription(Subscription subscription) {
    return localDataSource.cacheSubscription(subscription);
  }

  @override
  Future<Either<Failure, void>> cacheLimits(PlanLimits limits) async {
    // Los limites se cachean junto con la suscripcion
    // Este metodo existe por si se necesita cachear limites por separado
    return const Right(null);
  }

  @override
  Future<Either<Failure, PlanLimits>> getCachedLimits() async {
    final subscriptionResult = await localDataSource.getCachedSubscription();
    return subscriptionResult.fold(
      (failure) => Left(failure),
      (subscription) => Right(subscription.limits),
    );
  }

  @override
  Future<Either<Failure, void>> clearCache() {
    return localDataSource.clearCache();
  }

  @override
  Future<bool> isCachedSubscriptionExpired() {
    return localDataSource.isCachedSubscriptionExpired();
  }

  @override
  Future<DateTime?> getLastSyncDate() {
    return localDataSource.getLastSyncDate();
  }

  /// Verificar si expiro mientras estaba offline
  Future<bool> wasExpiredWhileOffline() {
    return localDataSource.wasExpiredWhileOffline();
  }

  /// Limpiar flag de expiracion offline
  Future<void> clearExpiredOfflineFlag() {
    return localDataSource.clearExpiredOfflineFlag();
  }
}
