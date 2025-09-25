// lib/features/dashboard/presentation/widgets/notifications_panel.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surface.withOpacity(0.95),
            AppColors.surface.withOpacity(0.9),
          ],
        ),
        boxShadow: [
          // Sombra principal profunda
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          // Sombra secundaria para elevación
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
          // Brillo superior sutil
          BoxShadow(
            color: Colors.white.withOpacity(0.3),
            blurRadius: 1,
            offset: const Offset(0, -1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            // Gradiente interno para profundidad
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.transparent,
                Colors.black.withOpacity(0.02),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                Obx(() => _buildNotificationsContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Icono principal con efecto 3D
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.info.withOpacity(0.2),
                AppColors.info.withOpacity(0.1),
                AppColors.info.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.info.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.notifications_rounded,
            color: AppColors.info,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        // Título con efectos de texto
        Expanded(
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                AppColors.textPrimary,
                AppColors.textPrimary.withOpacity(0.8),
              ],
            ).createShader(bounds),
            child: Text(
              'Notificaciones',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
          ),
        ),
        // Badge de notificaciones no leídas
        Obx(() => controller.unreadNotificationsCount > 0
            ? _UnreadBadge(count: controller.unreadNotificationsCount)
            : const SizedBox.shrink()),
        const SizedBox(width: 8),
        // Botón de refresh con animación
        _RefreshButton(onRefresh: controller.refreshNotifications),
      ],
    );
  }

  Widget _buildNotificationsContent() {
    final hasAdvancedData = controller.smartNotifications.isNotEmpty;
    final hasBasicData = controller.notifications.isNotEmpty;
    final isLoading = controller.isLoadingNotifications;
    final hasError = controller.notificationsError != null;

    if (isLoading && !hasAdvancedData && !hasBasicData) {
      return _buildModernShimmerList();
    }

    if (hasError && !hasAdvancedData && !hasBasicData) {
      return _buildModernErrorState();
    }

    if (!hasAdvancedData && !hasBasicData) {
      return _buildModernEmptyState();
    }

    return hasAdvancedData ? _buildAdvancedNotificationsList() : _buildNotificationsList();
  }

  Widget _buildNotificationsList() {
    final displayNotifications = controller.notifications.take(4).toList();
    
    return Column(
      children: [
        for (int index = 0; index < displayNotifications.length; index++)
          _ModernNotificationItem(
            notification: displayNotifications[index],
            index: index,
            onTap: () => controller.markNotificationAsRead(displayNotifications[index].id),
          ),
        if (controller.notifications.length > 4) ...[
          const SizedBox(height: 16),
          _ViewAllButton(
            count: controller.notifications.length,
            onPressed: () => Get.toNamed('/notifications'),
          ),
        ],
      ],
    );
  }

  Widget _buildAdvancedNotificationsList() {
    final displayNotifications = controller.smartNotifications.take(4).toList();
    
    return Column(
      children: [
        for (int index = 0; index < displayNotifications.length; index++)
          _ModernSmartNotificationItem(
            notification: displayNotifications[index],
            index: index,
            onTap: () {
              if (displayNotifications[index].actionUrl != null) {
                // TODO: Navigate to action URL or perform action
              }
            },
          ),
        if (controller.smartNotifications.length > 4) ...[
          const SizedBox(height: 16),
          _ViewAllButton(
            count: controller.smartNotifications.length,
            onPressed: () => Get.toNamed('/notifications'),
          ),
        ],
      ],
    );
  }

  Widget _buildModernShimmerList() {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: EdgeInsets.only(bottom: index < 2 ? 14 : 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surface.withOpacity(0.3),
                AppColors.surface.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: ShimmerLoading(
            child: Row(
              children: [
                const ShimmerContainer(width: 40, height: 40, isCircular: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ShimmerContainer(width: double.infinity, height: 16),
                      const SizedBox(height: 6),
                      const ShimmerContainer(width: 140, height: 14),
                      const SizedBox(height: 4),
                      const ShimmerContainer(width: 60, height: 12),
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

  Widget _buildModernErrorState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono de error con efecto glassmorphism
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.error.withOpacity(0.1),
                  AppColors.error.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: AppColors.error.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              color: AppColors.error,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Error de conexión',
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No se pudieron cargar las notificaciones',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _ModernButton(
            onPressed: controller.refreshNotifications,
            text: 'Reintentar',
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildModernEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono vacío con efecto glassmorphism
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.textSecondary.withOpacity(0.1),
                  AppColors.textSecondary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: AppColors.textSecondary.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textSecondary,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Sin notificaciones',
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Te notificaremos cuando haya\nnoticias importantes',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Badge de notificaciones no leídas con animación
class _UnreadBadge extends StatefulWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  State<_UnreadBadge> createState() => _UnreadBadgeState();
}

class _UnreadBadgeState extends State<_UnreadBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _controller.forward();
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.error,
                  AppColors.error.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.error.withOpacity(0.4 * _pulseAnimation.value),
                  blurRadius: 8 * _pulseAnimation.value,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              widget.count.toString(),
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Widget del botón de refresh con animación
class _RefreshButton extends StatefulWidget {
  final VoidCallback onRefresh;

  const _RefreshButton({required this.onRefresh});

  @override
  State<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<_RefreshButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.textSecondary.withOpacity(0.1),
                    AppColors.textSecondary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.border.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () {
                    _controller.forward().then((_) {
                      _controller.reverse();
                    });
                    widget.onRefresh();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Icon(
                    Icons.refresh_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Botón moderno reutilizable
class _ModernButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  final Color color;

  const _ModernButton({
    required this.onPressed,
    required this.text,
    required this.color,
  });

  @override
  State<_ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<_ModernButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.color,
                  widget.color.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {
                  _controller.forward().then((_) {
                    _controller.reverse();
                  });
                  widget.onPressed();
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    widget.text,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Botón "Ver todas" moderno
class _ViewAllButton extends StatefulWidget {
  final int count;
  final VoidCallback onPressed;

  const _ViewAllButton({
    required this.count,
    required this.onPressed,
  });

  @override
  State<_ViewAllButton> createState() => _ViewAllButtonState();
}

class _ViewAllButtonState extends State<_ViewAllButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {
                  _controller.forward().then((_) {
                    _controller.reverse();
                  });
                  widget.onPressed();
                },
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Ver todas (${widget.count})',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.primary,
                      size: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Item de notificación moderno con animaciones
class _ModernNotificationItem extends StatefulWidget {
  final dashboard.Notification notification;
  final int index;
  final VoidCallback onTap;

  const _ModernNotificationItem({
    required this.notification,
    required this.index,
    required this.onTap,
  });

  @override
  State<_ModernNotificationItem> createState() => _ModernNotificationItemState();
}

class _ModernNotificationItemState extends State<_ModernNotificationItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300 + (widget.index * 100)),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Iniciar animación con delay
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value, 0),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: EdgeInsets.only(bottom: widget.index < 3 ? 12 : 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isHovered
                      ? [
                          _getPriorityColor().withOpacity(0.05),
                          _getPriorityColor().withOpacity(0.02),
                        ]
                      : [
                          AppColors.surface.withOpacity(0.3),
                          AppColors.surface.withOpacity(0.1),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isHovered
                      ? _getPriorityColor().withOpacity(0.2)
                      : AppColors.border.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: MouseRegion(
                onEnter: (_) => setState(() => _isHovered = true),
                onExit: (_) => setState(() => _isHovered = false),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _buildNotificationIcon(),
                          const SizedBox(width: 12),
                          Expanded(child: _buildNotificationContent()),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getPriorityColor().withOpacity(0.15),
            _getPriorityColor().withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getPriorityColor().withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        _getTypeIcon(),
        color: _getPriorityColor(),
        size: 20,
      ),
    );
  }

  Widget _buildNotificationContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.notification.title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: widget.notification.isRead
                      ? FontWeight.w500
                      : FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!widget.notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getPriorityColor(),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          widget.notification.message,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getPriorityColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getPriorityText(),
                style: AppTextStyles.caption.copyWith(
                  color: _getPriorityColor(),
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.schedule_rounded,
              size: 11,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              widget.notification.formattedTime,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getPriorityColor() {
    switch (widget.notification.priority) {
      case dashboard.NotificationPriority.urgent:
        return AppColors.error;
      case dashboard.NotificationPriority.high:
        return Colors.orange;
      case dashboard.NotificationPriority.medium:
        return AppColors.warning;
      case dashboard.NotificationPriority.low:
        return AppColors.info;
    }
  }

  String _getPriorityText() {
    switch (widget.notification.priority) {
      case dashboard.NotificationPriority.urgent:
        return 'URGENTE';
      case dashboard.NotificationPriority.high:
        return 'ALTA';
      case dashboard.NotificationPriority.medium:
        return 'MEDIA';
      case dashboard.NotificationPriority.low:
        return 'BAJA';
    }
  }

  IconData _getTypeIcon() {
    switch (widget.notification.type) {
      case dashboard.NotificationType.sale:
        return Icons.shopping_cart_rounded;
      case dashboard.NotificationType.invoice:
        return Icons.receipt_long_rounded;
      case dashboard.NotificationType.payment:
        return Icons.payment_rounded;
      case dashboard.NotificationType.lowStock:
        return Icons.inventory_2_rounded;
      case dashboard.NotificationType.expense:
        return Icons.money_off_rounded;
      case dashboard.NotificationType.user:
        return Icons.person_rounded;
      case dashboard.NotificationType.system:
        return Icons.settings_rounded;
      case dashboard.NotificationType.reminder:
        return Icons.alarm_rounded;
    }
  }
}

// Item de notificación inteligente moderno con animaciones
class _ModernSmartNotificationItem extends StatefulWidget {
  final SmartNotification notification;
  final int index;
  final VoidCallback onTap;

  const _ModernSmartNotificationItem({
    required this.notification,
    required this.index,
    required this.onTap,
  });

  @override
  State<_ModernSmartNotificationItem> createState() => _ModernSmartNotificationItemState();
}

class _ModernSmartNotificationItemState extends State<_ModernSmartNotificationItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300 + (widget.index * 100)),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Iniciar animación con delay
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value, 0),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: EdgeInsets.only(bottom: widget.index < 3 ? 12 : 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isHovered
                      ? [
                          widget.notification.color.withOpacity(0.05),
                          widget.notification.color.withOpacity(0.02),
                        ]
                      : [
                          AppColors.surface.withOpacity(0.3),
                          AppColors.surface.withOpacity(0.1),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isHovered
                      ? widget.notification.color.withOpacity(0.2)
                      : AppColors.border.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: MouseRegion(
                onEnter: (_) => setState(() => _isHovered = true),
                onExit: (_) => setState(() => _isHovered = false),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _buildNotificationIcon(),
                          const SizedBox(width: 12),
                          Expanded(child: _buildNotificationContent()),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.notification.color.withOpacity(0.15),
            widget.notification.color.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: widget.notification.color.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        _getIconFromString(widget.notification.icon),
        color: widget.notification.color,
        size: 20,
      ),
    );
  }

  Widget _buildNotificationContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.notification.title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: widget.notification.isRead
                      ? FontWeight.w500
                      : FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!widget.notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.notification.priorityColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          widget.notification.message,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (widget.notification.priority != NotificationPriority.normal) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.notification.priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.notification.priority.displayName.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                    color: widget.notification.priorityColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.schedule_rounded,
              size: 11,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              widget.notification.formattedTime,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
            if (widget.notification.actionLabel != null) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.primary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.notification.actionLabel!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'receipt':
      case 'receipt_long':
        return Icons.receipt_long_rounded;
      case 'payment':
        return Icons.payment_rounded;
      case 'shopping_cart':
        return Icons.shopping_cart_rounded;
      case 'inventory_2':
        return Icons.inventory_2_rounded;
      case 'person':
        return Icons.person_rounded;
      case 'money_off':
        return Icons.money_off_rounded;
      case 'category':
        return Icons.category_rounded;
      case 'business':
        return Icons.business_rounded;
      case 'settings':
        return Icons.settings_rounded;
      case 'security':
        return Icons.security_rounded;
      case 'error':
        return Icons.error_rounded;
      case 'info':
        return Icons.info_rounded;
      case 'warning':
        return Icons.warning_rounded;
      case 'check_circle':
        return Icons.check_circle_rounded;
      case 'sync':
        return Icons.sync_rounded;
      case 'backup':
        return Icons.backup_rounded;
      case 'analytics':
        return Icons.analytics_rounded;
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'notification_important':
        return Icons.notification_important_rounded;
      case 'alarm':
        return Icons.alarm_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}