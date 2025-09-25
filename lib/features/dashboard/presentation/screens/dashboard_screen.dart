// lib/features/dashboard/presentation/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/dashboard_charts_section.dart';
import '../widgets/profitability_section.dart';
import '../widgets/recent_activity_card.dart';
import '../widgets/notifications_panel.dart';
import '../widgets/period_selector.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/config/themes/app_text_styles.dart';
import '../../../../app/shared/widgets/responsive_builder.dart';
import '../../../../app/shared/widgets/loading_overlay.dart';
import '../../../../app/shared/widgets/app_drawer.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: AppColors.textPrimary,
            ),
            onPressed: controller.refreshAll,
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
        ],
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: controller.refreshAll,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                child: Column(
                  children: [
                    // Selector de períodos horizontales
                    const PeriodSelector(),
                    const SizedBox(height: AppDimensions.spacingMedium),
                    
                    // Contenido responsivo
                    ResponsiveBuilder(
                      mobile: _buildMobileLayout(),
                      tablet: _buildTabletLayout(),
                      desktop: _buildDesktopLayout(),
                    ),
                  ],
                ),
              ),
            ),
            // Removido LoadingOverlay global para evitar bloqueo de las cards
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Charts Section unificada (incluye stats principales integradas)
        const DashboardChartsSection(),
        const SizedBox(height: AppDimensions.spacingMedium),

        // Profitability Section
        const ProfitabilitySection(),
        const SizedBox(height: AppDimensions.spacingMedium),

        // Recent Activity
        const RecentActivityCard(),
        const SizedBox(height: AppDimensions.spacingMedium),

        // Notifications
        const NotificationsPanel(),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Charts Section unificada - Primera fila (incluye stats principales integradas)
        const SizedBox(
          height: 580,
          child: DashboardChartsSection(),
        ),
        const SizedBox(height: AppDimensions.spacingLarge),

        // Profitability Section - Segunda fila
        const ProfitabilitySection(),
        const SizedBox(height: AppDimensions.spacingLarge),

        // Two column layout for activity and notifications - Tercera fila
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(flex: 2, child: RecentActivityCard()),
              const SizedBox(width: AppDimensions.spacingMedium),
              const Expanded(flex: 1, child: NotificationsPanel()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primera fila: Resumen Financiero unificado (incluye stats principales integradas)
        const SizedBox(
          height: 580, // Altura aumentada para incluir stats integradas
          child: DashboardChartsSection(),
        ),
        const SizedBox(height: AppDimensions.spacingLarge),

        // Segunda fila: Profitabilidad FIFO
        const ProfitabilitySection(),
        const SizedBox(height: AppDimensions.spacingLarge),

        // Tercera fila: Grid de componentes adicionales (2x2)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columna izquierda
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    const Expanded(child: RecentActivityCard()),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMedium),
              
              // Columna derecha
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    const Expanded(child: NotificationsPanel()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
