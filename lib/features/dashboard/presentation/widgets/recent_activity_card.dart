// lib/features/dashboard/presentation/widgets/recent_activity_card.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../../domain/entities/recent_activity.dart';
import '../../domain/entities/recent_activity_advanced.dart' as advanced;
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/config/themes/app_text_styles.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/shared/widgets/shimmer_loading.dart';

class RecentActivityCard extends GetView<DashboardController> {
  const RecentActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Actividad reciente',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: controller.refreshActivity,
                icon: const Icon(Icons.refresh, size: 20),
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          Obx(() => _buildActivityContent()),
        ],
      ),
    );
  }

  Widget _buildActivityContent() {
    // Usar datos avanzados si están disponibles, sino fallback a los básicos
    final hasAdvancedData = controller.recentActivitiesAdvanced.isNotEmpty;
    final hasBasicData = controller.recentActivities.isNotEmpty;
    final isLoading = controller.isLoadingActivity;
    final hasError = controller.activityError != null;

    if (isLoading && !hasAdvancedData && !hasBasicData) {
      return _buildShimmerList();
    }

    if (hasError && !hasAdvancedData && !hasBasicData) {
      return _buildErrorState();
    }

    if (!hasAdvancedData && !hasBasicData) {
      return _buildEmptyState();
    }

    return hasAdvancedData ? _buildAdvancedActivityList() : _buildActivityList();
  }

  Widget _buildActivityList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.recentActivities.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        thickness: 1,
        color: AppColors.border,
      ),
      itemBuilder: (context, index) {
        final activity = controller.recentActivities[index];
        return _ActivityItem(activity: activity);
      },
    );
  }

  Widget _buildAdvancedActivityList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.recentActivitiesAdvanced.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        thickness: 1,
        color: AppColors.border,
      ),
      itemBuilder: (context, index) {
        final activity = controller.recentActivitiesAdvanced[index];
        return _AdvancedActivityItem(activity: activity);
      },
    );
  }

  Widget _buildShimmerList() {
    return ShimmerLoading(
      child: Column(
        children: List.generate(
          5,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spacingMedium),
            child: Row(
              children: [
                const ShimmerContainer(width: 40, height: 40, isCircular: true),
                const SizedBox(width: AppDimensions.spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ShimmerContainer(width: double.infinity, height: 16),
                      const SizedBox(height: 4),
                      const ShimmerContainer(width: 120, height: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 48,
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          Text(
            'Error al cargar actividad',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSmall),
          Text(
            controller.activityError ?? 'Error desconocido',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          ElevatedButton(
            onPressed: controller.refreshActivity,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        children: [
          Icon(
            Icons.history,
            color: AppColors.textSecondary,
            size: 48,
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          Text(
            'Sin actividad reciente',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSmall),
          Text(
            'La actividad de tu negocio aparecerá aquí',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final RecentActivity activity;

  const _ActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingSmall),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getActivityColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Icon(
              _getActivityIcon(),
              color: _getActivityColor(),
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  activity.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spacingSmall),
          Text(
            activity.formattedTime,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon() {
    switch (activity.type) {
      case ActivityType.sale:
        return Icons.shopping_cart;
      case ActivityType.invoice:
        return Icons.receipt;
      case ActivityType.payment:
        return Icons.payment;
      case ActivityType.product:
        return Icons.inventory_2;
      case ActivityType.customer:
        return Icons.person;
      case ActivityType.expense:
        return Icons.money_off;
      case ActivityType.order:
        return Icons.shopping_cart;
      case ActivityType.user:
        return Icons.person;
      case ActivityType.system:
        return Icons.circle;
    }
  }

  Color _getActivityColor() {
    switch (activity.type) {
      case ActivityType.sale:
        return AppColors.success;
      case ActivityType.invoice:
        return AppColors.primary;
      case ActivityType.payment:
        return AppColors.info;
      case ActivityType.product:
        return AppColors.warning;
      case ActivityType.customer:
        return AppColors.info;
      case ActivityType.expense:
        return AppColors.error;
      case ActivityType.order:
        return AppColors.warning;
      case ActivityType.user:
        return AppColors.info;
      case ActivityType.system:
        return AppColors.textSecondary;
    }
  }
}

class _AdvancedActivityItem extends StatelessWidget {
  final advanced.RecentActivityAdvanced activity;

  const _AdvancedActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingSmall),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: activity.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Icon(
              _getIconFromString(activity.icon),
              color: activity.color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        activity.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (activity.priority != advanced.ActivityPriority.normal) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getPriorityColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          activity.priority.displayName,
                          style: AppTextStyles.caption.copyWith(
                            color: _getPriorityColor(),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  activity.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (activity.userName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'por ${activity.userName}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spacingSmall),
          Text(
            activity.formattedTime,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'receipt':
        return Icons.receipt;
      case 'payment':
        return Icons.payment;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'inventory_2':
        return Icons.inventory_2;
      case 'person':
        return Icons.person;
      case 'money_off':
        return Icons.money_off;
      case 'category':
        return Icons.category;
      case 'business':
        return Icons.business;
      case 'settings':
        return Icons.settings;
      case 'security':
        return Icons.security;
      case 'error':
        return Icons.error;
      case 'info':
        return Icons.info;
      case 'warning':
        return Icons.warning;
      case 'check_circle':
        return Icons.check_circle;
      case 'sync':
        return Icons.sync;
      case 'backup':
        return Icons.backup;
      case 'analytics':
        return Icons.analytics;
      case 'trending_up':
        return Icons.trending_up;
      case 'add':
        return Icons.add;
      case 'edit':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      case 'visibility':
        return Icons.visibility;
      case 'download':
        return Icons.download;
      case 'upload':
        return Icons.upload;
      case 'notification_important':
        return Icons.notification_important;
      default:
        return Icons.circle;
    }
  }

  Color _getPriorityColor() {
    switch (activity.priority) {
      case advanced.ActivityPriority.critical:
        return AppColors.error;
      case advanced.ActivityPriority.high:
        return Colors.orange;
      case advanced.ActivityPriority.normal:
        return AppColors.textSecondary;
      case advanced.ActivityPriority.low:
        return AppColors.info;
      case advanced.ActivityPriority.medium:
        return AppColors.warning;
    }
  }
}