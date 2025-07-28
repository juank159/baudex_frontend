// lib/features/invoices/presentation/screens/invoice_list_screen.dart
import 'package:baudex_desktop/app/config/routes/app_routes.dart';
import 'package:baudex_desktop/app/core/utils/responsive_helper.dart';
import 'package:baudex_desktop/features/invoices/presentation/widgets/invoice_status_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../../../../app/shared/widgets/custom_text_field_safe.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../controllers/invoice_list_controller.dart';
import '../bindings/invoice_binding.dart';
import '../widgets/invoice_card_widget.dart';
import '../widgets/invoice_filter_widget.dart';
import '../widgets/invoice_stats_widget.dart';
import '../../domain/entities/invoice.dart';

class InvoiceListScreen extends StatelessWidget {
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildScreenWithController(context);
  }

  /// Método para manejar el registro del controlador de forma robusta
  Widget _buildScreenWithController(BuildContext context) {
    return FutureBuilder<InvoiceListController>(
      future: _ensureControllerRegistration(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Error al inicializar',
                    style: TextStyle(fontSize: 18, color: Colors.red.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('No se pudo inicializar el controlador')),
          );
        }

        final controller = snapshot.data!;
        return _buildMainScreen(context, controller);
      },
    );
  }

  /// Asegurar que el controlador esté registrado
  Future<InvoiceListController> _ensureControllerRegistration() async {
    try {
      // Paso 1: Verificar si ya está registrado
      if (Get.isRegistered<InvoiceListController>()) {
        return Get.find<InvoiceListController>();
      }

      // Paso 2: Verificar dependencias base
      if (!InvoiceBinding.areBaseDependenciesRegistered()) {
        InvoiceBinding().dependencies();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Paso 3: Registrar el controlador específico
      InvoiceBinding.registerListController();

      // Paso 4: Verificar que se registró correctamente
      if (!Get.isRegistered<InvoiceListController>()) {
        throw Exception(
          'No se pudo registrar InvoiceListController después del intento',
        );
      }

      return Get.find<InvoiceListController>();
    } catch (e) {
      rethrow;
    }
  }

  /// ✅ NUEVO: Widget principal de la pantalla completamente rediseñado
  Widget _buildMainScreen(
    BuildContext context,
    InvoiceListController controller,
  ) {
    return Scaffold(
      appBar: _buildAppBar(context, controller),
      drawer: const AppDrawer(currentRoute: '/invoices'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // ✅ RESPONSIVE PERFECTO: Basado en el ancho real de la pantalla
          if (constraints.maxWidth < 600) {
            // MOBILE: < 600px
            return _buildMobileLayout(context, controller);
          } else if (constraints.maxWidth < 1024) {
            // TABLET: 600px - 1024px
            return _buildTabletLayout(context, controller);
          } else {
            // DESKTOP: > 1024px
            return _buildDesktopLayout(context, controller);
          }
        },
      ),
      floatingActionButton: _buildFloatingActionButton(context, controller),
      bottomNavigationBar: _buildBottomBar(context, controller),
    );
  }

  // ==================== APP BAR ====================

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    InvoiceListController controller,
  ) {
    return AppBar(
      title: const Text('Facturas'),
      elevation: 0,
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      actions: [
        // Buscar - Solo en móvil
        if (MediaQuery.of(context).size.width < 600)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showMobileSearch(context, controller),
          ),

        // Filtros
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () => _showFiltersBottomSheet(context, controller),
        ),

        // Refrescar
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: controller.refreshAllData,
        ),

        // Menú principal
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, context, controller),
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'multiselect',
                  child: Row(
                    children: [
                      Icon(Icons.checklist),
                      SizedBox(width: 8),
                      Text('Selección múltiple'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'stats',
                  child: Row(
                    children: [
                      Icon(Icons.analytics),
                      SizedBox(width: 8),
                      Text('Estadísticas'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.download),
                      SizedBox(width: 8),
                      Text('Exportar'),
                    ],
                  ),
                ),
              ],
        ),
      ],
    );
  }

  // ==================== LAYOUTS RESPONSIVE ====================

  /// ✅ MOBILE LAYOUT: Pantallas < 600px
  Widget _buildMobileLayout(
    BuildContext context,
    InvoiceListController controller,
  ) {
    return Column(
      children: [
        // ✅ Estadísticas compactas móviles
        _buildMobileStats(context, controller),

        // ✅ Barra de búsqueda móvil
        _buildMobileSearchBar(context, controller),

        // ✅ Lista de facturas con scroll perfecto
        Expanded(
          child: Container(
            color: Colors.grey.shade50,
            child: _buildInvoiceList(context, controller),
          ),
        ),
      ],
    );
  }

  /// ✅ TABLET LAYOUT: Pantallas 600px - 1024px
  Widget _buildTabletLayout(
    BuildContext context,
    InvoiceListController controller,
  ) {
    return Row(
      children: [
        // ✅ Lista principal (70%) - OVERFLOW COMPLETAMENTE SOLUCIONADO
        Expanded(
          flex: 7,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Prevenir overflow vertical
            children: [
              // ✅ Barra de búsqueda con altura fija para evitar overflow
              Container(
                constraints: const BoxConstraints(
                  maxHeight: 80, // Altura máxima fija
                  minHeight: 60, // Altura mínima
                ),
                child: _buildTabletSearchBar(context, controller),
              ),
              // ✅ Lista con Flexible en lugar de Expanded para manejo dinámico
              Flexible(
                flex: 1,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height - 200, // Limitar altura máxima
                  ),
                  color: Colors.grey.shade50,
                  child: _buildInvoiceList(context, controller),
                ),
              ),
            ],
          ),
        ),

        // ✅ Panel lateral derecho (30%)
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(left: BorderSide(color: Colors.grey.shade300)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: _buildTabletSidebar(context, controller),
        ),
      ],
    );
  }

  /// ✅ DESKTOP LAYOUT: Pantallas > 1024px - COMPLETAMENTE REDISEÑADO
  Widget _buildDesktopLayout(
    BuildContext context,
    InvoiceListController controller,
  ) {
    return Obx(() {
      if (controller.isLoading) {
        return const LoadingWidget(message: 'Cargando facturas...');
      }

      return Row(
        children: [
          // ✅ PANEL LATERAL IZQUIERDO: 320px fijo
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: _buildDesktopSidebar(context, controller),
          ),

          // ✅ ÁREA PRINCIPAL: Resto del espacio disponible
          Expanded(
            child: Column(
              children: [
                // ✅ Toolbar superior mejorado
                _buildDesktopToolbar(context, controller),

                // ✅ Lista de facturas con scroll perfecto
                Expanded(
                  child: Container(
                    color: Colors.grey.shade50,
                    child: _buildInvoiceList(context, controller),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  // ==================== COMPONENTES ESPECÍFICOS ====================

  /// ✅ Estadísticas móviles
  Widget _buildMobileStats(
    BuildContext context,
    InvoiceListController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: GetBuilder<InvoiceListController>(
        builder: (controller) {
          final totalInvoices = controller.filteredInvoices.length;
          final pendingInvoices =
              controller.filteredInvoices
                  .where(
                    (i) =>
                        i.status == InvoiceStatus.pending ||
                        i.status == InvoiceStatus.partiallyPaid,
                  )
                  .length;
          final overdueInvoices =
              controller.filteredInvoices.where((i) => i.isOverdue).length;

          return Row(
            children: [
              Expanded(
                child: _buildMobileStatCard(
                  'Total',
                  totalInvoices.toString(),
                  Icons.receipt_long,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildMobileStatCard(
                  'Pendientes',
                  pendingInvoices.toString(),
                  Icons.schedule,
                  pendingInvoices > 0 ? Colors.orange : Colors.grey,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildMobileStatCard(
                  'Vencidas',
                  overdueInvoices.toString(),
                  Icons.warning,
                  overdueInvoices > 0 ? Colors.red : Colors.grey,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMobileStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 8, color: color.withOpacity(0.8)),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// ✅ Barra de búsqueda móvil
  Widget _buildMobileSearchBar(
    BuildContext context,
    InvoiceListController controller,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
      color: Colors.white,
      child: SizedBox(
        height: 32,
        child: GetBuilder<InvoiceListController>(
          builder:
              (controller) => TextField(
                controller: controller.searchController,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Buscar facturas...',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  suffixIcon:
                      controller.searchQuery.isNotEmpty
                          ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: () {
                              try {
                                controller.searchController.clear();
                              } catch (e) {
                                controller.searchInvoices('');
                              }
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  isDense: true,
                ),
                onChanged: (value) => controller.searchInvoices(value),
              ),
        ),
      ),
    );
  }

  /// ✅ Barra de búsqueda tablet
  Widget _buildTabletSearchBar(
    BuildContext context,
    InvoiceListController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GetBuilder<InvoiceListController>(
              builder: (controller) => CustomTextFieldSafe(
                controller: controller.searchController,
                label: 'Buscar facturas',
                hint: 'Número, cliente, monto...',
                prefixIcon: Icons.search,
                debugLabel: 'TabletSearch',
                suffixIcon:
                    controller.searchQuery.isNotEmpty ? Icons.clear : null,
                onSuffixIconPressed:
                    controller.searchQuery.isNotEmpty
                        ? () {
                          try {
                            if (controller.searchController.canSafelyAccess()) {
                              controller.searchController.safeClear();
                            } else {
                              controller.searchInvoices('');
                            }
                          } catch (e) {
                            controller.searchInvoices('');
                          }
                        }
                        : null,
                onChanged: (value) => controller.searchInvoices(value),
              ),
            ),
          ),
          const SizedBox(width: 16),
          CustomButton(
            text: 'Nueva',
            icon: Icons.add,
            onPressed: controller.goToCreateInvoice,
          ),
        ],
      ),
    );
  }

  /// ✅ Sidebar tablet
  Widget _buildTabletSidebar(
    BuildContext context,
    InvoiceListController controller,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Panel de Control',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Estadísticas
          _buildSidebarStatsSection(context, controller),
          const SizedBox(height: 20),

          // Filtros rápidos
          _buildSidebarFiltersSection(context, controller),
          const SizedBox(height: 20),

          // Acciones rápidas
          _buildSidebarActionsSection(context, controller),
        ],
      ),
    );
  }

  /// ✅ Sidebar desktop mejorado - FIX OVERFLOW
  Widget _buildDesktopSidebar(
    BuildContext context,
    InvoiceListController controller,
  ) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // ✅ Header fijo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Theme.of(context).primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Panel de Facturas',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                          fontSize: 16,
                        ),
                      ),
                      GetBuilder<InvoiceListController>(
                        builder: (controller) {
                          final hasFilters = controller.hasFilters;
                          return Text(
                            hasFilters ? 'Filtros activos' : 'Sin filtros',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  hasFilters
                                      ? Colors.orange
                                      : Colors.grey.shade600,
                              fontWeight:
                                  hasFilters
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ✅ Búsqueda compacta
          Container(
            padding: const EdgeInsets.all(16),
            child: GetBuilder<InvoiceListController>(
              builder: (controller) => CustomTextFieldSafe(
                controller: controller.searchController,
                label: 'Buscar',
                hint: 'Número, cliente...',
                prefixIcon: Icons.search,
                debugLabel: 'DesktopSearch',
                suffixIcon:
                    controller.searchQuery.isNotEmpty ? Icons.clear : null,
                onSuffixIconPressed:
                    controller.searchQuery.isNotEmpty
                        ? () {
                          try {
                            if (controller.searchController.canSafelyAccess()) {
                              controller.searchController.safeClear();
                            } else {
                              controller.searchInvoices('');
                            }
                          } catch (e) {
                            controller.searchInvoices('');
                          }
                        }
                        : null,
                onChanged: (value) => controller.searchInvoices(value),
              ),
            ),
          ),

          // ✅ Contenido scrolleable con Flexible para mejor control de overflow
          Flexible(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Estadísticas con altura limitada
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: _buildSidebarStatsSection(context, controller),
                  ),
                  const SizedBox(height: 16),

                  // Filtros con altura limitada
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: _buildSidebarFiltersSection(context, controller),
                  ),
                  const SizedBox(height: 16),

                  // Acciones con altura limitada
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: _buildSidebarActionsSection(context, controller),
                  ),
                  const SizedBox(height: 20), // Espaciado final
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  /// ✅ Sección de estadísticas para sidebar
  Widget _buildSidebarStatsSection(
    BuildContext context,
    InvoiceListController controller,
  ) {
    return GetBuilder<InvoiceListController>(
      builder: (controller) {
        final totalInvoices = controller.filteredInvoices.length;
        final pendingInvoices =
            controller.filteredInvoices
                .where(
                  (i) =>
                      i.status == InvoiceStatus.pending ||
                      i.status == InvoiceStatus.partiallyPaid,
                )
                .length;
        final paidInvoices =
            controller.filteredInvoices
                .where((i) => i.status == InvoiceStatus.paid)
                .length;
        final overdueInvoices =
            controller.filteredInvoices.where((i) => i.isOverdue).length;

        return Container(
          padding: const EdgeInsets.all(12), // Reducido padding del contenedor
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8), // Reducido border radius
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Minimizar tamaño vertical
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics,
                    size: 16, // Reducido tamaño del icono
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Resumen',
                    style: TextStyle(
                      fontSize: 14, // Reducido tamaño del título
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10), // Reducido espacio
              // Grid de estadísticas 2x2 - ÁREA AJUSTADA
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.2, // Ajustado para mejor proporción
                crossAxisSpacing:
                    8, // Aumentado ligeramente para mejor separación
                mainAxisSpacing:
                    8, // Aumentado ligeramente para mejor separación
                children: [
                  _buildSidebarStatItem(
                    'Total',
                    totalInvoices.toString(),
                    Icons.receipt_long,
                    Colors.blue,
                  ),
                  _buildSidebarStatItem(
                    'Pagadas',
                    paidInvoices.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildSidebarStatItem(
                    'Pendientes',
                    pendingInvoices.toString(),
                    Icons.schedule,
                    pendingInvoices > 0 ? Colors.orange : Colors.grey,
                  ),
                  _buildSidebarStatItem(
                    'Vencidas',
                    overdueInvoices.toString(),
                    Icons.warning,
                    overdueInvoices > 0 ? Colors.red : Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebarStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        3,
      ), // Reducido 50% más para máximo aprovechamiento
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4), // Reducido proporcionalmente
        border: Border.all(color: color.withOpacity(0.25), width: 0.8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono más pequeño
          Icon(icon, color: color, size: 10), // Reducido 40% más
          const SizedBox(height: 1), // Mínimo espacio
          // Número
          Text(
            value,
            style: TextStyle(
              fontSize: 10, // Reducido 40% más
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 7, // Reducido 40% más
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// ✅ Sección de filtros para sidebar
  Widget _buildSidebarFiltersSection(
    BuildContext context,
    InvoiceListController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, size: 18, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Text(
                'Filtros Rápidos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filtros de estado
          GetBuilder<InvoiceListController>(
            builder: (controller) {
              return Column(
                children: [
                  _buildFilterOption(
                    'Todas',
                    controller.selectedStatus == null,
                    () => controller.filterByStatus(null),
                    Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  _buildFilterOption(
                    'Pagadas',
                    controller.selectedStatus == InvoiceStatus.paid,
                    () => controller.filterByStatus(InvoiceStatus.paid),
                    Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _buildFilterOption(
                    'Pendientes',
                    controller.selectedStatus == InvoiceStatus.pending,
                    () => controller.filterByStatus(InvoiceStatus.pending),
                    Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  _buildFilterOption(
                    'Vencidas',
                    controller.selectedStatus == InvoiceStatus.overdue,
                    () => controller.filterByStatus(InvoiceStatus.overdue),
                    Colors.red,
                  ),
                  if (controller.hasFilters) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'Limpiar Filtros',
                        icon: Icons.clear_all,
                        type: ButtonType.outline,
                        onPressed: controller.clearFilters,
                        fontSize: 12,
                        height: 36,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(
    String label,
    bool isSelected,
    VoidCallback onTap,
    Color color,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child:
                  isSelected
                      ? Icon(Icons.check, color: Colors.white, size: 10)
                      : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? color : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Sección de acciones para sidebar
  Widget _buildSidebarActionsSection(
    BuildContext context,
    InvoiceListController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, size: 18, color: Colors.amber.shade700),
              const SizedBox(width: 8),
              Text(
                'Acciones Rápidas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Botón nueva factura
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Nueva Factura',
              icon: Icons.add,
              onPressed: controller.goToCreateInvoice,
              height: 40,
            ),
          ),
          const SizedBox(height: 12),

          // Botón estadísticas
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Estadísticas',
              icon: Icons.analytics,
              type: ButtonType.outline,
              onPressed: () => Get.toNamed('/invoices/stats'),
              height: 40,
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Toolbar desktop mejorado
  Widget _buildDesktopToolbar(
    BuildContext context,
    InvoiceListController controller,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Información de resultados
          Expanded(
            child: GetBuilder<InvoiceListController>(
              builder: (controller) {
                final total = controller.filteredInvoices.length;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mostrando $total facturas',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (controller.searchQuery.isNotEmpty)
                      Text(
                        'Búsqueda: "${controller.searchQuery}"',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 14,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Acciones principales
          Row(
            children: [
              CustomButton(
                text: 'Nueva Factura',
                icon: Icons.add,
                onPressed: controller.goToCreateInvoice,
                height: 44,
              ),
              const SizedBox(width: 12),
              CustomButton(
                text: 'Filtros Avanzados',
                icon: Icons.tune,
                type: ButtonType.outline,
                onPressed: () => _showFiltersBottomSheet(context, controller),
                height: 44,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ✅ Lista de facturas optimizada
  Widget _buildInvoiceList(
    BuildContext context,
    InvoiceListController controller,
  ) {
    return GetBuilder<InvoiceListController>(
      builder: (controller) {
        if (controller.isLoading) {
          return const LoadingWidget(message: 'Cargando facturas...');
        }

        if (controller.filteredInvoices.isEmpty) {
          return _buildEmptyState(context, controller);
        }

        return RefreshIndicator(
          onRefresh: controller.refreshAllData,
          child: ListView.builder(
            controller: controller.scrollController,
            padding: const EdgeInsets.all(8),
            itemCount:
                controller.filteredInvoices.length +
                (controller.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              // Loading indicator para paginación
              if (index >= controller.filteredInvoices.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final invoice = controller.filteredInvoices[index];
              return InvoiceCardWidget(
                invoice: invoice,
                isSelected: controller.selectedInvoices.contains(invoice.id),
                isMultiSelectMode: controller.isMultiSelectMode,
                onTap: () => _handleInvoiceTap(invoice, controller),
                onLongPress: () => _handleInvoiceLongPress(invoice, controller),
                onActionTap:
                    (action) =>
                        _handleInvoiceAction(action, invoice, controller),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    InvoiceListController controller,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              controller.searchQuery.isNotEmpty || controller.hasFilters
                  ? 'No se encontraron facturas'
                  : 'No hay facturas aún',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              controller.searchQuery.isNotEmpty || controller.hasFilters
                  ? 'Intenta cambiar los filtros de búsqueda'
                  : 'Crea tu primera factura para comenzar',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (controller.searchQuery.isNotEmpty || controller.hasFilters)
              CustomButton(
                text: 'Limpiar Filtros',
                type: ButtonType.outline,
                onPressed: controller.clearFilters,
                height: 48,
              )
            else
              CustomButton(
                text: 'Crear Primera Factura',
                icon: Icons.add,
                onPressed: controller.goToCreateInvoice,
                height: 48,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(
    BuildContext context,
    InvoiceListController controller,
  ) {
    // Solo mostrar en móvil
    if (MediaQuery.of(context).size.width >= 600) {
      return const SizedBox.shrink();
    }

    return GetBuilder<InvoiceListController>(
      builder: (controller) {
        if (controller.isMultiSelectMode && controller.hasSelection) {
          return FloatingActionButton.extended(
            onPressed: () => _showBulkActionsDialog(context, controller),
            icon: const Icon(Icons.more_horiz),
            label: Text('${controller.selectedInvoices.length} seleccionadas'),
          );
        }

        return FloatingActionButton(
          onPressed: controller.goToCreateInvoice,
          child: const Icon(Icons.add),
        );
      },
    );
  }

  Widget? _buildBottomBar(
    BuildContext context,
    InvoiceListController controller,
  ) {
    // Solo mostrar en móvil
    if (MediaQuery.of(context).size.width >= 600) return null;

    return GetBuilder<InvoiceListController>(
      builder: (controller) {
        if (!controller.isMultiSelectMode) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${controller.selectedInvoices.length} facturas seleccionadas',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                if (controller.hasSelection) ...[
                  TextButton(
                    onPressed: controller.clearSelection,
                    child: const Text('Limpiar'),
                  ),
                  const SizedBox(width: 8),
                  CustomButton(
                    text: 'Acciones',
                    onPressed:
                        () => _showBulkActionsDialog(context, controller),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== EVENT HANDLERS ====================

  void _handleInvoiceTap(Invoice invoice, InvoiceListController controller) {
    if (controller.isMultiSelectMode) {
      controller.toggleInvoiceSelection(invoice.id);
    } else {
      controller.goToInvoiceDetail(invoice.id);
    }
  }

  void _handleInvoiceLongPress(
    Invoice invoice,
    InvoiceListController controller,
  ) {
    if (!controller.isMultiSelectMode) {
      controller.toggleMultiSelectMode();
    }
    controller.toggleInvoiceSelection(invoice.id);
  }

  void _handleInvoiceAction(
    String action,
    Invoice invoice,
    InvoiceListController controller,
  ) {
    switch (action) {
      case 'edit':
        controller.goToEditInvoice(invoice.id);
        break;
      case 'print':
        controller.printInvoice(invoice.id);
        break;
      case 'confirm':
        controller.confirmInvoice(invoice.id);
        break;
      case 'cancel':
        _showCancelConfirmation(invoice, controller);
        break;
      case 'delete':
        _showDeleteConfirmation(invoice, controller);
        break;
    }
  }

  void _handleMenuAction(
    String action,
    BuildContext context,
    InvoiceListController controller,
  ) {
    switch (action) {
      case 'multiselect':
        controller.toggleMultiSelectMode();
        break;
      case 'stats':
        Get.toNamed('/invoices/stats');
        break;
      case 'export':
        _showInfo('Próximamente', 'Función de exportar en desarrollo');
        break;
    }
  }

  // ==================== DIALOGS ====================

  void _showFiltersBottomSheet(
    BuildContext context,
    InvoiceListController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => InvoiceFilterWidget(controller: controller),
    );
  }

  void _showBulkActionsDialog(
    BuildContext context,
    InvoiceListController controller,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Acciones en Lote'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.print),
                  title: const Text('Imprimir Seleccionadas'),
                  onTap: () {
                    Get.back();
                    _showInfo(
                      'Próximamente',
                      'Impresión en lote en desarrollo',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Exportar Seleccionadas'),
                  onTap: () {
                    Get.back();
                    _showInfo(
                      'Próximamente',
                      'Exportación en lote en desarrollo',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Eliminar Seleccionadas'),
                  onTap: () {
                    Get.back();
                    _showBulkDeleteConfirmation(controller);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
    );
  }

  void _showCancelConfirmation(
    Invoice invoice,
    InvoiceListController controller,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancelar Factura'),
        content: Text('¿Cancelar la factura ${invoice.number}?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('No')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.cancelInvoice(invoice.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    Invoice invoice,
    InvoiceListController controller,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Eliminar Factura'),
        content: Text(
          '¿Eliminar la factura ${invoice.number}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteInvoice(invoice.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showBulkDeleteConfirmation(InvoiceListController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Eliminar Facturas'),
        content: Text(
          '¿Eliminar ${controller.selectedInvoices.length} facturas seleccionadas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _showInfo('Próximamente', 'Eliminación en lote en desarrollo');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showInfo(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
      icon: const Icon(Icons.info, color: Colors.blue),
      duration: const Duration(seconds: 3),
    );
  }

  void _showMobileSearch(
    BuildContext context,
    InvoiceListController controller,
  ) {
    showSearch(context: context, delegate: InvoiceSearchDelegate(controller));
  }
}

class InvoiceSearchDelegate extends SearchDelegate<Invoice?> {
  final InvoiceListController controller;

  InvoiceSearchDelegate(this.controller);

  @override
  String get searchFieldLabel => 'Buscar facturas...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.length < 2) {
      return const Center(
        child: Text('Ingresa al menos 2 caracteres para buscar'),
      );
    }

    final results =
        controller.filteredInvoices.where((invoice) {
          final searchLower = query.toLowerCase();
          return invoice.number.toLowerCase().contains(searchLower) ||
              invoice.customerName.toLowerCase().contains(searchLower);
        }).toList();

    if (results.isEmpty) {
      return const Center(child: Text('No se encontraron facturas'));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final invoice = results[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Icon(
              Icons.receipt_long,
              color: Theme.of(context).primaryColor,
            ),
          ),
          title: Text(invoice.number),
          subtitle: Text(invoice.customerName),
          trailing: Text(
            AppFormatters.formatCurrency(invoice.total),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onTap: () {
            close(context, invoice);
            controller.goToInvoiceDetail(invoice.id);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}
