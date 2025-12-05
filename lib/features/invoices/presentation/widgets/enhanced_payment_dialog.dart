// lib/features/invoices/presentation/widgets/enhanced_payment_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/invoice.dart';
import '../../../bank_accounts/domain/entities/bank_account.dart';
import '../../../bank_accounts/presentation/controllers/bank_accounts_controller.dart';
import '../../../bank_accounts/presentation/bindings/bank_accounts_binding.dart';
// ✅ NUEVO: Import para verificar saldo a favor
import '../../../customer_credits/presentation/controllers/customer_credit_controller.dart';
import '../../../customer_credits/presentation/bindings/customer_credit_binding.dart';

// Formateador de input personalizado para números con formato de miles
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Limpiar el texto (solo números)
    String cleaned = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Convertir a número
    int value = int.parse(cleaned);

    // Formatear con separadores de miles
    String formatted = AppFormatters.formatNumber(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Clase para manejar tamaños responsive del diálogo
class _DialogSizeConfig {
  final bool isMobile;
  final bool isTablet;

  _DialogSizeConfig({required this.isMobile, required this.isTablet});

  // Padding
  double get dialogPadding => isMobile ? 12 : (isTablet ? 16 : 20);
  double get cardPadding => isMobile ? 10 : (isTablet ? 12 : 14);
  double get sectionSpacing => isMobile ? 10 : (isTablet ? 12 : 14);

  // Fuentes
  double get titleSize => isMobile ? 16 : (isTablet ? 18 : 20);
  double get subtitleSize => isMobile ? 12 : (isTablet ? 13 : 14);
  double get bodySize => isMobile ? 11 : (isTablet ? 12 : 13);
  double get smallSize => isMobile ? 9 : (isTablet ? 10 : 11);
  double get totalSize => isMobile ? 20 : (isTablet ? 24 : 28);

  // Iconos
  double get iconSmall => isMobile ? 14 : (isTablet ? 16 : 18);
  double get iconMedium => isMobile ? 18 : (isTablet ? 20 : 22);
  double get iconLarge => isMobile ? 22 : (isTablet ? 24 : 28);

  // Botones
  double get buttonHeight => isMobile ? 42 : (isTablet ? 46 : 50);

  // Border radius
  double get radiusSmall => isMobile ? 6 : (isTablet ? 8 : 10);
  double get radiusMedium => isMobile ? 10 : (isTablet ? 12 : 14);
  double get radiusLarge => isMobile ? 14 : (isTablet ? 18 : 20);

  // Dialog width
  double get dialogWidth => isTablet ? 450 : 520;
}

/// Datos de un pago individual para el callback de pagos múltiples
class MultiplePaymentData {
  final double amount;
  final PaymentMethod method;
  final String? bankAccountId;
  final String? bankAccountName;

  const MultiplePaymentData({
    required this.amount,
    required this.method,
    this.bankAccountId,
    this.bankAccountName,
  });
}

class EnhancedPaymentDialog extends StatefulWidget {
  final double total;
  final String? customerName; // Nombre del cliente para validar crédito
  final String? customerId; // ✅ NUEVO: ID del cliente para verificar saldo a favor
  final Function(
    double receivedAmount,
    double change,
    PaymentMethod paymentMethod,
    InvoiceStatus status,
    bool shouldPrint, {
    String? bankAccountId,
    // Pagos múltiples
    List<MultiplePaymentData>? multiplePayments,
    bool? createCreditForRemaining,
    // ✅ NUEVO: Saldo a favor aplicado
    double? balanceApplied,
  })
  onPaymentConfirmed;
  final VoidCallback onCancel;

  const EnhancedPaymentDialog({
    super.key,
    required this.total,
    this.customerName,
    this.customerId, // ✅ NUEVO
    required this.onPaymentConfirmed,
    required this.onCancel,
  });

  /// Verificar si el cliente es "Consumidor Final" o similar
  bool get isDefaultCustomer {
    if (customerName == null) return true;
    final name = customerName!.toLowerCase().trim();
    return name.contains('consumidor final') ||
           name.contains('cliente final') ||
           name.contains('consumidor') ||
           name == 'final' ||
           name.isEmpty;
  }

  @override
  State<EnhancedPaymentDialog> createState() => _EnhancedPaymentDialogState();
}

/// Clase para representar un pago individual en modo múltiples pagos
class _PaymentEntry {
  double amount;
  PaymentMethod method;
  BankAccount? bankAccount;
  final TextEditingController amountController;

  _PaymentEntry({
    this.amount = 0,
    this.method = PaymentMethod.cash,
    this.bankAccount,
  }) : amountController = TextEditingController();

  void dispose() {
    amountController.dispose();
  }
}

class _EnhancedPaymentDialogState extends State<EnhancedPaymentDialog>
    with SingleTickerProviderStateMixin {
  final receivedController = TextEditingController();
  final receivedFocusNode = FocusNode();
  final dialogFocusNode = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  PaymentMethod selectedPaymentMethod = PaymentMethod.cash;
  double change = 0.0;
  bool canProcess = false;
  bool saveAsDraft = false;

  // 🏦 Cuentas bancarias
  BankAccountsController? _bankAccountsController;
  BankAccount? selectedBankAccount;

  // 💳 Modo de pagos múltiples
  bool _isMultiplePaymentMode = false;
  final List<_PaymentEntry> _multiplePayments = [];
  bool _createCreditForRemaining = false;

  // 💰 NUEVO: Saldo a favor del cliente
  bool _isLoadingBalance = false;
  double _availableBalance = 0.0;
  bool _applyBalance = false; // Si el usuario quiere aplicar el saldo
  double _balanceToApply = 0.0; // Monto del saldo a aplicar

  /// Total efectivo a pagar (total - saldo aplicado)
  double get _effectiveTotal => widget.total - (_applyBalance ? _balanceToApply : 0);

  /// Verificar si el cliente tiene saldo a favor disponible
  bool get _hasAvailableBalance => _availableBalance > 0 && !widget.isDefaultCustomer;

  _DialogSizeConfig _getConfig(BuildContext context) {
    return _DialogSizeConfig(
      isMobile: Responsive.isMobile(context),
      isTablet: Responsive.isTablet(context),
    );
  }

  @override
  void initState() {
    super.initState();

    // Animación de entrada
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward();

    // 🏦 Intentar obtener o inicializar el controlador de cuentas bancarias
    _initBankAccountsController();

    // 💰 Cargar saldo a favor del cliente (si tiene customerId)
    _loadClientBalance();

    // Para efectivo, inicializar con el total exacto formateado
    if (selectedPaymentMethod == PaymentMethod.cash) {
      receivedController.text = AppFormatters.formatNumber(
        widget.total.round(),
      );
      _calculateChange();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        receivedFocusNode.requestFocus();
        receivedController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: receivedController.text.length,
        );
      });
    }

    // Focus para capturar shortcuts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && dialogFocusNode.canRequestFocus) {
        dialogFocusNode.requestFocus();
        print('🔍 PAYMENT DIALOG: Focus inicial solicitado para shortcuts');
      }

      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && !dialogFocusNode.hasFocus && dialogFocusNode.canRequestFocus) {
          dialogFocusNode.requestFocus();
          print('🔍 PAYMENT DIALOG: Focus backup solicitado');
        }
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && dialogFocusNode.canRequestFocus) {
          dialogFocusNode.requestFocus();
          print('🔍 PAYMENT DIALOG: Focus final para garantizar shortcuts');
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    receivedController.dispose();
    receivedFocusNode.dispose();
    dialogFocusNode.dispose();
    // Limpiar controladores de pagos múltiples
    for (final payment in _multiplePayments) {
      payment.dispose();
    }
    super.dispose();
  }

  // ==================== MÉTODOS PARA PAGOS MÚLTIPLES ====================

  /// Calcular total de pagos múltiples
  double get _totalMultiplePayments {
    return _multiplePayments.fold(0.0, (sum, p) => sum + p.amount);
  }

  /// Calcular saldo restante en modo múltiples pagos
  /// ✅ USAR _effectiveTotal (total - saldo aplicado)
  double get _remainingBalance {
    return _effectiveTotal - _totalMultiplePayments;
  }

  /// Verificar si puede procesar en modo múltiples pagos
  bool get _canProcessMultiple {
    if (_multiplePayments.isEmpty) return false;
    if (_multiplePayments.any((p) => p.amount <= 0)) return false;

    // ✅ USAR _effectiveTotal (total - saldo aplicado)
    // Si el total pagado es menor que el total efectivo a pagar
    if (_totalMultiplePayments < _effectiveTotal) {
      // ✅ NUEVO: Si es cliente por defecto (Consumidor Final), NO puede tener crédito
      // Debe pagar el total completo
      if (widget.isDefaultCustomer) {
        return false; // No puede procesar - debe pagar el total
      }
      // Si es cliente registrado, debe activar "crear crédito"
      if (!_createCreditForRemaining) {
        return false;
      }
    }

    // No permitir exceder el total efectivo
    if (_totalMultiplePayments > _effectiveTotal) {
      return false;
    }

    return true;
  }

  /// Activar/desactivar modo de pagos múltiples
  void _toggleMultiplePaymentMode() {
    setState(() {
      _isMultiplePaymentMode = !_isMultiplePaymentMode;
      if (_isMultiplePaymentMode && _multiplePayments.isEmpty) {
        // ✅ CORREGIDO: Usar _effectiveTotal (total - saldo aplicado) en lugar de widget.total
        _addPaymentEntry(initialAmount: _effectiveTotal);
      }
      _updateCanProcess();
    });
  }

  /// Agregar nueva entrada de pago
  void _addPaymentEntry({double initialAmount = 0}) {
    final entry = _PaymentEntry(
      amount: initialAmount,
      method: PaymentMethod.cash,
    );
    if (initialAmount > 0) {
      entry.amountController.text = AppFormatters.formatNumber(initialAmount.round());
    }
    setState(() {
      _multiplePayments.add(entry);
      _updateCanProcess();
    });
  }

  /// Eliminar entrada de pago
  void _removePaymentEntry(int index) {
    if (_multiplePayments.length > 1) {
      setState(() {
        _multiplePayments[index].dispose();
        _multiplePayments.removeAt(index);
        _updateCanProcess();
      });
    }
  }

  /// Actualizar monto de un pago
  void _updatePaymentAmount(int index, String value) {
    final parsed = AppFormatters.parseNumber(value) ?? 0.0;
    setState(() {
      _multiplePayments[index].amount = parsed;
      _updateCanProcess();
    });
  }

  /// Actualizar método de pago de una entrada
  void _updatePaymentMethod(int index, PaymentMethod method) {
    setState(() {
      _multiplePayments[index].method = method;
      _multiplePayments[index].bankAccount = null; // Reset cuenta bancaria
    });
  }

  /// Actualizar cuenta bancaria de una entrada
  void _updatePaymentBankAccount(int index, BankAccount? account) {
    setState(() {
      _multiplePayments[index].bankAccount = account;
      // Actualizar método de pago según la cuenta
      if (account != null) {
        _multiplePayments[index].method = _getPaymentMethodFromBankAccount(account);
      }
    });
  }

  /// Actualizar estado de canProcess según el modo
  void _updateCanProcess() {
    if (_isMultiplePaymentMode) {
      canProcess = _canProcessMultiple;
    } else {
      _calculateChange();
    }
  }

  /// 🏦 Inicializar controlador de cuentas bancarias
  void _initBankAccountsController() {
    try {
      // Primero intentar encontrar el controlador existente
      if (Get.isRegistered<BankAccountsController>()) {
        _bankAccountsController = Get.find<BankAccountsController>();
        print('✅ BankAccountsController encontrado');

        // Cargar cuentas si no están cargadas
        if (_bankAccountsController!.bankAccounts.isEmpty) {
          _bankAccountsController!.loadBankAccounts();
        }
      } else {
        // Si no está registrado, intentar inicializar el binding
        print('🔄 Inicializando BankAccountsBinding...');
        _initBankAccountsBinding();
      }
    } catch (e) {
      print('⚠️ Error obteniendo BankAccountsController: $e');
      _initBankAccountsBinding();
    }
  }

  /// 🏦 Inicializar binding de cuentas bancarias
  void _initBankAccountsBinding() {
    try {
      // Usar el binding oficial para inicializar todas las dependencias
      BankAccountsBinding().dependencies();

      // Ahora intentar obtener el controlador
      if (Get.isRegistered<BankAccountsController>()) {
        _bankAccountsController = Get.find<BankAccountsController>();
        print('✅ BankAccountsController inicializado correctamente');

        // Cargar las cuentas bancarias
        _bankAccountsController!.loadBankAccounts();
      }
    } catch (e) {
      print('⚠️ No se pudo inicializar BankAccountsController: $e');
      print('💡 Las cuentas bancarias no estarán disponibles');
    }
  }

  /// 💰 Cargar saldo a favor del cliente
  Future<void> _loadClientBalance() async {
    // Solo cargar si tiene customerId y no es cliente por defecto
    if (widget.customerId == null || widget.isDefaultCustomer) {
      print('💰 Sin customerId o es cliente por defecto - no se verifica saldo a favor');
      return;
    }

    setState(() => _isLoadingBalance = true);

    try {
      // Intentar obtener el controlador de créditos
      CustomerCreditController? creditController;

      if (Get.isRegistered<CustomerCreditController>()) {
        creditController = Get.find<CustomerCreditController>();
      } else {
        // Inicializar el binding si no está registrado
        print('🔄 Inicializando CustomerCreditBinding...');
        CustomerCreditBinding().dependencies();
        if (Get.isRegistered<CustomerCreditController>()) {
          creditController = Get.find<CustomerCreditController>();
        }
      }

      if (creditController != null) {
        final balance = await creditController.getClientBalance(widget.customerId!);
        if (mounted && balance != null && balance.balance > 0) {
          setState(() {
            _availableBalance = balance.balance;
            // Por defecto, aplicar el máximo posible (min entre saldo y total)
            _balanceToApply = _availableBalance > widget.total ? widget.total : _availableBalance;
          });
          print('💰 Saldo a favor disponible: ${AppFormatters.formatCurrency(_availableBalance)}');
        }
      }
    } catch (e) {
      print('⚠️ Error al cargar saldo a favor: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingBalance = false);
      }
    }
  }

  void _calculateChange() {
    final received = AppFormatters.parseNumber(receivedController.text) ?? 0.0;

    setState(() {
      // ✅ USAR _effectiveTotal (total - saldo aplicado) en lugar de widget.total
      final totalToPay = _effectiveTotal;
      final totalRounded = double.parse(totalToPay.toStringAsFixed(2));
      final receivedRounded = double.parse(received.toStringAsFixed(2));

      change = receivedRounded - totalRounded;

      if (change.abs() < 0.01) {
        change = 0.0;
      }

      if (saveAsDraft) {
        canProcess = true;
        print('🔵 Modo borrador - Puede procesar: $canProcess');
        return;
      }

      // Si hay cuenta bancaria seleccionada = pago por transferencia (exacto, sin cambio)
      if (selectedBankAccount != null) {
        change = 0.0; // No hay cambio en transferencias
        canProcess = true;
        print('🏦 Transferencia a cuenta - Pago exacto, puede procesar: $canProcess');
        return;
      }

      if (selectedPaymentMethod == PaymentMethod.cash) {
        canProcess = receivedRounded >= totalRounded;
        print(
          '💰 Efectivo - Recibido: $receivedRounded, Total efectivo: $totalRounded, Cambio: ${change.toStringAsFixed(2)}, Puede procesar: $canProcess',
        );
      } else {
        canProcess = true;
        print('💳 Otros métodos - Puede procesar: $canProcess');
      }
    });
  }

  InvoiceStatus _getInvoiceStatus() {
    print('🔍 === CALCULANDO ESTADO DE FACTURA ===');
    print('   - saveAsDraft: $saveAsDraft');
    print('   - selectedPaymentMethod: ${selectedPaymentMethod.displayName}');

    if (saveAsDraft) {
      print('🔵 RESULTADO: BORRADOR por elección del usuario');
      return InvoiceStatus.draft;
    }

    InvoiceStatus resultado;
    switch (selectedPaymentMethod) {
      case PaymentMethod.cash:
        resultado = InvoiceStatus.paid;
        print('💰 RESULTADO: EFECTIVO = PAID');
        break;
      case PaymentMethod.creditCard:
        resultado = InvoiceStatus.paid;
        print('💳 RESULTADO: TARJETA CRÉDITO = PAID');
        break;
      case PaymentMethod.debitCard:
        resultado = InvoiceStatus.paid;
        print('💳 RESULTADO: TARJETA DÉBITO = PAID');
        break;
      case PaymentMethod.bankTransfer:
        resultado = InvoiceStatus.paid;
        print('🏦 RESULTADO: TRANSFERENCIA = PAID');
        break;
      case PaymentMethod.credit:
        resultado = InvoiceStatus.pending;
        print('📅 RESULTADO: CRÉDITO = PENDING');
        break;
      case PaymentMethod.check:
        resultado = InvoiceStatus.pending;
        print('📋 RESULTADO: CHEQUE = PENDING');
        break;
      case PaymentMethod.other:
        resultado = InvoiceStatus.pending;
        print('❓ RESULTADO: OTRO = PENDING');
        break;
      default:
        resultado = InvoiceStatus.draft;
        print('⚠️ RESULTADO: MÉTODO DESCONOCIDO = DRAFT');
    }

    print('✅ Estado final calculado: ${resultado.displayName}');
    return resultado;
  }

  LinearGradient _getStatusGradient(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return ElegantLightTheme.successGradient;
      case InvoiceStatus.pending:
        return ElegantLightTheme.warningGradient;
      case InvoiceStatus.draft:
        return ElegantLightTheme.infoGradient;
      case InvoiceStatus.cancelled:
        return ElegantLightTheme.errorGradient;
      default:
        return ElegantLightTheme.glassGradient;
    }
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return const Color(0xFF10B981);
      case InvoiceStatus.pending:
        return ElegantLightTheme.accentOrange;
      case InvoiceStatus.draft:
        return ElegantLightTheme.primaryBlue;
      case InvoiceStatus.cancelled:
        return const Color(0xFFEF4444);
      default:
        return ElegantLightTheme.textTertiary;
    }
  }

  String _getStatusDescription(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        // Si hay cuenta seleccionada, incluir esa info en el mensaje
        if (selectedBankAccount != null) {
          return 'Pago registrado en ${selectedBankAccount!.name}';
        }
        return 'Pago procesado en efectivo';
      case InvoiceStatus.pending:
        return 'La factura quedará PENDIENTE de pago';
      case InvoiceStatus.draft:
        return 'La factura se guardará como BORRADOR';
      case InvoiceStatus.cancelled:
        return 'La factura será CANCELADA';
      default:
        return 'Estado desconocido';
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(context);

    return Focus(
      focusNode: dialogFocusNode,
      autofocus: true,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent) {
          print(
            '🎹 PAYMENT DIALOG evento: ${event.logicalKey} - Ctrl: ${HardwareKeyboard.instance.isControlPressed}',
          );

          // ESC - Cancelar
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            print('🔴 PAYMENT DIALOG ESC - Cancelando...');
            widget.onCancel();
            return KeyEventResult.handled;
          }

          // Ctrl + Enter - Procesar sin imprimir
          if (event.logicalKey == LogicalKeyboardKey.enter &&
              HardwareKeyboard.instance.isControlPressed) {
            print('💾 PAYMENT DIALOG Ctrl+Enter - Procesando sin imprimir...');
            if (canProcess) {
              _confirmPayment(shouldPrint: false);
            } else {
              print('⚠️ No se puede procesar - canProcess: $canProcess');
            }
            return KeyEventResult.handled;
          }

          // Ctrl + P - Procesar e imprimir
          if (event.logicalKey == LogicalKeyboardKey.keyP &&
              HardwareKeyboard.instance.isControlPressed) {
            print('🖨️ PAYMENT DIALOG Ctrl+P - Procesando e imprimiendo...');
            if (canProcess) {
              _confirmPayment(shouldPrint: true);
            } else {
              print('⚠️ No se puede procesar - canProcess: $canProcess');
            }
            return KeyEventResult.handled;
          }

          print('🔍 PAYMENT DIALOG - Evento no manejado: ${event.logicalKey}');
        }
        return KeyEventResult.ignored;
      },
      child: config.isMobile
          ? _buildMobileDialog(context, config)
          : _buildDialogModal(context, config),
    );
  }

  // ==================== MOBILE LAYOUT (Fullscreen) ====================
  Widget _buildMobileDialog(BuildContext context, _DialogSizeConfig config) {
    return Dialog.fullscreen(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ElegantLightTheme.backgroundColor,
              Color(0xFFEFF6FF),
            ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _buildElegantAppBar(context, config),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(config.dialogPadding),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1️⃣ TOTAL A PAGAR
                          _buildTotalCard(context, config),
                          SizedBox(height: config.sectionSpacing),

                          // 💰 SALDO A FAVOR (solo si el cliente tiene saldo disponible)
                          if (_hasAvailableBalance || _isLoadingBalance)
                            _buildClientBalanceSection(context, config),
                          if (_hasAvailableBalance || _isLoadingBalance)
                            SizedBox(height: config.sectionSpacing),

                          // 2️⃣ TIPO DE PAGO (siempre visible, contiene toggle de pagos múltiples)
                          _buildPaymentMethodSection(context, config),
                          SizedBox(height: config.sectionSpacing),

                          // 3️⃣ CONTENIDO SEGÚN MODO DE PAGO
                          if (_isMultiplePaymentMode) ...[
                            // MODO PAGOS MÚLTIPLES: Lista de pagos
                            _buildMultiplePaymentsSection(context, config),
                            SizedBox(height: config.sectionSpacing),
                          ] else ...[
                            // MODO PAGO SIMPLE:
                            // 3.1 Selector de cuenta bancaria (PRIMERO - para decidir si es transferencia)
                            if (selectedPaymentMethod != PaymentMethod.credit &&
                                _bankAccountsController != null &&
                                _bankAccountsController!.activeAccounts.isNotEmpty) ...[
                              _buildBankAccountSelector(context, config),
                              SizedBox(height: config.sectionSpacing),
                            ],

                            // 3.2 Dinero recibido y cambio (solo si es efectivo SIN cuenta bancaria)
                            // Si hay cuenta seleccionada = transferencia, no necesita cambio
                            if (selectedPaymentMethod == PaymentMethod.cash && selectedBankAccount == null) ...[
                              _buildCashPaymentSection(context, config),
                              SizedBox(height: config.sectionSpacing),
                            ],

                            // 3.3 Info adicional (solo si NO hay cuenta seleccionada y NO es efectivo)
                            // Cuando hay cuenta, la info se muestra en la sección de estado
                            if (selectedBankAccount == null && selectedPaymentMethod != PaymentMethod.cash) ...[
                              _buildOtherPaymentInfo(context, config),
                              SizedBox(height: config.sectionSpacing),
                            ],
                          ],

                          // 4️⃣ OPCIÓN DE BORRADOR
                          _buildDraftOption(context, config),
                          SizedBox(height: config.sectionSpacing - 4),

                          // 5️⃣ ESTADO DE FACTURA
                          _buildInvoiceStatusSection(context, config),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: config.sectionSpacing),
                  _buildMobileActions(context, config),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== TABLET/DESKTOP MODAL ====================
  Widget _buildDialogModal(BuildContext context, _DialogSizeConfig config) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: config.isTablet ? 40 : 60,
              vertical: 24,
            ),
            child: Container(
              width: config.dialogWidth,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(config.radiusLarge),
                boxShadow: [
                  ...ElegantLightTheme.elevatedShadow,
                  BoxShadow(
                    color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(config.radiusLarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildElegantHeader(context, config),
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.all(config.dialogPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1️⃣ TOTAL A PAGAR
                            _buildTotalCard(context, config),
                            SizedBox(height: config.sectionSpacing),

                            // 💰 SALDO A FAVOR (solo si el cliente tiene saldo disponible)
                            if (_hasAvailableBalance || _isLoadingBalance)
                              _buildClientBalanceSection(context, config),
                            if (_hasAvailableBalance || _isLoadingBalance)
                              SizedBox(height: config.sectionSpacing),

                            // 2️⃣ TIPO DE PAGO (siempre visible, contiene toggle de pagos múltiples)
                            _buildPaymentMethodSection(context, config),
                            SizedBox(height: config.sectionSpacing),

                            // 3️⃣ CONTENIDO SEGÚN MODO DE PAGO
                            if (_isMultiplePaymentMode) ...[
                              // MODO PAGOS MÚLTIPLES: Lista de pagos
                              _buildMultiplePaymentsSection(context, config),
                              SizedBox(height: config.sectionSpacing),
                            ] else ...[
                              // MODO PAGO SIMPLE:
                              // 3.1 Selector de cuenta bancaria (PRIMERO - para decidir si es transferencia)
                              if (selectedPaymentMethod != PaymentMethod.credit &&
                                  _bankAccountsController != null &&
                                  _bankAccountsController!.activeAccounts.isNotEmpty) ...[
                                _buildBankAccountSelector(context, config),
                                SizedBox(height: config.sectionSpacing),
                              ],

                              // 3.2 Dinero recibido y cambio (solo si es efectivo SIN cuenta bancaria)
                              // Si hay cuenta seleccionada = transferencia, no necesita cambio
                              if (selectedPaymentMethod == PaymentMethod.cash && selectedBankAccount == null) ...[
                                _buildCashPaymentSection(context, config),
                                SizedBox(height: config.sectionSpacing),
                              ],

                              // 3.3 Info adicional (solo si NO hay cuenta seleccionada y NO es efectivo)
                              // Cuando hay cuenta, la info se muestra en la sección de estado
                              if (selectedBankAccount == null && selectedPaymentMethod != PaymentMethod.cash) ...[
                                _buildOtherPaymentInfo(context, config),
                                SizedBox(height: config.sectionSpacing),
                              ],
                            ],

                            // 4️⃣ OPCIÓN DE BORRADOR
                            _buildDraftOption(context, config),
                            SizedBox(height: config.sectionSpacing - 4),

                            // 5️⃣ ESTADO DE FACTURA
                            _buildInvoiceStatusSection(context, config),
                          ],
                        ),
                      ),
                    ),
                    _buildDialogActions(context, config),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== ELEGANT COMPONENTS ====================

  PreferredSizeWidget _buildElegantAppBar(BuildContext context, _DialogSizeConfig config) {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.close, color: Colors.white, size: config.iconSmall),
        ),
        onPressed: widget.onCancel,
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.payment, color: Colors.white, size: config.iconMedium),
          const SizedBox(width: 8),
          Text(
            'Procesar Pago',
            style: TextStyle(
              color: Colors.white,
              fontSize: config.subtitleSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        Tooltip(
          message: '⌨️ Shortcuts:\n• Ctrl+P: Imprimir\n• Ctrl+Enter: Procesar\n• ESC: Cancelar',
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              Icons.keyboard,
              color: Colors.white.withOpacity(0.7),
              size: config.iconSmall,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildElegantHeader(BuildContext context, _DialogSizeConfig config) {
    return Container(
      padding: EdgeInsets.all(config.cardPadding + 4),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(config.isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(config.radiusSmall),
            ),
            child: Icon(
              Icons.payment,
              color: Colors.white,
              size: config.iconMedium,
            ),
          ),
          SizedBox(width: config.isMobile ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Procesar Pago',
                  style: TextStyle(
                    fontSize: config.titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Confirma los detalles del pago',
                  style: TextStyle(
                    fontSize: config.smallSize,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          // Tooltip de shortcuts
          Tooltip(
            message: '⌨️ Shortcuts:\n• Ctrl+P: Imprimir\n• Ctrl+Enter: Procesar\n• ESC: Cancelar',
            child: Container(
              padding: EdgeInsets.all(config.isMobile ? 6 : 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(config.radiusSmall),
              ),
              child: Icon(
                Icons.keyboard,
                color: Colors.white.withOpacity(0.8),
                size: config.iconSmall,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onCancel,
            child: Container(
              padding: EdgeInsets.all(config.isMobile ? 6 : 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(config.radiusSmall),
              ),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: config.iconSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(BuildContext context, _DialogSizeConfig config) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(config.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ElegantLightTheme.primaryBlue.withOpacity(0.1),
            ElegantLightTheme.primaryBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(config.radiusMedium),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.shopping_cart,
                  color: Colors.white,
                  size: config.iconSmall,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Total a Pagar',
                style: TextStyle(
                  fontSize: config.bodySize,
                  color: ElegantLightTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: config.isMobile ? 6 : 8),
          Text(
            AppFormatters.formatCurrency(widget.total),
            style: TextStyle(
              fontSize: config.totalSize,
              fontWeight: FontWeight.bold,
              color: ElegantLightTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  /// 💰 Sección de saldo a favor del cliente
  Widget _buildClientBalanceSection(BuildContext context, _DialogSizeConfig config) {
    if (_isLoadingBalance) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(config.cardPadding),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.teal.withOpacity(0.08),
              Colors.teal.withOpacity(0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(config.radiusMedium),
          border: Border.all(color: Colors.teal.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade600),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Verificando saldo a favor...',
              style: TextStyle(
                fontSize: config.bodySize,
                color: Colors.teal.shade700,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(config.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.teal.withOpacity(0.12),
            Colors.teal.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(config.radiusMedium),
        border: Border.all(
          color: _applyBalance
              ? Colors.teal.withOpacity(0.5)
              : Colors.teal.withOpacity(0.2),
          width: _applyBalance ? 1.5 : 1,
        ),
        boxShadow: _applyBalance
            ? [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con icono y título
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal, Colors.teal.shade700],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: config.iconSmall,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo a favor disponible',
                      style: TextStyle(
                        fontSize: config.bodySize,
                        fontWeight: FontWeight.w700,
                        color: Colors.teal.shade800,
                      ),
                    ),
                    Text(
                      widget.customerName ?? 'Cliente',
                      style: TextStyle(
                        fontSize: config.smallSize,
                        color: Colors.teal.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal, Colors.teal.shade700],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppFormatters.formatCurrency(_availableBalance),
                  style: TextStyle(
                    fontSize: config.bodySize,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Switch para aplicar saldo
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _applyBalance = !_applyBalance;
                  if (_applyBalance) {
                    // Recalcular monto a aplicar (máximo posible)
                    _balanceToApply = _availableBalance > widget.total
                        ? widget.total
                        : _availableBalance;
                  }

                  // Calcular el nuevo total efectivo
                  final newEffectiveTotal = widget.total - (_applyBalance ? _balanceToApply : 0);

                  // ✅ ACTUALIZAR campo de dinero recibido con el nuevo total efectivo
                  // Solo para efectivo sin cuenta bancaria
                  if (selectedPaymentMethod == PaymentMethod.cash && selectedBankAccount == null) {
                    receivedController.text = AppFormatters.formatNumber(newEffectiveTotal.round());
                  }

                  // ✅ CORREGIDO: Actualizar el monto del primer pago múltiple si está activo
                  // Esto es CRÍTICO para evitar cobrar de más al cliente
                  if (_isMultiplePaymentMode && _multiplePayments.isNotEmpty) {
                    // Solo actualizar si hay un solo pago y su monto es el total anterior
                    // (para no afectar si el usuario ya modificó los montos manualmente)
                    if (_multiplePayments.length == 1) {
                      final currentAmount = _multiplePayments[0].amount;
                      final oldEffectiveTotal = _applyBalance
                          ? widget.total  // Antes no tenía saldo aplicado
                          : widget.total - _balanceToApply; // Antes sí tenía saldo aplicado

                      // Solo actualizar si el monto actual coincide con el total anterior
                      if ((currentAmount - oldEffectiveTotal).abs() < 1) {
                        _multiplePayments[0].amount = newEffectiveTotal;
                        _multiplePayments[0].amountController.text =
                            AppFormatters.formatNumber(newEffectiveTotal.round());
                        print('💰 Monto del pago múltiple actualizado: ${AppFormatters.formatCurrency(newEffectiveTotal)}');
                      }
                    }
                  }

                  _calculateChange();
                });
                print('💰 Saldo aplicado: $_applyBalance, Monto: $_balanceToApply, Total efectivo: $_effectiveTotal');
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _applyBalance
                      ? Colors.teal.withOpacity(0.15)
                      : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _applyBalance
                        ? Colors.teal.withOpacity(0.4)
                        : Colors.teal.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        gradient: _applyBalance
                            ? LinearGradient(
                                colors: [Colors.teal, Colors.teal.shade700],
                              )
                            : null,
                        color: _applyBalance ? null : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _applyBalance
                              ? Colors.teal
                              : Colors.teal.shade400,
                          width: 2,
                        ),
                      ),
                      child: _applyBalance
                          ? const Icon(Icons.check, color: Colors.white, size: 14)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Aplicar saldo a esta venta',
                        style: TextStyle(
                          fontSize: config.bodySize,
                          fontWeight: FontWeight.w600,
                          color: _applyBalance
                              ? Colors.teal.shade800
                              : Colors.teal.shade600,
                        ),
                      ),
                    ),
                    if (_applyBalance)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-${AppFormatters.formatCurrency(_balanceToApply)}',
                          style: TextStyle(
                            fontSize: config.smallSize,
                            fontWeight: FontWeight.w700,
                            color: Colors.teal.shade800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Mostrar nuevo total si se aplica saldo
          if (_applyBalance) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade600,
                        size: config.iconSmall,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Total a pagar:',
                        style: TextStyle(
                          fontSize: config.bodySize,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    AppFormatters.formatCurrency(_effectiveTotal),
                    style: TextStyle(
                      fontSize: config.subtitleSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection(BuildContext context, _DialogSizeConfig config) {
    final isCredit = selectedPaymentMethod == PaymentMethod.credit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.infoGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.payment,
                color: Colors.white,
                size: config.iconSmall - 2,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Tipo de Pago',
              style: TextStyle(
                fontSize: config.subtitleSize,
                fontWeight: FontWeight.w600,
                color: ElegantLightTheme.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: config.isMobile ? 8 : 10),
        // Toggle simplificado: Pago Inmediato vs A Crédito
        Row(
          children: [
            // Opción: Pago Inmediato
            Expanded(
              child: GestureDetector(
                onTap: () => _selectPaymentMethod(PaymentMethod.cash),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: EdgeInsets.symmetric(
                    horizontal: config.isMobile ? 12 : 16,
                    vertical: config.isMobile ? 10 : 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: !isCredit ? ElegantLightTheme.successGradient : null,
                    color: !isCredit ? null : Colors.white,
                    borderRadius: BorderRadius.circular(config.radiusMedium),
                    border: Border.all(
                      color: !isCredit
                          ? Colors.transparent
                          : ElegantLightTheme.textTertiary.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: !isCredit ? ElegantLightTheme.glowShadow : ElegantLightTheme.elevatedShadow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.payments,
                        color: !isCredit ? Colors.white : ElegantLightTheme.textSecondary,
                        size: config.iconMedium,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Pago Inmediato',
                              style: TextStyle(
                                fontSize: config.bodySize,
                                fontWeight: FontWeight.w600,
                                color: !isCredit ? Colors.white : ElegantLightTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Efectivo, trans...',
                              style: TextStyle(
                                fontSize: config.smallSize - 1,
                                color: !isCredit
                                    ? Colors.white.withOpacity(0.8)
                                    : ElegantLightTheme.textTertiary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (!isCredit) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: config.iconSmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Opción: A Crédito
            Expanded(
              child: GestureDetector(
                onTap: () => _selectPaymentMethod(PaymentMethod.credit),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: EdgeInsets.symmetric(
                    horizontal: config.isMobile ? 12 : 16,
                    vertical: config.isMobile ? 10 : 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: isCredit ? ElegantLightTheme.warningGradient : null,
                    color: isCredit ? null : Colors.white,
                    borderRadius: BorderRadius.circular(config.radiusMedium),
                    border: Border.all(
                      color: isCredit
                          ? Colors.transparent
                          : ElegantLightTheme.textTertiary.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: isCredit ? ElegantLightTheme.glowShadow : ElegantLightTheme.elevatedShadow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.credit_score,
                        color: isCredit ? Colors.white : ElegantLightTheme.textSecondary,
                        size: config.iconMedium,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'A Crédito',
                              style: TextStyle(
                                fontSize: config.bodySize,
                                fontWeight: FontWeight.w600,
                                color: isCredit ? Colors.white : ElegantLightTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Pago diferido',
                              style: TextStyle(
                                fontSize: config.smallSize - 1,
                                color: isCredit
                                    ? Colors.white.withOpacity(0.8)
                                    : ElegantLightTheme.textTertiary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isCredit) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: config.iconSmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        // ✅ MEJORADO: Toggle colapsable de pagos múltiples con mejor UX
        SizedBox(height: config.isMobile ? 8 : 10),
        GestureDetector(
          onTap: _toggleMultiplePaymentMode,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: config.isMobile ? 12 : 16,
              vertical: config.isMobile ? 10 : 12,
            ),
            decoration: BoxDecoration(
              gradient: _isMultiplePaymentMode
                  ? const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
                    )
                  : null,
              color: _isMultiplePaymentMode ? null : Colors.white,
              borderRadius: BorderRadius.circular(config.radiusMedium),
              border: Border.all(
                color: _isMultiplePaymentMode
                    ? Colors.transparent
                    : ElegantLightTheme.textTertiary.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: _isMultiplePaymentMode
                  ? [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : ElegantLightTheme.elevatedShadow,
            ),
            child: Row(
              children: [
                // Icono de pagos
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _isMultiplePaymentMode
                        ? Colors.white.withOpacity(0.2)
                        : const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.payments_outlined,
                    color: _isMultiplePaymentMode ? Colors.white : const Color(0xFF8B5CF6),
                    size: config.iconMedium - 2,
                  ),
                ),
                const SizedBox(width: 10),
                // Texto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Pagos Múltiples / Parciales',
                        style: TextStyle(
                          fontSize: config.bodySize,
                          fontWeight: FontWeight.w600,
                          color: _isMultiplePaymentMode ? Colors.white : ElegantLightTheme.textPrimary,
                        ),
                      ),
                      Text(
                        _isMultiplePaymentMode
                            ? 'Toca para cerrar y volver a pago simple'
                            : 'Divide el pago: efectivo + Nequi, pago parcial...',
                        style: TextStyle(
                          fontSize: config.smallSize - 1,
                          color: _isMultiplePaymentMode
                              ? Colors.white.withOpacity(0.8)
                              : ElegantLightTheme.textTertiary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // ✅ Icono de expandir/colapsar animado
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: _isMultiplePaymentMode ? 0.5 : 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _isMultiplePaymentMode
                          ? Colors.white.withOpacity(0.2)
                          : const Color(0xFF8B5CF6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: _isMultiplePaymentMode ? Colors.white : const Color(0xFF8B5CF6),
                      size: config.iconMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCashPaymentSection(BuildContext context, _DialogSizeConfig config) {
    final isValidAmount = change >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.successGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.attach_money,
                color: Colors.white,
                size: config.iconSmall - 2,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Dinero Recibido',
              style: TextStyle(
                fontSize: config.subtitleSize,
                fontWeight: FontWeight.w600,
                color: ElegantLightTheme.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: config.isMobile ? 8 : 10),

        // Campo de dinero recibido
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(config.radiusMedium),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: TextField(
            controller: receivedController,
            focusNode: receivedFocusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CurrencyInputFormatter(),
            ],
            style: TextStyle(
              fontSize: config.subtitleSize + 2,
              fontWeight: FontWeight.w700,
              color: isValidAmount
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
            ),
            decoration: InputDecoration(
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: isValidAmount
                      ? ElegantLightTheme.successGradient
                      : ElegantLightTheme.errorGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.attach_money,
                  color: Colors.white,
                  size: config.iconSmall,
                ),
              ),
              suffixIcon: Icon(
                isValidAmount ? Icons.check_circle : Icons.error,
                color: isValidAmount
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                size: config.iconMedium,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(config.radiusMedium),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(config.radiusMedium),
                borderSide: BorderSide(
                  color: isValidAmount
                      ? const Color(0xFF10B981).withOpacity(0.3)
                      : const Color(0xFFEF4444).withOpacity(0.3),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(config.radiusMedium),
                borderSide: BorderSide(
                  color: isValidAmount
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: config.isMobile ? 12 : 14,
              ),
              hintText: '0',
              hintStyle: TextStyle(
                color: ElegantLightTheme.textTertiary,
                fontSize: config.bodySize,
              ),
            ),
            onChanged: (value) => _calculateChange(),
            onTap: () {
              receivedController.selection = TextSelection(
                baseOffset: 0,
                extentOffset: receivedController.text.length,
              );
            },
          ),
        ),
        SizedBox(height: config.isMobile ? 10 : 12),

        // Cambio
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(config.cardPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isValidAmount
                  ? [
                      const Color(0xFF10B981).withOpacity(0.1),
                      const Color(0xFF10B981).withOpacity(0.05),
                    ]
                  : [
                      const Color(0xFFEF4444).withOpacity(0.1),
                      const Color(0xFFEF4444).withOpacity(0.05),
                    ],
            ),
            borderRadius: BorderRadius.circular(config.radiusMedium),
            border: Border.all(
              color: isValidAmount
                  ? const Color(0xFF10B981).withOpacity(0.3)
                  : const Color(0xFFEF4444).withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isValidAmount ? Icons.savings : Icons.warning,
                    color: isValidAmount
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    size: config.iconMedium,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cambio:',
                    style: TextStyle(
                      fontSize: config.bodySize,
                      fontWeight: FontWeight.w600,
                      color: isValidAmount
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
              Text(
                isValidAmount
                    ? AppFormatters.formatCurrency(change)
                    : 'Falta ${AppFormatters.formatCurrency(change.abs())}',
                style: TextStyle(
                  fontSize: config.subtitleSize,
                  fontWeight: FontWeight.bold,
                  color: isValidAmount
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ),

        // Mensaje de ayuda si falta dinero
        if (!isValidAmount)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: EdgeInsets.all(config.isMobile ? 8 : 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ElegantLightTheme.accentOrange.withOpacity(0.1),
                  ElegantLightTheme.accentOrange.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(config.radiusSmall),
              border: Border.all(
                color: ElegantLightTheme.accentOrange.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: ElegantLightTheme.accentOrange,
                  size: config.iconSmall,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'El monto recibido debe ser igual o mayor al total',
                    style: TextStyle(
                      fontSize: config.smallSize,
                      color: ElegantLightTheme.accentOrange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ==================== SECCIÓN DE PAGOS MÚLTIPLES ====================

  Widget _buildMultiplePaymentsSection(BuildContext context, _DialogSizeConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.payments,
                color: Colors.white,
                size: config.iconSmall - 2,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Métodos de Pago',
              style: TextStyle(
                fontSize: config.subtitleSize,
                fontWeight: FontWeight.w600,
                color: ElegantLightTheme.textPrimary,
              ),
            ),
            const Spacer(),
            // Resumen
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _remainingBalance <= 0
                    ? const Color(0xFF10B981).withOpacity(0.1)
                    : const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _remainingBalance <= 0
                    ? 'Completo'
                    : 'Faltan ${AppFormatters.formatCurrency(_remainingBalance)}',
                style: TextStyle(
                  fontSize: config.smallSize,
                  fontWeight: FontWeight.w600,
                  color: _remainingBalance <= 0
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: config.isMobile ? 10 : 12),

        // Lista de pagos
        ..._multiplePayments.asMap().entries.map((entry) {
          final index = entry.key;
          final payment = entry.value;
          return _buildPaymentEntryCard(context, config, index, payment);
        }).toList(),

        // Botón agregar otro pago
        SizedBox(height: config.isMobile ? 8 : 10),
        GestureDetector(
          onTap: () => _addPaymentEntry(),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: config.isMobile ? 10 : 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(config.radiusMedium),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withOpacity(0.3),
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: const Color(0xFF8B5CF6),
                  size: config.iconMedium,
                ),
                const SizedBox(width: 8),
                Text(
                  'Agregar Otro Método de Pago',
                  style: TextStyle(
                    fontSize: config.bodySize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Resumen de pagos
        SizedBox(height: config.isMobile ? 12 : 16),
        _buildPaymentsSummary(context, config),

        // ✅ MODIFICADO: Opción de crear crédito SOLO si:
        // 1. Hay saldo pendiente (_remainingBalance > 0)
        // 2. El cliente NO es "Consumidor Final" (widget.isDefaultCustomer == false)
        if (_remainingBalance > 0) ...[
          SizedBox(height: config.isMobile ? 12 : 16),
          if (!widget.isDefaultCustomer)
            _buildCreditOption(context, config)
          else
            _buildDefaultCustomerWarning(context, config),
        ],
      ],
    );
  }

  Widget _buildPaymentEntryCard(
    BuildContext context,
    _DialogSizeConfig config,
    int index,
    _PaymentEntry payment,
  ) {
    final bankAccounts = _bankAccountsController?.bankAccounts ?? [];

    return Container(
      margin: EdgeInsets.only(bottom: config.isMobile ? 8 : 10),
      padding: EdgeInsets.all(config.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(config.radiusMedium),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withOpacity(0.2),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con número y botón eliminar
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Pago ${index + 1}',
                style: TextStyle(
                  fontSize: config.bodySize,
                  fontWeight: FontWeight.w600,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (_multiplePayments.length > 1)
                GestureDetector(
                  onTap: () => _removePaymentEntry(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.close,
                      color: const Color(0xFFEF4444),
                      size: config.iconSmall,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: config.isMobile ? 10 : 12),

          // Campo de monto
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monto',
                      style: TextStyle(
                        fontSize: config.smallSize,
                        color: ElegantLightTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ElegantLightTheme.textTertiary.withOpacity(0.2),
                        ),
                      ),
                      child: TextField(
                        controller: payment.amountController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: config.bodySize,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          prefixText: '\$ ',
                          prefixStyle: TextStyle(
                            color: ElegantLightTheme.textSecondary,
                            fontSize: config.bodySize,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: InputBorder.none,
                          hintText: '0',
                        ),
                        inputFormatters: [CurrencyInputFormatter()],
                        onChanged: (value) => _updatePaymentAmount(index, value),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Selector de cuenta/método
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Método',
                      style: TextStyle(
                        fontSize: config.smallSize,
                        color: ElegantLightTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ElegantLightTheme.textTertiary.withOpacity(0.2),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<dynamic>(
                          isExpanded: true,
                          value: payment.bankAccount ?? payment.method,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          style: TextStyle(
                            fontSize: config.bodySize,
                            color: ElegantLightTheme.textPrimary,
                          ),
                          items: [
                            // Opción efectivo
                            DropdownMenuItem<PaymentMethod>(
                              value: PaymentMethod.cash,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(Icons.money, size: 14, color: Colors.green.shade600),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Efectivo'),
                                ],
                              ),
                            ),
                            // Cuentas bancarias con últimos 4 dígitos
                            ...bankAccounts.map((account) {
                              // ✅ Construir texto con nombre y últimos 4 dígitos (igual que Cuenta Destino)
                              final hasAccountNumber = account.accountNumber != null &&
                                                       account.accountNumber!.length >= 4;
                              final lastFourDigits = hasAccountNumber
                                  ? ' ****${account.accountNumber!.substring(account.accountNumber!.length - 4)}'
                                  : '';
                              final displayText = '${account.name}$lastFourDigits';

                              return DropdownMenuItem<BankAccount>(
                                value: account,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: _getBankAccountColor(account.type).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Icon(
                                        _getBankAccountIcon(account.type),
                                        size: 14,
                                        color: _getBankAccountColor(account.type),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        displayText,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: account.isDefault ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (account.isDefault) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: const Text(
                                          '✓',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            if (value is BankAccount) {
                              _updatePaymentBankAccount(index, value);
                            } else if (value is PaymentMethod) {
                              _updatePaymentMethod(index, value);
                              _updatePaymentBankAccount(index, null);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsSummary(BuildContext context, _DialogSizeConfig config) {
    return Container(
      padding: EdgeInsets.all(config.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withOpacity(0.08),
            const Color(0xFF8B5CF6).withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(config.radiusMedium),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total a Pagar:',
                style: TextStyle(
                  fontSize: config.bodySize,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
              Text(
                AppFormatters.formatCurrency(widget.total),
                style: TextStyle(
                  fontSize: config.bodySize,
                  fontWeight: FontWeight.w600,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pagos (${_multiplePayments.length}):',
                style: TextStyle(
                  fontSize: config.bodySize,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
              Text(
                AppFormatters.formatCurrency(_totalMultiplePayments),
                style: TextStyle(
                  fontSize: config.bodySize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saldo Restante:',
                style: TextStyle(
                  fontSize: config.subtitleSize,
                  fontWeight: FontWeight.w600,
                  color: _remainingBalance <= 0
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ),
              Text(
                AppFormatters.formatCurrency(_remainingBalance > 0 ? _remainingBalance : 0),
                style: TextStyle(
                  fontSize: config.subtitleSize,
                  fontWeight: FontWeight.bold,
                  color: _remainingBalance <= 0
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreditOption(BuildContext context, _DialogSizeConfig config) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _createCreditForRemaining = !_createCreditForRemaining;
          _updateCanProcess();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.all(config.cardPadding),
        decoration: BoxDecoration(
          gradient: _createCreditForRemaining
              ? LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.15),
                    Colors.orange.withOpacity(0.08),
                  ],
                )
              : null,
          color: _createCreditForRemaining ? null : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(config.radiusMedium),
          border: Border.all(
            color: _createCreditForRemaining
                ? Colors.orange
                : ElegantLightTheme.textTertiary.withOpacity(0.2),
            width: _createCreditForRemaining ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: _createCreditForRemaining
                    ? const LinearGradient(
                        colors: [Colors.orange, Color(0xFFFF8C00)],
                      )
                    : null,
                border: Border.all(
                  color: _createCreditForRemaining ? Colors.transparent : Colors.grey,
                  width: 1.5,
                ),
              ),
              child: _createCreditForRemaining
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.orange, Color(0xFFFF8C00)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.credit_score, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crear crédito por el saldo',
                    style: TextStyle(
                      fontSize: config.bodySize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'El cliente quedará debiendo ${AppFormatters.formatCurrency(_remainingBalance)}',
                    style: TextStyle(
                      fontSize: config.smallSize,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ NUEVO: Widget de advertencia cuando el cliente es "Consumidor Final"
  /// y no puede tener crédito - debe pagar el total o usar otro método
  Widget _buildDefaultCustomerWarning(BuildContext context, _DialogSizeConfig config) {
    return Container(
      padding: EdgeInsets.all(config.cardPadding),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7), // Amarillo suave
        borderRadius: BorderRadius.circular(config.radiusMedium),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFD97706),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pago incompleto',
                  style: TextStyle(
                    fontSize: config.bodySize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Faltan ${AppFormatters.formatCurrency(_remainingBalance)}. '
                  'Para generar crédito, selecciona un cliente registrado.',
                  style: TextStyle(
                    fontSize: config.smallSize,
                    color: const Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getBankAccountIcon(BankAccountType type) {
    switch (type) {
      case BankAccountType.cash:
        return Icons.money;
      case BankAccountType.savings:
      case BankAccountType.checking:
        return Icons.account_balance;
      case BankAccountType.digitalWallet:
        return Icons.phone_android;
      case BankAccountType.creditCard:
        return Icons.credit_card;
      case BankAccountType.debitCard:
        return Icons.credit_card;
      case BankAccountType.other:
        return Icons.payments;
    }
  }

  Color _getBankAccountColor(BankAccountType type) {
    switch (type) {
      case BankAccountType.cash:
        return Colors.green.shade600;
      case BankAccountType.savings:
      case BankAccountType.checking:
        return Colors.blue.shade600;
      case BankAccountType.digitalWallet:
        return Colors.purple.shade600;
      case BankAccountType.creditCard:
        return Colors.orange.shade600;
      case BankAccountType.debitCard:
        return Colors.teal.shade600;
      case BankAccountType.other:
        return Colors.grey.shade600;
    }
  }

  Widget _buildOtherPaymentInfo(BuildContext context, _DialogSizeConfig config) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(config.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ElegantLightTheme.primaryBlue.withOpacity(0.08),
            ElegantLightTheme.primaryBlue.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(config.radiusMedium),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(config.isMobile ? 8 : 10),
            decoration: BoxDecoration(
              gradient: selectedPaymentMethod == PaymentMethod.credit
                  ? ElegantLightTheme.warningGradient
                  : ElegantLightTheme.infoGradient,
              borderRadius: BorderRadius.circular(config.radiusSmall),
            ),
            child: Icon(
              selectedPaymentMethod == PaymentMethod.credit
                  ? Icons.schedule
                  : Icons.info,
              color: Colors.white,
              size: config.iconMedium,
            ),
          ),
          SizedBox(width: config.isMobile ? 10 : 12),
          Expanded(
            child: Text(
              selectedPaymentMethod == PaymentMethod.credit
                  ? 'El pago se registrará como crédito y quedará pendiente'
                  : 'Confirme que el pago ha sido procesado exitosamente',
              style: TextStyle(
                fontSize: config.bodySize,
                color: ElegantLightTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🏦 Selector de cuenta bancaria
  Widget _buildBankAccountSelector(BuildContext context, _DialogSizeConfig config) {
    final accounts = _bankAccountsController?.activeAccounts ?? [];
    if (accounts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.successGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: config.iconSmall - 2,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Cuenta de Destino',
              style: TextStyle(
                fontSize: config.subtitleSize,
                fontWeight: FontWeight.w600,
                color: ElegantLightTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: ElegantLightTheme.textTertiary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Opcional',
                style: TextStyle(
                  fontSize: config.smallSize - 1,
                  color: ElegantLightTheme.textTertiary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: config.isMobile ? 8 : 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(config.radiusMedium),
            border: Border.all(
              color: selectedBankAccount != null
                  ? const Color(0xFF10B981).withOpacity(0.5)
                  : ElegantLightTheme.textTertiary.withOpacity(0.2),
              width: selectedBankAccount != null ? 2 : 1,
            ),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: DropdownButtonFormField<BankAccount?>(
            value: selectedBankAccount,
            decoration: InputDecoration(
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: selectedBankAccount != null
                      ? ElegantLightTheme.successGradient
                      : LinearGradient(
                          colors: [
                            Colors.grey.shade300,
                            Colors.grey.shade400,
                          ],
                        ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  selectedBankAccount?.type.icon ?? Icons.account_balance_wallet,
                  color: Colors.white,
                  size: config.iconSmall,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(config.radiusMedium),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: config.isMobile ? 10 : 12,
              ),
            ),
            hint: Text(
              'Sin cuenta específica',
              style: TextStyle(
                fontSize: config.bodySize,
                color: ElegantLightTheme.textTertiary,
              ),
            ),
            items: [
              DropdownMenuItem<BankAccount?>(
                value: null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.money_off,
                      size: config.iconSmall,
                      color: ElegantLightTheme.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sin cuenta específica',
                      style: TextStyle(
                        fontSize: config.bodySize,
                        color: ElegantLightTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ...accounts.map((account) {
                // Construir texto con nombre y últimos 4 dígitos
                final accountDisplay = account.accountNumber != null && account.accountNumber!.length > 4
                    ? '${account.name} ****${account.accountNumber!.substring(account.accountNumber!.length - 4)}'
                    : account.name;

                return DropdownMenuItem<BankAccount?>(
                  value: account,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        account.type.icon,
                        size: config.iconSmall,
                        color: account.isDefault
                            ? const Color(0xFF10B981)
                            : ElegantLightTheme.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          accountDisplay,
                          style: TextStyle(
                            fontSize: config.bodySize,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (account.isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: ElegantLightTheme.successGradient,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '✓',
                            style: TextStyle(
                              fontSize: config.smallSize,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                selectedBankAccount = value;
              });
              // Recalcular estado de pago (transferencia = pago exacto sin cambio)
              _calculateChange();
              print('🏦 Cuenta seleccionada: ${value?.name ?? "Ninguna"}');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDraftOption(BuildContext context, _DialogSizeConfig config) {
    return GestureDetector(
      onTap: () {
        setState(() {
          saveAsDraft = !saveAsDraft;
          print('🔵 Checkbox borrador cambiado a: $saveAsDraft');

          if (saveAsDraft) {
            canProcess = true;
            print('🔵 Borrador marcado - Habilitando procesamiento');
          } else {
            _calculateChange();
            print('🔵 Borrador desmarcado - Recalculando...');
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.all(config.isMobile ? 10 : 12),
        decoration: BoxDecoration(
          gradient: saveAsDraft
              ? LinearGradient(
                  colors: [
                    ElegantLightTheme.primaryBlue.withOpacity(0.15),
                    ElegantLightTheme.primaryBlue.withOpacity(0.08),
                  ],
                )
              : null,
          color: saveAsDraft ? null : ElegantLightTheme.cardColor,
          borderRadius: BorderRadius.circular(config.radiusMedium),
          border: Border.all(
            color: saveAsDraft
                ? ElegantLightTheme.primaryBlue
                : ElegantLightTheme.textTertiary.withOpacity(0.2),
            width: saveAsDraft ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: config.isMobile ? 20 : 22,
              height: config.isMobile ? 20 : 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: saveAsDraft ? ElegantLightTheme.primaryGradient : null,
                border: Border.all(
                  color: saveAsDraft
                      ? Colors.transparent
                      : ElegantLightTheme.textTertiary,
                  width: 1.5,
                ),
              ),
              child: saveAsDraft
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: config.iconSmall - 2,
                    )
                  : null,
            ),
            SizedBox(width: config.isMobile ? 10 : 12),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.infoGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.edit_note,
                color: Colors.white,
                size: config.iconSmall,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Guardar como borrador',
                    style: TextStyle(
                      fontSize: config.bodySize,
                      fontWeight: FontWeight.w600,
                      color: saveAsDraft
                          ? ElegantLightTheme.primaryBlue
                          : ElegantLightTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Para revisión posterior',
                    style: TextStyle(
                      fontSize: config.smallSize,
                      color: ElegantLightTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceStatusSection(BuildContext context, _DialogSizeConfig config) {
    final status = _getInvoiceStatus();
    final statusColor = _getStatusColor(status);
    final statusGradient = _getStatusGradient(status);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(config.isMobile ? 10 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.1),
            statusColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(config.radiusMedium),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(config.isMobile ? 8 : 10),
            decoration: BoxDecoration(
              gradient: statusGradient,
              borderRadius: BorderRadius.circular(config.radiusSmall),
            ),
            child: Icon(
              _getStatusIcon(status),
              color: Colors.white,
              size: config.iconMedium,
            ),
          ),
          SizedBox(width: config.isMobile ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado: ${status.displayName}',
                  style: TextStyle(
                    fontSize: config.bodySize,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getStatusDescription(status),
                  style: TextStyle(
                    fontSize: config.smallSize,
                    color: statusColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ACTIONS ====================

  Widget _buildMobileActions(BuildContext context, _DialogSizeConfig config) {
    return Column(
      children: [
        // Botón principal: Procesar e Imprimir
        SizedBox(
          width: double.infinity,
          height: config.buttonHeight,
          child: _buildElegantButton(
            context: context,
            config: config,
            label: 'Procesar e Imprimir',
            icon: Icons.print,
            gradient: ElegantLightTheme.successGradient,
            onPressed: canProcess ? () => _confirmPayment(shouldPrint: true) : null,
            tooltip: 'Ctrl + P',
          ),
        ),
        const SizedBox(height: 10),

        // Botón secundario: Solo procesar
        SizedBox(
          width: double.infinity,
          height: config.buttonHeight,
          child: _buildElegantOutlinedButton(
            context: context,
            config: config,
            label: 'Solo Procesar',
            icon: Icons.save,
            onPressed: canProcess ? () => _confirmPayment(shouldPrint: false) : null,
            tooltip: 'Ctrl + Enter',
          ),
        ),
        const SizedBox(height: 10),

        // Botón cancelar
        SizedBox(
          width: double.infinity,
          height: config.buttonHeight - 4,
          child: TextButton(
            onPressed: widget.onCancel,
            child: Text(
              'Cancelar (ESC)',
              style: TextStyle(
                fontSize: config.bodySize,
                color: ElegantLightTheme.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDialogActions(BuildContext context, _DialogSizeConfig config) {
    return Container(
      padding: EdgeInsets.all(config.dialogPadding),
      decoration: BoxDecoration(
        color: ElegantLightTheme.backgroundColor,
        border: Border(
          top: BorderSide(
            color: ElegantLightTheme.textTertiary.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          // Fila de botones
          Row(
            children: [
              // Cancelar
              Expanded(
                child: SizedBox(
                  height: config.buttonHeight,
                  child: _buildElegantOutlinedButton(
                    context: context,
                    config: config,
                    label: 'Cancelar',
                    icon: Icons.close,
                    onPressed: widget.onCancel,
                    tooltip: 'ESC',
                    isCancel: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Solo procesar
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: config.buttonHeight,
                  child: _buildElegantButton(
                    context: context,
                    config: config,
                    label: 'Procesar',
                    icon: Icons.save,
                    gradient: ElegantLightTheme.primaryGradient,
                    onPressed: canProcess ? () => _confirmPayment(shouldPrint: false) : null,
                    tooltip: 'Ctrl + Enter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Botón principal
          SizedBox(
            width: double.infinity,
            height: config.buttonHeight,
            child: _buildElegantButton(
              context: context,
              config: config,
              label: 'Procesar e Imprimir',
              icon: Icons.print,
              gradient: ElegantLightTheme.successGradient,
              onPressed: canProcess ? () => _confirmPayment(shouldPrint: true) : null,
              tooltip: 'Ctrl + P',
              isPrimary: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElegantButton({
    required BuildContext context,
    required _DialogSizeConfig config,
    required String label,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback? onPressed,
    String? tooltip,
    bool isPrimary = false,
  }) {
    final isEnabled = onPressed != null;

    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(config.radiusMedium),
          child: Container(
            decoration: BoxDecoration(
              gradient: isEnabled
                  ? gradient
                  : const LinearGradient(
                      colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
                    ),
              borderRadius: BorderRadius.circular(config.radiusMedium),
              boxShadow: isEnabled && isPrimary
                  ? [
                      BoxShadow(
                        color: gradient.colors.first.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isEnabled ? Colors.white : Colors.grey,
                    size: config.iconMedium,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: config.bodySize,
                      fontWeight: FontWeight.w700,
                      color: isEnabled ? Colors.white : Colors.grey,
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

  Widget _buildElegantOutlinedButton({
    required BuildContext context,
    required _DialogSizeConfig config,
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    String? tooltip,
    bool isCancel = false,
  }) {
    final isEnabled = onPressed != null;

    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(config.radiusMedium),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(config.radiusMedium),
              border: Border.all(
                color: isCancel
                    ? ElegantLightTheme.textTertiary.withOpacity(0.3)
                    : isEnabled
                        ? ElegantLightTheme.primaryBlue
                        : ElegantLightTheme.textTertiary.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isCancel
                        ? ElegantLightTheme.textSecondary
                        : isEnabled
                            ? ElegantLightTheme.primaryBlue
                            : ElegantLightTheme.textTertiary,
                    size: config.iconMedium,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: config.bodySize,
                      fontWeight: FontWeight.w600,
                      color: isCancel
                          ? ElegantLightTheme.textSecondary
                          : isEnabled
                              ? ElegantLightTheme.primaryBlue
                              : ElegantLightTheme.textTertiary,
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

  // ==================== HELPER METHODS ====================

  IconData _getStatusIcon(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return Icons.check_circle;
      case InvoiceStatus.pending:
        return Icons.schedule;
      case InvoiceStatus.draft:
        return Icons.edit;
      case InvoiceStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  void _selectPaymentMethod(PaymentMethod method) {
    setState(() {
      selectedPaymentMethod = method;

      // Si es crédito, limpiar la cuenta bancaria seleccionada
      if (method == PaymentMethod.credit) {
        selectedBankAccount = null;
      }

      if (selectedPaymentMethod == PaymentMethod.cash) {
        receivedController.text = AppFormatters.formatNumber(
          widget.total.round(),
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          receivedFocusNode.requestFocus();
          receivedController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: receivedController.text.length,
          );
        });
      } else {
        receivedController.text = AppFormatters.formatNumber(
          widget.total.round(),
        );
        receivedFocusNode.unfocus();
      }
      _calculateChange();
    });
  }

  /// Mapea el tipo de cuenta bancaria al método de pago correspondiente
  PaymentMethod _getPaymentMethodFromBankAccount(BankAccount? account) {
    if (account == null) {
      return PaymentMethod.cash; // Default si no hay cuenta seleccionada
    }

    switch (account.type) {
      case BankAccountType.cash:
        return PaymentMethod.cash;
      case BankAccountType.savings:
      case BankAccountType.checking:
        return PaymentMethod.bankTransfer;
      case BankAccountType.digitalWallet:
        return PaymentMethod.bankTransfer; // Nequi, Daviplata, etc. = transferencia
      case BankAccountType.creditCard:
        return PaymentMethod.creditCard;
      case BankAccountType.debitCard:
        return PaymentMethod.debitCard;
      case BankAccountType.other:
        return PaymentMethod.other;
    }
  }

  void _confirmPayment({required bool shouldPrint}) {
    print('\n🚀 === CONFIRMANDO PAGO ===');
    print('📋 DEBE IMPRIMIR: $shouldPrint');
    print('📋 MODO MÚLTIPLES PAGOS: $_isMultiplePaymentMode');

    // ============ MODO PAGOS MÚLTIPLES ============
    if (_isMultiplePaymentMode) {
      _confirmMultiplePayments(shouldPrint: shouldPrint);
      return;
    }

    // ============ MODO PAGO SIMPLE (ORIGINAL) ============
    // Determinar el método de pago final basado en:
    // 1. Si es crédito, usar crédito
    // 2. Si es pago inmediato con cuenta bancaria, usar el tipo de cuenta
    // 3. Si es pago inmediato sin cuenta, usar efectivo
    final PaymentMethod finalPaymentMethod;
    if (selectedPaymentMethod == PaymentMethod.credit) {
      finalPaymentMethod = PaymentMethod.credit;
    } else if (selectedBankAccount != null) {
      finalPaymentMethod = _getPaymentMethodFromBankAccount(selectedBankAccount);
    } else {
      finalPaymentMethod = PaymentMethod.cash;
    }

    // ✅ USAR _effectiveTotal (total - saldo aplicado) para el monto recibido
    final received =
        selectedPaymentMethod == PaymentMethod.cash && selectedBankAccount == null
            ? AppFormatters.parseNumber(receivedController.text) ?? 0.0
            : _effectiveTotal; // Si es transferencia o crédito, el pago es por el total efectivo

    final invoiceStatus = _getInvoiceStatus();

    print('📋 DATOS FINALES:');
    print('   - Método original: ${selectedPaymentMethod.displayName}');
    print('   - Método final: ${finalPaymentMethod.displayName}');
    print('   - Borrador marcado: $saveAsDraft');
    print('   - Estado calculado: ${invoiceStatus.displayName}');
    print('   - Estado esperado: ${_getExpectedStatus()}');
    print('   - Total factura: ${widget.total.toStringAsFixed(2)}');
    print('   - Saldo aplicado: ${_applyBalance ? _balanceToApply.toStringAsFixed(2) : "0.00"}');
    print('   - Total efectivo a pagar: ${_effectiveTotal.toStringAsFixed(2)}');
    print('   - Recibido: ${received.toStringAsFixed(2)}');
    print('   - Cambio: ${change >= 0 ? change : 0.0}');
    print('   - Debe imprimir: $shouldPrint');
    print('   - Cuenta bancaria: ${selectedBankAccount?.name ?? "Ninguna"}');
    print('   - Tipo cuenta: ${selectedBankAccount?.type.displayName ?? "N/A"}');

    print('\n📤 ENVIANDO AL CALLBACK...');

    if (mounted) {
      Navigator.of(context).pop();
      print('🔒 Diálogo cerrado inmediatamente');
    }

    widget.onPaymentConfirmed(
      received,
      change >= 0 ? change : 0.0,
      finalPaymentMethod, // Usar el método de pago determinado por la cuenta
      invoiceStatus,
      shouldPrint,
      bankAccountId: selectedBankAccount?.id,
      balanceApplied: _applyBalance ? _balanceToApply : null, // ✅ NUEVO: Saldo a favor aplicado
    );

    print('✅ Callback ejecutado después de cerrar el diálogo\n');
  }

  /// Confirmar pagos múltiples
  void _confirmMultiplePayments({required bool shouldPrint}) {
    print('\n🚀 === CONFIRMANDO PAGOS MÚLTIPLES ===');
    print('📋 Total pagos: ${_multiplePayments.length}');
    print('💰 Total pagado: ${AppFormatters.formatCurrency(_totalMultiplePayments)}');
    print('💰 Saldo restante: ${AppFormatters.formatCurrency(_remainingBalance)}');
    print('📋 Crear crédito: $_createCreditForRemaining');

    // Construir lista de pagos
    final payments = _multiplePayments.map((p) {
      final method = p.bankAccount != null
          ? _getPaymentMethodFromBankAccount(p.bankAccount)
          : p.method;

      return MultiplePaymentData(
        amount: p.amount,
        method: method,
        bankAccountId: p.bankAccount?.id,
        bankAccountName: p.bankAccount?.name,
      );
    }).toList();

    // Determinar el estado de la factura
    // ✅ USAR _effectiveTotal (total - saldo aplicado)
    InvoiceStatus invoiceStatus;
    if (saveAsDraft) {
      invoiceStatus = InvoiceStatus.draft;
    } else if (_remainingBalance > 0 && _createCreditForRemaining) {
      // Pago parcial con crédito
      invoiceStatus = InvoiceStatus.partiallyPaid;
    } else if (_totalMultiplePayments >= _effectiveTotal) {
      // Pago completo (total efectivo cubierto)
      invoiceStatus = InvoiceStatus.paid;
    } else {
      invoiceStatus = InvoiceStatus.pending;
    }

    // Usar el primer método de pago como principal (para compatibilidad)
    final primaryMethod = payments.isNotEmpty ? payments.first.method : PaymentMethod.cash;
    final primaryBankAccountId = payments.isNotEmpty ? payments.first.bankAccountId : null;

    print('📋 DATOS FINALES (PAGOS MÚLTIPLES):');
    print('   - Total factura: ${AppFormatters.formatCurrency(widget.total)}');
    print('   - Saldo aplicado: ${_applyBalance ? AppFormatters.formatCurrency(_balanceToApply) : "\$0"}');
    print('   - Total efectivo a pagar: ${AppFormatters.formatCurrency(_effectiveTotal)}');
    for (var i = 0; i < payments.length; i++) {
      print('   - Pago ${i + 1}: ${AppFormatters.formatCurrency(payments[i].amount)} via ${payments[i].method.displayName}');
    }
    print('   - Estado: ${invoiceStatus.displayName}');
    print('   - Debe imprimir: $shouldPrint');

    print('\n📤 ENVIANDO AL CALLBACK...');

    if (mounted) {
      Navigator.of(context).pop();
      print('🔒 Diálogo cerrado inmediatamente');
    }

    widget.onPaymentConfirmed(
      _totalMultiplePayments,
      0.0, // No hay cambio en pagos múltiples
      primaryMethod,
      invoiceStatus,
      shouldPrint,
      bankAccountId: primaryBankAccountId,
      multiplePayments: payments,
      createCreditForRemaining: _createCreditForRemaining,
      balanceApplied: _applyBalance ? _balanceToApply : null, // ✅ NUEVO: Saldo a favor aplicado
    );

    print('✅ Callback de pagos múltiples ejecutado\n');
  }

  String _getExpectedStatus() {
    if (saveAsDraft) return 'DRAFT';

    switch (selectedPaymentMethod) {
      case PaymentMethod.cash:
      case PaymentMethod.creditCard:
      case PaymentMethod.debitCard:
      case PaymentMethod.bankTransfer:
        return 'PAID';
      case PaymentMethod.credit:
      case PaymentMethod.check:
      case PaymentMethod.other:
        return 'PENDING';
      default:
        return 'DRAFT';
    }
  }
}
