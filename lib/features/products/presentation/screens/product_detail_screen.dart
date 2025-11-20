// lib/features/products/presentation/screens/product_detail_screen.dart
import 'package:baudex_desktop/app/config/routes/app_routes.dart';
import 'package:baudex_desktop/app/core/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/product_detail_controller.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_price.dart';

class ProductDetailScreen extends GetView<ProductDetailController> {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
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
        child: Obx(() {
          if (controller.isLoading) {
            return const LoadingWidget(message: 'Cargando detalles...');
          }

          if (!controller.hasProduct) {
            return _buildErrorState(context);
          }

          return ResponsiveHelper.responsive(
            context,
            mobile: _buildMobileLayout(context),
            tablet: _buildTabletLayout(context),
            desktop: _buildDesktopLayout(context),
          );
        }),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Obx(
        () => Text(
          controller.hasProduct ? controller.productName : 'Producto',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          // Navega directamente al dashboard y elimina el historial
          Get.offAllNamed(AppRoutes.products);
        },
      ),
      actions: [
        // Compartir
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: controller.shareProduct,
          tooltip: 'Compartir producto',
        ),

        // Editar
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: controller.goToEditProduct,
          tooltip: 'Editar producto',
        ),

        // Gestión de stock
        IconButton(
          icon: const Icon(Icons.inventory, color: Colors.white),
          onPressed: controller.showStockDialog,
          tooltip: 'Gestionar stock',
        ),

        // Menú de opciones
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) => _handleMenuAction(value, context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'print_label',
              child: Row(
                children: [
                  Icon(Icons.print, color: ElegantLightTheme.primaryBlue, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Imprimir Etiqueta',
                    style: TextStyle(
                      color: ElegantLightTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'generate_report',
              child: Row(
                children: [
                  Icon(Icons.analytics, color: ElegantLightTheme.primaryBlue, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Generar Reporte',
                    style: TextStyle(
                      color: ElegantLightTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh, color: Colors.green.shade600, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Actualizar',
                    style: TextStyle(
                      color: ElegantLightTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Eliminar',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
            ElegantContainer(
              padding: const EdgeInsets.all(24),
              child: _buildProductHeader(context),
            ),
            SizedBox(height: context.verticalSpacing),
            ElegantContainer(
              padding: const EdgeInsets.all(24),
              child: _buildProductDetails(context),
            ),
            SizedBox(height: context.verticalSpacing),
            ElegantContainer(
              padding: const EdgeInsets.all(24),
              child: _buildPricesSection(context),
            ),
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
                ElegantContainer(
                  padding: const EdgeInsets.all(24),
                  child: _buildProductHeader(context),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ElegantContainer(
                        padding: const EdgeInsets.all(24),
                        child: _buildProductDetails(context),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: ElegantContainer(
                        padding: const EdgeInsets.all(24),
                        child: _buildPricesSection(context),
                      ),
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
                  color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.settings, color: ElegantLightTheme.primaryBlue),
                    SizedBox(width: 8),
                    Text(
                      'Acciones',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ElegantLightTheme.primaryBlue,
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
    return ElegantContainer(
      padding: context.responsivePadding,
      margin: EdgeInsets.zero,
      child: Obx(() {
        final product = controller.product!;
        return Row(
          children: [
            // Imagen del producto
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: ElegantLightTheme.cardColor,
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
                        color: ElegantLightTheme.textTertiary,
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
                      color: ElegantLightTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SKU: ${product.sku}',
                    style: TextStyle(color: ElegantLightTheme.textSecondary, fontSize: 14),
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
                          AppFormatters.formatPrice(
                            product.defaultPrice!.finalAmount,
                          ),
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
        labelColor: ElegantLightTheme.primaryBlue,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: ElegantLightTheme.primaryBlue,
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
                  color: ElegantLightTheme.cardColor,
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
                          color: ElegantLightTheme.textTertiary,
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
                        color: ElegantLightTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SKU: ${product.sku}',
                      style: TextStyle(
                        fontSize: 16,
                        color: ElegantLightTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (product.barcode != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Código: ${product.barcode}',
                        style: TextStyle(
                          fontSize: 14,
                          color: ElegantLightTheme.textSecondary,
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
                      AppFormatters.formatPrice(
                        product.defaultPrice!.finalAmount,
                      ),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    if (product.defaultPrice!.hasDiscount)
                      Text(
                        AppFormatters.formatPrice(product.defaultPrice!.amount),
                        style: TextStyle(
                          fontSize: 16,
                          decoration: TextDecoration.lineThrough,
                          color: ElegantLightTheme.textTertiary,
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
                color: ElegantLightTheme.textSecondary,
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
          ElegantContainer(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
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
                    color: ElegantLightTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 20),
                _buildInfoRow(context, 'Tipo', product.type.name.toUpperCase(), Icons.category),
                _buildInfoRow(context, 'Categoría', product.category?.name ?? 'N/A', Icons.folder),
                _buildInfoRow(context, 'Unidad', product.unit ?? 'pcs', Icons.straighten),
                _buildInfoRow(context, 'Creado por', product.createdBy?.fullName ?? 'N/A', Icons.person),
              ],
            ),
          ),

          // Información de stock
          ElegantContainer(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
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
                    color: ElegantLightTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 20),
                _buildInfoRow(
                  context,
                  'Stock Actual',
                  '${AppFormatters.formatStock(product.stock)} ${product.unit ?? "pcs"}',
                  Icons.inventory,
                  valueColor: product.isLowStock ? Colors.orange : Colors.green,
                ),
                _buildInfoRow(
                  context,
                  'Stock Mínimo',
                  '${AppFormatters.formatStock(product.minStock)} ${product.unit ?? "pcs"}',
                  Icons.warning_amber,
                ),
                _buildInfoRow(context, 'Estado Stock', controller.getStockStatusText(), Icons.assessment),
                if (product.isLowStock)
                  _buildInfoRow(
                    context,
                    'Alerta',
                    'Stock por debajo del mínimo',
                    Icons.error,
                    valueColor: Colors.orange,
                  ),
              ],
            ),
          ),

          // Información de facturación electrónica
          ElegantContainer(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Facturación Electrónica',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(
                      context,
                      mobile: 18,
                      tablet: 20,
                      desktop: 22,
                    ),
                    fontWeight: FontWeight.bold,
                    color: ElegantLightTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 20),
                _buildInfoRow(
                  context,
                  'Categoría de Impuesto',
                  product.taxCategory.displayName,
                  Icons.receipt_long,
                ),
                _buildInfoRow(
                  context,
                  'Tasa de Impuesto',
                  '${AppFormatters.formatNumber(product.taxRate)}%',
                  Icons.percent,
                ),
                _buildInfoRow(
                  context,
                  'Está Gravado',
                  product.isTaxable ? 'Sí' : 'No',
                  Icons.check_circle,
                  valueColor: product.isTaxable ? Colors.green : Colors.grey,
                ),
                if (product.taxDescription != null)
                  _buildInfoRow(
                    context,
                    'Descripción',
                    product.taxDescription!,
                    Icons.description,
                  ),
                if (product.hasRetention) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  if (product.retentionCategory != null)
                    _buildInfoRow(
                      context,
                      'Categoría de Retención',
                      product.retentionCategory!.displayName,
                      Icons.money_off,
                    ),
                  if (product.retentionRate != null)
                    _buildInfoRow(
                      context,
                      'Tasa de Retención',
                      '${AppFormatters.formatNumber(product.retentionRate!)}%',
                      Icons.trending_down,
                    ),
                  _buildInfoRow(
                    context,
                    'Aplica Retención',
                    'Sí',
                    Icons.verified,
                    valueColor: Colors.blue,
                  ),
                ],
              ],
            ),
          ),

          // Dimensiones y peso
          if (product.weight != null ||
              product.length != null ||
              product.width != null ||
              product.height != null)
            ElegantContainer(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
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
                      color: ElegantLightTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (product.weight != null)
                    _buildInfoRow(
                      context,
                      'Peso',
                      '${AppFormatters.formatNumber(product.weight!)} kg',
                      Icons.scale,
                    ),
                  if (product.length != null)
                    _buildInfoRow(
                      context,
                      'Largo',
                      '${AppFormatters.formatNumber(product.length!)} cm',
                      Icons.height,
                    ),
                  if (product.width != null)
                    _buildInfoRow(
                      context,
                      'Ancho',
                      '${AppFormatters.formatNumber(product.width!)} cm',
                      Icons.width_normal,
                    ),
                  if (product.height != null)
                    _buildInfoRow(
                      context,
                      'Alto',
                      '${AppFormatters.formatNumber(product.height!)} cm',
                      Icons.height,
                    ),
                ],
              ),
            ),

          // Fechas
          ElegantContainer(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Información de Registro',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(
                      context,
                      mobile: 18,
                      tablet: 20,
                      desktop: 22,
                    ),
                    fontWeight: FontWeight.bold,
                    color: ElegantLightTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 20),
                _buildInfoRow(context, 'Creado', _formatDate(product.createdAt), Icons.calendar_today),
                _buildInfoRow(context, 'Actualizado', _formatDate(product.updatedAt), Icons.update),
              ],
            ),
          ),
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
    return ElegantContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
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
                  color: ElegantLightTheme.primaryBlue,
                ),
              ),
              const Spacer(),
              Text(
                AppFormatters.formatPrice(productPrice.finalAmount),
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
                  'Precio original: ${AppFormatters.formatPrice(productPrice.amount)}',
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
                    '-${AppFormatters.formatNumber(productPrice.discountPercentage)}%',
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
              'Cantidad mínima: ${AppFormatters.formatNumber(productPrice.minQuantity)}',
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
      if (priceType is PriceType) {
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
            color: ElegantLightTheme.primaryBlue,
          ),
        ),
        const SizedBox(height: 16),
        ElegantContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.history, size: 48, color: ElegantLightTheme.textTertiary),
              const SizedBox(height: 16),
              Text(
                'Historial de Movimientos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Funcionalidad pendiente de implementar',
                style: TextStyle(color: ElegantLightTheme.textTertiary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: ElegantLightTheme.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: ElegantLightTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? ElegantLightTheme.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPricesState(BuildContext context) {
    return ElegantContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.price_change_outlined,
            size: 48,
            color: ElegantLightTheme.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin precios configurados',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ElegantLightTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Este producto no tiene precios configurados',
            style: TextStyle(color: ElegantLightTheme.textTertiary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElegantButton(
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
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ElegantLightTheme.primaryBlue, width: 2),
              color: Colors.white,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: controller.goToEditProduct,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit, color: ElegantLightTheme.primaryBlue, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Editar',
                      style: TextStyle(
                        color: ElegantLightTheme.primaryBlue,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElegantButton(
            text: 'Gestionar Stock',
            icon: Icons.inventory,
            gradient: ElegantLightTheme.primaryGradient,
            onPressed: controller.showStockDialog,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Obx(
            () => ElegantButton(
              text: controller.isDeleting ? 'Eliminando...' : 'Eliminar',
              icon: Icons.delete,
              gradient: ElegantLightTheme.errorGradient,
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
        ElegantButton(
          text: 'Editar Producto',
          icon: Icons.edit,
          gradient: ElegantLightTheme.primaryGradient,
          onPressed: controller.goToEditProduct,
          width: double.infinity,
        ),

        const SizedBox(height: 12),

        ElegantButton(
          text: 'Gestionar Stock',
          icon: Icons.inventory,
          gradient: ElegantLightTheme.infoGradient,
          onPressed: controller.showStockDialog,
          width: double.infinity,
        ),

        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ElegantLightTheme.primaryBlue, width: 2),
            color: Colors.white,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: controller.printLabel,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.print, color: ElegantLightTheme.primaryBlue, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Imprimir Etiqueta',
                    style: TextStyle(
                      color: ElegantLightTheme.primaryBlue,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        const Divider(),

        const SizedBox(height: 12),

        ElegantButton(
          text: 'Actualizar',
          icon: Icons.refresh,
          gradient: ElegantLightTheme.successGradient,
          onPressed: controller.refreshData,
          width: double.infinity,
        ),

        const SizedBox(height: 12),

        Obx(
          () => ElegantButton(
            text: controller.isDeleting ? 'Eliminando...' : 'Eliminar',
            icon: Icons.delete,
            gradient: ElegantLightTheme.errorGradient,
            onPressed: controller.isDeleting ? null : controller.confirmDelete,
            isLoading: controller.isDeleting,
            width: double.infinity,
          ),
        ),

        const Spacer(),

        // Información del producto
        Obx(() {
          if (!controller.hasProduct) return const SizedBox.shrink();

          final product = controller.product!;
          return ElegantContainer(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Información Rápida',
                  style: TextStyle(
                    fontSize: 12,
                    color: ElegantLightTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Stock: ${AppFormatters.formatStock(product.stock)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Categoría: ${product.category?.name ?? "N/A"}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Última actualización:',
                  style: TextStyle(fontSize: 12, color: ElegantLightTheme.textSecondary),
                ),
                Text(
                  _formatDate(product.updatedAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: ElegantLightTheme.textPrimary,
                  ),
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
          Icon(Icons.error_outline, size: 100, color: ElegantLightTheme.textTertiary),
          SizedBox(height: context.verticalSpacing),
          Text(
            'Producto no encontrado',
            style: TextStyle(
              fontSize: 18,
              color: ElegantLightTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: context.verticalSpacing / 2),
          Text(
            'El producto que buscas no existe o ha sido eliminado',
            style: TextStyle(color: ElegantLightTheme.textTertiary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.verticalSpacing * 2),
          ElegantButton(
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
      return Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
        child: FloatingActionButton(
          onPressed: controller.goToEditProduct,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.edit, color: Colors.white),
        ),
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
