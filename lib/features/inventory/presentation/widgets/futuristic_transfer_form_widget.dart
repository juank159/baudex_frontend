// lib/features/inventory/presentation/widgets/futuristic_transfer_form_widget.dart
import 'package:baudex_desktop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/theme/futuristic_notifications.dart';
import '../../domain/entities/warehouse.dart';
import '../../../products/domain/entities/product.dart';
import '../controllers/inventory_transfers_controller.dart';
import 'futuristic_warehouse_selector_widget.dart';
import 'futuristic_product_search_widget.dart';

class FuturisticTransferFormWidget
    extends GetView<InventoryTransfersController> {
  const FuturisticTransferFormWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 1200;

        // Responsive values
        final headerIconSize =
            isMobile
                ? 20.0
                : isTablet
                ? 22.0
                : 24.0;
        final headerIconPadding =
            isMobile
                ? 10.0
                : isTablet
                ? 11.0
                : 12.0;
        final headerTitleFontSize =
            isMobile
                ? 16.0
                : isTablet
                ? 18.0
                : 20.0;
        final headerSpacing =
            isMobile
                ? 12.0
                : isTablet
                ? 14.0
                : 16.0;
        final sectionSpacing =
            isMobile
                ? 16.0
                : isTablet
                ? 20.0
                : 24.0;

        return FuturisticContainer(
          hasGlow: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(headerIconPadding),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: ElegantLightTheme.glowShadow,
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: headerIconSize,
                    ),
                  ),
                  SizedBox(width: headerSpacing),
                  Expanded(
                    child: Text(
                      'Nueva Transferencia',
                      style: TextStyle(
                        color: ElegantLightTheme.textPrimary,
                        fontSize: headerTitleFontSize,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: controller.toggleForm,
                    icon: const Icon(Icons.close),
                    iconSize: isMobile ? 18.0 : 20.0,
                  ),
                ],
              ),
              SizedBox(height: sectionSpacing),

              // Warehouse selection row with futuristic styling
              _buildWarehouseSection(isMobile, isTablet),

              SizedBox(height: sectionSpacing - 4),

              // Product and quantity section
              _buildProductSearchSection(isMobile, isTablet),

              SizedBox(height: sectionSpacing - 4),

              // Added products list
              _buildAddedProductsList(isMobile, isTablet),

              SizedBox(height: sectionSpacing - 4),

              // Notes field
              _buildNotesSection(isMobile, isTablet),

              SizedBox(height: sectionSpacing),

              // Action buttons
              _buildActionButtons(isMobile, isTablet),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWarehouseSection(bool isMobile, bool isTablet) {
    final sectionTitleFontSize =
        isMobile
            ? 14.0
            : isTablet
            ? 15.0
            : 16.0;
    final sectionSpacing =
        isMobile
            ? 12.0
            : isTablet
            ? 14.0
            : 16.0;

    return FuturisticContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Almacenes',
            style: TextStyle(
              color: ElegantLightTheme.textPrimary,
              fontSize: sectionTitleFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: sectionSpacing),
          isMobile
              ? Column(
                children: [
                  Obx(
                    () => FuturisticWarehouseSelectorWidget(
                      label: 'Almacén de Origen',
                      selectedWarehouse: _getWarehouseById(
                        controller.selectedFromWarehouseId.value,
                      ),
                      availableWarehouses: controller.warehouses,
                      onWarehouseSelected: (warehouse) {
                        _handleWarehouseChange(
                          warehouse,
                          isOriginWarehouse: true,
                        );
                      },
                      isRequired: true,
                      icon: Icons.warehouse,
                      iconColor: ElegantLightTheme.infoGradient.colors.first,
                    ),
                  ),
                  SizedBox(height: sectionSpacing),
                  Container(
                    width: isMobile ? 50 : 60,
                    height: isMobile ? 50 : 60,
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(isMobile ? 25 : 30),
                      boxShadow: ElegantLightTheme.glowShadow,
                    ),
                    child: Icon(
                      Icons.arrow_downward,
                      color: Colors.white,
                      size: isMobile ? 20 : 24,
                    ),
                  ),
                  SizedBox(height: sectionSpacing),
                  Obx(
                    () => FuturisticWarehouseSelectorWidget(
                      label: 'Almacén de Destino',
                      selectedWarehouse: _getWarehouseById(
                        controller.selectedToWarehouseId.value,
                      ),
                      availableWarehouses:
                          _getAvailableWarehousesForDestination(),
                      onWarehouseSelected: (warehouse) {
                        _handleWarehouseChange(
                          warehouse,
                          isOriginWarehouse: false,
                        );
                      },
                      isRequired: true,
                      icon: Icons.warehouse,
                      iconColor: ElegantLightTheme.successGradient.colors.first,
                    ),
                  ),
                ],
              )
              : Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => FuturisticWarehouseSelectorWidget(
                        label: 'Almacén de Origen',
                        selectedWarehouse: _getWarehouseById(
                          controller.selectedFromWarehouseId.value,
                        ),
                        availableWarehouses: controller.warehouses,
                        onWarehouseSelected: (warehouse) {
                          _handleWarehouseChange(
                            warehouse,
                            isOriginWarehouse: true,
                          );
                        },
                        isRequired: true,
                        icon: Icons.warehouse,
                        iconColor: ElegantLightTheme.infoGradient.colors.first,
                      ),
                    ),
                  ),
                  SizedBox(width: sectionSpacing),
                  Container(
                    padding: EdgeInsets.all(isTablet ? 11.0 : 12.0),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: ElegantLightTheme.glowShadow,
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: isTablet ? 18 : 20,
                    ),
                  ),
                  SizedBox(width: sectionSpacing),
                  Expanded(
                    child: Obx(
                      () => FuturisticWarehouseSelectorWidget(
                        label: 'Almacén de Destino',
                        selectedWarehouse: _getWarehouseById(
                          controller.selectedToWarehouseId.value,
                        ),
                        availableWarehouses:
                            _getAvailableWarehousesForDestination(),
                        onWarehouseSelected: (warehouse) {
                          _handleWarehouseChange(
                            warehouse,
                            isOriginWarehouse: false,
                          );
                        },
                        isRequired: true,
                        icon: Icons.warehouse,
                        iconColor:
                            ElegantLightTheme.successGradient.colors.first,
                      ),
                    ),
                  ),
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildProductSearchSection(bool isMobile, bool isTablet) {
    final sectionTitleFontSize =
        isMobile
            ? 14.0
            : isTablet
            ? 15.0
            : 16.0;
    final sectionSpacing =
        isMobile
            ? 12.0
            : isTablet
            ? 14.0
            : 16.0;

    return FuturisticContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.add_shopping_cart,
                color: ElegantLightTheme.primaryBlue,
                size: isMobile ? 18 : 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Buscar y Agregar Productos',
                style: TextStyle(
                  color: ElegantLightTheme.textPrimary,
                  fontSize: sectionTitleFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: sectionSpacing),
          _buildProductSelector(isMobile, isTablet),
          SizedBox(height: isMobile ? 8 : 12),
          Obx(() {
            final originWarehouse = _getWarehouseById(
              controller.selectedFromWarehouseId.value,
            );

            return Container(
              padding: EdgeInsets.all(isMobile ? 8 : 12),
              decoration: BoxDecoration(
                color: ElegantLightTheme.infoGradient.colors.first.withOpacity(
                  0.1,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ElegantLightTheme.infoGradient.colors.first
                      .withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: ElegantLightTheme.infoGradient.colors.first,
                    size: isMobile ? 14 : 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      originWarehouse != null
                          ? 'Las cantidades mostradas corresponden SOLO al almacén "${originWarehouse.name}". Los productos se agregan automáticamente con cantidad 1.'
                          : 'Los productos se agregan automáticamente con cantidad 1. Puedes editar la cantidad después.',
                      style: TextStyle(
                        color: ElegantLightTheme.infoGradient.colors.first,
                        fontSize: isMobile ? 11 : 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProductSelector(bool isMobile, bool isTablet) {
    final labelFontSize =
        isMobile
            ? 12.0
            : isTablet
            ? 13.0
            : 14.0;
    final fieldSpacing = isMobile ? 6.0 : 8.0;

    return Obx(() {
      final hasOriginWarehouse =
          controller.selectedFromWarehouseId.value.isNotEmpty;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Producto *',
            style: TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: labelFontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: fieldSpacing),
          if (!hasOriginWarehouse)
            Container(
              padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
              decoration: BoxDecoration(
                color: ElegantLightTheme.warningGradient.colors.first
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ElegantLightTheme.warningGradient.colors.first
                      .withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_outlined,
                    color: ElegantLightTheme.warningGradient.colors.first,
                    size: isMobile ? 16 : 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Primero debes seleccionar el almacén de origen para ver las cantidades disponibles',
                      style: TextStyle(
                        color: ElegantLightTheme.warningGradient.colors.first,
                        fontSize: isMobile ? 12 : 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            FuturisticProductSearchWidget(
              hintText: 'Buscar producto...',
              searchFunction: _searchProducts,
              getStockFunction: _getProductStock,
              onProductSelected: (product) {
                controller.selectedProductId.value = product.id;
                controller.productController.text = product.name;

                // Auto-agregar el producto con cantidad 1
                controller.quantityController.text = '1';
                controller.addProductToTransfer();

                // Limpiar el formulario para agregar otro producto
                controller.productController.clear();
                controller.quantityController.clear();
                controller.selectedProductId.value = '';
              },
            ),
        ],
      );
    });
  }

  Widget _buildNotesSection(bool isMobile, bool isTablet) {
    final sectionTitleFontSize =
        isMobile
            ? 14.0
            : isTablet
            ? 15.0
            : 16.0;
    final sectionSpacing =
        isMobile
            ? 12.0
            : isTablet
            ? 14.0
            : 16.0;
    final iconSize = isMobile ? 14.0 : 16.0;

    return FuturisticContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notas (Opcional)',
            style: TextStyle(
              color: ElegantLightTheme.textPrimary,
              fontSize: sectionTitleFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: sectionSpacing),
          Container(
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.glassGradient,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ElegantLightTheme.textSecondary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: TextFormField(
              controller: controller.notesController,
              maxLines: 3,
              style: const TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Agregar notas sobre la transferencia...',
                hintStyle: TextStyle(
                  color: ElegantLightTheme.textSecondary.withOpacity(0.6),
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.infoGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.notes, color: Colors.white, size: iconSize),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isMobile, bool isTablet) {
    final buttonSpacing =
        isMobile
            ? 10.0
            : isTablet
            ? 12.0
            : 16.0;
    final buttonHeight =
        isMobile
            ? 44.0
            : isTablet
            ? 46.0
            : 48.0;

    return isMobile
        ? Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: buttonHeight,
              child: FuturisticButton(
                text: 'Cancelar',
                icon: Icons.close,
                gradient: ElegantLightTheme.errorGradient,
                onPressed: controller.toggleForm,
              ),
            ),
            SizedBox(height: buttonSpacing),
            SizedBox(
              width: double.infinity,
              height: buttonHeight,
              child: Obx(
                () => FuturisticButton(
                  text:
                      controller.isCreating.value
                          ? 'Creando...'
                          : 'Crear Transferencia',
                  icon: controller.isCreating.value ? null : Icons.send,
                  isLoading: controller.isCreating.value,
                  onPressed:
                      controller.isCreating.value ? null : _createTransfer,
                ),
              ),
            ),
          ],
        )
        : Row(
          children: [
            Expanded(
              child: SizedBox(
                height: buttonHeight,
                child: FuturisticButton(
                  text: 'Cancelar',
                  icon: Icons.close,
                  gradient: ElegantLightTheme.errorGradient,
                  onPressed: controller.toggleForm,
                ),
              ),
            ),
            SizedBox(width: buttonSpacing),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: buttonHeight,
                child: Obx(
                  () => FuturisticButton(
                    text:
                        controller.isCreating.value
                            ? 'Creando...'
                            : 'Crear Transferencia',
                    icon: controller.isCreating.value ? null : Icons.send,
                    isLoading: controller.isCreating.value,
                    onPressed:
                        controller.isCreating.value ? null : _createTransfer,
                  ),
                ),
              ),
            ),
          ],
        );
  }

  void _createTransfer() {
    FuturisticNotifications.showProcessing(
      'Creando Transferencia',
      'Procesando la transferencia entre almacenes...',
    );
    controller.createTransfer();
  }

  bool _validateForm() {
    if (controller.selectedFromWarehouseId.value.isEmpty) {
      FuturisticNotifications.showError(
        'Almacén Requerido',
        'Debe seleccionar el almacén de origen',
      );
      return false;
    }

    if (controller.selectedToWarehouseId.value.isEmpty) {
      FuturisticNotifications.showError(
        'Almacén Requerido',
        'Debe seleccionar el almacén de destino',
      );
      return false;
    }

    if (controller.selectedFromWarehouseId.value ==
        controller.selectedToWarehouseId.value) {
      FuturisticNotifications.showError(
        'Almacenes Inválidos',
        'Los almacenes de origen y destino deben ser diferentes',
      );
      return false;
    }

    if (controller.selectedProductId.value.isEmpty) {
      FuturisticNotifications.showError(
        'Producto Requerido',
        'Debe seleccionar un producto para transferir',
      );
      return false;
    }

    final quantity = double.tryParse(controller.quantityController.text);
    if (quantity == null || quantity <= 0) {
      FuturisticNotifications.showError(
        'Cantidad Inválida',
        'La cantidad debe ser un número mayor a cero',
      );
      return false;
    }

    return true;
  }

  Warehouse? _getWarehouseById(String id) {
    if (id.isEmpty) return null;

    try {
      return controller.warehouses.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Warehouse> _getAvailableWarehousesForDestination() {
    // Filtrar el almacén de origen para que no aparezca en destino
    final originWarehouseId = controller.selectedFromWarehouseId.value;

    if (originWarehouseId.isEmpty) {
      return controller.warehouses.toList();
    }

    return controller.warehouses
        .where((warehouse) => warehouse.id != originWarehouseId)
        .toList();
  }

  Widget _buildAddedProductsList(bool isMobile, bool isTablet) {
    final sectionTitleFontSize =
        isMobile
            ? 14.0
            : isTablet
            ? 15.0
            : 16.0;
    final sectionSpacing =
        isMobile
            ? 12.0
            : isTablet
            ? 14.0
            : 16.0;

    return Obx(() {
      if (controller.transferItems.isEmpty) {
        return const SizedBox.shrink();
      }

      return FuturisticContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Productos a Transferir',
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: sectionTitleFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 6 : 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.successGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isMobile
                        ? '${controller.transferItems.length} prod.'
                        : '${controller.transferItems.length} productos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 10 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 6 : 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isMobile
                        ? '${controller.totalQuantityInTransfer} uds.'
                        : '${controller.totalQuantityInTransfer} unidades',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 10 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: sectionSpacing),
            ...controller.transferItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildProductItem(item, index, isMobile, isTablet);
            }),
          ],
        ),
      );
    });
  }

  Widget _buildProductItem(
    TransferItem item,
    int index,
    bool isMobile,
    bool isTablet,
  ) {
    final itemPadding = isMobile ? 8.0 : 12.0;
    final iconSize = isMobile ? 16.0 : 18.0;
    final titleFontSize = isMobile ? 13.0 : 14.0;
    final quantityFontSize = isMobile ? 12.0 : 13.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(itemPadding),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ElegantLightTheme.textSecondary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Product icon
          Container(
            padding: EdgeInsets.all(isMobile ? 4 : 6),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.infoGradient,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.inventory_2,
              color: Colors.white,
              size: isMobile ? 14 : 16,
            ),
          ),
          SizedBox(width: isMobile ? 8 : 12),

          // Product name - EXPANDIDO para usar más espacio
          Expanded(
            child: FutureBuilder<String>(
              future: _getProductName(item.productId),
              builder: (context, snapshot) {
                return Text(
                  snapshot.data ?? 'Producto ${index + 1}',
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: isMobile ? 13.0 : titleFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ),

          SizedBox(width: isMobile ? 8 : 12),

          // 📦 MOSTRAR STOCK DISPONIBLE DEL ALMACÉN DE ORIGEN (Solo en tablet/desktop)
          if (!isMobile)
            FutureBuilder<int>(
              future: _getProductStock(item.productId),
              builder: (context, stockSnapshot) {
                final availableStock = stockSnapshot.data ?? 0;
                final hasStock = availableStock > 0;
                final isWarning = availableStock < item.quantity;
                final isError = availableStock == 0;

                Color backgroundColor;
                Color borderColor;
                Color textColor;
                String displayText;

                if (isError) {
                  backgroundColor = Colors.red.withOpacity(0.1);
                  borderColor = Colors.red.withOpacity(0.3);
                  textColor = Colors.red.shade700;
                  displayText = 'Sin stock';
                } else if (isWarning) {
                  backgroundColor = Colors.orange.withOpacity(0.1);
                  borderColor = Colors.orange.withOpacity(0.3);
                  textColor = Colors.orange.shade700;
                  displayText = '$availableStock disp.';
                } else {
                  backgroundColor = Colors.green.withOpacity(0.1);
                  borderColor = Colors.green.withOpacity(0.3);
                  textColor = Colors.green.shade700;
                  displayText = '$availableStock disp.';
                }

                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isError)
                        Icon(
                          Icons.warning_amber_rounded,
                          color: textColor,
                          size: 12,
                        ),
                      if (isError) SizedBox(width: 3),
                      Text(
                        displayText,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          if (!isMobile) SizedBox(width: 12),

          // Compact quantity editor
          Container(
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.glassGradient,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Decrease button
                GestureDetector(
                  onTap: () => _decreaseQuantity(item, index),
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 3 : 5),
                    child: Icon(
                      Icons.remove,
                      color: ElegantLightTheme.textSecondary,
                      size: isMobile ? 14 : 16,
                    ),
                  ),
                ),
                // Quantity display (tappable to edit)
                GestureDetector(
                  onTap: () => _editQuantityDialog(item, index),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 8 : 10,
                      vertical: isMobile ? 3 : 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.successGradient,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '${item.quantity}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 12 : quantityFontSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                // Increase button
                GestureDetector(
                  onTap: () => _increaseQuantity(item, index),
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 3 : 5),
                    child: Icon(
                      Icons.add,
                      color: ElegantLightTheme.primaryBlue,
                      size: isMobile ? 14 : 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: isMobile ? 8 : 10),

          // "unidades" label
          if (!isMobile)
            Text(
              'unidades',
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),

          // ESPACIADOR - Push el botón eliminar a la derecha
          if (!isMobile) const Spacer(),
          if (isMobile) SizedBox(width: 8),

          // Remove button - PEGADO en móvil, SEPARADO en desktop
          Container(
            margin: EdgeInsets.only(left: isMobile ? 0 : 16),
            child: IconButton(
              onPressed: () => controller.removeProductFromTransfer(index),
              icon: Icon(
                Icons.delete_outline,
                color: Colors.red.shade400,
                size: isMobile ? 18 : 20,
              ),
              tooltip: 'Eliminar producto',
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.all(isMobile ? 6 : 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Product>> _searchProducts(String query) async {
    try {
      // Use the real search function from the controller
      return await controller.searchProducts(query);
    } catch (e) {
      print('Error searching products in transfer form: $e');
      return [];
    }
  }

  Future<int> _getProductStock(String productId) async {
    try {
      // Only get stock if origin warehouse is selected
      if (controller.selectedFromWarehouseId.value.isEmpty) {
        print(
          '🚫 No origin warehouse selected, returning 0 stock for product $productId',
        );
        return 0;
      }

      final warehouseId = controller.selectedFromWarehouseId.value;
      final warehouse = _getWarehouseById(warehouseId);

      print('🔍 GETTING STOCK for product: $productId');
      print(
        '🏬 From warehouse: ${warehouse?.name ?? 'Unknown'} (ID: $warehouseId)',
      );

      final stock = await controller.getProductStock(productId, warehouseId);

      print(
        '📦 Stock result: $stock units for product $productId in warehouse ${warehouse?.name}',
      );

      return stock;
    } catch (e) {
      print('❌ Error getting product stock in transfer form: $e');
      return 0;
    }
  }

  Future<String> _getProductName(String productId) async {
    try {
      // Search for a single character to get all products, then filter by ID
      final products = await controller.searchProducts('');
      final product = products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Product not found'),
      );
      return product.name;
    } catch (e) {
      print('Error getting product name: $e');
      return 'Producto';
    }
  }

  // ==================== WAREHOUSE CHANGE MANAGEMENT ====================

  void _handleWarehouseChange(
    Warehouse warehouse, {
    required bool isOriginWarehouse,
  }) {
    // Verificar si hay productos en la lista
    if (controller.transferItems.isNotEmpty) {
      _showWarehouseChangeDialog(
        warehouse,
        isOriginWarehouse: isOriginWarehouse,
      );
    } else {
      // No hay productos, cambiar directamente
      _updateWarehouse(warehouse, isOriginWarehouse: isOriginWarehouse);
    }
  }

  void _showWarehouseChangeDialog(
    Warehouse warehouse, {
    required bool isOriginWarehouse,
  }) {
    final warehouseType = isOriginWarehouse ? 'origen' : 'destino';
    final currentWarehouse =
        isOriginWarehouse
            ? _getWarehouseById(controller.selectedFromWarehouseId.value)
            : _getWarehouseById(controller.selectedToWarehouseId.value);

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.warningGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Cambiar Almacén',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tienes ${controller.transferItems.length} productos en la lista de transferencia.',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cambio propuesto:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Almacén de $warehouseType:',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${currentWarehouse?.name ?? 'No seleccionado'} → ${warehouse.name}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '¿Qué deseas hacer?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _updateWarehouse(warehouse, isOriginWarehouse: isOriginWarehouse);
              controller.transferItems.clear();
              FuturisticNotifications.showInfo(
                'Lista Limpiada',
                'Los productos fueron eliminados debido al cambio de almacén',
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.orange.withOpacity(0.1),
            ),
            child: Text(
              'Cambiar y Limpiar Lista',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateWarehouse(
    Warehouse warehouse, {
    required bool isOriginWarehouse,
  }) {
    if (isOriginWarehouse) {
      controller.selectedFromWarehouseId.value = warehouse.id;
      controller.fromWarehouseController.text = warehouse.displayName;
    } else {
      controller.selectedToWarehouseId.value = warehouse.id;
      controller.toWarehouseController.text = warehouse.displayName;
    }
  }

  // ==================== QUANTITY MANAGEMENT ====================

  Future<void> _increaseQuantity(TransferItem item, int index) async {
    // Get available stock for this product in origin warehouse
    final availableStock = await _getProductStock(item.productId);

    if (item.quantity >= availableStock) {
      FuturisticNotifications.showError(
        'Stock Insuficiente',
        'No puedes transferir más de $availableStock unidades disponibles',
      );
      return;
    }

    controller.updateProductQuantity(index, item.quantity + 1);
  }

  void _decreaseQuantity(TransferItem item, int index) {
    if (item.quantity <= 1) {
      FuturisticNotifications.showWarning(
        'Cantidad Mínima',
        'La cantidad mínima es 1 unidad',
      );
      return;
    }

    controller.updateProductQuantity(index, item.quantity - 1);
  }

  Future<void> _editQuantityDialog(TransferItem item, int index) async {
    final availableStock = await _getProductStock(item.productId);
    final quantityController = TextEditingController(
      text: item.quantity.toString(),
    );

    Get.dialog(
      AlertDialog(
        title: const Text('Editar Cantidad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Stock disponible: $availableStock unidades'),
            const SizedBox(height: 16),
            TextFormField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nueva cantidad',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final newQuantity = int.tryParse(quantityController.text);
              if (newQuantity == null || newQuantity <= 0) {
                FuturisticNotifications.showError(
                  'Cantidad Inválida',
                  'Ingresa un número válido mayor a 0',
                );
                return;
              }

              if (newQuantity > availableStock) {
                FuturisticNotifications.showError(
                  'Stock Insuficiente',
                  'Solo hay $availableStock unidades disponibles',
                );
                return;
              }

              controller.updateProductQuantity(index, newQuantity);
              Get.back();
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }
}
