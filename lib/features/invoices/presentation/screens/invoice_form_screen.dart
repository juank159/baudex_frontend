// lib/features/invoices/presentation/screens/invoice_form_screen.dart
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:baudex_desktop/features/invoices/presentation/widgets/modern_invoice_items_table.dart';
import 'package:baudex_desktop/features/invoices/presentation/widgets/enhanced_payment_dialog.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:baudex_desktop/app/core/utils/responsive.dart';
import 'package:baudex_desktop/app/core/utils/formatters.dart';
import 'package:baudex_desktop/app/core/theme/elegant_light_theme.dart';
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
  final bool _isProductSearchActive =
      false; // ✅ NUEVO: Rastrear si ProductSearchWidget está activo
  DateTime?
  _lastEnterEvent; // ✅ NUEVO: Rastrear último evento Enter para evitar propagación

  // ScrollController para la tabla de productos (para hacer scroll automático)
  final ScrollController _productsScrollController = ScrollController();

  // ✅ NUEVO: GlobalKeys para coordinar focus entre widgets
  final GlobalKey<ProductSearchWidgetState> _productSearchKey =
      GlobalKey<ProductSearchWidgetState>();
  final GlobalKey<CustomerSelectorWidgetState> _customerSelectorKey =
      GlobalKey<CustomerSelectorWidgetState>();

  @override
  void initState() {
    super.initState();
    // Register global keyboard handler
    ServicesBinding.instance.keyboard.addHandler(_handleGlobalKeyEvent);

    // ✅ NUEVO: Escuchar cambios en lastUpdatedItemIndex para selección automática
    _setupUpdatedItemListener();
  }

  // ✅ NUEVO: Configurar listener para productos actualizados
  void _setupUpdatedItemListener() {
    final controller = widget.controller;
    if (controller != null) {
      // Usar ever para reaccionar cada vez que cambie lastUpdatedItemIndex
      ever(controller.lastUpdatedItemIndexObs, (int? index) {
        if (index != null && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedIndex = index;
              print(
                '🎯 SCREEN: Producto actualizado seleccionado automáticamente en índice: $index',
              );
            });
            // ✅ MEJORADO: Hacer scroll suave al item seleccionado con delay
            _scrollToSelectedWithDelay();
          });
        }
      });
    }
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

    // ✅ CRÍTICO: No procesar Enter si el ProductSearchWidget está activo
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
      final focusedWidget = FocusManager.instance.primaryFocus?.context?.widget;
      if (focusedWidget != null &&
          focusedWidget.toString().contains('TextField')) {
        print(
          '🚫 SCREEN Enter ignorado - Focus está en campo de búsqueda de productos',
        );
        return false;
      }
    }

    if (event is KeyDownEvent) {
      // Detectar teclas modificadoras
      if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
          event.logicalKey == LogicalKeyboardKey.shiftRight) {
        _isShiftPressed = true;
        print('🔧 SCREEN Shift PRESIONADO');
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
          event.logicalKey == LogicalKeyboardKey.controlRight) {
        _isCtrlPressed = true;
        print('🔧 SCREEN Ctrl PRESIONADO');
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

      // ✅ SHORTCUTS ACTUALIZADOS: Solo con Control presionado (NATIVO)
      if (_selectedIndex >= 0 &&
          _selectedIndex < controller.invoiceItems.length) {
        // ✅ USAR FLUTTER NATIVO para detectar Ctrl presionado
        final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;

        // Shortcuts SOLO con Control presionado (NATIVO)
        if (isCtrlPressed) {
          // Ctrl + = (tecla +) para incrementar en 1 - NATIVO
          if (event.logicalKey == LogicalKeyboardKey.equal) {
            _incrementQuantity(1, controller);
            return true;
          }

          // Ctrl + - para decrementar en 1 - NATIVO
          if (event.logicalKey == LogicalKeyboardKey.minus) {
            _decrementQuantity(1, controller);
            return true;
          }

          // Ctrl + número (1-9) para incrementar por esa cantidad - NATIVO
          if (event.logicalKey.keyLabel.length == 1) {
            final key = event.logicalKey.keyLabel;
            if (RegExp(r'^[1-9]$').hasMatch(key)) {
              final increment = int.parse(key);
              _incrementQuantity(increment, controller);
              return true;
            }
          }

          // Ctrl + T - NATIVO (nuevo shortcut)
          if (event.logicalKey == LogicalKeyboardKey.keyT) {
            // Acción para Ctrl + T (puedes definir qué hace)
            print('🎹 SCREEN Ctrl+T detectado (NATIVO)');
            // TODO: Implementar acción específica para Ctrl + T
            return true;
          }

          // Ctrl + W - NATIVO (nuevo shortcut)
          if (event.logicalKey == LogicalKeyboardKey.keyW) {
            // Acción para Ctrl + W (puedes definir qué hace)
            print('🎹 SCREEN Ctrl+W detectado (NATIVO)');
            // TODO: Implementar acción específica para Ctrl + W
            return true;
          }

          // Ctrl + Tab - NATIVO (nuevo shortcut)
          if (event.logicalKey == LogicalKeyboardKey.tab) {
            // Acción para Ctrl + Tab (puedes definir qué hace)
            print('🎹 SCREEN Ctrl+Tab detectado (NATIVO)');
            // TODO: Implementar acción específica para Ctrl + Tab
            return true;
          }

          // Ctrl + Enter para procesar venta - NATIVO
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            print('🔍 SCREEN Enter detectado - Ctrl nativo: $isCtrlPressed');

            // ✅ VERIFICACIÓN: Asegurar que no haya focus en TextField
            final focusedWidget =
                FocusManager.instance.primaryFocus?.context?.widget;
            if (focusedWidget != null &&
                focusedWidget.toString().contains('TextField')) {
              print(
                '🚫 SCREEN Ctrl+Enter cancelado - Focus en campo de búsqueda',
              );
              return false;
            }

            // ✅ NUEVO: Evitar eventos Enter duplicados o propagados
            final now = DateTime.now();
            if (_lastEnterEvent != null &&
                now.difference(_lastEnterEvent!).inMilliseconds < 500) {
              print(
                '🚫 SCREEN Ctrl+Enter ignorado - Evento muy reciente (${now.difference(_lastEnterEvent!).inMilliseconds}ms)',
              );
              return false;
            }
            _lastEnterEvent = now;

            print(
              '🎹 SCREEN Ctrl+Enter detectado (NATIVO) - canSave: ${controller.canSave}, isSaving: ${controller.isSaving}',
            );
            if (controller.canSave && !controller.isSaving) {
              print('🎯 SCREEN Abriendo diálogo de pago...');
              _showPaymentDialog(context, controller);
            }
            return true;
          }

          // Ctrl + Delete para eliminar producto - NATIVO
          if (event.logicalKey == LogicalKeyboardKey.delete) {
            _deleteSelectedItem(controller);
            return true;
          }
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
        print('🔧 SCREEN Shift LIBERADO');
      }
      if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
          event.logicalKey == LogicalKeyboardKey.controlRight) {
        _isCtrlPressed = false;
        print('🔧 SCREEN Ctrl LIBERADO');
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
    final double viewportHeight =
        _productsScrollController.position.viewportDimension;
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

  // ✅ NUEVO: Método para hacer scroll con delay para productos actualizados
  void _scrollToSelectedWithDelay() {
    // Dar un breve delay para que las animaciones de UI se completen primero
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _scrollToSelected();
        print(
          '📜 SCREEN: Scroll automático ejecutado para índice: $_selectedIndex',
        );
      }
    });
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
        child: Obx(
          () =>
              controller.isLoading
                  ? _buildLoadingView()
                  : context.isMobile
                  ? _buildMobileLayout(context, controller)
                  : _buildDesktopLayout(context, controller),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: ElegantLightTheme.glowShadow,
            ),
            child: const Icon(
              Icons.point_of_sale,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Preparando POS...',
            style: TextStyle(
              color: ElegantLightTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(ElegantLightTheme.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  // Layout para móviles (scroll completo como antes)
  Widget _buildMobileLayout(
    BuildContext context,
    InvoiceFormController controller,
  ) {
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomerSelectorWidget(
            key: _customerSelectorKey,
            selectedCustomer: controller.selectedCustomer,
            onCustomerSelected: controller.selectCustomer,
            onClearCustomer: controller.clearCustomer,
            controller: controller,
            onFocusChanged: (hasFocus) {
              // ✅ NUEVO: Coordinar focus con ProductSearchWidget
              if (hasFocus) {
                _productSearchKey.currentState?.pauseFocusRestoration();
              } else {
                _productSearchKey.currentState?.resumeFocusRestoration();
              }
            },
          ),
          SizedBox(height: context.verticalSpacing * 0.4),
          ProductSearchWidget(
            key: _productSearchKey,
            controller: controller,
            autoFocus: true,
            onProductSelected: (product, quantity) {
              controller.addOrUpdateProductToInvoice(
                product,
                quantity: quantity,
              );
              // ✅ MODIFICADO: No forzar selección aquí, dejar que el controlador maneje la selección automática
              // La selección se manejará automáticamente por el listener
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
  Widget _buildDesktopLayout(
    BuildContext context,
    InvoiceFormController controller,
  ) {
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
                  key: _customerSelectorKey,
                  selectedCustomer: controller.selectedCustomer,
                  onCustomerSelected: controller.selectCustomer,
                  onClearCustomer: controller.clearCustomer,
                  controller: controller,
                  onFocusChanged: (hasFocus) {
                    // ✅ NUEVO: Coordinar focus con ProductSearchWidget
                    if (hasFocus) {
                      _productSearchKey.currentState?.pauseFocusRestoration();
                    } else {
                      _productSearchKey.currentState?.resumeFocusRestoration();
                    }
                  },
                ),
                SizedBox(height: context.verticalSpacing * 0.4),
                ProductSearchWidget(
                  key: _productSearchKey,
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
                    scrollController:
                        _productsScrollController, // Para scroll automático
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
            context.responsivePadding.bottom *
                0.4, // Reducir más el padding inferior
          ),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
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
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
      ),
      actions: _buildAppBarActions(context, controller),
    );
  }

  Widget _buildMobileTitle(
    BuildContext context,
    InvoiceFormController controller,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icono elegante
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.point_of_sale,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              controller.isEditMode ? 'Editar Factura' : 'Punto de Venta',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (controller.isEditMode)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.warningGradient,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: ElegantLightTheme.accentOrange.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'BORRADOR',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
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
        // Icono elegante para desktop
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.point_of_sale,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          controller.pageTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        if (controller.isEditMode) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.warningGradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: ElegantLightTheme.accentOrange.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.edit_note,
                  color: Colors.white,
                  size: 14,
                ),
                SizedBox(width: 4),
                Text(
                  'BORRADOR',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
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
        Tooltip(
          message: 'Nueva Venta',
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: controller.clearFormForNewSale,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.add_circle_outline,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    actions.add(
      Container(
        margin: EdgeInsets.only(right: context.isMobile ? 4 : 12),
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
      () {
        final canSave = controller.canSave && !controller.isSaving;
        return Container(
          decoration: BoxDecoration(
            gradient: canSave
                ? ElegantLightTheme.successGradient
                : LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.2),
                      Colors.white.withValues(alpha: 0.1),
                    ],
                  ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: canSave
                ? [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: canSave ? () => _showPaymentDialog(context, controller) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: controller.isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.shopping_cart_checkout,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopSaveButton(
    BuildContext context,
    InvoiceFormController controller,
  ) {
    return Obx(
      () {
        final canSave = controller.canSave && !controller.isSaving;
        return Tooltip(
          message: 'Procesar Venta (Ctrl+Enter)',
          child: Container(
            decoration: BoxDecoration(
              gradient: canSave
                  ? ElegantLightTheme.successGradient
                  : LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.2),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                    ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: canSave
                  ? [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
              border: Border.all(
                color: canSave
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: canSave ? () => _showPaymentDialog(context, controller) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      controller.isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.shopping_cart_checkout,
                              color: Colors.white,
                              size: 20,
                            ),
                      const SizedBox(width: 8),
                      Text(
                        controller.isSaving ? 'Procesando...' : controller.saveButtonText,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotalsSection(
    BuildContext context,
    InvoiceFormController controller,
  ) {
    return Obx(() {
      return Container(
        padding: EdgeInsets.all(context.isMobile ? 10 : 14),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.glassGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ElegantLightTheme.textSecondary.withOpacity(0.2),
          ),
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: ElegantLightTheme.glowShadow,
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: Colors.white,
                    size: context.isMobile ? 12 : 14,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Resumen',
                  style: TextStyle(
                    fontSize: context.isMobile ? 13 : 15,
                    fontWeight: FontWeight.w700,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${controller.invoiceItems.length} items',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.isMobile ? 8 : 10),
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
            Padding(
              padding: EdgeInsets.symmetric(vertical: context.isMobile ? 4 : 6),
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      ElegantLightTheme.textSecondary.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
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
    final Color amountColor = isTotal
        ? const Color(0xFF10B981) // Verde elegante
        : isDiscount
            ? const Color(0xFFEF4444) // Rojo elegante
            : ElegantLightTheme.textPrimary;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.isMobile ? 2 : 3),
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
                        ? (context.isMobile ? 12 : 14)
                        : (context.isMobile ? 10 : 11),
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
                color: isTotal
                    ? ElegantLightTheme.textPrimary
                    : ElegantLightTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: isTotal
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.successGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      AppFormatters.formatCurrency(amount.abs()),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: context.isMobile ? 13 : 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Text(
                    isDiscount
                        ? '-${AppFormatters.formatCurrency(amount.abs())}'
                        : AppFormatters.formatCurrency(amount.abs()),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: context.isMobile ? 10 : 12,
                      fontWeight: FontWeight.w600,
                      color: amountColor,
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
            customerName: controller.selectedCustomer?.displayName,
            customerId: controller.selectedCustomer?.id, // ✅ NUEVO: ID del cliente para verificar saldo a favor
            onPaymentConfirmed: (
              amount,
              change,
              paymentMethod,
              status,
              shouldPrint, {
              String? bankAccountId,
              List<MultiplePaymentData>? multiplePayments,
              bool? createCreditForRemaining,
              double? balanceApplied, // ✅ NUEVO: Saldo a favor aplicado
            }) async {
              print('🎯 === PROCESANDO VENTA ===');
              print('📋 Estado: ${status.displayName}');
              print('💰 Método: ${paymentMethod.displayName}');
              print('🖨️ Imprimir: $shouldPrint');
              print('🏦 Cuenta: $bankAccountId');
              print('💳 Pagos múltiples: ${multiplePayments?.length ?? 0}');
              print('📋 Crear crédito: $createCreditForRemaining');
              print('💰 Saldo aplicado: ${balanceApplied ?? 0}');

              try {
                // Guardar la factura con el estado y método de pago correctos
                final success = await controller.saveInvoiceWithPayment(
                  amount,
                  change,
                  paymentMethod,
                  status,
                  shouldPrint,
                  bankAccountId: bankAccountId,
                  multiplePayments: multiplePayments,
                  createCreditForRemaining: createCreditForRemaining ?? false,
                  balanceApplied: balanceApplied, // ✅ NUEVO: Pasar saldo aplicado
                );

                print('🔍 SCREEN: saveInvoiceWithPayment returned: $success');

                // ✅ SOLO CONTINUAR SI LA OPERACIÓN FUE EXITOSA
                if (success) {
                  print(
                    '✅ SCREEN: Operación exitosa - continuando con limpieza y snackbar',
                  );

                  // ✅ NOTA: El diálogo ya se cerró automáticamente en _confirmPayment

                  // ✅ NUEVO: Cerrar la pestaña automáticamente después de procesar venta
                  // Solo cerrar si no es borrador Y si hay más de una pestaña abierta
                  if (status != InvoiceStatus.draft) {
                    final tabsController = Get.find<InvoiceTabsController>();
                    if (tabsController.currentTab != null) {
                      // ✅ NUEVA VALIDACIÓN: Solo cerrar si hay más de una pestaña
                      if (tabsController.tabs.length > 1) {
                        print(
                          '🔖 Cerrando pestaña después de procesar venta (quedan ${tabsController.tabs.length - 1} pestañas)...',
                        );
                        tabsController.closeTab(
                          tabsController.currentTab!.id,
                          forceClose: true,
                        );
                      } else {
                        print(
                          '🔖 No se cierra la pestaña: es la única abierta',
                        );
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
