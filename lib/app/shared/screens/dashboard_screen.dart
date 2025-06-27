// ================================= DASHBOARD SCREEN ====================

//lib/app/shared/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/routes/app_routes.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/custom_card.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';

class DashboardScreen extends GetView<AuthController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
      ),
    );
  }

  // ==================== LAYOUTS PRINCIPALES ====================

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(context),
          SizedBox(height: context.verticalSpacing),
          _buildStatsGrid(context, crossAxisCount: 2),
          SizedBox(height: context.verticalSpacing),
          _buildInvoicesOverview(context),
          SizedBox(height: context.verticalSpacing),
          _buildCategoriesOverview(context),
          SizedBox(height: context.verticalSpacing),
          _buildProductsOverview(context),
          SizedBox(height: context.verticalSpacing),
          _buildCustomersOverview(context),
          SizedBox(height: context.verticalSpacing),
          _buildQuickActions(context),
          SizedBox(height: context.verticalSpacing),
          _buildRecentActivity(context),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(context),
          SizedBox(height: context.verticalSpacing),
          _buildStatsGrid(context, crossAxisCount: 4),
          SizedBox(height: context.verticalSpacing),
          _buildInvoicesOverview(context), // ✅ AGREGADO
          SizedBox(height: context.verticalSpacing),
          _buildCategoriesOverview(context),
          SizedBox(height: context.verticalSpacing),
          _buildProductsOverview(context),
          SizedBox(height: context.verticalSpacing),
          _buildCustomersOverview(context),
          SizedBox(height: context.verticalSpacing),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildQuickActions(context)),
              SizedBox(width: context.horizontalSpacing),
              Expanded(flex: 3, child: _buildRecentActivity(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(context),
          SizedBox(height: context.verticalSpacing),
          _buildStatsGrid(context, crossAxisCount: 4),
          SizedBox(height: context.verticalSpacing),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildInvoicesOverview(context), // ✅ AGREGADO
                    SizedBox(height: context.verticalSpacing),
                    _buildCategoriesOverview(context),
                    SizedBox(height: context.verticalSpacing),
                    _buildProductsOverview(context),
                    SizedBox(height: context.verticalSpacing),
                    _buildCustomersOverview(context),
                    SizedBox(height: context.verticalSpacing),
                    _buildRecentActivity(context),
                    SizedBox(height: context.verticalSpacing),
                    _buildChartsSection(context),
                  ],
                ),
              ),
              SizedBox(width: context.horizontalSpacing),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildQuickActions(context),
                    SizedBox(height: context.verticalSpacing),
                    _buildUpcomingTasks(context),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== APPBAR ====================

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: Row(
        children: [
          Icon(
            Icons.dashboard_rounded,
            color: Theme.of(context).primaryColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            'Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
        ],
      ),
      actions: [
        // Notificaciones
        IconButton(
          onPressed: () => _showNotifications(context),
          icon: Stack(
            children: [
              const Icon(Icons.notifications_outlined, size: 26),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Perfil y opciones
        Obx(
          () => PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).primaryColor,
                    backgroundImage:
                        controller.currentUser?.avatar != null
                            ? NetworkImage(controller.currentUser!.avatar!)
                            : null,
                    child:
                        controller.currentUser?.avatar == null
                            ? Text(
                              controller.currentUser?.firstName
                                      .substring(0, 1)
                                      .toUpperCase() ??
                                  'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                            : null,
                  ),
                  if (!context.isMobile) ...[
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          controller.currentUser?.firstName ?? 'Usuario',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _getRoleText(
                            controller.currentUser?.role.value ?? 'user',
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down, size: 18),
                  ],
                ],
              ),
            ),
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, color: Colors.grey.shade700),
                        const SizedBox(width: 12),
                        const Text('Mi Perfil'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(
                          Icons.settings_outlined,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 12),
                        const Text('Configuración'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 12),
                        Text(
                          'Cerrar Sesión',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  // ==================== SECCIÓN DE BIENVENIDA ====================

  Widget _buildWelcomeSection(BuildContext context) {
    return Obx(
      () => CustomCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenido de vuelta,',
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(
                        context,
                        mobile: 16,
                        tablet: 18,
                        desktop: 20,
                      ),
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.currentUser?.fullName ?? 'Usuario',
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(
                        context,
                        mobile: 24,
                        tablet: 28,
                        desktop: 32,
                      ),
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.headlineLarge?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aquí tienes un resumen de tu actividad hoy',
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(
                        context,
                        mobile: 14,
                        tablet: 16,
                        desktop: 18,
                      ),
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (!context.isMobile) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.dashboard_rounded,
                  size: 60,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== GRID DE ESTADÍSTICAS ====================

  Widget _buildStatsGrid(BuildContext context, {required int crossAxisCount}) {
    final stats = [
      _StatItem(
        title: 'Ventas Hoy',
        value: '\$24,500',
        change: '+12.5%',
        isPositive: true,
        icon: Icons.trending_up,
        color: Colors.green,
      ),
      _StatItem(
        title: 'Facturas',
        value: '156', // ✅ ACTUALIZADO: Era el último, ahora es segundo
        change: '+8.3%', // ✅ CAMBIADO: Era negativo, ahora positivo
        isPositive: true, // ✅ CAMBIADO
        icon: Icons.receipt_long_outlined,
        color: Colors.orange,
      ),
      _StatItem(
        title: 'Productos',
        value: '1,245',
        change: '+3.2%',
        isPositive: true,
        icon: Icons.inventory_2_outlined,
        color: Colors.blue,
      ),
      _StatItem(
        title: 'Clientes',
        value: '8,543',
        change: '+5.1%',
        isPositive: true,
        icon: Icons.people_outline,
        color: Colors.purple,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: context.isMobile ? 1.2 : 1.5,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) => _buildStatCard(context, stats[index]),
    );
  }

  Widget _buildStatCard(BuildContext context, _StatItem stat) {
    return CustomCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: stat.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(stat.icon, color: stat.color, size: 24),
                  ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            stat.isPositive
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        stat.change,
                        style: TextStyle(
                          color:
                              stat.isPositive
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: Text(
                  stat.value,
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(
                      context,
                      mobile: 20,
                      tablet: 24,
                      desktop: 28,
                    ),
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineLarge?.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  stat.title,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==================== SECCIÓN DE FACTURAS ====================

  Widget _buildInvoicesOverview(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInvoicesHeader(context),
          const SizedBox(height: 20),
          _buildInvoicesStats(context),
          const SizedBox(height: 16),
          _buildInvoicesValueCard(context),
          const SizedBox(height: 16),
          _buildInvoicesQuickActions(context),
          const SizedBox(height: 12),
          _buildInvoicesAlerts(context),
        ],
      ),
    );
  }

  Widget _buildInvoicesHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Gestión de Facturas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineLarge?.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () => Get.toNamed(AppRoutes.invoices),
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: const Text('Ver todas'),
        ),
      ],
    );
  }

  Widget _buildInvoicesStats(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInvoiceStatItem(
                'Total',
                '1,456',
                Icons.receipt_long_outlined,
                Colors.orange,
                () => Get.toNamed(AppRoutes.invoices),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInvoiceStatItem(
                'Pagadas',
                '1,298',
                Icons.check_circle_outline,
                Colors.green,
                () => Get.toNamed('/invoices/status/paid'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInvoiceStatItem(
                'Pendientes',
                '134',
                Icons.schedule_outlined,
                Colors.blue,
                () => Get.toNamed('/invoices/status/pending'),
              ),
            ),
            if (!context.isMobile) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _buildInvoiceStatItem(
                  'Vencidas',
                  '24',
                  Icons.warning_outlined,
                  Colors.red,
                  () => Get.toNamed(AppRoutes.invoicesOverdue),
                ),
              ),
            ],
          ],
        ),
        if (context.isMobile) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInvoiceStatItem(
                  'Vencidas',
                  '24',
                  Icons.warning_outlined,
                  Colors.red,
                  () => Get.toNamed(AppRoutes.invoicesOverdue),
                ),
              ),
              const Expanded(child: SizedBox()),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInvoiceStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoicesValueCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.monetization_on,
              color: Colors.orange,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Facturado (Mes)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  '\$147,350',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Get.toNamed(AppRoutes.invoicesStats),
            child: const Text('Ver detalles', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildInvoiceQuickAction(
            'Nueva Factura',
            Icons.add,
            Colors.teal,
            () => Get.toNamed(AppRoutes.invoicesCreate),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildInvoiceQuickAction(
            'Estadísticas',
            Icons.analytics,
            Colors.deepPurple,
            () => Get.toNamed(AppRoutes.invoicesStats),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildInvoiceQuickAction(
            'Vencidas',
            Icons.warning,
            Colors.red,
            () => Get.toNamed(AppRoutes.invoicesOverdue),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceQuickAction(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoicesAlerts(BuildContext context) {
    const int overdueCount = 24;
    const int draftCount = 8;
    const int todayDueCount = 5;

    final bool hasOverdue = overdueCount > 0;
    final bool hasDrafts = draftCount > 0;
    final bool hasTodayDue = todayDueCount > 0;
    final bool hasAnyAlert = hasOverdue || hasDrafts || hasTodayDue;

    if (!hasAnyAlert) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.05),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Facturas al día',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Alertas de facturas vencidas
        if (hasOverdue)
          Container(
            margin: EdgeInsets.only(bottom: (hasDrafts || hasTodayDue) ? 8 : 0),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: InkWell(
              onTap: () => Get.toNamed(AppRoutes.invoicesOverdue),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$overdueCount facturas vencidas',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.red.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),

        // Alertas de facturas que vencen hoy
        if (hasTodayDue)
          Container(
            margin: EdgeInsets.only(bottom: hasDrafts ? 8 : 0),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: InkWell(
              onTap: () => Get.toNamed('/invoices/status/pending'),
              child: Row(
                children: [
                  const Icon(Icons.today, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$todayDueCount facturas vencen hoy',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.orange.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),

        // Alertas de borradores pendientes
        if (hasDrafts)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: InkWell(
              onTap: () => Get.toNamed('/invoices/status/draft'),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$draftCount borradores sin enviar',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.blue.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ==================== SECCIÓN DE CATEGORÍAS ====================

  Widget _buildCategoriesOverview(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.category,
                        color: Colors.indigo,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Gestión de Categorías',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).textTheme.headlineLarge?.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.categories),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Ver todas'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildCategoryStatItem(
                  'Total',
                  '24',
                  Icons.category_outlined,
                  Colors.blue,
                  () => Get.toNamed(AppRoutes.categories),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCategoryStatItem(
                  'Activas',
                  '21',
                  Icons.check_circle_outline,
                  Colors.green,
                  () => Get.toNamed(AppRoutes.categories),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCategoryStatItem(
                  'Principales',
                  '8',
                  Icons.account_tree_outlined,
                  Colors.purple,
                  () => Get.toNamed(AppRoutes.categoriesTree),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCategoryQuickAction(
                  'Nueva Categoría',
                  Icons.add,
                  Colors.teal,
                  () => Get.toNamed(AppRoutes.categoriesCreate),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCategoryQuickAction(
                  'Ver Árbol',
                  Icons.account_tree,
                  Colors.deepPurple,
                  () => Get.toNamed(AppRoutes.categoriesTree),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryQuickAction(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SECCIÓN DE PRODUCTOS ====================

  Widget _buildProductsOverview(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductsHeader(context),
          const SizedBox(height: 20),
          _buildProductsStats(context),
          const SizedBox(height: 16),
          _buildInventoryValueCard(context),
          const SizedBox(height: 16),
          _buildProductsQuickActions(context),
          const SizedBox(height: 12),
          _buildProductsAlerts(context),
        ],
      ),
    );
  }

  Widget _buildProductsHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Gestión de Productos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineLarge?.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () => Get.toNamed(AppRoutes.products),
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: const Text('Ver todos'),
        ),
      ],
    );
  }

  Widget _buildProductsStats(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildProductStatItem(
                'Total',
                '1,245',
                Icons.inventory_2_outlined,
                Colors.blue,
                () => Get.toNamed(AppRoutes.products),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildProductStatItem(
                'En Stock',
                '1,156',
                Icons.check_circle_outline,
                Colors.green,
                () => Get.toNamed(AppRoutes.products),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildProductStatItem(
                'Stock Bajo',
                '23',
                Icons.warning_outlined,
                Colors.orange,
                () => Get.toNamed(AppRoutes.productsLowStock),
              ),
            ),
            if (!context.isMobile) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _buildProductStatItem(
                  'Agotados',
                  '12',
                  Icons.error_outline,
                  Colors.red,
                  () => Get.toNamed(AppRoutes.products),
                ),
              ),
            ],
          ],
        ),
        if (context.isMobile) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildProductStatItem(
                  'Agotados',
                  '12',
                  Icons.error_outline,
                  Colors.red,
                  () => Get.toNamed(AppRoutes.products),
                ),
              ),
              const Expanded(child: SizedBox()),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildProductStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryValueCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.attach_money,
              color: Colors.green,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Valor Total del Inventario',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  '\$2,847,350',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Get.toNamed(AppRoutes.productsStats),
            child: const Text('Ver detalles', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildProductQuickAction(
            'Nuevo Producto',
            Icons.add,
            Colors.teal,
            () => Get.toNamed(AppRoutes.productsCreate),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildProductQuickAction(
            'Estadísticas',
            Icons.analytics,
            Colors.deepPurple,
            () => Get.toNamed(AppRoutes.productsStats),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildProductQuickAction(
            'Stock Bajo',
            Icons.warning,
            Colors.orange,
            () => Get.toNamed(AppRoutes.productsLowStock),
          ),
        ),
      ],
    );
  }

  Widget _buildProductQuickAction(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsAlerts(BuildContext context) {
    const int lowStockCount = 23;
    const int outOfStockCount = 12;

    final bool hasLowStock = lowStockCount > 0;
    final bool hasOutOfStock = outOfStockCount > 0;
    final bool hasAnyAlert = hasLowStock || hasOutOfStock;

    if (!hasAnyAlert) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.05),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Inventario en buen estado',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (hasLowStock)
          Container(
            margin: EdgeInsets.only(bottom: hasOutOfStock ? 8 : 0),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: InkWell(
              onTap: () => Get.toNamed(AppRoutes.productsLowStock),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$lowStockCount productos con stock bajo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.orange.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
        if (hasOutOfStock)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: InkWell(
              onTap: () => Get.toNamed(AppRoutes.products),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$outOfStockCount productos agotados',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.red.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ==================== SECCIÓN DE CLIENTES ====================

  Widget _buildCustomersOverview(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCustomersHeader(context),
          const SizedBox(height: 20),
          _buildCustomersStats(context),
          const SizedBox(height: 16),
          _buildCustomersValueCard(context),
          const SizedBox(height: 16),
          _buildCustomersQuickActions(context),
          const SizedBox(height: 12),
          _buildCustomersIndicators(context),
        ],
      ),
    );
  }

  Widget _buildCustomersHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.people, color: Colors.purple, size: 24),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Gestión de Clientes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineLarge?.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () => Get.toNamed(AppRoutes.customers),
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: const Text('Ver todos'),
        ),
      ],
    );
  }

  Widget _buildCustomersStats(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCustomerStatItem(
                'Total',
                '8,543',
                Icons.people_outline,
                Colors.purple,
                () => Get.toNamed(AppRoutes.customers),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCustomerStatItem(
                'Activos',
                '7,892',
                Icons.person_outline,
                Colors.green,
                () => Get.toNamed(AppRoutes.customers),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCustomerStatItem(
                'Nuevos Hoy',
                '15',
                Icons.person_add_outlined,
                Colors.blue,
                () => Get.toNamed(AppRoutes.customers),
              ),
            ),
            if (!context.isMobile) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _buildCustomerStatItem(
                  'VIP',
                  '124',
                  Icons.star_outline,
                  Colors.orange,
                  () => Get.toNamed(AppRoutes.customers),
                ),
              ),
            ],
          ],
        ),
        if (context.isMobile) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCustomerStatItem(
                  'VIP',
                  '124',
                  Icons.star_outline,
                  Colors.orange,
                  () => Get.toNamed(AppRoutes.customers),
                ),
              ),
              const Expanded(child: SizedBox()),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCustomerStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomersValueCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.trending_up,
              color: Colors.purple,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Valor Promedio por Cliente',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  '\$1,842',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Get.toNamed(AppRoutes.customersStats),
            child: const Text('Ver detalles', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildCustomerQuickAction(
            'Nuevo Cliente',
            Icons.person_add,
            Colors.teal,
            () => Get.toNamed(AppRoutes.customersCreate),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCustomerQuickAction(
            'Estadísticas',
            Icons.analytics,
            Colors.deepPurple,
            () => Get.toNamed(AppRoutes.customersStats),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCustomerQuickAction(
            'Buscar',
            Icons.search,
            Colors.blue,
            () => Get.toNamed(AppRoutes.customers),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerQuickAction(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomersIndicators(BuildContext context) {
    const int newRegistrations = 15;
    const int birthdays = 3;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: InkWell(
            onTap: () => Get.toNamed(AppRoutes.customers),
            child: Row(
              children: [
                const Icon(Icons.person_add, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$newRegistrations nuevos registros hoy',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.blue.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.05),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: InkWell(
            onTap: () => Get.toNamed(AppRoutes.customers),
            child: Row(
              children: [
                const Icon(Icons.cake, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$birthdays clientes cumplen años hoy',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.orange.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== ACCIONES RÁPIDAS ====================

  Widget _buildQuickActions(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acciones Rápidas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.headlineLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            context,
            'Nueva Factura', // ✅ PRIMER LUGAR: La acción más importante
            Icons.receipt_long,
            Colors.orange, // ✅ CAMBIADO: Era azul, ahora naranja para facturas
            () => Get.toNamed(AppRoutes.invoicesCreate), // ✅ ACTUALIZADO
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context,
            'Agregar Producto',
            Icons.add_box_outlined,
            Colors.green,
            () => Get.toNamed(AppRoutes.productsCreate),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context,
            'Nuevo Cliente',
            Icons.person_add_outlined,
            Colors.purple,
            () => Get.toNamed(AppRoutes.customersCreate),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context,
            'Ver Reportes',
            Icons.analytics_outlined,
            Colors.blue, // ✅ CAMBIADO: Era naranja, ahora azul
            () => _navigateToFeature('reports'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ACTIVIDAD RECIENTE ====================

  Widget _buildRecentActivity(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Actividad Reciente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineLarge?.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () => _navigateToFeature('activity'),
                child: const Text('Ver todo'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            'Nueva factura creada', // ✅ MANTENIDO: Ya era sobre facturas
            'Factura #1234 por \$1,500',
            Icons.receipt_long,
            Colors
                .orange, // ✅ CAMBIADO: Era verde, ahora naranja para consistencia
            '2 min',
          ),
          _buildActivityItem(
            'Pago recibido', // ✅ AGREGADO: Nueva actividad de facturas
            'Factura #1230 pagada por \$2,300',
            Icons.payment,
            Colors.green,
            '8 min',
          ),
          _buildActivityItem(
            'Producto agregado',
            'Laptop Dell XPS 15 añadida al inventario',
            Icons.laptop,
            Colors.blue,
            '15 min',
          ),
          _buildActivityItem(
            'Cliente registrado',
            'Juan Pérez se registró en el sistema',
            Icons.person_add,
            Colors.purple,
            '1 hora',
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String time,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ==================== SECCIONES ADICIONALES ====================

  Widget _buildChartsSection(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ventas del Mes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.headlineLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Gráfico de ventas',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(
                    '(Próximamente)',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTasks(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tareas Pendientes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.headlineLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          _buildTaskItem('Revisar inventario', 'Hoy, 3:00 PM', false),
          _buildTaskItem('Llamar a proveedor', 'Mañana, 10:00 AM', false),
          _buildTaskItem('Actualizar precios', 'Completado', true),
        ],
      ),
    );
  }

  Widget _buildTaskItem(String title, String time, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? Colors.grey : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MÉTODOS DE ACCIÓN ====================

  void _handleMenuAction(String value) {
    switch (value) {
      case 'profile':
        Get.toNamed(AppRoutes.profile);
        break;
      case 'settings':
        _showComingSoon('Configuración');
        break;
      case 'logout':
        _showLogoutDialog();
        break;
    }
  }

  void _showNotifications(BuildContext context) {
    _showComingSoon('Notificaciones');
  }

  void _navigateToFeature(String feature) {
    switch (feature) {
      case 'products':
        Get.toNamed(AppRoutes.products);
        break;
      case 'customers':
        Get.toNamed(AppRoutes.customers);
        break;
      case 'invoices': // ✅ AGREGADO
        Get.toNamed(AppRoutes.invoices);
        break;
      case 'reports':
      case 'activity':
      default:
        _showComingSoon(feature);
        break;
    }
  }

  void _showComingSoon(String feature) {
    Get.snackbar(
      'Próximamente',
      '$feature estará disponible en una próxima actualización',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
      icon: const Icon(Icons.info, color: Colors.blue),
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.logout();
            },
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleText(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrador';
      case 'manager':
        return 'Gerente';
      case 'user':
      default:
        return 'Usuario';
    }
  }
}

// ==================== CLASE DE APOYO ====================

class _StatItem {
  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;
  final Color color;

  _StatItem({
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.icon,
    required this.color,
  });
}
