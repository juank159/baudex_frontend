// lib/features/dashboard/presentation/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/dashboard_stats_grid.dart';
import '../widgets/dashboard_charts_section.dart';
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
            Obx(
              () => LoadingOverlay(
                isLoading: controller.isLoading,
                message: 'Cargando dashboard...',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats Grid
        const DashboardStatsGrid(),
        const SizedBox(height: AppDimensions.spacingMedium),

        // Charts Section
        const DashboardChartsSection(),
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
        // Stats Grid
        const DashboardStatsGrid(),
        const SizedBox(height: AppDimensions.spacingMedium),

        // Charts Section
        const DashboardChartsSection(),
        const SizedBox(height: AppDimensions.spacingMedium),

        // Two column layout for activity and notifications
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(flex: 2, child: RecentActivityCard()),
            const SizedBox(width: AppDimensions.spacingMedium),
            const Expanded(flex: 1, child: NotificationsPanel()),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats Grid
        const DashboardStatsGrid(),
        const SizedBox(height: AppDimensions.spacingMedium),

        // Main content area with three columns
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column - Charts
            const Expanded(flex: 2, child: DashboardChartsSection()),
            const SizedBox(width: AppDimensions.spacingMedium),

            // Right column - Activity and Notifications
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  const RecentActivityCard(),
                  const SizedBox(height: AppDimensions.spacingMedium),
                  const NotificationsPanel(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
