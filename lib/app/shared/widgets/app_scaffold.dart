// lib/app/shared/widgets/app_scaffold.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_drawer.dart';
import '../controllers/app_drawer_controller.dart';
import '../../core/utils/responsive_helper.dart';

/// Scaffold reutilizable con drawer integrado
/// Usar en cualquier pantalla principal que necesite navegación
class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final Color? backgroundColor;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool includeDrawer;
  final String? currentRoute;
  final bool resizeToAvoidBottomInset;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.includeDrawer = true,
    this.currentRoute,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    // Asegurar que el drawer controller esté registrado
    Get.lazyPut<AppDrawerController>(() => AppDrawerController());
    
    return Scaffold(
      appBar: appBar,
      drawer: includeDrawer ? _buildDrawer(context) : null,
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      backgroundColor: backgroundColor,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    // En pantallas de escritorio mostrar drawer persistente si hay espacio
    if (ResponsiveHelper.isDesktop(context)) {
      return AppDrawer(currentRoute: currentRoute);
    }
    
    // En pantallas móviles/tablet usar drawer normal
    return AppDrawer(currentRoute: currentRoute);
  }
}

/// Builder específico para AppBars con estilo consistente
class AppBarBuilder {
  static PreferredSizeWidget build({
    required String title,
    IconData? leadingIcon,
    VoidCallback? onLeadingPressed,
    List<Widget>? actions,
    bool automaticallyImplyLeading = true,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    bool centerTitle = false,
  }) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null && !automaticallyImplyLeading) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Get.theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                leadingIcon,
                color: Get.theme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor ?? Get.theme.scaffoldBackgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation ?? 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: onLeadingPressed != null && leadingIcon != null
          ? IconButton(
              icon: Icon(leadingIcon),
              onPressed: onLeadingPressed,
            )
          : null,
      actions: actions,
    );
  }

  /// AppBar moderna con gradiente
  static PreferredSizeWidget buildGradient({
    required String title,
    IconData? leadingIcon,
    List<Widget>? actions,
    bool automaticallyImplyLeading = true,
    List<Color>? gradientColors,
  }) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors ?? [
              Get.theme.primaryColor,
              Get.theme.primaryColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null && !automaticallyImplyLeading) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    leadingIcon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: automaticallyImplyLeading,
          actions: actions,
        ),
      ),
    );
  }

  /// AppBar para pantallas con búsqueda
  static PreferredSizeWidget buildWithSearch({
    required String title,
    required VoidCallback onSearchPressed,
    IconData? leadingIcon,
    List<Widget>? actions,
    bool automaticallyImplyLeading = true,
  }) {
    final searchAction = IconButton(
      icon: const Icon(Icons.search),
      onPressed: onSearchPressed,
      tooltip: 'Buscar',
    );

    final allActions = [
      searchAction,
      ...?actions,
    ];

    return build(
      title: title,
      leadingIcon: leadingIcon,
      actions: allActions,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }

  /// AppBar para formularios con acciones de guardar/cancelar
  static PreferredSizeWidget buildForm({
    required String title,
    required VoidCallback onSave,
    VoidCallback? onCancel,
    bool isLoading = false,
    IconData? leadingIcon,
  }) {
    return build(
      title: title,
      leadingIcon: leadingIcon,
      actions: [
        if (onCancel != null)
          TextButton(
            onPressed: isLoading ? null : onCancel,
            child: const Text('Cancelar'),
          ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: isLoading ? null : onSave,
          child: isLoading 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Guardar'),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}

/// Extensiones para facilitar el uso del AppScaffold
extension AppScaffoldExtensions on Widget {
  /// Envolver widget en AppScaffold con configuración básica
  Widget wrapInAppScaffold({
    PreferredSizeWidget? appBar,
    Widget? floatingActionButton,
    bool includeDrawer = true,
    String? currentRoute,
  }) {
    return AppScaffold(
      appBar: appBar,
      body: this,
      floatingActionButton: floatingActionButton,
      includeDrawer: includeDrawer,
      currentRoute: currentRoute,
    );
  }

  /// Envolver widget en AppScaffold con AppBar automática
  Widget wrapWithAppBar({
    required String title,
    IconData? leadingIcon,
    List<Widget>? actions,
    Widget? floatingActionButton,
    bool includeDrawer = true,
    String? currentRoute,
  }) {
    return AppScaffold(
      appBar: AppBarBuilder.build(
        title: title,
        leadingIcon: leadingIcon,
        actions: actions,
      ),
      body: this,
      floatingActionButton: floatingActionButton,
      includeDrawer: includeDrawer,
      currentRoute: currentRoute,
    );
  }
}