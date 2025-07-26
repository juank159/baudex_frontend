// lib/features/customers/presentation/screens/customers_list_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../controllers/customers_controller.dart';
import '../controllers/customer_stats_controller.dart';
import '../widgets/customer_card_widget.dart';
import '../widgets/customer_filter_widget.dart';
import '../widgets/customer_stats_widget.dart';
import '../../domain/entities/customer.dart';

class CustomersListScreen extends GetView<CustomersController> {
  const CustomersListScreen({super.key});

  // Acceso al controlador de estadísticas
  CustomerStatsController get statsController =>
      Get.find<CustomerStatsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      drawer: const AppDrawer(currentRoute: '/customers'),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Clientes'),
      elevation: 0,
      actions: [
        // Búsqueda rápida en móvil
        if (ResponsiveHelper.isMobile(context))
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showMobileSearch(context),
          ),

        // Filtros
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () => _showFilters(context),
        ),

        // Refrescar
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            controller.refreshCustomers();
            try {
              statsController.refreshStats();
            } catch (e) {
              print('⚠️ StatsController no encontrado: $e');
            }
          },
        ),

        // Menú de opciones
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, context),
          itemBuilder: (context) => [
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
            const PopupMenuItem(
              value: 'import',
              child: Row(
                children: [
                  Icon(Icons.upload),
                  SizedBox(width: 8),
                  Text('Importar'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Obx(() {
      if (controller.isLoading) {
        return const LoadingWidget(message: 'Cargando clientes...');
      }

      return Column(
        children: [
          // Estadísticas compactas
          _buildCompactStats(context),

          // Lista de clientes
          Expanded(child: _buildCustomersList(context)),
        ],
      );
    });
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Obx(() {
      if (controller.isLoading) {
        return const LoadingWidget(message: 'Cargando clientes...');
      }

      return Row(
        children: [
          // Panel lateral - TAMAÑO OPTIMIZADO PARA TABLET
          Container(
            width: ResponsiveHelper.responsiveValue(
              context,
              mobile: 320,
              tablet: 380,
              desktop: 420,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: _buildSidebarContent(context),
          ),

          // Lista principal
          Expanded(child: _buildCustomersList(context)),
        ],
      );
    });
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Obx(() {
      if (controller.isLoading) {
        return const LoadingWidget(message: 'Cargando clientes...');
      }

      return Row(
        children: [
          // Panel lateral - ANCHO DINÁMICO BASADO EN TAMAÑO DE PANTALLA
          Container(
            width: _calculateOptimalSidebarWidth(screenWidth),
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
                // Toolbar superior
                _buildDesktopToolbar(context),

                // Lista de clientes
                Expanded(child: _buildCustomersList(context)),
              ],
            ),
          ),
        ],
      );
    });
  }

  // ==================== NUEVOS MÉTODOS OPTIMIZADOS ====================

  /// Calcula el ancho óptimo del sidebar basado en el tamaño de pantalla
  double _calculateOptimalSidebarWidth(double screenWidth) {
    if (screenWidth < 1200) {
      return 350; // Pantallas pequeñas (1024-1199px)
    } else if (screenWidth < 1440) {
      return 400; // Pantallas medianas (1200-1439px)
    } else if (screenWidth < 1920) {
      return 450; // Pantallas grandes (1440-1919px)
    } else if (screenWidth < 2560) {
      return 500; // Pantallas muy grandes (1920-2559px)
    } else {
      return 550; // Pantallas 4K+ (2560px+)
    }
  }

  /// Contenido optimizado del sidebar
  Widget _buildSidebarContent(BuildContext context) {
    return Column(
      children: [
        // Header del panel con mejor espaciado
        _buildSidebarHeader(context),

        // Búsqueda con mejor padding
        _buildSidebarSearch(context),

        // Contenido scrolleable optimizado
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.responsiveValue(
                context,
                mobile: 12,
                tablet: 16,
                desktop: 20,
              ),
            ),
            child: Column(
              children: [
                // Estadísticas mejoradas
                _buildOptimizedStats(context),

                SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),

                // Filtros
                const CustomerFilterWidget(),

                SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Header del sidebar optimizado
  Widget _buildSidebarHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        ResponsiveHelper.responsiveValue(
          context,
          mobile: 16,
          tablet: 20,
          desktop: 24,
        ),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.filter_list,
              color: Theme.of(context).primaryColor,
              size: ResponsiveHelper.responsiveValue(
                context,
                mobile: 18,
                tablet: 20,
                desktop: 22,
              ),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context, size: SpacingSize.small)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panel de Control',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getFontSize(
                      context,
                      mobile: 16,
                      tablet: 18,
                      desktop: 20,
                      fontContext: FontContext.subtitle,
                    ),
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                if (!ResponsiveHelper.isMobile(context))
                  Text(
                    'Filtros y estadísticas',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getFontSize(
                        context,
                        mobile: 12,
                        tablet: 13,
                        desktop: 14,
                        fontContext: FontContext.caption,
                      ),
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Búsqueda del sidebar optimizada
  Widget _buildSidebarSearch(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        ResponsiveHelper.responsiveValue(
          context,
          mobile: 12,
          tablet: 16,
          desktop: 20,
        ),
      ),
      child: _buildSearchField(context),
    );
  }

  /// Estadísticas optimizadas para el sidebar
  Widget _buildOptimizedStats(BuildContext context) {
    return GetBuilder<CustomerStatsController>(
      init: Get.find<CustomerStatsController>(),
      builder: (statsCtrl) {
        return Obx(() {
          if (statsCtrl.stats != null) {
            return Container(
              width: double.infinity,
              child: CustomerStatsWidget(
                stats: statsCtrl.stats!,
                isCompact: ResponsiveHelper.isMobile(context),
              ),
            );
          }
          return _buildStatsPlaceholder(context);
        });
      },
    );
  }

  /// Placeholder mejorado para estadísticas
  Widget _buildStatsPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        ResponsiveHelper.responsiveValue(
          context,
          mobile: 16,
          tablet: 20,
          desktop: 24,
        ),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getBorderRadius(context, radiusContext: BorderRadiusContext.card),
        ),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.analytics,
            color: Colors.grey.shade400,
            size: ResponsiveHelper.responsiveValue(
              context,
              mobile: 36,
              tablet: 42,
              desktop: 48,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context, size: SpacingSize.small)),
          Text(
            'Cargando estadísticas...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: ResponsiveHelper.getFontSize(
                context,
                mobile: 12,
                tablet: 14,
                desktop: 14,
                fontContext: FontContext.caption,
              ),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStats(BuildContext context) {
    return GetBuilder<CustomerStatsController>(
      init: Get.find<CustomerStatsController>(),
      builder: (statsCtrl) {
        return Obx(() {
          if (statsCtrl.stats != null) {
            return Container(
              margin: ResponsiveHelper.getPadding(context, paddingContext: PaddingContext.compact),
              child: CustomerStatsWidget(
                stats: statsCtrl.stats!,
                isCompact: true,
              ),
            );
          }
          return const SizedBox.shrink();
        });
      },
    );
  }

  Widget _buildDesktopToolbar(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        ResponsiveHelper.responsiveValue(
          context,
          mobile: 12,
          tablet: 16,
          desktop: 20,
        ),
      ),
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
          // Información de resultados mejorada
          Expanded(
            child: Obx(() {
              final total = controller.totalItems;
              final current = controller.customers.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lista de Clientes',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getFontSize(
                        context,
                        mobile: 16,
                        tablet: 18,
                        desktop: 20,
                        fontContext: FontContext.subtitle,
                      ),
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mostrando $current de $total clientes registrados',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: ResponsiveHelper.getFontSize(
                        context,
                        mobile: 12,
                        tablet: 13,
                        desktop: 14,
                        fontContext: FontContext.caption,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),

          SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context)),

          // Acciones con mejor espaciado
          Row(
            children: [
              CustomButton(
                text: 'Estadísticas',
                icon: Icons.analytics,
                type: ButtonType.outline,
                size: ResponsiveHelper.isMobile(context) ? ButtonSize.compact : ButtonSize.medium,
                onPressed: controller.goToCustomerStats,
              ),
              
              SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context, size: SpacingSize.small)),
              
              CustomButton(
                text: 'Nuevo Cliente',
                icon: Icons.person_add,
                size: ResponsiveHelper.isMobile(context) ? ButtonSize.compact : ButtonSize.medium,
                onPressed: controller.goToCreateCustomer,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return CustomTextField(
      controller: controller.searchController,
      label: 'Buscar clientes',
      hint: 'Nombre, email, documento...',
      prefixIcon: Icons.search,
      suffixIcon: controller.isSearchMode ? Icons.clear : null,
      onSuffixIconPressed: controller.isSearchMode ? controller.clearFilters : null,
      onChanged: controller.updateSearch,
    );
  }

  Widget _buildCustomersList(BuildContext context) {
    return Obx(() {
      final customers = controller.isSearchMode
          ? controller.searchResults
          : controller.customers;

      if (customers.isEmpty && !controller.isLoading) {
        return _buildEmptyState(context);
      }

      return RefreshIndicator(
        onRefresh: () async {
          await controller.refreshCustomers();
          try {
            await statsController.refreshStats();
          } catch (e) {
            print('⚠️ StatsController no encontrado: $e');
          }
        },
        child: ListView.builder(
          controller: controller.scrollController,
          padding: ResponsiveHelper.getPadding(context, paddingContext: PaddingContext.general),
          itemCount: customers.length + (controller.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= customers.length) {
              return Padding(
                padding: EdgeInsets.all(
                  ResponsiveHelper.responsiveValue(
                    context,
                    mobile: 12,
                    tablet: 16,
                    desktop: 20,
                  ),
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final customer = customers[index];
            return Container(
              margin: EdgeInsets.only(
                bottom: ResponsiveHelper.getVerticalSpacing(
                  context,
                  size: SpacingSize.small,
                ),
              ),
              child: CustomerCardWidget(
                customer: customer,
                onTap: () => controller.showCustomerDetails(customer.id),
                onEdit: () => controller.goToEditCustomer(customer.id),
                onDelete: () => controller.confirmDelete(customer),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: ResponsiveHelper.responsiveValue(
            context,
            mobile: 300,
            tablet: 400,
            desktop: 500,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: ResponsiveHelper.responsiveValue(
                context,
                mobile: 80,
                tablet: 100,
                desktop: 120,
              ),
              color: Colors.grey.shade400,
            ),
            SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),
            
            Text(
              controller.isSearchMode
                  ? 'No se encontraron clientes'
                  : 'No hay clientes registrados',
              style: TextStyle(
                fontSize: ResponsiveHelper.getFontSize(
                  context,
                  mobile: 18,
                  tablet: 20,
                  desktop: 22,
                  fontContext: FontContext.title,
                ),
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: ResponsiveHelper.getVerticalSpacing(context, size: SpacingSize.small)),
            
            Text(
              controller.isSearchMode
                  ? 'Intenta con otros términos de búsqueda'
                  : 'Registra tu primer cliente para comenzar',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: ResponsiveHelper.getFontSize(
                  context,
                  mobile: 14,
                  tablet: 15,
                  desktop: 16,
                ),
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: ResponsiveHelper.getVerticalSpacing(context, size: SpacingSize.large)),
            
            if (!controller.isSearchMode)
              CustomButton(
                text: 'Registrar Primer Cliente',
                icon: Icons.person_add,
                size: ResponsiveHelper.isMobile(context) ? ButtonSize.medium : ButtonSize.large,
                onPressed: controller.goToCreateCustomer,
              )
            else
              CustomButton(
                text: 'Limpiar Búsqueda',
                icon: Icons.clear,
                type: ButtonType.outline,
                size: ResponsiveHelper.isMobile(context) ? ButtonSize.medium : ButtonSize.large,
                onPressed: controller.clearFilters,
              ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    if (ResponsiveHelper.isMobile(context)) {
      return FloatingActionButton(
        onPressed: controller.goToCreateCustomer,
        child: const Icon(Icons.person_add),
      );
    }
    return null;
  }

  // ==================== ACTION METHODS ====================

  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'stats':
        controller.goToCustomerStats();
        break;
      case 'export':
        _showExportDialog(context);
        break;
      case 'import':
        _showImportDialog(context);
        break;
    }
  }

  void _showMobileSearch(BuildContext context) {
    showSearch(context: context, delegate: CustomerSearchDelegate(controller));
  }

  void _showFilters(BuildContext context) {
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Filtros',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getFontSize(
                        context,
                        mobile: 18,
                        tablet: 20,
                        desktop: 22,
                        fontContext: FontContext.title,
                      ),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      controller.clearFilters();
                      Get.back();
                    },
                    child: const Text('Limpiar'),
                  ),
                ],
              ),
            ),

            // Filters content
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: CustomerFilterWidget(),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancelar',
                      type: ButtonType.outline,
                      onPressed: () => Get.back(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Aplicar',
                      onPressed: () => Get.back(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showExportDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Exportar Clientes'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Selecciona el formato de exportación:'),
            SizedBox(height: 16),
            Text('Funcionalidad pendiente de implementar'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.exportCustomersToCSV();
            },
            child: const Text('Exportar'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Importar Clientes'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Selecciona el archivo a importar:'),
            SizedBox(height: 16),
            Text('Funcionalidad pendiente de implementar'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.importCustomersFromCSV();
            },
            child: const Text('Importar'),
          ),
        ],
      ),
    );
  }
}

// ==================== SEARCH DELEGATE ====================

class CustomerSearchDelegate extends SearchDelegate<Customer?> {
  final CustomersController controller;

  CustomerSearchDelegate(this.controller);

  @override
  String get searchFieldLabel => 'Buscar clientes...';

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

    controller.searchCustomers(query);

    return Obx(() {
      if (controller.isSearching) {
        return const Center(child: CircularProgressIndicator());
      }

      final results = controller.searchResults;
      if (results.isEmpty) {
        return const Center(child: Text('No se encontraron resultados'));
      }

      return ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final customer = results[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(Icons.person, color: Theme.of(context).primaryColor),
            ),
            title: Text(customer.displayName),
            subtitle: Text('${customer.email} • ${customer.formattedDocument}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: customer.isActive
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                customer.status.name.toUpperCase(),
                style: TextStyle(
                  color: customer.isActive ? Colors.green : Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              close(context, customer);
              controller.showCustomerDetails(customer.id);
            },
          );
        },
      );
    });
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Escribe para buscar clientes'));
    }

    return buildResults(context);
  }
}