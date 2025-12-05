// lib/features/invoices/presentation/screens/invoice_list_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../../../app/shared/widgets/custom_text_field_safe.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../controllers/invoice_list_controller.dart';
import '../controllers/invoice_stats_controller.dart';
import '../bindings/invoice_binding.dart';
import '../widgets/invoice_card_widget.dart';
import '../widgets/invoice_filter_widget.dart';
import '../widgets/invoice_skeleton_widget.dart'; // ✅ Skeleton loading para facturas
import '../../domain/entities/invoice.dart';
import '../../domain/usecases/get_invoice_stats_usecase.dart';
import '../../domain/usecases/get_overdue_invoices_usecase.dart';

/// Helper para asegurar que InvoiceStatsController esté registrado
void _ensureStatsControllerRegistered() {
  if (!Get.isRegistered<InvoiceStatsController>()) {
    try {
      // Verificar que los use cases estén disponibles
      if (Get.isRegistered<GetInvoiceStatsUseCase>() &&
          Get.isRegistered<GetOverdueInvoicesUseCase>()) {
        Get.put(
          InvoiceStatsController(
            getInvoiceStatsUseCase: Get.find<GetInvoiceStatsUseCase>(),
            getOverdueInvoicesUseCase: Get.find<GetOverdueInvoicesUseCase>(),
          ),
          permanent: true,
        );
        // print('✅ InvoiceStatsController registrado dinámicamente');
      } else {
        // print('⚠️ Use cases no disponibles para InvoiceStatsController');
      }
    } catch (e) {
      // print('❌ Error registrando InvoiceStatsController: $e');
    }
  }
}

/// ✅ AUTO-REFRESH: Convertido a StatefulWidget para manejar lifecycle
class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen>
    with WidgetsBindingObserver {
  InvoiceListController? _controller;

  // ✅ SOLUCIÓN: ScrollController manejado por el StatefulWidget
  // Esto garantiza un lifecycle correcto y evita el error de múltiples posiciones
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    // ✅ Crear ScrollController fresco para esta instancia del widget
    _scrollController = ScrollController();
    // ✅ AUTO-REFRESH: Registrar observer del ciclo de vida de la app
    WidgetsBinding.instance.addObserver(this);
    _initializeController();
  }

  @override
  void dispose() {
    // ✅ CRÍTICO: Disponer el ScrollController antes de cerrar
    _scrollController.dispose();
    // ✅ AUTO-REFRESH: Remover observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// ✅ AUTO-REFRESH: Detectar cuando la app/pantalla vuelve a primer plano
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Solo verificar refresh, NO recrear ScrollController agresivamente
      _controller?.checkAndRefreshIfNeeded();
    }
  }

  /// ✅ AUTO-REFRESH: Detectar cuando volvemos a esta ruta específica
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Solo verificar refresh al volver, NO recrear ScrollController
    if (mounted && _controller != null) {
      _controller!.checkAndRefreshIfNeeded();
    }
  }

  Future<void> _initializeController() async {
    final controller = await _ensureControllerRegistration();
    if (mounted) {
      setState(() {
        _controller = controller;
      });
      // ✅ Configurar listener de scroll para paginación
      _setupScrollListener(controller);
    }
  }

  /// ✅ Configurar listener de scroll para paginación infinita
  void _setupScrollListener(InvoiceListController controller) {
    _scrollController.addListener(() {
      if (!mounted) return;

      // Solo proceder si tiene una posición válida
      if (!_scrollController.hasClients) return;

      final position = _scrollController.position;
      final threshold = position.maxScrollExtent - 300;

      // Verificar si debemos cargar más
      if (position.pixels >= threshold &&
          controller.hasNextPage &&
          !controller.isLoadingMore &&
          !controller.isLoading) {
        controller.loadMoreInvoices();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<InvoiceListController>(
      future: _ensureControllerRegistration(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: _LoadingView(),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorScreen(snapshot.error.toString());
        }

        final controller = snapshot.data;
        if (controller == null) {
          return _buildErrorScreen('No se pudo inicializar el controlador');
        }

        return _buildMainScreen(context, controller);
      },
    );
  }

  Future<InvoiceListController> _ensureControllerRegistration() async {
    try {
      if (Get.isRegistered<InvoiceListController>()) {
        final controller = Get.find<InvoiceListController>();
        // NO recrear ScrollController aquí - solo si hay problema real
        // El getter mainScrollController ya maneja la lógica de reparación
        return controller;
      }

      final binding = InvoiceBinding();
      binding.dependencies();
      await Future.delayed(const Duration(milliseconds: 100));

      return Get.find<InvoiceListController>();
    } catch (e) {
      debugPrint('Error registrando controlador: $e');
      rethrow;
    }
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar facturas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
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

  Widget _buildMainScreen(BuildContext context, InvoiceListController controller) {
    return Scaffold(
      appBar: _buildAppBar(context, controller),
      drawer: const AppDrawer(currentRoute: '/invoices'),
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ElegantLightTheme.backgroundColor,
              ElegantLightTheme.cardColor,
            ],
          ),
        ),
        child: ResponsiveHelper.responsive(
          context,
          mobile: _buildMobileLayout(context, controller),
          tablet: _buildTabletLayout(context, controller),
          desktop: _buildDesktopLayout(context, controller),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context, controller),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, InvoiceListController controller) {
    return AppBar(
      title: const Text(
        'Gestión de Facturas',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
      ),
      actions: [
        if (ResponsiveHelper.isMobile(context))
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => _showMobileSearch(context, controller),
            tooltip: 'Búsqueda avanzada',
          ),

        Obx(() => IconButton(
          icon: controller.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.refresh, color: Colors.white),
          onPressed: controller.isLoading ? null : () async {
            // ✅ Refresh manual del usuario - mostrar mensaje de éxito
            await controller.refreshAllData(showSuccessMessage: true);
          },
          tooltip: controller.isLoading ? 'Actualizando...' : 'Actualizar facturas',
        )),

        IconButton(
          icon: const Icon(Icons.filter_list, color: Colors.white),
          onPressed: () => _showFilters(context, controller),
          tooltip: 'Filtros avanzados',
        ),

        Obx(() {
          final overdueCount = controller.filteredInvoices
              .where((i) => i.isOverdue)
              .length;

          return IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.warning_outlined,
                  color: overdueCount > 0 ? Colors.orange : Colors.white,
                ),
                if (overdueCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$overdueCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              if (overdueCount > 0) {
                controller.filterByStatus(InvoiceStatus.overdue);
              } else {
                Get.snackbar(
                  'Sin alertas',
                  'No hay facturas vencidas',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.green.shade100,
                  colorText: Colors.green.shade800,
                );
              }
            },
            tooltip: overdueCount > 0
                ? 'Ver $overdueCount facturas vencidas'
                : 'Sin facturas vencidas',
          );
        }),

        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context, InvoiceListController controller) {
    if (ResponsiveHelper.isDesktop(context)) {
      return const SizedBox.shrink();
    }

    // ✅ MOBILE: Botón circular con diseño elegante
    if (ResponsiveHelper.isMobile(context)) {
      return Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.4),
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
            onTap: () => controller.goToCreateInvoice(),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      );
    }

    // ✅ TABLET: Botón extendido con diseño elegante
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.4),
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
          onTap: () => controller.goToCreateInvoice(),
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Nueva Factura',
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

  Widget _buildDesktopLayout(BuildContext context, InvoiceListController controller) {
    return Obx(() {
      // ✅ Usar skeleton loading para carga inicial
      if (controller.isLoading && controller.filteredInvoices.isEmpty) {
        return Row(
          children: [
            _DesktopSidebar(controller: controller),
            Expanded(
              child: Column(
                children: [
                  _DesktopToolbar(controller: controller),
                  const Expanded(child: InvoiceSkeletonList(itemCount: 8)),
                ],
              ),
            ),
          ],
        );
      }

      return Row(
        children: [
          _DesktopSidebar(controller: controller),
          Expanded(
            child: Column(
              children: [
                _DesktopToolbar(controller: controller),
                Expanded(child: _buildInvoicesList(controller)),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildMobileLayout(BuildContext context, InvoiceListController controller) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: _SearchField(controller: controller),
        ),
        Expanded(child: _buildInvoicesList(controller)),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context, InvoiceListController controller) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: _SearchField(controller: controller),
        ),
        Expanded(child: _buildInvoicesList(controller)),
      ],
    );
  }

  Widget _buildInvoicesList(InvoiceListController controller) {
    return Obx(() {
      // ✅ Skeleton loading para carga inicial (sin datos previos)
      if (controller.isLoading && controller.filteredInvoices.isEmpty) {
        return const InvoiceSkeletonList(itemCount: 8);
      }

      final invoiceList = controller.filteredInvoices;

      if (invoiceList.isEmpty) {
        return _EmptyState(isSearching: controller.searchQuery.isNotEmpty);
      }

      return RefreshIndicator(
        onRefresh: () => controller.refreshAllData(showSuccessMessage: true),
        child: Column(
          children: [
            if (controller.totalPages > 1) _PaginationInfo(controller: controller),

            Expanded(
              child: ListView.builder(
                controller: _scrollController, // ✅ Usar ScrollController local del StatefulWidget
                padding: const EdgeInsets.all(16),
                cacheExtent: 500, // ✅ Pre-cargar items fuera de pantalla
                itemCount: invoiceList.length + (controller.hasNextPage ? 1 : 0),
                itemBuilder: (context, index) {
                  // ✅ Indicador de carga al final
                  if (index >= invoiceList.length) {
                    return _LoadMoreIndicator(controller: controller);
                  }

                  final invoice = invoiceList[index];

                  return InvoiceCardWidget(
                    key: ValueKey(invoice.id), // ✅ Key para optimizar rebuild
                    invoice: invoice,
                    isSelected: controller.selectedInvoices.contains(invoice.id),
                    isMultiSelectMode: controller.isMultiSelectMode,
                    onTap: () => _handleInvoiceTap(invoice, controller),
                    onLongPress: () => _handleInvoiceLongPress(invoice, controller),
                    onActionTap: (action) => _handleInvoiceAction(action, invoice, controller),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  void _handleInvoiceTap(Invoice invoice, InvoiceListController controller) {
    if (controller.isMultiSelectMode) {
      controller.toggleInvoiceSelection(invoice.id);
    } else {
      controller.goToInvoiceDetail(invoice.id);
    }
  }

  void _handleInvoiceLongPress(Invoice invoice, InvoiceListController controller) {
    if (!controller.isMultiSelectMode) {
      controller.toggleMultiSelectMode();
    }
    controller.toggleInvoiceSelection(invoice.id);
  }

  void _handleInvoiceAction(String action, Invoice invoice, InvoiceListController controller) {
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

  void _showMobileSearch(BuildContext context, InvoiceListController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // ✅ Permite que el sheet use más espacio
      builder: (context) => SafeArea(
        // ✅ Respeta el Safe Area (notch, barra de estado, etc.)
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16, // ✅ Respeta el teclado
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ Indicador visual de que es un bottom sheet
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Búsqueda de Facturas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),
              _SearchField(controller: controller),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilters(BuildContext context, InvoiceListController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: InvoiceFilterWidget(controller: controller),
        ),
      ),
    );
  }


  void _showCancelConfirmation(Invoice invoice, InvoiceListController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancelar Factura'),
        content: Text('¿Cancelar la factura ${invoice.number}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('No'),
          ),
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

  void _showDeleteConfirmation(Invoice invoice, InvoiceListController controller) {
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
}

// ==================== EXTRACTED WIDGETS ====================

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ElegantLightTheme.backgroundColor,
            ElegantLightTheme.cardColor,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: ElegantLightTheme.glowShadow,
              ),
              child: const Icon(
                Icons.receipt_long,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Cargando facturas...',
              style: TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Preparando la experiencia futurista',
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  final InvoiceListController controller;

  const _DesktopSidebar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: MediaQuery.of(context).size.height - kToolbarHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const _SidebarHeader(),
          _SearchField(controller: controller),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatsSection(controller: controller),
                  const SizedBox(height: 16),
                  _FilterSection(controller: controller),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ElegantLightTheme.primaryGradient.colors.first.withValues(alpha: 0.15),
            ElegantLightTheme.primaryGradient.colors.last.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.receipt_long, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => ElegantLightTheme.primaryGradient.createShader(bounds),
                  child: const Text(
                    'Facturas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.successGradient,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Gestión y búsqueda',
                      style: TextStyle(
                        fontSize: 12,
                        color: ElegantLightTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final InvoiceListController controller;

  const _SearchField({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.glassGradient,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ElegantLightTheme.textSecondary.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CustomTextFieldSafe(
          controller: controller.searchController,
          label: '',
          hint: 'Buscar por número, cliente o monto...',
          prefixIcon: Icons.search,
          suffixIcon: controller.searchController.text.isNotEmpty ? Icons.clear : null,
          onSuffixIconPressed: controller.searchController.text.isNotEmpty
              ? controller.clearFilters
              : null,
        ),
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final InvoiceListController controller;

  const _StatsSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    // Usar Obx para reactividad con la lista de facturas del controlador
    return Obx(() {
      // Calcular estadísticas localmente usando la misma lógica de isOverdue
      // que usa la UI, garantizando consistencia entre contador y visualización
      final invoices = controller.invoices;

      // Contadores calculados localmente
      final totalCount = invoices.length;
      final paidCount = invoices.where((inv) =>
        inv.status == InvoiceStatus.paid || inv.balanceDue <= 0
      ).length;
      final pendingCount = invoices.where((inv) =>
        (inv.status == InvoiceStatus.pending ||
         inv.status == InvoiceStatus.partiallyPaid) &&
        !inv.isOverdue &&
        inv.balanceDue > 0
      ).length;
      // Usar la lógica de isOverdue de la entidad Invoice para consistencia
      final overdueCount = invoices.where((inv) => inv.isOverdue).length;

      return FuturisticContainer(
        hasGlow: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: ElegantLightTheme.glowShadow,
                  ),
                  child: const Icon(
                    Icons.analytics,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Estadísticas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _StatRow(
              label: 'Total',
              value: totalCount.toString(),
              icon: Icons.receipt_long,
              color: ElegantLightTheme.primaryBlue,
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: 'Pagadas',
              value: paidCount.toString(),
              icon: Icons.check_circle,
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: 'Pendientes',
              value: pendingCount.toString(),
              icon: Icons.schedule,
              color: pendingCount > 0 ? Colors.orange : Colors.grey,
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: 'Vencidas',
              value: overdueCount.toString(),
              icon: Icons.warning,
              color: overdueCount > 0 ? Colors.red : Colors.grey,
            ),
          ],
        ),
      );
    });
  }
}

/// Widget de fila de estadística con contador animado profesional
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [color, color.withValues(alpha: 0.7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final numericValue = int.tryParse(value) ?? 0;
    final hasValue = numericValue > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: hasValue ? 0.4 : 0.2),
          width: hasValue ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: hasValue ? 0.15 : 0.08),
            blurRadius: hasValue ? 10 : 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono con gradiente y efecto glow
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 14),
          // Label con estilo mejorado
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ElegantLightTheme.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasValue ? 'Activo' : 'Sin registros',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: hasValue
                            ? color.withValues(alpha: 0.8)
                            : ElegantLightTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Contador con badge animado
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: numericValue.toDouble()),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, child) {
              return Container(
                constraints: const BoxConstraints(minWidth: 48),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: hasValue ? gradient : null,
                  color: hasValue ? null : ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: hasValue ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Text(
                  animatedValue.round().toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: hasValue ? Colors.white : ElegantLightTheme.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final InvoiceListController controller;

  const _FilterSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Filtros',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Estado',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterChip(
              label: 'Todos',
              isSelected: controller.selectedStatus == null,
              onTap: () => controller.filterByStatus(null),
              color: Colors.grey,
            ),
            _FilterChip(
              label: 'Pagadas',
              isSelected: controller.selectedStatus == InvoiceStatus.paid,
              onTap: () => controller.filterByStatus(InvoiceStatus.paid),
              color: Colors.green,
            ),
            _FilterChip(
              label: 'Pendientes',
              isSelected: controller.selectedStatus == InvoiceStatus.pending,
              onTap: () => controller.filterByStatus(InvoiceStatus.pending),
              color: Colors.orange,
            ),
            _FilterChip(
              label: 'Canceladas',
              isSelected: controller.selectedStatus == InvoiceStatus.cancelled,
              onTap: () => controller.filterByStatus(InvoiceStatus.cancelled),
              color: Colors.red,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_hasActiveFilters(controller))
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.clearFilters,
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Limpiar Filtros'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    ));
  }

  bool _hasActiveFilters(InvoiceListController controller) {
    return controller.selectedStatus != null ||
        controller.selectedPaymentMethod != null ||
        controller.startDate != null ||
        controller.endDate != null ||
        controller.minAmount != null ||
        controller.maxAmount != null ||
        controller.searchQuery.isNotEmpty;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: ElegantLightTheme.normalAnimation,
        width: 120,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : ElegantLightTheme.glassGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : ElegantLightTheme.textSecondary.withValues(alpha: 0.3),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : ElegantLightTheme.elevatedShadow,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : ElegantLightTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _DesktopToolbar extends StatelessWidget {
  final InvoiceListController controller;

  const _DesktopToolbar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(() {
              final searchMode = controller.searchQuery.isNotEmpty;
              final count = controller.filteredInvoices.length;
              final label = searchMode ? 'Resultados' : 'Facturas';

              return Row(
                children: [
                  // Icono decorativo
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.glassGradient,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      searchMode ? Icons.search : Icons.receipt_long,
                      size: 20,
                      color: ElegantLightTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: ElegantLightTheme.textPrimary,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: ElegantLightTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              count.toString(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (controller.totalPages > 1)
                        Text(
                          controller.paginationInfo,
                          style: TextStyle(
                            fontSize: 12,
                            color: ElegantLightTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (searchMode && controller.searchQuery.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.filter_alt,
                              size: 12,
                              color: ElegantLightTheme.primaryBlue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '"${controller.searchQuery}"',
                              style: TextStyle(
                                fontSize: 12,
                                color: ElegantLightTheme.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              );
            }),
          ),
          Obx(() {
            if (controller.isSearching) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.glassGradient,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ElegantLightTheme.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Buscando...',
                      style: TextStyle(
                        fontSize: 12,
                        color: ElegantLightTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                onSelected: (value) => _handleDesktopAction(value, context, controller),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: ElegantLightTheme.infoGradient.colors.first.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.download,
                            size: 16,
                            color: ElegantLightTheme.infoGradient.colors.first,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Exportar Lista'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'stats',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.analytics,
                            size: 16,
                            color: ElegantLightTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Estadísticas'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.glassGradient,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.more_horiz,
                        size: 18,
                        color: ElegantLightTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 16,
                        color: ElegantLightTheme.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Botón Nueva Factura con tema elegante
              Container(
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                    ...ElegantLightTheme.glowShadow,
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => controller.goToCreateInvoice(),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Nueva Factura',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
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

  void _handleDesktopAction(String action, BuildContext context, InvoiceListController controller) {
    switch (action) {
      case 'export':
        Get.snackbar(
          'Próximamente',
          'La función de exportar facturas estará disponible pronto',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green.shade800,
          icon: const Icon(Icons.download, color: Colors.green),
        );
        break;
      case 'stats':
        Get.toNamed('/invoices/stats');
        break;
    }
  }
}

class _PaginationInfo extends StatelessWidget {
  final InvoiceListController controller;

  const _PaginationInfo({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Obx(() => Column(
        children: [
          LinearProgressIndicator(
            value: controller.loadingProgress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                controller.paginationInfo,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              if (controller.isLoadingMore)
                Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Cargando...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      )),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  final InvoiceListController controller;

  const _LoadMoreButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        if (controller.isLoadingMore) {
          return const Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text(
                'Cargando más facturas...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          );
        }

        return TextButton(
          onPressed: controller.canLoadMore ? controller.loadMoreInvoices : null,
          child: Text(
            controller.canLoadMore ? 'Cargar más facturas' : 'No hay más facturas',
          ),
        );
      }),
    );
  }
}

/// ✅ Indicador de carga automática al final de la lista
class _LoadMoreIndicator extends StatefulWidget {
  final InvoiceListController controller;

  const _LoadMoreIndicator({required this.controller});

  @override
  State<_LoadMoreIndicator> createState() => _LoadMoreIndicatorState();
}

class _LoadMoreIndicatorState extends State<_LoadMoreIndicator> {
  @override
  void initState() {
    super.initState();
    // Cargar automáticamente cuando el indicador se hace visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.canLoadMore && !widget.controller.isLoadingMore) {
        widget.controller.loadMoreInvoices();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (widget.controller.isLoadingMore) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ElegantLightTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Cargando más facturas...',
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }

      // Si ya no hay más páginas pero el widget está visible
      if (!widget.controller.hasNextPage) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 16,
                color: ElegantLightTheme.textTertiary,
              ),
              const SizedBox(width: 8),
              Text(
                'Has visto todas las facturas',
                style: TextStyle(
                  color: ElegantLightTheme.textTertiary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }

      return const SizedBox(height: 24);
    });
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearching;

  const _EmptyState({required this.isSearching});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.receipt_long,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'Sin resultados' : 'No hay facturas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Intenta con otros términos de búsqueda'
                : 'Crea tu primera factura',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class FuturisticContainer extends StatelessWidget {
  final Widget child;
  final bool hasGlow;

  const FuturisticContainer({
    super.key,
    required this.child,
    this.hasGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.textSecondary.withValues(alpha: 0.2),
        ),
        boxShadow: hasGlow ? ElegantLightTheme.glowShadow : ElegantLightTheme.elevatedShadow,
      ),
      child: child,
    );
  }
}
