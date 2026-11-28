// lib/features/invoices/presentation/screens/invoice_form_screen.dart
import 'package:baudex_desktop/app/core/diagnostics/action_timings.dart';
import 'package:baudex_desktop/app/core/diagnostics/paint_probe.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:baudex_desktop/app/core/utils/snackbar_policy.dart';
import 'package:baudex_desktop/features/invoices/presentation/widgets/modern_invoice_items_table.dart';
import 'package:baudex_desktop/features/invoices/presentation/widgets/enhanced_payment_dialog.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:baudex_desktop/app/core/utils/responsive.dart';
import 'package:baudex_desktop/app/core/utils/formatters.dart';
import 'package:baudex_desktop/app/core/theme/elegant_light_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../breb/presentation/widgets/breb_payment_dialog.dart';
import '../controllers/invoice_form_controller.dart';
import '../controllers/invoice_tabs_controller.dart';
import '../widgets/product_search_widget.dart';
import '../widgets/invoice_shortcut_keys.dart';
import '../widgets/customer_selector_widget.dart';
import '../widgets/items_scroll_math.dart';

class InvoiceFormScreen extends StatefulWidget {
  final InvoiceFormController? controller;

  const InvoiceFormScreen({super.key, this.controller});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  // Fila seleccionada (a la que van los atajos Ctrl+número). Vive en un
  // ValueNotifier que escucha SOLO la tabla: antes era estado de toda la
  // pantalla y cada escaneo o flecha redibujaba cliente, buscador, tabla y
  // totales (con 50+ líneas el lector se sentía trabado).
  final ValueNotifier<int> _selection = ValueNotifier<int>(-1);
  int get _selectedIndex => _selection.value;
  set _selectedIndex(int value) => _selection.value = value;
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

  // Escucha del último producto modificado; se libera en dispose().
  Worker? _updatedItemWorker;
  // Escucha de la lista de productos: mantiene siempre una fila elegida.
  Worker? _itemsWorker;

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
      _updatedItemWorker = ever(controller.lastUpdatedItemIndexObs, (
        int? index,
      ) {
        if (index != null && mounted) {
          _selectedIndex = normalizeSelectedIndex(
            index,
            controller.invoiceItems.length,
          );
          _scrollToSelectedWithDelay();
        }
      });
      // Cualquier cambio de la lista (agregar, quitar, vaciar, venta nueva,
      // abrir una factura para editar): que nunca quede sin fila elegida
      // habiendo productos, ni elegida una fila que ya no existe.
      _itemsWorker = ever(controller.invoiceItemsObs, (_) {
        if (mounted) _normalizeSelection();
      });
      // Al abrir la pantalla (o volver a esta pestaña) con productos ya
      // puestos: elegir el último tocado, o el de arriba.
      final count = controller.invoiceItems.length;
      _selectedIndex = normalizeSelectedIndex(
        controller.lastUpdatedItemIndex ?? _selectedIndex,
        count,
      );
    }
  }

  void _normalizeSelection() {
    final count = widget.controller?.invoiceItems.length ?? 0;
    _selectedIndex = normalizeSelectedIndex(_selectedIndex, count);
  }

  @override
  void didUpdateWidget(covariant InvoiceFormScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      // Otra factura (otra pestaña) en la misma pantalla: escuchar la nueva.
      _updatedItemWorker?.dispose();
      _itemsWorker?.dispose();
      _selectedIndex = -1;
      _setupUpdatedItemListener();
    }
  }

  @override
  void dispose() {
    // Unregister global keyboard handler
    ServicesBinding.instance.keyboard.removeHandler(_handleGlobalKeyEvent);
    // Sin esto, cada cambio de pestaña dejaba una escucha viva en el
    // controlador (y con ella, esta pantalla completa en memoria).
    _updatedItemWorker?.dispose();
    _itemsWorker?.dispose();
    _productsScrollController.dispose();
    _selection.dispose();
    super.dispose();
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (!mounted) return false;
    // Dígito sin Ctrl: no es un atajo (lo escribe el cajero o el lector).
    if (isPlainDigitKey(event.logicalKey,
        modifierPressed: shortcutModifierPressed())) {
      return false;
    }

    final controller = widget.controller;
    if (controller == null || controller.invoiceItems.isEmpty) return false;

    // ✅ NUEVO: No procesar shortcuts si hay un dialog activo
    // Verificar si hay un overlay activo (como un Dialog)
    final overlay = Overlay.of(context);
    if (overlay.mounted && ModalRoute.of(context)?.isCurrent != true) {
      return false;
    }

    // ✅ CRÍTICO: No procesar Enter si el ProductSearchWidget está activo
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
      final focusedWidget = FocusManager.instance.primaryFocus?.context?.widget;
      if (focusedWidget != null &&
          focusedWidget.toString().contains('TextField')) {
        return false;
      }
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

      // ✅ SHORTCUTS ACTUALIZADOS: Solo con Control presionado (NATIVO)
      if (_selectedIndex >= 0 &&
          _selectedIndex < controller.invoiceItems.length) {
        // ✅ USAR FLUTTER NATIVO para detectar Ctrl presionado
        final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;

        // Shortcuts SOLO con Control presionado (NATIVO)
        if (isCtrlPressed) {
          // Ctrl + "+" / Ctrl + "=" / "+" del teclado numérico: suma 1.
          // Ctrl + "-" / "-" del teclado numérico: resta 1.
          final delta = quantityShortcutDelta(
            event.logicalKey,
            character: event.character,
          );
          if (delta == 1) {
            _incrementQuantity(1, controller);
            return true;
          }
          if (delta == -1) {
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
            // TODO: Implementar acción específica para Ctrl + T
            return true;
          }

          // Ctrl + W - NATIVO (nuevo shortcut)
          if (event.logicalKey == LogicalKeyboardKey.keyW) {
            // Acción para Ctrl + W (puedes definir qué hace)
            // TODO: Implementar acción específica para Ctrl + W
            return true;
          }

          // Ctrl + Tab - NATIVO (nuevo shortcut)
          if (event.logicalKey == LogicalKeyboardKey.tab) {
            // Acción para Ctrl + Tab (puedes definir qué hace)
            // TODO: Implementar acción específica para Ctrl + Tab
            return true;
          }

          // Ctrl + Enter para procesar venta - NATIVO
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            // ✅ VERIFICACIÓN: Asegurar que no haya focus en TextField
            final focusedWidget =
                FocusManager.instance.primaryFocus?.context?.widget;
            if (focusedWidget != null &&
                focusedWidget.toString().contains('TextField')) {
              return false;
            }

            // ✅ NUEVO: Evitar eventos Enter duplicados o propagados
            final now = DateTime.now();
            if (_lastEnterEvent != null &&
                now.difference(_lastEnterEvent!).inMilliseconds < 500) {
              return false;
            }
            _lastEnterEvent = now;

            if (controller.canSave && !controller.isSaving) {
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

    _selectedIndex = (_selectedIndex + direction).clamp(
      0,
      controller.invoiceItems.length - 1,
    );

    // Hacer scroll automático para que el elemento seleccionado sea visible
    _scrollToSelected();
  }

  void _moveToFirst(InvoiceFormController controller) {
    if (controller.invoiceItems.isNotEmpty) {
      _selectedIndex = 0;
      _scrollToSelected();
    }
  }

  void _moveToLast(InvoiceFormController controller) {
    if (controller.invoiceItems.isNotEmpty) {
      _selectedIndex = controller.invoiceItems.length - 1;
      _scrollToSelected();
    }
  }

  // Lleva la fila elegida a la vista (flechas, Inicio/Fin, re-escaneo).
  // Antes suponía filas de 54 px; miden ~36 en escritorio y ~41 en celular,
  // así que con muchas líneas la fila re-escaneada quedaba fuera de la vista.
  // Ahora se mide la fila real: alto total del contenido / número de filas.
  void _scrollToSelected() {
    if (!_productsScrollController.hasClients || _selectedIndex < 0) return;
    final count = widget.controller?.invoiceItems.length ?? 0;
    if (count == 0) return;
    final position = _productsScrollController.position;
    final target = scrollOffsetToReveal(
      index: _selectedIndex.clamp(0, count - 1),
      itemCount: count,
      contentExtent: position.maxScrollExtent + position.viewportDimension,
      viewportExtent: position.viewportDimension,
      currentOffset: position.pixels,
    );
    if (target == null) return;
    _productsScrollController.animateTo(
      target.clamp(0.0, position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  // ✅ NUEVO: Método para hacer scroll con delay para productos actualizados
  void _scrollToSelectedWithDelay() {
    // Dar un breve delay para que las animaciones de UI se completen primero
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _scrollToSelected();
      }
    });
  }

  void _incrementQuantity(int increment, InvoiceFormController controller) {
    if (_selectedIndex >= 0 &&
        _selectedIndex < controller.invoiceItems.length) {
      final item = controller.invoiceItems[_selectedIndex];
      final newQuantity = item.quantity + increment;

      // ⚠️ La validación de stock SOLO aplica si el tenant tiene activa
      // la preferencia `validateStockBeforeInvoice` y NO tiene activado
      // `allowOverselling`. Esa misma lógica está centralizada en
      // `controller.shouldValidateStock` — el resto del form ya la
      // respeta (handleProductSelection, búsqueda visual de items
      // sin stock, etc). Antes este atajo Ctrl++ la ignoraba: el
      // cajero veía "Stock insuficiente" aunque hubiera configurado
      // su negocio para vender sin stock. Ahora se alinea.
      final product = controller.availableProducts.firstWhereOrNull(
        (p) => p.id == item.productId,
      );

      if (controller.shouldValidateStock &&
          product != null &&
          !_isTemporaryProduct(product)) {
        if (newQuantity > product.stock) {
          replacePreviousSnackbar();
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
      // Devolver focus al searchbox — el atajo de teclado puede haber
      // sido invocado mientras el cajero seguía con el cursor allí, no
      // queremos que el rebuild pierda la posición.
      _productSearchKey.currentState?.requestFocus();
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
      // Mantener focus en el searchbox tras el atajo de teclado.
      _productSearchKey.currentState?.requestFocus();
    }
  }

  void _setExactQuantity(double quantity, InvoiceFormController controller) {
    if (_selectedIndex >= 0 &&
        _selectedIndex < controller.invoiceItems.length) {
      final item = controller.invoiceItems[_selectedIndex];

      // Misma lógica que `_incrementQuantity`: respetar la preferencia
      // del tenant antes de bloquear por stock.
      final product = controller.availableProducts.firstWhereOrNull(
        (p) => p.id == item.productId,
      );

      if (controller.shouldValidateStock &&
          product != null &&
          !_isTemporaryProduct(product)) {
        if (quantity > product.stock) {
          replacePreviousSnackbar();
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
      _productSearchKey.currentState?.requestFocus();
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
        _selectedIndex = _selectedIndex.clamp(
          0,
          controller.invoiceItems.length - 1,
        );
      } else {
        _selectedIndex = -1;
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
    // Lo que no está en una capa propia (fondo, textos de la barra…): si
    // esto se pinta con cada tecla, algo de afuera se está ensuciando.
    return PaintProbe(
      name: 'factura: resto de la pantalla',
      child: Scaffold(
      appBar: _buildAppBar(context, controller),
      backgroundColor: Colors.transparent,
      body: Container(
        // Llena todo el alto: en celular el degradado terminaba donde
        // terminaba el contenido y abajo quedaba una franja vacía.
        constraints: const BoxConstraints.expand(),
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
                  // Capa propia: lo que se reacomoda adentro no repinta
                  // el fondo degradado ni la barra superior.
                  : PaintProbe(
                    name: 'factura: cuerpo',
                    child: _buildDesktopLayout(context, controller),
                  ),
        ),
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
              valueColor: AlwaysStoppedAnimation<Color>(
                ElegantLightTheme.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Alto mínimo para que en celular la tabla ocupe el espacio libre y el
  /// resumen quede abajo. Más bajo (teclado abierto, celular horizontal) se
  /// mantiene el desplazamiento de antes con la tabla de 250.
  static const double _mobileFillMinHeight = 560;

  // Layout para móviles
  Widget _buildMobileLayout(
    BuildContext context,
    InvoiceFormController controller,
  ) {
    final customer = CustomerSelectorWidget(
      key: _customerSelectorKey,
      selectedCustomer: controller.selectedCustomer,
      onCustomerSelected: controller.selectCustomer,
      onClearCustomer: controller.clearCustomer,
      controller: controller,
      onFocusChanged: (hasFocus) {
        // Coordinar el foco con ProductSearchWidget
        if (hasFocus) {
          _productSearchKey.currentState?.pauseFocusRestoration();
        } else {
          _productSearchKey.currentState?.resumeFocusRestoration();
        }
      },
    );
    final search = ProductSearchWidget(
      key: _productSearchKey,
      controller: controller,
      autoFocus: true,
      onProductSelected: (product, quantity) {
        // La fila la elige el controlador (nueva arriba o la que se
        // actualizó).
        controller.handleProductSelection(product, quantity: quantity);
      },
    );
    Widget table({double? height}) => ValueListenableBuilder<int>(
          valueListenable: _selection,
          builder: (context, selected, _) => ModernInvoiceItemsTable(
            controller: controller,
            selectedIndex: selected,
            onSelectionChanged: (index) => _selectedIndex = index,
            // Tras +/-/eliminar/seleccionar fila, regresar el cursor al
            // searchbox para el siguiente escaneo o búsqueda.
            onItemModified: () {
              _productSearchKey.currentState?.requestFocus();
            },
            // El mismo controlador que usa el re-escaneo para llevar la
            // fila actualizada a la vista.
            scrollController: _productsScrollController,
            height: height ?? 250,
          ),
        );
    final gap = SizedBox(height: context.verticalSpacing * 0.4);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight >= _mobileFillMinHeight) {
          return Padding(
            padding: context.responsivePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                customer,
                gap,
                search,
                gap,
                Expanded(child: table(height: double.infinity)),
                gap,
                _buildTotalsSection(context, controller),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              customer,
              gap,
              search,
              gap,
              table(),
              gap,
              _buildTotalsSection(context, controller),
            ],
          ),
        );
      },
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
          // Capa propia y casi vacía (sus hijos tienen la suya): cada tecla
          // del buscador reacomoda esta zona y, sin esta capa, eso obligaba
          // a repintar el fondo y la barra de toda la pantalla.
          child: PaintProbe(
            name: 'factura: zona de contenido',
            child: SingleChildScrollView(
            padding: context.responsivePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cada parte en su propia capa: al escribir en el buscador
                // solo se repinta el buscador, no el cliente, la tabla ni
                // los totales (antes se repintaba toda la pantalla por
                // tecla, y en equipos que pintan lento eso se nota).
                PaintProbe(
                  name: 'factura: cliente',
                  child: CustomerSelectorWidget(
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
                ),
                SizedBox(height: context.verticalSpacing * 0.4),
                PaintProbe(
                  name: 'factura: buscador',
                  child: ProductSearchWidget(
                  key: _productSearchKey,
                  controller: controller,
                  autoFocus: true,
                  onProductSelected: (product, quantity) {
                    controller.handleProductSelection(
                      product,
                      quantity: quantity,
                    );
                    // La fila la elige el controlador (nueva arriba o la
                    // que se actualizó): forzar la 0 mandaba el siguiente
                    // Ctrl+número a otro producto.
                  },
                  ),
                ),
                SizedBox(height: context.verticalSpacing * 0.4),
                // La tabla de productos con altura dinámica para desktop
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: PaintProbe(
                    name: 'factura: tabla de líneas',
                    child: ValueListenableBuilder<int>(
                    valueListenable: _selection,
                    builder:
                        (context, selected, _) => ModernInvoiceItemsTable(
                          controller: controller,
                          selectedIndex: selected,
                          onSelectionChanged: (index) => _selectedIndex = index,
                          // Tras +/-/eliminar/seleccionar fila, devolver el
                          // cursor al searchbox.
                          onItemModified: () {
                            _productSearchKey.currentState?.requestFocus();
                          },
                          scrollController:
                              _productsScrollController, // Para scroll automático
                        ),
                    ),
                  ),
                ),
              ],
            ),
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
            color: ElegantLightTheme.backgroundColor,
            border: Border(
              top: BorderSide(
                color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: PaintProbe(
            name: 'factura: totales',
            child: _buildTotalsSection(context, controller),
          ),
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
      flexibleSpace: PaintProbe(
        name: 'factura: barra superior (fondo)',
        child: Container(
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.primaryGradient,
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
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
          child: const Icon(Icons.point_of_sale, color: Colors.white, size: 18),
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
                      color: ElegantLightTheme.accentOrange.withValues(
                        alpha: 0.4,
                      ),
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
          child: const Icon(Icons.point_of_sale, color: Colors.white, size: 20),
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
                Icon(Icons.edit_note, color: Colors.white, size: 14),
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
                // Botón "Nueva venta" del AppBar: limpia el form Y
                // devuelve el focus al campo de búsqueda para que el
                // cajero pueda seguir escaneando sin tocar la pantalla.
                onTap: () {
                  controller.clearFormForNewSale();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _productSearchKey.currentState?.requestFocus();
                  });
                },
                // No robar focus al tap del botón mismo (mismo motivo
                // que los +/- de los items).
                canRequestFocus: false,
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
    return Obx(() {
      final canSave = controller.canSave && !controller.isSaving;
      return Container(
        decoration: BoxDecoration(
          gradient:
              canSave
                  ? ElegantLightTheme.successGradient
                  : LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.2),
                      Colors.white.withValues(alpha: 0.1),
                    ],
                  ),
          borderRadius: BorderRadius.circular(10),
          boxShadow:
              canSave
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
            onTap:
                canSave ? () => _showPaymentDialog(context, controller) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child:
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
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDesktopSaveButton(
    BuildContext context,
    InvoiceFormController controller,
  ) {
    return Obx(() {
      final canSave = controller.canSave && !controller.isSaving;
      return Tooltip(
        message: 'Procesar Venta (Ctrl+Enter)',
        child: Container(
          decoration: BoxDecoration(
            gradient:
                canSave
                    ? ElegantLightTheme.successGradient
                    : LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.2),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                    ),
            borderRadius: BorderRadius.circular(12),
            boxShadow:
                canSave
                    ? [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                    : null,
            border: Border.all(
              color:
                  canSave
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap:
                  canSave
                      ? () => _showPaymentDialog(context, controller)
                      : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
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
                      controller.isSaving
                          ? 'Procesando...'
                          : controller.saveButtonText,
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
    });
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
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
    final Color amountColor =
        isTotal
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
                color:
                    isTotal
                        ? ElegantLightTheme.textPrimary
                        : ElegantLightTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child:
                isTotal
                    ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
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

  /// Después de una venta: cierra la pestaña (si hay más de una) o limpia la
  /// factura y devuelve el cursor al buscador, para seguir escaneando.
  void _leaveReadyForNextSale(InvoiceFormController controller) {
    final tabsController = Get.find<InvoiceTabsController>();
    if (tabsController.currentTab == null) return;
    // Solo cerrar si hay más de una pestaña abierta.
    if (tabsController.tabs.length > 1) {
      tabsController.closeTab(tabsController.currentTab!.id, forceClose: true);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.clearFormForNewSale();
      // Segundo callback: el foco se pide DESPUÉS del redibujo que dispara la
      // limpieza (antes, el campo aún no está listo y el foco se pierde).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _productSearchKey.currentState?.requestFocus();
      });
    });
  }

  /// Cobro por Bre-B (se elige dentro del diálogo de pago): muestra el QR con
  /// el total y espera el aviso del banco. La venta se guarda en el servidor
  /// solo cuando el cliente paga; si cancela o vence, se vuelve al diálogo de
  /// pago con la misma venta.
  Future<void> _chargeWithBreb(
    BuildContext context,
    InvoiceFormController controller,
  ) async {
    final draft = await controller.buildBrebDraft();
    if (draft == null || !context.mounted) return;

    final invoiceId = await BrebPaymentDialog.showForSale(
      context,
      draft: draft,
      amount: controller.total,
    );
    if (invoiceId == null) {
      // No se pagó (canceló o venció): se vuelve al diálogo de pago para
      // cobrar la misma venta de otra forma.
      if (mounted && context.mounted) _showPaymentDialog(context, controller);
      return;
    }

    final invoice = await controller.completeBrebSale(invoiceId);
    if (!mounted) return;
    _leaveReadyForNextSale(controller);
    replacePreviousSnackbar();
    Get.snackbar(
      'Venta pagada por Bre-B',
      invoice != null
          ? 'Factura ${invoice.number} registrada y pagada.'
          : 'El pago se confirmó y la venta quedó registrada. Aparecerá en la lista al sincronizar.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.check_circle, color: Colors.green),
      duration: const Duration(seconds: 4),
    );
  }

  void _showPaymentDialog(
    BuildContext context,
    InvoiceFormController controller,
  ) {
    // Solo mide: de tocar Procesar a que el diálogo de pago ya se ve.
    final opening = ActionTimings.instance.start('Abrir diálogo de pago');
    WidgetsBinding.instance.addPostFrameCallback((_) => opening.end());
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => EnhancedPaymentDialog(
            total: controller.total,
            customerName: controller.selectedCustomer?.displayName,
            customerId: controller.selectedCustomer?.id,
            customerCreditLimit: controller.selectedCustomer?.creditLimit ?? 0,
            customerCurrentBalance:
                controller.selectedCustomer?.currentBalance ?? 0,
            onPaymentConfirmed: (
              amount,
              change,
              paymentMethod,
              status,
              shouldPrint, {
              String? bankAccountId,
              List<MultiplePaymentData>? multiplePayments,
              bool? createCreditForRemaining,
              double? balanceApplied,
              String? paymentCurrency,
              double? paymentCurrencyAmount,
              double? exchangeRate,
            }) async {
              if (paymentCurrency != null) {}

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
                  balanceApplied: balanceApplied,
                  paymentCurrency: paymentCurrency,
                  paymentCurrencyAmount: paymentCurrencyAmount,
                  exchangeRate: exchangeRate,
                );

                // ✅ SOLO CONTINUAR SI LA OPERACIÓN FUE EXITOSA
                if (success) {
                  // ✅ NOTA: El diálogo ya se cerró automáticamente en _confirmPayment

                  // ✅ NUEVO: Cerrar la pestaña automáticamente después de procesar venta
                  // Solo cerrar si no es borrador Y si hay más de una pestaña abierta
                  if (status != InvoiceStatus.draft) {
                    _leaveReadyForNextSale(controller);
                  }

                  // ✅ MOSTRAR MENSAJE DE ÉXITO SOLO SI LA OPERACIÓN FUE EXITOSA
                  replacePreviousSnackbar();
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
                  // El controller llama _showError() cuando hay un ServerFailure,
                  // pero si retorna false por cualquier otra razón sin mostrar nada,
                  // mostramos un snackbar genérico de fallback para que el usuario
                  // nunca quede mirando una pantalla sin respuesta.
                  if (!Get.isSnackbarOpen) {
                    replacePreviousSnackbar();
                    Get.snackbar(
                      'No se procesó la venta',
                      'Verifica los datos e intenta nuevamente.',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: Colors.red.shade100,
                      colorText: Colors.red.shade800,
                      icon: const Icon(Icons.error_outline, color: Colors.red),
                      duration: const Duration(seconds: 4),
                    );
                  }
                }
              } catch (e) {
                // ✅ NOTA: El diálogo ya se cerró automáticamente en _confirmPayment

                replacePreviousSnackbar();
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
            // Bre-B es una opción más del diálogo de pago (solo si el negocio
            // tiene llaves configuradas y es una venta nueva).
            onBrebRequested:
                controller.canChargeWithBreb
                    ? () => _chargeWithBreb(context, controller)
                    : null,
          ),
    );
  }
}
