// lib/app/shared/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/routes/app_routes.dart';
import '../controllers/app_drawer_controller.dart';
import '../models/drawer_menu_item.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';

/// Drawer principal de la aplicación que se puede usar en cualquier pantalla
/// Incluye navegación completa y gestión de estado
class AppDrawer extends GetWidget<AppDrawerController> {
  final String? currentRoute;

  const AppDrawer({super.key, this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildMenuItems(context)),
          _buildFooter(context),
        ],
      ),
    );
  }

  // ==================== HEADER ====================

  Widget _buildHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo de la app
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.shopping_cart,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),

            // Nombre de la app
            const Text(
              'Baudex Desktop',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Subtítulo
            Text(
              'Sistema de Gestión',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== MENU ITEMS ====================

  Widget _buildMenuItems(BuildContext context) {
    return Obx(() {
      final menuItems = controller.menuItems;

      return ListView(
        padding: EdgeInsets.zero,
        children: [
          // Items principales
          ...menuItems
              .where(
                (item) => !item.isInSettings && !item.isInConfigurationGroup,
              )
              .map((item) {
                return _buildMenuItem(context, item);
              }),

          // Separador
          const Divider(height: 1),

          // Grupo de Configuración
          _buildConfigurationGroup(context),

          // Items de configuración que no están en el grupo
          ...menuItems
              .where(
                (item) => item.isInSettings && !item.isInConfigurationGroup,
              )
              .map((item) {
                return _buildMenuItem(context, item);
              }),
        ],
      );
    });
  }

  Widget _buildMenuItem(BuildContext context, DrawerMenuItem item) {
    final isSelected =
        currentRoute == item.route || Get.currentRoute == item.route;

    return ListTile(
      leading: Obx(() {
        final badgeCount = controller.getBadgeCount(item.id);

        return Stack(
          children: [
            Icon(
              item.icon,
              color:
                  isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade600,
            ),
            if (badgeCount > 0)
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
                  child: Text(
                    badgeCount > 99 ? '99+' : badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      }),
      title: Text(
        item.title,
        style: TextStyle(
          color:
              isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade800,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle:
          item.subtitle != null
              ? Text(
                item.subtitle!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              )
              : null,
      selected: isSelected,
      selectedTileColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      onTap: () => _handleMenuTap(context, item),
    );
  }

  void _handleMenuTap(BuildContext context, DrawerMenuItem item) {
    // Cerrar el drawer
    Navigator.pop(context);

    // Ejecutar acción personalizada si existe
    if (item.onTap != null) {
      item.onTap!();
      return;
    }

    // Validar que la ruta existe antes de navegar
    if (item.route != null && item.route!.isNotEmpty) {
      final currentRoute = Get.currentRoute;
      if (currentRoute != item.route) {
        try {
          Get.toNamed(item.route!);
        } catch (e) {
          print('❌ Error al navegar a ${item.route}: $e');
          Get.snackbar(
            'Error de Navegación',
            'No se pudo acceder a ${item.title}. La pantalla aún no está disponible.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange.shade100,
            colorText: Colors.orange.shade800,
            icon: const Icon(Icons.warning, color: Colors.orange),
          );
        }
      }
    } else {
      // Mostrar mensaje si la ruta no está disponible
      Get.snackbar(
        'Próximamente',
        '${item.title} estará disponible pronto.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue.shade100,
        colorText: Colors.blue.shade800,
        icon: const Icon(Icons.info, color: Colors.blue),
      );
    }
  }

  Widget _buildConfigurationGroup(BuildContext context) {
    // Obtener items de configuración del grupo
    final configItems =
        controller.menuItems
            .where((item) => item.isInConfigurationGroup)
            .toList();

    if (configItems.isEmpty) return const SizedBox.shrink();

    return Obx(() {
      // Usar método alternativo para evitar problemas del IDE con el getter
      final drawerController = Get.find<AppDrawerController>();
      final isExpanded = drawerController.getConfigurationExpandedState();

      return Column(
        children: [
          // Header del grupo de configuración
          ListTile(
            leading: Icon(
              Icons.settings,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(
              'Configuración',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
            subtitle: Text(
              '${configItems.length} configuraciones',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Theme.of(context).primaryColor,
            ),
            onTap: drawerController.toggleConfigurationExpanded,
          ),

          // Items de configuración (colapsables)
          if (isExpanded) ...[
            Container(
              margin: const EdgeInsets.only(left: 16),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                children:
                    configItems.map((item) {
                      return _buildConfigurationItem(context, item);
                    }).toList(),
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildConfigurationItem(BuildContext context, DrawerMenuItem item) {
    final isSelected =
        currentRoute == item.route || Get.currentRoute == item.route;

    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: ListTile(
        leading: Icon(
          item.icon,
          size: 20,
          color:
              isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade600,
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontSize: 14,
            color:
                isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade800,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle:
            item.subtitle != null
                ? Text(
                  item.subtitle!,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                )
                : null,
        selected: isSelected,
        selectedTileColor: Theme.of(
          context,
        ).primaryColor.withValues(alpha: 0.1),
        onTap: () => _handleMenuTap(context, item),
        contentPadding: const EdgeInsets.only(left: 16, right: 16),
        dense: true,
      ),
    );
  }

  // ==================== FOOTER ====================

  Widget _buildFooter(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        final user = authController.currentUser;

        return Column(
          children: [
            const Divider(),

            // Información del usuario
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.1),
                backgroundImage:
                    user?.avatar != null ? NetworkImage(user!.avatar!) : null,
                child:
                    user?.avatar == null
                        ? Icon(
                          Icons.person,
                          color: Theme.of(context).primaryColor,
                        )
                        : null,
              ),
              title: Text(
                user?.fullName ?? 'Usuario',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(_getRoleText(user?.role.value ?? 'user')),
              trailing: PopupMenuButton<String>(
                onSelected: (value) => _handleUserAction(value, authController),
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
                      const PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.settings_outlined, size: 20),
                            SizedBox(width: 12),
                            Text('Configuración'),
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
                            Text(
                              'Cerrar Sesión',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                child: Icon(Icons.more_vert, color: Colors.grey.shade600),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _handleUserAction(String action, AuthController authController) {
    switch (action) {
      case 'profile':
        Get.toNamed(AppRoutes.profile);
        break;
      case 'settings':
        // TODO: Implementar pantalla de configuración de usuario
        Get.snackbar(
          'Próximamente',
          'Configuración de usuario estará disponible pronto',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.blue.shade100,
          colorText: Colors.blue.shade800,
        );
        break;
      case 'logout':
        _showLogoutDialog(authController);
        break;
    }
  }

  void _showLogoutDialog(AuthController authController) {
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
              authController.logout();
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
