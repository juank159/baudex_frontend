// lib/features/products/presentation/widgets/product_filter_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../controllers/products_controller.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_price.dart';

class ProductFilterWidget extends GetView<ProductsController> {
  const ProductFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros',
            style: TextStyle(
              fontSize: Responsive.getFontSize(context, mobile: 18, tablet: 20),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Filtro por estado
          _buildFilterSection(
            context,
            'Estado del Producto',
            _buildStatusFilter(context),
          ),

          const SizedBox(height: 16),

          // Filtro por stock
          _buildFilterSection(
            context,
            'Estado del Stock',
            _buildStockFilter(context),
          ),

          const SizedBox(height: 16),

          // Filtro por categoría
          _buildFilterSection(
            context,
            'Categoría',
            _buildCategoryFilter(context),
          ),

          const SizedBox(height: 16),

          // Filtro por tipo
          _buildFilterSection(
            context,
            'Tipo de Producto',
            _buildTypeFilter(context),
          ),

          const SizedBox(height: 16),

          // Filtro por precio
          _buildFilterSection(
            context,
            'Rango de Precio',
            _buildPriceFilter(context),
          ),

          const SizedBox(height: 24),

          // Acciones
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Limpiar Filtros',
                  type: ButtonType.outline,
                  onPressed: controller.clearFilters,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Aplicar',
                  onPressed: () => controller.loadProducts(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
    BuildContext context,
    String title,
    Widget content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildStatusFilter(BuildContext context) {
    return Obx(
      () => Column(
        children: [
          RadioListTile<ProductStatus?>(
            title: const Text('Todos'),
            value: null,
            groupValue: controller.currentStatus,
            onChanged: (value) => controller.applyStatusFilter(value),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<ProductStatus>(
            title: const Text('Productos Activos'),
            subtitle: Text('${controller.stats?.active ?? 0} productos'),
            value: ProductStatus.active,
            groupValue: controller.currentStatus,
            onChanged: (value) => controller.applyStatusFilter(value),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<ProductStatus>(
            title: const Text('Productos Inactivos'),
            subtitle: Text('${controller.stats?.inactive ?? 0} productos'),
            value: ProductStatus.inactive,
            groupValue: controller.currentStatus,
            onChanged: (value) => controller.applyStatusFilter(value),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildStockFilter(BuildContext context) {
    return Obx(
      () => Column(
        children: [
          CheckboxListTile(
            title: const Text('Solo productos en stock'),
            subtitle: Text('${controller.stats?.inStock ?? 0} productos'),
            value: controller.inStock ?? false,
            onChanged: (value) => controller.applyStockFilter(inStock: value),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          CheckboxListTile(
            title: const Text('Solo productos con stock bajo'),
            subtitle: Text('${controller.stats?.lowStock ?? 0} productos'),
            value: controller.lowStock ?? false,
            onChanged: (value) => controller.applyStockFilter(lowStock: value),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context) {
    // TODO: Implementar cuando tengas las categorías disponibles
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.category, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            'Selector de categorías (Pendiente)',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const Spacer(),
          if (controller.selectedCategoryId != null)
            TextButton(
              onPressed: () => controller.applyCategoryFilter(null),
              child: const Text('Limpiar'),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeFilter(BuildContext context) {
    return Obx(
      () => Column(
        children: [
          RadioListTile<ProductType?>(
            title: const Text('Todos los tipos'),
            value: null,
            groupValue: controller.currentType,
            onChanged: (value) => controller.applyTypeFilter(value),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<ProductType>(
            title: const Text('Productos'),
            value: ProductType.product,
            groupValue: controller.currentType,
            onChanged: (value) => controller.applyTypeFilter(value),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<ProductType>(
            title: const Text('Servicios'),
            value: ProductType.service,
            groupValue: controller.currentType,
            onChanged: (value) => controller.applyTypeFilter(value),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceFilter(BuildContext context) {
    return Obx(() {
      final minPrice = controller.minPrice ?? 0.0;
      final maxPrice = controller.maxPrice ?? 1000.0;

      return Column(
        children: [
          // Selector de tipo de precio
          DropdownButtonFormField<PriceType>(
            value: controller.priceType,
            decoration: const InputDecoration(
              labelText: 'Tipo de Precio',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items:
                PriceType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getPriceTypeName(type)),
                  );
                }).toList(),
            onChanged: (value) {
              if (value != null) {
                controller.applyPriceFilter(minPrice, maxPrice, value);
              }
            },
          ),
          const SizedBox(height: 12),

          // Campos de precio mínimo y máximo
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: minPrice.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Precio mín.',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final price = double.tryParse(value) ?? 0.0;
                    controller.applyPriceFilter(
                      price,
                      maxPrice,
                      controller.priceType,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: maxPrice.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Precio máx.',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final price = double.tryParse(value) ?? 1000.0;
                    controller.applyPriceFilter(
                      minPrice,
                      price,
                      controller.priceType,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  String _getPriceTypeName(PriceType type) {
    switch (type) {
      case PriceType.price1:
        return 'Precio al Público';
      case PriceType.price2:
        return 'Precio Mayorista';
      case PriceType.price3:
        return 'Precio Distribuidor';
      case PriceType.special:
        return 'Precio Especial';
      case PriceType.cost:
        return 'Precio de Costo';
      default:
        return type.toString();
    }
  }
}
