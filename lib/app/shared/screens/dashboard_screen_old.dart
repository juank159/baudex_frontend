// lib/app/shared/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/routes/app_routes.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';

class DashboardScreen extends GetView<AuthController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentRoute: AppRoutes.dashboard,
      appBar: _buildAppBar(context),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
      ),
    );
  }

  // ==================== LAYOUTS RESPONSIVOS ====================

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(context),
          SizedBox(height: context.verticalSpacing),
          _buildStatsGrid(context, crossAxisCount: 2),
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
          _buildWelcomeCard(context),
          SizedBox(height: context.verticalSpacing),
          _buildStatsGrid(context, crossAxisCount: 4),
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
          _buildWelcomeCard(context),
          SizedBox(height: context.verticalSpacing),
          _buildStatsGrid(context, crossAxisCount: 4),
          SizedBox(height: context.verticalSpacing),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildRecentActivity(context)),
              SizedBox(width: context.horizontalSpacing),
              Expanded(flex: 1, child: _buildQuickActions(context)),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== APPBAR MODERNO ====================

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.dashboard_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: Responsive.getFontSize(
                context,
                mobile: 20,
                tablet: 22,
                desktop: 24,
              ),
            ),
          ),
        ],
      ),
      actions: [
        _buildNotificationButton(context),
        const SizedBox(width: 8),
        _buildUserProfile(context),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return IconButton(
      onPressed: () => _showComingSoon('Notificaciones'),
      icon: Stack(
        children: [
          Icon(Icons.notifications_outlined, size: context.isMobile ? 22 : 24),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 10, minHeight: 10),
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
    );
  }

  Widget _buildUserProfile(BuildContext context) {
    return Obx(
      () => PopupMenuButton<String>(
        onSelected: _handleMenuAction,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).primaryColorDark,
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
                            fontSize: 14,
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
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _getRoleText(
                        controller.currentUser?.role.value ?? 'user',
                      ),
                      style: TextStyle(fontSize: 12, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.white),
              ],
            ],
          ),
        ),
        itemBuilder:
            (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 20),
                    SizedBox(width: 12),
                    Text('Mi Perfil'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
      ),
    );
  }

  // ==================== TARJETA DE BIENVENIDA ====================

  Widget _buildWelcomeCard(BuildContext context) {
    return Obx(
      () => CustomCard(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor.withValues(alpha: 0.1),
                Theme.of(context).primaryColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Hola, ${controller.currentUser?.firstName ?? 'Usuario'}!',
                      style: TextStyle(
                        fontSize: Responsive.getFontSize(
                          context,
                          mobile: 22,
                          tablet: 26,
                          desktop: 28,
                        ),
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.headlineLarge?.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bienvenido a tu sistema de gestión',
                      style: TextStyle(
                        fontSize: Responsive.getFontSize(
                          context,
                          mobile: 14,
                          tablet: 16,
                          desktop: 16,
                        ),
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!context.isMobile)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.waving_hand,
                    size: 40,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== ESTADÍSTICAS PRINCIPALES ====================

  Widget _buildStatsGrid(BuildContext context, {required int crossAxisCount}) {
    final stats = [
      _StatCard(
        title: 'Ventas Hoy',
        value: '\$24,500',
        icon: Icons.trending_up,
        color: Colors.green,
        route: AppRoutes.invoices,
      ),
      _StatCard(
        title: 'Facturas',
        value: '156',
        icon: Icons.receipt_long,
        color: Colors.orange,
        route: AppRoutes.invoices,
      ),
      _StatCard(
        title: 'Productos',
        value: '1,245',
        icon: Icons.inventory_2,
        color: Colors.blue,
        route: AppRoutes.products,
      ),
      _StatCard(
        title: 'Clientes',
        value: '8,543',
        icon: Icons.people,
        color: Colors.purple,
        route: AppRoutes.customers,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: context.isMobile ? 1.3 : 1.4,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) => _buildStatCard(context, stats[index]),
    );
  }

  Widget _buildStatCard(BuildContext context, _StatCard stat) {
    return InkWell(
      onTap: () => Get.toNamed(stat.route),
      borderRadius: BorderRadius.circular(12),
      child: CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: stat.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    stat.icon,
                    color: stat.color,
                    size: context.isMobile ? 20 : 24,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
            const Spacer(),
            Text(
              stat.value,
              style: TextStyle(
                fontSize: Responsive.getFontSize(
                  context,
                  mobile: 20,
                  tablet: 24,
                  desktop: 26,
                ),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.headlineLarge?.color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              stat.title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ACCIONES RÁPIDAS ====================

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        title: 'Nueva Factura',
        icon: Icons.receipt_long,
        color: Colors.orange,
        route: AppRoutes.invoicesWithTabs,
      ),
      _QuickAction(
        title: 'Agregar Producto',
        icon: Icons.add_box,
        color: Colors.green,
        route: AppRoutes.productsCreate,
      ),
      _QuickAction(
        title: 'Gestionar Categorías',
        icon: Icons.category,
        color: Colors.indigo,
        route: AppRoutes.categories,
      ),
      _QuickAction(
        title: 'Nuevo Cliente',
        icon: Icons.person_add,
        color: Colors.purple,
        route: AppRoutes.customersCreate,
      ),

      _QuickAction(
        title: 'Ver Reportes',
        icon: Icons.analytics,
        color: Colors.blue,
        onTap: () => _showComingSoon('Reportes'),
      ),
      _QuickAction(
        title: 'Configuraciones',
        icon: Icons.settings,
        color: Colors.grey.shade700,
        onTap: () => _showConfigurationsDialog(context),
      ),
    ];

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Acciones Rápidas',
                style: TextStyle(
                  fontSize: Responsive.getFontSize(
                    context,
                    mobile: 16,
                    tablet: 18,
                    desktop: 18,
                  ),
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.headlineLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...actions.map(
            (action) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildActionButton(context, action),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, _QuickAction action) {
    return InkWell(
      onTap: action.onTap ?? () => Get.toNamed(action.route!),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: action.color.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(8),
          color: action.color.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Icon(action.icon, color: action.color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                action.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ACTIVIDAD RECIENTE ====================

  Widget _buildRecentActivity(BuildContext context) {
    final activities = [
      _Activity(
        title: 'Nueva factura creada',
        subtitle: 'Factura #1234 por \$1,500',
        icon: Icons.receipt_long,
        color: Colors.orange,
        time: '2 min',
      ),
      _Activity(
        title: 'Pago recibido',
        subtitle: 'Factura #1230 pagada',
        icon: Icons.payment,
        color: Colors.green,
        time: '8 min',
      ),
      _Activity(
        title: 'Producto agregado',
        subtitle: 'Laptop Dell XPS agregada',
        icon: Icons.laptop,
        color: Colors.blue,
        time: '15 min',
      ),
      _Activity(
        title: 'Cliente registrado',
        subtitle: 'Juan Pérez se registró',
        icon: Icons.person_add,
        color: Colors.purple,
        time: '1 hora',
      ),
    ];

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Actividad Reciente',
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(
                        context,
                        mobile: 16,
                        tablet: 18,
                        desktop: 18,
                      ),
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.headlineLarge?.color,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _showComingSoon('Historial completo'),
                child: const Text('Ver todo'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...activities.map(
            (activity) => _buildActivityItem(context, activity),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, _Activity activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: activity.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(activity.icon, color: activity.color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  activity.subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            activity.time,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
      case 'logout':
        _showLogoutDialog();
        break;
    }
  }

  void _showComingSoon(String feature) {
    Get.snackbar(
      'Próximamente',
      '$feature estará disponible pronto',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
      icon: const Icon(Icons.info, color: Colors.blue),
      duration: const Duration(seconds: 2),
    );
  }

  void _showConfigurationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: context.isMobile ? double.infinity : 500,
            maxHeight: context.isMobile 
                ? MediaQuery.of(context).size.height * 0.7 
                : 600,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey.shade700,
                      Colors.grey.shade600,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Configuraciones del Sistema',
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(
                            context,
                            mobile: 18,
                            tablet: 20,
                            desktop: 22,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildConfigurationOption(
                        context,
                        title: 'Configuración de Facturas',
                        subtitle: 'Numeración, impuestos, formatos y valores por defecto',
                        icon: Icons.receipt_long,
                        color: Colors.orange,
                        onTap: () {
                          Navigator.of(context).pop();
                          Get.toNamed('/settings/invoice');
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildConfigurationOption(
                        context,
                        title: 'Configuración de Impresoras',
                        subtitle: 'Impresoras USB/Red, formatos de papel y configuración térmica',
                        icon: Icons.print,
                        color: Colors.blue,
                        onTap: () {
                          Navigator.of(context).pop();
                          Get.toNamed('/settings/printer');
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildConfigurationOption(
                        context,
                        title: 'Configuración de la Aplicación',
                        subtitle: 'Tema, idioma, notificaciones y datos de la empresa',
                        icon: Icons.apps,
                        color: Colors.green,
                        onTap: () {
                          Navigator.of(context).pop();
                          Get.toNamed('/settings/app');
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildConfigurationOption(
                        context,
                        title: 'Base de Datos',
                        subtitle: 'Respaldo, importación y gestión de datos locales',
                        icon: Icons.storage,
                        color: Colors.purple,
                        onTap: () {
                          Navigator.of(context).pop();
                          _showComingSoon('Gestión de Base de Datos');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigurationOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
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

  // ==================== DRAWER ELIMINADO ====================
  // El drawer ahora es manejado por AppScaffold y AppDrawer

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

// ==================== CLASES DE APOYO ====================

class _StatCard {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String route;

  _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class _QuickAction {
  final String title;
  final IconData icon;
  final Color color;
  final String? route;
  final VoidCallback? onTap;

  _QuickAction({
    required this.title,
    required this.icon,
    required this.color,
    this.route,
    this.onTap,
  });
}

class _Activity {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String time;

  _Activity({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.time,
  });
}
