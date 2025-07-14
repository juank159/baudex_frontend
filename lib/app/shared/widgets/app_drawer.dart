// lib/app/shared/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/routes/app_routes.dart';
import '../controllers/app_drawer_controller.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';

/// Drawer principal de la aplicación que se puede usar en cualquier pantalla
/// Incluye navegación completa y gestión de estado
class AppDrawer extends GetWidget<AppDrawerController> {
  final String? currentRoute;
  
  const AppDrawer({
    super.key,
    this.currentRoute,
  });

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
      child: Container(
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
          ...menuItems.where((item) => !item.isInSettings).map((item) {
            return _buildMenuItem(context, item);
          }),
          
          // Separador
          const Divider(height: 1),
          
          // Items de configuración
          ...menuItems.where((item) => item.isInSettings).map((item) {
            return _buildMenuItem(context, item);
          }),
        ],
      );
    });
  }

  Widget _buildMenuItem(BuildContext context, DrawerMenuItem item) {
    final isSelected = currentRoute == item.route || Get.currentRoute == item.route;
    
    return ListTile(
      leading: Obx(() {
        final badgeCount = controller.getBadgeCount(item.id);
        
        return Stack(
          children: [
            Icon(
              item.icon,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade600,
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
              ),
          ],
        );
      }),
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

  void _handleMenuTap(BuildContext context, DrawerMenuItem item) {
    // Cerrar el drawer
    Navigator.pop(context);
    
    // Ejecutar acción personalizada si existe
    if (item.onTap != null) {
      item.onTap!();
      return;
    }
    
    // Navegar si no es la ruta actual
    if (item.route != null && Get.currentRoute != item.route) {
      Get.toNamed(item.route!);
    }
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

// ==================== MODELO DE ITEM DEL MENU ====================

class DrawerMenuItem {
  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;
  final String? route;
  final VoidCallback? onTap;
  final bool isInSettings;
  final bool isEnabled;
  
  const DrawerMenuItem({
    required this.id,
    required this.title,
    required this.icon,
    this.subtitle,
    this.route,
    this.onTap,
    this.isInSettings = false,
    this.isEnabled = true,
  });

  DrawerMenuItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    IconData? icon,
    String? route,
    VoidCallback? onTap,
    bool? isInSettings,
    bool? isEnabled,
  }) {
    return DrawerMenuItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      route: route ?? this.route,
      onTap: onTap ?? this.onTap,
      isInSettings: isInSettings ?? this.isInSettings,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}