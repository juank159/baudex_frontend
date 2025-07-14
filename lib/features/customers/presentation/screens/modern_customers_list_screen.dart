// lib/features/customers/presentation/screens/modern_customers_list_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/app_scaffold.dart';
import '../../../../app/config/routes/app_routes.dart';
import '../controllers/customers_controller.dart';
import '../controllers/customer_stats_controller.dart';
import '../widgets/modern_customer_card_widget.dart';
import '../widgets/modern_customer_stats_widget.dart';
import '../widgets/modern_customer_filter_widget.dart';
import '../../domain/entities/customer.dart';

class ModernCustomersListScreen extends GetView<CustomersController> {
  const ModernCustomersListScreen({super.key});

  CustomerStatsController get statsController =>
      Get.find<CustomerStatsController>();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentRoute: AppRoutes.customers,
      appBar: _buildModernAppBar(context),
      body: ResponsiveHelper.isMobile(context)
          ? _buildMobileLayout(context)
          : _buildDesktopLayout(context),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return AppBar(
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.people,
              size: isMobile ? 18 : 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Flexible(
            child: Text(
              'Clientes',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Get.offAllNamed('/dashboard'),
      ),
      actions: [
        // Búsqueda rápida en móvil
        if (isMobile)
          IconButton(
            icon: const Icon(Icons.search, size: 20),
            onPressed: () => _showMobileSearch(context),
            tooltip: 'Buscar',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              foregroundColor: Colors.white,
            ),
          ),

        // Filtros
        IconButton(
          icon: const Icon(Icons.filter_list, size: 20),
          onPressed: () => _showFilters(context),
          tooltip: 'Filtros',
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.1),
            foregroundColor: Colors.white,
          ),
        ),

        // Refrescar
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: () {
            controller.refreshCustomers();
            try {
              statsController.refreshStats();
            } catch (e) {
              print('⚠️ StatsController no encontrado: $e');
            }
          },
          tooltip: 'Actualizar',
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.1),
            foregroundColor: Colors.white,
          ),
        ),

        // Estadísticas - Solo desktop/tablet
        if (!isMobile)
          IconButton(
            icon: const Icon(Icons.analytics, size: 20),
            onPressed: () => controller.goToCustomerStats(),
            tooltip: 'Estadísticas',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              foregroundColor: Colors.white,
            ),
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
          // Estadísticas ultra compactas
          _buildCompactStats(context),

          // Búsqueda compacta
          _buildMobileSearch(context),

          // Lista de clientes
          Expanded(child: _buildCustomersList(context)),
        ],
      );
    });
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Obx(() {
      if (controller.isLoading) {
        return const LoadingWidget(message: 'Cargando clientes...');
      }

      return Row(
        children: [
          // Panel lateral compacto
          Container(
            width: 320, // Reducido de 420 a 320
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
                // Toolbar superior compacto
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

  Widget _buildSidebarContent(BuildContext context) {
    return Column(
      children: [
        // Header del panel compacto
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16), // Reducido de 24 a 16
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
              const Expanded(
                child: Text(
                  'Panel de Control',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Búsqueda
        Container(
          padding: const EdgeInsets.all(16),
          child: _buildSearchField(context),
        ),

        // Contenido scrolleable
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Estadísticas
                _buildSidebarStats(context),

                const SizedBox(height: 16),

                // Filtros
                const ModernCustomerFilterWidget(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStats(BuildContext context) {
    return GetBuilder<CustomerStatsController>(
      init: Get.find<CustomerStatsController>(),
      builder: (statsCtrl) {
        return Obx(() {
          if (statsCtrl.stats != null) {
            return Container(
              margin: const EdgeInsets.all(16),
              child: ModernCustomerStatsWidget(
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

  Widget _buildSidebarStats(BuildContext context) {
    return GetBuilder<CustomerStatsController>(
      init: Get.find<CustomerStatsController>(),
      builder: (statsCtrl) {
        return Obx(() {
          if (statsCtrl.stats != null) {
            return ModernCustomerStatsWidget(
              stats: statsCtrl.stats!,
              isCompact: false,
            );
          }
          return _buildStatsPlaceholder(context);
        });
      },
    );
  }

  Widget _buildStatsPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.analytics,
            color: Colors.grey.shade400,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'Cargando estadísticas...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSearch(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _buildSearchField(context),
    );
  }

  Widget _buildDesktopToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16), // Reducido de 20 a 16
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
              final total = controller.totalItems;
              final current = controller.customers.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lista de Clientes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mostrando $current de $total clientes registrados',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              );
            }),
          ),

          const SizedBox(width: 16),

          // Acciones compactas
          Row(
            children: [
              CustomButton(
                text: 'Estadísticas',
                icon: Icons.analytics,
                type: ButtonType.outline,
                size: ButtonSize.compact,
                onPressed: controller.goToCustomerStats,
              ),
              
              const SizedBox(width: 12),
              
              CustomButton(
                text: 'Nuevo Cliente',
                icon: Icons.person_add,
                size: ButtonSize.compact,
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
          padding: const EdgeInsets.all(16), // Padding compacto uniforme
          itemCount: customers.length + (controller.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= customers.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final customer = customers[index];
            return ModernCustomerCardWidget(
              customer: customer,
              onTap: () => controller.showCustomerDetails(customer.id),
              onEdit: () => controller.goToEditCustomer(customer.id),
              onDelete: () => controller.confirmDelete(customer),
            );
          },
        ),
      );
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: ResponsiveHelper.isMobile(context) ? 80 : 100,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            
            Text(
              controller.isSearchMode
                  ? 'No se encontraron clientes'
                  : 'No hay clientes registrados',
              style: TextStyle(
                fontSize: ResponsiveHelper.isMobile(context) ? 18 : 20,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            Text(
              controller.isSearchMode
                  ? 'Intenta con otros términos de búsqueda'
                  : 'Registra tu primer cliente para comenzar',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            if (!controller.isSearchMode)
              CustomButton(
                text: 'Registrar Primer Cliente',
                icon: Icons.person_add,
                size: ButtonSize.medium,
                onPressed: controller.goToCreateCustomer,
              )
            else
              CustomButton(
                text: 'Limpiar Búsqueda',
                icon: Icons.clear,
                type: ButtonType.outline,
                size: ButtonSize.medium,
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

  void _showMobileSearch(BuildContext context) {
    showSearch(context: context, delegate: CustomerSearchDelegate(controller));
  }

  void _showFilters(BuildContext context) {
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Filtros',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
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
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: ModernCustomerFilterWidget(),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
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
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final customer = results[index];
          return ModernCustomerCardWidget(
            customer: customer,
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