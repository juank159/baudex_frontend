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
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/shared/widgets/shimmer_loading.dart';

class RecentActivityCard extends GetView<DashboardController> {
  const RecentActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: ElegantLightTheme.cardGradient,
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          ...ElegantLightTheme.elevatedShadow,
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 25,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ElegantLightTheme.primaryBlue.withValues(alpha: 0.02),
                Colors.transparent,
                ElegantLightTheme.warningGradient.colors.first.withValues(alpha: 0.01),
              ],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
              final padding = isMobile ? 16.0 : (isTablet ? 20.0 : 24.0);
              final headerSpacing = isMobile ? 16.0 : (isTablet ? 20.0 : 24.0);
              
              return Padding(
                padding: EdgeInsets.all(padding), // Responsive padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFuturisticHeader(),
                    SizedBox(height: headerSpacing), // Responsive spacing
                    Obx(() => _buildActivityContent()),
                  ],
                ),
              );
            },
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

  Widget _buildFuturisticHeader() {
    return Row(
      children: [
        // Icono principal futurístico
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.warningGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              ...ElegantLightTheme.glowShadow,
              BoxShadow(
                color: ElegantLightTheme.warningGradient.colors.first.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.electric_bolt,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        // Título futurístico con degradado
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => ElegantLightTheme.warningGradient.createShader(bounds),
                child: Text(
                  'Actividad Reciente',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      gradient: ElegantLightTheme.successGradient,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Últimas transacciones',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: ElegantLightTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Botón de refresh futurístico
        _FuturisticActivityRefreshButton(onRefresh: controller.refreshActivity),
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

// Botón de refresh futurístico para actividades
class _FuturisticActivityRefreshButton extends StatefulWidget {
  final VoidCallback onRefresh;

  const _FuturisticActivityRefreshButton({required this.onRefresh});

  @override
  State<_FuturisticActivityRefreshButton> createState() => _FuturisticActivityRefreshButtonState();
}

class _FuturisticActivityRefreshButtonState extends State<_FuturisticActivityRefreshButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
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
        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: _isHovered
                      ? ElegantLightTheme.warningGradient
                      : ElegantLightTheme.glassGradient,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ElegantLightTheme.warningGradient.colors.first
                        .withValues(alpha: _isHovered ? 0.4 : 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    ...ElegantLightTheme.elevatedShadow,
                    if (_isHovered || _glowAnimation.value > 0)
                      BoxShadow(
                        color: ElegantLightTheme.warningGradient.colors.first
                            .withValues(alpha: (_glowAnimation.value * 0.4).clamp(0.0, 1.0)),
                        blurRadius: (20 * _glowAnimation.value).clamp(0.0, 20.0),
                        offset: const Offset(0, 0),
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
                      widget.onRefresh();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: _isHovered
                            ? LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.2),
                                  Colors.white.withValues(alpha: 0.1),
                                ],
                              )
                            : null,
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        color: _isHovered
                            ? Colors.white
                            : ElegantLightTheme.warningGradient.colors.first,
                        size: 22,
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
            child: Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final isMobile = screenWidth < 600;
                final isTablet = screenWidth >= 600 && screenWidth < 900;
                
                // Responsive spacing and sizing
                final bottomMargin = isMobile ? 8.0 : (isTablet ? 12.0 : 16.0);
                final padding = isMobile ? 12.0 : (isTablet ? 16.0 : 20.0);
                final iconSpacing = isMobile ? 12.0 : (isTablet ? 14.0 : 16.0);
                final borderRadius = isMobile ? 12.0 : 16.0;
                
                return Container(
                  margin: EdgeInsets.only(bottom: widget.index < 4 ? bottomMargin : 0),
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
                    borderRadius: BorderRadius.circular(borderRadius),
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
                      padding: EdgeInsets.all(padding),
                      child: Row(
                        children: [
                          _buildActivityIcon(),
                          SizedBox(width: iconSpacing),
                          Expanded(child: _buildActivityContent()),
                          _buildTimeLabel(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityIcon() {
    final activityColor = _getActivityColor();
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 900;
        
        // Responsive sizes
        final iconSize = isMobile ? 36.0 : (isTablet ? 40.0 : 48.0);
        final iconRadius = iconSize / 2;
        final innerIconSize = isMobile ? 18.0 : (isTablet ? 20.0 : 24.0);
        
        return Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                activityColor.withOpacity(0.20),
                activityColor.withOpacity(0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(iconRadius),
            boxShadow: [
              BoxShadow(
                color: activityColor.withOpacity(0.3),
                blurRadius: isMobile ? 8 : (isTablet ? 10 : 12),
                offset: Offset(0, isMobile ? 4 : (isTablet ? 5 : 6)),
                spreadRadius: isMobile ? 0.5 : 1,
              ),
              if (widget.activity.type == ActivityType.invoice || 
                  widget.activity.type == ActivityType.expense)
                BoxShadow(
                  color: activityColor.withOpacity(0.15),
                  blurRadius: isMobile ? 15 : (isTablet ? 18 : 20),
                  offset: Offset(0, isMobile ? 6 : (isTablet ? 7 : 8)),
                  spreadRadius: isMobile ? 1 : 2,
                ),
            ],
          ),
          child: Icon(
            _getActivityIcon(),
            color: activityColor,
            size: innerIconSize,
          ),
        );
      },
    );
  }

  Widget _buildActivityContent() {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 900;
        
        // Responsive font sizes
        final titleFontSize = isMobile ? 13.0 : (isTablet ? 14.0 : 15.0);
        final descriptionFontSize = isMobile ? 11.0 : (isTablet ? 12.0 : 13.0);
        final spacing = isMobile ? 2.0 : (isTablet ? 3.0 : 4.0);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.activity.title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: titleFontSize,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: spacing),
            Text(
              widget.activity.description,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: descriptionFontSize,
              ),
              maxLines: isMobile ? 1 : 2, // Solo 1 línea en móvil para más compacto
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeLabel() {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 900;
        
        // Responsive sizes
        final fontSize = isMobile ? 9.0 : (isTablet ? 10.0 : 11.0);
        final horizontalPadding = isMobile ? 6.0 : (isTablet ? 7.0 : 8.0);
        final verticalPadding = isMobile ? 3.0 : 4.0;
        final borderRadius = isMobile ? 6.0 : 8.0;
        
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding, 
            vertical: verticalPadding
          ),
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Text(
            widget.activity.formattedTime,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: fontSize,
            ),
          ),
        );
      },
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
        return AppColors.success; // Verde para facturas
      case ActivityType.payment:
        return AppColors.info;
      case ActivityType.product:
        return AppColors.warning;
      case ActivityType.customer:
        return AppColors.info;
      case ActivityType.expense:
        return AppColors.error; // Rojo para gastos
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
            child: Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final isMobile = screenWidth < 600;
                final isTablet = screenWidth >= 600 && screenWidth < 900;
                
                // Responsive spacing and sizing
                final bottomMargin = isMobile ? 8.0 : (isTablet ? 12.0 : 16.0);
                final padding = isMobile ? 12.0 : (isTablet ? 16.0 : 20.0);
                final iconSpacing = isMobile ? 12.0 : (isTablet ? 14.0 : 16.0);
                final borderRadius = isMobile ? 12.0 : 16.0;
                
                return Container(
                  margin: EdgeInsets.only(bottom: widget.index < 4 ? bottomMargin : 0),
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
                    borderRadius: BorderRadius.circular(borderRadius),
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
                      padding: EdgeInsets.all(padding),
                      child: Row(
                        children: [
                          _buildActivityIcon(),
                          SizedBox(width: iconSpacing),
                          Expanded(child: _buildActivityContent()),
                          _buildTimeLabel(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityIcon() {
    // Determinar si es factura o gasto basado en el tipo de actividad
    final isInvoice = widget.activity.title.toLowerCase().contains('factura') || 
                     widget.activity.icon.contains('receipt');
    final isExpense = widget.activity.title.toLowerCase().contains('gasto') || 
                     widget.activity.icon.contains('money_off');
    
    // Usar colores específicos para facturas (verde) y gastos (rojo)
    final activityColor = isInvoice 
        ? AppColors.success 
        : isExpense 
            ? AppColors.error 
            : widget.activity.color;
    
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 900;
        
        // Responsive sizes
        final iconSize = isMobile ? 36.0 : (isTablet ? 40.0 : 48.0);
        final iconRadius = iconSize / 2;
        final innerIconSize = isMobile ? 18.0 : (isTablet ? 20.0 : 24.0);
        
        return Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                activityColor.withOpacity(0.20),
                activityColor.withOpacity(0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(iconRadius),
            boxShadow: [
              BoxShadow(
                color: activityColor.withOpacity(0.3),
                blurRadius: isMobile ? 8 : (isTablet ? 10 : 12),
                offset: Offset(0, isMobile ? 4 : (isTablet ? 5 : 6)),
                spreadRadius: isMobile ? 0.5 : 1,
              ),
              if (isInvoice || isExpense)
                BoxShadow(
                  color: activityColor.withOpacity(0.15),
                  blurRadius: isMobile ? 15 : (isTablet ? 18 : 20),
                  offset: Offset(0, isMobile ? 6 : (isTablet ? 7 : 8)),
                  spreadRadius: isMobile ? 1 : 2,
                ),
            ],
          ),
          child: Icon(
            _getIconFromString(widget.activity.icon),
            color: activityColor,
            size: innerIconSize,
          ),
        );
      },
    );
  }

  Widget _buildActivityContent() {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 900;
        
        // Responsive font sizes
        final titleFontSize = isMobile ? 13.0 : (isTablet ? 14.0 : 15.0);
        final descriptionFontSize = isMobile ? 11.0 : (isTablet ? 12.0 : 13.0);
        final userNameFontSize = isMobile ? 9.0 : (isTablet ? 10.0 : 11.0);
        final spacing = isMobile ? 2.0 : (isTablet ? 3.0 : 4.0);
        final badgeSpacing = isMobile ? 6.0 : 8.0;
        
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
                      fontSize: titleFontSize,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.activity.priority != advanced.ActivityPriority.normal) ...[
                  SizedBox(width: badgeSpacing),
                  _buildPriorityBadge(),
                ],
              ],
            ),
            SizedBox(height: spacing),
            Text(
              widget.activity.description,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: descriptionFontSize,
              ),
              maxLines: isMobile ? 1 : 2, // Solo 1 línea en móvil para más compacto
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.activity.userName.isNotEmpty) ...[
              SizedBox(height: spacing),
              Text(
                'por ${widget.activity.userName}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                  fontSize: userNameFontSize,
                ),
              ),
            ],
          ],
        );
      },
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
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 900;
        
        // Responsive sizes
        final fontSize = isMobile ? 9.0 : (isTablet ? 10.0 : 11.0);
        final horizontalPadding = isMobile ? 6.0 : (isTablet ? 7.0 : 8.0);
        final verticalPadding = isMobile ? 3.0 : 4.0;
        final borderRadius = isMobile ? 6.0 : 8.0;
        
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding, 
            vertical: verticalPadding
          ),
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Text(
            widget.activity.formattedTime,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: fontSize,
            ),
          ),
        );
      },
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