// lib/features/products/presentation/screens/product_detail_screen.dart
import 'package:baudex_desktop/app/config/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/product_detail_controller.dart';
import '../../domain/entities/product.dart';

class ProductDetailScreen extends GetView<ProductDetailController> {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Obx(() {
        if (controller.isLoading) {
          return const LoadingWidget(message: 'Cargando detalles...');
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
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Obx(
        () => Text(controller.hasProduct ? controller.productName : 'Producto'),
      ),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          // Navega directamente al dashboard y elimina el historial
          Get.offAllNamed(AppRoutes.products);
        },
      ),
      actions: [
        // Compartir
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: controller.shareProduct,
        ),

        // Editar
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: controller.goToEditProduct,
        ),

        // Gestión de stock
        IconButton(
          icon: const Icon(Icons.inventory),
          onPressed: controller.showStockDialog,
        ),

        // Menú de opciones
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, context),
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'print_label',
                  child: Row(
                    children: [
                      Icon(Icons.print),
                      SizedBox(width: 8),
                      Text('Imprimir Etiqueta'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'generate_report',
                  child: Row(
                    children: [
                      Icon(Icons.analytics),
                      SizedBox(width: 8),
                      Text('Generar Reporte'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh),
                      SizedBox(width: 8),
                      Text('Actualizar'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // Header compacto con información básica
          _buildMobileHeader(context),

          // Tab Bar
          _buildTabBar(context),

          // Tab Bar View
          Expanded(child: _buildTabBarView(context)),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      child: AdaptiveContainer(
        maxWidth: 900,
        child: Column(
          children: [
            SizedBox(height: context.verticalSpacing),
            CustomCard(child: _buildProductHeader(context)),
            SizedBox(height: context.verticalSpacing),
            CustomCard(child: _buildProductDetails(context)),
            SizedBox(height: context.verticalSpacing),
            CustomCard(child: _buildPricesSection(context)),
            SizedBox(height: context.verticalSpacing),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Contenido principal
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                CustomCard(child: _buildProductHeader(context)),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomCard(child: _buildProductDetails(context)),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: CustomCard(child: _buildPricesSection(context)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Panel lateral
        Container(
          width: 350,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(left: BorderSide(color: Colors.grey.shade300)),
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
                    Icon(Icons.settings, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Acciones',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Acciones
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildSidebarActions(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    return Container(
      padding: context.responsivePadding,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Obx(() {
        final product = controller.product!;
        return Row(
          children: [
            // Imagen del producto
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                image:
                    product.primaryImage != null
                        ? DecorationImage(
                          image: NetworkImage(product.primaryImage!),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
              child:
                  product.primaryImage == null
                      ? Icon(
                        Icons.inventory_2,
                        size: 30,
                        color: Colors.grey.shade400,
                      )
                      : null,
            ),

            SizedBox(width: context.horizontalSpacing),

            // Información básica
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SKU: ${product.sku}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: controller.getStockStatusColor().withOpacity(
                            0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          controller.getStockStatusText(),
                          style: TextStyle(
                            color: controller.getStockStatusColor(),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (product.defaultPrice != null)
                        Text(
                          '\$${product.defaultPrice!.finalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Material(
      color: Colors.white,
      child: TabBar(
        controller: controller.tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: Theme.of(context).primaryColor,
        tabs: const [
          Tab(text: 'Detalles'),
          Tab(text: 'Precios'),
          Tab(text: 'Movimientos'),
        ],
      ),
    );
  }

  Widget _buildTabBarView(BuildContext context) {
    return TabBarView(
      controller: controller.tabController,
      children: [
        SingleChildScrollView(
          padding: context.responsivePadding,
          child: _buildProductDetails(context),
        ),
        SingleChildScrollView(
          padding: context.responsivePadding,
          child: _buildPricesSection(context),
        ),
        SingleChildScrollView(
          padding: context.responsivePadding,
          child: _buildMovementsSection(context),
        ),
      ],
    );
  }

  Widget _buildProductHeader(BuildContext context) {
    return Obx(() {
      final product = controller.product!;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Imagen de producto
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  image:
                      product.primaryImage != null
                          ? DecorationImage(
                            image: NetworkImage(product.primaryImage!),
                            fit: BoxFit.cover,
                          )
                          : null,
                ),
                child:
                    product.primaryImage == null
                        ? Icon(
                          Icons.inventory_2,
                          size: 60,
                          color: Colors.grey.shade400,
                        )
                        : null,
              ),

              SizedBox(width: context.horizontalSpacing * 2),

              // Información principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: Responsive.getFontSize(
                          context,
                          mobile: 24,
                          tablet: 28,
                          desktop: 32,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SKU: ${product.sku}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (product.barcode != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Código: ${product.barcode}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Estado del producto
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                product.isActive
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            product.isActive ? 'ACTIVO' : 'INACTIVO',
                            style: TextStyle(
                              color:
                                  product.isActive
                                      ? Colors.green.shade800
                                      : Colors.orange.shade800,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Estado del stock
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: controller.getStockStatusColor().withOpacity(
                              0.1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            controller.getStockStatusText().toUpperCase(),
                            style: TextStyle(
                              color: controller.getStockStatusColor(),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Precio principal
              if (product.defaultPrice != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${product.defaultPrice!.finalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    if (product.defaultPrice!.hasDiscount)
                      Text(
                        '\$${product.defaultPrice!.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
            ],
          ),

          if (product.description != null) ...[
            const SizedBox(height: 16),
            Text(
              product.description!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildProductDetails(BuildContext context) {
    return Obx(() {
      final product = controller.product!;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información del Producto',
            style: TextStyle(
              fontSize: Responsive.getFontSize(context, mobile: 18, tablet: 20),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Información básica
          _buildDetailCard('Información Básica', [
            _buildDetailRow('Tipo', product.type.name.toUpperCase()),
            _buildDetailRow('Categoría', product.category?.name ?? 'N/A'),
            _buildDetailRow('Unidad', product.unit ?? 'pcs'),
            _buildDetailRow('Creado por', product.createdBy?.fullName ?? 'N/A'),
          ]),

          const SizedBox(height: 16),

          // Información de stock
          _buildDetailCard('Gestión de Stock', [
            _buildDetailRow(
              'Stock Actual',
              '${product.stock.toStringAsFixed(2)} ${product.unit ?? "pcs"}',
            ),
            _buildDetailRow(
              'Stock Mínimo',
              '${product.minStock.toStringAsFixed(2)} ${product.unit ?? "pcs"}',
            ),
            _buildDetailRow('Estado Stock', controller.getStockStatusText()),
            if (product.isLowStock)
              _buildDetailRow(
                'Alerta',
                'Stock por debajo del mínimo',
                isWarning: true,
              ),
          ]),

          const SizedBox(height: 16),

          // Dimensiones y peso
          if (product.weight != null ||
              product.length != null ||
              product.width != null ||
              product.height != null)
            _buildDetailCard('Dimensiones y Peso', [
              if (product.weight != null)
                _buildDetailRow(
                  'Peso',
                  '${product.weight!.toStringAsFixed(2)} kg',
                ),
              if (product.length != null)
                _buildDetailRow(
                  'Largo',
                  '${product.length!.toStringAsFixed(2)} cm',
                ),
              if (product.width != null)
                _buildDetailRow(
                  'Ancho',
                  '${product.width!.toStringAsFixed(2)} cm',
                ),
              if (product.height != null)
                _buildDetailRow(
                  'Alto',
                  '${product.height!.toStringAsFixed(2)} cm',
                ),
            ]),

          const SizedBox(height: 16),

          // Fechas
          _buildDetailCard('Información de Registro', [
            _buildDetailRow('Creado', _formatDate(product.createdAt)),
            _buildDetailRow('Actualizado', _formatDate(product.updatedAt)),
          ]),
        ],
      );
    });
  }

  // Widget _buildPricesSection(BuildContext context) {
  //   return Obx(() {
  //     final product = controller.product!;

  //     return Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           'Precios del Producto',
  //           style: TextStyle(
  //             fontSize: Responsive.getFontSize(context, mobile: 18, tablet: 20),
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //         const SizedBox(height: 16),

  //         if (product.prices == null || product.prices!.isEmpty)
  //           _buildEmptyPricesState(context)
  //         else
  //           ...product.prices!.map((price) => _buildPriceCard(context, price)),
  //       ],
  //     );
  //   });
  // }

  Widget _buildPricesSection(BuildContext context) {
    return Obx(() {
      final product = controller.product!;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Precios del Producto',
            style: TextStyle(
              fontSize: Responsive.getFontSize(context, mobile: 18, tablet: 20),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (product.prices == null || product.prices!.isEmpty)
            _buildEmptyPricesState(context)
          else
            ...product.prices!.map((price) => _buildPriceCard(context, price)),
        ],
      );
    });
  }

  // Widget _buildPriceCard(BuildContext context, productPrice) {
  //   return Container(
  //     margin: const EdgeInsets.only(bottom: 12),
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: Colors.grey.shade300),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Text(
  //               _getPriceTypeName(productPrice.type.name),
  //               style: const TextStyle(
  //                 fontSize: 16,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //             const Spacer(),
  //             Text(
  //               '\$${productPrice.finalAmount.toStringAsFixed(2)}',
  //               style: TextStyle(
  //                 fontSize: 20,
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.green.shade700,
  //               ),
  //             ),
  //           ],
  //         ),
  //         if (productPrice.hasDiscount) ...[
  //           const SizedBox(height: 4),
  //           Row(
  //             children: [
  //               Text(
  //                 'Precio original: \$${productPrice.amount.toStringAsFixed(2)}',
  //                 style: TextStyle(
  //                   fontSize: 14,
  //                   decoration: TextDecoration.lineThrough,
  //                   color: Colors.grey.shade600,
  //                 ),
  //               ),
  //               const SizedBox(width: 8),
  //               Container(
  //                 padding: const EdgeInsets.symmetric(
  //                   horizontal: 6,
  //                   vertical: 2,
  //                 ),
  //                 decoration: BoxDecoration(
  //                   color: Colors.red.shade100,
  //                   borderRadius: BorderRadius.circular(8),
  //                 ),
  //                 child: Text(
  //                   '-${productPrice.discountPercentage.toStringAsFixed(0)}%',
  //                   style: TextStyle(
  //                     fontSize: 12,
  //                     fontWeight: FontWeight.bold,
  //                     color: Colors.red.shade700,
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ],
  //         if (productPrice.minQuantity > 1) ...[
  //           const SizedBox(height: 4),
  //           Text(
  //             'Cantidad mínima: ${productPrice.minQuantity.toStringAsFixed(0)}',
  //             style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
  //           ),
  //         ],
  //       ],
  //     ),
  //   );
  // }

  Widget _buildPriceCard(BuildContext context, productPrice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                // ✅ SOLUCIÓN: Usar método helper seguro en lugar de .name
                _getPriceTypeDisplayName(productPrice.type),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                '\$${_formatPrice(productPrice.finalAmount)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),

          // ✅ AÑADIDO: Validación segura para descuentos
          if (_hasDiscount(productPrice)) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Precio original: \$${_formatPrice(productPrice.amount)}',
                  style: TextStyle(
                    fontSize: 14,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '-${_formatPrice(productPrice.discountPercentage)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // ✅ AÑADIDO: Validación segura para cantidad mínima
          if (_hasMinQuantity(productPrice)) ...[
            const SizedBox(height: 4),
            Text(
              'Cantidad mínima: ${_formatQuantity(productPrice.minQuantity)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  String _getPriceTypeDisplayName(dynamic priceType) {
    try {
      // Si es un enum con extensión
      if (priceType != null && priceType.displayName != null) {
        return priceType.displayName;
      }

      // Si es un string directamente
      if (priceType is String) {
        return _mapStringToPriceTypeName(priceType);
      }

      // Si es un enum sin extensión, usar toString()
      final typeString = priceType.toString().split('.').last;
      return _mapStringToPriceTypeName(typeString);
    } catch (e) {
      print('❌ Error al obtener nombre de tipo de precio: $e');
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

  String _formatPrice(dynamic value) {
    try {
      if (value == null) return '0.00';

      double price;
      if (value is double) {
        price = value;
      } else if (value is int) {
        price = value.toDouble();
      } else if (value is String) {
        price = double.tryParse(value) ?? 0.0;
      } else {
        price = 0.0;
      }

      return price.toStringAsFixed(2);
    } catch (e) {
      print('❌ Error al formatear precio: $e');
      return '0.00';
    }
  }

  String _formatQuantity(dynamic value) {
    try {
      if (value == null) return '1';

      if (value is double) {
        return value.toStringAsFixed(0);
      } else if (value is int) {
        return value.toString();
      } else if (value is String) {
        final quantity = double.tryParse(value) ?? 1.0;
        return quantity.toStringAsFixed(0);
      }

      return '1';
    } catch (e) {
      print('❌ Error al formatear cantidad: $e');
      return '1';
    }
  }

  bool _hasDiscount(dynamic productPrice) {
    try {
      if (productPrice == null) return false;

      // Verificar descuento por porcentaje
      final discountPercentage = productPrice.discountPercentage;
      if (discountPercentage != null && discountPercentage > 0) {
        return true;
      }

      // Verificar descuento por cantidad
      final discountAmount = productPrice.discountAmount;
      if (discountAmount != null && discountAmount > 0) {
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Error al verificar descuento: $e');
      return false;
    }
  }

  bool _hasMinQuantity(dynamic productPrice) {
    try {
      if (productPrice == null) return false;

      final minQuantity = productPrice.minQuantity;
      if (minQuantity != null && minQuantity > 1) {
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Error al verificar cantidad mínima: $e');
      return false;
    }
  }

  // Widget _buildMovementsSection(BuildContext context) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         'Movimientos de Stock',
  //         style: TextStyle(
  //           fontSize: Responsive.getFontSize(context, mobile: 18, tablet: 20),
  //           fontWeight: FontWeight.bold,
  //         ),
  //       ),
  //       const SizedBox(height: 16),
  //       Container(
  //         padding: const EdgeInsets.all(24),
  //         decoration: BoxDecoration(
  //           color: Colors.grey.shade50,
  //           borderRadius: BorderRadius.circular(12),
  //           border: Border.all(color: Colors.grey.shade300),
  //         ),
  //         child: Column(
  //           children: [
  //             Icon(Icons.history, size: 48, color: Colors.grey.shade400),
  //             const SizedBox(height: 16),
  //             Text(
  //               'Historial de Movimientos',
  //               style: TextStyle(
  //                 fontSize: 16,
  //                 fontWeight: FontWeight.w600,
  //                 color: Colors.grey.shade600,
  //               ),
  //             ),
  //             const SizedBox(height: 8),
  //             Text(
  //               'Funcionalidad pendiente de implementar',
  //               style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
  //               textAlign: TextAlign.center,
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildMovementsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Movimientos de Stock',
          style: TextStyle(
            fontSize: Responsive.getFontSize(context, mobile: 18, tablet: 20),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Historial de Movimientos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Funcionalidad pendiente de implementar',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard(String title, List<Widget> details) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...details,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color:
                    isWarning ? Colors.orange.shade700 : Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPricesState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(
            Icons.price_change_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin precios configurados',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Este producto no tiene precios configurados',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Configurar Precios',
            icon: Icons.edit,
            onPressed: controller.goToEditProduct,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: 'Editar',
            icon: Icons.edit,
            type: ButtonType.outline,
            onPressed: controller.goToEditProduct,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CustomButton(
            text: 'Gestionar Stock',
            icon: Icons.inventory,
            onPressed: controller.showStockDialog,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Obx(
            () => CustomButton(
              text: controller.isDeleting ? 'Eliminando...' : 'Eliminar',
              icon: Icons.delete,
              backgroundColor: Colors.red,
              onPressed:
                  controller.isDeleting ? null : controller.confirmDelete,
              isLoading: controller.isDeleting,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomButton(
          text: 'Editar Producto',
          icon: Icons.edit,
          onPressed: controller.goToEditProduct,
          width: double.infinity,
        ),

        const SizedBox(height: 12),

        CustomButton(
          text: 'Gestionar Stock',
          icon: Icons.inventory,
          type: ButtonType.outline,
          onPressed: controller.showStockDialog,
          width: double.infinity,
        ),

        const SizedBox(height: 12),

        CustomButton(
          text: 'Imprimir Etiqueta',
          icon: Icons.print,
          type: ButtonType.outline,
          onPressed: controller.printLabel,
          width: double.infinity,
        ),

        const SizedBox(height: 24),

        const Divider(),

        const SizedBox(height: 12),

        CustomButton(
          text: 'Actualizar',
          icon: Icons.refresh,
          type: ButtonType.outline,
          onPressed: controller.refreshData,
          width: double.infinity,
        ),

        const SizedBox(height: 12),

        Obx(
          () => CustomButton(
            text: controller.isDeleting ? 'Eliminando...' : 'Eliminar',
            icon: Icons.delete,
            type: ButtonType.outline,
            onPressed: controller.isDeleting ? null : controller.confirmDelete,
            isLoading: controller.isDeleting,
            width: double.infinity,
            backgroundColor: Colors.red,
          ),
        ),

        const Spacer(),

        // Información del producto
        Obx(() {
          if (!controller.hasProduct) return const SizedBox.shrink();

          final product = controller.product!;
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Información Rápida',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Stock: ${product.stock.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Categoría: ${product.category?.name ?? "N/A"}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Última actualización:',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  _formatDate(product.updatedAt),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 100, color: Colors.grey.shade400),
          SizedBox(height: context.verticalSpacing),
          Text(
            'Producto no encontrado',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: context.verticalSpacing / 2),
          Text(
            'El producto que buscas no existe o ha sido eliminado',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.verticalSpacing * 2),
          CustomButton(
            text: 'Volver a Productos',
            icon: Icons.arrow_back,
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    if (context.isMobile) {
      return FloatingActionButton(
        onPressed: controller.goToEditProduct,
        child: const Icon(Icons.edit),
      );
    }
    return null;
  }

  // ==================== ACTION METHODS ====================

  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'print_label':
        controller.printLabel();
        break;
      case 'generate_report':
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getPriceTypeName(String type) {
    switch (type) {
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
}
