// lib/features/invoices/presentation/widgets/product_search_widget.dart
import 'package:baudex_desktop/app/core/theme/futuristic_notifications.dart';
import 'dart:async';
import 'package:baudex_desktop/app/shared/screens/barcode_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/app_logger.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/widgets/responsive_layout.dart' as rl
    show ResponsiveLayout;
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/services/audio_notification_service.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_price.dart';
import '../../../products/domain/entities/tax_enums.dart';
import '../controllers/invoice_form_controller.dart';
import '../../../breb/presentation/widgets/breb_ui.dart';
import '../../domain/price_entry.dart';
import '../../domain/invoice_entry_metrics.dart';
import '../../../../app/core/utils/frame_timings_probe.dart';
import '../../domain/scan_burst_detector.dart';
import 'barcode_scan_queue.dart';
import 'invoice_shortcut_keys.dart';
import 'scanner_focus.dart';

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
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  // Número de la búsqueda en curso: si una búsqueda lenta termina después
  // de una más nueva, su resultado se descarta y no tapa al nuevo.
  int _searchSeq = 0;

  // Confirmación en segundo plano de un valor cuando el índice de códigos
  // no puede asegurarlo (sin cargar, catálogo bajando o sincronización
  // escribiendo): la opción ya está pintada; esto solo la cambia por el
  // producto si resulta que existe uno con ese código.
  Timer? _valueCheckTimer;
  String? _valueCheckQuery;
  Future<Product?>? _valueCheckFuture;
  static const Duration _valueCheckDelay = Duration(milliseconds: 80);

  InvoiceEntryMetrics get _metrics => InvoiceEntryMetrics.instance;

  // Escaneos (Enter del lector): se buscan de una vez y en orden.
  late final BarcodeScanQueue _scanQueue;

  // Ráfaga del lector: mientras las teclas llegan en milésimas, un valor
  // (los primeros 7 dígitos de cualquier código) NO se pinta tecla a tecla.
  // Si la ráfaga se corta sin Enter, se pinta a los [_burstFlushDelay].
  final ScanBurstDetector _burst = ScanBurstDetector();
  final Stopwatch _keyClock = Stopwatch()..start();
  Timer? _burstFlushTimer;
  String _previousText = '';
  int _runStartFrame = 0;
  static const Duration _burstFlushDelay = Duration(milliseconds: 60);

  /// Solo para pruebas: reloj de las teclas (las pruebas de pantalla
  /// manejan un tiempo simulado que el reloj real no ve).
  @visibleForTesting
  static Duration Function()? debugKeyClock;

  Duration _keyTime() => debugKeyClock?.call() ?? _keyClock.elapsed;

  // Lecturas en la cola, en orden: cronómetro desde su Enter.
  final List<_ScanTrace> _scanWatches = [];

  // ── Lectura directa del lector (teclas, sin pasar por la caja) ──
  //
  // El lector manda los dígitos en milésimas. Si cada uno entra a la caja de
  // texto, la pantalla alcanza a dibujar el código a medias ("números
  // entrando uno a uno") y la tarjeta "Producto sin registrar" de los
  // primeros dígitos. Por eso, con la caja vacía, los dígitos se RETIENEN
  // aquí (la tecla se consume y no llega a la caja):
  //  - llega Enter (o Tab) → es una lectura: se busca el código completo de
  //    una vez; la caja nunca mostró nada;
  //  - pasan [_firstDigitHold] sin otra tecla → era una persona: el dígito
  //    entra a la caja y sale la tarjeta de valor, como siempre (los
  //    dígitos siguientes de una persona ya no se retienen);
  //  - llegan más dígitos seguidos sin Enter → al parar entran todos juntos.
  final List<String> _scanKeys = [];
  final Set<LogicalKeyboardKey> _consumedKeys = {};
  Timer? _scanKeysTimer;
  Duration _scanKeysFirst = Duration.zero;
  Duration _scanKeysLast = Duration.zero;
  int _scanKeysFirstEngineUs = 0;
  int _scanKeysStartFrame = 0;

  /// Espera del primer dígito con la caja vacía (¿viene otro enseguida?).
  static const Duration _firstDigitHold = Duration(milliseconds: 32);

  /// Ya en ráfaga: pausa que la da por terminada (lector sin Enter).
  static const Duration _burstKeysHold = Duration(milliseconds: 80);

  /// Dígitos seguidos que ya son un código de barras (lector sin Enter).
  static const int _barcodeKeys = 8;

  /// Solo para pruebas y mediciones: apagar la lectura directa por teclas
  /// (queda el camino anterior, por la caja de texto).
  static bool debugDirectScanKeys = true;

  /// Reloj del motor al llegar la primera tecla de la tanda por la caja.
  int _runFirstEngineUs = 0;

  // Control para pausar la restauración automática de focus.
  // El padre (ej: CustomerSelectorWidget) lo puede activar mientras el
  // usuario está editando otros campos.
  bool _pauseFocusRestoration = false;

  @override
  void initState() {
    super.initState();
    _scanQueue = BarcodeScanQueue(
      // Solo lo exacto del equipo: la cola nunca espera al servidor.
      find: (code) =>
          widget.controller.findProductByBarcode(code, localOnly: true),
      onFound: (product, _) {
        final since = _takeScanWatch();
        if (mounted) _addScannedProduct(product, since: since);
      },
      onNotFound: (code) {
        final since = _takeScanWatch();
        if (mounted) unawaited(_resolveMissingScan(code, since));
      },
    );
    _searchController.addListener(_onSearchChanged);

    // Reaccionar SOLO cuando el focus realmente cambia (no en un timer).
    _focusNode.addListener(_onFocusChanged);

    _initializeAudioService();
    ensureFrameTimingsProbe();

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
    if (!_nobodyElseHasFocus()) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pauseFocusRestoration) return;
      if (_focusNode.hasFocus) return;
      if (_hasModalRouteAbove()) return;
      if (!_nobodyElseHasFocus()) return;
      _focusNode.requestFocus();
    });
  }

  /// ¿El foco quedó "en nadie"? Al reconstruirse la pantalla (sincronización,
  /// avisos) el foco cae al ámbito (`FocusScopeNode`), no a null: antes eso
  /// contaba como "otro lo tiene" y la caja no lo recuperaba nunca, así que
  /// las teclas del lector se perdían.
  bool _nobodyElseHasFocus() => scannerFocusIsFree(
        FocusManager.instance.primaryFocus,
        own: [_focusNode, _keyboardFocusNode],
      );

  /// ✅ NUEVO: Inicializar servicio de notificaciones de audio
  /// La voz se prepara en un rato libre (unos segundos sin teclear), no
  /// al abrir la pantalla ni en el primer Enter: su primera carga puede
  /// frenar la app. Una sola vez por sesión.
  Future<void> _initializeAudioService() async {
    AudioNotificationService.instance.warmUpWhenIdle();
  }

  @override
  void dispose() {
    try {
      _debounceTimer?.cancel();
      _burstFlushTimer?.cancel();
      _scanKeysTimer?.cancel();
      _valueCheckTimer?.cancel();
      _scanQueue.dispose();
      AudioNotificationService.instance.cancelWarmUpWhenIdle();

      _searchController.removeListener(_onSearchChanged);
      _focusNode.removeListener(_onFocusChanged);

      _searchController.dispose();
      _focusNode.dispose();
      _keyboardFocusNode.dispose();
      _resultsScrollController.dispose();
    } catch (e) {
AppLogger.w('⚠️ Error en dispose de ProductSearchWidget: $e');
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
        }
      });
    }
  }

  // ✅ NUEVO: Pausar temporalmente la restauración automática de focus
  void pauseFocusRestoration() {
    _pauseFocusRestoration = true;
  }

  // ✅ NUEVO: Reanudar la restauración automática de focus
  void resumeFocusRestoration() {
    _pauseFocusRestoration = false;
  }

  /// API pública para que el padre fuerce el focus de vuelta al
  /// TextField. Se llama después de eventos que sacan el focus pero
  /// que sabemos que el usuario querrá seguir escaneando/buscando:
  ///   - Tras procesar una venta y limpiar el form (Nueva venta)
  ///   - Tras cerrar un dialog modal
  /// Internamente usa `_ensureSearchFieldFocus` que ya respeta:
  ///   - mounted
  ///   - rutas modales encima (no roba focus si hay un dialog)
  ///   - `_pauseFocusRestoration` (no fuerza si el padre lo pausó)
  void requestFocus() {
    _ensureSearchFieldFocus();
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
          
          // Asegurar focus después de seleccionar
          if (!_focusNode.hasFocus && !_hasModalRouteAbove()) {
            _focusNode.requestFocus();
          }
        }
      });
    } catch (e) {
AppLogger.w('⚠️ Error auto-seleccionando texto: $e');
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
          // Dígitos del lector: se retienen aquí (ver [_scanKeys]).
          final direct = _handleScanKey(event);
          if (direct != null) return direct;
          // ✅ CRÍTICO: Interceptar Enter ANTES de que llegue al TextField
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
            // Solo se usa el resultado resaltado si es de lo que hay escrito
            // AHORA y no es un código de barras: con el lector, un resultado
            // viejo se quedaba con el Enter y el código siguiente se pegaba
            // al anterior en la caja.
            final text = _searchController.text.trim();
            if (_showResults &&
                _searchResults.isNotEmpty &&
                _selectedResultIndex >= 0 &&
                _selectedResultIndex < _searchResults.length &&
                text == _lastSearchTerm &&
                !_isBarcodeQuery(text)) {
              final selectedProduct = _searchResults[_selectedResultIndex];
              if (!widget.controller.shouldValidateStock || selectedProduct.stock > 0) {
                _selectProduct(selectedProduct);
              } else {
                // Producto sin stock con validación activa: avisar al usuario
                // (snackbar + audio) en lugar de silenciar la tecla.
                _notifyOutOfStock(selectedProduct);
              }
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored; // ✅ Permitir propagación normal
        },
        child: RawKeyboardListener(
          focusNode: _keyboardFocusNode, // ✅ NUEVO: FocusNode separado para navegación
          onKey: _handleKeyboardNavigation,
          // Cada tecla repinta y vuelve a medir SOLO la caja (ver
          // [_isolatedField]).
          child: _isolatedField(_buildTextField(isMobileOrTablet)),
        ),
      ),
    );
  }

  /// Alto de la caja con el tamaño de letra normal (el mínimo de un campo).
  static const double _fieldHeight = 48;

  /// Aísla la caja del resto de la pantalla: capa propia y tamaño fijo.
  ///
  /// Sin esto, cada dígito volvía a medir la caja y, con ella, toda la
  /// columna hasta la página: la pantalla entera de la factura (cliente,
  /// tabla, totales, sombras) se medía y se repintaba por tecla, 13 veces
  /// por lectura. Con el tamaño fijo (todo el ancho disponible × el alto
  /// mínimo de un campo) la medición termina en la caja, y la capa propia
  /// hace que solo ella se repinte. Si el equipo usa letra agrandada se
  /// deja como antes: el alto ya no es el mínimo.
  ///
  /// OJO: no usar `LayoutBuilder` aquí; al cambiar algo adentro pide medir
  /// de nuevo hacia arriba y se pierde el aislamiento.
  Widget _isolatedField(Widget field) {
    final normalText = MediaQuery.textScalerOf(context).scale(12) == 12;
    if (!normalText) return field;
    return SizedBox(
      width: double.infinity,
      height: _fieldHeight,
      child: RepaintBoundary(child: field),
    );
  }

  Widget _buildTextField(bool isMobileOrTablet) {
    return TextField(
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
            // Enter NO suelta el foco de la caja (por defecto lo soltaba y
            // había que recuperarlo en cada lectura): solo confirma.
            onEditingComplete: _searchController.clearComposing,
            onSubmitted: (value) {
              // ✅ CRÍTICO: Solo procesar onSubmitted si no hay selección activa
              final text = value.trim();
              if (_selectedResultIndex < 0 ||
                  _selectedResultIndex >= _searchResults.length ||
                  text != _lastSearchTerm ||
                  _isBarcodeQuery(text)) {
                _handleDirectSearch(value);
              } else {
                // Si hay selección activa, procesar ese producto en lugar de buscar
                final selectedProduct = _searchResults[_selectedResultIndex];
                if (!widget.controller.shouldValidateStock || selectedProduct.stock > 0) {
                  _selectProduct(selectedProduct);
                }
              }
            },
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
          onTap: canSelect
              ? () => _selectProduct(product)
              : () => _notifyOutOfStock(product),
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

    final price = priceFromEntry(searchValue);

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.alphaBlend(
                ElegantLightTheme.primaryBlue.withOpacity(0.08), Colors.white),
            Color.alphaBlend(
                ElegantLightTheme.primaryBlue.withOpacity(0.04), Colors.white),
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
                        'Valor: ${AppFormatters.formatCurrency(price)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: ElegantLightTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rl.ResponsiveLayout.isMobile(context)
                            ? 'Toca para agregarlo'
                            : 'Presiona Enter para agregarlo',
                        style: const TextStyle(
                          fontSize: 12,
                          color: ElegantLightTheme.textSecondary,
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
      
      // Flecha hacia abajo
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedResultIndex = (_selectedResultIndex + 1).clamp(
            0,
            _searchResults.length - 1,
          );
          _scrollToSelected();
        });
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
AppLogger.w('⚠️ ProductSearchWidget: Widget no montado, cancelando búsqueda');
      return;
    }
    
    try {
      // ✅ NUEVO: Asegurar que el focus permanezca en el TextField mientras se escribe
      if (_focusNode.canRequestFocus && !_focusNode.hasFocus) {
        _ensureSearchFieldFocus();
      }
      
      // Cancelar timer anterior si existe
      _debounceTimer?.cancel();
      _burstFlushTimer?.cancel();
      AudioNotificationService.instance.noteActivity();

      final query = _searchController.text.trim();

      // ¿Tecla del lector? Solo cuenta un carácter agregado al final (una
      // tecla); pegar texto o borrar empieza de cero. Un aviso sin cambio
      // de texto (solo el cursor) no cuenta.
      final text = _searchController.text;
      var inBurst = false;
      if (text != _previousText) {
        final isKey = text.length == _previousText.length + 1 &&
            text.startsWith(_previousText);
        _previousText = text;
        if (isKey) {
          inBurst = _burst.addKey(_keyTime());
          if (_burst.keys == 1) {
            _runStartFrame = drawnFrameCount;
            _runFirstEngineUs = engineClockMicros();
          }
        } else {
          _burst.reset();
        }
      }

      // ✅ No auto-seleccionar durante la escritura para evitar cortar el código

    if (query.isEmpty) {
      _searchSeq++;
      _forgetValueCheck();
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
    }

      // Valor (≤7 dígitos): se pinta EN ESTA MISMA TECLA, sin pausa de
      // tecleo y sin depender de la base, del servidor ni de la
      // sincronización.
      if (_isUnregisteredProductQuery(query)) {
        // En ráfaga del lector estos dígitos son el principio de un código,
        // no un valor: no se pinta nada por tecla. Si la ráfaga se corta
        // sin Enter (era un valor tecleado muy rápido), se pinta enseguida.
        if (inBurst) {
          _metrics.scanKeysNotRedrawn++;
          _burstFlushTimer = Timer(_burstFlushDelay, () {
            if (mounted && _searchController.text.trim() == query) {
              _showValueNow(query);
            }
          });
          return;
        }
        _showValueNow(query);
        return;
      }

      // Crear nuevo timer con debounce
      _debounceTimer = Timer(_debounceDuration, () {
        _performSearch(query);
      });
    } catch (e) {
AppLogger.w('⚠️ Error en _onSearchChanged (ProductSearchWidget): $e');
      // Cancelar timer si hay error
      _debounceTimer?.cancel();
    }
  }

  Future<void> _performSearch(String query) async {
    // Un valor nunca pasa por aquí (ni pausa ni base): ver [_showValueNow].
    if (_isUnregisteredProductQuery(query)) {
      _showValueNow(query);
      return;
    }
    // Evitar búsquedas repetidas
    if (query == _lastSearchTerm) return;
    _lastSearchTerm = query;

    // Búsqueda mínima de 2 caracteres
    if (query.length < 2) {
      _searchSeq++;
      setState(() {
        _searchResults.clear();
        _showResults =
            true; // Mostrar para que aparezca la opción de producto sin registrar
      });
      return;
    }

    // Do NOT block on isLoadingProducts — ISAR is always ready regardless of remote refresh

    final seq = ++_searchSeq;
    final searchWatch = Stopwatch()..start();
    setState(() {
      _isSearching = true;
    });

    try {
      List<Product> results = [];
      
      final isBarcode = _isBarcodeQuery(query);

      if (isBarcode) {
        // Código de barras (>7 dígitos) escrito sin Enter: búsqueda exacta
        // en el equipo (y, si no, la general de siempre). Si aparece se
        // agrega abajo de una vez (antes esperaba 500 ms más).
        final product = await widget.controller.findProductByBarcode(query);
        if (product != null) results.add(product);
      } else {
        // Búsqueda de texto normal (nombre, SKU parcial, etc.)
        final searchResults = await widget.controller.searchProducts(query);
        results.addAll(searchResults);
        _metrics.record(
          EntryMetric.textSearch,
          searchWatch.elapsedMicroseconds / 1000,
          widget.controller.entryContext(),
        );
      }

      // Eliminar duplicados y limitar resultados
      final uniqueResults = <String, Product>{};
      for (final product in results) {
        uniqueResults[product.id] = product;
      }

      if (mounted && seq == _searchSeq) {
        setState(() {
          _searchResults.clear();
          // Sin cap: mostramos TODOS los resultados que coinciden. El
          // contenedor que envuelve la lista tiene `maxHeight: 300` +
          // `ListView.builder`, así que el scroll virtualizado maneja
          // catálogos grandes sin lag ni overflow visual.
          _searchResults.addAll(uniqueResults.values);
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

        // Código de barras encontrado: se agrega de una vez.
        if (isBarcode && _searchResults.isNotEmpty) {
          _selectProduct(_searchResults.first);
          return;
        }
        
        // ✅ NUEVO: Audio y auto-selección para códigos de barras no encontrados
        if (isBarcode && _searchResults.isEmpty) {
          // Reproducir audio "Producto no encontrado" para códigos de barras
          AudioNotificationService.instance.announceProductNotFound();
          
          // Auto-seleccionar cuando no se encontró el código de barras para facilitar reemplazo
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _autoSelectBarcodeText();
            }
          });
        }
      }

    } catch (e) {
AppLogger.e('❌ Error en búsqueda de productos: $e');
      if (mounted && seq == _searchSeq) {
        setState(() {
          _searchResults.clear();
          _showResults = true;
          _isSearching = false;
        });
        
        // ✅ MEJORADO: Mantener focus incluso cuando hay errores
        if (_isBarcodeQuery(query)) {
          _ensureSearchFieldFocus();
        }
      }
    }
  }

  void _handleDirectSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) return;

    // Código de barras (Enter del lector): se busca y se agrega de una vez,
    // en orden. Solo se usan resultados en pantalla si son de ESTE código
    // (antes, con resultados viejos de otra búsqueda, se agregaba el primero
    // de esos: un producto equivocado).
    if (_isBarcodeQuery(q)) {
      if (_searchResults.isNotEmpty && _lastSearchTerm == q) {
        _selectProduct(_searchResults.first);
      } else {
        _enqueueScan(q);
      }
      return;
    }

    // Precio de producto no registrado (≤7 dígitos): misma regla de siempre.
    if (_isUnregisteredProductQuery(q)) {
      if (_searchResults.isNotEmpty && _lastSearchTerm == q) {
        _selectProduct(_searchResults.first);
      } else {
        _resolvePriceEnter(q);
      }
      return;
    }

    // Texto: si hay resultados, seleccionar el primero (igual que antes);
    // si todavía no, buscar ya sin esperar.
    if (_searchResults.isNotEmpty) {
      _selectProduct(_searchResults.first);
    } else {
      _debounceTimer?.cancel();
      _performSearch(q);
    }
  }

  /// Escaneo: la caja queda libre para el siguiente código y este se busca
  /// en la cola (en orden, sin perder ninguno).
  void _enqueueScan(String code, {_DirectScan? direct}) {
    _debounceTimer?.cancel();
    _burstFlushTimer?.cancel();
    final enterUs = engineClockMicros();
    final int? firstKeyUs;
    if (direct != null) {
      // Entró por las teclas: la caja no mostró nada.
      firstKeyUs = direct.firstKeyEngineUs;
      _metrics.recordScan(
        keys: direct.keys,
        avgGapMs: direct.averageGapMs,
        frames: direct.frames,
        burst: true,
        direct: true,
      );
    } else {
      final typed = _burst.keys >= 2;
      firstKeyUs = typed ? _runFirstEngineUs : null;
      final frames = drawnFrameCount - _runStartFrame;
      _metrics.recordScan(
        keys: _burst.keys,
        avgGapMs: _burst.averageGapMs,
        frames: frames,
        burst: _burst.inBurst,
      );
      // Por la caja: cada cuadro entre la primera tecla y el Enter mostró
      // el código a medias (o la tarjeta de valor).
      if (typed) _metrics.scanPartialFrames += frames;
    }
    if (firstKeyUs != null) {
      _metrics.record(
        EntryMetric.scanFirstKeyToCode,
        (enterUs - firstKeyUs) / 1000,
        widget.controller.entryContext(),
      );
    }
    _burst.reset();
    _searchSeq++; // descarta una búsqueda en curso de este mismo texto
    _lastSearchTerm = '';
    if (_searchController.text.isNotEmpty) _searchController.clear();
    if (_showResults) {
      // Quedaba algo pintado de antes (p. ej. "no encontrado"): se limpia.
      setState(() {
        _searchResults.clear();
        _showResults = false;
        _isSearching = false;
        _selectedResultIndex = -1;
      });
    }
    _scanWatches.add(_ScanTrace(firstKeyUs));
    _scanQueue.add(code);
  }

  _ScanTrace? _takeScanWatch() =>
      _scanWatches.isEmpty ? null : _scanWatches.removeAt(0);

  // ──────────── Lectura directa por teclas ────────────

  /// ¿La caja está vacía (o con todo seleccionado, que se reemplaza)?
  bool _fieldIsBlank() {
    final value = _searchController.value;
    if (value.text.isEmpty) return true;
    final s = value.selection;
    return s.isValid && s.start == 0 && s.end == value.text.length;
  }

  /// Tecla sobre la caja: `handled` si se retuvo, `ignored` si debe seguir
  /// su camino ya, o `null` si no es asunto de la lectura directa.
  KeyEventResult? _handleScanKey(KeyEvent event) {
    if (!debugDirectScanKeys) return null;
    if (event is KeyUpEvent) {
      return _consumedKeys.remove(event.logicalKey)
          ? KeyEventResult.handled
          : null;
    }
    // Solo con el cursor en ESTA caja. Con el foco en otro campo o en un
    // diálogo (el del nombre, cantidad, cliente…) nunca se retiene nada.
    if (!_focusNode.hasPrimaryFocus) {
      if (_scanKeys.isNotEmpty) _releaseScanKeys();
      return null;
    }
    AudioNotificationService.instance.noteActivity();
    final digit = plainDigitOf(
      event.character,
      modifierPressed: shortcutModifierPressed(),
    );
    if (digit != null) {
      // Solo se retiene si empieza con la caja vacía (un lector siempre
      // empieza así) o si ya hay dígitos retenidos. Con texto en la caja,
      // la persona está escribiendo: camino normal.
      if (_scanKeys.isEmpty &&
          (!_fieldIsBlank() || _searchController.value.composing.isValid)) {
        return null;
      }
      final now = _keyTime();
      if (_scanKeys.isEmpty) {
        _scanKeysFirst = now;
        _scanKeysFirstEngineUs = engineClockMicros();
        _scanKeysStartFrame = drawnFrameCount;
      }
      _scanKeysLast = now;
      _scanKeys.add(digit);
      _consumedKeys.add(event.logicalKey);
      _scanKeysTimer?.cancel();
      _scanKeysGrace = 0;
      _scanKeysTimer = Timer(
        _scanKeys.length == 1 ? _firstDigitHold : _burstKeysHold,
        _scanKeysWaitOver,
      );
      return KeyEventResult.handled;
    }
    if (_scanKeys.isEmpty) return null;
    // Hay dígitos retenidos y llegó otra tecla.
    final key = event.logicalKey;
    final isEnter = key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;
    // Lectores configurados con Tab al final en vez de Enter.
    final isScannerTab =
        key == LogicalKeyboardKey.tab && _scanKeys.length >= _barcodeKeys;
    if (event is KeyDownEvent && (isEnter || isScannerTab)) {
      _consumedKeys.add(key);
      _confirmScanKeys();
      return KeyEventResult.handled;
    }
    // Mayús, Bloq Mayús, Ctrl… sueltas (algunos lectores las mandan entre
    // dígitos): no cortan la lectura.
    if (isModifierOnlyKey(key)) return null;
    // Cualquier otra tecla (letra, borrar, flechas…): lo retenido entra a
    // la caja ya, y la tecla sigue su camino normal sobre ese texto.
    _releaseScanKeys();
    return null;
  }

  /// Se acabó la espera por otra tecla. Si este aviso llegó TARDE (la
  /// pantalla estaba ocupada dibujando un cuadro lento), las teclas del
  /// lector pueden estar en fila detrás de él: se da un respiro corto para
  /// atenderlas antes de decidir que era una persona. Sin esto, en un equipo
  /// lento una lectura de cada tantas soltaba el primer dígito a la caja.
  void _scanKeysWaitOver() {
    if (_scanKeys.isEmpty || !mounted) return;
    final hold = _scanKeys.length == 1 ? _firstDigitHold : _burstKeysHold;
    final late = _keyTime() - _scanKeysLast - hold;
    if (late > _lateTimerSlack && _scanKeysGrace < _maxGraces) {
      _scanKeysGrace++;
      _scanKeysTimer = Timer(_graceAfterLateTimer, _scanKeysWaitOver);
      return;
    }
    _releaseScanKeys();
  }

  int _scanKeysGrace = 0;
  static const Duration _lateTimerSlack = Duration(milliseconds: 8);
  static const Duration _graceAfterLateTimer = Duration(milliseconds: 12);
  static const int _maxGraces = 3;

  /// Saca los dígitos retenidos (y sus datos para la medición).
  _DirectScan _takeScanKeys() {
    _scanKeysTimer?.cancel();
    final digits = _scanKeys.join();
    final keys = _scanKeys.length;
    _scanKeys.clear();
    return _DirectScan(
      digits: digits,
      keys: keys,
      averageGapMs: keys < 2
          ? null
          : (_scanKeysLast - _scanKeysFirst).inMicroseconds / 1000 / (keys - 1),
      frames: drawnFrameCount - _scanKeysStartFrame,
      firstKeyEngineUs: _scanKeysFirstEngineUs,
    );
  }

  /// Texto que quedaría en la caja al soltar [digits].
  String _textWith(String digits) =>
      _fieldIsBlank() ? digits : _searchController.text + digits;

  /// Pone [text] en la caja de un golpe (un solo cambio, un solo cuadro).
  void _putText(String text) {
    _searchController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// No llegó Enter: los dígitos retenidos entran a la caja TODOS JUNTOS y
  /// sigue lo de siempre (un valor pinta su tarjeta en ese mismo cuadro).
  /// Si son un código completo (lector sin Enter), se busca de una vez.
  void _releaseScanKeys() {
    if (_scanKeys.isEmpty || !mounted) return;
    final scan = _takeScanKeys();
    final text = _textWith(scan.digits);
    _putText(text);
    if (scan.keys >= _barcodeKeys && _isBarcodeQuery(text.trim())) {
      _debounceTimer?.cancel();
      unawaited(_performSearch(text.trim()));
    }
  }

  /// Llegó Enter (o Tab del lector) con dígitos retenidos.
  void _confirmScanKeys() {
    if (_scanKeys.isEmpty || !mounted) return;
    final scan = _takeScanKeys();
    final text = _textWith(scan.digits).trim();
    if (_isBarcodeQuery(text)) {
      // Lectura: directo a la cola. La caja no llega a mostrar el código.
      _enqueueScan(text, direct: scan);
      return;
    }
    // Un valor (o un código corto) tecleado rapidísimo + Enter: entra a la
    // caja y sigue el Enter de siempre (producto con ese código, o el
    // diálogo de "Producto sin registrar").
    _putText(text);
    _handleDirectSearch(text);
  }

  /// El código no está en el equipo. Con el catálogo completo, no existe:
  /// se avisa de una vez. Si el catálogo todavía está bajando y hay
  /// internet, se pregunta al servidor FUERA de la cola (las lecturas
  /// siguientes no esperan); si aparece, se agrega cuando llegue.
  Future<void> _resolveMissingScan(String code, _ScanTrace? since) async {
    Product? product;
    try {
      if (await widget.controller.scanMayExistOnServer()) {
        product = await widget.controller.findProductByBarcode(code);
      }
    } catch (_) {
      product = null;
    }
    if (!mounted) return;
    if (product != null) {
      _addScannedProduct(product, since: since);
    } else {
      _showBarcodeNotFound(code);
    }
  }

  /// Unidades en la factura ahora (`null` si no se puede leer).
  double? _invoiceUnits() {
    try {
      var units = 0.0;
      for (final item in widget.controller.invoiceItems) {
        units += item.quantity;
      }
      return units;
    } catch (_) {
      return null;
    }
  }

  /// Producto escaneado encontrado. La caja NO se borra: el siguiente código
  /// puede estar entrando.
  void _addScannedProduct(Product product, {_ScanTrace? since}) {
    final before = since == null ? null : _invoiceUnits();
    if (since != null) {
      _metrics.record(
        EntryMetric.scanLookup,
        since.sinceEnter.elapsedMicroseconds / 1000,
      );
    }
    widget.onProductSelected(product, 1);
    if (since != null && before != null) _recordLineAdded(since, before);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasModalRouteAbove()) _focusNode.requestFocus();
    });
  }

  /// Guarda cuánto pasó del Enter a la línea PINTADA en la factura. Se
  /// revisa al final de cada cuadro (agregar la línea dibuja uno); si en
  /// 3 s no entró (sin existencias, diálogo de presentaciones), se deja.
  void _recordLineAdded(_ScanTrace since, double before) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || since.sinceEnter.elapsedMilliseconds > 3000) return;
      final now = _invoiceUnits();
      if (now == null) return;
      if (now != before) {
        final context = widget.controller.entryContext();
        _metrics.record(
          EntryMetric.scanEnterToLine,
          since.sinceEnter.elapsedMicroseconds / 1000,
          context,
        );
        // Lo que el cajero ve: de la primera tecla a la línea EN PANTALLA.
        final firstKeyUs = since.firstKeyEngineUs;
        if (firstKeyUs != null) {
          whenFrameShown(currentFrameNumber(), (shownAt) {
            _metrics.record(
              EntryMetric.scanFirstKeyToSeen,
              (shownAt - firstKeyUs) / 1000,
              context,
            );
          });
        }
      } else {
        _recordLineAdded(since, before);
      }
    });
  }

  /// Código escaneado sin producto: aviso de voz y, si no se está escribiendo
  /// otra cosa, el código queda seleccionado en la caja para corregirlo
  /// (como antes).
  void _showBarcodeNotFound(String code) {
    AudioNotificationService.instance.announceProductNotFound();
    if (_searchController.text.isNotEmpty || _scanQueue.pendingCount > 1) return;
    _lastSearchTerm = code; // ya se buscó: no repetir
    _searchController.text = code;
    setState(() {
      _searchResults.clear();
      _showResults = true;
      _isSearching = false;
      _selectedResultIndex = -1;
    });
    _autoSelectBarcodeText();
  }

  /// Tecla con un valor ("5", "50", "500"…). Todo lo que se pinta sale de
  /// la memoria, en este mismo cuadro:
  /// - el índice no conoce un producto con ese código → "Producto sin
  ///   registrar" de una vez. Si el índice no puede asegurarlo (sin cargar,
  ///   catálogo bajando, sincronización escribiendo), se confirma después
  ///   en segundo plano y, solo si aparece un producto, se cambia la opción
  ///   por ese producto;
  /// - el índice conoce un producto con ese código → se trae ese producto
  ///   por su id (una lectura) y se muestra: el registrado gana.
  void _showValueNow(String query) {
    final watch = Stopwatch()..start();
    _debounceTimer?.cancel();
    final guess = widget.controller.guessValueEntry(query);
    final context = widget.controller.entryContext();
    final seq = ++_searchSeq;
    _lastSearchTerm = query;
    if (_valueCheckQuery != query) _forgetValueCheck();

    final localId = guess.existingLocalId;
    if (localId != null) {
      setState(() {
        _searchResults.clear();
        _showResults = true;
        _isSearching = true;
        _selectedResultIndex = -1;
      });
      unawaited(_showRegisteredForValue(query, seq, localId));
      return;
    }

    if (guess.certain) {
      _metrics.valueKeysCertain++;
    } else {
      _metrics.valueKeysUnconfirmed++;
    }
    setState(() {
      _searchResults.clear();
      _showResults = true;
      _isSearching = false;
      _selectedResultIndex = -1;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _metrics.record(
        EntryMetric.keyToOption,
        watch.elapsedMicroseconds / 1000,
        context,
      );
    });
    if (!guess.certain) {
      _valueCheckTimer?.cancel();
      _valueCheckTimer = Timer(_valueCheckDelay, () {
        if (mounted && _searchController.text.trim() == query) {
          unawaited(_checkValue(query));
        }
      });
    }
  }

  /// El índice dice que hay un producto con ese código corto.
  Future<void> _showRegisteredForValue(String query, int seq, int localId) async {
    Product? product;
    try {
      product = await widget.controller.productByLocalId(localId);
      // Ya no está (borrado o inactivo): lo que diga la base.
      product ??= await _checkValue(query);
    } catch (_) {}
    if (!mounted || seq != _searchSeq) return;
    setState(() {
      _searchResults.clear();
      if (product != null) _searchResults.add(product);
      _showResults = true;
      _isSearching = false;
      _selectedResultIndex = product != null ? 0 : -1;
    });
  }

  void _forgetValueCheck() {
    _valueCheckTimer?.cancel();
    _valueCheckQuery = null;
    _valueCheckFuture = null;
  }

  /// Confirma en la base local (dos lecturas exactas por índice, sin
  /// servidor) si existe un producto activo con ese código. Una sola
  /// consulta por valor: el Enter reutiliza la que ya va en curso. Si
  /// aparece y el valor sigue escrito, reemplaza la opción por el producto.
  Future<Product?> _checkValue(String query) {
    if (_valueCheckQuery == query && _valueCheckFuture != null) {
      return _valueCheckFuture!;
    }
    _valueCheckTimer?.cancel();
    _valueCheckQuery = query;
    final watch = Stopwatch()..start();
    final context = widget.controller.entryContext();
    return _valueCheckFuture = () async {
      Product? product;
      try {
        product = await widget.controller.findRegisteredProductForValue(query);
      } catch (_) {}
      _metrics.record(
        EntryMetric.backgroundCheck,
        watch.elapsedMicroseconds / 1000,
        context,
      );
      if (product != null &&
          mounted &&
          _lastSearchTerm == query &&
          _searchController.text.trim() == query &&
          !_isSearching) {
        setState(() {
          _searchResults
            ..clear()
            ..add(product!);
          _showResults = true;
          _selectedResultIndex = 0;
        });
      }
      return product;
    }();
  }

  /// Enter con un valor (≤7 dígitos): si existe un producto con ese código
  /// se agrega ese; si no, se abre el diálogo del nombre (como siempre):
  /// Enter otra vez lo agrega como "Producto sin registrar".
  ///
  /// El diálogo sale DE INMEDIATO. Con el índice seguro no se consulta
  /// nada. Si no lo está (índice sin cargar, catálogo bajando o la
  /// sincronización escribiendo productos), se le da UN cuadro
  /// ([_enterGrace]) a la confirmación local, que casi siempre ya terminó
  /// mientras se tecleaba; si no alcanzó, el diálogo sale igual y la
  /// respuesta se usa cuando llegue: si existe un producto con ese código,
  /// se agrega ese (el registrado gana), antes o al confirmar el nombre.
  /// Antes el diálogo esperaba hasta 250 ms esa confirmación.
  Future<void> _resolvePriceEnter(String q) async {
    final watch = Stopwatch()..start();
    _debounceTimer?.cancel();
    final seq = ++_searchSeq;
    final guess = widget.controller.guessValueEntry(q);
    final localId = guess.existingLocalId;
    final price = priceFromEntry(q);
    if (localId == null && guess.certain) {
      _createUnregisteredProduct(price, since: watch);
      return;
    }
    final check = _registeredFor(q, localId);
    Product? match;
    var answered = false;
    await Future.any<void>([
      check.then((product) {
        match = product;
        answered = true;
      }),
      Future<void>.delayed(_enterGrace),
    ]);
    if (!mounted || seq != _searchSeq || _searchController.text.trim() != q) {
      return;
    }
    if (match != null) {
      _selectProduct(match!);
    } else {
      _createUnregisteredProduct(
        price,
        since: watch,
        registered: answered ? null : check,
      );
    }
  }

  /// Espera máxima del diálogo por la confirmación local: un cuadro.
  static const Duration _enterGrace = Duration(milliseconds: 16);

  /// Producto registrado con ese código, solo con lo del equipo. Nunca
  /// falla ni espera al servidor.
  Future<Product?> _registeredFor(String q, int? localId) async {
    try {
      Product? match;
      if (localId != null) {
        match = await widget.controller.productByLocalId(localId);
      }
      return match ?? await _checkValue(q);
    } catch (_) {
      return null;
    }
  }

  /// Solo para pruebas y mediciones: ¿se está mostrando la tarjeta
  /// "Producto sin registrar" (valor) ahora?
  bool get debugValueOptionVisible =>
      _showResults &&
      _searchResults.isEmpty &&
      !_isSearching &&
      _isUnregisteredProductQuery(_searchController.text.trim());

  // ==================== FUNCIONES AUXILIARES ====================

  bool _isBarcodeQuery(String value) =>
      classifySearchEntry(value) == SearchEntryKind.barcode;

  bool _isUnregisteredProductQuery(String value) =>
      classifySearchEntry(value) == SearchEntryKind.price;

  /// [registered]: confirmación local todavía en curso de "¿existe un
  /// producto con ese código?" (ver [_resolvePriceEnter]).
  void _createUnregisteredProduct(
    double price, {
    Stopwatch? since,
    Future<Product?>? registered,
  }) {
    // Primero el diálogo; la voz no debe retrasarlo.
    _showProductNameDialog(price, registered: registered);
    if (since != null) {
      final context = widget.controller.entryContext();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _metrics.record(
          EntryMetric.enterToDialog,
          since.elapsedMicroseconds / 1000,
          context,
        );
      });
    }
    // La voz, DESPUÉS de que el diálogo ya está en pantalla: si el motor
    // de voz se demora (la primera frase en Windows), no retrasa el campo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(const Duration(milliseconds: 60), () {
        unawaited(
            AudioNotificationService.instance.announceProductNotRegistered());
      });
    });
  }

  void _showProductNameDialog(double price, {Future<Product?>? registered}) {
    // El nombre sale ya escrito y seleccionado: listo para Enter o para
    // escribir encima, desde el primer cuadro.
    final nameController = TextEditingController.fromValue(
      const TextEditingValue(
        text: unregisteredProductName,
        selection: TextSelection(
          baseOffset: 0,
          extentOffset: unregisteredProductName.length,
        ),
      ),
    );

    // El diálogo sigue abierto y nadie lo ha resuelto todavía.
    var open = true;
    Product? found;

    // La confirmación local llegó con el diálogo abierto y SÍ existe un
    // producto con ese código: se cierra y se agrega ese (el registrado
    // gana, como siempre).
    var answered = registered == null;
    bool registeredAnswered() => answered;
    registered?.then((product) {
      answered = true;
      found = product;
      if (product == null || !open || !mounted) return;
      open = false;
      Navigator.of(context, rootNavigator: true).pop();
      _selectProduct(product);
    });

    Future<void> submit(BuildContext dialogContext) async {
      final name = nameController.text.trim();
      if (name.isEmpty || !open) return;
      open = false;
      Navigator.of(dialogContext).pop();
      final product = found;
      if (product != null) {
        _selectProduct(product);
        return;
      }
      // La línea entra YA, sin esperar a la base. Si la confirmación local
      // sigue pendiente y al llegar resulta que sí existía un producto con
      // ese código, la línea se cambia por el registrado (por detrás).
      final tempId = _createProductWithName(name, price);
      if (registered != null && !registeredAnswered()) {
        unawaited(registered
            .timeout(_lateRegisteredTimeout, onTimeout: () => null)
            .then((late) {
          if (late == null || !mounted) return;
          widget.controller.replaceUnregisteredLine(tempId, late);
        }).catchError((_) {}));
      }
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      // Sin animación de entrada: el campo queda listo en el primer cuadro.
      animationStyle: AnimationStyle.noAnimation,
      builder: (dialogContext) => brebAlertDialog(
        title: brebDialogTitle(
          Icons.add_shopping_cart,
          'Producto sin registrar',
        ),
        content: SizedBox(
          width: 380,
          child: Theme(
            data: Theme.of(dialogContext).copyWith(
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: ElegantLightTheme.primaryBlue,
                selectionColor: ElegantLightTheme.primaryBlue.withOpacity(0.25),
                selectionHandleColor: ElegantLightTheme.primaryBlue,
              ),
            ),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Valor: ${AppFormatters.formatCurrency(price)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ElegantLightTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                autofocus: true,
                maxLength: 100,
                decoration: brebInputDecoration(
                  label: 'Nombre en la factura',
                  hint: 'Escribe el nombre del producto...',
                  icon: Icons.edit_outlined,
                ),
                onSubmitted: (_) => submit(dialogContext),
              ),
            ],
            ),
          ),
        ),
        actions: [
          TextButton(
            style: brebTextButtonStyle(),
            onPressed: () {
              if (!open) return;
              open = false;
              Navigator.of(dialogContext).pop();
              // Mantener focus para continuar escaneando después de cancelar
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _ensureSearchFieldFocus();
                }
              });
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: brebPrimaryButtonStyle(),
            onPressed: () => submit(dialogContext),
            child: const Text('Agregar'),
          ),
        ],
      ),
    ).whenComplete(() => open = false);
  }

  /// Tope para cambiar por detrás la línea por el producto registrado.
  static const Duration _lateRegisteredTimeout = Duration(seconds: 3);

  /// Agrega la línea sin registrar; devuelve el id temporal del producto.
  String _createProductWithName(String productName, double price) {
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

    _selectProduct(unregisteredProduct);
    return unregisteredProduct.id;
  }

  // ==================== SCANNER FUNCTIONALITY ====================

  Future<void> _openBarcodeScanner() async {
    try {

      final scannedCode = await Get.to<String>(
        () => const BarcodeScannerScreen(),
      );

      if (scannedCode != null && scannedCode.isNotEmpty) {
        
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
AppLogger.e('❌ Error al abrir escáner: $e');
      _showError('Error de escáner', 'No se pudo abrir el escáner de códigos');
      
      // Mantener focus aunque haya error
      _ensureSearchFieldFocus();
    }
  }

  /// Notifica al usuario (visual + voz) que el producto no tiene stock y
  /// no se puede agregar a la factura.
  ///
  /// Guardia interna: si la preferencia "validar stock" está desactivada,
  /// el método NO hace nada — el cajero ya decidió que la app permite
  /// vender sin validar inventario, así que ni siquiera deberíamos
  /// avisarlo. Defense in depth para que cualquier camino que llame
  /// este método respete la preferencia.
  void _notifyOutOfStock(Product product) {
    if (!widget.controller.shouldValidateStock) return;

    // Audio TTS — async, no bloquea UI. Servicio offline (no requiere red).
    AudioNotificationService.instance.announceOutOfStock();

    FuturisticNotifications.showError(
      'Sin stock',
      '${product.name} no tiene unidades disponibles',
      duration: const Duration(milliseconds: 2500),
    );
  }

  void _selectProduct(Product product, {double quantity = 1}) {
    final watch = Stopwatch()..start();
    // Cancelar cualquier búsqueda pendiente
    _debounceTimer?.cancel();
    _burstFlushTimer?.cancel();
    _scanKeysTimer?.cancel();
    _scanKeys.clear();
    _burst.reset();
    _forgetValueCheck();

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
      }
    });

    // Notificar selección (SIN audio para productos agregados)
    widget.onProductSelected(product, quantity);

    final context = widget.controller.entryContext();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _metrics.record(
        EntryMetric.confirmToLine,
        watch.elapsedMicroseconds / 1000,
        context,
      );
    });
  }

  void _showError(String title, String message) {
    FuturisticNotifications.showError(
      title,
      message,
      duration: const Duration(seconds: 3),
    );
  }
}

/// Una lectura en la cola: cronómetro desde su Enter y, si se conoce, el
/// instante (reloj del motor) de su primera tecla.
class _ScanTrace {
  _ScanTrace(this.firstKeyEngineUs);
  final Stopwatch sinceEnter = Stopwatch()..start();
  final int? firstKeyEngineUs;
}

/// Dígitos de una lectura que entró directo por las teclas.
class _DirectScan {
  const _DirectScan({
    required this.digits,
    required this.keys,
    required this.averageGapMs,
    required this.frames,
    required this.firstKeyEngineUs,
  });
  final String digits;
  final int keys;
  final double? averageGapMs;
  final int frames;
  final int firstKeyEngineUs;
}
