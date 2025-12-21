// // lib/features/products/presentation/screens/product_detail_screen.dart
// import 'package:baudex_desktop/app/config/routes/app_routes.dart';
// import 'package:baudex_desktop/app/core/utils/formatters.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../../app/core/utils/responsive_helper.dart';
// import '../../../../app/core/theme/elegant_light_theme.dart';
// import '../../../../app/shared/widgets/loading_widget.dart';
// import '../controllers/product_detail_controller.dart';
// import '../../domain/entities/product.dart';
// import '../../domain/entities/product_price.dart';

// class ProductDetailScreen extends GetView<ProductDetailController> {
//   const ProductDetailScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: _buildAppBar(context),
//       backgroundColor: ElegantLightTheme.backgroundColor,
//       body: Obx(() {
//         if (controller.isLoading) {
//           return const LoadingWidget(message: 'Cargando detalles...');
//         }

//         if (!controller.hasProduct) {
//           return _buildErrorState(context);
//         }

//         return ResponsiveHelper.isMobile(context)
//             ? _buildMobileLayout(context)
//             : _buildDesktopLayout(context);
//       }),
//       floatingActionButton: _buildFloatingActionButton(context),
//     );
//   }

//   PreferredSizeWidget _buildAppBar(BuildContext context) {
//     return AppBar(
//       title: Obx(
//         () => Text(
//           controller.hasProduct ? controller.productName : 'Producto',
//           style: const TextStyle(
//             color: Colors.white,
//             fontSize: 18,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ),
//       backgroundColor: Colors.transparent,
//       elevation: 0,
//       flexibleSpace: Container(
//         decoration: BoxDecoration(
//           gradient: ElegantLightTheme.primaryGradient,
//           boxShadow: ElegantLightTheme.elevatedShadow,
//         ),
//       ),
//       leading: IconButton(
//         icon: const Icon(Icons.arrow_back, color: Colors.white),
//         onPressed: () => Get.offAllNamed(AppRoutes.products),
//       ),
//       actions: [
//         IconButton(
//           icon: const Icon(Icons.share, color: Colors.white),
//           onPressed: controller.shareProduct,
//           tooltip: 'Compartir producto',
//         ),
//         IconButton(
//           icon: const Icon(Icons.edit, color: Colors.white),
//           onPressed: controller.goToEditProduct,
//           tooltip: 'Editar producto',
//         ),
//         IconButton(
//           icon: const Icon(Icons.inventory, color: Colors.white),
//           onPressed: controller.showStockDialog,
//           tooltip: 'Gestionar stock',
//         ),
//         PopupMenuButton<String>(
//           icon: const Icon(Icons.more_vert, color: Colors.white),
//           onSelected: (value) => _handleMenuAction(value, context),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           elevation: 8,
//           itemBuilder: (context) => [
//             PopupMenuItem(
//               value: 'print_label',
//               child: Row(
//                 children: [
//                   Icon(Icons.print, color: ElegantLightTheme.primaryBlue, size: 20),
//                   const SizedBox(width: 12),
//                   Text('Imprimir Etiqueta', style: TextStyle(color: ElegantLightTheme.textPrimary, fontSize: 14)),
//                 ],
//               ),
//             ),
//             PopupMenuItem(
//               value: 'generate_report',
//               child: Row(
//                 children: [
//                   Icon(Icons.analytics, color: ElegantLightTheme.primaryBlue, size: 20),
//                   const SizedBox(width: 12),
//                   Text('Generar Reporte', style: TextStyle(color: ElegantLightTheme.textPrimary, fontSize: 14)),
//                 ],
//               ),
//             ),
//             PopupMenuItem(
//               value: 'refresh',
//               child: Row(
//                 children: [
//                   Icon(Icons.refresh, color: Colors.green.shade600, size: 20),
//                   const SizedBox(width: 12),
//                   Text('Actualizar', style: TextStyle(color: ElegantLightTheme.textPrimary, fontSize: 14)),
//                 ],
//               ),
//             ),
//             const PopupMenuDivider(),
//             PopupMenuItem(
//               value: 'delete',
//               child: Row(
//                 children: [
//                   Icon(Icons.delete, color: Colors.red.shade600, size: 20),
//                   const SizedBox(width: 12),
//                   Text('Eliminar', style: TextStyle(color: Colors.red.shade600, fontSize: 14, fontWeight: FontWeight.w500)),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   // ============================= MOBILE LAYOUT =============================
//   Widget _buildMobileLayout(BuildContext context) {
//     return Column(
//       children: [
//         _buildCompactHeader(context),
//         _buildElegantTabs(context),
//         Expanded(child: _buildTabContent(context)),
//       ],
//     );
//   }

//   Widget _buildCompactHeader(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.all(12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: ElegantLightTheme.cardGradient,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: ElegantLightTheme.elevatedShadow,
//       ),
//       child: Obx(() {
//         final product = controller.product!;
//         return Row(
//           children: [
//             Container(
//               width: 70,
//               height: 70,
//               decoration: BoxDecoration(
//                 gradient: _getStockGradient(product),
//                 borderRadius: BorderRadius.circular(14),
//                 boxShadow: [
//                   BoxShadow(
//                     color: _getStockColor(product).withValues(alpha: 0.3),
//                     blurRadius: 12,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: Center(
//                 child: Icon(
//                   _getProductIcon(product),
//                   color: Colors.white,
//                   size: 35,
//                 ),
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     product.name,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: ElegantLightTheme.textPrimary,
//                     ),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'SKU: ${product.sku}',
//                     style: const TextStyle(
//                       fontSize: 13,
//                       color: ElegantLightTheme.textSecondary,
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//                         decoration: BoxDecoration(
//                           gradient: _getStockGradient(product).scale(0.3),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Text(
//                           _getStockText(product),
//                           style: TextStyle(
//                             color: _getStockColor(product),
//                             fontSize: 11,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       if (product.defaultPrice != null)
//                         Text(
//                           AppFormatters.formatPrice(product.defaultPrice!.finalAmount),
//                           style: TextStyle(
//                             fontSize: 15,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.green.shade700,
//                           ),
//                         ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         );
//       }),
//     );
//   }

//   Widget _buildElegantTabs(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       height: 65,
//       decoration: BoxDecoration(
//         gradient: ElegantLightTheme.cardGradient,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: ElegantLightTheme.elevatedShadow,
//       ),
//       child: Obx(
//         () => Row(
//           children: [
//             Expanded(
//               child: _buildTabButton(
//                 title: 'Detalles',
//                 icon: Icons.info_outline,
//                 index: 0,
//                 isSelected: controller.currentTabIndex == 0,
//               ),
//             ),
//             Expanded(
//               child: _buildTabButton(
//                 title: 'Precios',
//                 icon: Icons.sell_outlined,
//                 index: 1,
//                 isSelected: controller.currentTabIndex == 1,
//               ),
//             ),
//             Expanded(
//               child: _buildTabButton(
//                 title: 'Movimientos',
//                 icon: Icons.swap_horiz,
//                 index: 2,
//                 isSelected: controller.currentTabIndex == 2,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTabButton({
//     required String title,
//     required IconData icon,
//     required int index,
//     required bool isSelected,
//   }) {
//     return AnimatedContainer(
//       duration: ElegantLightTheme.normalAnimation,
//       curve: ElegantLightTheme.smoothCurve,
//       margin: const EdgeInsets.all(6),
//       decoration: BoxDecoration(
//         gradient: isSelected ? ElegantLightTheme.primaryGradient : null,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: isSelected ? ElegantLightTheme.glowShadow : null,
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(12),
//           onTap: () => controller.tabController.animateTo(index),
//           child: Container(
//             padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   icon,
//                   color: isSelected ? Colors.white : ElegantLightTheme.textSecondary,
//                   size: 18,
//                 ),
//                 const SizedBox(height: 3),
//                 Text(
//                   title,
//                   style: TextStyle(
//                     color: isSelected ? Colors.white : ElegantLightTheme.textSecondary,
//                     fontSize: 10,
//                     fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   textAlign: TextAlign.center,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTabContent(BuildContext context) {
//     return TabBarView(
//       controller: controller.tabController,
//       children: [
//         SingleChildScrollView(
//           padding: const EdgeInsets.all(12),
//           child: _buildProductDetails(context),
//         ),
//         SingleChildScrollView(
//           padding: const EdgeInsets.all(12),
//           child: _buildPricesSection(context),
//         ),
//         SingleChildScrollView(
//           padding: const EdgeInsets.all(12),
//           child: _buildMovementsSection(context),
//         ),
//       ],
//     );
//   }

//   // ============================= DESKTOP LAYOUT =============================
//   Widget _buildDesktopLayout(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           flex: 3,
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               children: [
//                 _buildDesktopHeader(context),
//                 const SizedBox(height: 20),
//                 _buildProductDetails(context),
//               ],
//             ),
//           ),
//         ),
//         _buildElegantSidebar(context),
//       ],
//     );
//   }

//   Widget _buildDesktopHeader(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         gradient: ElegantLightTheme.cardGradient,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: ElegantLightTheme.elevatedShadow,
//       ),
//       child: Obx(() {
//         final product = controller.product!;
//         return Row(
//           children: [
//             Container(
//               width: 100,
//               height: 100,
//               decoration: BoxDecoration(
//                 gradient: _getStockGradient(product),
//                 borderRadius: BorderRadius.circular(18),
//                 boxShadow: [
//                   BoxShadow(
//                     color: _getStockColor(product).withValues(alpha: 0.3),
//                     blurRadius: 15,
//                     offset: const Offset(0, 5),
//                   ),
//                 ],
//               ),
//               child: Center(
//                 child: Icon(
//                   _getProductIcon(product),
//                   color: Colors.white,
//                   size: 50,
//                 ),
//               ),
//             ),
//             const SizedBox(width: 24),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     product.name,
//                     style: const TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: ElegantLightTheme.textPrimary,
//                       letterSpacing: -0.5,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'SKU: ${product.sku}',
//                     style: const TextStyle(
//                       fontSize: 15,
//                       color: ElegantLightTheme.textSecondary,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   if (product.barcode != null) ...[
//                     const SizedBox(height: 4),
//                     Text(
//                       'Código: ${product.barcode}',
//                       style: const TextStyle(
//                         fontSize: 14,
//                         color: ElegantLightTheme.textSecondary,
//                       ),
//                     ),
//                   ],
//                   const SizedBox(height: 12),
//                   Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                         decoration: BoxDecoration(
//                           color: product.isActive ? Colors.green.shade100 : Colors.orange.shade100,
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Text(
//                           product.isActive ? 'ACTIVO' : 'INACTIVO',
//                           style: TextStyle(
//                             color: product.isActive ? Colors.green.shade800 : Colors.orange.shade800,
//                             fontSize: 11,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                         decoration: BoxDecoration(
//                           gradient: _getStockGradient(product).scale(0.2),
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(
//                             color: _getStockColor(product).withValues(alpha: 0.4),
//                             width: 1.5,
//                           ),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(
//                               _getStockIcon(product),
//                               size: 12,
//                               color: _getStockColor(product),
//                             ),
//                             const SizedBox(width: 6),
//                             Text(
//                               _getStockText(product),
//                               style: TextStyle(
//                                 color: _getStockColor(product),
//                                 fontSize: 11,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   if (product.description != null) ...[
//                     const SizedBox(height: 12),
//                     Text(
//                       product.description!,
//                       style: const TextStyle(
//                         fontSize: 14,
//                         color: ElegantLightTheme.textSecondary,
//                         height: 1.4,
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//             if (product.defaultPrice != null)
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   Text(
//                     AppFormatters.formatPrice(product.defaultPrice!.finalAmount),
//                     style: TextStyle(
//                       fontSize: 28,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.green.shade700,
//                     ),
//                   ),
//                   if (product.defaultPrice!.hasDiscount)
//                     Text(
//                       AppFormatters.formatPrice(product.defaultPrice!.amount),
//                       style: const TextStyle(
//                         fontSize: 15,
//                         decoration: TextDecoration.lineThrough,
//                         color: ElegantLightTheme.textTertiary,
//                       ),
//                     ),
//                 ],
//               ),
//           ],
//         );
//       }),
//     );
//   }

//   Widget _buildElegantSidebar(BuildContext context) {
//     return Container(
//       width: 320,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.08),
//             blurRadius: 20,
//             offset: const Offset(-5, 0),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           // Tabs header
//           Container(
//             height: 75,
//             margin: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               gradient: ElegantLightTheme.cardGradient,
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: ElegantLightTheme.elevatedShadow,
//             ),
//             child: Obx(
//               () => Row(
//                 children: [
//                   Expanded(
//                     child: _buildSidebarTab(
//                       title: 'Detalles',
//                       icon: Icons.info_outline,
//                       index: 0,
//                       isSelected: controller.currentTabIndex == 0,
//                     ),
//                   ),
//                   Expanded(
//                     child: _buildSidebarTab(
//                       title: 'Precios',
//                       icon: Icons.sell_outlined,
//                       index: 1,
//                       isSelected: controller.currentTabIndex == 1,
//                     ),
//                   ),
//                   Expanded(
//                     child: _buildSidebarTab(
//                       title: 'Historial',
//                       icon: Icons.history,
//                       index: 2,
//                       isSelected: controller.currentTabIndex == 2,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // Content
//           Expanded(
//             child: TabBarView(
//               controller: controller.tabController,
//               children: [
//                 _buildSidebarDetailsTab(),
//                 _buildSidebarPricesTab(),
//                 _buildSidebarMovementsTab(),
//               ],
//             ),
//           ),

//           // Action buttons
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: _buildSidebarActions(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSidebarTab({
//     required String title,
//     required IconData icon,
//     required int index,
//     required bool isSelected,
//   }) {
//     return AnimatedContainer(
//       duration: ElegantLightTheme.normalAnimation,
//       curve: ElegantLightTheme.smoothCurve,
//       margin: const EdgeInsets.all(6),
//       decoration: BoxDecoration(
//         gradient: isSelected ? ElegantLightTheme.primaryGradient : null,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: isSelected ? ElegantLightTheme.glowShadow : null,
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(12),
//           onTap: () => controller.tabController.animateTo(index),
//           child: Container(
//             padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   icon,
//                   color: isSelected ? Colors.white : ElegantLightTheme.textSecondary,
//                   size: 18,
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   title,
//                   style: TextStyle(
//                     color: isSelected ? Colors.white : ElegantLightTheme.textSecondary,
//                     fontSize: 10,
//                     fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   textAlign: TextAlign.center,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSidebarDetailsTab() {
//     return Obx(() {
//       final product = controller.product!;
//       return SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildSidebarSection(
//               title: 'Stock',
//               items: [
//                 _buildSidebarInfoRow(
//                   'Actual',
//                   '${AppFormatters.formatStock(product.stock)} ${product.unit ?? "uds"}',
//                   Icons.inventory_2_outlined,
//                   valueColor: _getStockColor(product),
//                 ),
//                 _buildSidebarInfoRow(
//                   'Mínimo',
//                   '${AppFormatters.formatStock(product.minStock)} ${product.unit ?? "uds"}',
//                   Icons.warning_amber,
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             _buildSidebarSection(
//               title: 'Información',
//               items: [
//                 _buildSidebarInfoRow('Tipo', product.type.name.toUpperCase(), Icons.category_outlined),
//                 _buildSidebarInfoRow('Categoría', product.category?.name ?? 'N/A', Icons.folder_outlined),
//                 _buildSidebarInfoRow('Unidad', product.unit ?? 'pcs', Icons.straighten),
//               ],
//             ),
//             const SizedBox(height: 16),
//             _buildSidebarSection(
//               title: 'Impuestos',
//               items: [
//                 _buildSidebarInfoRow(
//                   'Categoría',
//                   product.taxCategory.displayName,
//                   Icons.receipt_long_outlined,
//                 ),
//                 _buildSidebarInfoRow(
//                   'Tasa',
//                   '${AppFormatters.formatNumber(product.taxRate)}%',
//                   Icons.percent,
//                 ),
//               ],
//             ),
//           ],
//         ),
//       );
//     });
//   }

//   Widget _buildSidebarPricesTab() {
//     return Obx(() {
//       final product = controller.product!;
//       if (product.prices == null || product.prices!.isEmpty) {
//         return Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.price_change_outlined, size: 60, color: ElegantLightTheme.textTertiary),
//               const SizedBox(height: 16),
//               Text(
//                 'Sin precios',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: ElegantLightTheme.textSecondary,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         );
//       }

//       return ListView.builder(
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         itemCount: product.prices!.length,
//         itemBuilder: (context, index) {
//           final price = product.prices![index];
//           return _buildSidebarPriceCard(price);
//         },
//       );
//     });
//   }

//   Widget _buildSidebarMovementsTab() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.history, size: 60, color: ElegantLightTheme.textTertiary),
//           const SizedBox(height: 16),
//           Text(
//             'Historial de Movimientos',
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//               color: ElegantLightTheme.textSecondary,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 40),
//             child: Text(
//               'Funcionalidad pendiente',
//               style: TextStyle(
//                 color: ElegantLightTheme.textTertiary,
//                 fontSize: 12,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSidebarSection({required String title, required List<Widget> items}) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: const TextStyle(
//             fontSize: 12,
//             fontWeight: FontWeight.bold,
//             color: ElegantLightTheme.primaryBlue,
//             letterSpacing: 0.5,
//           ),
//         ),
//         const SizedBox(height: 12),
//         ...items,
//       ],
//     );
//   }

//   Widget _buildSidebarInfoRow(String label, String value, IconData icon, {Color? valueColor}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Row(
//         children: [
//           Icon(icon, size: 16, color: ElegantLightTheme.textTertiary),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 12,
//                 color: ElegantLightTheme.textSecondary,
//               ),
//             ),
//           ),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//               color: valueColor ?? ElegantLightTheme.textPrimary,
//             ),
//             textAlign: TextAlign.end,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSidebarPriceCard(dynamic price) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         gradient: ElegantLightTheme.cardGradient,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 _getPriceTypeDisplayName(price.type),
//                 style: const TextStyle(
//                   fontSize: 11,
//                   fontWeight: FontWeight.bold,
//                   color: ElegantLightTheme.primaryBlue,
//                 ),
//               ),
//               Text(
//                 AppFormatters.formatPrice(price.finalAmount),
//                 style: TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.green.shade700,
//                 ),
//               ),
//             ],
//           ),
//           if (_hasDiscount(price)) ...[
//             const SizedBox(height: 6),
//             Row(
//               children: [
//                 Text(
//                   'Antes: ${AppFormatters.formatPrice(price.amount)}',
//                   style: const TextStyle(
//                     fontSize: 10,
//                     decoration: TextDecoration.lineThrough,
//                     color: ElegantLightTheme.textTertiary,
//                   ),
//                 ),
//                 const SizedBox(width: 6),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                   decoration: BoxDecoration(
//                     color: Colors.red.shade100,
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: Text(
//                     '-${AppFormatters.formatNumber(price.discountPercentage)}%',
//                     style: TextStyle(
//                       fontSize: 9,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.red.shade700,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildSidebarActions() {
//     return Column(
//       children: [
//         ElevatedButton.icon(
//           onPressed: controller.goToEditProduct,
//           icon: const Icon(Icons.edit, size: 18),
//           label: const Text('Editar Producto'),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: ElegantLightTheme.primaryBlue,
//             foregroundColor: Colors.white,
//             minimumSize: const Size(double.infinity, 48),
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           ),
//         ),
//         const SizedBox(height: 10),
//         ElevatedButton.icon(
//           onPressed: controller.showStockDialog,
//           icon: const Icon(Icons.inventory, size: 18),
//           label: const Text('Gestionar Stock'),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.white,
//             foregroundColor: ElegantLightTheme.primaryBlue,
//             side: const BorderSide(color: ElegantLightTheme.primaryBlue, width: 2),
//             minimumSize: const Size(double.infinity, 48),
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           ),
//         ),
//         const SizedBox(height: 10),
//         Obx(
//           () => ElevatedButton.icon(
//             onPressed: controller.isDeleting ? null : controller.confirmDelete,
//             icon: const Icon(Icons.delete, size: 18),
//             label: Text(controller.isDeleting ? 'Eliminando...' : 'Eliminar'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red.shade600,
//               foregroundColor: Colors.white,
//               minimumSize: const Size(double.infinity, 48),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // ============================= CONTENT SECTIONS =============================
//   Widget _buildProductDetails(BuildContext context) {
//     return Obx(() {
//       final product = controller.product!;

//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Información Básica
//           _buildCompactInfoCard(
//             title: 'Información Básica',
//             icon: Icons.info_outline,
//             children: [
//               _buildCompactRow('Tipo', product.type.name.toUpperCase(), Icons.category),
//               _buildCompactRow('Categoría', product.category?.name ?? 'N/A', Icons.folder),
//               _buildCompactRow('Unidad', product.unit ?? 'pcs', Icons.straighten),
//               _buildCompactRow('Creado por', product.createdBy?.fullName ?? 'N/A', Icons.person),
//             ],
//           ),
//           const SizedBox(height: 16),

//           // Gestión de Stock
//           _buildCompactInfoCard(
//             title: 'Gestión de Stock',
//             icon: Icons.inventory_2_outlined,
//             children: [
//               _buildCompactRow(
//                 'Stock Actual',
//                 '${AppFormatters.formatStock(product.stock)} ${product.unit ?? "pcs"}',
//                 Icons.inventory,
//                 valueColor: _getStockColor(product),
//               ),
//               _buildCompactRow(
//                 'Stock Mínimo',
//                 '${AppFormatters.formatStock(product.minStock)} ${product.unit ?? "pcs"}',
//                 Icons.warning_amber,
//               ),
//               if (product.isLowStock)
//                 _buildCompactRow(
//                   'Alerta',
//                   'Stock por debajo del mínimo',
//                   Icons.error,
//                   valueColor: Colors.orange,
//                 ),
//             ],
//           ),
//           const SizedBox(height: 16),

//           // Facturación Electrónica
//           _buildCompactInfoCard(
//             title: 'Facturación Electrónica',
//             icon: Icons.receipt_long_outlined,
//             children: [
//               _buildCompactRow('Categoría de Impuesto', product.taxCategory.displayName, Icons.receipt_long),
//               _buildCompactRow('Tasa de Impuesto', '${AppFormatters.formatNumber(product.taxRate)}%', Icons.percent),
//               _buildCompactRow(
//                 'Está Gravado',
//                 product.isTaxable ? 'Sí' : 'No',
//                 Icons.check_circle,
//                 valueColor: product.isTaxable ? Colors.green : Colors.grey,
//               ),
//               if (product.hasRetention) ...[
//                 if (product.retentionCategory != null)
//                   _buildCompactRow('Retención', product.retentionCategory!.displayName, Icons.money_off),
//                 if (product.retentionRate != null)
//                   _buildCompactRow('Tasa Retención', '${AppFormatters.formatNumber(product.retentionRate!)}%', Icons.trending_down),
//               ],
//             ],
//           ),
//         ],
//       );
//     });
//   }

//   Widget _buildCompactInfoCard({
//     required String title,
//     required IconData icon,
//     required List<Widget> children,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         gradient: ElegantLightTheme.cardGradient,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: ElegantLightTheme.elevatedShadow,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, size: 18, color: ElegantLightTheme.primaryBlue),
//               const SizedBox(width: 8),
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.bold,
//                   color: ElegantLightTheme.primaryBlue,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 14),
//           ...children,
//         ],
//       ),
//     );
//   }

//   Widget _buildCompactRow(String label, String value, IconData icon, {Color? valueColor}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, size: 16, color: ElegantLightTheme.textTertiary),
//           const SizedBox(width: 10),
//           Expanded(
//             flex: 2,
//             child: Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 13,
//                 color: ElegantLightTheme.textSecondary,
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 2,
//             child: Text(
//               value,
//               style: TextStyle(
//                 fontSize: 13,
//                 fontWeight: FontWeight.w600,
//                 color: valueColor ?? ElegantLightTheme.textPrimary,
//               ),
//               textAlign: TextAlign.end,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPricesSection(BuildContext context) {
//     return Obx(() {
//       final product = controller.product!;

//       if (product.prices == null || product.prices!.isEmpty) {
//         return _buildEmptyState(
//           icon: Icons.price_change_outlined,
//           title: 'Sin precios configurados',
//           message: 'Este producto no tiene precios configurados',
//           actionText: 'Configurar Precios',
//           onAction: controller.goToEditProduct,
//         );
//       }

//       return Column(
//         children: product.prices!.map((price) => _buildPriceCard(price)).toList(),
//       );
//     });
//   }

//   Widget _buildPriceCard(dynamic price) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 14),
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         gradient: ElegantLightTheme.cardGradient,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: ElegantLightTheme.elevatedShadow,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Text(
//                 _getPriceTypeDisplayName(price.type),
//                 style: const TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.bold,
//                   color: ElegantLightTheme.primaryBlue,
//                 ),
//               ),
//               const Spacer(),
//               Text(
//                 AppFormatters.formatPrice(price.finalAmount),
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.green.shade700,
//                 ),
//               ),
//             ],
//           ),
//           if (_hasDiscount(price)) ...[
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Text(
//                   'Precio original: ${AppFormatters.formatPrice(price.amount)}',
//                   style: const TextStyle(
//                     fontSize: 13,
//                     decoration: TextDecoration.lineThrough,
//                     color: ElegantLightTheme.textTertiary,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//                   decoration: BoxDecoration(
//                     color: Colors.red.shade100,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(
//                     '-${AppFormatters.formatNumber(price.discountPercentage)}%',
//                     style: TextStyle(
//                       fontSize: 11,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.red.shade700,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//           if (_hasMinQuantity(price)) ...[
//             const SizedBox(height: 6),
//             Text(
//               'Cantidad mínima: ${AppFormatters.formatNumber(price.minQuantity)}',
//               style: const TextStyle(
//                 fontSize: 12,
//                 color: ElegantLightTheme.textSecondary,
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildMovementsSection(BuildContext context) {
//     return _buildEmptyState(
//       icon: Icons.history,
//       title: 'Historial de Movimientos',
//       message: 'Funcionalidad pendiente de implementar',
//       actionText: null,
//       onAction: null,
//     );
//   }

//   Widget _buildEmptyState({
//     required IconData icon,
//     required String title,
//     required String message,
//     String? actionText,
//     VoidCallback? onAction,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(40),
//       decoration: BoxDecoration(
//         gradient: ElegantLightTheme.cardGradient,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: ElegantLightTheme.elevatedShadow,
//       ),
//       child: Column(
//         children: [
//           Icon(icon, size: 60, color: ElegantLightTheme.textTertiary),
//           const SizedBox(height: 16),
//           Text(
//             title,
//             style: const TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.w600,
//               color: ElegantLightTheme.textSecondary,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             message,
//             style: const TextStyle(
//               color: ElegantLightTheme.textTertiary,
//               fontSize: 13,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           if (actionText != null && onAction != null) ...[
//             const SizedBox(height: 20),
//             ElevatedButton.icon(
//               onPressed: onAction,
//               icon: const Icon(Icons.edit, size: 16),
//               label: Text(actionText),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: ElegantLightTheme.primaryBlue,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildErrorState(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.error_outline, size: 100, color: ElegantLightTheme.textTertiary),
//           const SizedBox(height: 20),
//           const Text(
//             'Producto no encontrado',
//             style: TextStyle(
//               fontSize: 18,
//               color: ElegantLightTheme.textSecondary,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 10),
//           const Text(
//             'El producto que buscas no existe o ha sido eliminado',
//             style: TextStyle(color: ElegantLightTheme.textTertiary, fontSize: 14),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 30),
//           ElevatedButton.icon(
//             onPressed: () => Get.back(),
//             icon: const Icon(Icons.arrow_back),
//             label: const Text('Volver a Productos'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: ElegantLightTheme.primaryBlue,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget? _buildFloatingActionButton(BuildContext context) {
//     if (ResponsiveHelper.isMobile(context)) {
//       return Container(
//         decoration: BoxDecoration(
//           gradient: ElegantLightTheme.primaryGradient,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: ElegantLightTheme.elevatedShadow,
//         ),
//         child: FloatingActionButton(
//           onPressed: controller.goToEditProduct,
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           child: const Icon(Icons.edit, color: Colors.white),
//         ),
//       );
//     }
//     return null;
//   }

//   // ============================= HELPER METHODS =============================
//   void _handleMenuAction(String action, BuildContext context) {
//     switch (action) {
//       case 'print_label':
//         controller.printLabel();
//         break;
//       case 'generate_report':
//         controller.generateReport();
//         break;
//       case 'refresh':
//         controller.refreshData();
//         break;
//       case 'delete':
//         controller.confirmDelete();
//         break;
//     }
//   }

//   IconData _getProductIcon(Product product) {
//     if (product.type == ProductType.service) {
//       return Icons.handyman;
//     }
//     return Icons.shopping_bag;
//   }

//   Color _getStockColor(Product product) {
//     if (product.stock <= 0 || product.status == ProductStatus.outOfStock) {
//       return Colors.red.shade600;
//     } else if (product.isLowStock) {
//       return ElegantLightTheme.accentOrange;
//     } else {
//       return Colors.green.shade600;
//     }
//   }

//   LinearGradient _getStockGradient(Product product) {
//     if (product.stock <= 0 || product.status == ProductStatus.outOfStock) {
//       return ElegantLightTheme.errorGradient;
//     } else if (product.isLowStock) {
//       return ElegantLightTheme.warningGradient;
//     } else {
//       return ElegantLightTheme.successGradient;
//     }
//   }

//   IconData _getStockIcon(Product product) {
//     if (product.stock <= 0 || product.status == ProductStatus.outOfStock) {
//       return Icons.remove_circle;
//     } else if (product.isLowStock) {
//       return Icons.warning;
//     } else {
//       return Icons.check_circle;
//     }
//   }

//   String _getStockText(Product product) {
//     if (product.stock <= 0 || product.status == ProductStatus.outOfStock) {
//       return 'SIN STOCK';
//     } else if (product.isLowStock) {
//       return 'STOCK BAJO';
//     } else {
//       return 'EN STOCK';
//     }
//   }

//   String _getPriceTypeDisplayName(dynamic priceType) {
//     try {
//       if (priceType is PriceType) {
//         return priceType.displayName;
//       }
//       if (priceType is String) {
//         return _mapStringToPriceTypeName(priceType);
//       }
//       final typeString = priceType.toString().split('.').last;
//       return _mapStringToPriceTypeName(typeString);
//     } catch (e) {
//       return 'Precio';
//     }
//   }

//   String _mapStringToPriceTypeName(String type) {
//     switch (type.toLowerCase()) {
//       case 'price1':
//         return 'Precio al Público';
//       case 'price2':
//         return 'Precio Mayorista';
//       case 'price3':
//         return 'Precio Distribuidor';
//       case 'special':
//         return 'Precio Especial';
//       case 'cost':
//         return 'Precio de Costo';
//       default:
//         return type.toUpperCase();
//     }
//   }

//   bool _hasDiscount(dynamic productPrice) {
//     try {
//       if (productPrice == null) return false;
//       final discountPercentage = productPrice.discountPercentage;
//       if (discountPercentage != null && discountPercentage > 0) return true;
//       final discountAmount = productPrice.discountAmount;
//       if (discountAmount != null && discountAmount > 0) return true;
//       return false;
//     } catch (e) {
//       return false;
//     }
//   }

//   bool _hasMinQuantity(dynamic productPrice) {
//     try {
//       if (productPrice == null) return false;
//       final minQuantity = productPrice.minQuantity;
//       if (minQuantity != null && minQuantity > 1) return true;
//       return false;
//     } catch (e) {
//       return false;
//     }
//   }
// }

// lib/features/products/presentation/screens/product_detail_screen.dart
import 'package:baudex_desktop/app/config/routes/app_routes.dart';
import 'package:baudex_desktop/app/core/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/product_detail_controller.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_price.dart';

class ProductDetailScreen extends GetView<ProductDetailController> {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElegantLightTheme.backgroundColor,
      appBar: _buildElegantAppBar(context),
      body: Obx(() {
        if (controller.isLoading) {
          return const LoadingWidget(
            message: 'Cargando detalles del producto...',
          );
        }

        if (!controller.hasProduct) {
          return _buildErrorState(context);
        }

        return ResponsiveLayout(
          mobile: _buildMobileLayout(context),
          tablet: _buildTabletLayout(context),
          desktop: _buildDesktopLayout(context),
        );
      }),
      floatingActionButton: _buildMobileFAB(context),
    );
  }

  // ==================== ELEGANT APP BAR ====================

  PreferredSizeWidget _buildElegantAppBar(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
        ),
      ),
      title: Obx(
        () => Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Icon(
                controller.hasProduct
                    ? _getProductIcon(controller.product!)
                    : Icons.shopping_bag,
                size: isMobile ? 18 : 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.hasProduct
                        ? controller.product!.name
                        : 'Detalles del Producto',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 16 : 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (controller.hasProduct)
                    Text(
                      'SKU: ${controller.product!.sku}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, size: 20),
        onPressed: () => Get.offAllNamed(AppRoutes.products),
      ),
      actions: [
        if (controller.hasProduct) ...[
          IconButton(
            icon: const Icon(Icons.share, size: 20),
            onPressed: controller.shareProduct,
            tooltip: 'Compartir producto',
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: controller.goToEditProduct,
            tooltip: 'Editar producto',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20, color: Colors.white),
            onSelected: (value) => _handleMenuAction(value, context),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            itemBuilder:
                (context) => [
                  _buildPopupMenuItem(
                    'stock',
                    Icons.inventory,
                    'Gestionar Stock',
                    ElegantLightTheme.infoGradient,
                  ),
                  _buildPopupMenuItem(
                    'print',
                    Icons.print,
                    'Imprimir Etiqueta',
                    ElegantLightTheme.successGradient,
                  ),
                  _buildPopupMenuItem(
                    'report',
                    Icons.analytics,
                    'Generar Reporte',
                    ElegantLightTheme.primaryGradient,
                  ),
                  _buildPopupMenuItem(
                    'refresh',
                    Icons.refresh,
                    'Actualizar',
                    ElegantLightTheme.infoGradient,
                  ),
                  const PopupMenuDivider(),
                  _buildPopupMenuItem(
                    'delete',
                    Icons.delete,
                    'Eliminar',
                    ElegantLightTheme.errorGradient,
                    isDestructive: true,
                  ),
                ],
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    String value,
    IconData icon,
    String label,
    LinearGradient gradient, {
    bool isDestructive = false,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color:
                  isDestructive
                      ? Colors.red.shade600
                      : ElegantLightTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MOBILE LAYOUT ====================

  Widget _buildMobileLayout(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.refreshData,
      color: ElegantLightTheme.primaryBlue,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildProductProfileCard(context),
            const SizedBox(height: 12),
            _buildQuickMetricsRow(context),
            const SizedBox(height: 12),
            _buildProductInfoCard(context),
            const SizedBox(height: 12),
            _buildStockInfoCard(context),
            const SizedBox(height: 12),
            _buildTaxInfoCard(context),
            const SizedBox(height: 12),
            _buildPricesCard(context),
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }

  // ==================== TABLET LAYOUT ====================

  Widget _buildTabletLayout(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.refreshData,
      color: ElegantLightTheme.primaryBlue,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                _buildCompactHeader(context),
                const SizedBox(height: 12),

                // Fila 1: Info Producto y Stock
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildCompactProductCard(context)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildCompactStockCard(context)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Fila 2: Impuestos y Acciones
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildCompactTaxCard(context)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildCompactActionsCard(context)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Precios (ancho completo)
                _buildCompactPricesCard(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== DESKTOP LAYOUT ====================

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Main Content Area
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.refreshData,
            color: ElegantLightTheme.primaryBlue,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildProductProfileCard(context),
                  const SizedBox(height: 16),
                  _buildQuickMetricsRow(context),
                  const SizedBox(height: 16),

                  // Info Producto y Stock en fila
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildProductInfoCard(context)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStockInfoCard(context)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildTaxInfoCard(context),
                  const SizedBox(height: 16),
                  _buildPricesCard(context),
                ],
              ),
            ),
          ),
        ),

        // Right Sidebar
        Container(
          width: 300,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ElegantLightTheme.cardColor,
                ElegantLightTheme.backgroundColor,
              ],
            ),
            border: Border(
              left: BorderSide(
                color: ElegantLightTheme.textTertiary.withValues(alpha: 0.12),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildSidebarStatusSection(context),
                const SizedBox(height: 16),
                _buildActionsCard(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== SIDEBAR STATUS SECTION ====================

  Widget _buildSidebarStatusSection(BuildContext context) {
    return Obx(() {
      final product = controller.product!;
      final color = _getStockColor(product);

      return FuturisticContainer(
        padding: const EdgeInsets.all(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.04)],
        ),
        child: Column(
          children: [
            // Icono grande con estado
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: _getStockGradient(product),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                _getStockIcon(product),
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Estado label
            Text(
              _getStockText(product),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _getStockDescription(product),
              style: const TextStyle(
                fontSize: 13,
                color: ElegantLightTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // Info rápida del producto
            _buildSidebarInfoRow(
              icon: Icons.inventory_2,
              label: 'Stock actual',
              value:
                  '${AppFormatters.formatStock(product.stock)} ${product.unit ?? "uds"}',
              valueColor: color,
            ),
            const SizedBox(height: 12),
            if (product.defaultPrice != null)
              _buildSidebarInfoRow(
                icon: Icons.sell,
                label: 'Precio',
                value: AppFormatters.formatPrice(
                  product.defaultPrice!.finalAmount,
                ),
                valueColor: Colors.green.shade700,
              ),
            const SizedBox(height: 12),
            _buildSidebarInfoRow(
              icon: Icons.category,
              label: 'Tipo',
              value: product.type.name.toUpperCase(),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSidebarInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: ElegantLightTheme.primaryBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: ElegantLightTheme.textTertiary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== COMPACT COMPONENTS ====================

  Widget _buildCompactHeader(BuildContext context) {
    return Obx(() {
      final product = controller.product!;

      return FuturisticContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildAnimatedAvatar(product, true, size: 56),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ElegantLightTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(product),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'SKU: ${product.sku}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: ElegantLightTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.barcode != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Código: ${product.barcode}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: ElegantLightTheme.textTertiary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Quick metrics compactos
            const SizedBox(width: 16),
            _buildCompactMetric(
              '${AppFormatters.formatStock(product.stock)}',
              'Stock',
              _getStockColor(product),
            ),
            const SizedBox(width: 12),
            if (product.defaultPrice != null)
              _buildCompactMetric(
                AppFormatters.formatCompactCurrency(
                  product.defaultPrice!.finalAmount,
                ),
                'Precio',
                Colors.green.shade700,
              ),
          ],
        ),
      );
    });
  }

  Widget _buildCompactMetric(String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: ElegantLightTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactProductCard(BuildContext context) {
    return Obx(() {
      final product = controller.product!;

      return FuturisticContainer(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCompactCardHeader(
              'Información',
              Icons.info_outline,
              ElegantLightTheme.primaryGradient,
            ),
            const SizedBox(height: 12),
            _buildCompactInfoRow('Tipo', product.type.name.toUpperCase()),
            _buildCompactInfoRow('Categoría', product.category?.name ?? 'N/A'),
            _buildCompactInfoRow('Unidad', product.unit ?? 'pcs'),
            if (product.createdBy != null)
              _buildCompactInfoRow('Creado por', product.createdBy!.fullName),
          ],
        ),
      );
    });
  }

  Widget _buildCompactStockCard(BuildContext context) {
    return Obx(() {
      final product = controller.product!;

      return FuturisticContainer(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCompactCardHeader(
              'Stock',
              Icons.inventory_2,
              ElegantLightTheme.infoGradient,
            ),
            const SizedBox(height: 12),
            _buildCompactInfoRow(
              'Actual',
              '${AppFormatters.formatStock(product.stock)} ${product.unit ?? "uds"}',
            ),
            _buildCompactInfoRow(
              'Mínimo',
              '${AppFormatters.formatStock(product.minStock)} ${product.unit ?? "uds"}',
            ),
            if (product.isLowStock)
              _buildCompactInfoRow('Alerta', 'Stock por debajo del mínimo'),
          ],
        ),
      );
    });
  }

  Widget _buildCompactTaxCard(BuildContext context) {
    return Obx(() {
      final product = controller.product!;

      return FuturisticContainer(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCompactCardHeader(
              'Impuestos',
              Icons.receipt_long,
              ElegantLightTheme.successGradient,
            ),
            const SizedBox(height: 12),
            _buildCompactInfoRow('Categoría', product.taxCategory.displayName),
            _buildCompactInfoRow(
              'Tasa',
              '${AppFormatters.formatNumber(product.taxRate)}%',
            ),
            _buildCompactInfoRow('Gravado', product.isTaxable ? 'Sí' : 'No'),
          ],
        ),
      );
    });
  }

  Widget _buildCompactActionsCard(BuildContext context) {
    return FuturisticContainer(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompactCardHeader(
            'Acciones',
            Icons.flash_on,
            ElegantLightTheme.warningGradient,
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildCompactActionButton(
                  icon: Icons.edit,
                  label: 'Editar',
                  color: ElegantLightTheme.primaryBlue,
                  onTap: controller.goToEditProduct,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactActionButton(
                  icon: Icons.inventory,
                  label: 'Stock',
                  color: const Color(0xFF3B82F6),
                  onTap: controller.showStockDialog,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCompactActionButton(
                  icon: Icons.print,
                  label: 'Etiqueta',
                  color: const Color(0xFF10B981),
                  onTap: controller.printLabel,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Obx(
                  () => _buildCompactActionButton(
                    icon: Icons.delete_outline,
                    label: 'Eliminar',
                    color: const Color(0xFFEF4444),
                    onTap:
                        controller.isDeleting ? null : controller.confirmDelete,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPricesCard(BuildContext context) {
    return Obx(() {
      final product = controller.product!;
      if (product.prices == null || product.prices!.isEmpty) {
        return FuturisticContainer(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              _buildCompactCardHeader(
                'Precios',
                Icons.sell,
                ElegantLightTheme.successGradient,
              ),
              const SizedBox(height: 12),
              const Text(
                'Sin precios configurados',
                style: TextStyle(
                  fontSize: 12,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      }

      return FuturisticContainer(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCompactCardHeader(
              'Precios',
              Icons.sell,
              ElegantLightTheme.successGradient,
            ),
            const SizedBox(height: 12),
            ...product.prices!.map(
              (price) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildCompactPriceRow(price),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCompactPriceRow(dynamic price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _getPriceTypeDisplayName(price.type),
          style: const TextStyle(
            fontSize: 11,
            color: ElegantLightTheme.textSecondary,
          ),
        ),
        Text(
          AppFormatters.formatCompactCurrency(price.finalAmount),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
      ],
    );
  }

  // ==================== COMPACT HELPER WIDGETS ====================

  Widget _buildCompactCardHeader(
    String title,
    IconData icon,
    LinearGradient gradient,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: ElegantLightTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: ElegantLightTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ElegantLightTheme.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== PROFILE CARDS ====================

  Widget _buildProductProfileCard(BuildContext context) {
    return Obx(() {
      final product = controller.product!;
      final isMobile = context.isMobile;

      return FuturisticContainer(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          children: [
            Row(
              children: [
                _buildAnimatedAvatar(product, isMobile),
                SizedBox(width: isMobile ? 14 : 18),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: ElegantLightTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.qr_code,
                            size: 14,
                            color: ElegantLightTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'SKU: ${product.sku}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: ElegantLightTheme.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildStatusBadge(product),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAnimatedAvatar(Product product, bool isMobile, {double? size}) {
    final avatarSize = size ?? (isMobile ? 70 : 80);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              gradient: _getStockGradient(product),
              borderRadius: BorderRadius.circular(avatarSize / 2),
              boxShadow: [
                BoxShadow(
                  color: _getStockColor(product).withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              _getProductIcon(product),
              size: avatarSize * 0.5,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(Product product) {
    final isActive = product.isActive;
    final color = isActive ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final gradient =
        isActive
            ? ElegantLightTheme.successGradient
            : ElegantLightTheme.warningGradient;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: gradient.scale(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isActive ? 'ACTIVO' : 'INACTIVO',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMetricsRow(BuildContext context) {
    return Obx(() {
      final product = controller.product!;
      final isMobile = context.isMobile;

      return Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              'Stock',
              '${AppFormatters.formatStock(product.stock)}',
              Icons.inventory_2,
              _getStockColor(product),
              isMobile,
            ),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          if (product.defaultPrice != null)
            Expanded(
              child: _buildMetricCard(
                'Precio',
                AppFormatters.formatCompactCurrency(
                  product.defaultPrice!.finalAmount,
                ),
                Icons.sell,
                Colors.green.shade700,
                isMobile,
              ),
            ),
          SizedBox(width: isMobile ? 8 : 12),
          Expanded(
            child: _buildMetricCard(
              'Tipo',
              product.type.name.toUpperCase(),
              Icons.category,
              const Color(0xFF8B5CF6),
              isMobile,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isMobile,
  ) {
    return FuturisticContainer(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withValues(alpha: 0.08), color.withValues(alpha: 0.03)],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: isMobile ? 18 : 22),
          ),
          SizedBox(height: isMobile ? 8 : 10),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, animValue, child) {
              return Opacity(
                opacity: animValue,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 10 : 11,
              color: ElegantLightTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== INFO CARDS ====================

  Widget _buildProductInfoCard(BuildContext context) {
    return Obx(() {
      final product = controller.product!;

      return _buildInfoSection(
        title: 'Información del Producto',
        icon: Icons.info_outline,
        gradient: ElegantLightTheme.primaryGradient,
        children: [
          _buildInfoRow(
            'Tipo',
            product.type.name.toUpperCase(),
            Icons.category_outlined,
          ),
          _buildInfoRow(
            'Categoría',
            product.category?.name ?? 'N/A',
            Icons.folder_outlined,
          ),
          _buildInfoRow('Unidad', product.unit ?? 'pcs', Icons.straighten),
          if (product.createdBy != null)
            _buildInfoRow(
              'Creado por',
              product.createdBy!.fullName,
              Icons.person_outline,
            ),
          if (product.description != null)
            _buildInfoRow(
              'Descripción',
              product.description!,
              Icons.description_outlined,
            ),
        ],
      );
    });
  }

  Widget _buildStockInfoCard(BuildContext context) {
    return Obx(() {
      final product = controller.product!;

      return _buildInfoSection(
        title: 'Gestión de Stock',
        icon: Icons.inventory_2_outlined,
        gradient: ElegantLightTheme.infoGradient,
        children: [
          _buildInfoRow(
            'Stock Actual',
            '${AppFormatters.formatStock(product.stock)} ${product.unit ?? "pcs"}',
            Icons.inventory,
            valueColor: _getStockColor(product),
          ),
          _buildInfoRow(
            'Stock Mínimo',
            '${AppFormatters.formatStock(product.minStock)} ${product.unit ?? "pcs"}',
            Icons.warning_amber,
          ),
          if (product.isLowStock)
            _buildInfoRow(
              'Alerta',
              'Stock por debajo del mínimo',
              Icons.error,
              valueColor: Colors.orange,
            ),
        ],
      );
    });
  }

  Widget _buildTaxInfoCard(BuildContext context) {
    return Obx(() {
      final product = controller.product!;

      return FuturisticContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.successGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Facturación Electrónica',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRowSimple(
              'Categoría de Impuesto',
              product.taxCategory.displayName,
              Icons.receipt_long,
            ),
            _buildInfoRowSimple(
              'Tasa de Impuesto',
              '${AppFormatters.formatNumber(product.taxRate)}%',
              Icons.percent,
            ),
            _buildInfoRowSimple(
              'Está Gravado',
              product.isTaxable ? 'Sí' : 'No',
              Icons.check_circle,
              valueColor: product.isTaxable ? Colors.green : Colors.grey,
            ),
            if (product.hasRetention) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              if (product.retentionCategory != null)
                _buildInfoRowSimple(
                  'Retención',
                  product.retentionCategory!.displayName,
                  Icons.money_off,
                ),
              if (product.retentionRate != null)
                _buildInfoRowSimple(
                  'Tasa Retención',
                  '${AppFormatters.formatNumber(product.retentionRate!)}%',
                  Icons.trending_down,
                ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildPricesCard(BuildContext context) {
    return Obx(() {
      final product = controller.product!;

      if (product.prices == null || product.prices!.isEmpty) {
        return FuturisticContainer(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                Icons.price_change_outlined,
                size: 60,
                color: ElegantLightTheme.textTertiary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Sin precios configurados',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Este producto no tiene precios configurados',
                style: TextStyle(
                  color: ElegantLightTheme.textTertiary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return FuturisticContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.successGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.sell, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Precios',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...product.prices!.map((price) => _buildPriceRow(price)),
          ],
        ),
      );
    });
  }

  Widget _buildPriceRow(dynamic price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade50, Colors.white],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade700, Colors.green.shade600],
              ),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.3),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getPriceTypeDisplayName(price.type),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
                if (_hasDiscount(price)) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        AppFormatters.formatPrice(price.amount),
                        style: const TextStyle(
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                          color: ElegantLightTheme.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-${AppFormatters.formatNumber(price.discountPercentage)}%',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: price.finalAmount),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, animValue, child) {
              return Text(
                AppFormatters.formatPrice(animValue),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required LinearGradient gradient,
    required List<Widget> children,
  }) {
    return FuturisticContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.colors.first.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ElegantLightTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? ElegantLightTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowSimple(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: ElegantLightTheme.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: ElegantLightTheme.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? ElegantLightTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SIDEBAR COMPONENTS ====================

  Widget _buildActionsCard(BuildContext context) {
    return FuturisticContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: const Icon(
                  Icons.flash_on,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Acciones Rápidas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildElegantActionButton(
            icon: Icons.edit,
            label: 'Editar Producto',
            description: 'Modificar información',
            gradient: ElegantLightTheme.primaryGradient,
            onTap: controller.goToEditProduct,
          ),
          const SizedBox(height: 10),

          _buildElegantActionButton(
            icon: Icons.inventory,
            label: 'Gestionar Stock',
            description: 'Ajustar inventario',
            gradient: ElegantLightTheme.infoGradient,
            onTap: controller.showStockDialog,
          ),
          const SizedBox(height: 10),

          _buildElegantActionButton(
            icon: Icons.print,
            label: 'Imprimir Etiqueta',
            description: 'Generar código de barras',
            gradient: ElegantLightTheme.successGradient,
            onTap: controller.printLabel,
          ),

          const SizedBox(height: 16),

          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Obx(
            () => _buildElegantActionButton(
              icon: Icons.delete_outline,
              label:
                  controller.isDeleting ? 'Eliminando...' : 'Eliminar Producto',
              description: 'Eliminar permanentemente',
              gradient: ElegantLightTheme.errorGradient,
              onTap: controller.isDeleting ? null : controller.confirmDelete,
              isLoading: controller.isDeleting,
              isDanger: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElegantActionButton({
    required IconData icon,
    required String label,
    required String description,
    required LinearGradient gradient,
    required VoidCallback? onTap,
    bool isLoading = false,
    bool isDanger = false,
  }) {
    final isEnabled = onTap != null && !isLoading;
    final primaryColor = gradient.colors.first;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor.withValues(alpha: isEnabled ? 0.08 : 0.04),
                primaryColor.withValues(alpha: isEnabled ? 0.03 : 0.01),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: primaryColor.withValues(alpha: isEnabled ? 0.25 : 0.1),
              width: 1,
            ),
            boxShadow:
                isEnabled
                    ? [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: isEnabled ? gradient : null,
                  color: isEnabled ? null : primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow:
                      isEnabled
                          ? [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                          : null,
                ),
                child:
                    isLoading
                        ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isEnabled
                                  ? Colors.white
                                  : primaryColor.withValues(alpha: 0.5),
                            ),
                          ),
                        )
                        : Icon(
                          icon,
                          size: 18,
                          color:
                              isEnabled
                                  ? Colors.white
                                  : primaryColor.withValues(alpha: 0.5),
                        ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            isEnabled
                                ? (isDanger
                                    ? primaryColor
                                    : ElegantLightTheme.textPrimary)
                                : ElegantLightTheme.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            isEnabled
                                ? ElegantLightTheme.textSecondary
                                : ElegantLightTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: isEnabled ? 0.1 : 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color:
                      isEnabled
                          ? primaryColor
                          : primaryColor.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== MOBILE FAB ====================

  Widget? _buildMobileFAB(BuildContext context) {
    if (!context.isMobile) return null;

    return FloatingActionButton(
      onPressed: controller.goToEditProduct,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: ElegantLightTheme.glowShadow,
        ),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  // ==================== ERROR STATE ====================

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: FuturisticContainer(
        width: 400,
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.errorGradient.scale(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Producto no encontrado',
              style: TextStyle(
                fontSize: 20,
                color: ElegantLightTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'El producto que buscas no existe o ha sido eliminado',
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElegantButton(
              text: 'Volver a Productos',
              icon: Icons.arrow_back,
              onPressed: () => Get.offAllNamed(AppRoutes.products),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPER METHODS ====================

  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'stock':
        controller.showStockDialog();
        break;
      case 'print':
        controller.printLabel();
        break;
      case 'report':
        controller.generateReport();
        break;
      case 'refresh':
        controller.refreshData();
        break;
      case 'delete':
        controller.confirmDelete();
        break;
    }
  }

  IconData _getProductIcon(Product product) {
    if (product.type == ProductType.service) {
      return Icons.handyman;
    }
    return Icons.shopping_bag;
  }

  Color _getStockColor(Product product) {
    if (product.stock <= 0 || product.status == ProductStatus.outOfStock) {
      return Colors.red.shade600;
    } else if (product.isLowStock) {
      return ElegantLightTheme.accentOrange;
    } else {
      return Colors.green.shade600;
    }
  }

  LinearGradient _getStockGradient(Product product) {
    if (product.stock <= 0 || product.status == ProductStatus.outOfStock) {
      return ElegantLightTheme.errorGradient;
    } else if (product.isLowStock) {
      return ElegantLightTheme.warningGradient;
    } else {
      return ElegantLightTheme.successGradient;
    }
  }

  IconData _getStockIcon(Product product) {
    if (product.stock <= 0 || product.status == ProductStatus.outOfStock) {
      return Icons.remove_circle;
    } else if (product.isLowStock) {
      return Icons.warning;
    } else {
      return Icons.check_circle;
    }
  }

  String _getStockText(Product product) {
    if (product.stock <= 0 || product.status == ProductStatus.outOfStock) {
      return 'SIN STOCK';
    } else if (product.isLowStock) {
      return 'STOCK BAJO';
    } else {
      return 'EN STOCK';
    }
  }

  String _getStockDescription(Product product) {
    if (product.stock <= 0 || product.status == ProductStatus.outOfStock) {
      return 'Producto agotado - Requiere reabastecimiento';
    } else if (product.isLowStock) {
      return 'Stock por debajo del mínimo establecido';
    } else {
      return 'Stock disponible para venta';
    }
  }

  String _getPriceTypeDisplayName(dynamic priceType) {
    try {
      if (priceType is PriceType) {
        return priceType.displayName;
      }
      if (priceType is String) {
        return _mapStringToPriceTypeName(priceType);
      }
      final typeString = priceType.toString().split('.').last;
      return _mapStringToPriceTypeName(typeString);
    } catch (e) {
      return 'Precio';
    }
  }

  String _mapStringToPriceTypeName(String type) {
    switch (type.toLowerCase()) {
      case 'price1':
        return 'Precio al Público';
      case 'price2':
        return 'Precio Mayorista';
      case 'price3':
        return 'Precio Distribuidor';
      case 'special':
        return 'Precio Especial';
      case 'cost':
        return 'Precio de Costo';
      default:
        return type.toUpperCase();
    }
  }

  bool _hasDiscount(dynamic productPrice) {
    try {
      if (productPrice == null) return false;
      final discountPercentage = productPrice.discountPercentage;
      if (discountPercentage != null && discountPercentage > 0) return true;
      final discountAmount = productPrice.discountAmount;
      if (discountAmount != null && discountAmount > 0) return true;
      return false;
    } catch (e) {
      return false;
    }
  }
}

// Extension ya existe en responsive.dart, no es necesario redefinirla
