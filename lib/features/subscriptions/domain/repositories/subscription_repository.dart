// lib/features/subscriptions/domain/repositories/subscription_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/subscription.dart';
import '../entities/subscription_usage.dart';
import '../entities/action_validation.dart';
import '../entities/plan_limits.dart';

/// Interfaz del repositorio de suscripciones
abstract class SubscriptionRepository {
  /// Obtener la suscripcion actual desde el servidor
  Future<Either<Failure, Subscription>> getCurrentSubscription();

  /// Obtener los limites del plan actual
  Future<Either<Failure, PlanLimits>> getSubscriptionLimits();

  /// Obtener el uso actual de recursos
  Future<Either<Failure, SubscriptionUsage>> getSubscriptionUsage({
    int products = 0,
    int customers = 0,
    int users = 0,
    int invoicesThisMonth = 0,
    int expensesThisMonth = 0,
    int storageMB = 0,
  });

  /// Validar si una accion esta permitida
  Future<Either<Failure, ActionValidation>> validateAction(
    String action, {
    int? currentUsage,
  });

  /// Obtener suscripcion cacheada (para modo offline)
  Future<Either<Failure, Subscription>> getCachedSubscription();

  /// Guardar suscripcion en cache
  Future<Either<Failure, void>> cacheSubscription(Subscription subscription);

  /// Guardar limites en cache
  Future<Either<Failure, void>> cacheLimits(PlanLimits limits);

  /// Obtener limites cacheados
  Future<Either<Failure, PlanLimits>> getCachedLimits();

  /// Limpiar cache de suscripcion
  Future<Either<Failure, void>> clearCache();

  /// Verificar si la suscripcion en cache esta expirada
  Future<bool> isCachedSubscriptionExpired();

  /// Obtener fecha de ultima sincronizacion
  Future<DateTime?> getLastSyncDate();
}
