// lib/features/invoices/presentation/screens/invoice_form_screen.dart
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:baudex_desktop/features/invoices/presentation/widgets/modern_invoice_items_table.dart';
import 'package:baudex_desktop/features/invoices/presentation/widgets/enhanced_payment_dialog.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:baudex_desktop/app/core/utils/responsive.dart';
import 'package:baudex_desktop/app/core/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/invoice_form_controller.dart';
import '../controllers/invoice_tabs_controller.dart';
import '../widgets/product_search_widget.dart';
import '../widgets/customer_selector_widget.dart';

class InvoiceFormScreen extends StatefulWidget {
  final InvoiceFormController? controller;

  const InvoiceFormScreen({super.key, this.controller});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  int _selectedIndex = -1;
  bool _isShiftPressed = false;
  bool _isCtrlPressed = false;
  
  // ScrollController para la tabla de productos (para hacer scroll automático)
  final ScrollController _productsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Register global keyboard handler
    ServicesBinding.instance.keyboard.addHandler(_handleGlobalKeyEvent);
  }

  @override
  void dispose() {
    // Unregister global keyboard handler
    ServicesBinding.instance.keyboard.removeHandler(_handleGlobalKeyEvent);
    _productsScrollController.dispose();
    super.dispose();
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (!mounted) return false;

    final controller = widget.controller;
    if (controller == null || controller.invoiceItems.isEmpty) return false;

    // ✅ NUEVO: No procesar shortcuts si hay un dialog activo
    // Verificar si hay un overlay activo (como un Dialog)
    final overlay = Overlay.of(context);
    if (overlay.mounted && ModalRoute.of(context)?.isCurrent != true) {
      print('🚫 SCREEN Shortcuts deshabilitados - Dialog activo');
      return false;
    }

    if (event is KeyDownEvent) {
      // Detectar teclas modificadoras
      if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
          event.logicalKey == LogicalKeyboardKey.shiftRight) {
        _isShiftPressed = true;
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
          event.logicalKey == LogicalKeyboardKey.controlRight) {
        _isCtrlPressed = true;
        return true;
      }

      // Navegación con flechas
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _moveSelection(-1, controller);
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _moveSelection(1, controller);
        return true;
      }

      // ✅ NUEVOS SHORTCUTS: Solo con Shift presionado
      if (_selectedIndex >= 0 &&
          _selectedIndex < controller.invoiceItems.length) {
        
        // Shortcuts SOLO con Shift presionado
        if (_isShiftPressed) {
          // Shift + = (tecla +) para incrementar en 1
          if (event.logicalKey == LogicalKeyboardKey.equal) {
            _incrementQuantity(1, controller);
            return true;
          }
          
          // Shift + - para decrementar en 1
          if (event.logicalKey == LogicalKeyboardKey.minus) {
            _decrementQuantity(1, controller);
            return true;
          }

          // Shift + número (1-9) para incrementar por esa cantidad
          if (event.logicalKey.keyLabel.length == 1) {
            final key = event.logicalKey.keyLabel;
            if (RegExp(r'^[1-9]$').hasMatch(key)) {
              final increment = int.parse(key);
              _incrementQuantity(increment, controller);
              return true;
            }
          }
          
          // Shift + Enter para procesar venta
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            print('🎹 SCREEN Shift+Enter detectado - canSave: ${controller.canSave}, isSaving: ${controller.isSaving}');
            if (controller.canSave && !controller.isSaving) {
              print('🎯 SCREEN Abriendo diálogo de pago...');
              _showPaymentDialog(context, controller);
            }
            return true;
          }
        }

        // Eliminar producto seleccionado con Shift + Delete
        if (event.logicalKey == LogicalKeyboardKey.delete && _isShiftPressed) {
          _deleteSelectedItem(controller);
          return true;
        }

        // Duplicar producto con Ctrl + D
        if (_isCtrlPressed && event.logicalKey == LogicalKeyboardKey.keyD) {
          _duplicateSelectedItem(controller);
          return true;
        }
      }

      // Navegación rápida con Home/End
      if (event.logicalKey == LogicalKeyboardKey.home) {
        _moveToFirst(controller);
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.end) {
        _moveToLast(controller);
        return true;
      }
    }

    if (event is KeyUpEvent) {
      // Resetear teclas modificadoras
      if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
          event.logicalKey == LogicalKeyboardKey.shiftRight) {
        _isShiftPressed = false;
      }
      if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
          event.logicalKey == LogicalKeyboardKey.controlRight) {
        _isCtrlPressed = false;
      }
    }

    return false;
  }

  void _moveSelection(int direction, InvoiceFormController controller) {
    if (controller.invoiceItems.isEmpty) return;

    setState(() {
      _selectedIndex = (_selectedIndex + direction).clamp(
        0,
        controller.invoiceItems.length - 1,
      );
    });
    
    // Hacer scroll automático para que el elemento seleccionado sea visible
    _scrollToSelected();
  }

  void _moveToFirst(InvoiceFormController controller) {
    if (controller.invoiceItems.isNotEmpty) {
      setState(() {
        _selectedIndex = 0;
      });
      _scrollToSelected();
    }
  }

  void _moveToLast(InvoiceFormController controller) {
    if (controller.invoiceItems.isNotEmpty) {
      setState(() {
        _selectedIndex = controller.invoiceItems.length - 1;
      });
      _scrollToSelected();
    }
  }

  // Método para hacer scroll automático al elemento seleccionado
  void _scrollToSelected() {
    if (!_productsScrollController.hasClients || _selectedIndex < 0) return;

    // Altura estimada de cada fila en la tabla (coincide con el diseño compacto)
    const double itemHeight = 50.0; // Altura compacta de cada fila (ajustada)
    const double padding = 4.0; // Padding entre elementos (reducido)
    
    final double targetPosition = (_selectedIndex * (itemHeight + padding));
    final double viewportHeight = _productsScrollController.position.viewportDimension;
    final double currentScroll = _productsScrollController.offset;
    
    // Calcular si el elemento está fuera de la vista
    final double itemTop = targetPosition;
    final double itemBottom = targetPosition + itemHeight;
    final double viewportTop = currentScroll;
    final double viewportBottom = currentScroll + viewportHeight;
    
    double? newScrollPosition;
    
    // Si el elemento está arriba de la vista, hacer scroll hacia arriba
    if (itemTop < viewportTop) {
      newScrollPosition = itemTop - padding;
    }
    // Si el elemento está abajo de la vista, hacer scroll hacia abajo
    else if (itemBottom > viewportBottom) {
      newScrollPosition = itemBottom - viewportHeight + padding;
    }
    
    // Solo hacer scroll si es necesario
    if (newScrollPosition != null) {
      _productsScrollController.animateTo(
        newScrollPosition.clamp(
          0.0, 
          _productsScrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  void _incrementQuantity(int increment, InvoiceFormController controller) {
    if (_selectedIndex >= 0 &&
        _selectedIndex < controller.invoiceItems.length) {
      final item = controller.invoiceItems[_selectedIndex];
      final newQuantity = item.quantity + increment;

      // Validar stock si es necesario
      final product = controller.availableProducts.firstWhereOrNull(
        (p) => p.id == item.productId,
      );

      if (product != null && !_isTemporaryProduct(product)) {
        if (newQuantity > product.stock) {
          Get.snackbar(
            'Stock Insuficiente',
            'Solo hay ${product.stock.toInt()} unidades disponibles de ${product.name}',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
            icon: const Icon(Icons.warning, color: Colors.red),
            duration: const Duration(seconds: 2),
          );
          return;
        }
      }

      final updatedItem = item.copyWith(quantity: newQuantity);
      controller.updateItem(_selectedIndex, updatedItem);
    }
  }

  void _decrementQuantity(int decrement, InvoiceFormController controller) {
    if (_selectedIndex >= 0 &&
        _selectedIndex < controller.invoiceItems.length) {
      final item = controller.invoiceItems[_selectedIndex];
      final newQuantity = (item.quantity - decrement).clamp(
        1.0,
        double.infinity,
      );

      if (newQuantity < 1) {
        _deleteSelectedItem(controller);
        return;
      }

      final updatedItem = item.copyWith(quantity: newQuantity);
      controller.updateItem(_selectedIndex, updatedItem);
    }
  }

  void _setExactQuantity(double quantity, InvoiceFormController controller) {
    if (_selectedIndex >= 0 &&
        _selectedIndex < controller.invoiceItems.length) {
      final item = controller.invoiceItems[_selectedIndex];

      // Validar stock si es necesario
      final product = controller.availableProducts.firstWhereOrNull(
        (p) => p.id == item.productId,
      );

      if (product != null && !_isTemporaryProduct(product)) {
        if (quantity > product.stock) {
          Get.snackbar(
            'Stock Insuficiente',
            'Solo hay ${product.stock.toInt()} unidades disponibles de ${product.name}',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
            icon: const Icon(Icons.warning, color: Colors.red),
            duration: const Duration(seconds: 2),
          );
          return;
        }
      }

      final updatedItem = item.copyWith(quantity: quantity);
      controller.updateItem(_selectedIndex, updatedItem);
    }
  }

  bool _isTemporaryProduct(Product product) {
    return product.id.startsWith('temp_') ||
        product.id.startsWith('unregistered_') ||
        (product.metadata?['isTemporary'] == true);
  }

  void _deleteSelectedItem(InvoiceFormController controller) {
    if (_selectedIndex >= 0 &&
        _selectedIndex < controller.invoiceItems.length) {
      controller.removeItem(_selectedIndex);

      // Ajustar selección después de eliminar
      if (controller.invoiceItems.isNotEmpty) {
        setState(() {
          _selectedIndex = _selectedIndex.clamp(
            0,
            controller.invoiceItems.length - 1,
          );
        });
      } else {
        setState(() {
          _selectedIndex = -1;
        });
      }
    }
  }

  void _duplicateSelectedItem(InvoiceFormController controller) {
    if (_selectedIndex >= 0 &&
        _selectedIndex < controller.invoiceItems.length) {
      final item = controller.invoiceItems[_selectedIndex];
      final product = controller.availableProducts.firstWhereOrNull(
        (p) => p.id == item.productId,
      );

      if (product != null) {
        controller.addOrUpdateProductToInvoice(
          product,
          quantity: item.quantity,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ SIEMPRE usar el controlador pasado como parámetro
    final controller = widget.controller;

    if (controller == null) {
      // ✅ Si no hay controlador, mostrar error en lugar de buscar uno global
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Error: No se proporcionó controlador específico',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
              Text(
                'Este componente requiere un controlador específico',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ Usar el controlador específico con Obx para reactividad
    return Scaffold(
      appBar: _buildAppBar(context, controller),
      body: Obx(
        () =>
            controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : context.isMobile
                    ? _buildMobileLayout(context, controller)
                    : _buildDesktopLayout(context, controller),
      ),
    );
  }

  // Layout para móviles (scroll completo como antes)
  Widget _buildMobileLayout(BuildContext context, InvoiceFormController controller) {
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomerSelectorWidget(
            selectedCustomer: controller.selectedCustomer,
            onCustomerSelected: controller.selectCustomer,
            onClearCustomer: controller.clearCustomer,
            controller: controller,
          ),
          SizedBox(height: context.verticalSpacing * 0.4),
          ProductSearchWidget(
            controller: controller,
            autoFocus: true,
            onProductSelected: (product, quantity) {
              controller.addOrUpdateProductToInvoice(
                product,
                quantity: quantity,
              );
              setState(() {
                _selectedIndex = 0;
              });
            },
          ),
          SizedBox(height: context.verticalSpacing * 0.4),
          ModernInvoiceItemsTable(
            controller: controller,
            selectedIndex: _selectedIndex,
            onSelectionChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            height: 250,
          ),
          SizedBox(height: context.verticalSpacing * 0.4),
          _buildTotalsSection(context, controller),
        ],
      ),
    );
  }

  // Layout para desktop (resumen fijo en la parte inferior)
  Widget _buildDesktopLayout(BuildContext context, InvoiceFormController controller) {
    return Column(
      children: [
        // Sección superior con scroll
        Expanded(
          child: SingleChildScrollView(
            padding: context.responsivePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomerSelectorWidget(
                  selectedCustomer: controller.selectedCustomer,
                  onCustomerSelected: controller.selectCustomer,
                  onClearCustomer: controller.clearCustomer,
                  controller: controller,
                ),
                SizedBox(height: context.verticalSpacing * 0.4),
                ProductSearchWidget(
                  controller: controller,
                  autoFocus: true,
                  onProductSelected: (product, quantity) {
                    controller.addOrUpdateProductToInvoice(
                      product,
                      quantity: quantity,
                    );
                    setState(() {
                      _selectedIndex = 0;
                    });
                  },
                ),
                SizedBox(height: context.verticalSpacing * 0.4),
                // La tabla de productos con altura dinámica para desktop
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: ModernInvoiceItemsTable(
                    controller: controller,
                    selectedIndex: _selectedIndex,
                    onSelectionChanged: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    scrollController: _productsScrollController, // Para scroll automático
                  ),
                ),
              ],
            ),
          ),
        ),
        // Resumen de venta fijo solo en desktop
        Container(
          padding: EdgeInsets.fromLTRB(
            context.responsivePadding.left,
            4, // Reducir más el padding superior
            context.responsivePadding.right,
            context.responsivePadding.bottom * 0.4, // Reducir más el padding inferior
          ),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(
              top: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: _buildTotalsSection(context, controller),
        ),
      ],
    );
  }

  AppBar _buildAppBar(BuildContext context, InvoiceFormController controller) {
    return AppBar(
      title:
          context.isMobile
              ? _buildMobileTitle(context, controller)
              : _buildDesktopTitle(context, controller),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      actions: _buildAppBarActions(context, controller),
    );
  }

  Widget _buildMobileTitle(
    BuildContext context,
    InvoiceFormController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          controller.isEditMode ? 'Editar' : 'POS',
          style: const TextStyle(fontSize: 16),
        ),
        if (controller.isEditMode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'BORRADOR',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopTitle(
    BuildContext context,
    InvoiceFormController controller,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(controller.pageTitle),
        if (controller.isEditMode) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'BORRADOR',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildAppBarActions(
    BuildContext context,
    InvoiceFormController controller,
  ) {
    final actions = <Widget>[];

    if (!controller.isEditMode && !context.isMobile) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: controller.clearFormForNewSale,
          tooltip: 'Nueva Venta',
        ),
      );
    }

    actions.add(
      Container(
        margin: EdgeInsets.only(right: context.isMobile ? 4 : 8),
        child:
            context.isMobile
                ? _buildMobileSaveButton(context, controller)
                : _buildDesktopSaveButton(context, controller),
      ),
    );

    return actions;
  }

  Widget _buildMobileSaveButton(
    BuildContext context,
    InvoiceFormController controller,
  ) {
    return Obx(
      () => ElevatedButton(
        onPressed:
            controller.canSave && !controller.isSaving
                ? () => _showPaymentDialog(context, controller)
                : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child:
            controller.isSaving
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : Tooltip(
                  message: 'Procesar Venta (Shift+Enter)',
                  child: const Icon(Icons.point_of_sale, size: 20),
                ),
      ),
    );
  }

  Widget _buildDesktopSaveButton(
    BuildContext context,
    InvoiceFormController controller,
  ) {
    return Obx(
      () => Tooltip(
        message: 'Procesar Venta (Shift+Enter)',
        child: ElevatedButton.icon(
          onPressed:
              controller.canSave && !controller.isSaving
                  ? () => _showPaymentDialog(context, controller)
                  : null,
          icon:
              controller.isSaving
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Icon(Icons.point_of_sale),
          label: Text(
            controller.isSaving ? 'Guardando...' : controller.saveButtonText,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTotalsSection(
    BuildContext context,
    InvoiceFormController controller,
  ) {
    return Obx(() {
      return Container(
        padding: EdgeInsets.all(context.isMobile ? 6 : 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: Theme.of(context).primaryColor,
                  size: context.isMobile ? 14 : 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Resumen',
                  style: TextStyle(
                    fontSize: context.isMobile ? 12 : 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '${controller.invoiceItems.length}',
                  style: TextStyle(
                    fontSize: context.isMobile ? 8 : 9,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.isMobile ? 3 : 4),
            _buildTotalRow(context, 'Subtotal', controller.subtotalWithoutTax),
            if (controller.totalDiscountAmount > 0)
              _buildTotalRow(
                context,
                'Descuentos',
                -controller.totalDiscountAmount,
                isDiscount: true,
              ),
            if (controller.taxAmount > 0)
              _buildTotalRow(
                context,
                'IVA (${controller.taxPercentage}%)',
                controller.taxAmount,
              ),
            Divider(height: context.isMobile ? 6 : 8, thickness: 0.5),
            _buildTotalRow(context, 'TOTAL', controller.total, isTotal: true),
          ],
        ),
      );
    });
  }

  Widget _buildTotalRow(
    BuildContext context,
    String label,
    double amount, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.isMobile ? 1 : 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize:
                    isTotal
                        ? (context.isMobile ? 11 : 13)
                        : (context.isMobile ? 8 : 10),
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isTotal ? Colors.black : Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              isDiscount 
                ? '-${AppFormatters.formatCurrency(amount.abs())}'
                : AppFormatters.formatCurrency(amount.abs()),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize:
                    isTotal
                        ? (context.isMobile ? 13 : 15)
                        : (context.isMobile ? 9 : 11),
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                color:
                    isTotal
                        ? Colors.green.shade600
                        : isDiscount
                        ? Colors.red.shade600
                        : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(
    BuildContext context,
    InvoiceFormController controller,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => EnhancedPaymentDialog(
            total: controller.total,
            onPaymentConfirmed: (
              amount,
              change,
              paymentMethod,
              status,
              shouldPrint,
            ) async {
              print('🎯 === PROCESANDO VENTA ===');
              print('📋 Estado: ${status.displayName}');
              print('💰 Método: ${paymentMethod.displayName}');
              print('🖨️ Imprimir: $shouldPrint');

              try {
                // Guardar la factura con el estado y método de pago correctos
                final success = await controller.saveInvoiceWithPayment(
                  amount,
                  change,
                  paymentMethod,
                  status,
                  shouldPrint,
                );

                print('🔍 SCREEN: saveInvoiceWithPayment returned: $success');

                // ✅ SOLO CONTINUAR SI LA OPERACIÓN FUE EXITOSA
                if (success) {
                  print('✅ SCREEN: Operación exitosa - continuando con limpieza y snackbar');
                  
                  // ✅ NOTA: El diálogo ya se cerró automáticamente en _confirmPayment

                  // ✅ NUEVO: Cerrar la pestaña automáticamente después de procesar venta
                  // Solo cerrar si no es borrador Y si hay más de una pestaña abierta
                  if (status != InvoiceStatus.draft) {
                    final tabsController = Get.find<InvoiceTabsController>();
                    if (tabsController.currentTab != null) {
                      // ✅ NUEVA VALIDACIÓN: Solo cerrar si hay más de una pestaña
                      if (tabsController.tabs.length > 1) {
                        print('🔖 Cerrando pestaña después de procesar venta (quedan ${tabsController.tabs.length - 1} pestañas)...');
                        tabsController.closeTab(
                          tabsController.currentTab!.id,
                          forceClose: true,
                        );
                      } else {
                        print('🔖 No se cierra la pestaña: es la única abierta');
                        // ✅ OPCIONAL: Limpiar la factura actual para una nueva venta
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          controller.clearFormForNewSale();
                        });
                      }
                    }
                  }

                  // ✅ MOSTRAR MENSAJE DE ÉXITO SOLO SI LA OPERACIÓN FUE EXITOSA
                  print('🎉 SCREEN: Mostrando snackbar de éxito');
                  Get.snackbar(
                    'Venta Procesada',
                    status == InvoiceStatus.draft
                        ? 'Factura guardada como borrador'
                        : 'Venta procesada exitosamente',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.green.shade100,
                    colorText: Colors.green.shade800,
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    duration: const Duration(seconds: 3),
                  );
                } else {
                  print('❌ SCREEN: Operación falló - NO se muestra snackbar');
                  // No hacer nada más, el controlador ya manejó el error
                }
              } catch (e) {
                print('❌ Error al procesar venta: $e');
                // ✅ NOTA: El diálogo ya se cerró automáticamente en _confirmPayment

                Get.snackbar(
                  'Error',
                  'Error al procesar la venta: $e',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.red.shade100,
                  colorText: Colors.red.shade800,
                  icon: const Icon(Icons.error, color: Colors.red),
                  duration: const Duration(seconds: 4),
                );
              }
            },
            onCancel: () {
              Navigator.of(context).pop();
            },
          ),
    );
  }
}
