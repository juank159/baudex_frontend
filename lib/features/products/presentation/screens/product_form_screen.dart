// // lib/features/products/presentation/screens/product_form_screen.dart
// import 'package:baudex_desktop/features/products/presentation/widgets/category_selector_widget.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../../app/core/utils/responsive.dart';
// import '../../../../app/shared/widgets/custom_button.dart';
// import '../../../../app/shared/widgets/custom_card.dart';
// import '../../../../app/shared/widgets/custom_text_field.dart';
// import '../../../../app/shared/widgets/loading_widget.dart';
// import '../controllers/product_form_controller.dart';
// import '../../domain/entities/product.dart';
// import '../../domain/entities/product_price.dart';

// // Importa la pantalla del escáner de código de barras
// import 'package:baudex_desktop/app/shared/screens/barcode_scanner_screen.dart';

// class ProductFormScreen extends GetView<ProductFormController> {
//   const ProductFormScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     print('🖼️ ProductFormScreen: Construyendo pantalla...');
//     // ✅ AÑADE ESTA LÍNEA PARA DEPURACIÓN
//     print('DEBUG: context.isMobile es: ${context.isMobile}');

//     return Scaffold(
//       appBar: _buildAppBar(context),
//       body: GetBuilder<ProductFormController>(
//         builder: (controller) {
//           print(
//             '🔄 ProductFormScreen: Reconstruyendo body - isLoading: ${controller.isLoading}',
//           );

//           if (controller.isLoading) {
//             return LoadingWidget(
//               message:
//                   controller.isEditMode
//                       ? 'Cargando producto...'
//                       : 'Preparando formulario...',
//             );
//           }

//           return ResponsiveLayout(
//             mobile: _buildMobileLayout(context),
//             tablet: _buildTabletLayout(context),
//             desktop: _buildDesktopLayout(context),
//           );
//         },
//       ),
//       bottomNavigationBar: _buildBottomActions(context),
//     );
//   }

//   PreferredSizeWidget _buildAppBar(BuildContext context) {
//     return AppBar(
//       // ✅ SOLUCIÓN: GetBuilder en lugar de Obx para el título
//       title: GetBuilder<ProductFormController>(
//         builder: (controller) => Text(controller.pageTitle),
//       ),
//       elevation: 0,
//       actions: [
//         // Previsualizar
//         IconButton(
//           icon: const Icon(Icons.preview),
//           onPressed: () {
//             try {
//               controller.previewProduct();
//             } catch (e) {
//               print('❌ Error en previsualizar: $e');
//             }
//           },
//           tooltip: 'Previsualizar',
//         ),

//         // Limpiar formulario - Solo mostrar si NO es modo edición
//         GetBuilder<ProductFormController>(
//           builder: (controller) {
//             if (!controller.isEditMode) {
//               return IconButton(
//                 icon: const Icon(Icons.clear_all),
//                 onPressed: () => _showClearConfirmation(context),
//                 tooltip: 'Limpiar formulario',
//               );
//             }
//             return const SizedBox.shrink();
//           },
//         ),

//         // Menú de opciones
//         PopupMenuButton<String>(
//           onSelected: (value) => _handleMenuAction(value, context),
//           itemBuilder:
//               (context) => [
//                 const PopupMenuItem(
//                   value: 'clear',
//                   child: Row(
//                     children: [
//                       Icon(Icons.clear_all),
//                       SizedBox(width: 8),
//                       Text('Limpiar Formulario'),
//                     ],
//                   ),
//                 ),
//                 const PopupMenuItem(
//                   value: 'preview',
//                   child: Row(
//                     children: [
//                       Icon(Icons.preview),
//                       SizedBox(width: 8),
//                       Text('Previsualizar'),
//                     ],
//                   ),
//                 ),
//                 const PopupMenuItem(
//                   value: 'calculator',
//                   child: Row(
//                     children: [
//                       Icon(Icons.calculate),
//                       SizedBox(width: 8),
//                       Text('Calculadora'),
//                     ],
//                   ),
//                 ),
//               ],
//         ),
//       ],
//     );
//   }

//   Widget _buildMobileLayout(BuildContext context) {
//     return Form(
//       key: controller.formKey,
//       child: SingleChildScrollView(
//         padding: context.responsivePadding,
//         child: Column(
//           children: [
//             // Información básica
//             _buildBasicInfoSection(context),
//             SizedBox(height: context.verticalSpacing),

//             // Stock y medidas
//             _buildStockSection(context),
//             SizedBox(height: context.verticalSpacing),

//             // Precios
//             _buildPricesSection(context),
//             SizedBox(
//               height: context.verticalSpacing * 3,
//             ), // Espacio para el bottom bar
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTabletLayout(BuildContext context) {
//     return Form(
//       key: controller.formKey,
//       child: SingleChildScrollView(
//         child: AdaptiveContainer(
//           maxWidth: 900,
//           child: Column(
//             children: [
//               SizedBox(height: context.verticalSpacing),

//               // Información básica
//               CustomCard(child: _buildBasicInfoContent(context)),
//               SizedBox(height: context.verticalSpacing),

//               // Stock y medidas en dos columnas
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Expanded(
//                     child: CustomCard(child: _buildStockContent(context)),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: CustomCard(child: _buildDimensionsContent(context)),
//                   ),
//                 ],
//               ),
//               SizedBox(height: context.verticalSpacing),

//               // Precios
//               CustomCard(child: _buildPricesContent(context)),
//               SizedBox(height: context.verticalSpacing),

//               // Acciones
//               _buildActions(context),
//               SizedBox(height: context.verticalSpacing),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDesktopLayout(BuildContext context) {
//     return Row(
//       children: [
//         // Contenido principal
//         Expanded(
//           flex: 2,
//           child: Form(
//             key: controller.formKey,
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(32.0),
//               child: Column(
//                 children: [
//                   // Información básica
//                   CustomCard(child: _buildBasicInfoContent(context)),
//                   const SizedBox(height: 24),

//                   // Stock y dimensiones
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Expanded(
//                         child: CustomCard(child: _buildStockContent(context)),
//                       ),
//                       const SizedBox(width: 24),
//                       Expanded(
//                         child: CustomCard(
//                           child: _buildDimensionsContent(context),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 24),

//                   // Precios
//                   CustomCard(child: _buildPricesContent(context)),
//                 ],
//               ),
//             ),
//           ),
//         ),

//         // Panel lateral
//         Container(
//           width: 350,
//           decoration: BoxDecoration(
//             color: Colors.grey.shade50,
//             border: Border(left: BorderSide(color: Colors.grey.shade300)),
//           ),
//           child: Column(
//             children: [
//               // Header del panel
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Theme.of(context).primaryColor.withOpacity(0.1),
//                   border: Border(
//                     bottom: BorderSide(color: Colors.grey.shade300),
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(Icons.settings, color: Theme.of(context).primaryColor),
//                     const SizedBox(width: 8),
//                     Text(
//                       'Configuración',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Theme.of(context).primaryColor,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               // Contenido del panel
//               Expanded(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: _buildSidebarContent(context),
//                 ),
//               ),

//               // Acciones en el panel
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: _buildSidebarActions(context),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   // ==================== SECTIONS ====================

//   Widget _buildBasicInfoSection(BuildContext context) {
//     return CustomCard(child: _buildBasicInfoContent(context));
//   }

//   Widget _buildBasicInfoContent(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Información Básica',
//           style: TextStyle(
//             fontSize: Responsive.getFontSize(context, mobile: 18, tablet: 20),
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 16),

//         // Nombre del producto
//         CustomTextField(
//           controller: controller.nameController,
//           label: 'Nombre del Producto *',
//           hint: 'Ingresa el nombre del producto',
//           prefixIcon: Icons.inventory_2,
//           validator: (value) {
//             if (value?.trim().isEmpty ?? true) {
//               return 'El nombre es requerido';
//             }
//             return null;
//           },
//         ),
//         const SizedBox(height: 16),

//         // Descripción
//         CustomTextField(
//           controller: controller.descriptionController,
//           label: 'Descripción',
//           hint: 'Descripción detallada del producto',
//           prefixIcon: Icons.description,
//           maxLines: 3,
//         ),
//         const SizedBox(height: 16),

//         // SKU y Código de barras
//         Row(
//           children: [
//             Expanded(
//               flex: 2,
//               child: CustomTextField(
//                 controller: controller.skuController,
//                 label: 'SKU *',
//                 hint: 'Código único del producto',
//                 prefixIcon: Icons.qr_code,
//                 validator: (value) {
//                   if (value?.trim().isEmpty ?? true) {
//                     return 'El SKU es requerido';
//                   }
//                   return null;
//                 },
//               ),
//             ),
//             const SizedBox(width: 12),
//             CustomButton(
//               text: 'Generar',
//               type: ButtonType.outline,
//               onPressed: () {
//                 try {
//                   controller.generateSku();
//                 } catch (e) {
//                   print('❌ Error al generar SKU: $e');
//                 }
//               },
//               width: 100,
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),

//         // CÓDIGO DE BARRAS CON BOTÓN DE ESCANEO CONDICIONAL
//         CustomTextField(
//           controller: controller.barcodeController,
//           label: 'Código de Barras',
//           hint: 'Código de barras del producto',
//           prefixIcon: Icons.barcode_reader,
//           keyboardType: TextInputType.number,
//           validator: (value) {
//             if (value != null && value.isNotEmpty) {
//               return controller.validateBarcode(value)
//                   ? null
//                   : 'Código de barras inválido';
//             }
//             return null;
//           },
//           // ✅ AGREGADO: Icono de sufijo y acción para el escáner
//           suffixIcon: context.isMobile ? Icons.camera_alt : null,
//           onSuffixIconPressed:
//               context.isMobile
//                   ? () async {
//                     // Navega a la pantalla del escáner y espera el resultado
//                     final scannedCode = await Get.to<String>(
//                       () => const BarcodeScannerScreen(),
//                     );
//                     if (scannedCode != null) {
//                       controller.barcodeController.text = scannedCode;
//                     }
//                   }
//                   : null, // No hay acción si no es móvil
//         ),
//         const SizedBox(height: 16),

//         // Tipo y Estado
//         Row(
//           children: [
//             Expanded(flex: 1, child: _buildTypeSelector(context)),
//             const SizedBox(width: 12), // Reducido de 16 a 12
//             Expanded(flex: 1, child: _buildStatusSelector(context)),
//           ],
//         ),
//         const SizedBox(height: 16),

//         // Categoría
//         _buildCategorySelector(context),
//       ],
//     );
//   }

//   Widget _buildStockSection(BuildContext context) {
//     return CustomCard(child: _buildStockContent(context));
//   }

//   Widget _buildStockContent(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Gestión de Stock',
//           style: TextStyle(
//             fontSize: Responsive.getFontSize(context, mobile: 18, tablet: 20),
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 16),

//         // Stock actual y mínimo
//         Row(
//           children: [
//             Expanded(
//               child: CustomTextField(
//                 controller: controller.stockController,
//                 label: 'Stock Actual *',
//                 hint: '0',
//                 prefixIcon: Icons.inventory,
//                 keyboardType: TextInputType.number,
//                 validator: (value) {
//                   final stock = double.tryParse(value ?? '');
//                   if (stock == null || stock < 0) {
//                     return 'Stock inválido';
//                   }
//                   return null;
//                 },
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: CustomTextField(
//                 controller: controller.minStockController,
//                 label: 'Stock Mínimo *',
//                 hint: '0',
//                 prefixIcon: Icons.warning,
//                 keyboardType: TextInputType.number,
//                 validator: (value) {
//                   final minStock = double.tryParse(value ?? '');
//                   if (minStock == null || minStock < 0) {
//                     return 'Stock mínimo inválido';
//                   }
//                   return null;
//                 },
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),

//         // Unidad de medida
//         CustomTextField(
//           controller: controller.unitController,
//           label: 'Unidad de Medida',
//           hint: 'pcs, kg, m, etc.',
//           prefixIcon: Icons.straighten,
//         ),
//       ],
//     );
//   }

//   Widget _buildDimensionsContent(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Dimensiones y Peso',
//           style: TextStyle(
//             fontSize: Responsive.getFontSize(context, mobile: 18, tablet: 20),
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 16),

//         // Peso
//         CustomTextField(
//           controller: controller.weightController,
//           label: 'Peso (kg)',
//           hint: '0.00',
//           prefixIcon: Icons.fitness_center,
//           keyboardType: TextInputType.number,
//         ),
//         const SizedBox(height: 16),

//         // Dimensiones
//         Row(
//           children: [
//             Expanded(
//               child: CustomTextField(
//                 controller: controller.lengthController,
//                 label: 'Largo (cm)',
//                 hint: '0.00',
//                 keyboardType: TextInputType.number,
//               ),
//             ),
//             const SizedBox(width: 8),
//             Expanded(
//               child: CustomTextField(
//                 controller: controller.widthController,
//                 label: 'Ancho (cm)',
//                 hint: '0.00',
//                 keyboardType: TextInputType.number,
//               ),
//             ),
//             const SizedBox(width: 8),
//             Expanded(
//               child: CustomTextField(
//                 controller: controller.heightController,
//                 label: 'Alto (cm)',
//                 hint: '0.00',
//                 keyboardType: TextInputType.number,
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildPricesSection(BuildContext context) {
//     return CustomCard(child: _buildPricesContent(context));
//   }

//   Widget _buildPricesContent(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Text(
//               'Configuración de Precios',
//               style: TextStyle(
//                 fontSize: Responsive.getFontSize(
//                   context,
//                   mobile: 18,
//                   tablet: 20,
//                 ),
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const Spacer(),
//             CustomButton(
//               text: 'Calculadora de Precios',
//               icon: Icons.calculate,
//               type: ButtonType.outline,
//               onPressed: () {
//                 try {
//                   controller.showPriceCalculator();
//                 } catch (e) {
//                   print('❌ Error en calculadora: $e');
//                 }
//               },
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),

//         // Precio de costo
//         CustomTextField(
//           controller: controller.costPriceController,
//           label: 'Precio de Costo',
//           hint: '0.00',
//           prefixIcon: Icons.attach_money,
//           keyboardType: TextInputType.number,
//         ),
//         const SizedBox(height: 16),

//         // Precios de venta
//         Row(
//           children: [
//             Expanded(
//               child: CustomTextField(
//                 controller: controller.price1Controller,
//                 label: 'Precio al Público',
//                 hint: '0.00',
//                 prefixIcon: Icons.sell,
//                 keyboardType: TextInputType.number,
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: CustomTextField(
//                 controller: controller.price2Controller,
//                 label: 'Precio Mayorista',
//                 hint: '0.00',
//                 prefixIcon: Icons.sell,
//                 keyboardType: TextInputType.number,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),

//         Row(
//           children: [
//             Expanded(
//               child: CustomTextField(
//                 controller: controller.price3Controller,
//                 label: 'Precio Distribuidor',
//                 hint: '0.00',
//                 prefixIcon: Icons.sell,
//                 keyboardType: TextInputType.number,
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: CustomTextField(
//                 controller: controller.specialPriceController,
//                 label: 'Precio Especial',
//                 hint: '0.00',
//                 prefixIcon: Icons.local_offer,
//                 keyboardType: TextInputType.number,
//               ),
//             ),
//           ],
//         ),

//         // Información de márgenes
//         _buildMarginInfo(context),
//       ],
//     );
//   }

//   Widget _buildMarginInfo(BuildContext context) {
//     // ✅ SOLUCIÓN: Calcular aquí directamente sin observables reactivos
//     final costText = controller.costPriceController.text;
//     final sellText = controller.price1Controller.text;

//     if (costText.isEmpty || sellText.isEmpty) {
//       return const SizedBox.shrink();
//     }

//     final costPrice = double.tryParse(costText) ?? 0;
//     final sellPrice = double.tryParse(sellText) ?? 0;
//     final margin = controller.calculateMargin(costPrice, sellPrice);

//     return Container(
//       margin: const EdgeInsets.only(top: 16),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.blue.shade50,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.blue.shade200),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.trending_up, color: Colors.blue.shade600),
//           const SizedBox(width: 8),
//           Text(
//             'Margen de ganancia: ${margin.toStringAsFixed(1)}%',
//             style: TextStyle(
//               color: Colors.blue.shade800,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ==================== SELECTORS ====================

//   Widget _buildTypeSelector(BuildContext context) {
//     return GetBuilder<ProductFormController>(
//       builder:
//           (controller) => DropdownButtonFormField<ProductType>(
//             value: controller.productType,
//             decoration: const InputDecoration(
//               labelText: 'Tipo *',
//               prefixIcon: Icon(Icons.category),
//               border: OutlineInputBorder(),
//               contentPadding: EdgeInsets.symmetric(
//                 horizontal: 8,
//                 vertical: 12,
//               ), // ← AGREGADO
//               isDense: true, // ← AGREGADO
//             ),
//             isExpanded: true, // ← AGREGADO - Esto es CLAVE para evitar overflow
//             items:
//                 ProductType.values.map((type) {
//                   return DropdownMenuItem(
//                     value: type,
//                     child: Text(
//                       _getTypeDisplayName(type),
//                       overflow: TextOverflow.ellipsis, // ← AGREGADO
//                     ),
//                   );
//                 }).toList(),
//             onChanged: (value) {
//               if (value != null) {
//                 try {
//                   controller.setProductType(value);
//                 } catch (e) {
//                   print('❌ Error al cambiar tipo: $e');
//                 }
//               }
//             },
//             validator: (value) => value == null ? 'Selecciona un tipo' : null,
//           ),
//     );
//   }

//   Widget _buildStatusSelector(BuildContext context) {
//     return GetBuilder<ProductFormController>(
//       builder:
//           (controller) => DropdownButtonFormField<ProductStatus>(
//             value: controller.productStatus,
//             decoration: const InputDecoration(
//               labelText: 'Estado *',
//               prefixIcon: Icon(Icons.toggle_on),
//               border: OutlineInputBorder(),
//               contentPadding: EdgeInsets.symmetric(
//                 horizontal: 8,
//                 vertical: 12,
//               ), // ← AGREGADO
//               isDense: true, // ← AGREGADO
//             ),
//             isExpanded: true, // ← AGREGADO - Esto es CLAVE para evitar overflow
//             items:
//                 ProductStatus.values.map((status) {
//                   return DropdownMenuItem(
//                     value: status,
//                     child: Text(
//                       _getStatusDisplayName(status),
//                       overflow: TextOverflow.ellipsis, // ← AGREGADO
//                     ),
//                   );
//                 }).toList(),
//             onChanged: (value) {
//               if (value != null) {
//                 try {
//                   controller.setProductStatus(value);
//                 } catch (e) {
//                   print('❌ Error al cambiar estado: $e');
//                 }
//               }
//             },
//           ),
//     );
//   }

//   Widget _buildCategorySelector(BuildContext context) {
//     print('🔧 ProductFormScreen: Construyendo selector de categorías');

//     // ✅ SOLUCIÓN: Usar el CategorySelectorWidget arreglado
//     return GetBuilder<ProductFormController>(
//       builder: (controller) {
//         print('   selectedCategoryId: ${controller.selectedCategoryId}');
//         print('   selectedCategoryName: ${controller.selectedCategoryName}');
//         //print('   isCategoryServiceAvailable: ${controller.isCategoryServiceAvailable}');

//         return CategorySelectorWidget(
//           selectedCategoryId: controller.selectedCategoryId,
//           selectedCategoryName: controller.selectedCategoryName,
//           onCategorySelected: (categoryId, categoryName) {
//             print('🎯 Categoría seleccionada: $categoryName ($categoryId)');
//             controller.setCategorySelection(categoryId, categoryName);
//           },
//           label: 'Categoría',
//           hint: 'Seleccionar categoría',
//           isRequired: true,
//         );
//       },
//     );
//   }

//   // ==================== SIDEBAR ====================

//   Widget _buildSidebarContent(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Herramientas',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: Colors.grey.shade800,
//           ),
//         ),
//         const SizedBox(height: 16),

//         CustomButton(
//           text: 'Generar SKU',
//           icon: Icons.auto_fix_high,
//           type: ButtonType.outline,
//           onPressed: () {
//             try {
//               controller.generateSku();
//             } catch (e) {
//               print('❌ Error al generar SKU: $e');
//             }
//           },
//           width: double.infinity,
//         ),
//         const SizedBox(height: 12),

//         CustomButton(
//           text: 'Calculadora de Precios',
//           icon: Icons.calculate,
//           type: ButtonType.outline,
//           onPressed: () {
//             try {
//               controller.showPriceCalculator();
//             } catch (e) {
//               print('❌ Error en calculadora: $e');
//             }
//           },
//           width: double.infinity,
//         ),
//         const SizedBox(height: 12),

//         CustomButton(
//           text: 'Previsualizar',
//           icon: Icons.preview,
//           type: ButtonType.outline,
//           onPressed: () {
//             try {
//               controller.previewProduct();
//             } catch (e) {
//               print('❌ Error en previsualizar: $e');
//             }
//           },
//           width: double.infinity,
//         ),

//         const SizedBox(height: 24),
//         const Divider(),
//         const SizedBox(height: 16),

//         Text(
//           'Información',
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             color: Colors.grey.shade700,
//           ),
//         ),
//         const SizedBox(height: 12),

//         Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: Colors.grey.shade100,
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Campos requeridos:',
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.grey.shade700,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               const Text(
//                 '• Nombre del producto',
//                 style: TextStyle(fontSize: 12),
//               ),
//               const Text('• SKU único', style: TextStyle(fontSize: 12)),
//               const Text('• Tipo de producto', style: TextStyle(fontSize: 12)),
//               const Text('• Categoría', style: TextStyle(fontSize: 12)),
//               const Text('• Stock inicial', style: TextStyle(fontSize: 12)),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSidebarActions(BuildContext context) {
//     return Column(
//       children: [
//         // ✅ SOLUCIÓN: GetBuilder en lugar de Obx para el botón de guardar
//         GetBuilder<ProductFormController>(
//           builder:
//               (controller) => CustomButton(
//                 text:
//                     controller.isSaving
//                         ? 'Guardando...'
//                         : controller.saveButtonText,
//                 icon: controller.isEditMode ? Icons.update : Icons.save,
//                 onPressed:
//                     controller.isSaving
//                         ? null
//                         : () {
//                           try {
//                             controller.saveProduct();
//                           } catch (e) {
//                             print('❌ Error al guardar: $e');
//                           }
//                         },
//                 isLoading: controller.isSaving,
//                 width: double.infinity,
//               ),
//         ),
//         const SizedBox(height: 12),
//         CustomButton(
//           text: 'Cancelar',
//           type: ButtonType.outline,
//           onPressed: () => Get.back(),
//           width: double.infinity,
//         ),
//       ],
//     );
//   }

//   // ==================== ACTIONS ====================

//   Widget _buildActions(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: CustomButton(
//             text: 'Cancelar',
//             type: ButtonType.outline,
//             onPressed: () => Get.back(),
//           ),
//         ),
//         const SizedBox(width: 16),
//         Expanded(
//           flex: 2,
//           child: GetBuilder<ProductFormController>(
//             builder:
//                 (controller) => CustomButton(
//                   text:
//                       controller.isSaving
//                           ? 'Guardando...'
//                           : controller.saveButtonText,
//                   icon: controller.isEditMode ? Icons.update : Icons.save,
//                   onPressed:
//                       controller.isSaving
//                           ? null
//                           : () {
//                             try {
//                               controller.saveProduct();
//                             } catch (e) {
//                               print('❌ Error al guardar: $e');
//                             }
//                           },
//                   isLoading: controller.isSaving,
//                 ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget? _buildBottomActions(BuildContext context) {
//     if (!context.isMobile) return null;

//     return Container(
//       padding: EdgeInsets.all(context.responsivePadding.horizontal),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border(top: BorderSide(color: Colors.grey.shade300)),
//       ),
//       child: SafeArea(child: _buildActions(context)),
//     );
//   }

//   // ==================== HELPER METHODS ====================

//   void _handleMenuAction(String action, BuildContext context) {
//     try {
//       switch (action) {
//         case 'clear':
//           _showClearConfirmation(context);
//           break;
//         case 'preview':
//           controller.previewProduct();
//           break;
//         case 'calculator':
//           controller.showPriceCalculator();
//           break;
//       }
//     } catch (e) {
//       print('❌ Error en acción del menú: $e');
//     }
//   }

//   void _showClearConfirmation(BuildContext context) {
//     Get.dialog(
//       AlertDialog(
//         title: const Text('Limpiar Formulario'),
//         content: const Text(
//           '¿Estás seguro que deseas limpiar todos los campos?\n\n'
//           'Esta acción no se puede deshacer.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: const Text('Cancelar'),
//           ),
//           TextButton(
//             onPressed: () {
//               Get.back();
//               try {
//                 controller.clearForm();
//               } catch (e) {
//                 print('❌ Error al limpiar formulario: $e');
//               }
//             },
//             style: TextButton.styleFrom(foregroundColor: Colors.orange),
//             child: const Text('Limpiar'),
//           ),
//         ],
//       ),
//     );
//   }

//   String _getTypeDisplayName(ProductType type) {
//     switch (type) {
//       case ProductType.product:
//         return 'Producto';
//       case ProductType.service:
//         return 'Servicio';
//       default:
//         return type.toString();
//     }
//   }

//   String _getStatusDisplayName(ProductStatus status) {
//     switch (status) {
//       case ProductStatus.active:
//         return 'Activo';
//       case ProductStatus.inactive:
//         return 'Inactivo';
//       default:
//         return status.toString();
//     }
//   }
// }

// lib/features/products/presentation/screens/product_form_screen.dart
import 'package:baudex_desktop/features/products/presentation/widgets/category_selector_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/product_form_controller.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_price.dart';

// Importa la pantalla del escáner de código de barras
import 'package:baudex_desktop/app/shared/screens/barcode_scanner_screen.dart';

class ProductFormScreen extends GetView<ProductFormController> {
  const ProductFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('🖼️ ProductFormScreen: Construyendo pantalla...');
    print('DEBUG: context.isMobile es: ${context.isMobile}');

    return Scaffold(
      appBar: _buildAppBar(context),
      body: GetBuilder<ProductFormController>(
        builder: (controller) {
          print(
            '🔄 ProductFormScreen: Reconstruyendo body - isLoading: ${controller.isLoading}',
          );

          if (controller.isLoading) {
            return LoadingWidget(
              message:
                  controller.isEditMode
                      ? 'Cargando producto...'
                      : 'Preparando formulario...',
            );
          }

          return ResponsiveLayout(
            mobile: _buildMobileLayout(context),
            tablet: _buildTabletLayout(context),
            desktop: _buildDesktopLayout(context),
          );
        },
      ),
      bottomNavigationBar: _buildBottomActions(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: GetBuilder<ProductFormController>(
        builder: (controller) => Text(controller.pageTitle),
      ),
      elevation: 0,
      actions: [
        // Previsualizar - Solo en desktop/tablet
        if (!context.isMobile)
          IconButton(
            icon: const Icon(Icons.preview),
            onPressed: () {
              try {
                controller.previewProduct();
              } catch (e) {
                print('❌ Error en previsualizar: $e');
              }
            },
            tooltip: 'Previsualizar',
          ),

        // Limpiar formulario - Solo mostrar si NO es modo edición
        if (!context.isMobile)
          GetBuilder<ProductFormController>(
            builder: (controller) {
              if (!controller.isEditMode) {
                return IconButton(
                  icon: const Icon(Icons.clear_all),
                  onPressed: () => _showClearConfirmation(context),
                  tooltip: 'Limpiar formulario',
                );
              }
              return const SizedBox.shrink();
            },
          ),

        // Menú de opciones - Responsive
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, context),
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all),
                      SizedBox(width: 8),
                      Text('Limpiar Formulario'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'preview',
                  child: Row(
                    children: [
                      Icon(Icons.preview),
                      SizedBox(width: 8),
                      Text('Previsualizar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'calculator',
                  child: Row(
                    children: [
                      Icon(Icons.calculate),
                      SizedBox(width: 8),
                      Text('Calculadora'),
                    ],
                  ),
                ),
              ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(context.isMobile ? 16.0 : 20.0),
        child: Column(
          children: [
            // Información básica
            _buildBasicInfoSection(context),
            SizedBox(height: context.verticalSpacing),

            // Stock y medidas en mobile
            _buildStockSection(context),
            SizedBox(height: context.verticalSpacing),

            // Dimensiones en móvil
            _buildDimensionsSection(context),
            SizedBox(height: context.verticalSpacing),

            // Precios
            _buildPricesSection(context),
            SizedBox(height: context.verticalSpacing * 3),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: SingleChildScrollView(
        child: AdaptiveContainer(
          maxWidth: 1000, // Aumentado para tablet
          child: Column(
            children: [
              SizedBox(height: context.verticalSpacing),

              // Información básica
              CustomCard(child: _buildBasicInfoContent(context)),
              SizedBox(height: context.verticalSpacing),

              // Stock y dimensiones en dos columnas para tablet
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 1,
                      child: CustomCard(child: _buildStockContent(context)),
                    ),
                    SizedBox(width: context.horizontalSpacing),
                    Expanded(
                      flex: 1,
                      child: CustomCard(
                        child: _buildDimensionsContent(context),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.verticalSpacing),

              // Precios
              CustomCard(child: _buildPricesContent(context)),
              SizedBox(height: context.verticalSpacing),

              // Acciones para tablet
              _buildTabletActions(context),
              SizedBox(height: context.verticalSpacing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Contenido principal - Más ancho
        Expanded(
          flex: 3, // Aumentado de 2 a 3
          child: Form(
            key: controller.formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(context.horizontalSpacing * 1.5),
              child: Column(
                children: [
                  // Información básica
                  CustomCard(child: _buildBasicInfoContent(context)),
                  SizedBox(height: context.verticalSpacing),

                  // Stock y dimensiones en desktop
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 1,
                          child: CustomCard(child: _buildStockContent(context)),
                        ),
                        SizedBox(width: context.horizontalSpacing),
                        Expanded(
                          flex: 1,
                          child: CustomCard(
                            child: _buildDimensionsContent(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.verticalSpacing),

                  // Precios
                  CustomCard(child: _buildPricesContent(context)),
                  SizedBox(height: context.verticalSpacing),
                ],
              ),
            ),
          ),
        ),

        // Panel lateral - Más compacto
        Container(
          width: MediaQuery.of(context).size.width * 0.25, // Responsive width
          constraints: const BoxConstraints(minWidth: 280, maxWidth: 350),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(left: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Column(
            children: [
              // Header del panel
              Container(
                padding: EdgeInsets.all(context.horizontalSpacing),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Configuración',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                          fontSize: Responsive.getFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Contenido del panel
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(context.horizontalSpacing),
                  child: _buildSidebarContent(context),
                ),
              ),

              // Acciones en el panel
              Padding(
                padding: EdgeInsets.all(context.horizontalSpacing),
                child: _buildSidebarActions(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== SECTIONS ====================

  Widget _buildBasicInfoSection(BuildContext context) {
    return CustomCard(child: _buildBasicInfoContent(context));
  }

  Widget _buildBasicInfoContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información Básica',
          style: TextStyle(
            fontSize: Responsive.getFontSize(
              context,
              mobile: 18,
              tablet: 20,
              desktop: 22,
            ),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: context.verticalSpacing),

        // Nombre del producto
        CustomTextField(
          controller: controller.nameController,
          label: 'Nombre del Producto *',
          hint: 'Ingresa el nombre del producto',
          prefixIcon: Icons.inventory_2,
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return 'El nombre es requerido';
            }
            return null;
          },
        ),
        SizedBox(height: context.verticalSpacing),

        // Descripción
        CustomTextField(
          controller: controller.descriptionController,
          label: 'Descripción',
          hint: 'Descripción detallada del producto',
          prefixIcon: Icons.description,
          maxLines: context.isMobile ? 2 : 3,
        ),
        SizedBox(height: context.verticalSpacing),

        // SKU y Código de barras - Responsive
        if (context.isMobile) ...[
          // En móvil: columna
          CustomTextField(
            controller: controller.skuController,
            label: 'SKU *',
            hint: 'Código único del producto',
            prefixIcon: Icons.qr_code,
            validator: (value) {
              if (value?.trim().isEmpty ?? true) {
                return 'El SKU es requerido';
              }
              return null;
            },
          ),
          SizedBox(height: context.verticalSpacing * 0.75),
          CustomButton(
            text: 'Generar SKU',
            type: ButtonType.outline,
            onPressed: () {
              try {
                controller.generateSku();
              } catch (e) {
                print('❌ Error al generar SKU: $e');
              }
            },
            width: double.infinity,
          ),
        ] else ...[
          // En tablet/desktop: fila
          Row(
            children: [
              Expanded(
                flex: 3,
                child: CustomTextField(
                  controller: controller.skuController,
                  label: 'SKU *',
                  hint: 'Código único del producto',
                  prefixIcon: Icons.qr_code,
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return 'El SKU es requerido';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: context.horizontalSpacing * 0.75),
              SizedBox(
                width: Responsive.isTablet(context) ? 120 : 140,
                child: CustomButton(
                  text: 'Generar',
                  type: ButtonType.outline,
                  onPressed: () {
                    try {
                      controller.generateSku();
                    } catch (e) {
                      print('❌ Error al generar SKU: $e');
                    }
                  },
                ),
              ),
            ],
          ),
        ],
        SizedBox(height: context.verticalSpacing),

        // Código de barras con escáner
        CustomTextField(
          controller: controller.barcodeController,
          label: 'Código de Barras',
          hint: 'Código de barras del producto',
          prefixIcon: Icons.barcode_reader,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              return controller.validateBarcode(value)
                  ? null
                  : 'Código de barras inválido';
            }
            return null;
          },
          suffixIcon: context.isMobile ? Icons.camera_alt : null,
          onSuffixIconPressed:
              context.isMobile
                  ? () async {
                    final scannedCode = await Get.to<String>(
                      () => const BarcodeScannerScreen(),
                    );
                    if (scannedCode != null) {
                      controller.barcodeController.text = scannedCode;
                    }
                  }
                  : null,
        ),
        SizedBox(height: context.verticalSpacing),

        // Tipo y Estado - Responsive
        if (context.isMobile) ...[
          // En móvil: columna
          _buildTypeSelector(context),
          SizedBox(height: context.verticalSpacing * 0.75),
          _buildStatusSelector(context),
        ] else ...[
          // En tablet/desktop: fila
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: _buildTypeSelector(context)),
                SizedBox(width: context.horizontalSpacing),
                Expanded(child: _buildStatusSelector(context)),
              ],
            ),
          ),
        ],
        SizedBox(height: context.verticalSpacing),

        // Categoría
        _buildCategorySelector(context),
      ],
    );
  }

  Widget _buildStockSection(BuildContext context) {
    return CustomCard(child: _buildStockContent(context));
  }

  Widget _buildStockContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestión de Stock',
          style: TextStyle(
            fontSize: Responsive.getFontSize(
              context,
              mobile: 18,
              tablet: 20,
              desktop: 22,
            ),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: context.verticalSpacing),

        // Stock actual y mínimo - Responsive
        if (context.isMobile) ...[
          // En móvil: columna
          CustomTextField(
            controller: controller.stockController,
            label: 'Stock Actual *',
            hint: '0',
            prefixIcon: Icons.inventory,
            keyboardType: TextInputType.number,
            validator: (value) {
              final stock = double.tryParse(value ?? '');
              if (stock == null || stock < 0) {
                return 'Stock inválido';
              }
              return null;
            },
          ),
          SizedBox(height: context.verticalSpacing * 0.75),
          CustomTextField(
            controller: controller.minStockController,
            label: 'Stock Mínimo *',
            hint: '0',
            prefixIcon: Icons.warning,
            keyboardType: TextInputType.number,
            validator: (value) {
              final minStock = double.tryParse(value ?? '');
              if (minStock == null || minStock < 0) {
                return 'Stock mínimo inválido';
              }
              return null;
            },
          ),
        ] else ...[
          // En tablet/desktop: fila
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: controller.stockController,
                  label: 'Stock Actual *',
                  hint: '0',
                  prefixIcon: Icons.inventory,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final stock = double.tryParse(value ?? '');
                    if (stock == null || stock < 0) {
                      return 'Stock inválido';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: context.horizontalSpacing),
              Expanded(
                child: CustomTextField(
                  controller: controller.minStockController,
                  label: 'Stock Mínimo *',
                  hint: '0',
                  prefixIcon: Icons.warning,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final minStock = double.tryParse(value ?? '');
                    if (minStock == null || minStock < 0) {
                      return 'Stock mínimo inválido';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
        SizedBox(height: context.verticalSpacing),

        // Unidad de medida
        CustomTextField(
          controller: controller.unitController,
          label: 'Unidad de Medida',
          hint: 'pcs, kg, m, etc.',
          prefixIcon: Icons.straighten,
        ),
      ],
    );
  }

  // Nueva sección de dimensiones para móvil
  Widget _buildDimensionsSection(BuildContext context) {
    return CustomCard(child: _buildDimensionsContent(context));
  }

  Widget _buildDimensionsContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dimensiones y Peso',
          style: TextStyle(
            fontSize: Responsive.getFontSize(
              context,
              mobile: 18,
              tablet: 20,
              desktop: 22,
            ),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: context.verticalSpacing),

        // Peso
        CustomTextField(
          controller: controller.weightController,
          label: 'Peso (kg)',
          hint: '0.00',
          prefixIcon: Icons.fitness_center,
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: context.verticalSpacing),

        // Dimensiones - Responsive
        if (context.isMobile) ...[
          // En móvil: una por fila
          CustomTextField(
            controller: controller.lengthController,
            label: 'Largo (cm)',
            hint: '0.00',
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: context.verticalSpacing * 0.75),
          CustomTextField(
            controller: controller.widthController,
            label: 'Ancho (cm)',
            hint: '0.00',
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: context.verticalSpacing * 0.75),
          CustomTextField(
            controller: controller.heightController,
            label: 'Alto (cm)',
            hint: '0.00',
            keyboardType: TextInputType.number,
          ),
        ] else ...[
          // En tablet/desktop: tres columnas
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: controller.lengthController,
                  label: 'Largo (cm)',
                  hint: '0.00',
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: context.horizontalSpacing * 0.5),
              Expanded(
                child: CustomTextField(
                  controller: controller.widthController,
                  label: 'Ancho (cm)',
                  hint: '0.00',
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: context.horizontalSpacing * 0.5),
              Expanded(
                child: CustomTextField(
                  controller: controller.heightController,
                  label: 'Alto (cm)',
                  hint: '0.00',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPricesSection(BuildContext context) {
    return CustomCard(child: _buildPricesContent(context));
  }

  Widget _buildPricesContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header responsive
        if (context.isMobile) ...[
          // En móvil: columna
          Text(
            'Configuración de Precios',
            style: TextStyle(
              fontSize: Responsive.getFontSize(
                context,
                mobile: 18,
                tablet: 20,
                desktop: 22,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: context.verticalSpacing * 0.75),
          CustomButton(
            text: 'Calculadora de Precios',
            icon: Icons.calculate,
            type: ButtonType.outline,
            onPressed: () {
              try {
                controller.showPriceCalculator();
              } catch (e) {
                print('❌ Error en calculadora: $e');
              }
            },
            width: double.infinity,
          ),
        ] else ...[
          // En tablet/desktop: fila
          Row(
            children: [
              Expanded(
                child: Text(
                  'Configuración de Precios',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(
                      context,
                      mobile: 18,
                      tablet: 20,
                      desktop: 22,
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              CustomButton(
                text:
                    Responsive.isTablet(context)
                        ? 'Calculadora'
                        : 'Calculadora de Precios',
                icon: Icons.calculate,
                type: ButtonType.outline,
                onPressed: () {
                  try {
                    controller.showPriceCalculator();
                  } catch (e) {
                    print('❌ Error en calculadora: $e');
                  }
                },
              ),
            ],
          ),
        ],
        SizedBox(height: context.verticalSpacing),

        // Precio de costo
        CustomTextField(
          controller: controller.costPriceController,
          label: 'Precio de Costo',
          hint: '0.00',
          prefixIcon: Icons.attach_money,
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: context.verticalSpacing),

        // Precios de venta - Responsive
        if (context.isMobile) ...[
          // En móvil: uno por fila
          CustomTextField(
            controller: controller.price1Controller,
            label: 'Precio al Público',
            hint: '0.00',
            prefixIcon: Icons.sell,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: context.verticalSpacing * 0.75),
          CustomTextField(
            controller: controller.price2Controller,
            label: 'Precio Mayorista',
            hint: '0.00',
            prefixIcon: Icons.sell,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: context.verticalSpacing * 0.75),
          CustomTextField(
            controller: controller.price3Controller,
            label: 'Precio Distribuidor',
            hint: '0.00',
            prefixIcon: Icons.sell,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: context.verticalSpacing * 0.75),
          CustomTextField(
            controller: controller.specialPriceController,
            label: 'Precio Especial',
            hint: '0.00',
            prefixIcon: Icons.local_offer,
            keyboardType: TextInputType.number,
          ),
        ] else ...[
          // En tablet/desktop: dos por fila
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: controller.price1Controller,
                  label: 'Precio al Público',
                  hint: '0.00',
                  prefixIcon: Icons.sell,
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: context.horizontalSpacing),
              Expanded(
                child: CustomTextField(
                  controller: controller.price2Controller,
                  label: 'Precio Mayorista',
                  hint: '0.00',
                  prefixIcon: Icons.sell,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          SizedBox(height: context.verticalSpacing),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: controller.price3Controller,
                  label: 'Precio Distribuidor',
                  hint: '0.00',
                  prefixIcon: Icons.sell,
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: context.horizontalSpacing),
              Expanded(
                child: CustomTextField(
                  controller: controller.specialPriceController,
                  label: 'Precio Especial',
                  hint: '0.00',
                  prefixIcon: Icons.local_offer,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],

        // Información de márgenes
        _buildMarginInfo(context),
      ],
    );
  }

  Widget _buildMarginInfo(BuildContext context) {
    final costText = controller.costPriceController.text;
    final sellText = controller.price1Controller.text;

    if (costText.isEmpty || sellText.isEmpty) {
      return const SizedBox.shrink();
    }

    final costPrice = double.tryParse(costText) ?? 0;
    final sellPrice = double.tryParse(sellText) ?? 0;
    final margin = controller.calculateMargin(costPrice, sellPrice);

    return Container(
      margin: EdgeInsets.only(top: context.verticalSpacing),
      padding: EdgeInsets.all(context.horizontalSpacing * 0.75),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up, color: Colors.blue.shade600),
          SizedBox(width: context.horizontalSpacing * 0.5),
          Expanded(
            child: Text(
              'Margen de ganancia: ${margin.toStringAsFixed(1)}%',
              style: TextStyle(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w600,
                fontSize: Responsive.getFontSize(
                  context,
                  mobile: 14,
                  tablet: 15,
                  desktop: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SELECTORS ====================

  Widget _buildTypeSelector(BuildContext context) {
    return GetBuilder<ProductFormController>(
      builder:
          (controller) => DropdownButtonFormField<ProductType>(
            value: controller.productType,
            decoration: InputDecoration(
              labelText: 'Tipo *',
              prefixIcon: const Icon(Icons.category),
              border: const OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.isMobile ? 12 : 16,
                vertical: context.isMobile ? 16 : 18,
              ),
              isDense: !Responsive.isMobile(context),
            ),
            isExpanded: true,
            items:
                ProductType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      _getTypeDisplayName(type),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Responsive.getFontSize(context),
                      ),
                    ),
                  );
                }).toList(),
            onChanged: (value) {
              if (value != null) {
                try {
                  controller.setProductType(value);
                } catch (e) {
                  print('❌ Error al cambiar tipo: $e');
                }
              }
            },
            validator: (value) => value == null ? 'Selecciona un tipo' : null,
          ),
    );
  }

  Widget _buildStatusSelector(BuildContext context) {
    return GetBuilder<ProductFormController>(
      builder:
          (controller) => DropdownButtonFormField<ProductStatus>(
            value: controller.productStatus,
            decoration: InputDecoration(
              labelText: 'Estado *',
              prefixIcon: const Icon(Icons.toggle_on),
              border: const OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.isMobile ? 12 : 16,
                vertical: context.isMobile ? 16 : 18,
              ),
              isDense: !Responsive.isMobile(context),
            ),
            isExpanded: true,
            items:
                ProductStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(
                      _getStatusDisplayName(status),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Responsive.getFontSize(context),
                      ),
                    ),
                  );
                }).toList(),
            onChanged: (value) {
              if (value != null) {
                try {
                  controller.setProductStatus(value);
                } catch (e) {
                  print('❌ Error al cambiar estado: $e');
                }
              }
            },
          ),
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
    print('🔧 ProductFormScreen: Construyendo selector de categorías');

    return GetBuilder<ProductFormController>(
      builder: (controller) {
        print('   selectedCategoryId: ${controller.selectedCategoryId}');
        print('   selectedCategoryName: ${controller.selectedCategoryName}');

        return CategorySelectorWidget(
          selectedCategoryId: controller.selectedCategoryId,
          selectedCategoryName: controller.selectedCategoryName,
          onCategorySelected: (categoryId, categoryName) {
            print('🎯 Categoría seleccionada: $categoryName ($categoryId)');
            controller.setCategorySelection(categoryId, categoryName);
          },
          label: 'Categoría',
          hint: 'Seleccionar categoría',
          isRequired: true,
        );
      },
    );
  }

  // ==================== SIDEBAR ====================

  Widget _buildSidebarContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Herramientas',
          style: TextStyle(
            fontSize: Responsive.getFontSize(
              context,
              mobile: 16,
              tablet: 16,
              desktop: 16,
            ),
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: context.verticalSpacing),

        CustomButton(
          text: 'Generar SKU',
          icon: Icons.auto_fix_high,
          type: ButtonType.outline,
          onPressed: () {
            try {
              controller.generateSku();
            } catch (e) {
              print('❌ Error al generar SKU: $e');
            }
          },
          width: double.infinity,
        ),
        SizedBox(height: context.verticalSpacing * 0.75),

        CustomButton(
          text: 'Calculadora de Precios',
          icon: Icons.calculate,
          type: ButtonType.outline,
          onPressed: () {
            try {
              controller.showPriceCalculator();
            } catch (e) {
              print('❌ Error en calculadora: $e');
            }
          },
          width: double.infinity,
        ),
        SizedBox(height: context.verticalSpacing * 0.75),

        CustomButton(
          text: 'Previsualizar',
          icon: Icons.preview,
          type: ButtonType.outline,
          onPressed: () {
            try {
              controller.previewProduct();
            } catch (e) {
              print('❌ Error en previsualizar: $e');
            }
          },
          width: double.infinity,
        ),

        SizedBox(height: context.verticalSpacing * 1.5),
        const Divider(),
        SizedBox(height: context.verticalSpacing),

        Text(
          'Información',
          style: TextStyle(
            fontSize: Responsive.getFontSize(
              context,
              mobile: 14,
              tablet: 14,
              desktop: 14,
            ),
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: context.verticalSpacing * 0.75),

        Container(
          padding: EdgeInsets.all(context.horizontalSpacing * 0.75),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Campos requeridos:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Nombre del producto',
                style: TextStyle(fontSize: 12),
              ),
              const Text('• SKU único', style: TextStyle(fontSize: 12)),
              const Text('• Tipo de producto', style: TextStyle(fontSize: 12)),
              const Text('• Categoría', style: TextStyle(fontSize: 12)),
              const Text('• Stock inicial', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarActions(BuildContext context) {
    return Column(
      children: [
        GetBuilder<ProductFormController>(
          builder:
              (controller) => CustomButton(
                text:
                    controller.isSaving
                        ? 'Guardando...'
                        : controller.saveButtonText,
                icon: controller.isEditMode ? Icons.update : Icons.save,
                onPressed:
                    controller.isSaving
                        ? null
                        : () {
                          try {
                            controller.saveProduct();
                          } catch (e) {
                            print('❌ Error al guardar: $e');
                          }
                        },
                isLoading: controller.isSaving,
                width: double.infinity,
              ),
        ),
        SizedBox(height: context.verticalSpacing * 0.75),
        CustomButton(
          text: 'Cancelar',
          type: ButtonType.outline,
          onPressed: () => Get.back(),
          width: double.infinity,
        ),
      ],
    );
  }

  // ==================== ACTIONS ====================

  Widget _buildTabletActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: 'Cancelar',
            type: ButtonType.outline,
            onPressed: () => Get.back(),
          ),
        ),
        SizedBox(width: context.horizontalSpacing),
        Expanded(
          flex: 2,
          child: GetBuilder<ProductFormController>(
            builder:
                (controller) => CustomButton(
                  text:
                      controller.isSaving
                          ? 'Guardando...'
                          : controller.saveButtonText,
                  icon: controller.isEditMode ? Icons.update : Icons.save,
                  onPressed:
                      controller.isSaving
                          ? null
                          : () {
                            try {
                              controller.saveProduct();
                            } catch (e) {
                              print('❌ Error al guardar: $e');
                            }
                          },
                  isLoading: controller.isSaving,
                ),
          ),
        ),
      ],
    );
  }

  Widget? _buildBottomActions(BuildContext context) {
    if (!context.isMobile) return null;

    return Container(
      padding: EdgeInsets.all(context.responsivePadding.horizontal),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Cancelar',
                type: ButtonType.outline,
                onPressed: () => Get.back(),
              ),
            ),
            SizedBox(width: context.horizontalSpacing),
            Expanded(
              flex: 2,
              child: GetBuilder<ProductFormController>(
                builder:
                    (controller) => CustomButton(
                      text:
                          controller.isSaving
                              ? 'Guardando...'
                              : controller.saveButtonText,
                      icon: controller.isEditMode ? Icons.update : Icons.save,
                      onPressed:
                          controller.isSaving
                              ? null
                              : () {
                                try {
                                  controller.saveProduct();
                                } catch (e) {
                                  print('❌ Error al guardar: $e');
                                }
                              },
                      isLoading: controller.isSaving,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPER METHODS ====================

  void _handleMenuAction(String action, BuildContext context) {
    try {
      switch (action) {
        case 'clear':
          _showClearConfirmation(context);
          break;
        case 'preview':
          controller.previewProduct();
          break;
        case 'calculator':
          controller.showPriceCalculator();
          break;
      }
    } catch (e) {
      print('❌ Error en acción del menú: $e');
    }
  }

  void _showClearConfirmation(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Limpiar Formulario'),
        content: const Text(
          '¿Estás seguro que deseas limpiar todos los campos?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              try {
                controller.clearForm();
              } catch (e) {
                print('❌ Error al limpiar formulario: $e');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  String _getTypeDisplayName(ProductType type) {
    switch (type) {
      case ProductType.product:
        return 'Producto';
      case ProductType.service:
        return 'Servicio';
      default:
        return type.toString();
    }
  }

  String _getStatusDisplayName(ProductStatus status) {
    switch (status) {
      case ProductStatus.active:
        return 'Activo';
      case ProductStatus.inactive:
        return 'Inactivo';
      default:
        return status.toString();
    }
  }
}
