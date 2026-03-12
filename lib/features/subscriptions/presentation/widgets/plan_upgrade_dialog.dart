// lib/features/subscriptions/presentation/widgets/plan_upgrade_dialog.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/subscription_enums.dart';
import '../../domain/entities/plan_limits.dart';
import '../../domain/entities/plan_features.dart';

/// Diálogo para mostrar opciones de upgrade de plan
///
/// Muestra comparación entre el plan actual y los planes superiores
/// con sus características y precios.
class PlanUpgradeDialog extends StatelessWidget {
  final SubscriptionPlan currentPlan;
  final String? featureRequested;
  final String? limitReached;
  final VoidCallback? onPlanSelected;

  const PlanUpgradeDialog({
    super.key,
    required this.currentPlan,
    this.featureRequested,
    this.limitReached,
    this.onPlanSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(context),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mensaje contextual
                    if (featureRequested != null || limitReached != null)
                      _buildContextMessage(context),

                    const SizedBox(height: 20),

                    // Planes disponibles
                    _buildPlanCards(context),
                  ],
                ),
              ),
            ),

            // Footer
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.upgrade,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mejora tu Plan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Desbloquea más funcionalidades',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildContextMessage(BuildContext context) {
    String message;
    IconData icon;
    Color color;

    if (limitReached != null) {
      message = 'Has alcanzado el límite de $limitReached en tu plan actual.';
      icon = Icons.warning_amber_rounded;
      color = Colors.orange;
    } else if (featureRequested != null) {
      message = 'La función "$featureRequested" requiere un plan superior.';
      icon = Icons.lock_outline;
      color = Colors.blue;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCards(BuildContext context) {
    final plans = _getAvailablePlans();

    return Column(
      children: plans.map((plan) {
        final isRecommended = plan.plan == _getRecommendedPlan();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _PlanCard(
            plan: plan,
            isCurrentPlan: plan.plan == currentPlan,
            isRecommended: isRecommended,
            onSelect: () {
              Get.back();
              onPlanSelected?.call();
              Get.toNamed('/settings/subscription', arguments: {'plan': plan.plan});
            },
          ),
        );
      }).toList(),
    );
  }

  List<_PlanInfo> _getAvailablePlans() {
    return [
      _PlanInfo(
        plan: SubscriptionPlan.basic,
        name: 'Básico',
        price: '\$29.900',
        period: '/mes',
        description: 'Ideal para pequeños negocios',
        limits: PlanLimits.basic,
        features: PlanFeatures.basic,
        color: Colors.green,
        icon: Icons.star_outline,
      ),
      _PlanInfo(
        plan: SubscriptionPlan.premium,
        name: 'Premium',
        price: '\$59.900',
        period: '/mes',
        description: 'Para negocios en crecimiento',
        limits: PlanLimits.premium,
        features: PlanFeatures.premium,
        color: Colors.purple,
        icon: Icons.star,
      ),
      _PlanInfo(
        plan: SubscriptionPlan.enterprise,
        name: 'Empresarial',
        price: '\$149.900',
        period: '/mes',
        description: 'Solución completa sin límites',
        limits: PlanLimits.enterprise,
        features: PlanFeatures.enterprise,
        color: Colors.indigo,
        icon: Icons.diamond,
      ),
    ].where((p) => p.plan.index > currentPlan.index).toList();
  }

  SubscriptionPlan _getRecommendedPlan() {
    switch (currentPlan) {
      case SubscriptionPlan.trial:
        return SubscriptionPlan.basic;
      case SubscriptionPlan.basic:
        return SubscriptionPlan.premium;
      case SubscriptionPlan.premium:
        return SubscriptionPlan.enterprise;
      default:
        return SubscriptionPlan.basic;
    }
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(Icons.support_agent, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '¿Necesitas ayuda? Contáctanos',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Ahora no'),
          ),
        ],
      ),
    );
  }

  /// Mostrar diálogo de upgrade
  static void show({
    required SubscriptionPlan currentPlan,
    String? featureRequested,
    String? limitReached,
    VoidCallback? onPlanSelected,
  }) {
    Get.dialog(
      PlanUpgradeDialog(
        currentPlan: currentPlan,
        featureRequested: featureRequested,
        limitReached: limitReached,
        onPlanSelected: onPlanSelected,
      ),
      barrierDismissible: true,
    );
  }
}

class _PlanInfo {
  final SubscriptionPlan plan;
  final String name;
  final String price;
  final String period;
  final String description;
  final PlanLimits limits;
  final PlanFeatures features;
  final Color color;
  final IconData icon;

  const _PlanInfo({
    required this.plan,
    required this.name,
    required this.price,
    required this.period,
    required this.description,
    required this.limits,
    required this.features,
    required this.color,
    required this.icon,
  });
}

class _PlanCard extends StatelessWidget {
  final _PlanInfo plan;
  final bool isCurrentPlan;
  final bool isRecommended;
  final VoidCallback onSelect;

  const _PlanCard({
    required this.plan,
    required this.isCurrentPlan,
    required this.isRecommended,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecommended ? plan.color : Colors.grey.shade200,
          width: isRecommended ? 2 : 1,
        ),
        boxShadow: isRecommended
            ? [
                BoxShadow(
                  color: plan.color.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Badge recomendado
          if (isRecommended)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: plan.color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: const Text(
                '⭐ RECOMENDADO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header del plan
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: plan.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(plan.icon, color: plan.color, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            plan.description,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          plan.price,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: plan.color,
                          ),
                        ),
                        Text(
                          plan.period,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Features destacadas
                _buildFeatureRow(
                  Icons.inventory_2,
                  'Productos',
                  plan.limits.maxProducts == -1
                      ? 'Ilimitados'
                      : '${plan.limits.maxProducts}',
                ),
                _buildFeatureRow(
                  Icons.people,
                  'Clientes',
                  plan.limits.maxCustomers == -1
                      ? 'Ilimitados'
                      : '${plan.limits.maxCustomers}',
                ),
                _buildFeatureRow(
                  Icons.receipt,
                  'Facturas/mes',
                  plan.limits.maxInvoicesPerMonth == -1
                      ? 'Ilimitadas'
                      : '${plan.limits.maxInvoicesPerMonth}',
                ),
                _buildFeatureRow(
                  Icons.group,
                  'Usuarios',
                  plan.limits.maxUsers == -1
                      ? 'Ilimitados'
                      : '${plan.limits.maxUsers}',
                ),

                const SizedBox(height: 16),

                // Botón de selección
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCurrentPlan ? null : onSelect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: plan.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: Text(
                      isCurrentPlan ? 'Plan Actual' : 'Seleccionar Plan',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
