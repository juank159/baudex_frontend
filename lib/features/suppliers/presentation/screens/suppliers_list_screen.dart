// lib/features/suppliers/presentation/screens/suppliers_list_screen.dart
import 'package:baudex_desktop/app/ui/layouts/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/suppliers_controller.dart';
import '../widgets/supplier_card_widget.dart';
import '../widgets/supplier_filter_widget.dart';
import '../widgets/supplier_stats_widget.dart';

class SuppliersListScreen extends GetView<SuppliersController> {
  const SuppliersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Proveedores',
      actions: [],
      floatingActionButton: _buildFloatingActionButton(context),
      body:
          ResponsiveHelper.isMobile(context)
              ? _buildMobileLayout(context)
              : _buildDesktopLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.suppliers.isEmpty) {
        return const Center(child: LoadingWidget());
      }

      return Column(
        children: [
          // Estadísticas compactas
          if (controller.stats.value != null)
            SupplierStatsWidget(
              stats: controller.stats.value!,
              isCompact: true,
            ),

          // Búsqueda compacta
          _buildMobileSearch(context),

          // Lista de proveedores
          Expanded(child: _buildSuppliersList(context)),
        ],
      );
    });
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Obx(() {
      if (controller.isLoading.value && controller.suppliers.isEmpty) {
        return const Center(child: LoadingWidget());
      }

      return Row(
        children: [
          // Panel lateral - SOLO EN DESKTOP
          if (isDesktop)
            Container(
              width: 320,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(right: BorderSide(color: Colors.grey.shade300)),
              ),
              child: _buildSidebarContent(context),
            ),

          // Área principal
          Expanded(
            child: Column(
              children: [
                // Toolbar superior adaptable (solo desktop)
                if (isDesktop) _buildDesktopToolbar(context),

                // Banner compacto de resumen
                if (controller.stats.value != null)
                  SupplierStatsWidget(
                    stats: controller.stats.value!,
                    isCompact: true,
                  ),

                // Search field (para tablets sin sidebar)
                if (!isDesktop)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: _buildSearchField(context),
                  ),

                // Lista de proveedores
                Expanded(child: _buildSuppliersList(context)),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSidebarContent(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Header del panel compacto
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.dashboard,
                  color: Theme.of(context).primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Flexible(
                child: Text(
                  'Panel de Control',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Búsqueda
        Padding(
          padding: const EdgeInsets.all(12),
          child: _buildSearchField(context),
        ),

        const SizedBox(height: 12),

        // Filtros
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: SupplierFilterWidget(),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildMobileSearch(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: _buildSearchField(context),
    );
  }

  Widget _buildDesktopToolbar(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Container(
      padding: EdgeInsets.all(isTablet ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Información de resultados
          Expanded(
            child: Obx(() {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lista de Proveedores',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.resultsText,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: isTablet ? 12 : 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            }),
          ),

          SizedBox(width: isTablet ? 8 : 16),

          // Acciones adaptables según pantalla
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón Nuevo Proveedor - Adaptable
              if (isDesktop)
                // Desktop: Botón con texto
                Container(
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.successGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: ElegantLightTheme.elevatedShadow,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: controller.goToCreateSupplier,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Nuevo Proveedor',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else
                // Tablet: Solo icono
                Container(
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.successGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: ElegantLightTheme.elevatedShadow,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: controller.goToCreateSupplier,
                      borderRadius: BorderRadius.circular(10),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.add, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Obx(() {
      // Verificar que el controlador está disponible y no ha sido disposed
      if (!Get.isRegistered<SuppliersController>()) {
        return const SizedBox.shrink();
      }

      final hasSearch = controller.searchQuery.value.isNotEmpty;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                hasSearch
                    ? ElegantLightTheme.primaryBlue.withOpacity(0.4)
                    : Colors.grey.shade300,
            width: hasSearch ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  hasSearch
                      ? ElegantLightTheme.primaryBlue.withOpacity(0.1)
                      : Colors.black.withOpacity(0.04),
              blurRadius: hasSearch ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icono de búsqueda
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 8),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  hasSearch ? Icons.search_outlined : Icons.search,
                  key: ValueKey(hasSearch),
                  color:
                      hasSearch
                          ? ElegantLightTheme.primaryBlue
                          : Colors.grey.shade500,
                  size: 22,
                ),
              ),
            ),

            // Campo de texto con protección de dispose
            Expanded(
              child: _SafeTextField(controller: controller, isMobile: isMobile),
            ),

            // Botón de limpiar
            if (hasSearch)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      try {
                        if (Get.isRegistered<SuppliersController>()) {
                          controller.searchController.clear();
                          controller.searchQuery.value = '';
                        }
                      } catch (e) {
                        // Silenciosamente manejar el error si el controller fue disposed
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildSuppliersList(BuildContext context) {
    return Obx(() {
      final suppliers = controller.displayedSuppliers;

      if (suppliers.isEmpty && !controller.isLoading.value) {
        return _buildEmptyState(context);
      }

      if (controller.error.value.isNotEmpty && suppliers.isEmpty) {
        return _buildErrorState(context);
      }

      return RefreshIndicator(
        onRefresh: controller.refreshSuppliers,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: suppliers.length + (controller.canLoadMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= suppliers.length) {
              return _buildLoadMoreButton();
            }

            final supplier = suppliers[index];
            return SupplierCardWidget(
              supplier: supplier,
              onTap: () => controller.goToSupplierDetail(supplier.id),
              onEdit: () => controller.goToSupplierEdit(supplier.id),
              onDelete: () => controller.deleteSupplier(supplier.id),
            );
          },
        ),
      );
    });
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Obx(
        () =>
            controller.isLoadingMore.value
                ? const Center(child: CircularProgressIndicator())
                : Container(
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient.scale(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: controller.loadNextPage,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.expand_more,
                              color: ElegantLightTheme.primaryBlue,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Cargar más',
                              style: TextStyle(
                                color: ElegantLightTheme.primaryBlue,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final hasSearch = controller.searchQuery.value.isNotEmpty;

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: isMobile ? 340 : 480),
        margin: const EdgeInsets.all(24),
        padding: EdgeInsets.all(isMobile ? 32 : 48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono con gradiente circular
            Container(
              width: isMobile ? 100 : 120,
              height: isMobile ? 100 : 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      hasSearch
                          ? [
                            ElegantLightTheme.accentOrange.withOpacity(0.1),
                            ElegantLightTheme.accentOrange.withOpacity(0.05),
                          ]
                          : [
                            ElegantLightTheme.primaryBlue.withOpacity(0.1),
                            ElegantLightTheme.primaryBlue.withOpacity(0.05),
                          ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasSearch ? Icons.search_off : Icons.business_outlined,
                size: isMobile ? 50 : 60,
                color:
                    hasSearch
                        ? ElegantLightTheme.accentOrange
                        : ElegantLightTheme.primaryBlue,
              ),
            ),

            SizedBox(height: isMobile ? 24 : 32),

            // Título
            Text(
              hasSearch
                  ? 'No se encontraron proveedores'
                  : 'No hay proveedores registrados',
              style: TextStyle(
                fontSize: isMobile ? 20 : 24,
                color: ElegantLightTheme.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Descripción
            Text(
              hasSearch
                  ? 'Intenta con otros términos de búsqueda o ajusta los filtros aplicados'
                  : 'Comienza agregando tu primer proveedor para llevar un mejor control',
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: isMobile ? 14 : 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: isMobile ? 28 : 36),

            // Botón elegante
            if (hasSearch)
              _buildElegantButton(
                context: context,
                text: 'Limpiar Búsqueda',
                icon: Icons.clear_all,
                color: ElegantLightTheme.accentOrange,
                onPressed: () {
                  controller.searchController.clear();
                  controller.searchQuery.value = '';
                },
                isOutline: true,
              )
            else
              _buildElegantButton(
                context: context,
                text: 'Agregar Proveedor',
                icon: Icons.add_circle_outline,
                color: ElegantLightTheme.primaryBlue,
                onPressed: controller.goToCreateSupplier,
                isOutline: false,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: isMobile ? 340 : 480),
        margin: const EdgeInsets.all(24),
        padding: EdgeInsets.all(isMobile ? 32 : 48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.red.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isMobile ? 100 : 120,
              height: isMobile ? 100 : 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.red.shade100.withOpacity(0.5),
                    Colors.red.shade50,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: isMobile ? 50 : 60,
                color: Colors.red.shade600,
              ),
            ),

            SizedBox(height: isMobile ? 24 : 32),

            Text(
              'Error al cargar proveedores',
              style: TextStyle(
                fontSize: isMobile ? 20 : 24,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Obx(
              () => Text(
                controller.error.value,
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: isMobile ? 14 : 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: isMobile ? 28 : 36),

            _buildElegantButton(
              context: context,
              text: 'Reintentar',
              icon: Icons.refresh,
              color: Colors.red.shade600,
              onPressed: controller.reloadSuppliers,
              isOutline: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElegantButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required bool isOutline,
  }) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 24 : 32,
            vertical: isMobile ? 14 : 16,
          ),
          decoration: BoxDecoration(
            gradient:
                isOutline
                    ? null
                    : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withOpacity(0.8)],
                    ),
            color: isOutline ? Colors.transparent : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOutline ? color : color.withOpacity(0.3),
              width: isOutline ? 2 : 1,
            ),
            boxShadow:
                isOutline
                    ? null
                    : [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isOutline ? color : Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                text,
                style: TextStyle(
                  color: isOutline ? color : Colors.white,
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) {
      return const SizedBox.shrink();
    }

    if (ResponsiveHelper.isMobile(context)) {
      return Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ElegantLightTheme.primaryBlue.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            ...ElegantLightTheme.glowShadow,
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => controller.goToCreateSupplier(),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          ...ElegantLightTheme.glowShadow,
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: () => controller.goToCreateSupplier(),
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Nuevo Proveedor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget seguro para TextField que previene acceso a controllers disposed
/// durante rebuilds causados por redimensionamiento de ventana
class _SafeTextField extends StatefulWidget {
  final SuppliersController controller;
  final bool isMobile;

  const _SafeTextField({required this.controller, required this.isMobile});

  @override
  State<_SafeTextField> createState() => _SafeTextFieldState();
}

class _SafeTextFieldState extends State<_SafeTextField> {
  @override
  Widget build(BuildContext context) {
    // Verificar que el controller aún está montado y no ha sido disposed
    try {
      if (!mounted || !Get.isRegistered<SuppliersController>()) {
        return const SizedBox.shrink();
      }

      // Verificar que el TextEditingController no ha sido disposed
      final searchController = widget.controller.searchController;

      // Intentar acceder al texto para verificar si está disposed
      // Si está disposed, lanzará una excepción
      final _ = searchController.text;

      return TextField(
        controller: searchController,
        onChanged: (value) {
          try {
            if (mounted && Get.isRegistered<SuppliersController>()) {
              widget.controller.searchQuery.value = value;
            }
          } catch (e) {
            // Ignorar errores durante dispose
          }
        },
        style: TextStyle(
          fontSize: widget.isMobile ? 14 : 15,
          fontWeight: FontWeight.w500,
          color: ElegantLightTheme.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Buscar proveedores...',
          hintStyle: TextStyle(
            fontSize: widget.isMobile ? 14 : 15,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 4,
          ),
        ),
      );
    } catch (e) {
      // Si hay algún error (controller disposed), retornar widget vacío
      return const SizedBox.shrink();
    }
  }

  @override
  void dispose() {
    // No dispose del controller aquí - es manejado por GetX
    super.dispose();
  }
}
