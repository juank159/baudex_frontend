// lib/features/inventory/presentation/widgets/transfer_form/transfer_basic_form.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../../app/config/themes/app_dimensions.dart';
import '../../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../../app/core/utils/formatters.dart';
import '../../../../products/domain/entities/product.dart';
import '../../controllers/create_transfer_controller.dart';

class TransferBasicForm extends StatefulWidget {
  const TransferBasicForm({super.key});

  @override
  State<TransferBasicForm> createState() => _TransferBasicFormState();
}

class _TransferBasicFormState extends State<TransferBasicForm> {
  CreateTransferController get controller => Get.find<CreateTransferController>();
  
  // Map to store TextEditingController for each product quantity
  final Map<String, TextEditingController> _quantityControllers = {};

  @override
  void dispose() {
    // Dispose all quantity controllers
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    _quantityControllers.clear();
    super.dispose();
  }

  void _cleanupRemovedControllers() {
    // Remove controllers for products that are no longer in the transfer
    final currentProductIds = controller.transferItems.map((item) => item.productId).toSet();
    final controllersToRemove = <String>[];
    
    for (final productId in _quantityControllers.keys) {
      if (!currentProductIds.contains(productId)) {
        _quantityControllers[productId]?.dispose();
        controllersToRemove.add(productId);
      }
    }
    
    for (final productId in controllersToRemove) {
      _quantityControllers.remove(productId);
    }
  }

  TextEditingController _getQuantityController(String productId, int quantity) {
    if (!_quantityControllers.containsKey(productId)) {
      _quantityControllers[productId] = TextEditingController(text: quantity.toString());
    }
    // Update the controller text if quantity changed
    if (_quantityControllers[productId]!.text != quantity.toString()) {
      _quantityControllers[productId]!.text = quantity.toString();
    }
    return _quantityControllers[productId]!;
  }

  void _updateQuantityFromText(String value, UITransferItem item) {
    final newQuantity = int.tryParse(value) ?? item.quantity;
    
    if (newQuantity > 0 && newQuantity <= item.availableStock) {
      // Actualizar el valor en el controlador
      controller.updateProductQuantity(item.productId, newQuantity);
      print('✅ Cantidad actualizada: ${item.product.name} -> $newQuantity');
    } else {
      // Reset to current quantity if invalid
      final quantityController = _quantityControllers[item.productId];
      if (quantityController != null) {
        quantityController.text = item.quantity.toString();
      }
      print('❌ Cantidad inválida: $value, mantener: ${item.quantity}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductSelection(),
        const SizedBox(height: AppDimensions.paddingLarge),
        _buildTransferItemsList(),
      ],
    );
  }

  Widget _buildProductSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Buscar Productos'),
        const SizedBox(height: AppDimensions.paddingSmall),
        
        // Product search field
        Container(
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(8),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: Stack(
            children: [
              Obx(() => TextFormField(
                controller: controller.productController,
                decoration: InputDecoration(
                  hintText: (controller.selectedFromWarehouseId.value.isEmpty || controller.selectedToWarehouseId.value.isEmpty)
                      ? 'Selecciona ambos almacenes primero' 
                      : 'Buscar productos...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: ElegantLightTheme.textSecondary,
                  ),
                  suffixIcon: controller.productController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade600),
                          onPressed: () {
                            controller.productController.clear();
                            controller.searchResults.clear();
                          },
                          tooltip: 'Limpiar búsqueda',
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.all(16),
                ),
                onChanged: (value) {
                  // Buscar productos si hay texto
                  if (value.trim().isNotEmpty) {
                    controller.searchProducts(value);
                  } else {
                    controller.searchResults.clear();
                  }
                },
                enabled: controller.selectedFromWarehouseId.value.isNotEmpty && controller.selectedToWarehouseId.value.isNotEmpty,
              )),
              
              // Loading indicator
              Obx(() => controller.isLoading.value
                  ? Positioned(
                      right: 50,
                      top: 12,
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(ElegantLightTheme.primaryBlue),
                        ),
                      ),
                    )
                  : const SizedBox.shrink()),
            ],
          ),
        ),
        
        
        // Search results
        Obx(() => _buildSearchResults()),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (controller.searchResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: controller.searchResults.length,
        itemBuilder: (context, index) {
          final product = controller.searchResults[index];
          return _buildProductItem(product);
        },
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    final availableStock = controller.getProductStock(product.id);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.inventory_2,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              product.name,
              style: Get.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: ElegantLightTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              children: [
                Icon(
                  Icons.warehouse,
                  size: 14,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Stock: ${AppFormatters.formatNumber(availableStock)} unidades',
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            onTap: () {
              // Agregar directamente con cantidad 1
              controller.addProductToTransfer(product, 1);
              setState(() {
                controller.productController.clear(); // Limpiar búsqueda
                controller.searchResults.clear();
              });
            },
          ),
          
          // Indicador de disponibilidad - punto verde en esquina superior derecha
          if (availableStock > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade600.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          
          // Indicador de sin stock - punto rojo en esquina superior derecha
          if (availableStock <= 0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade600.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }




  Widget _buildTransferItemsList() {
    return Obx(() {
      // Clean up controllers for removed products
      _cleanupRemovedControllers();
      
      if (controller.transferItems.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey.shade100, Colors.grey.shade200.withValues(alpha: 0.5)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'Sin productos agregados',
                  style: Get.textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Busca y selecciona productos para agregar',
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Productos Seleccionados (${controller.transferItems.length})'),
          const SizedBox(height: AppDimensions.paddingSmall),
          
          // Lista de productos
          ...controller.transferItems.map((item) => _buildTransferItem(item)).toList(),
          
        ],
      );
    });
  }

  Widget _buildTransferItem(UITransferItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(8),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Producto info
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.inventory_2,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            
            // Detalles del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: Get.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ElegantLightTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Disponible: ${AppFormatters.formatNumber(item.availableStock)} unidades',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: ElegantLightTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Contador de cantidad profesional
            _buildQuantityCounter(item),
            
            const SizedBox(width: 8),
            
            // Botón eliminar
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => controller.removeProductFromTransfer(item.productId),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red.shade600,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityCounter(UITransferItem item) {
    final quantityController = _getQuantityController(item.productId, item.quantity);
    
    return Container(
      width: 120,
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: Row(
        children: [
          // Botón decrementar
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: item.quantity > 1 ? () {
                controller.updateProductQuantity(item.productId, item.quantity - 1);
              } : null,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
              child: Container(
                width: 28,
                height: 34,
                decoration: BoxDecoration(
                  color: item.quantity > 1 ? Colors.blue.shade600 : Colors.grey.shade300,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomLeft: Radius.circular(4),
                  ),
                ),
                child: const Icon(
                  Icons.remove,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          // Input de cantidad - editable sin contenedor feo
          Expanded(
            child: TextFormField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: Get.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: ElegantLightTheme.textPrimary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                filled: false,
                hintText: null,
              ),
              onFieldSubmitted: (value) {
                _updateQuantityFromText(value, item);
              },
              onEditingComplete: () {
                _updateQuantityFromText(quantityController.text, item);
              },
              onTapOutside: (event) {
                _updateQuantityFromText(quantityController.text, item);
              },
            ),
          ),
          
          // Botón incrementar
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: item.quantity < item.availableStock ? () {
                controller.updateProductQuantity(item.productId, item.quantity + 1);
              } : null,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
              child: Container(
                width: 28,
                height: 34,
                decoration: BoxDecoration(
                  color: item.quantity < item.availableStock ? Colors.blue.shade600 : Colors.grey.shade300,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: const Icon(
                  Icons.add,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Get.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: ElegantLightTheme.textPrimary,
      ),
    );
  }

}