// lib/features/purchase_orders/presentation/screens/purchase_order_form_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/shared/widgets/app_scaffold.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../controllers/purchase_order_form_controller.dart';
import '../../domain/entities/purchase_order.dart';
import '../widgets/supplier_selector_widget.dart';
import '../widgets/product_selector_widget.dart';
import '../widgets/product_item_form_widget.dart';

class PurchaseOrderFormScreen extends GetView<PurchaseOrderFormController> {
  const PurchaseOrderFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => AppScaffold(
      includeDrawer: false, // Quitar drawer
      appBar: AppBarBuilder.buildGradient(
        title: controller.titleText,
        automaticallyImplyLeading: true, // Solo arrow back
        gradientColors: [
          ElegantLightTheme.primaryGradient.colors.first,
          ElegantLightTheme.primaryGradient.colors.last,
          ElegantLightTheme.primaryBlue,
        ],
        actions: [
          if (!controller.isLoading.value)
            TextButton(
              onPressed: controller.clearForm,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: const Text('Limpiar'),
            ),
          const SizedBox(width: AppDimensions.paddingSmall),
        ],
      ),
      body: controller.isLoading.value
          ? const Center(child: LoadingWidget())
          : _buildFormContent(),
    ));
  }

  Widget _buildFormContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1200;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey.shade50,
                Colors.white,
              ],
            ),
          ),
          child: Column(
            children: [
              // Stepper progress indicator
              _buildStepperHeader(),
              
              // Form content with responsive constraints
              Expanded(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 1000 : isTablet ? 800 : double.infinity,
                  ),
                  margin: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32 : isTablet ? 24 : 0,
                  ),
                  child: Form(
                    key: controller.formKey,
                    child: _buildCurrentStepContent(),
                  ),
                ),
              ),
              
              // Navigation buttons with responsive styling
              _buildNavigationButtons(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepperHeader() {
    final stepIcons = [Icons.store, Icons.inventory_2, Icons.note_add];
    final stepLabels = ['Básica', 'Productos', 'Adicional'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < 3; i++) ...[
            Expanded(
              child: Obx(() {
                final isActive = controller.currentStep.value == i;
                final isDone = controller.currentStep.value > i;
                return GestureDetector(
                  onTap: () => controller.goToStep(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isActive || isDone
                                ? AppColors.primary
                                : Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isDone
                                ? const Icon(Icons.check, color: Colors.white, size: 14)
                                : Icon(stepIcons[i], color: Colors.white, size: 13),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            stepLabels[i],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                              color: isActive
                                  ? AppColors.primary
                                  : isDone
                                      ? AppColors.primary.withOpacity(0.7)
                                      : Colors.grey.shade500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            if (i < 2)
              Obx(() => Container(
                width: 20,
                height: 2,
                color: controller.currentStep.value > i
                    ? AppColors.primary
                    : Colors.grey.shade300,
              )),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    return Obx(() {
      switch (controller.currentStep.value) {
        case 0:
          return _buildBasicInfoStep();
        case 1:
          return _buildItemsStep();
        case 2:
          return _buildAdditionalInfoStep();
        default:
          return Container();
      }
    });
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Proveedor
          Text(
            'Proveedor *',
            style: Get.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Obx(() => SupplierSelectorWidget(
            selectedSupplier: controller.selectedSupplier.value,
            controller: controller,
            onSupplierSelected: controller.selectSupplier,
            onClearSupplier: controller.clearSupplier,
            activateOnTextFieldTap: true, // Activar con tap en textfield
          )),
          if (controller.supplierError.value)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Debe seleccionar un proveedor',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),

          const SizedBox(height: AppDimensions.paddingMedium),

          // Prioridad
          Text(
            'Prioridad',
            style: Get.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Obx(() => DropdownButtonFormField<PurchaseOrderPriority>(
            value: controller.priority.value,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              prefixIcon: Icon(
                _getPriorityIcon(controller.priority.value),
                color: _getPriorityColor(controller.priority.value),
              ),
            ),
            items: PurchaseOrderPriority.values.map((priority) =>
              DropdownMenuItem(
                value: priority,
                child: Row(
                  children: [
                    Icon(
                      _getPriorityIcon(priority),
                      size: 16,
                      color: _getPriorityColor(priority),
                    ),
                    const SizedBox(width: AppDimensions.paddingSmall),
                    Text(_getPriorityText(priority)),
                  ],
                ),
              ),
            ).toList(),
            onChanged: (value) {
              if (value != null) {
                controller.priority.value = value;
              }
            },
          )),

          const SizedBox(height: AppDimensions.paddingMedium),

          // Fechas
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fecha de Orden *',
                      style: Get.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingSmall),
                    Obx(() => InkWell(
                      onTap: controller.selectOrderDate,
                      child: Container(
                        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: controller.orderDateError.value 
                                ? Colors.red 
                                : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: AppDimensions.paddingSmall),
                            Text(
                              controller.orderDateController.text,
                              style: Get.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fecha de Entrega *',
                      style: Get.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingSmall),
                    Obx(() => InkWell(
                      onTap: controller.selectExpectedDeliveryDate,
                      child: Container(
                        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: controller.expectedDeliveryDateError.value 
                                ? Colors.red 
                                : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: AppDimensions.paddingSmall),
                            Text(
                              controller.expectedDeliveryDateController.text,
                              style: Get.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),

          if (controller.orderDateError.value || controller.expectedDeliveryDateError.value)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'La fecha de entrega debe ser posterior a la fecha de orden',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),

          const SizedBox(height: AppDimensions.paddingMedium),

          // Moneda
          CustomTextField(
            controller: controller.currencyController,
            label: 'Moneda',
            hint: 'COP',
            prefixIcon: Icons.monetization_on,
          ),

          const SizedBox(height: AppDimensions.paddingMedium),

          // Notas
          CustomTextField(
            controller: controller.notesController,
            label: 'Notas',
            hint: 'Notas adicionales sobre la orden...',
            maxLines: 3,
            prefixIcon: Icons.note,
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
        ],
      ),
    );
  }

  Widget _buildItemsStep() {
    return Column(
      children: [
        // Header mejorado y compacto
        _buildOptimizedItemsHeader(),

        // Lista de items optimizada para muchos productos
        Expanded(
          child: _buildOptimizedItemsList(),
        ),

        // Resumen de totales compacto
        _buildCompactTotalsSummary(),
      ],
    );
  }

  Widget _buildOptimizedItemsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.04),
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withOpacity(0.15)),
        ),
      ),
      child: Obx(() {
        final completed = controller.items.where((i) => i.isValid).length;
        return Row(
          children: [
            Icon(Icons.inventory_2, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              '$completed producto${completed != 1 ? 's' : ''}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
            const Spacer(),
            Text(
              AppFormatters.formatCurrency(controller.totalAmount.value),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildOptimizedItemsList() {
    return Obx(() {
      if (controller.items.isEmpty) {
        return _buildEmptyItemsState();
      }

      final hasActiveItem = controller.activeItemIndex.value >= 0;

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: controller.items.length + (hasActiveItem ? 0 : 1),
        itemBuilder: (context, index) {
          // Items
          if (index < controller.items.length) {
            final item = controller.items[index];
            final isActive = controller.activeItemIndex.value == index;

            return ProductItemFormWidget(
              key: ValueKey('item_${item.productId}_$index'),
              item: item,
              index: index,
              isActive: isActive,
              onQuantityChanged: (value) =>
                  controller.updateItemQuantity(index, value),
              onPriceChanged: (value) =>
                  controller.updateItemPrice(index, value),
              onDiscountChanged: (value) =>
                  controller.updateItemDiscount(index, value),
              onRemove: controller.items.length > 1
                  ? () => controller.removeItem(index)
                  : null,
              onComplete: () => controller.completeActiveItem(),
              onEdit: () => controller.editItem(index),
              onProductSelected: (product) {
                if (product != null) {
                  controller.selectProductForItem(index, product);
                } else {
                  controller.updateItemProduct(index, '', '', 0.0);
                }
              },
            );
          }

          // Boton "Agregar Otro Producto"
          return Padding(
            padding: const EdgeInsets.only(top: AppDimensions.paddingSmall),
            child: OutlinedButton.icon(
              onPressed: controller.addEmptyItem,
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text('Agregar Otro Producto'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.primary.withOpacity(0.5),
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildCompactTotalsSummary() {
    return Obx(() {
      final validCount = controller.items.where((i) => i.isValid).length;
      final hasActiveItem = controller.activeItemIndex.value >= 0;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          border: Border(
            top: BorderSide(color: AppColors.primary.withOpacity(0.2)),
          ),
        ),
        child: Row(
          children: [
            if (hasActiveItem)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.orange.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'Agrega el producto para continuar',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade700, fontWeight: FontWeight.w500),
                  ),
                ],
              )
            else
              Text(
                '$validCount producto${validCount != 1 ? 's' : ''}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            const Spacer(),
            Text(
              AppFormatters.formatCurrency(controller.totalAmount.value),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAdditionalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información Adicional',
            style: Get.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),

          // Toggle para información de entrega
          Obx(() => SwitchListTile(
            title: const Text('Información de Entrega'),
            subtitle: const Text('Agregar detalles específicos de entrega'),
            value: controller.showDeliveryInfo.value,
            onChanged: (value) => controller.toggleDeliveryInfo(),
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          )),

          // Información de entrega (condicional)
          Obx(() => controller.showDeliveryInfo.value
              ? _buildDeliveryInfoSection()
              : const SizedBox.shrink()),

          const SizedBox(height: AppDimensions.paddingMedium),

          // Notas internas
          CustomTextField(
            controller: controller.internalNotesController,
            label: 'Notas Internas',
            hint: 'Notas internas para el equipo...',
            maxLines: 3,
            prefixIcon: Icons.lock,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoSection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppDimensions.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información de Entrega',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            
            CustomTextField(
              controller: controller.deliveryAddressController,
              label: 'Dirección de Entrega',
              hint: 'Dirección completa para la entrega',
              prefixIcon: Icons.location_on,
            ),
            
            const SizedBox(height: AppDimensions.paddingMedium),
            
            CustomTextField(
              controller: controller.contactPersonController,
              label: 'Persona de Contacto',
              hint: 'Nombre de la persona que recibe',
              prefixIcon: Icons.person,
            ),
            
            const SizedBox(height: AppDimensions.paddingMedium),
            
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: controller.contactPhoneController,
                    label: 'Teléfono',
                    hint: 'Número de contacto',
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingMedium),
                Expanded(
                  child: CustomTextField(
                    controller: controller.contactEmailController,
                    label: 'Email',
                    hint: 'Email de contacto',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyItemsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            'No hay productos agregados',
            style: Get.textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Text(
            'Agrega productos para crear la orden de compra',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          CustomButton(
            text: 'Agregar Primer Producto',
            onPressed: controller.addEmptyItem,
            icon: Icons.add,
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(int index) {
    return Obx(() {
      final item = controller.items[index];
      
      return Card(
        margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header del item
              Row(
                children: [
                  Text(
                    'Producto ${index + 1}',
                    style: Get.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (controller.items.length > 1)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => controller.removeItem(index),
                      color: Colors.red.shade600,
                      tooltip: 'Eliminar producto',
                    ),
                ],
              ),
              
              const SizedBox(height: AppDimensions.paddingMedium),
              
              // Selector de producto
              ProductSelectorWidget(
                selectedProduct: item.productId.isNotEmpty ? null : null, // Necesitaremos el objeto Product completo
                controller: controller,
                hint: item.productName.isNotEmpty ? item.productName : 'Seleccionar producto',
                activateOnTextFieldTap: true,
                onProductSelected: (product) => controller.selectProductForItem(index, product),
                onClearProduct: () {
                  final updatedItem = item.copyWith(
                    productId: '',
                    productName: '',
                    unitPrice: 0.0,
                  );
                  controller.items[index] = updatedItem;
                  controller.calculateTotals();
                },
              ),
              
              const SizedBox(height: AppDimensions.paddingMedium),
              
              // Cantidad y precio
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('quantity_${item.productId}_$index'),
                      controller: TextEditingController(text: AppFormatters.formatStock(item.quantity)),
                      decoration: InputDecoration(
                        labelText: 'Cantidad',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        ),
                        prefixIcon: Icon(Icons.format_list_numbered),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        print('🔢 DEBUG: Cantidad changed para item $index: $value');
                        final quantity = AppFormatters.parseNumber(value)?.toInt() ?? 0;
                        print('🔢 DEBUG: Parsed quantity: $quantity');
                        controller.updateItemQuantity(index, quantity);
                      },
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingMedium),
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('price_${item.productId}_$index'),
                      controller: TextEditingController(text: AppFormatters.formatCurrency(item.unitPrice)),
                      decoration: InputDecoration(
                        labelText: 'Precio Unitario',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        ),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        print('💰 DEBUG: Precio changed para item $index: $value');
                        final price = AppFormatters.parseNumber(value) ?? 0.0;
                        print('💰 DEBUG: Parsed price: $price');
                        controller.updateItemPrice(index, price);
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppDimensions.paddingMedium),
              
              // Descuento y total del item
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('discount_${item.productId}_$index'),
                      controller: TextEditingController(text: AppFormatters.formatStock(item.discountPercentage)),
                      decoration: InputDecoration(
                        labelText: 'Descuento (%)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        ),
                        prefixIcon: Icon(Icons.percent),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final discount = double.tryParse(value) ?? 0.0;
                        controller.updateItemDiscount(index, discount);
                      },
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingMedium),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Item',
                            style: Get.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            AppFormatters.formatCurrency(item.quantity * item.unitPrice * (1 - item.discountPercentage / 100)),
                            style: Get.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // Debug info (deshabilitado en producción)
              if (false) // Set to true for debugging
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    'DEBUG: Item $index - Q:${item.quantity}, P:${item.unitPrice}, Valid:${item.isValid}',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTotalsSummary() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Obx(() => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal:', style: Get.textTheme.bodyMedium),
              Text(
                AppFormatters.formatCurrency(controller.subtotal.value),
                style: Get.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Descuento:', style: Get.textTheme.bodyMedium),
              Text(
                '-${AppFormatters.formatCurrency(controller.discountAmount.value)}',
                style: Get.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Impuestos:', style: Get.textTheme.bodyMedium),
              Text(
                AppFormatters.formatCurrency(controller.taxAmount.value),
                style: Get.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                AppFormatters.formatCurrency(controller.totalAmount.value),
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      )),
    );
  }

  Widget _buildNavigationButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1200;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
        final isMobile = constraints.maxWidth < 600;
        
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 24 : isTablet ? 20 : 14,
            vertical: isMobile ? 10 : 16,
          ),
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 1000 : isTablet ? 800 : double.infinity,
          ),
          margin: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : isTablet ? 24 : 0,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Obx(() {
              return Row(
                children: [
                  if (!controller.isFirstStep) ...[
                    Expanded(
                      child: CustomButton(
                        text: 'Anterior',
                        onPressed: controller.previousStep,
                        type: ButtonType.outline,
                        icon: Icons.arrow_back,
                      ),
                    ),
                    SizedBox(width: isMobile ? 12 : isDesktop ? 20 : AppDimensions.paddingMedium),
                  ],

                  Expanded(
                    flex: controller.isFirstStep ? 3 : 2,
                    child: controller.isLastStep
                        ? CustomButton(
                            text: controller.saveButtonText,
                            onPressed: controller.isSaving.value ? null : controller.savePurchaseOrder,
                            isLoading: controller.isSaving.value,
                            icon: Icons.save,
                          )
                        : CustomButton(
                            text: 'Siguiente',
                            onPressed: controller.canProceed ? controller.nextStep : null,
                            icon: Icons.arrow_forward,
                          ),
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  // Helper methods
  void _selectSupplier() {
    // Implementación del selector será manejada por el widget SupplierSelectorWidget
    // que será agregado directamente en el build
  }

  void _selectProduct(int index) {
    // Implementación del selector será manejada por el widget ProductSelectorWidget
    // que será agregado directamente en el build del item
  }

  Color _getPriorityColor(PurchaseOrderPriority priority) {
    switch (priority) {
      case PurchaseOrderPriority.low:
        return Colors.green;
      case PurchaseOrderPriority.medium:
        return Colors.orange;
      case PurchaseOrderPriority.high:
        return Colors.red;
      case PurchaseOrderPriority.urgent:
        return Colors.deepPurple;
    }
  }

  IconData _getPriorityIcon(PurchaseOrderPriority priority) {
    switch (priority) {
      case PurchaseOrderPriority.low:
        return Icons.keyboard_arrow_down;
      case PurchaseOrderPriority.medium:
        return Icons.remove;
      case PurchaseOrderPriority.high:
        return Icons.keyboard_arrow_up;
      case PurchaseOrderPriority.urgent:
        return Icons.priority_high;
    }
  }

  String _getPriorityText(PurchaseOrderPriority priority) {
    switch (priority) {
      case PurchaseOrderPriority.low:
        return 'Baja';
      case PurchaseOrderPriority.medium:
        return 'Media';
      case PurchaseOrderPriority.high:
        return 'Alta';
      case PurchaseOrderPriority.urgent:
        return 'Urgente';
    }
  }

}