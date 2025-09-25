// lib/features/dashboard/presentation/widgets/recent_activity_card.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
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
                Obx(() => _buildActivityContent()),
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
                AppColors.primary.withOpacity(0.2),
                AppColors.primary.withOpacity(0.1),
                AppColors.primary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.timeline,
            color: AppColors.primary,
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
              'Actividad Reciente',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
          ),
        ),
        // Botón de refresh con animación
        _RefreshButton(onRefresh: controller.refreshActivity),
      ],
    );
  }

  Widget _buildActivityContent() {
    final hasAdvancedData = controller.recentActivitiesAdvanced.isNotEmpty;
    final hasBasicData = controller.recentActivities.isNotEmpty;
    final isLoading = controller.isLoadingActivity;
    final hasError = controller.activityError != null;

    if (isLoading && !hasAdvancedData && !hasBasicData) {
      return _buildModernShimmerList();
    }

    if (hasError && !hasAdvancedData && !hasBasicData) {
      return _buildModernErrorState();
    }

    if (!hasAdvancedData && !hasBasicData) {
      return _buildModernEmptyState();
    }

    return hasAdvancedData ? _buildAdvancedActivityList() : _buildActivityList();
  }

  Widget _buildActivityList() {
    return Column(
      children: [
        for (int index = 0; index < controller.recentActivities.length; index++)
          _ModernActivityItem(
            activity: controller.recentActivities[index],
            index: index,
          ),
      ],
    );
  }

  Widget _buildAdvancedActivityList() {
    return Column(
      children: [
        for (int index = 0; index < controller.recentActivitiesAdvanced.length; index++)
          _ModernAdvancedActivityItem(
            activity: controller.recentActivitiesAdvanced[index],
            index: index,
          ),
      ],
    );
  }

  Widget _buildModernShimmerList() {
    return Column(
      children: List.generate(
        4,
        (index) => Container(
          margin: EdgeInsets.only(bottom: index < 3 ? 16 : 0),
          padding: const EdgeInsets.all(20),
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
                const ShimmerContainer(width: 48, height: 48, isCircular: true),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ShimmerContainer(width: double.infinity, height: 18),
                      const SizedBox(height: 8),
                      const ShimmerContainer(width: 160, height: 14),
                      const SizedBox(height: 4),
                      const ShimmerContainer(width: 80, height: 12),
                    ],
                  ),
                ),
                const ShimmerContainer(width: 40, height: 12),
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
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Oops! Error de conexión',
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No se pudo cargar la actividad reciente',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _ModernButton(
            onPressed: controller.refreshActivity,
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
              Icons.timeline_outlined,
              color: AppColors.textSecondary,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Sin actividad reciente',
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando realices acciones en tu negocio,\naparecerán aquí automáticamente',
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
                onTapDown: (_) {
                  setState(() => _isPressed = true);
                  _controller.forward();
                },
                onTapUp: (_) {
                  setState(() => _isPressed = false);
                  _controller.reverse();
                },
                onTapCancel: () {
                  setState(() => _isPressed = false);
                  _controller.reverse();
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text(
                    widget.text,
                    style: AppTextStyles.bodyMedium.copyWith(
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

// Item de actividad moderno con animaciones
class _ModernActivityItem extends StatefulWidget {
  final RecentActivity activity;
  final int index;

  const _ModernActivityItem({
    required this.activity,
    required this.index,
  });

  @override
  State<_ModernActivityItem> createState() => _ModernActivityItemState();
}

class _ModernActivityItemState extends State<_ModernActivityItem>
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
              margin: EdgeInsets.only(bottom: widget.index < 4 ? 16 : 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isHovered
                      ? [
                          _getActivityColor().withOpacity(0.05),
                          _getActivityColor().withOpacity(0.02),
                        ]
                      : [
                          AppColors.surface.withOpacity(0.3),
                          AppColors.surface.withOpacity(0.1),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isHovered
                      ? _getActivityColor().withOpacity(0.2)
                      : AppColors.border.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: MouseRegion(
                onEnter: (_) => setState(() => _isHovered = true),
                onExit: (_) => setState(() => _isHovered = false),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      _buildActivityIcon(),
                      const SizedBox(width: 16),
                      Expanded(child: _buildActivityContent()),
                      _buildTimeLabel(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getActivityColor().withOpacity(0.15),
            _getActivityColor().withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _getActivityColor().withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        _getActivityIcon(),
        color: _getActivityColor(),
        size: 24,
      ),
    );
  }

  Widget _buildActivityContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.activity.title,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          widget.activity.description,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTimeLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        widget.activity.formattedTime,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
  }

  IconData _getActivityIcon() {
    switch (widget.activity.type) {
      case ActivityType.sale:
        return Icons.shopping_cart_rounded;
      case ActivityType.invoice:
        return Icons.receipt_long_rounded;
      case ActivityType.payment:
        return Icons.payment_rounded;
      case ActivityType.product:
        return Icons.inventory_2_rounded;
      case ActivityType.customer:
        return Icons.person_rounded;
      case ActivityType.expense:
        return Icons.money_off_rounded;
      case ActivityType.order:
        return Icons.shopping_bag_rounded;
      case ActivityType.user:
        return Icons.person_add_rounded;
      case ActivityType.system:
        return Icons.settings_rounded;
    }
  }

  Color _getActivityColor() {
    switch (widget.activity.type) {
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

// Item de actividad avanzada moderno con animaciones
class _ModernAdvancedActivityItem extends StatefulWidget {
  final advanced.RecentActivityAdvanced activity;
  final int index;

  const _ModernAdvancedActivityItem({
    required this.activity,
    required this.index,
  });

  @override
  State<_ModernAdvancedActivityItem> createState() => _ModernAdvancedActivityItemState();
}

class _ModernAdvancedActivityItemState extends State<_ModernAdvancedActivityItem>
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
              margin: EdgeInsets.only(bottom: widget.index < 4 ? 16 : 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isHovered
                      ? [
                          widget.activity.color.withOpacity(0.05),
                          widget.activity.color.withOpacity(0.02),
                        ]
                      : [
                          AppColors.surface.withOpacity(0.3),
                          AppColors.surface.withOpacity(0.1),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isHovered
                      ? widget.activity.color.withOpacity(0.2)
                      : AppColors.border.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: MouseRegion(
                onEnter: (_) => setState(() => _isHovered = true),
                onExit: (_) => setState(() => _isHovered = false),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      _buildActivityIcon(),
                      const SizedBox(width: 16),
                      Expanded(child: _buildActivityContent()),
                      _buildTimeLabel(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.activity.color.withOpacity(0.15),
            widget.activity.color.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: widget.activity.color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        _getIconFromString(widget.activity.icon),
        color: widget.activity.color,
        size: 24,
      ),
    );
  }

  Widget _buildActivityContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.activity.title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.activity.priority != advanced.ActivityPriority.normal) ...[
              const SizedBox(width: 8),
              _buildPriorityBadge(),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          widget.activity.description,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (widget.activity.userName.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'por ${widget.activity.userName}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriorityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getPriorityColor().withOpacity(0.15),
            _getPriorityColor().withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getPriorityColor().withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.activity.priority.icon,
            size: 10,
            color: _getPriorityColor(),
          ),
          const SizedBox(width: 4),
          Text(
            widget.activity.priority.displayName.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              color: _getPriorityColor(),
              fontWeight: FontWeight.w700,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        widget.activity.formattedTime,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
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
      case 'add':
        return Icons.add_rounded;
      case 'edit':
        return Icons.edit_rounded;
      case 'delete':
        return Icons.delete_rounded;
      case 'visibility':
        return Icons.visibility_rounded;
      case 'download':
        return Icons.download_rounded;
      case 'upload':
        return Icons.upload_rounded;
      case 'notification_important':
        return Icons.notification_important_rounded;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet_rounded;
      case 'schedule':
        return Icons.schedule_rounded;
      case 'report_problem':
        return Icons.report_problem_rounded;
      case 'person_add':
        return Icons.person_add_rounded;
      case 'login':
        return Icons.login_rounded;
      default:
        return Icons.circle;
    }
  }

  Color _getPriorityColor() {
    switch (widget.activity.priority) {
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