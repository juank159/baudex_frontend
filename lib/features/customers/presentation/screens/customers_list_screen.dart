// // lib/features/customers/presentation/screens/customers_list_screen.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../../app/core/utils/responsive.dart';
// import '../../../../app/shared/widgets/custom_text_field.dart';
// import '../../../../app/shared/widgets/custom_button.dart';
// import '../../../../app/shared/widgets/loading_widget.dart';
// import '../controllers/customers_controller.dart';
// import '../widgets/customer_card_widget.dart';
// import '../widgets/customer_filter_widget.dart';
// import '../widgets/customer_stats_widget.dart';
// import '../../domain/entities/customer.dart';

// class CustomersListScreen extends GetView<CustomersController> {
//   const CustomersListScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: _buildAppBar(context),
//       body: ResponsiveLayout(
//         mobile: _buildMobileLayout(context),
//         tablet: _buildTabletLayout(context),
//         desktop: _buildDesktopLayout(context),
//       ),
//       floatingActionButton: _buildFloatingActionButton(context),
//     );
//   }

//   PreferredSizeWidget _buildAppBar(BuildContext context) {
//     return AppBar(
//       title: const Text('Clientes'),
//       elevation: 0,
//       leading: IconButton(
//         icon: const Icon(Icons.arrow_back),
//         onPressed: () => Get.offAllNamed('/dashboard'),
//       ),
//       actions: [
//         // Búsqueda rápida en móvil
//         if (context.isMobile)
//           IconButton(
//             icon: const Icon(Icons.search),
//             onPressed: () => _showMobileSearch(context),
//           ),

//         // Filtros
//         IconButton(
//           icon: const Icon(Icons.filter_list),
//           onPressed: () => _showFilters(context),
//         ),

//         // Refrescar
//         IconButton(
//           icon: const Icon(Icons.refresh),
//           onPressed: controller.refreshCustomers,
//         ),

//         // Menú de opciones
//         PopupMenuButton<String>(
//           onSelected: (value) => _handleMenuAction(value, context),
//           itemBuilder:
//               (context) => [
//                 const PopupMenuItem(
//                   value: 'stats',
//                   child: Row(
//                     children: [
//                       Icon(Icons.analytics),
//                       SizedBox(width: 8),
//                       Text('Estadísticas'),
//                     ],
//                   ),
//                 ),
//                 const PopupMenuItem(
//                   value: 'export',
//                   child: Row(
//                     children: [
//                       Icon(Icons.download),
//                       SizedBox(width: 8),
//                       Text('Exportar'),
//                     ],
//                   ),
//                 ),
//                 const PopupMenuItem(
//                   value: 'import',
//                   child: Row(
//                     children: [
//                       Icon(Icons.upload),
//                       SizedBox(width: 8),
//                       Text('Importar'),
//                     ],
//                   ),
//                 ),
//               ],
//         ),
//       ],
//     );
//   }

//   Widget _buildMobileLayout(BuildContext context) {
//     return Obx(() {
//       if (controller.isLoading) {
//         return const LoadingWidget(message: 'Cargando clientes...');
//       }

//       return Column(
//         children: [
//           // Estadísticas compactas
//           if (controller.stats != null)
//             Padding(
//               padding: context.responsivePadding,
//               child: CustomerStatsWidget(
//                 stats: controller.stats!,
//                 isCompact: true,
//               ),
//             ),

//           // Lista de clientes
//           Expanded(child: _buildCustomersList(context)),
//         ],
//       );
//     });
//   }

//   Widget _buildTabletLayout(BuildContext context) {
//     return Obx(() {
//       if (controller.isLoading) {
//         return const LoadingWidget(message: 'Cargando clientes...');
//       }

//       return Row(
//         children: [
//           // Panel lateral con filtros y estadísticas
//           Container(
//             width: 300,
//             decoration: BoxDecoration(
//               color: Colors.grey.shade50,
//               border: Border(right: BorderSide(color: Colors.grey.shade300)),
//             ),
//             child: Column(
//               children: [
//                 // Búsqueda
//                 Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: _buildSearchField(context),
//                 ),

//                 // Filtros
//                 Expanded(
//                   child: SingleChildScrollView(
//                     child: Column(
//                       children: [
//                         // Estadísticas
//                         if (controller.stats != null)
//                           Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 16),
//                             child: CustomerStatsWidget(
//                               stats: controller.stats!,
//                               isCompact: false,
//                             ),
//                           ),

//                         const SizedBox(height: 16),

//                         // Filtros
//                         const CustomerFilterWidget(),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Lista principal
//           Expanded(child: _buildCustomersList(context)),
//         ],
//       );
//     });
//   }

//   Widget _buildDesktopLayout(BuildContext context) {
//     return Obx(() {
//       if (controller.isLoading) {
//         return const LoadingWidget(message: 'Cargando clientes...');
//       }

//       return Row(
//         children: [
//           // Panel lateral izquierdo
//           Container(
//             width: 350,
//             decoration: BoxDecoration(
//               color: Colors.grey.shade50,
//               border: Border(right: BorderSide(color: Colors.grey.shade300)),
//             ),
//             child: Column(
//               children: [
//                 // Header del panel
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Theme.of(context).primaryColor.withOpacity(0.1),
//                     border: Border(
//                       bottom: BorderSide(color: Colors.grey.shade300),
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(
//                         Icons.filter_list,
//                         color: Theme.of(context).primaryColor,
//                       ),
//                       const SizedBox(width: 8),
//                       Text(
//                         'Filtros y Estadísticas',
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: Theme.of(context).primaryColor,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 // Búsqueda
//                 Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: _buildSearchField(context),
//                 ),

//                 // Contenido scrolleable
//                 Expanded(
//                   child: SingleChildScrollView(
//                     child: Column(
//                       children: [
//                         // Estadísticas
//                         if (controller.stats != null)
//                           Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 16),
//                             child: CustomerStatsWidget(
//                               stats: controller.stats!,
//                               isCompact: false,
//                             ),
//                           ),

//                         const SizedBox(height: 24),

//                         // Filtros
//                         const CustomerFilterWidget(),

//                         const SizedBox(height: 16),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Área principal
//           Expanded(
//             child: Column(
//               children: [
//                 // Toolbar superior
//                 _buildDesktopToolbar(context),

//                 // Lista de clientes
//                 Expanded(child: _buildCustomersList(context)),
//               ],
//             ),
//           ),
//         ],
//       );
//     });
//   }

//   Widget _buildDesktopToolbar(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
//       ),
//       child: Row(
//         children: [
//           // Información de resultados
//           Expanded(
//             child: Obx(() {
//               final total = controller.totalItems;
//               final current = controller.customers.length;

//               return Text(
//                 'Mostrando $current de $total clientes',
//                 style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
//               );
//             }),
//           ),

//           // Acciones rápidas
//           CustomButton(
//             text: 'Nuevo Cliente',
//             icon: Icons.person_add,
//             onPressed: controller.goToCreateCustomer,
//           ),

//           const SizedBox(width: 12),

//           CustomButton(
//             text: 'Estadísticas',
//             icon: Icons.analytics,
//             type: ButtonType.outline,
//             onPressed: () => _showStatsDialog(context),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSearchField(BuildContext context) {
//     return CustomTextField(
//       controller: controller.searchController,
//       label: 'Buscar clientes',
//       hint: 'Nombre, email, documento...',
//       prefixIcon: Icons.search,
//       suffixIcon: controller.isSearchMode ? Icons.clear : null,
//       onSuffixIconPressed:
//           controller.isSearchMode ? controller.clearFilters : null,
//       onChanged: controller.updateSearch,
//     );
//   }

//   Widget _buildCustomersList(BuildContext context) {
//     return Obx(() {
//       final customers =
//           controller.isSearchMode
//               ? controller.searchResults
//               : controller.customers;

//       if (customers.isEmpty && !controller.isLoading) {
//         return _buildEmptyState(context);
//       }

//       return RefreshIndicator(
//         onRefresh: controller.refreshCustomers,
//         child: ListView.builder(
//           controller: controller.scrollController,
//           padding: context.responsivePadding,
//           itemCount: customers.length + (controller.isLoadingMore ? 1 : 0),
//           itemBuilder: (context, index) {
//             if (index >= customers.length) {
//               return const Padding(
//                 padding: EdgeInsets.all(16),
//                 child: Center(child: CircularProgressIndicator()),
//               );
//             }

//             final customer = customers[index];
//             return Padding(
//               padding: const EdgeInsets.only(bottom: 12),
//               child: CustomerCardWidget(
//                 customer: customer,
//                 onTap: () => controller.showCustomerDetails(customer.id),
//                 onEdit: () => controller.goToEditCustomer(customer.id),
//                 onDelete: () => controller.confirmDelete(customer),
//               ),
//             );
//           },
//         ),
//       );
//     });
//   }

//   Widget _buildEmptyState(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.people_outline, size: 100, color: Colors.grey.shade400),
//           SizedBox(height: context.verticalSpacing),
//           Text(
//             controller.isSearchMode
//                 ? 'No se encontraron clientes'
//                 : 'No hay clientes registrados',
//             style: TextStyle(
//               fontSize: 18,
//               color: Colors.grey.shade600,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           SizedBox(height: context.verticalSpacing / 2),
//           Text(
//             controller.isSearchMode
//                 ? 'Intenta con otros términos de búsqueda'
//                 : 'Registra tu primer cliente para comenzar',
//             style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
//             textAlign: TextAlign.center,
//           ),
//           SizedBox(height: context.verticalSpacing * 2),
//           if (!controller.isSearchMode)
//             CustomButton(
//               text: 'Registrar Primer Cliente',
//               icon: Icons.person_add,
//               onPressed: controller.goToCreateCustomer,
//             )
//           else
//             CustomButton(
//               text: 'Limpiar Búsqueda',
//               icon: Icons.clear,
//               type: ButtonType.outline,
//               onPressed: controller.clearFilters,
//             ),
//         ],
//       ),
//     );
//   }

//   Widget? _buildFloatingActionButton(BuildContext context) {
//     if (context.isMobile) {
//       return FloatingActionButton(
//         onPressed: controller.goToCreateCustomer,
//         child: const Icon(Icons.person_add),
//       );
//     }
//     return null;
//   }

//   // ==================== ACTION METHODS ====================

//   void _handleMenuAction(String action, BuildContext context) {
//     switch (action) {
//       case 'stats':
//         _showStatsDialog(context);
//         break;
//       case 'export':
//         _showExportDialog(context);
//         break;
//       case 'import':
//         _showImportDialog(context);
//         break;
//     }
//   }

//   void _showMobileSearch(BuildContext context) {
//     showSearch(context: context, delegate: CustomerSearchDelegate(controller));
//   }

//   void _showFilters(BuildContext context) {
//     Get.bottomSheet(
//       Container(
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Handle
//             Container(
//               width: 40,
//               height: 4,
//               margin: const EdgeInsets.symmetric(vertical: 12),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade300,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),

//             // Title
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Row(
//                 children: [
//                   const Text(
//                     'Filtros',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   const Spacer(),
//                   TextButton(
//                     onPressed: () {
//                       controller.clearFilters();
//                       Get.back();
//                     },
//                     child: const Text('Limpiar'),
//                   ),
//                 ],
//               ),
//             ),

//             // Filters content
//             const Expanded(
//               child: SingleChildScrollView(child: CustomerFilterWidget()),
//             ),

//             // Actions
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: CustomButton(
//                       text: 'Cancelar',
//                       type: ButtonType.outline,
//                       onPressed: () => Get.back(),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: CustomButton(
//                       text: 'Aplicar',
//                       onPressed: () => Get.back(),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//       isScrollControlled: true,
//     );
//   }

//   void _showStatsDialog(BuildContext context) {
//     if (controller.stats == null) {
//       Get.snackbar(
//         'Sin datos',
//         'Las estadísticas no están disponibles',
//         snackPosition: SnackPosition.TOP,
//       );
//       return;
//     }

//     Get.dialog(
//       AlertDialog(
//         title: const Text('Estadísticas de Clientes'),
//         content: SizedBox(
//           width: 400,
//           child: CustomerStatsWidget(
//             stats: controller.stats!,
//             isCompact: false,
//           ),
//         ),
//         actions: [
//           TextButton(onPressed: () => Get.back(), child: const Text('Cerrar')),
//         ],
//       ),
//     );
//   }

//   void _showExportDialog(BuildContext context) {
//     Get.dialog(
//       AlertDialog(
//         title: const Text('Exportar Clientes'),
//         content: const Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text('Selecciona el formato de exportación:'),
//             SizedBox(height: 16),
//             Text('Funcionalidad pendiente de implementar'),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: const Text('Cancelar'),
//           ),
//           TextButton(
//             onPressed: () {
//               Get.back();
//               Get.snackbar(
//                 'Exportar',
//                 'Funcionalidad pendiente de implementar',
//                 snackPosition: SnackPosition.TOP,
//               );
//             },
//             child: const Text('Exportar'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showImportDialog(BuildContext context) {
//     Get.dialog(
//       AlertDialog(
//         title: const Text('Importar Clientes'),
//         content: const Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text('Selecciona el archivo a importar:'),
//             SizedBox(height: 16),
//             Text('Funcionalidad pendiente de implementar'),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: const Text('Cancelar'),
//           ),
//           TextButton(
//             onPressed: () {
//               Get.back();
//               Get.snackbar(
//                 'Importar',
//                 'Funcionalidad pendiente de implementar',
//                 snackPosition: SnackPosition.TOP,
//               );
//             },
//             child: const Text('Importar'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ==================== SEARCH DELEGATE ====================

// class CustomerSearchDelegate extends SearchDelegate<Customer?> {
//   final CustomersController controller;

//   CustomerSearchDelegate(this.controller);

//   @override
//   String get searchFieldLabel => 'Buscar clientes...';

//   @override
//   List<Widget> buildActions(BuildContext context) {
//     return [
//       IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
//     ];
//   }

//   @override
//   Widget buildLeading(BuildContext context) {
//     return IconButton(
//       icon: const Icon(Icons.arrow_back),
//       onPressed: () => close(context, null),
//     );
//   }

//   @override
//   Widget buildResults(BuildContext context) {
//     if (query.length < 2) {
//       return const Center(
//         child: Text('Ingresa al menos 2 caracteres para buscar'),
//       );
//     }

//     controller.searchCustomers(query);

//     return Obx(() {
//       if (controller.isSearching) {
//         return const Center(child: CircularProgressIndicator());
//       }

//       final results = controller.searchResults;
//       if (results.isEmpty) {
//         return const Center(child: Text('No se encontraron resultados'));
//       }

//       return ListView.builder(
//         itemCount: results.length,
//         itemBuilder: (context, index) {
//           final customer = results[index];
//           return ListTile(
//             leading: CircleAvatar(
//               backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
//               child: Icon(Icons.person, color: Theme.of(context).primaryColor),
//             ),
//             title: Text(customer.displayName),
//             subtitle: Text('${customer.email} • ${customer.formattedDocument}'),
//             trailing: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               decoration: BoxDecoration(
//                 color:
//                     customer.isActive
//                         ? Colors.green.withOpacity(0.1)
//                         : Colors.orange.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Text(
//                 customer.status.name.toUpperCase(),
//                 style: TextStyle(
//                   color: customer.isActive ? Colors.green : Colors.orange,
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             onTap: () {
//               close(context, customer);
//               controller.showCustomerDetails(customer.id);
//             },
//           );
//         },
//       );
//     });
//   }

//   @override
//   Widget buildSuggestions(BuildContext context) {
//     if (query.isEmpty) {
//       return const Center(child: Text('Escribe para buscar clientes'));
//     }

//     return buildResults(context);
//   }
// }

// lib/features/customers/presentation/screens/customers_list_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Get.offAllNamed('/dashboard'),
      ),
      actions: [
        // Búsqueda rápida en móvil
        if (context.isMobile)
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
            // También refrescar estadísticas
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
          itemBuilder:
              (context) => [
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
          // Estadísticas compactas usando el StatsController
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
          // Panel lateral con filtros y estadísticas
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                // Búsqueda
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildSearchField(context),
                ),

                // Filtros
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Estadísticas
                        _buildSidebarStats(context),

                        const SizedBox(height: 16),

                        // Filtros
                        const CustomerFilterWidget(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista principal
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
          // Panel lateral izquierdo
          Container(
            width: 350,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                // Header del panel
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Filtros y Estadísticas',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Búsqueda
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildSearchField(context),
                ),

                // Contenido scrolleable
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Estadísticas
                        _buildSidebarStats(context),

                        const SizedBox(height: 24),

                        // Filtros
                        const CustomerFilterWidget(),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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

  Widget _buildCompactStats(BuildContext context) {
    return GetBuilder<CustomerStatsController>(
      init: Get.find<CustomerStatsController>(),
      builder: (statsCtrl) {
        return Obx(() {
          if (statsCtrl.stats != null) {
            return Padding(
              padding: context.responsivePadding,
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

  Widget _buildSidebarStats(BuildContext context) {
    return GetBuilder<CustomerStatsController>(
      init: Get.find<CustomerStatsController>(),
      builder: (statsCtrl) {
        return Obx(() {
          if (statsCtrl.stats != null) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CustomerStatsWidget(
                stats: statsCtrl.stats!,
                isCompact: false,
              ),
            );
          }
          return Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Icon(Icons.analytics, color: Colors.grey.shade400, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Cargando estadísticas...',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildDesktopToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          // Información de resultados
          Expanded(
            child: Obx(() {
              final total = controller.totalItems;
              final current = controller.customers.length;

              return Text(
                'Mostrando $current de $total clientes',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              );
            }),
          ),

          // Acciones rápidas
          CustomButton(
            text: 'Nuevo Cliente',
            icon: Icons.person_add,
            onPressed: controller.goToCreateCustomer,
          ),

          const SizedBox(width: 12),

          CustomButton(
            text: 'Estadísticas',
            icon: Icons.analytics,
            type: ButtonType.outline,
            onPressed:
                controller.goToCustomerStats, // Usar el método del controller
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
      onSuffixIconPressed:
          controller.isSearchMode ? controller.clearFilters : null,
      onChanged: controller.updateSearch,
    );
  }

  Widget _buildCustomersList(BuildContext context) {
    return Obx(() {
      final customers =
          controller.isSearchMode
              ? controller.searchResults
              : controller.customers;

      if (customers.isEmpty && !controller.isLoading) {
        return _buildEmptyState(context);
      }

      return RefreshIndicator(
        onRefresh: () async {
          await controller.refreshCustomers();
          // También refrescar estadísticas
          try {
            await statsController.refreshStats();
          } catch (e) {
            print('⚠️ StatsController no encontrado: $e');
          }
        },
        child: ListView.builder(
          controller: controller.scrollController,
          padding: context.responsivePadding,
          itemCount: customers.length + (controller.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= customers.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final customer = customers[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 100, color: Colors.grey.shade400),
          SizedBox(height: context.verticalSpacing),
          Text(
            controller.isSearchMode
                ? 'No se encontraron clientes'
                : 'No hay clientes registrados',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: context.verticalSpacing / 2),
          Text(
            controller.isSearchMode
                ? 'Intenta con otros términos de búsqueda'
                : 'Registra tu primer cliente para comenzar',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.verticalSpacing * 2),
          if (!controller.isSearchMode)
            CustomButton(
              text: 'Registrar Primer Cliente',
              icon: Icons.person_add,
              onPressed: controller.goToCreateCustomer,
            )
          else
            CustomButton(
              text: 'Limpiar Búsqueda',
              icon: Icons.clear,
              type: ButtonType.outline,
              onPressed: controller.clearFilters,
            ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    if (context.isMobile) {
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
        controller.goToCustomerStats(); // Navegar a la pantalla de estadísticas
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  const Text(
                    'Filtros',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              child: SingleChildScrollView(child: CustomerFilterWidget()),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
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
                color:
                    customer.isActive
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
