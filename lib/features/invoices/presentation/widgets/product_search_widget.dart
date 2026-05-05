// lib/features/invoices/presentation/widgets/product_search_widget.dart
import 'dart:async';
import 'package:baudex_desktop/app/shared/screens/barcode_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/services/audio_notification_service.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_price.dart';
import '../../../products/domain/entities/tax_enums.dart';
import '../controllers/invoice_form_controller.dart';

class ProductSearchWidget extends StatefulWidget {
  final InvoiceFormController controller;
  final Function(Product product, double quantity) onProductSelected;
  final bool autoFocus;
  final String? hint;

  const ProductSearchWidget({
    super.key,
    required this.controller,
    required this.onProductSelected,
    this.autoFocus = false,
    this.hint,
  });

  @override
  State<ProductSearchWidget> createState() => ProductSearchWidgetState();
}

class ProductSearchWidgetState extends State<ProductSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode(); // Para el TextField
  final FocusNode _keyboardFocusNode = FocusNode(); // ✅ NUEVO: Para el RawKeyboardListener
  final List<Product> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  String _lastSearchTerm = '';

  // ✅ NUEVO: Variables para navegación por teclado
  int _selectedResultIndex = -1;
  final ScrollController _resultsScrollController = ScrollController();

  // Timer para debounce
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  // Control para pausar la restauración automática de focus.
  // El padre (ej: CustomerSelectorWidget) lo puede activar mientras el
  // usuario está editando otros campos.
  bool _pauseFocusRestoration = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // Reaccionar SOLO cuando el focus realmente cambia (no en un timer).
    _focusNode.addListener(_onFocusChanged);

    _initializeAudioService();

    // Auto focus al abrir la pantalla — un solo intento, sin timer continuo.
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _focusNode.requestFocus();
        });
      });
    }
  }

  /// Reacciona a cambios de focus del campo de búsqueda. Diseñado para
  /// barcode scanning: si el campo perdió focus pero NADIE más lo tomó,
  /// lo recuperamos para que el siguiente escaneo siga llegando aquí.
  /// Si otro campo (cliente, cantidad, etc) tomó focus, lo respetamos.
  void _onFocusChanged() {
    if (!mounted || _pauseFocusRestoration) return;
    if (_focusNode.hasFocus) return;
    if (_hasModalRouteAbove()) return;

    // Si OTRO widget (otro TextField, botón con focus) tiene primary focus,
    // no robarlo. Solo restaurar si nadie más lo tiene.
    final primary = FocusManager.instance.primaryFocus;
    if (primary != null && primary != _focusNode) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pauseFocusRestoration) return;
      if (_focusNode.hasFocus) return;
      if (_hasModalRouteAbove()) return;
      if (FocusManager.instance.primaryFocus != null &&
          FocusManager.instance.primaryFocus != _focusNode) return;
      _focusNode.requestFocus();
    });
  }

  /// ✅ NUEVO: Inicializar servicio de notificaciones de audio
  Future<void> _initializeAudioService() async {
    try {
      await AudioNotificationService.instance.initialize();
      print('🔊 ProductSearchWidget: Servicio de audio inicializado para notificaciones');
    } catch (e) {
      print('⚠️ ProductSearchWidget: Error al inicializar audio: $e');
    }
  }

  @override
  void dispose() {
    try {
      _debounceTimer?.cancel();

      _searchController.removeListener(_onSearchChanged);
      _focusNode.removeListener(_onFocusChanged);

      _searchController.dispose();
      _focusNode.dispose();
      _keyboardFocusNode.dispose();
      _resultsScrollController.dispose();
    } catch (e) {
      print('⚠️ Error en dispose de ProductSearchWidget: $e');
    }
    super.dispose();
  }

  // ✅ NUEVO: Verificar si hay rutas modales abiertas (dialogs)
  bool _hasModalRouteAbove() {
    try {
      final overlay = Overlay.of(context);
      return ModalRoute.of(context)?.isCurrent != true;
    } catch (e) {
      return false; // Si hay error, asumir que no hay modal
    }
  }

  // ✅ MEJORADO: Focus manual cuando sea necesario
  void _ensureSearchFieldFocus() {
    if (mounted && !_focusNode.hasFocus && !_hasModalRouteAbove()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasModalRouteAbove()) {
          _focusNode.requestFocus();
          print('🔍 Focus asegurado en campo de búsqueda');
        }
      });
    }
  }

  // ✅ NUEVO: Pausar temporalmente la restauración automática de focus
  void pauseFocusRestoration() {
    _pauseFocusRestoration = true;
    print('🔍 Focus restauración pausada - otros campos pueden tomar control');
  }

  // ✅ NUEVO: Reanudar la restauración automática de focus
  void resumeFocusRestoration() {
    _pauseFocusRestoration = false;
    print('🔍 Focus restauración reanudada - monitoreo activo');
  }

  // ✅ NUEVO: Auto-seleccionar texto completo para códigos de barras
  void _autoSelectBarcodeText() {
    if (!mounted || _searchController.text.isEmpty) return;
    
    try {
      // Programar la selección para el siguiente frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _searchController.text.isNotEmpty) {
          _searchController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _searchController.text.length,
          );
          print('✅ Texto auto-seleccionado: "${_searchController.text}"');
          
          // Asegurar focus después de seleccionar
          if (!_focusNode.hasFocus && !_hasModalRouteAbove()) {
            _focusNode.requestFocus();
          }
        }
      });
    } catch (e) {
      print('⚠️ Error auto-seleccionando texto: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          // Header con tema elegante
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 12,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Productos',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (_isSearching)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ElegantLightTheme.primaryBlue,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Campo de búsqueda principal con escáner
          _buildSearchField(context),

          // Resultados de búsqueda
          if (_showResults && _searchResults.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildSearchResults(context),
          ],

          // Opción de producto sin registrar o mensaje de no resultados
          if (_showResults && _searchResults.isEmpty && !_isSearching) ...[
            const SizedBox(height: 6),
            _buildUnregisteredProductOption(context),
          ],

        // Tips de uso cuando no hay búsqueda
        if (!_showResults && _searchController.text.isEmpty) ...[
          const SizedBox(height: 8),
          _buildUsageTips(context),
        ],
      ],
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final isMobileOrTablet = context.isMobile || Responsive.isTablet(context);

    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focusNode.hasFocus
              ? ElegantLightTheme.primaryBlue.withOpacity(0.5)
              : ElegantLightTheme.textTertiary.withOpacity(0.2),
          width: _focusNode.hasFocus ? 2 : 1,
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Focus(
        onKeyEvent: (FocusNode node, KeyEvent event) {
          // ✅ CRÍTICO: Interceptar Enter ANTES de que llegue al TextField
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
            if (_showResults && _searchResults.isNotEmpty && _selectedResultIndex >= 0) {
              print('🚫 INTERCEPTANDO Enter - hay selección activa ($_selectedResultIndex)');
              final selectedProduct = _searchResults[_selectedResultIndex];
              if (!widget.controller.shouldValidateStock || selectedProduct.stock > 0) {
                _selectProduct(selectedProduct);
              }
              return KeyEventResult.handled; // ✅ Bloquear propagación
            }
          }
          return KeyEventResult.ignored; // ✅ Permitir propagación normal
        },
        child: RawKeyboardListener(
          focusNode: _keyboardFocusNode, // ✅ NUEVO: FocusNode separado para navegación
          onKey: _handleKeyboardNavigation,
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ElegantLightTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: widget.hint ?? 'Buscar...',
              hintStyle: const TextStyle(
                color: ElegantLightTheme.textTertiary,
                fontSize: 11,
              ),
              // Icono de búsqueda a la izquierda
              prefixIcon: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.search,
                  color: ElegantLightTheme.primaryBlue,
                  size: 22,
                ),
              ),
              // Icono de escáner QR DENTRO del search a la derecha
              suffixIcon: Padding(
                padding: const EdgeInsets.all(6),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isMobileOrTablet ? _openBarcodeScanner : null,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: ElegantLightTheme.glowShadow,
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
            onSubmitted: (value) {
              // ✅ CRÍTICO: Solo procesar onSubmitted si no hay selección activa
              if (_selectedResultIndex < 0) {
                print('🔍 SUBMIT: Procesando sin selección activa');
                _handleDirectSearch(value);
              } else {
                print('🔍 SUBMIT: Hay selección activa ($_selectedResultIndex) - procesando producto seleccionado');
                // Si hay selección activa, procesar ese producto en lugar de buscar
                final selectedProduct = _searchResults[_selectedResultIndex];
                if (!widget.controller.shouldValidateStock || selectedProduct.stock > 0) {
                  _selectProduct(selectedProduct);
                }
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withOpacity(0.2),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.builder(
          controller: _resultsScrollController, // ✅ NUEVO: Usar scroll controller
          shrinkWrap: true,
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final product = _searchResults[index];
            final isSelected =
                index ==
                _selectedResultIndex; // ✅ NUEVO: Verificar si está seleccionado
            return _buildProductTile(context, product, isSelected: isSelected);
          },
        ),
      ),
    );
  }

  Widget _buildProductTile(
    BuildContext context,
    Product product, {
    bool isSelected = false,
  }) {
    final hasStock = product.stock > 0;
    final canSelect = hasStock || !widget.controller.shouldValidateStock;
    final price = product.sellingPrice ?? 0.0;

    // Tamaños responsive
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    // Configuración de tamaños según pantalla
    final double iconSize = isMobile ? 32 : (isTablet ? 36 : 40);
    final double iconInnerSize = isMobile ? 16 : (isTablet ? 18 : 20);
    final double nameSize = isMobile ? 12 : (isTablet ? 13 : 14);
    final double priceSize = isMobile ? 12 : (isTablet ? 13 : 14);
    final double stockSize = isMobile ? 8 : (isTablet ? 9 : 10);
    final double padding = isMobile ? 6 : (isTablet ? 8 : 10);
    final double actionSize = isMobile ? 28 : (isTablet ? 32 : 36);
    final double actionIconSize = isMobile ? 14 : (isTablet ? 16 : 18);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 4, vertical: 1),
      child: Material(
        color: isSelected
            ? ElegantLightTheme.primaryBlue.withOpacity(0.08)
            : canSelect
                ? ElegantLightTheme.surfaceColor
                : ElegantLightTheme.cardColor,
        borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
          onTap: canSelect ? () => _selectProduct(product) : () {
            print('🔊 Producto sin stock: ${product.name}');
          },
          child: Container(
            decoration: isSelected
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                    border: Border.all(
                      color: ElegantLightTheme.primaryBlue,
                      width: 1.5,
                    ),
                  )
                : null,
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Row(
                children: [
                  // Icono de producto compacto
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      gradient: canSelect
                          ? ElegantLightTheme.primaryGradient
                          : ElegantLightTheme.glassGradient,
                      borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      color: canSelect
                          ? Colors.white
                          : ElegantLightTheme.textTertiary,
                      size: iconInnerSize,
                    ),
                  ),
                  SizedBox(width: isMobile ? 8 : 10),

                  // Información del producto - DOS FILAS
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // FILA 1: Nombre del producto
                        Text(
                          product.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: nameSize,
                            color: canSelect
                                ? ElegantLightTheme.textPrimary
                                : ElegantLightTheme.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isMobile ? 2 : 3),

                        // FILA 2: Precio + Stock
                        Row(
                          children: [
                            // Precio
                            Text(
                              AppFormatters.formatCurrency(price),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: priceSize,
                                color: canSelect
                                    ? ElegantLightTheme.primaryBlue
                                    : ElegantLightTheme.textTertiary,
                              ),
                            ),
                            SizedBox(width: isMobile ? 6 : 8),
                            // Stock badge
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 5 : 6,
                                vertical: isMobile ? 2 : 3,
                              ),
                              decoration: BoxDecoration(
                                gradient: hasStock
                                    ? ElegantLightTheme.successGradient
                                    : ElegantLightTheme.errorGradient,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                hasStock
                                    ? '${AppFormatters.formatStock(product.stock)}'
                                    : 'Sin stock',
                                style: TextStyle(
                                  fontSize: stockSize,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Botón de acción compacto
                  Container(
                    width: actionSize,
                    height: actionSize,
                    decoration: BoxDecoration(
                      gradient: canSelect
                          ? ElegantLightTheme.successGradient
                          : ElegantLightTheme.errorGradient,
                      borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                    ),
                    child: Icon(
                      canSelect ? Icons.add : Icons.block,
                      color: Colors.white,
                      size: actionIconSize,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnregisteredProductOption(BuildContext context) {
    final searchValue = _searchController.text.trim();
    final isUnregisteredProduct = _isUnregisteredProductQuery(searchValue);

    if (!isUnregisteredProduct) {
      return _buildNoResultsMessage();
    }

    final price = double.tryParse(searchValue) ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ElegantLightTheme.primaryBlue.withOpacity(0.08),
            ElegantLightTheme.primaryBlue.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _createUnregisteredProduct(price),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icono con gradiente
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.infoGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: ElegantLightTheme.glowShadow,
                  ),
                  child: const Icon(
                    Icons.add_shopping_cart,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Información
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Producto sin registrar',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: ElegantLightTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Precio: ${AppFormatters.formatCurrency(price)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: ElegantLightTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Icono de acción con gradiente
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ElegantLightTheme.accentOrange.withOpacity(0.1),
            ElegantLightTheme.accentOrange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.accentOrange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.warningGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.search_off,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No se encontraron productos para "${_searchController.text}"',
              style: const TextStyle(
                fontSize: 12,
                color: ElegantLightTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageTips(BuildContext context) {
    return const SizedBox.shrink(); // Vacío, sin tips innecesarios
  }

  // ==================== NAVEGACIÓN POR TECLADO ====================

  void _handleKeyboardNavigation(RawKeyEvent event) {
    // ✅ MEJORADO: Solo manejar navegación cuando hay resultados, sin quitar focus del TextField
    if (event is RawKeyDownEvent && _showResults && _searchResults.isNotEmpty) {
      print('🎹 Navegación detectada: ${event.logicalKey} - Resultados: ${_searchResults.length}');
      
      // Flecha hacia abajo
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedResultIndex = (_selectedResultIndex + 1).clamp(
            0,
            _searchResults.length - 1,
          );
          _scrollToSelected();
        });
        print('⬇️ Seleccionado: $_selectedResultIndex/${_searchResults.length - 1}');
        return;
      }

      // Flecha hacia arriba
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedResultIndex = (_selectedResultIndex - 1).clamp(
            0,
            _searchResults.length - 1,
          );
          _scrollToSelected();
        });
        print('⬆️ Seleccionado: $_selectedResultIndex/${_searchResults.length - 1}');
        return;
      }

      // ✅ REMOVIDO: Enter handling se hace ahora en el Focus widget superior
    }
  }

  void _scrollToSelected() {
    if (_selectedResultIndex >= 0 && _resultsScrollController.hasClients) {
      // Altura compacta según responsive
      final isMobile = Responsive.isMobile(context);
      final double itemHeight = isMobile ? 48.0 : 56.0; // Altura más compacta
      final double targetOffset = _selectedResultIndex * itemHeight;

      _resultsScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  // ==================== LÓGICA DE BÚSQUEDA ====================

  void _onSearchChanged() {
    // Verificar que el widget esté montado y el controlador disponible
    if (!mounted) {
      print('⚠️ ProductSearchWidget: Widget no montado, cancelando búsqueda');
      return;
    }
    
    try {
      // ✅ NUEVO: Asegurar que el focus permanezca en el TextField mientras se escribe
      if (_focusNode.canRequestFocus && !_focusNode.hasFocus) {
        _ensureSearchFieldFocus();
      }
      
      // Cancelar timer anterior si existe
      _debounceTimer?.cancel();

      final query = _searchController.text.trim();

      // ✅ No auto-seleccionar durante la escritura para evitar cortar el código

    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _showResults = false;
        _isSearching = false;
        _lastSearchTerm = '';
        _selectedResultIndex = -1; // ✅ NUEVO: Resetear selección
      });
      return;
    }

    // ✅ NUEVO: Si el usuario está escribiendo y hay resultados visibles, resetear selección
    if (_showResults && _searchResults.isNotEmpty && query != _lastSearchTerm) {
      setState(() {
        _selectedResultIndex = -1; // Resetear selección mientras escribe
      });
      print('⌨️ Usuario escribiendo, selección reseteada');
    }

      // Crear nuevo timer con debounce
      _debounceTimer = Timer(_debounceDuration, () {
        _performSearch(query);
      });
    } catch (e) {
      print('⚠️ Error en _onSearchChanged (ProductSearchWidget): $e');
      // Cancelar timer si hay error
      _debounceTimer?.cancel();
    }
  }

  Future<void> _performSearch(String query) async {
    // Evitar búsquedas repetidas
    if (query == _lastSearchTerm) return;
    _lastSearchTerm = query;

    // Búsqueda mínima de 2 caracteres
    if (query.length < 2) {
      setState(() {
        _searchResults.clear();
        _showResults =
            true; // Mostrar para que aparezca la opción de producto sin registrar
      });
      return;
    }

    if (widget.controller.isLoadingProducts) {
      print('⚠️ Productos aún cargando, esperando...');
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      List<Product> results = [];
      
      // Verificar si el query es un código de barras (>7 dígitos) o precio (≤7 dígitos)
      final isBarcode = _isBarcodeQuery(query);
      final isUnregisteredProduct = _isUnregisteredProductQuery(query);
      
      if (isBarcode) {
        // Búsqueda por código de barras para números >7 dígitos
        print('🔍 Búsqueda por código de barras: $query');
        
        // 1. Primero buscar localmente
        final exactMatch = await _searchByBarcode(query);
        if (exactMatch != null) {
          results.add(exactMatch);
        }
        
        // 2. Si no se encuentra localmente, buscar en la API
        if (exactMatch == null) {
          print('🌐 Código de barras no encontrado localmente, buscando en API...');
          final apiResults = await widget.controller.searchProducts(query);
          results.addAll(apiResults);
        }
        
        // Si hay resultados después de búsqueda local + API, agregar automáticamente el primero
        if (results.isNotEmpty) {
          final productToAdd = results.first;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && _searchResults.isNotEmpty) {
                _selectProduct(productToAdd);
              }
            });
          });
        } else {
          // Solo mensaje de log, SIN audio para códigos de barras no encontrados
          print('🔊 Código de barras no encontrado');
        }
      } else if (!isUnregisteredProduct) {
        // Búsqueda normal para texto y números que no son códigos de barras ni precios
        
        // 1. Búsqueda por SKU exacto
        final skuMatch = await _searchBySku(query);
        if (skuMatch != null) {
          results.add(skuMatch);
        }

        // 2. Búsqueda general usando el controlador (solo para búsquedas de texto)
        final searchResults = await widget.controller.searchProducts(query);
        results.addAll(searchResults);
      }
      // Si isUnregisteredProduct es true, no agregamos resultados para que aparezca la opción de producto sin registrar

      // Eliminar duplicados y limitar resultados
      final uniqueResults = <String, Product>{};
      for (final product in results) {
        uniqueResults[product.id] = product;
      }

      if (mounted) {
        setState(() {
          _searchResults.clear();
          _searchResults.addAll(uniqueResults.values.take(8));
          _showResults = true;
          _isSearching = false;
          _selectedResultIndex =
              _searchResults.isNotEmpty
                  ? 0
                  : -1;
        });
        
        // Activar keyboard focus cuando hay resultados PERO mantener TextField focus
        if (_searchResults.isNotEmpty) {
          _ensureSearchFieldFocus();
        }
        
        // ✅ NUEVO: Audio y auto-selección para códigos de barras no encontrados
        if (isBarcode && _searchResults.isEmpty) {
          // Reproducir audio "Producto no encontrado" para códigos de barras
          AudioNotificationService.instance.announceProductNotFound();
          print('🔊 Código de barras no encontrado - Reproduciendo audio');
          
          // Auto-seleccionar cuando no se encontró el código de barras para facilitar reemplazo
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _autoSelectBarcodeText();
              print('🔍 Código de barras no encontrado - Texto auto-seleccionado para reemplazo');
            }
          });
        }
      }

      print(
        '✅ Búsqueda completada: ${_searchResults.length} productos encontrados (Código barras: $isBarcode, Producto sin registrar: $isUnregisteredProduct)',
      );
    } catch (e) {
      print('❌ Error en búsqueda de productos: $e');
      if (mounted) {
        setState(() {
          _searchResults.clear();
          _showResults = true;
          _isSearching = false;
        });
        
        // ✅ MEJORADO: Mantener focus incluso cuando hay errores
        if (_isBarcodeQuery(query)) {
          _ensureSearchFieldFocus();
          print('🔍 Focus mantenido después de error en búsqueda de código de barras (SIN audio)');
        }
      }
    }
  }

  Future<Product?> _searchByBarcode(String barcode) async {
    try {
      if (widget.controller.isLoadingProducts) {
        return null;
      }

      final products = widget.controller.availableProducts;
      return products.firstWhereOrNull(
        (product) => product.barcode?.toLowerCase() == barcode.toLowerCase(),
      );
    } catch (e) {
      print('❌ Error en búsqueda por código de barras: $e');
      return null;
    }
  }

  Future<Product?> _searchBySku(String sku) async {
    try {
      if (widget.controller.isLoadingProducts) {
        return null;
      }

      final products = widget.controller.availableProducts;
      return products.firstWhereOrNull(
        (product) => product.sku.toLowerCase() == sku.toLowerCase(),
      );
    } catch (e) {
      print('❌ Error en búsqueda por SKU: $e');
      return null;
    }
  }

  void _handleDirectSearch(String query) {
    if (query.trim().isEmpty) return;

    // Si hay resultados, seleccionar el primero
    if (_searchResults.isNotEmpty) {
      _selectProduct(_searchResults.first);
    } else if (_isUnregisteredProductQuery(query)) {
      // Si es un número ≤7 dígitos y no hay resultados, crear producto sin registrar
      final price = double.tryParse(query) ?? 0.0;
      _createUnregisteredProduct(price);
    }
  }

  // ==================== FUNCIONES AUXILIARES ====================

  bool _isNumericValue(String value) {
    return double.tryParse(value) != null;
  }
  
  bool _isBarcodeQuery(String value) {
    // Códigos de barras: números con más de 7 dígitos
    if (!_isNumericValue(value)) return false;
    String digitsOnly = value.replaceAll('.', '').replaceAll(',', '');
    return RegExp(r'^\d{8,}$').hasMatch(digitsOnly);
  }
  
  bool _isUnregisteredProductQuery(String value) {
    // Productos sin registrar: números con 7 dígitos o menos
    if (!_isNumericValue(value)) return false;
    String digitsOnly = value.replaceAll('.', '').replaceAll(',', '');
    return RegExp(r'^\d{1,7}$').hasMatch(digitsOnly);
  }

  void _createUnregisteredProduct(double price) {
    // ✅ NUEVO: Notificación de voz para productos sin registrar
    AudioNotificationService.instance.announceProductNotRegistered();
    print('🔊 Creando producto sin registrar con precio: ${AppFormatters.formatCurrency(price)}');
    
    _showProductNameDialog(price);
  }

  void _showProductNameDialog(double price) {
    final TextEditingController nameController = TextEditingController();
    nameController.text = 'Producto sin registrar';

    // Seleccionar todo el texto cuando se abra el diálogo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nameController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: nameController.text.length,
      );
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.add_shopping_cart,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text('Nuevo Producto'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Precio: ${AppFormatters.formatCurrency(price)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nombre del producto:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  maxLength: 100,
                  decoration: InputDecoration(
                    hintText: 'Escribe el nombre del producto...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      Navigator.of(context).pop();
                      _createProductWithName(value.trim(), price);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // ✅ MEJORADO: Mantener focus para continuar escaneando después de cancelar
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _ensureSearchFieldFocus();
                      print('🔍 Focus restaurado después de cancelar diálogo');
                    }
                  });
                },
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    Navigator.of(context).pop();
                    _createProductWithName(name, price);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Agregar'),
              ),
            ],
          ),
    );
  }

  void _createProductWithName(String productName, double price) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final unregisteredProduct = Product(
      id: 'temp_$timestamp',
      name: productName,
      sku: 'TEMP-$timestamp',
      description: 'Producto no registrado en inventario',
      type: ProductType.product,
      status: ProductStatus.active,
      stock: 999, // Stock "infinito" para productos temporales
      minStock: 0,
      unit: 'pcs',
      isTaxable: false,
      taxRate: 0,
      taxCategory: TaxCategory.noGravado,
      barcode: null,
      weight: null,
      length: null,
      width: null,
      height: null,
      images: null,
      metadata: {
        'isTemporary': true,
        'originalPrice': price,
        'createdInPOS': true,
      },
      categoryId: 'temp-category',
      createdById: 'system',
      prices: [
        ProductPrice(
          id: 'temp_price_$timestamp',
          type: PriceType.price1,
          name: 'Precio Temporal',
          amount: price,
          currency: 'COP',
          status: PriceStatus.active,
          validFrom: DateTime.now(),
          validTo: null,
          discountPercentage: 0,
          discountAmount: null,
          minQuantity: 1,
          profitMargin: null,
          notes: 'Precio para producto temporal',
          productId: 'temp_$timestamp',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ],
      category: null,
      createdBy: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    print(
      '✅ Producto temporal creado: $productName - ${AppFormatters.formatCurrency(price)}',
    );
    print('🆔 ID temporal: temp_$timestamp');
    _selectProduct(unregisteredProduct);
  }

  // ==================== SCANNER FUNCTIONALITY ====================

  Future<void> _openBarcodeScanner() async {
    try {
      print('📱 Abriendo escáner de códigos de barras...');

      final scannedCode = await Get.to<String>(
        () => const BarcodeScannerScreen(),
      );

      if (scannedCode != null && scannedCode.isNotEmpty) {
        print('🔍 Código escaneado: $scannedCode');
        
        // ✅ MEJORADO: Establecer texto y auto-seleccionar para próximo escaneo
        _searchController.text = scannedCode;
        _autoSelectBarcodeText();
        
        // Asegurar focus después del escaneo
        _ensureSearchFieldFocus();

        // Trigger búsqueda automática después del escaneo
        _handleDirectSearch(scannedCode);
      } else {
        // Si no se escaneó nada, mantener focus para próximo intento
        _ensureSearchFieldFocus();
      }
    } catch (e) {
      print('❌ Error al abrir escáner: $e');
      _showError('Error de escáner', 'No se pudo abrir el escáner de códigos');
      
      // Mantener focus aunque haya error
      _ensureSearchFieldFocus();
    }
  }

  void _selectProduct(Product product, {double quantity = 1}) {
    // Cancelar cualquier búsqueda pendiente
    _debounceTimer?.cancel();

    // Limpiar búsqueda
    _searchController.clear();
    setState(() {
      _searchResults.clear();
      _showResults = false;
      _lastSearchTerm = '';
      _isSearching = false;
      _selectedResultIndex = -1; // ✅ NUEVO: Resetear selección
    });

    // ✅ MEJORADO: Asegurar focus inmediato para escáner continuo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasModalRouteAbove()) {
        _focusNode.requestFocus();
        print('🔍 Focus restaurado para escáner continuo después de selección');
      }
    });

    // Notificar selección (SIN audio para productos agregados)
    widget.onProductSelected(product, quantity);

    print('✅ Producto seleccionado: ${product.name} - Focus mantenido para próximo escaneo');
  }

  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      icon: const Icon(Icons.error, color: Colors.red),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(8),
    );
  }
}
