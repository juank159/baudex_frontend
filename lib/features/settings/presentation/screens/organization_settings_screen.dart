// lib/features/settings/presentation/screens/organization_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/ui/layouts/main_layout.dart';
import '../../../../app/shared/widgets/responsive_builder.dart';
import '../controllers/organization_controller.dart';
import '../widgets/edit_organization_dialog.dart';
import '../widgets/main_warehouse_selector.dart';

class OrganizationSettingsScreen extends StatefulWidget {
  const OrganizationSettingsScreen({super.key});

  @override
  State<OrganizationSettingsScreen> createState() => _OrganizationSettingsScreenState();
}

class _OrganizationSettingsScreenState extends State<OrganizationSettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: ElegantLightTheme.normalAnimation,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: ElegantLightTheme.elasticCurve),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrganizationController>();
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Obx(
              () => controller.isLoading
                  ? _buildLoadingState()
                  : MainLayout(
                      title: _getResponsiveTitle(context),
                      showBackButton: true,
                      showDrawer: false,
                      actions: _buildAppBarActions(context),
                      body: _buildFuturisticContent(context),
                    ),
            ),
          ),
        );
      },
    );
  }

  String _getResponsiveTitle(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 600) {
      return 'Configuración';
    } else if (screenWidth < 800) {
      return 'Config. Organización';
    } else {
      return 'Configuración de Organización';
    }
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () => Get.find<OrganizationController>().loadCurrentOrganization(),
        tooltip: 'Actualizar',
      ),
      const SizedBox(width: 16),
    ];
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ElegantLightTheme.backgroundColor,
            ElegantLightTheme.backgroundColor.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: ElegantLightTheme.glowShadow,
              ),
              child: const Icon(
                Icons.corporate_fare,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Cargando configuración...',
              style: TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Preparando tu centro de organización',
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticContent(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ElegantLightTheme.backgroundColor,
            ElegantLightTheme.backgroundColor.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: ResponsiveBuilder(
        mobile: _buildMobileLayout(),
        tablet: _buildTabletLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentOrganizationCard(),
          const SizedBox(height: 24),
          const MainWarehouseSelector(),
          const SizedBox(height: 24),
          _buildQuickActionsCard(),
          const SizedBox(height: 100), // Extra space at bottom
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentOrganizationCard(),
          const SizedBox(height: 32),
          const MainWarehouseSelector(),
          const SizedBox(height: 32),
          _buildQuickActionsCard(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentOrganizationCard(),
          const SizedBox(height: 32),
          const MainWarehouseSelector(),
          const SizedBox(height: 32),
          _buildQuickActionsCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }



  Widget _buildCurrentOrganizationCard() {
    final controller = Get.find<OrganizationController>();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        
        // Responsive sizing
        bool isMobile = screenWidth < 600;
        bool isTablet = screenWidth >= 600 && screenWidth < 1000;
        
        double iconPadding = isMobile ? 10 : isTablet ? 11 : 12;
        double iconSize = isMobile ? 20 : isTablet ? 22 : 24;
        double titleFontSize = isMobile ? 16 : isTablet ? 18 : 20;
        double spacing = isMobile ? 12 : isTablet ? 14 : 16;
        double verticalSpacing = isMobile ? 18 : isTablet ? 21 : 24;
        
        return FuturisticContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(iconPadding),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.infoGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: ElegantLightTheme.glowShadow,
                    ),
                    child: Icon(
                      Icons.apartment,
                      color: Colors.white,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: Text(
                      isMobile 
                        ? 'Información\nde la Organización'
                        : 'Información de la Organización',
                      style: TextStyle(
                        color: ElegantLightTheme.textPrimary,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: verticalSpacing),
              Obx(() {
                final organization = controller.currentOrganization;
                if (organization == null) {
                  return _buildNoOrganizationWidget();
                }
                return _buildOrganizationDetails(organization);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoOrganizationWidget() {
    final controller = Get.find<OrganizationController>();
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.glassGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ElegantLightTheme.warningGradient.colors.first.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.warningGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sin Organización',
                style: TextStyle(
                  color: ElegantLightTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tu usuario no tiene una organización asignada. Esto puede causar problemas de acceso.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FuturisticButton(
            text: 'Recargar',
            icon: Icons.refresh,
            onPressed: controller.loadCurrentOrganization,
            gradient: ElegantLightTheme.primaryGradient,
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizationDetails(organization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información de suscripción
        _buildFuturisticSubscriptionCard(organization),
        const SizedBox(height: 24),
        
        // Detalles de organización
        _buildFuturisticDetailsSection(organization),
        
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FuturisticButton(
            text: 'Editar Organización',
            icon: Icons.edit,
            onPressed: () => _showEditOrganizationDialog(organization),
            gradient: ElegantLightTheme.primaryGradient,
          ),
        ),
      ],
    );
  }

  Widget _buildFuturisticDetailsSection(organization) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        
        // Responsive sizing
        bool isMobile = screenWidth < 600;
        bool isTablet = screenWidth >= 600 && screenWidth < 1000;
        
        double containerPadding = isMobile ? 16 : isTablet ? 18 : 20;
        double iconPadding = isMobile ? 6 : isTablet ? 7 : 8;
        double iconSize = isMobile ? 14 : isTablet ? 15 : 16;
        double titleFontSize = isMobile ? 14 : isTablet ? 15 : 16;
        double spacing = isMobile ? 10 : isTablet ? 11 : 12;
        double verticalSpacing = isMobile ? 16 : isTablet ? 18 : 20;
        
        return Container(
          padding: EdgeInsets.all(containerPadding),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.glassGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(iconPadding),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.successGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: Text(
                      isMobile 
                        ? 'Detalles de\nla Organización'
                        : 'Detalles de la Organización',
                      style: TextStyle(
                        color: ElegantLightTheme.textPrimary,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: verticalSpacing),
              
              _buildFuturisticDetailRow('Nombre', organization.name, Icons.business),
              _buildFuturisticDetailRow('Slug', organization.slug, Icons.link),
              _buildFuturisticDetailRow('Moneda', organization.currency, Icons.currency_exchange),
              _buildFuturisticDetailRow('Idioma', organization.locale, Icons.language),
              _buildFuturisticDetailRow('Zona Horaria', organization.timezone, Icons.access_time),
              _buildFuturisticDetailRow(
                'Estado',
                organization.isActive ? 'Activa' : 'Inactiva',
                organization.isActive ? Icons.check_circle : Icons.cancel,
                statusColor: organization.isActive 
                  ? ElegantLightTheme.successGradient.colors.first
                  : ElegantLightTheme.errorGradient.colors.first,
              ),
              if (organization.domain != null)
                _buildFuturisticDetailRow('Dominio', organization.domain!, Icons.domain),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFuturisticDetailRow(
    String label, 
    String value, 
    IconData icon, {
    Color? statusColor,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        
        // Responsive sizing
        bool isMobile = screenWidth < 600;
        bool isTablet = screenWidth >= 600 && screenWidth < 1000;
        
        double margin = isMobile ? 8 : isTablet ? 10 : 12;
        double padding = isMobile ? 10 : isTablet ? 11 : 12;
        double iconSize = isMobile ? 16 : isTablet ? 17 : 18;
        double labelFontSize = isMobile ? 12 : isTablet ? 13 : 14;
        double valueFontSize = isMobile ? 12 : isTablet ? 13 : 14;
        double spacing = isMobile ? 8 : isTablet ? 10 : 12;
        double labelWidth = isMobile ? 80 : isTablet ? 90 : 100;
        
        return Container(
          margin: EdgeInsets.only(bottom: margin),
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: ElegantLightTheme.backgroundColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: statusColor?.withValues(alpha: 0.2) ?? 
                     ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: statusColor ?? ElegantLightTheme.textSecondary,
                size: iconSize,
              ),
              SizedBox(width: spacing),
              SizedBox(
                width: labelWidth,
                child: Text(
                  '$label:',
                  style: TextStyle(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: statusColor ?? ElegantLightTheme.textPrimary,
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFuturisticSubscriptionCard(organization) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * animationValue),
          child: Opacity(
            opacity: animationValue,
            child: _buildSubscriptionCardContent(organization),
          ),
        );
      },
    );
  }

  Widget _buildSubscriptionCardContent(organization) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        
        // Responsive sizing
        bool isMobile = screenWidth < 600;
        bool isTablet = screenWidth >= 600 && screenWidth < 1000;
        
        double containerPadding = isMobile ? 16 : isTablet ? 20 : 24;
        double iconPadding = isMobile ? 8 : isTablet ? 10 : 12;
        double iconSize = isMobile ? 20 : isTablet ? 22 : 24;
        double titleFontSize = isMobile ? 16 : isTablet ? 18 : 20;
        double subtitleFontSize = isMobile ? 12 : isTablet ? 13 : 14;
        double statusFontSize = isMobile ? 10 : isTablet ? 11 : 12;
        double spacing = isMobile ? 12 : isTablet ? 14 : 16;
        double verticalSpacing = isMobile ? 18 : isTablet ? 21 : 24;
        double statusPadding = isMobile ? 8 : isTablet ? 10 : 12;
        
        return Container(
          padding: EdgeInsets.all(containerPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getSubscriptionColor(organization.subscriptionPlan),
                _getSubscriptionColor(organization.subscriptionPlan).withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _getSubscriptionColor(organization.subscriptionPlan).withValues(alpha: 0.3),
                offset: const Offset(0, 8),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(iconPadding),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getSubscriptionIcon(organization.subscriptionPlan),
                      color: Colors.white,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMobile 
                            ? 'Plan ${organization.subscriptionPlan.displayName}'
                            : 'Plan ${organization.subscriptionPlan.displayName}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isMobile ? 2 : 4),
                        Text(
                          isMobile ? 'Activa' : 'Suscripción activa',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: subtitleFontSize,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: statusPadding, 
                      vertical: statusPadding / 2
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      organization.subscriptionStatus.displayName,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: statusFontSize,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: verticalSpacing),
              
              // Barra de progreso futurista
              _buildFuturisticSubscriptionProgress(organization),
              
              SizedBox(height: verticalSpacing),
              
              // Información de fechas
              Row(
                children: [
                  Expanded(
                    child: _buildFuturisticSubscriptionInfo(
                      isMobile ? 'Días' : 'Días restantes',
                      '${organization.remainingDays}',
                      Icons.access_time,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: _buildFuturisticSubscriptionInfo(
                      organization.isTrialPlan 
                        ? (isMobile ? 'Fin trial' : 'Fecha fin trial')
                        : (isMobile ? 'Renovación' : 'Renovación'),
                      _formatDate(organization.isTrialPlan 
                        ? organization.trialEndDate 
                        : organization.subscriptionEndDate),
                      Icons.event,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFuturisticSubscriptionProgress(organization) {
    final progress = organization.subscriptionProgress;
    final remainingDays = organization.remainingDays;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              organization.isTrialPlan ? 'Progreso del trial' : 'Progreso de suscripción',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1000),
          tween: Tween<double>(begin: 0.0, end: progress),
          builder: (context, animatedValue, child) {
            return Container(
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.white.withValues(alpha: 0.2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: animatedValue,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    remainingDays <= 3 
                      ? Colors.red.shade300
                      : remainingDays <= 7
                        ? Colors.orange.shade300
                        : Colors.white,
                  ),
                  minHeight: 12,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFuturisticSubscriptionInfo(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.8),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSubscriptionColor(subscriptionPlan) {
    switch (subscriptionPlan.toString()) {
      case 'SubscriptionPlan.trial':
        return Colors.orange;
      case 'SubscriptionPlan.basic':
        return Colors.blue;
      case 'SubscriptionPlan.premium':
        return Colors.purple;
      case 'SubscriptionPlan.enterprise':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getSubscriptionIcon(subscriptionPlan) {
    switch (subscriptionPlan.toString()) {
      case 'SubscriptionPlan.trial':
        return Icons.access_time;
      case 'SubscriptionPlan.basic':
        return Icons.business;
      case 'SubscriptionPlan.premium':
        return Icons.star;
      case 'SubscriptionPlan.enterprise':
        return Icons.corporate_fare;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showEditOrganizationDialog(organization) {
    Get.dialog(EditOrganizationDialog(organization: organization));
  }

  Widget _buildQuickActionsCard() {
    return FuturisticContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Acciones Rápidas',
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          _buildQuickActionButton(
            'Exportar Datos',
            'Funcionalidad en desarrollo',
            Icons.download,
            ElegantLightTheme.primaryGradient,
            _showDevelopmentDialog,
          ),
          const SizedBox(height: 12),
          _buildQuickActionButton(
            'Generar Reporte',
            'Funcionalidad en desarrollo',
            Icons.analytics,
            ElegantLightTheme.infoGradient,
            _showDevelopmentDialog,
          ),
          const SizedBox(height: 12),
          _buildQuickActionButton(
            'Configurar API',
            'Funcionalidad en desarrollo',
            Icons.key,
            ElegantLightTheme.warningGradient,
            _showDevelopmentDialog,
          ),
          const SizedBox(height: 12),
          _buildQuickActionButton(
            'Soporte Técnico',
            'Funcionalidad en desarrollo',
            Icons.support_agent,
            ElegantLightTheme.successGradient,
            _showDevelopmentDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String title,
    String subtitle,
    IconData icon,
    LinearGradient gradient,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showDevelopmentDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.warningGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.construction,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'En Desarrollo',
              style: TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: const Text(
          'Esta funcionalidad está actualmente en desarrollo y estará disponible en futuras versiones.',
          style: TextStyle(
            color: ElegantLightTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Entendido',
              style: TextStyle(
                color: ElegantLightTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
