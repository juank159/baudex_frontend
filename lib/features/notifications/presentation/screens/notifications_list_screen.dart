// lib/features/notifications/presentation/screens/notifications_list_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_text_styles.dart';
import '../../../dashboard/domain/entities/notification.dart' as entities;
import '../controllers/notifications_controller.dart';
import '../widgets/notification_card_widget.dart';
import '../widgets/notification_filter_widget.dart';
import '../widgets/notification_skeleton_widget.dart';
import '../../../../app/presentation/widgets/sync_status_indicator.dart';

class NotificationsListScreen extends GetView<NotificationsController> {
  const NotificationsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElegantLightTheme.scaffoldBackground,
      appBar: _buildModernAppBar(context),
      body: ResponsiveHelper.isMobile(context)
          ? _buildMobileLayout(context)
          : _buildDesktopLayout(context),
      floatingActionButton: ResponsiveHelper.isMobile(context)
          ? _buildModernFloatingActionButton(context)
          : null,
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.notifications_rounded,
              color: Colors.white,
              size: isMobile ? 18 : 20,
            ),
          ),
          SizedBox(width: isMobile ? 10 : 12),
          Text(
            'Notificaciones',
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Obx(() {
            final unreadCount = controller.unreadCount;
            if (unreadCount == 0) return const SizedBox.shrink();

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: TextStyle(
                  color: ElegantLightTheme.primaryBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
        ],
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      actions: isMobile
          ? [
              const SyncStatusIcon(),
              _buildMobileMenuButton(context),
              const SizedBox(width: 8),
            ]
          : [
              const SyncStatusIcon(),
              _buildAppBarActionButton(
                icon: Icons.search_rounded,
                tooltip: 'Buscar',
                onPressed: () => _showSearchDialog(context),
              ),
              _buildAppBarActionButton(
                icon: Icons.filter_list_rounded,
                tooltip: 'Filtrar',
                onPressed: () => _showFilterSheet(context),
              ),
              Obx(() {
                final unreadCount = controller.unreadCount;
                if (unreadCount == 0) return const SizedBox.shrink();

                return _buildAppBarActionButton(
                  icon: Icons.done_all_rounded,
                  tooltip: 'Marcar todas como leidas',
                  onPressed: () => _confirmMarkAllAsRead(context),
                );
              }),
              _buildAppBarActionButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Actualizar',
                onPressed: () => controller.refreshNotifications(),
              ),
              const SizedBox(width: 8),
            ],
    );
  }

  Widget _buildAppBarActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileMenuButton(BuildContext context) {
    return Obx(() {
      final unreadCount = controller.unreadCount;
      return PopupMenuButton<String>(
        icon: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        offset: const Offset(0, 50),
        onSelected: (value) {
          switch (value) {
            case 'search':
              _showSearchDialog(context);
              break;
            case 'filter':
              _showFilterSheet(context);
              break;
            case 'mark_read':
              _confirmMarkAllAsRead(context);
              break;
            case 'refresh':
              controller.refreshNotifications();
              break;
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'search',
            child: ListTile(
              leading: Icon(Icons.search_rounded),
              title: Text('Buscar'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: 'filter',
            child: ListTile(
              leading: Icon(Icons.filter_list_rounded),
              title: Text('Filtrar'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (unreadCount > 0)
            PopupMenuItem(
              value: 'mark_read',
              child: ListTile(
                leading: const Icon(Icons.done_all_rounded),
                title: Text('Marcar todas como leídas ($unreadCount)'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          const PopupMenuItem(
            value: 'refresh',
            child: ListTile(
              leading: Icon(Icons.refresh_rounded),
              title: Text('Actualizar'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildMobileLayout(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => controller.refreshNotifications(),
      color: ElegantLightTheme.primaryBlue,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildModernQuickStats(context),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                if (controller.isLoading && controller.notifications.isEmpty) {
                  return const NotificationSkeletonWidget(itemCount: 8);
                }

                if (controller.errorMessage.isNotEmpty && controller.notifications.isEmpty) {
                  return _buildModernErrorState(context);
                }

                if (controller.notifications.isEmpty) {
                  return _buildModernEmptyState(context);
                }

                return _buildNotificationsList(context);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Sidebar with filters (desktop only)
        if (ResponsiveHelper.isDesktop(context))
          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                width: 320,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.95),
                      Colors.white.withOpacity(0.85),
                    ],
                  ),
                  border: Border(
                    right: BorderSide(
                      color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  boxShadow: ElegantLightTheme.elevatedShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: ElegantLightTheme.warningGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: ElegantLightTheme.warningOrange.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                ElegantLightTheme.warningGradient.createShader(bounds),
                            child: Text(
                              'Filtros',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Obx(() => NotificationFilterWidget(
                          showUnreadOnly: controller.showUnreadOnly,
                          selectedType: controller.selectedType,
                          selectedPriority: controller.selectedPriority,
                          startDate: null,
                          endDate: null,
                          onUnreadOnlyChanged: (_) => controller.toggleUnreadFilter(),
                          onTypeChanged: (type) => controller.filterByType(type),
                          onPriorityChanged: (priority) => controller.filterByPriority(priority),
                          onDateRangeChanged: (start, end) {},
                          onClearFilters: () {
                            controller.clearFilters();
                          },
                        )),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Main content area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildModernQuickStats(context),
                const SizedBox(height: 24),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        decoration: ElegantLightTheme.glassDecoration(
                          borderColor: ElegantLightTheme.primaryBlue.withOpacity(0.15),
                          gradient: ElegantLightTheme.glassGradient,
                        ),
                        child: Obx(() {
                          if (controller.isLoading && controller.notifications.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(24),
                              child: NotificationSkeletonWidget(itemCount: 10),
                            );
                          }

                          if (controller.errorMessage.isNotEmpty &&
                              controller.notifications.isEmpty) {
                            return _buildModernErrorState(context);
                          }

                          if (controller.notifications.isEmpty) {
                            return _buildModernEmptyState(context);
                          }

                          return _buildNotificationsList(context);
                        }),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernQuickStats(BuildContext context) {
    return Obx(() {
      final total = controller.notifications.length;
      final unread = controller.unreadCount;
      final read = total - unread;

      return Row(
        children: [
          Expanded(
            child: _buildModernStatCard(
              context,
              icon: Icons.notifications_rounded,
              label: 'Total',
              value: total.toString(),
              gradient: ElegantLightTheme.primaryGradient,
              color: ElegantLightTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildModernStatCard(
              context,
              icon: Icons.circle_notifications_rounded,
              label: 'No leidas',
              value: unread.toString(),
              gradient: ElegantLightTheme.warningGradient,
              color: ElegantLightTheme.warningOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildModernStatCard(
              context,
              icon: Icons.check_circle_rounded,
              label: 'Leidas',
              value: read.toString(),
              gradient: ElegantLightTheme.successGradient,
              color: ElegantLightTheme.successGreen,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildModernStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required LinearGradient gradient,
    required Color color,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              ...ElegantLightTheme.elevatedShadow,
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const Spacer(),
                  ShaderMask(
                    shaderCallback: (bounds) => gradient.createShader(bounds),
                    child: Text(
                      value,
                      style: AppTextStyles.titleLarge.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 13,
                  color: ElegantLightTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!controller.isLoading &&
            controller.hasMorePages &&
            scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
          controller.loadMoreNotifications();
        }
        return false;
      },
      child: ListView.builder(
        padding: ResponsiveHelper.isDesktop(context)
            ? const EdgeInsets.all(24)
            : EdgeInsets.zero,
        itemCount: controller.notifications.length + (controller.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == controller.notifications.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            );
          }

          final notification = controller.notifications[index];

          return NotificationCardWidget(
            notification: notification,
            onTap: () => _navigateToDetail(context, notification),
            onMarkAsRead: notification.isRead
                ? null
                : () => controller.markAsRead(notification.id),
            onDelete: () => _confirmDelete(context, notification),
          );
        },
      ),
    );
  }

  Widget _buildModernEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with glassmorphism effect
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ElegantLightTheme.primaryBlue.withOpacity(0.15),
                          ElegantLightTheme.primaryBlue.withOpacity(0.08),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 48,
                      color: ElegantLightTheme.primaryBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              ShaderMask(
                shaderCallback: (bounds) =>
                    ElegantLightTheme.primaryGradient.createShader(bounds),
                child: Text(
                  'No hay notificaciones',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Cuando recibas notificaciones apareceran aqui',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 15,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              _buildModernButton(
                icon: Icons.refresh_rounded,
                label: 'Actualizar',
                gradient: ElegantLightTheme.primaryGradient,
                onPressed: () => controller.refreshNotifications(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernErrorState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon with glassmorphism effect
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ElegantLightTheme.errorRed.withOpacity(0.15),
                          ElegantLightTheme.errorRed.withOpacity(0.08),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ElegantLightTheme.errorRed.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ElegantLightTheme.errorRed.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: ElegantLightTheme.errorRed,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              ShaderMask(
                shaderCallback: (bounds) =>
                    ElegantLightTheme.errorGradient.createShader(bounds),
                child: Text(
                  'Error al cargar notificaciones',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Obx(() => Text(
                controller.errorMessage,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 15,
                  color: ElegantLightTheme.textSecondary,
                ),
              )),
              const SizedBox(height: 28),
              _buildModernButton(
                icon: Icons.refresh_rounded,
                label: 'Reintentar',
                gradient: ElegantLightTheme.primaryGradient,
                onPressed: () => controller.refreshNotifications(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernButton({
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildModernFloatingActionButton(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Scroll to top
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: FloatingActionButton.small(
            onPressed: () {
              // Implement scroll to top
            },
            heroTag: 'scroll_top',
            backgroundColor: Colors.white,
            elevation: 4,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.glassGradient,
                shape: BoxShape.circle,
                border: Border.all(
                  color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
                ),
              ),
              child: Icon(
                Icons.arrow_upward_rounded,
                color: ElegantLightTheme.primaryBlue,
                size: 20,
              ),
            ),
          ),
        ),

        // Filters FAB
        Container(
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: ElegantLightTheme.primaryBlue.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () => _showFilterSheet(context),
            heroTag: 'filters',
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Obx(() {
              final hasFilters = controller.showUnreadOnly ||
                  controller.selectedType != null ||
                  controller.selectedPriority != null;

              return Stack(
                children: [
                  const Icon(
                    Icons.filter_list_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                  if (hasFilters)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: ElegantLightTheme.errorGradient,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: ElegantLightTheme.errorRed.withOpacity(0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: ElegantLightTheme.glassDecoration(
                borderColor: ElegantLightTheme.primaryBlue.withOpacity(0.2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: ElegantLightTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Buscar notificaciones',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: ElegantLightTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Buscar por titulo o mensaje...',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: ElegantLightTheme.textSecondary,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: ElegantLightTheme.primaryBlue,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (query) {
                      controller.debouncedSearch(query);
                    },
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        'Cancelar',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: ElegantLightTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.95),
                  Colors.white.withOpacity(0.9),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: ElegantLightTheme.primaryBlue.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) => SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Obx(() => NotificationFilterWidget(
                    showUnreadOnly: controller.showUnreadOnly,
                    selectedType: controller.selectedType,
                    selectedPriority: controller.selectedPriority,
                    startDate: null,
                    endDate: null,
                    onUnreadOnlyChanged: (_) => controller.toggleUnreadFilter(),
                    onTypeChanged: (type) => controller.filterByType(type),
                    onPriorityChanged: (priority) => controller.filterByPriority(priority),
                    onDateRangeChanged: (start, end) {},
                    onClearFilters: () {
                      controller.clearFilters();
                      Get.back();
                    },
                  )),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmMarkAllAsRead(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: ElegantLightTheme.glassDecoration(
                borderColor: ElegantLightTheme.primaryBlue.withOpacity(0.2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.infoGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.done_all_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Marcar todas como leidas',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Estas seguro de que deseas marcar todas las notificaciones como leidas?',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: ElegantLightTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Get.back(),
                          child: Text(
                            'Cancelar',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: ElegantLightTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModernButton(
                          icon: Icons.check_rounded,
                          label: 'Confirmar',
                          gradient: ElegantLightTheme.successGradient,
                          onPressed: () {
                            Get.back();
                            controller.markAllAsRead();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, entities.Notification notification) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: ElegantLightTheme.glassDecoration(
                borderColor: ElegantLightTheme.errorRed.withOpacity(0.2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.errorGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ElegantLightTheme.errorRed.withOpacity(0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Eliminar notificacion',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Estas seguro de que deseas eliminar esta notificacion? Esta accion no se puede deshacer.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: ElegantLightTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Get.back(),
                          child: Text(
                            'Cancelar',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: ElegantLightTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModernButton(
                          icon: Icons.delete_rounded,
                          label: 'Eliminar',
                          gradient: ElegantLightTheme.errorGradient,
                          onPressed: () {
                            Get.back();
                            controller.deleteNotification(notification.id);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, entities.Notification notification) {
    // Mark as read when opening
    if (!notification.isRead) {
      controller.markAsRead(notification.id);
    }

    // Navigate to detail screen
    Get.toNamed('/notifications/${notification.id}');
  }
}
