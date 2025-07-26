// lib/features/dashboard/presentation/widgets/notifications_panel.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../../domain/entities/notification.dart' as dashboard;
import '../../domain/entities/smart_notification.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/config/themes/app_text_styles.dart';
import '../../../../app/shared/widgets/shimmer_loading.dart';

class NotificationsPanel extends GetView<DashboardController> {
  const NotificationsPanel({super.key});

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
                  'Notificaciones',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Obx(() => controller.unreadNotificationsCount > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        controller.unreadNotificationsCount.toString(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : const SizedBox.shrink()),
              IconButton(
                onPressed: controller.refreshNotifications,
                icon: const Icon(Icons.refresh, size: 20),
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          Obx(() => _buildNotificationsContent()),
        ],
      ),
    );
  }

  Widget _buildNotificationsContent() {
    // Usar datos avanzados si están disponibles, sino fallback a los básicos
    final hasAdvancedData = controller.smartNotifications.isNotEmpty;
    final hasBasicData = controller.notifications.isNotEmpty;
    final isLoading = controller.isLoadingNotifications;
    final hasError = controller.notificationsError != null;

    if (isLoading && !hasAdvancedData && !hasBasicData) {
      return _buildShimmerList();
    }

    if (hasError && !hasAdvancedData && !hasBasicData) {
      return _buildErrorState();
    }

    if (!hasAdvancedData && !hasBasicData) {
      return _buildEmptyState();
    }

    return hasAdvancedData ? _buildAdvancedNotificationsList() : _buildNotificationsList();
  }

  Widget _buildNotificationsList() {
    // Show only first 5 notifications in dashboard
    final displayNotifications = controller.notifications.take(5).toList();
    
    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayNotifications.length,
          separatorBuilder: (context, index) => const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.border,
          ),
          itemBuilder: (context, index) {
            final notification = displayNotifications[index];
            return _NotificationItem(
              notification: notification,
              onTap: () => controller.markNotificationAsRead(notification.id),
            );
          },
        ),
        if (controller.notifications.length > 5) ...[
          const SizedBox(height: AppDimensions.spacingMedium),
          TextButton(
            onPressed: () => Get.toNamed('/notifications'),
            child: Text(
              'Ver todas (${controller.notifications.length})',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAdvancedNotificationsList() {
    // Show only first 5 notifications in dashboard
    final displayNotifications = controller.smartNotifications.take(5).toList();
    
    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayNotifications.length,
          separatorBuilder: (context, index) => const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.border,
          ),
          itemBuilder: (context, index) {
            final notification = displayNotifications[index];
            return _SmartNotificationItem(
              notification: notification,
              onTap: () {
                // TODO: Implement smart notification action
                if (notification.actionUrl != null) {
                  // Navigate to action URL or perform action
                }
              },
            );
          },
        ),
        if (controller.smartNotifications.length > 5) ...[
          const SizedBox(height: AppDimensions.spacingMedium),
          TextButton(
            onPressed: () => Get.toNamed('/notifications'),
            child: Text(
              'Ver todas (${controller.smartNotifications.length})',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildShimmerList() {
    return ShimmerLoading(
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spacingMedium),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerContainer(width: 8, height: 8, isCircular: true),
                const SizedBox(width: AppDimensions.spacingSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ShimmerContainer(width: double.infinity, height: 16),
                      const SizedBox(height: 4),
                      const ShimmerContainer(width: 100, height: 14),
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
            Icons.notifications_off,
            color: AppColors.error,
            size: 48,
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          Text(
            'Error al cargar notificaciones',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          ElevatedButton(
            onPressed: controller.refreshNotifications,
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
            Icons.notifications_none,
            color: AppColors.textSecondary,
            size: 48,
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          Text(
            'Sin notificaciones',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSmall),
          Text(
            'Las notificaciones aparecerán aquí',
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

class _NotificationItem extends StatelessWidget {
  final dashboard.Notification notification;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.spacingSmall,
            horizontal: AppDimensions.spacingSmall,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: notification.isRead
                      ? AppColors.textSecondary.withOpacity(0.3)
                      : _getPriorityColor(),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.message,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _getTypeIcon(),
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          notification.formattedTime,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor() {
    switch (notification.priority) {
      case dashboard.NotificationPriority.urgent:
        return AppColors.error;
      case dashboard.NotificationPriority.high:
        return AppColors.error;
      case dashboard.NotificationPriority.medium:
        return AppColors.warning;
      case dashboard.NotificationPriority.low:
        return AppColors.info;
    }
  }

  IconData _getTypeIcon() {
    switch (notification.type) {
      case dashboard.NotificationType.sale:
        return Icons.shopping_cart;
      case dashboard.NotificationType.invoice:
        return Icons.receipt;
      case dashboard.NotificationType.payment:
        return Icons.payment;
      case dashboard.NotificationType.lowStock:
        return Icons.inventory;
      case dashboard.NotificationType.expense:
        return Icons.money_off;
      case dashboard.NotificationType.user:
        return Icons.person;
      case dashboard.NotificationType.system:
        return Icons.settings;
      case dashboard.NotificationType.reminder:
        return Icons.alarm;
    }
  }
}

class _SmartNotificationItem extends StatelessWidget {
  final SmartNotification notification;
  final VoidCallback onTap;

  const _SmartNotificationItem({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.spacingSmall,
            horizontal: AppDimensions.spacingSmall,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: notification.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Icon(
                  _getIconFromString(notification.icon),
                  color: notification.color,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (notification.priority != NotificationPriority.normal) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: notification.priorityColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              notification.priority.displayName.toUpperCase(),
                              style: AppTextStyles.caption.copyWith(
                                color: notification.priorityColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.message,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: notification.isRead
                                ? AppColors.textSecondary.withOpacity(0.3)
                                : notification.priorityColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          notification.formattedTime,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        if (notification.actionLabel != null) ...[
                          const Spacer(),
                          Text(
                            notification.actionLabel!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 10,
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
      case 'notification_important':
        return Icons.notification_important;
      case 'alarm':
        return Icons.alarm;
      default:
        return Icons.notifications;
    }
  }
}