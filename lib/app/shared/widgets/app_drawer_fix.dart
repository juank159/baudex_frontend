// lib/app/shared/widgets/app_drawer_fix.dart
// VERSIÓN ALTERNATIVA PARA SOLUCIONAR PROBLEMAS DEL IDE

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/routes/app_routes.dart';
import '../controllers/app_drawer_controller.dart';
import '../models/drawer_menu_item.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';

/// Drawer principal - versión sin problemas de IDE
class AppDrawerFix extends StatelessWidget {
  final String? currentRoute;
  
  const AppDrawerFix({
    super.key,
    this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    // Obtener controlador directamente
    final controller = Get.find<AppDrawerController>();
    
    return Drawer(
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildMenuItems(context, controller)),
          _buildFooter(context),
        ],
      ),
    );
  }

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
            const Text(
              'Baudex Desktop',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
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

  Widget _buildMenuItems(BuildContext context, AppDrawerController controller) {
    return Obx(() {
      final menuItems = controller.menuItems;
      
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          // Items principales
          ...menuItems.where((item) => !item.isInSettings && !item.isInConfigurationGroup).map((item) {
            return _buildMenuItem(context, item, controller);
          }),
          
          // Separador
          const Divider(height: 1),
          
          // Grupo de Configuración con implementación robusta
          _buildConfigurationGroupRobust(context, controller),
        ],
      );
    });
  }

  Widget _buildMenuItem(BuildContext context, DrawerMenuItem item, AppDrawerController controller) {
    final isSelected = currentRoute == item.route || Get.currentRoute == item.route;
    
    return ListTile(
      leading: Stack(
        children: [
          Icon(
            item.icon,
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade600,
          ),
          Obx(() {
            final badgeCount = controller.getBadgeCount(item.id);
            if (badgeCount > 0) {
              return Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
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
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      title: Text(
        item.title,
        style: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade800,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: item.subtitle != null ? Text(
        item.subtitle!,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ) : null,
      selected: isSelected,
      selectedTileColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      onTap: () => _handleMenuTap(context, item),
    );
  }

  Widget _buildConfigurationGroupRobust(BuildContext context, AppDrawerController controller) {
    final configItems = controller.menuItems
        .where((item) => item.isInConfigurationGroup)
        .toList();
    
    if (configItems.isEmpty) return const SizedBox.shrink();

    return Obx(() {
      // Usar método robusto para obtener estado
      final isExpanded = controller.getConfigurationExpandedState();
      
      return Column(
        children: [
          // Header del grupo
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
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Theme.of(context).primaryColor,
            ),
            onTap: controller.toggleConfigurationExpanded,
          ),
          
          // Items expandibles
          if (isExpanded) ...[
            Container(
              margin: const EdgeInsets.only(left: 16),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                children: configItems.map((item) {
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
    final isSelected = currentRoute == item.route || Get.currentRoute == item.route;
    
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: ListTile(
        leading: Icon(
          item.icon,
          size: 20,
          color: isSelected 
            ? Theme.of(context).primaryColor 
            : Colors.grey.shade600,
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontSize: 14,
            color: isSelected 
              ? Theme.of(context).primaryColor 
              : Colors.grey.shade800,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: item.subtitle != null ? Text(
          item.subtitle!,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ) : null,
        selected: isSelected,
        selectedTileColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        onTap: () => _handleMenuTap(context, item),
        contentPadding: const EdgeInsets.only(left: 16, right: 16),
        dense: true,
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final authController = Get.find<AuthController>();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        final user = authController.currentUser;
        
        return Column(
          children: [
            const Divider(),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                backgroundImage: user?.avatar != null 
                  ? NetworkImage(user!.avatar!) 
                  : null,
                child: user?.avatar == null 
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
                itemBuilder: (context) => [
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
                        Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: Icon(
                  Icons.more_vert,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _handleMenuTap(BuildContext context, DrawerMenuItem item) {
    Navigator.pop(context);
    
    if (item.onTap != null) {
      item.onTap!();
      return;
    }
    
    if (item.route != null && Get.currentRoute != item.route) {
      Get.toNamed(item.route!);
    }
  }

  void _handleUserAction(String action, AuthController authController) {
    switch (action) {
      case 'profile':
        Get.toNamed(AppRoutes.profile);
        break;
      case 'settings':
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