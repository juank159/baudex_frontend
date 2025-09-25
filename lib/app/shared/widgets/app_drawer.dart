// lib/app/shared/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../../config/routes/app_routes.dart';
import '../controllers/app_drawer_controller.dart';
import '../models/drawer_menu_item.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../core/theme/elegant_light_theme.dart';

/// Drawer principal de la aplicación que se puede usar en cualquier pantalla
/// Incluye navegación completa y gestión de estado
class AppDrawer extends GetWidget<AppDrawerController> {
  final String? currentRoute;

  const AppDrawer({super.key, this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ElegantLightTheme.surfaceColor,
              ElegantLightTheme.surfaceColor.withOpacity(0.98),
              ElegantLightTheme.surfaceColor.withOpacity(0.95),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
          boxShadow: [
            // Sombra principal para profundidad
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              offset: const Offset(4, 0),
              blurRadius: 20,
              spreadRadius: 2,
            ),
            // Sombra secundaria para suavidad
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(2, 0),
              blurRadius: 10,
              spreadRadius: 1,
            ),
            // Brillo sutil en el borde derecho
            BoxShadow(
              color: ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.1),
              offset: const Offset(1, 0),
              blurRadius: 15,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
          child: Stack(
            children: [
              // Gradiente de fondo principal
              Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.02),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: _buildMenuItems(context),
                      ),
                    ),
                  ),
                  _buildFooter(context),
                ],
              ),
              
              // Borde derecho con brillo
              Positioned(
                right: 0,
                top: 25,
                bottom: 25,
                child: Container(
                  width: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.3),
                        ElegantLightTheme.primaryGradient.colors.last.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              
              // Borde superior sutil
              Positioned(
                top: 0,
                left: 0,
                right: 25,
                child: Container(
                  height: 0.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              
              // Borde inferior sutil
              Positioned(
                bottom: 0,
                left: 0,
                right: 25,
                child: Container(
                  height: 0.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(0.05),
                        Colors.black.withOpacity(0.02),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              
              // Resplandor interno sutil en las esquinas
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(25),
                    ),
                    gradient: RadialGradient(
                      center: const Alignment(0.8, -0.8),
                      radius: 1.2,
                      colors: [
                        Colors.white.withOpacity(0.4),
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(25),
                    ),
                    gradient: RadialGradient(
                      center: const Alignment(0.8, 0.8),
                      radius: 1.2,
                      colors: [
                        ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.2),
                        ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== HEADER ====================

  Widget _buildHeader(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1200;
    
    // Alturas responsivas
    double headerHeight;
    if (isMobile) {
      headerHeight = 180; // Más compacto en móvil
    } else if (isTablet) {
      headerHeight = 220; // Intermedio en tablet  
    } else {
      headerHeight = 250; // Completo en desktop
    }
    
    return Container(
      height: headerHeight,
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
        boxShadow: [
          ...ElegantLightTheme.elevatedShadow,
          BoxShadow(
            color: ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Efecto de fondo con gradiente adicional
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.05),
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
          // Contenido principal responsivo
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo de la app con animación Lottie centrada y responsiva
                Center(
                  child: Lottie.asset(
                    'assets/images/shopping cart.json',
                    width: isMobile ? 70 : isTablet ? 85 : 100,
                    height: isMobile ? 70 : isTablet ? 85 : 100,
                    fit: BoxFit.contain,
                    repeat: true,
                    animate: true,
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 20),

                // Nombre de la app con efecto de texto responsivo
                Center(
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        Colors.white,
                        Colors.white.withOpacity(0.8),
                      ],
                    ).createShader(bounds),
                    child: Text(
                      'Baudex',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 22 : isTablet ? 24 : 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MENU ITEMS ====================

  Widget _buildMenuItems(BuildContext context) {
    return Obx(() {
      final menuItems = controller.menuItems;
      final size = MediaQuery.of(context).size;
      final isMobile = size.width < 600;
      final isTablet = size.width >= 600 && size.width < 1200;

      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 4 : 8,
          vertical: 8,
        ),
        child: Column(
          children: [
          // Items principales
          ...menuItems
              .where(
                (item) => !item.isInSettings && !item.isInConfigurationGroup,
              )
              .map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _buildMenuItem(context, item),
                );
              }),

          // Separador elegante
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  ElegantLightTheme.textSecondary.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Grupo de Configuración
          _buildConfigurationGroup(context),

          // Items de configuración que no están en el grupo
          ...menuItems
              .where(
                (item) => item.isInSettings && !item.isInConfigurationGroup,
              )
              .map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _buildMenuItem(context, item),
                );
              }),
              
          // Espacio adicional al final
          const SizedBox(height: 20),
          ],
        ),
      );
    });
  }

  Widget _buildMenuItem(BuildContext context, DrawerMenuItem item) {
    if (item.hasSubmenu) {
      return _buildSubmenuItem(context, item);
    }

    final isSelected =
        currentRoute == item.route || Get.currentRoute == item.route;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.15),
                  ElegantLightTheme.primaryGradient.colors.last.withOpacity(0.05),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(
                color: ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.3),
                width: 1,
              )
            : null,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.2),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleMenuTap(context, item),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Icono con efecto 3D
                Obx(() {
                  final badgeCount = controller.getBadgeCount(item.id);
                  
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? ElegantLightTheme.primaryGradient
                          : LinearGradient(
                              colors: [
                                ElegantLightTheme.textSecondary.withOpacity(0.1),
                                ElegantLightTheme.textSecondary.withOpacity(0.05),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.3),
                                offset: const Offset(0, 2),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                offset: const Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                    ),
                    child: Stack(
                      children: [
                        Icon(
                          item.icon,
                          color: isSelected
                              ? Colors.white
                              : ElegantLightTheme.textSecondary,
                          size: 20,
                        ),
                        if (badgeCount > 0)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                gradient: ElegantLightTheme.errorGradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.4),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
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
                    ),
                  );
                }),
                const SizedBox(width: 16),
                
                // Texto con efectos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          color: isSelected
                              ? ElegantLightTheme.primaryGradient.colors.first
                              : ElegantLightTheme.textPrimary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 15,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (item.subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            item.subtitle!,
                            style: TextStyle(
                              fontSize: 11,
                              color: ElegantLightTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Indicador de selección
                if (isSelected)
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmenuItem(BuildContext context, DrawerMenuItem item) {
    return Obx(() {
      final isExpanded = controller.isSubmenuExpanded(item.id);
      final hasSelectedSubitem = item.submenu?.any((subitem) =>
        currentRoute == subitem.route || Get.currentRoute == subitem.route
      ) ?? false;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Column(
          children: [
            // Header del submenú con efectos 3D
            Container(
              decoration: BoxDecoration(
                gradient: hasSelectedSubitem
                    ? LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.15),
                          ElegantLightTheme.primaryGradient.colors.last.withOpacity(0.05),
                        ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(12),
                border: hasSelectedSubitem
                    ? Border.all(
                        color: ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.3),
                        width: 1,
                      )
                    : null,
                boxShadow: hasSelectedSubitem
                    ? [
                        BoxShadow(
                          color: ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.2),
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (item.route != null && item.route!.isNotEmpty) {
                      _handleMenuTap(context, item);
                    } else {
                      controller.toggleSubmenuExpanded(item.id);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Icono con badge
                        Obx(() {
                          final badgeCount = controller.getBadgeCount(item.id);
                          
                          return Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: hasSelectedSubitem
                                  ? ElegantLightTheme.primaryGradient
                                  : LinearGradient(
                                      colors: [
                                        ElegantLightTheme.textSecondary.withOpacity(0.1),
                                        ElegantLightTheme.textSecondary.withOpacity(0.05),
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: hasSelectedSubitem
                                  ? [
                                      BoxShadow(
                                        color: ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.3),
                                        offset: const Offset(0, 2),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        offset: const Offset(0, 1),
                                        blurRadius: 3,
                                      ),
                                    ],
                            ),
                            child: Stack(
                              children: [
                                Icon(
                                  item.icon,
                                  color: hasSelectedSubitem
                                      ? Colors.white
                                      : ElegantLightTheme.textSecondary,
                                  size: 20,
                                ),
                                if (badgeCount > 0)
                                  Positioned(
                                    right: -4,
                                    top: -4,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        gradient: ElegantLightTheme.errorGradient,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.4),
                                            offset: const Offset(0, 2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
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
                            ),
                          );
                        }),
                        const SizedBox(width: 16),
                        
                        // Título y subtítulo
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontWeight: hasSelectedSubitem ? FontWeight.w700 : FontWeight.w600,
                                  color: hasSelectedSubitem
                                      ? ElegantLightTheme.primaryGradient.colors.first
                                      : ElegantLightTheme.textPrimary,
                                  fontSize: 15,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              if (item.subtitle != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    item.subtitle!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: ElegantLightTheme.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        // Icono de expansión con efecto
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: ElegantLightTheme.textSecondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: ElegantLightTheme.normalAnimation,
                            child: Icon(
                              Icons.expand_more,
                              color: hasSelectedSubitem
                                  ? ElegantLightTheme.primaryGradient.colors.first
                                  : ElegantLightTheme.textSecondary,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Items del submenú con animación
            if (isExpanded && item.submenu != null)
              Container(
                margin: const EdgeInsets.only(left: 20, top: 8),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Column(
                  children: item.submenu!.map((subitem) {
                    return _buildSubmenuChild(context, subitem);
                  }).toList(),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildSubmenuChild(BuildContext context, DrawerMenuItem item) {
    final isSelected =
        currentRoute == item.route || Get.currentRoute == item.route;

    return Container(
      margin: const EdgeInsets.only(left: 12, bottom: 2),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.1),
                  ElegantLightTheme.primaryGradient.colors.last.withOpacity(0.05),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(
                color: ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.2),
                width: 1,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleMenuTap(context, item),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Icono pequeño con efecto
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.1)
                        : ElegantLightTheme.textSecondary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    item.icon,
                    size: 16,
                    color: isSelected
                        ? ElegantLightTheme.primaryGradient.colors.first
                        : ElegantLightTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Texto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? ElegantLightTheme.primaryGradient.colors.first
                              : ElegantLightTheme.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          letterSpacing: 0.1,
                        ),
                      ),
                      if (item.subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            item.subtitle!,
                            style: TextStyle(
                              fontSize: 10,
                              color: ElegantLightTheme.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Indicador pequeño
                if (isSelected)
                  Container(
                    width: 3,
                    height: 12,
                    decoration: BoxDecoration(
                      color: ElegantLightTheme.primaryGradient.colors.first,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleMenuTap(BuildContext context, DrawerMenuItem item) {
    // Si es un item con submenú, alternar expansión
    if (item.hasSubmenu && (item.route == null || item.route!.isEmpty)) {
      controller.toggleSubmenuExpanded(item.id);
      return;
    }

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
    final configItems =
        controller.menuItems
            .where((item) => item.isInConfigurationGroup)
            .toList();

    if (configItems.isEmpty) return const SizedBox.shrink();

    return Obx(() {
      final drawerController = Get.find<AppDrawerController>();
      final isExpanded = drawerController.getConfigurationExpandedState();

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Column(
          children: [
            // Header del grupo de configuración con efectos 3D
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.12),
                    ElegantLightTheme.primaryGradient.colors.last.withOpacity(0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.25),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.15),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: drawerController.toggleConfigurationExpanded,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Icono de configuración con efecto especial
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: ElegantLightTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.4),
                                offset: const Offset(0, 2),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Título y contador
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Configuración',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: ElegantLightTheme.primaryGradient.colors.first,
                                  fontSize: 15,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              Text(
                                '${configItems.length} configuraciones',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: ElegantLightTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Icono de expansión animado
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: ElegantLightTheme.normalAnimation,
                            child: Icon(
                              Icons.expand_more,
                              color: ElegantLightTheme.primaryGradient.colors.first,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Items de configuración con animación
            if (isExpanded)
              Container(
                margin: const EdgeInsets.only(left: 20, top: 8),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Column(
                  children: configItems.map((item) {
                    return _buildConfigurationItem(context, item);
                  }).toList(),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildConfigurationItem(BuildContext context, DrawerMenuItem item) {
    final isSelected =
        currentRoute == item.route || Get.currentRoute == item.route;

    return Container(
      margin: const EdgeInsets.only(left: 12, bottom: 2),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.1),
                  ElegantLightTheme.primaryGradient.colors.last.withOpacity(0.05),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(
                color: ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.2),
                width: 1,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleMenuTap(context, item),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Icono con efecto
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.1)
                        : ElegantLightTheme.textSecondary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    item.icon,
                    size: 16,
                    color: isSelected
                        ? ElegantLightTheme.primaryGradient.colors.first
                        : ElegantLightTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Texto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? ElegantLightTheme.primaryGradient.colors.first
                              : ElegantLightTheme.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          letterSpacing: 0.1,
                        ),
                      ),
                      if (item.subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            item.subtitle!,
                            style: TextStyle(
                              fontSize: 10,
                              color: ElegantLightTheme.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Indicador de selección
                if (isSelected)
                  Container(
                    width: 3,
                    height: 12,
                    decoration: BoxDecoration(
                      color: ElegantLightTheme.primaryGradient.colors.first,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== FOOTER ====================

  Widget _buildFooter(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.03),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: ElegantLightTheme.textSecondary.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Obx(() {
        final user = authController.currentUser;

        return Container(
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ElegantLightTheme.textSecondary.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar con efectos 3D
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: ElegantLightTheme.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          user?.avatar != null ? NetworkImage(user!.avatar!) : null,
                      child: user?.avatar == null
                          ? Icon(
                              Icons.person,
                              color: ElegantLightTheme.primaryGradient.colors.first,
                              size: 24,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Información del usuario
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Usuario',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: ElegantLightTheme.textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getRoleText(user?.role.value ?? 'user'),
                        style: TextStyle(
                          fontSize: 12,
                          color: ElegantLightTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Menu de opciones con efectos
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ElegantLightTheme.textSecondary.withOpacity(0.05),
                        ElegantLightTheme.textSecondary.withOpacity(0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ElegantLightTheme.textSecondary.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: PopupMenuButton<String>(
                    onSelected: (value) => _handleUserAction(value, authController),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 18,
                              color: ElegantLightTheme.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Mi Perfil',
                              style: TextStyle(
                                color: ElegantLightTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(
                              Icons.settings_outlined,
                              size: 18,
                              color: ElegantLightTheme.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Configuración',
                              style: TextStyle(
                                color: ElegantLightTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(
                              Icons.logout,
                              color: ElegantLightTheme.errorGradient.colors.first,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Cerrar Sesión',
                              style: TextStyle(
                                color: ElegantLightTheme.errorGradient.colors.first,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.more_vert,
                        color: ElegantLightTheme.textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
