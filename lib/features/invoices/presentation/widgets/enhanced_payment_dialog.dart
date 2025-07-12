// lib/features/invoices/presentation/widgets/enhanced_payment_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/invoice.dart';

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

class EnhancedPaymentDialog extends StatefulWidget {
  final double total;
  final Function(
    double receivedAmount,
    double change,
    PaymentMethod paymentMethod,
    InvoiceStatus status,
    bool shouldPrint, // ✅ NUEVO PARÁMETRO para indicar si debe imprimir
  )
  onPaymentConfirmed;
  final VoidCallback onCancel;

  const EnhancedPaymentDialog({
    super.key,
    required this.total,
    required this.onPaymentConfirmed,
    required this.onCancel,
  });

  @override
  State<EnhancedPaymentDialog> createState() => _EnhancedPaymentDialogState();
}

class _EnhancedPaymentDialogState extends State<EnhancedPaymentDialog> {
  final receivedController = TextEditingController();
  final receivedFocusNode = FocusNode(); // ✅ NUEVO: FocusNode para el campo
  final dialogFocusNode = FocusNode(); // ✅ NUEVO: FocusNode para el diálogo
  PaymentMethod selectedPaymentMethod = PaymentMethod.cash;
  double change = 0.0;
  bool canProcess = false;
  bool saveAsDraft = false;

  @override
  void initState() {
    super.initState();
    // Para efectivo, inicializar con el total exacto formateado
    if (selectedPaymentMethod == PaymentMethod.cash) {
      receivedController.text = AppFormatters.formatNumber(
        widget.total.round(),
      );
      _calculateChange();

      // ✅ NUEVO: Dar focus automáticamente al campo de dinero recibido
      WidgetsBinding.instance.addPostFrameCallback((_) {
        receivedFocusNode.requestFocus();
        // Seleccionar todo el texto para fácil edición
        receivedController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: receivedController.text.length,
        );
      });
    }

    // ✅ NUEVO: Dar focus al diálogo para shortcuts después de un breve delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          dialogFocusNode.requestFocus();
        }
      });
    });
  }

  @override
  void dispose() {
    receivedController.dispose();
    receivedFocusNode.dispose(); // ✅ NUEVO: Limpiar FocusNode
    dialogFocusNode.dispose(); // ✅ NUEVO: Limpiar FocusNode del diálogo
    super.dispose();
  }

  void _calculateChange() {
    // Usar el parseador para manejar formato de miles
    final received = AppFormatters.parseNumber(receivedController.text) ?? 0.0;

    setState(() {
      change = received - widget.total;

      if (saveAsDraft) {
        canProcess = true;
        print('🔵 Modo borrador - Puede procesar: $canProcess');
        return;
      }

      if (selectedPaymentMethod == PaymentMethod.cash) {
        // ✅ Corrección: comparar valores redondeados a 2 decimales
        final totalRounded = double.parse(widget.total.toStringAsFixed(2));
        final receivedRounded = double.parse(received.toStringAsFixed(2));

        canProcess = receivedRounded >= totalRounded;

        print(
          '💰 Efectivo - Recibido: $receivedRounded, Total: $totalRounded, Puede procesar: $canProcess',
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

    // 🔥 PRIORIDAD 1: Si está marcado como borrador, SIEMPRE devolver draft
    if (saveAsDraft) {
      print('🔵 RESULTADO: BORRADOR por elección del usuario');
      return InvoiceStatus.draft;
    }

    // 🔥 PRIORIDAD 2: Según método de pago
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

  // ✅ OBTENER COLOR SEGÚN ESTADO
  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.pending:
        return Colors.orange;
      case InvoiceStatus.draft:
        return Colors.blue;
      case InvoiceStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ✅ OBTENER DESCRIPCIÓN DEL ESTADO
  String _getStatusDescription(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return 'La factura quedará marcada como PAGADA';
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
    return RawKeyboardListener(
      focusNode: dialogFocusNode,
      autofocus:
          true, // ✅ NUEVO: Auto-focus para capturar eventos inmediatamente
      onKey: (RawKeyEvent event) {
        // ✅ MEJORADO: Procesar tanto KeyDown como KeyUp para consumir completamente
        if (event is RawKeyDownEvent) {
          print(
            '🎹 RAW DIALOG evento: ${event.logicalKey} - Shift: ${event.isShiftPressed}',
          );

          // ESC - Cancelar
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            print('🔴 RAW DIALOG ESC - Cancelando...');
            widget.onCancel();
            return; // Consumir evento
          }

          // Shift + Enter - Procesar sin imprimir
          if (event.logicalKey == LogicalKeyboardKey.enter &&
              event.isShiftPressed) {
            print('💾 RAW DIALOG Shift+Enter - Procesando sin imprimir...');
            if (canProcess) {
              _confirmPayment(shouldPrint: false);
            }
            return; // Consumir evento
          }

          // Shift + P - Procesar e imprimir (MEJORADO)
          if (event.logicalKey == LogicalKeyboardKey.keyP &&
              event.isShiftPressed) {
            print('🖨️ RAW DIALOG Shift+P - Procesando e imprimiendo...');
            if (canProcess) {
              _confirmPayment(shouldPrint: true);
            }
            return; // Consumir evento
          }

          // Enter solo - Procesar e imprimir
          if (event.logicalKey == LogicalKeyboardKey.enter &&
              !event.isShiftPressed) {
            print('🖨️ RAW DIALOG Enter - Procesando e imprimiendo...');
            if (canProcess) {
              _confirmPayment(shouldPrint: true);
            }
            return; // Consumir evento
          }
        }

        // ✅ NUEVO: También consumir eventos KeyUp para evitar propagación
        if (event is RawKeyUpEvent) {
          // Consumir eventos KeyUp de nuestros shortcuts para evitar propagación
          if (event.logicalKey == LogicalKeyboardKey.escape ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              (event.logicalKey == LogicalKeyboardKey.keyP &&
                  event.isShiftPressed)) {
            print('🔒 RAW DIALOG KeyUp consumido: ${event.logicalKey}');
            return; // Consumir evento KeyUp también
          }
        }
      },
      child: ResponsiveLayout(
        mobile: _buildMobileDialog(context),
        tablet: _buildTabletDialog(context),
        desktop: _buildDesktopDialog(context),
      ),
    );
  }

  // ==================== MOBILE LAYOUT ====================
  Widget _buildMobileDialog(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Procesar Pago'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onCancel,
          ),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTotalCard(context),
                        const SizedBox(height: 16), // Reducido de 24 a 16
                        // ✅ NUEVO ORDEN: Dinero recibido y cambio ANTES de métodos de pago
                        if (selectedPaymentMethod == PaymentMethod.cash) ...[
                          _buildCashPaymentSection(context, isMobile: true),
                          const SizedBox(height: 16), // Reducido de 24 a 16
                        ],
                        _buildPaymentMethodSection(context, isMobile: true),
                        const SizedBox(height: 16), // Reducido de 24 a 16
                        if (selectedPaymentMethod != PaymentMethod.cash) ...[
                          _buildOtherPaymentSection(context),
                          const SizedBox(height: 16), // Reducido de 24 a 16
                        ],
                        _buildDraftOption(context),
                        const SizedBox(height: 12), // Reducido de 16 a 12
                        _buildInvoiceStatusSection(context),
                      ],
                    ),
                  ),
                ),
                _buildMobileActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== TABLET LAYOUT ====================
  Widget _buildTabletDialog(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTotalCard(context),
                    const SizedBox(height: 20), // Reducido de 24 a 20
                    // ✅ NUEVO ORDEN: Dinero recibido y cambio ANTES de métodos de pago
                    if (selectedPaymentMethod == PaymentMethod.cash) ...[
                      _buildCashPaymentSection(context, isMobile: false),
                      const SizedBox(height: 20), // Reducido de 24 a 20
                    ],
                    _buildPaymentMethodSection(context, isMobile: false),
                    const SizedBox(height: 20), // Reducido de 24 a 20
                    if (selectedPaymentMethod != PaymentMethod.cash) ...[
                      _buildOtherPaymentSection(context),
                      const SizedBox(height: 20), // Reducido de 24 a 20
                    ],
                    _buildDraftOption(context),
                    const SizedBox(height: 14), // Reducido de 16 a 14
                    _buildInvoiceStatusSection(context),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: _buildDesktopActions(context),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== DESKTOP LAYOUT ====================
  Widget _buildDesktopDialog(BuildContext context) {
    return Dialog(
      child: Container(
        width: 550,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTotalCard(context),
                    const SizedBox(height: 24), // Reducido de 32 a 24
                    // ✅ NUEVO ORDEN: Dinero recibido y cambio ANTES de métodos de pago
                    if (selectedPaymentMethod == PaymentMethod.cash) ...[
                      _buildCashPaymentSection(context, isMobile: false),
                      const SizedBox(height: 24), // Reducido de 32 a 24
                    ],
                    _buildPaymentMethodSection(context, isMobile: false),
                    const SizedBox(height: 24), // Reducido de 32 a 24
                    if (selectedPaymentMethod != PaymentMethod.cash) ...[
                      _buildOtherPaymentSection(context),
                      const SizedBox(height: 24), // Reducido de 32 a 24
                    ],
                    _buildDraftOption(context),
                    const SizedBox(height: 16), // Mantenido igual
                    _buildInvoiceStatusSection(context),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: _buildDesktopActions(context),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SHARED COMPONENTS ====================

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.payment, color: Theme.of(context).primaryColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Text(
                  'Procesar Pago',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                // ✅ NUEVO: Icono de ayuda con tooltip de shortcuts
                Tooltip(
                  message:
                      '⌨️ Shortcuts disponibles:\n• Enter: Procesar e Imprimir\n• Shift+Enter: Solo Procesar\n• Shift+P: Imprimir\n• ESC: Cancelar',
                  preferBelow: true,
                  child: Icon(
                    Icons.help_outline,
                    color: Theme.of(context).primaryColor.withOpacity(0.7),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          IconButton(onPressed: widget.onCancel, icon: const Icon(Icons.close)),
        ],
      ),
    );
  }

  Widget _buildTotalCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.isMobile ? 16 : 18), // Reducido de 20
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Total a Pagar',
            style: TextStyle(
              fontSize: context.isMobile ? 14 : 16, // Reducido de 16:18
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6), // Reducido de 8
          Text(
            AppFormatters.formatCurrency(widget.total),
            style: TextStyle(
              fontSize: context.isMobile ? 24 : 28, // Reducido de 28:32
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection(
    BuildContext context, {
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Método de Pago',
          style: TextStyle(
            fontSize: context.isMobile ? 14 : 16, // Tamaño reducido
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 10), // Reducido de 12 a 10

        if (isMobile)
          _buildMobilePaymentMethods()
        else
          _buildDesktopPaymentMethods(),
      ],
    );
  }

  Widget _buildMobilePaymentMethods() {
    return Column(
      children:
          PaymentMethod.values.map((method) {
            final isSelected = selectedPaymentMethod == method;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Material(
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _selectPaymentMethod(method),
                  child: Container(
                    padding: EdgeInsets.all(
                      context.isMobile ? 12 : 14,
                    ), // Padding reducido
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color:
                          isSelected
                              ? Theme.of(context).primaryColor.withOpacity(0.1)
                              : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getPaymentMethodIcon(method),
                          color:
                              isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            method.displayName,
                            style: TextStyle(
                              fontSize:
                                  context.isMobile
                                      ? 14
                                      : 16, // Tamaño responsive
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight
                                          .w500, // Mejor peso para no seleccionados
                              color:
                                  isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey.shade700, // Mejor contraste
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(context).primaryColor,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildDesktopPaymentMethods() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children:
            PaymentMethod.values.map((method) {
              final isSelected = selectedPaymentMethod == method;
              final isLast = method == PaymentMethod.values.last;

              return Container(
                decoration: BoxDecoration(
                  border:
                      isLast
                          ? null
                          : Border(
                            bottom: BorderSide(color: Colors.grey.shade200),
                          ),
                ),
                child: RadioListTile<PaymentMethod>(
                  value: method,
                  groupValue: selectedPaymentMethod,
                  onChanged: (value) => _selectPaymentMethod(value!),
                  title: Row(
                    children: [
                      Icon(
                        _getPaymentMethodIcon(method),
                        color:
                            isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        method.displayName,
                        style: TextStyle(
                          fontSize:
                              context.isMobile ? 14 : 16, // Tamaño responsive
                          fontWeight:
                              isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500, // Mejor peso
                          color:
                              isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade700, // Mejor contraste
                        ),
                      ),
                    ],
                  ),
                  activeColor: Theme.of(context).primaryColor,
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildCashPaymentSection(
    BuildContext context, {
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dinero Recibido',
          style: TextStyle(
            fontSize: context.isMobile ? 14 : 16, // Tamaño reducido
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 10), // Reducido de 12 a 10

        TextField(
          controller: receivedController,
          focusNode: receivedFocusNode,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CurrencyInputFormatter(), // Aplicar formato de miles automáticamente
          ],
          style: TextStyle(
            fontSize: context.isMobile ? 14 : 16, // Tamaño reducido
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            prefixText: '\$ ',
            prefixStyle: TextStyle(
              fontSize: context.isMobile ? 14 : 16, // Tamaño reducido
              fontWeight: FontWeight.w600,
            ),
            border: const OutlineInputBorder(),
            contentPadding: EdgeInsets.all(
              context.isMobile ? 12 : 14,
            ), // Padding reducido
            hintText: '0.00',
            // ✅ NUEVO: Color dinámico según el estado del cambio
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: change >= 0 ? Colors.green : Colors.red,
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: change >= 0 ? Colors.green : Colors.red,
                width: 2,
              ),
            ),
            // ✅ NUEVO: Ícono de estado
            suffixIcon: Icon(
              change >= 0 ? Icons.check_circle : Icons.error,
              color: change >= 0 ? Colors.green : Colors.red,
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
        const SizedBox(height: 16),

        // Cambio
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14), // Reducido de 16 a 14
          decoration: BoxDecoration(
            color: change >= 0 ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: change >= 0 ? Colors.green.shade200 : Colors.red.shade200,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cambio:',
                style: TextStyle(
                  fontSize: context.isMobile ? 13 : 15, // Tamaño reducido
                  fontWeight: FontWeight.w600,
                  color:
                      change >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
              Text(
                change >= 0
                    ? AppFormatters.formatCurrency(change)
                    : AppFormatters.formatCurrency(0),
                style: TextStyle(
                  fontSize: context.isMobile ? 16 : 18, // Tamaño reducido
                  fontWeight: FontWeight.bold,
                  color:
                      change >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
            ],
          ),
        ),

        // ✅ MENSAJE DE AYUDA PARA EFECTIVO (solo cuando el monto es MENOR al total)
        if (change < 0)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(10), // Reducido de 12 a 10
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.orange.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'El monto recibido debe ser igual o mayor al total',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildOtherPaymentSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: saveAsDraft ? Colors.blue.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: saveAsDraft ? Colors.blue.shade200 : Colors.blue.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(
            saveAsDraft ? Icons.edit : Icons.info,
            color: Colors.blue.shade600,
          ),
          const SizedBox(height: 8),
          Text(
            saveAsDraft
                ? 'La factura se guardará como borrador para revisión'
                : selectedPaymentMethod == PaymentMethod.credit
                ? 'El pago se registrará como crédito y quedará pendiente'
                : 'Confirme que el pago ha sido procesado exitosamente',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.isMobile ? 14 : 16,
              color: Colors.blue.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceStatusSection(BuildContext context) {
    final status = _getInvoiceStatus();
    final statusColor = _getStatusColor(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getStatusIcon(status), color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Estado de Factura',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getStatusDescription(status),
            style: TextStyle(fontSize: 12, color: statusColor.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftOption(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: saveAsDraft ? Colors.blue.shade100 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: saveAsDraft ? Colors.blue.shade400 : Colors.blue.shade200,
          width: saveAsDraft ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: saveAsDraft,
        onChanged: (value) {
          setState(() {
            saveAsDraft = value ?? false;
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
        title: Text(
          'Guardar como borrador',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: saveAsDraft ? Colors.blue.shade800 : Colors.blue.shade700,
          ),
        ),
        subtitle: Text(
          saveAsDraft
              ? 'La factura se guardará para revisión posterior'
              : 'La factura necesita revisión antes de procesar el pago',
          style: TextStyle(
            fontSize: 12,
            color: saveAsDraft ? Colors.blue.shade700 : Colors.blue.shade600,
          ),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: Colors.blue.shade600,
      ),
    );
  }

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

  // ==================== ACTIONS ====================

  // ✅ NUEVAS ACCIONES - MÓVIL CON DOS BOTONES
  Widget _buildMobileActions(BuildContext context) {
    return Column(
      children: [
        // ✅ NUEVO BOTÓN: Procesar e Imprimir
        SizedBox(
          width: double.infinity,
          height: 48,
          child: Tooltip(
            message: 'Procesar pago e imprimir factura (Shift + P)',
            child: ElevatedButton.icon(
              onPressed:
                  canProcess ? () => _confirmPayment(shouldPrint: true) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.print),
              label: const Text(
                'Procesar Venta e Imprimir',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ✅ BOTÓN ORIGINAL: Solo procesar (sin imprimir)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: Tooltip(
            message: 'Procesar pago sin imprimir (Shift+Enter)',
            child: OutlinedButton.icon(
              onPressed:
                  canProcess ? () => _confirmPayment(shouldPrint: false) : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                side: BorderSide(color: Theme.of(context).primaryColor),
              ),
              icon: const Icon(Icons.save),
              label: const Text(
                'Procesar Venta',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Botón cancelar
        SizedBox(
          width: double.infinity,
          height: 48,
          child: Tooltip(
            message: 'Cancelar y cerrar diálogo (ESC)',
            child: OutlinedButton(
              onPressed: widget.onCancel,
              child: const Text('Cancelar'),
            ),
          ),
        ),
      ],
    );
  }

  // ✅ NUEVAS ACCIONES - DESKTOP CON DOS BOTONES
  Widget _buildDesktopActions(BuildContext context) {
    return Column(
      children: [
        // Fila principal con botones de acción
        Row(
          children: [
            Expanded(
              child: Tooltip(
                message: 'Cancelar y cerrar diálogo (ESC)',
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Tooltip(
                message: 'Procesar pago sin imprimir (Shift+Enter)',
                child: OutlinedButton.icon(
                  onPressed:
                      canProcess
                          ? () => _confirmPayment(shouldPrint: false)
                          : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    foregroundColor: Theme.of(context).primaryColor,
                    side: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Procesar Venta',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ✅ NUEVO BOTÓN PRINCIPAL: Procesar e Imprimir
        SizedBox(
          width: double.infinity,
          child: Tooltip(
            message: 'Procesar pago e imprimir factura (Shift + P )',
            child: ElevatedButton.icon(
              onPressed:
                  canProcess ? () => _confirmPayment(shouldPrint: true) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              icon: const Icon(Icons.print),
              label: const Text(
                'Procesar Venta e Imprimir',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== HELPER METHODS ====================

  void _selectPaymentMethod(PaymentMethod method) {
    setState(() {
      selectedPaymentMethod = method;

      if (selectedPaymentMethod == PaymentMethod.cash) {
        receivedController.text = AppFormatters.formatNumber(
          widget.total.round(),
        );

        // ✅ NUEVO: Dar focus automáticamente cuando se selecciona efectivo
        WidgetsBinding.instance.addPostFrameCallback((_) {
          receivedFocusNode.requestFocus();
          // Seleccionar todo el texto para fácil edición
          receivedController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: receivedController.text.length,
          );
        });
      } else {
        receivedController.text = AppFormatters.formatNumber(
          widget.total.round(),
        );
        // Quitar focus si no es efectivo
        receivedFocusNode.unfocus();
      }
      _calculateChange();
    });
  }

  // ✅ MÉTODO MODIFICADO: Ahora recibe parámetro shouldPrint
  void _confirmPayment({required bool shouldPrint}) {
    print('\n🚀 === CONFIRMANDO PAGO ===');
    print('📋 DEBE IMPRIMIR: $shouldPrint');

    final received =
        selectedPaymentMethod == PaymentMethod.cash
            ? AppFormatters.parseNumber(receivedController.text) ?? 0.0
            : widget.total;

    final invoiceStatus = _getInvoiceStatus();

    print('📋 DATOS FINALES:');
    print('   - Método: ${selectedPaymentMethod.displayName}');
    print('   - Borrador marcado: $saveAsDraft');
    print('   - Estado calculado: ${invoiceStatus.displayName}');
    print('   - Estado esperado: ${_getExpectedStatus()}');
    print('   - Recibido: \${received.toStringAsFixed(2)}');
    print('   - Cambio: \${change >= 0 ? change : 0.0}');
    print('   - Debe imprimir: $shouldPrint');

    print('\n📤 ENVIANDO AL CALLBACK...');

    // ✅ NUEVO: Inmediatamente cerrar el diálogo antes de llamar al callback
    // para evitar problemas con operaciones asíncronas
    if (mounted) {
      Navigator.of(context).pop();
      print('🔒 Diálogo cerrado inmediatamente');
    }

    // Llamar al callback para procesar la venta
    widget.onPaymentConfirmed(
      received,
      change >= 0 ? change : 0.0,
      selectedPaymentMethod,
      invoiceStatus,
      shouldPrint, // ✅ NUEVO PARÁMETRO
    );

    print('✅ Callback ejecutado después de cerrar el diálogo\n');
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

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.attach_money;
      case PaymentMethod.creditCard:
        return Icons.credit_card;
      case PaymentMethod.debitCard:
        return Icons.payment;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.check:
        return Icons.receipt_long;
      case PaymentMethod.credit:
        return Icons.schedule;
      case PaymentMethod.other:
        return Icons.more_horiz;
      default:
        return Icons.payment;
    }
  }
}
