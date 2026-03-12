// lib/features/subscriptions/domain/entities/action_validation.dart

import 'package:equatable/equatable.dart';
import 'subscription_enums.dart';

/// Resultado de validacion de una accion
class ActionValidation extends Equatable {
  final bool allowed;
  final String? reason;
  final SubscriptionPlan? requiredPlan;
  final int? currentLimit;
  final int? currentUsage;

  const ActionValidation({
    required this.allowed,
    this.reason,
    this.requiredPlan,
    this.currentLimit,
    this.currentUsage,
  });

  /// Crear validacion exitosa
  factory ActionValidation.allowed() {
    return const ActionValidation(allowed: true);
  }

  /// Crear validacion denegada por feature
  factory ActionValidation.featureNotAllowed({
    required String reason,
    required SubscriptionPlan requiredPlan,
  }) {
    return ActionValidation(
      allowed: false,
      reason: reason,
      requiredPlan: requiredPlan,
    );
  }

  /// Crear validacion denegada por limite
  factory ActionValidation.limitReached({
    required String reason,
    required SubscriptionPlan requiredPlan,
    required int currentLimit,
    required int currentUsage,
  }) {
    return ActionValidation(
      allowed: false,
      reason: reason,
      requiredPlan: requiredPlan,
      currentLimit: currentLimit,
      currentUsage: currentUsage,
    );
  }

  /// Crear validacion denegada por suscripcion expirada
  factory ActionValidation.subscriptionExpired() {
    return const ActionValidation(
      allowed: false,
      reason: 'Tu suscripcion ha expirado. Renueva para continuar.',
    );
  }

  /// Crear validacion denegada por falta de suscripcion
  factory ActionValidation.noSubscription() {
    return const ActionValidation(
      allowed: false,
      reason: 'No tienes una suscripcion activa.',
      requiredPlan: SubscriptionPlan.trial,
    );
  }

  /// Verificar si se alcanzo el limite
  bool get isLimitIssue => currentLimit != null && currentUsage != null;

  /// Obtener mensaje de upgrade sugerido
  String? get upgradeMessage {
    if (allowed || requiredPlan == null) return null;
    return 'Actualiza a ${requiredPlan!.displayName} para desbloquear esta funcion.';
  }

  @override
  List<Object?> get props => [
        allowed,
        reason,
        requiredPlan,
        currentLimit,
        currentUsage,
      ];
}
